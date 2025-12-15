import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../model/timeline_item.dart';

/// Manages all AudioPlayer instances and synchronization
class AudioManager extends ChangeNotifier {
  final Map<String, AudioPlayer> _players = {};

  /// Initialize an audio player for a timeline item
  Future<AudioPlayer?> initializePlayer(TimelineItem item) async {
    if (_players.containsKey(item.id)) {
      return _players[item.id];
    }

    try {
      final player = AudioPlayer();
      await player.setFilePath(item.file!.path);
      await player.setVolume(item.volume);

      _players[item.id] = player;
      notifyListeners();

      return player;
    } catch (e) {
      debugPrint('❌ AudioManager: Failed to initialize ${item.id}: $e');
      return null;
    }
  }

  /// Play all audio tracks that should be active at current playhead
  Future<void> playAll({
    required List<TimelineItem> audioItems,
    required Duration playheadPosition,
  }) async {
    for (final audio in audioItems) {
      final player = _players[audio.id];
      if (player == null) continue;

      final inRange = playheadPosition >= audio.startTime &&
          playheadPosition < audio.startTime + audio.duration;

      if (inRange) {
        final targetPos = audio.trimStart + (playheadPosition - audio.startTime);

        // Sync position if drift is significant
        if ((player.position - targetPos).abs() > const Duration(milliseconds: 200)) {
          await player.seek(targetPos);
        }

        if (!player.playing) {
          await player.play();
        }
      } else {
        if (player.playing) {
          await player.pause();
        }
      }
    }
  }

  /// Pause all audio players
  Future<void> pauseAll() async {
    for (final player in _players.values) {
      try {
        if (player.playing) {
          await player.pause();
        }
      } catch (e) {
        debugPrint('❌ AudioManager: Error pausing: $e');
      }
    }
    notifyListeners();
  }

  /// Stop all audio players
  Future<void> stopAll() async {
    for (final player in _players.values) {
      try {
        await player.stop();
      } catch (e) {
        debugPrint('❌ AudioManager: Error stopping: $e');
      }
    }
    notifyListeners();
  }

  /// Seek all players to a position
  Future<void> seekAll(Duration position) async {
    for (final player in _players.values) {
      try {
        await player.seek(position);
      } catch (e) {
        debugPrint('❌ AudioManager: Error seeking: $e');
      }
    }
    notifyListeners();
  }

  /// Sync audio players with playhead position
  Future<void> syncAll({
    required List<TimelineItem> audioItems,
    required Duration playheadPosition,
  }) async {
    for (final audio in audioItems) {
      final player = _players[audio.id];
      if (player == null) continue;

      final inRange = playheadPosition >= audio.startTime &&
          playheadPosition < audio.startTime + audio.duration;

      if (inRange) {
        final targetPos = audio.trimStart + (playheadPosition - audio.startTime);
        await player.seek(targetPos);
      }
    }
  }

  /// Set volume for specific audio item
  Future<void> setVolume(String itemId, double volume) async {
    final player = _players[itemId];
    if (player != null) {
      await player.setVolume(volume.clamp(0.0, 1.0));
      notifyListeners();
    }
  }

  /// Get player for a specific item
  AudioPlayer? getPlayer(String itemId) {
    return _players[itemId];
  }

  /// Remove player for an item
  void removePlayer(String itemId) {
    final player = _players.remove(itemId);
    if (player != null) {
      player.pause();
      player.dispose();
      notifyListeners();
    }
  }

  /// Clear all players
  @override
  void dispose() {
    for (final player in _players.values) {
      player.pause();
      player.dispose();
    }
    _players.clear();
    super.dispose();
  }
}