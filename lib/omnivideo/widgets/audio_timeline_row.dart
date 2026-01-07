import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../nes_scr/widgets/wave_form_painter.dart';
import '../provider/video_editor_provider.dart';
import '../timeline_constants.dart';

class AudioTrackRow extends StatelessWidget {
  const AudioTrackRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();

    final worldWidth = provider.totalTimelineSeconds * pixelsPerSecond;

    return SizedBox(
      height: 60,
      width: worldWidth,
      child: Stack(
        children: provider.audioTracks.map((track) {
          final left = track.start * pixelsPerSecond;
          final width = track.duration * pixelsPerSecond;
          final bool selected = provider.selectedAudioTrack?.id == track.id;

          return Positioned(
            left: left,
            top: 0,
            width: width,
            child: GestureDetector(
              onTap: () {
                provider.selectAudio(track);
              },
              onHorizontalDragUpdate: (details) {
                final dx = details.delta.dx / pixelsPerSecond;
                final newStart = track.start + dx;
                if (newStart < 0) return;
                provider.moveAudio(track, newStart);
              },
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: selected
                      ? Border.all(color: const Color(0xFF00D9FF), width: 3)
                      : null,
                  boxShadow: selected
                      ? [const BoxShadow(color: Color(0xFF00D9FF), blurRadius: 8)]
                      : null,
                ),
                clipBehavior: Clip.hardEdge,
                child: track.waveform != null
                    ? RepaintBoundary(
                  child: AudioWaveform(
                    waveform: track.waveform!,
                    color: Colors.white,
                    height: 56,
                  ),
                )
                    : const Center(
                  child: Text('Loading...',
                      style: TextStyle(color: Colors.white70, fontSize: 10)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
