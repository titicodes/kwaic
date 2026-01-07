import 'package:flutter/material.dart';

import '../model/video_track.dart';
import '../timeline_constants.dart';

class TiledVideoTimeline extends StatelessWidget {
  final VideoTrack track;

  const TiledVideoTimeline({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    final tileWidth = 48.0; // constant = crisp
    final clipWidth = track.duration.inMilliseconds / 1000 * pixelsPerSecond;
    final count = (clipWidth / tileWidth).ceil();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: List.generate(count, (i) {
          final index = (i % track.timelineThumbnails.length);

          return SizedBox(
            width: tileWidth,
            height: 60,
            child: Image.memory(
              track.timelineThumbnails[index],
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
            ),
          );
        }),
      ),
    );
  }
}
