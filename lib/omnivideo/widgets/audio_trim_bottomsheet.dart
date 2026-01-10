import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/audio_track.dart';
import '../provider/video_editor_provider.dart';
import '../../nes_scr/widgets/wave_form_painter.dart'; // your waveform painter

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
    provider.startAudioTrimPreview();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();
    final waveWidth = track.originalDuration * 80; // px per second

    return Container(
      height: 280,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    provider.endAudioTrimPreview();
                    provider.showBottomSheet = false;
                    provider.showContextToolbar = true;
                  },
                ),
                const Text('Trim Audio', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.greenAccent),
                  onPressed: () async {
                    await provider.applyAudioTrim();
                    provider.endAudioTrimPreview();
                    provider.showBottomSheet = false;
                    provider.showContextToolbar = true;
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: waveWidth,
                child: Stack(
                  children: [
                    // Full waveform (dimmed)
                    if (track.waveform != null)
                      CustomPaint(
                        painter: AudioWaveformPainter(
                          waveform: track.waveform!,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        size: Size(waveWidth, 100),
                      ),

                    // Active selection (bright)
                    ClipRect(
                      clipper: _TrimClipper(
                        left: startPercent * waveWidth,
                        right: (1 - endPercent) * waveWidth,
                      ),
                      child: CustomPaint(
                        painter: AudioWaveformPainter(
                          waveform: track.waveform!,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        size: Size(waveWidth, 100),
                      ),
                    ),

                    // Left handle
                    Positioned(
                      left: startPercent * waveWidth - 15,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (d) {
                          final newP = (startPercent * waveWidth + d.delta.dx) / waveWidth;
                          setState(() => startPercent = newP.clamp(0.0, endPercent - 0.02));
                          provider.previewAudioTrimStart(startPercent * track.originalDuration);
                        },
                        child: Container(width: 30, height: 100, color: Colors.transparent, alignment: Alignment.center, child: Container(width: 6, color: Colors.white)),
                      ),
                    ),

                    // Right handle
                    Positioned(
                      left: endPercent * waveWidth - 15,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (d) {
                          final newP = (endPercent * waveWidth + d.delta.dx) / waveWidth;
                          setState(() => endPercent = newP.clamp(startPercent + 0.02, 1.0));
                          provider.previewAudioTrimEnd(endPercent * track.originalDuration);
                        },
                        child: Container(width: 30, height: 100, color: Colors.transparent, alignment: Alignment.center, child: Container(width: 6, color: Colors.white)),
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
                Text(_formatDuration(Duration(seconds: (startPercent * track.originalDuration).round()))),
                Text(_formatDuration(Duration(seconds: (endPercent * track.originalDuration).round()))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}

class _TrimClipper extends CustomClipper<Rect> {
  final double left;
  final double right;

  _TrimClipper({required this.left, required this.right});

  @override
  Rect getClip(Size size) => Rect.fromLTRB(left, 0, size.width - right, size.height);

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => true;
}
