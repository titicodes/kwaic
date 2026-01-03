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
    final provider = context.read<VideoEditorProvider>();

    // final clipWidth = track.duration.inMilliseconds / 1000 * pixelsPerSecond;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final deltaSeconds = details.delta.dx / pixelsPerSecond;
        final newStart =
            track.startTime +
            Duration(milliseconds: (deltaSeconds * 1000).round());

        if (newStart < Duration.zero) return;
        provider.moveClip(track, newStart);
      },

      child: Container(
        //width: clipWidth,
        height: clipHeight,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade700,
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.hardEdge, // 💥 HARD STOP OVERFLOW
        child:
            track.timelineThumbnails.isEmpty
                ? (track.thumbnail != null
                    ? Image.memory(
                      track.thumbnail!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                    : Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: Colors.blueGrey.shade800),
                        const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ))
                : LayoutBuilder(
                  builder: (context, c) {
                    final fitCount = (c.maxWidth / thumbWidth).floor();
                    final remainder = c.maxWidth - fitCount * thumbWidth;

                    return ClipRect(
                      child: Row(
                        children: [
                          // Perfectly fitting tiles
                          for (int i = 0; i < fitCount; i++)
                            SizedBox(
                              width: thumbWidth,
                              height: clipHeight,
                              child: Image.memory(
                                track.timelineThumbnails[i %
                                    track.timelineThumbnails.length],
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              ),
                            ),

                          // Stretch final pixel filler (CapCut trick)
                          if (remainder > 0)
                            SizedBox(
                              width: remainder,
                              height: clipHeight,
                              child: Image.memory(
                                track.timelineThumbnails[fitCount %
                                    track.timelineThumbnails.length],
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
