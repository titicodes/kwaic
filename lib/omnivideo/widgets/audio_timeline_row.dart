// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../nes_scr/widgets/wave_form_painter.dart';
// import '../model/audio_track.dart';
// import '../provider/video_editor_provider.dart';
// import '../timeline_constants.dart';
//
// class AudioTrackRow extends StatelessWidget {
//   const AudioTrackRow({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<VideoEditorProvider>();
//     final worldWidth = provider.timelineWorldWidth;
//
//     return SizedBox(
//       height: 60,
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         physics: const NeverScrollableScrollPhysics(),
//         controller: provider.timelineScrollController, // Share scroll with video row!
//         child: SizedBox(
//           width: worldWidth, // Now safe: this is inside scrollable
//           child: Stack(
//             clipBehavior: Clip.none, // Allows items to overflow if needed
//             children: provider.audioTracks.map((track) {
//               final double left = track.start * pixelsPerSecond;
//               final double width = math.max(track.duration * pixelsPerSecond, 40.0);
//               final bool isSelected = provider.selectedAudioTrack?.id == track.id;
//
//               return Positioned(
//                 left: left,
//                 top: 0,
//                 width: width,
//                 child: GestureDetector(
//                   onTap: () => provider.selectAudio(track),
//                   onDoubleTap: () {
//                     final pos = provider.currentPosition;
//                     final trackStart = Duration(milliseconds: (track.start * 1000).round());
//                     final trackEnd = trackStart + Duration(milliseconds: (track.duration * 1000).round());
//                     if (pos >= trackStart && pos < trackEnd) {
//                       provider.splitAudioAt(pos);
//                     }
//                   },
//                   onLongPressMoveUpdate: (details) {
//                     final deltaSeconds = details.delta.dx / pixelsPerSecond;
//                     final newStart = Duration(milliseconds: ((track.start + deltaSeconds) * 1000).round().clamp(0, double.infinity.toInt()));
//                     provider.moveAudio(track, newStart.inMilliseconds / 1000.0);
//                   },
//                   child: Container(
//                     height: 60,
//                     decoration: BoxDecoration(
//                       color: Colors.deepPurple.withOpacity(0.4),
//                       borderRadius: BorderRadius.circular(8),
//                       border: isSelected ? Border.all(color: const Color(0xFF00D9FF), width: 3) : null,
//                       boxShadow: isSelected ? [const BoxShadow(color: Color(0xFF00D9FF), blurRadius: 8)] : null,
//                     ),
//                     child: track.waveform != null
//                         ? CustomPaint(
//                       painter: AudioWaveformPainter(
//                         waveform: track.waveform!,
//                         color: Colors.white.withOpacity(0.8),
//                       ),
//                       size: Size(width, 60),
//                     )
//                         : const Center(
//                       child: Text(
//                         'Loading waveform...',
//                         style: TextStyle(color: Colors.white70, fontSize: 10),
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../nes_scr/widgets/wave_form_painter.dart'; // or your custom painter
import '../model/audio_track.dart';
import '../provider/video_editor_provider.dart';
import '../timeline_constants.dart';

class AudioTrackRow extends StatelessWidget {
  const AudioTrackRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();
    final worldWidth = provider.timelineWorldWidth;

    return SizedBox(
      height: 60,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        controller: provider.timelineScrollController, // Sync with video row
        child: SizedBox(
          width: worldWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children:
                provider.audioTracks.map((track) {
                  final double left = track.start * pixelsPerSecond;
                  final double width = math.max(
                    track.duration * pixelsPerSecond,
                    40.0,
                  );
                  final bool isSelected =
                      provider.selectedAudioTrack?.id == track.id;

                  return Positioned(
                    left: left,
                    top: 0,
                    width: width,
                    child: GestureDetector(
                      // Tap to select
                      onTap: () => provider.selectAudio(track),

                      // Double tap to split at current position
                      onDoubleTap: () {
                        final pos = provider.currentPosition;
                        final trackStart = Duration(
                          milliseconds: (track.start * 1000).round(),
                        );
                        final trackEnd =
                            trackStart +
                            Duration(
                              milliseconds: (track.duration * 1000).round(),
                            );
                        if (pos >= trackStart && pos < trackEnd) {
                          provider.splitAudioAt(pos);
                        }
                      },

                      child: Stack(
                        children: [
                          // Main audio clip
                          Container(
                            height: 60,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: const Color(0xFF00D9FF),
                                        width: 3,
                                      )
                                      : null,
                              boxShadow:
                                  isSelected
                                      ? [
                                        const BoxShadow(
                                          color: Color(0xFF00D9FF),
                                          blurRadius: 8,
                                        ),
                                      ]
                                      : null,
                            ),
                            clipBehavior: Clip.hardEdge,
                            child:
                                track.waveform != null
                                    ? RepaintBoundary(
                                      child: CustomPaint(
                                        painter: AudioWaveformPainter(
                                          waveform: track.waveform!,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                        size: Size(width, 60),
                                      ),
                                    )
                                    : const Center(
                                      child: Text(
                                        'Loading...',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                          ),

                          // Full-area drag for moving the clip (long-press)
                          // Full-area drag for moving the clip (long-press)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onLongPressMoveUpdate: (
                                LongPressMoveUpdateDetails details,
                              ) {
                                // Use offsetFromOrigin instead of delta
                                final deltaSeconds =
                                    details.offsetFromOrigin.dx /
                                    pixelsPerSecond;
                                final newStartSeconds =
                                    track.start + deltaSeconds;

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
                                      final deltaSeconds =
                                          details.delta.dx / pixelsPerSecond;
                                      final newStartSeconds =
                                          track.start + deltaSeconds;
                                      if (newStartSeconds >= 0 &&
                                          newStartSeconds <
                                              track.start +
                                                  track.duration -
                                                  0.2) {
                                        provider.previewAudioTrimStart(
                                          newStartSeconds,
                                        );
                                      }
                                    },
                                    onHorizontalDragEnd: (_) {
                                      final newStart = Duration(
                                        milliseconds:
                                            provider
                                                .audioTrimStart
                                                .inMilliseconds,
                                      );
                                      provider.applyAudioTrim(

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
                                      final deltaSeconds =
                                          details.delta.dx / pixelsPerSecond;
                                      final newEndSeconds =
                                          (track.start + track.duration) +
                                          deltaSeconds;
                                      if (newEndSeconds > track.start + 0.2 &&
                                          newEndSeconds <=
                                              track.start +
                                                  track.originalDuration) {
                                        provider.previewAudioTrimEnd(
                                          newEndSeconds,
                                        );
                                      }
                                    },
                                    onHorizontalDragEnd: (_) {
                                      final newEnd = Duration(
                                        milliseconds:
                                            provider
                                                .audioTrimEnd
                                                .inMilliseconds,
                                      );
                                      provider.applyAudioTrim(

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
        ),
      ),
    );
  }
}
