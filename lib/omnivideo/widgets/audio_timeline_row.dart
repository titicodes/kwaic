import 'package:flutter/material.dart';

import '../../nes_scr/widgets/audio_library_sheet.dart';
import '../../nes_scr/widgets/wave_form_painter.dart';
import '../model/audio_track.dart';
import '../provider/video_editor_provider.dart';
import 'package:provider/provider.dart';

import '../timeline_constants.dart';

class AudioTrackRow extends StatelessWidget {
  const AudioTrackRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();

    double cursor = 0.0; // ← Same as VideoClipsRow

    return SizedBox(
      height: 60,
      width: provider.timelineWorldWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Audio tracks — same cursor system as video
          ...provider.audioTracks.map((track) {
            final double width = track.duration * pixelsPerSecond;
            final double left = cursor;
            cursor += width + clipGap; // same gap as video

            final bool isSelected = provider.selectedAudioTrack?.id == track.id;

            return Positioned(
              left: left,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  provider.selectAudio(track);
                  // Do NOT open toolbar for audio (CapCut style)
                },
                onHorizontalDragUpdate: (details) {
                  final deltaSeconds = details.delta.dx / pixelsPerSecond;
                  final newStart = track.start + deltaSeconds;
                  if (newStart < 0) return;

                  final updated = track.copyWith(start: newStart);
                  final index = provider.audioTracks.indexWhere((t) => t.id == track.id);
                  if (index != -1) {
                    final newList = List<AudioTrack>.from(provider.audioTracks);
                    newList[index] = updated;
                    provider.audioTracks = newList;
                  }
                },
                child: Container(
                  width: width.clamp(60.0, double.infinity),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: const Color(0xFF00D9FF), width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [const BoxShadow(color: Color(0xFF00D9FF), blurRadius: 8)]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: track.waveform != null
                        ? AudioWaveform(
                      waveform: track.waveform!,
                      color: Colors.white,
                      height: 56,
                    )
                        : const Center(
                      child: Text(
                        'Loading...',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),

          // "Add Audio" button
          if (provider.audioTracks.isEmpty)
            Positioned(
              left: 200, // arbitrary — will be centered by layout
              top: 18,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AudioLibrarySheet(
                      insertPosition: provider.currentPosition,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline, color: Color(0xFF8B5CF6), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Add Audio',
                        style: TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}