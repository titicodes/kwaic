import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/video_track.dart';
import '../provider/video_editor_provider.dart';
import '../timeline_constants.dart';

class VideoClipWidget extends StatelessWidget {
  final VideoTrack track;

  const VideoClipWidget({super.key, required this.track});

  static const double thumbWidth = 28;
  static const double clipHeight = 56;

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoEditorProvider>(
      builder: (context, provider, _) {
        final thumbnails = track.timelineThumbnails;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final deltaSeconds = details.delta.dx / pixelsPerSecond;
            final newStart = track.startTime +
                Duration(milliseconds: (deltaSeconds * 1000).round());
            if (newStart < Duration.zero) return;
            provider.moveClip(track, newStart);
          },
          child: Container(
            height: clipHeight,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade700,
              borderRadius: BorderRadius.circular(6),
            ),
            clipBehavior: Clip.hardEdge,
            child: thumbnails.isNotEmpty
                ? LayoutBuilder(
              builder: (context, constraints) {
                final int fitCount =
                (constraints.maxWidth / thumbWidth).floor();
                final double remainder =
                    constraints.maxWidth - fitCount * thumbWidth;

                return RepaintBoundary(
                  child: Row(
                    children: [
                      for (int i = 0; i < fitCount; i++)
                        SizedBox(
                          width: thumbWidth,
                          height: clipHeight,
                          child: Image.memory(
                            thumbnails[i % thumbnails.length],
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                      if (remainder > 0)
                        SizedBox(
                          width: remainder,
                          height: clipHeight,
                          child: Image.memory(
                            thumbnails[fitCount % thumbnails.length],
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                    ],
                  ),
                );
              },
            )
                : track.thumbnail != null
                ? Image.memory(
              track.thumbnail!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            )
                : const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
          ),
        );
      },
    );
  }
}
