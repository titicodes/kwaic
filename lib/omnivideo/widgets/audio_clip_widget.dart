import 'package:flutter/material.dart';

import '../model/audio_track.dart';

class AudioClipWidget extends StatelessWidget {
  final AudioTrack track;
  final double pixelsPerSecond;

  const AudioClipWidget({
    super.key,
    required this.track,
    required this.pixelsPerSecond,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: track.start * pixelsPerSecond,
      width: track.duration * pixelsPerSecond,
      top: 0,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.greenAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.audiotrack),
      ),
    );
  }
}
