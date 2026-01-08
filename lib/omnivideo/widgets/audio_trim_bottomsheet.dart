// widgets/audio_trim_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:kwaic/nes_scr/widgets/wave_form_painter.dart';
import 'package:provider/provider.dart';
import '../model/audio_track.dart';
import '../provider/video_editor_provider.dart';

class AudioTrimBottomSheet extends StatefulWidget {
  const AudioTrimBottomSheet({super.key});

  @override
  State<AudioTrimBottomSheet> createState() => _AudioTrimBottomSheetState();
}

class _AudioTrimBottomSheetState extends State<AudioTrimBottomSheet> {
  late AudioTrack track;
  double startPercent = 0.0;
  double endPercent = 1.0;

  @override
  void initState() {
    super.initState();
    final provider = context.read<VideoEditorProvider>();
    track = provider.selectedAudioTrack!;
    provider.startTrimPreview();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();
    final waveWidth = track.originalDuration * 80; // 80 px per second

    return Container(
      height: 240,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    provider.endTrimPreview();
                    provider.showBottomSheet = false;
                    provider.showContextToolbar = true;
                  },
                ),
                const Text('Trim Audio', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: () => _applyTrim(provider),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: waveWidth,
                height: 100,
                child: Stack(
                  children: [
                    // In AudioTrimBottomSheet.dart
                    if (track.waveform != null)
                      CustomPaint(
                        painter: AudioWaveformPainter(
                          waveform: track.waveform!,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        size: Size(waveWidth, 100),
                      ),
                    // Left handle
                    _buildHandle(
                      left: startPercent * waveWidth - 15,
                      onDrag: (dx) {
                        final newP = (startPercent * waveWidth + dx) / waveWidth;
                        setState(() => startPercent = newP.clamp(0.0, endPercent - 0.02));
                        final ms = (startPercent * track.originalDuration * 1000).round();
                        provider.previewAudioTrimStart(startPercent * track.originalDuration);
                      },
                    ),
                    // Right handle
                    _buildHandle(
                      left: endPercent * waveWidth - 15,
                      onDrag: (dx) {
                        final newP = (endPercent * waveWidth + dx) / waveWidth;
                        setState(() => endPercent = newP.clamp(startPercent + 0.02, 1.0));
                        final ms = (endPercent * track.originalDuration * 1000).round();
                        provider.previewAudioTrimEnd(endPercent * track.originalDuration);
                      },
                    ),
                    // Selection overlay
                    IgnorePointer(
                      child: Container(
                        margin: EdgeInsets.only(
                          left: startPercent * waveWidth,
                          right: (1 - endPercent) * waveWidth,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(Duration(seconds: (startPercent * track.originalDuration).round())), style: const TextStyle(color: Colors.white)),
                Text(_formatDuration(Duration(seconds: (endPercent * track.originalDuration).round())), style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle({required double left, required Function(double) onDrag}) {
    return Positioned(
      left: left.clamp(-15, double.infinity),
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
        child: Container(
          width: 30,
          alignment: Alignment.center,
          child: Container(width: 4, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _applyTrim(VideoEditorProvider provider) async {
    final newStart = Duration(seconds: (startPercent * track.originalDuration).round());
    final newEnd = Duration(seconds: (endPercent * track.originalDuration).round());
    await provider.applyAudioTrim(track, newStart, newEnd);
    provider.endTrimPreview();
    provider.showBottomSheet = false;
    provider.showContextToolbar = true;
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000 ~/ 100);
    return '$min:$sec.$ms';
  }
}