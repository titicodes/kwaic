// widgets/audio_track_row.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../nes_scr/widgets/wave_form_painter.dart';
import '../model/audio_track.dart';
import '../provider/video_editor_provider.dart';
import '../timeline_constants.dart';

class AudioTrackRow extends StatelessWidget {
  const AudioTrackRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();
    final worldWidth = provider.totalTimelineSeconds * pixelsPerSecond;

    return SizedBox(
      height: 50,
      width: worldWidth,
      child: Stack(
        children: provider.audioTracks.map((track) {
          final double left = track.start * pixelsPerSecond;
          final double width = math.max(track.duration * pixelsPerSecond, 40);
          final bool isSelected = provider.selectedAudioTrack?.id == track.id;

          return Positioned(
            left: left,
            top: 0,
            width: width,
            child: GestureDetector(
              // Tap to select
              onTap: () => provider.selectAudio(track),

              // Double tap to split
              onDoubleTap: () {
                final pos = provider.currentPosition;
                if (pos >= track.startTime && pos < track.endTime) {
                  provider.splitAudioAt(pos);
                }
              },

              child: Stack(
                children: [
                  // Main audio clip container
                  Container(
                    height: 60,
                    margin: const EdgeInsets.only(right: 4),
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
                    clipBehavior: Clip.hardEdge,
                    child: track.waveform != null
                        ? RepaintBoundary(
                      child: AudioWaveform(
                        waveform: track.waveform!,
                        color: Colors.white,
                        height: 60,
                      ),
                    )
                        : const Center(
                      child: Text(
                        'Loading...',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                  ),

                  // Full-area drag for moving the clip
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onLongPressMoveUpdate: (details) {
                        final deltaSeconds = details.offsetFromOrigin.dx / pixelsPerSecond;
                        final newStartSeconds = track.start + deltaSeconds;
                        if (newStartSeconds >= 0) {
                          provider.moveAudio(track, newStartSeconds);
                        }
                      },
                    ),
                  ),

                  // Trim handles — only when selected
                  if (isSelected)
                    Positioned.fill(
                      child: Row(
                        children: [
                          // Left trim handle
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onHorizontalDragUpdate: (details) {
                              final deltaSeconds = details.delta.dx / pixelsPerSecond;
                              final newStartSeconds = track.start + deltaSeconds;
                              if (newStartSeconds >= 0 &&
                                  newStartSeconds < track.start + track.duration - 0.2) {
                                provider.previewAudioTrimStart(newStartSeconds);
                              }
                            },
                            onHorizontalDragEnd: (_) {
                              final newStart = Duration(
                                milliseconds: (provider.audioTrimStart.inMilliseconds),
                              );
                              provider.applyAudioTrim(
                                track,
                                newStart,
                                track.endTime,
                              );
                            },
                            child: Container(
                              width: 20,
                              color: Colors.transparent,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 5,
                                height: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Right trim handle
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onHorizontalDragUpdate: (details) {
                              final deltaSeconds = details.delta.dx / pixelsPerSecond;
                              final newEndSeconds = (track.start + track.duration) + deltaSeconds;
                              if (newEndSeconds > track.start + 0.2 &&
                                  newEndSeconds <= track.start + track.originalDuration) {
                                provider.previewAudioTrimEnd(newEndSeconds);
                              }
                            },
                            onHorizontalDragEnd: (_) {
                              final newEnd = Duration(
                                milliseconds: (provider.audioTrimEnd.inMilliseconds),
                              );
                              provider.applyAudioTrim(
                                track,
                                track.startTime,
                                newEnd,
                              );
                            },
                            child: Container(
                              width: 20,
                              color: Colors.transparent,
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 5,
                                height: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}