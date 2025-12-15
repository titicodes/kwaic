// servuices/audio_video_sync.dart

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../model/timeline_item.dart';

class AudioVideoSync {
  final Map<String, AudioPlayer> _audioPlayers = {};

  // Pass the audio items and their players (you'll populate this from your editor)
  AudioVideoSync(Map<String, AudioPlayer> audioPlayers) {
    _audioPlayers.addAll(audioPlayers);
  }

  /// Plays only the audio tracks that are active at the current playhead position
  Future<void> playAudioTracks({
    required List<TimelineItem> audioItems,
    required ValueNotifier<Duration> playhead,
    required bool isPlaying,
  }) async {
    if (!isPlaying) return;

    final currentPos = playhead.value;

    for (final audio in audioItems) {
      final player = _audioPlayers[audio.id];
      if (player == null) continue;

      final inRange = currentPos >= audio.startTime &&
          currentPos < audio.startTime + audio.duration;

      if (inRange) {
        final targetPos = audio.trimStart + (currentPos - audio.startTime);

        // Seek if too far off (prevents drift)
        if ((player.position - targetPos).abs() > const Duration(milliseconds: 180)) {
          try {
            await player.seek(targetPos);
          } catch (e) {
            debugPrint("Audio seek failed: $e");
          }
        }

        // Set volume
        await player.setVolume(audio.volume);

        // Play if not already playing
        if (!player.playing) {
          await player.play();
        }
      } else {
        // Stop audio that's outside the active range
        if (player.playing) {
          await player.pause();
        }
      }
    }
  }

  /// Pause all audio players
  Future<void> pauseAllAudio() async {
    for (final player in _audioPlayers.values) {
      if (player.playing) {
        await player.pause();
      }
    }
  }

  /// Optional: Stop + dispose all players when editor closes
  Future<void> dispose() async {
    for (final player in _audioPlayers.values) {
      await player.pause();
      await player.dispose();
    }
    _audioPlayers.clear();
  }
}