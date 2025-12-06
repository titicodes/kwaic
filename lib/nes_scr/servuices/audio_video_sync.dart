import 'package:video_player/video_player.dart';

import '../model/timeline_item.dart';

class AudioVideoSync {
  final Map<String, VideoPlayerController> audioControllers;
  final List<TimelineItem> audioItems;

  AudioVideoSync(this.audioControllers, this.audioItems);

  Future<void> syncAtPosition(Duration position) async {
    for (final audio in audioItems) {
      if (position >= audio.startTime &&
          position < audio.startTime + audio.duration) {
        final ctrl = audioControllers[audio.id];
        if (ctrl != null && ctrl.value.isInitialized) {
          final localPos = position - audio.startTime;
          final sourcePos = audio.trimStart + localPos;

          // Sync audio playback
          if ((ctrl.value.position - sourcePos).abs() >
              const Duration(milliseconds: 100)) {
            await ctrl.seekTo(sourcePos);
          }

          await ctrl.setVolume(audio.volume);
        }
      }
    }
  }

  Future<void> play() async {
    for (final ctrl in audioControllers.values) {
      if (ctrl.value.isInitialized) {
        await ctrl.play();
      }
    }
  }

  Future<void> pause() async {
    for (final ctrl in audioControllers.values) {
      if (ctrl.value.isInitialized) {
        await ctrl.pause();
      }
    }
  }
}
