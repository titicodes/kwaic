

import 'package:flutter/material.dart';
import 'audio_manager.dart';
import 'video_manager.dart';
import '../model/timeline_item.dart';

/// Manages playback state and controls
class PlaybackController extends ChangeNotifier {
  final VideoManager videoManager;
  final AudioManager audioManager;
  bool _isPlaying = false;
  Duration _playheadPosition = Duration.zero;
  List<TimelineItem> _currentClips = [];
  List<TimelineItem> _currentAudioItems = [];

  bool get isPlaying => _isPlaying;
  Duration get playheadPosition => _playheadPosition;

  PlaybackController({
    required this.videoManager,
    required this.audioManager,
  }) {
    videoManager.onGlobalPositionUpdated = _handlePositionUpdate;
  }

  /// Toggle play/pause
  Future<void> togglePlayPause({
    required List<TimelineItem> clips,
    required List<TimelineItem> audioItems,
  }) async {
    if (videoManager.activeController == null ||
        !videoManager.activeController!.value.isInitialized) {
      debugPrint('⚠️ PlaybackController: No video loaded');
      return;
    }

    _isPlaying = !_isPlaying;
    _currentClips = clips;
    _currentAudioItems = audioItems;
    notifyListeners();

    if (_isPlaying) {
      // Wait for video frame to be ready
      int attempts = 0;
      while (attempts < 30 && !videoManager.isVideoFrameReady) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }

      await videoManager.play();
      await audioManager.playAll(
        audioItems: audioItems,
        playheadPosition: _playheadPosition,
      );
    } else {
      await videoManager.pause();
      await audioManager.pauseAll();
    }
  }

  /// Seek to a specific position
  Future<void> seekTo(
      Duration position, {
        required List<TimelineItem> clips,
        required List<TimelineItem> audioItems,
      }) async {
    _playheadPosition = position;
    _currentClips = clips;
    _currentAudioItems = audioItems;
    notifyListeners();

    // Find active clip at this position
    final activeClip = _findClipAtPosition(clips, position);
    if (activeClip != null) {
      await videoManager.switchToClip(
        activeClip,
        playheadPosition: position,
        isPlaying: _isPlaying,
      );
    } else {
      await stop();
      return;
    }

    // Sync audio
    await audioManager.syncAll(
      audioItems: audioItems,
      playheadPosition: position,
    );
  }

  /// Internal handler for position updates from VideoManager
  void _handlePositionUpdate(Duration globalPosition) {
    _playheadPosition = globalPosition;
    notifyListeners();

    // Check if near end of current clip and advance if needed
    final activeItem = videoManager.activeItem;
    if (activeItem != null && isPlaying) {
      final effectiveDuration = Duration(
        milliseconds: (activeItem.duration.inMilliseconds / activeItem.speed).round(),
      );
      if (globalPosition >= activeItem.startTime + effectiveDuration - const Duration(milliseconds: 50)) {
        final nextEnd = activeItem.startTime + effectiveDuration;
        final nextClip = _findNextClip(_currentClips, nextEnd);
        if (nextClip != null) {
          seekTo(
            nextClip.startTime,
            clips: _currentClips,
            audioItems: _currentAudioItems,
          );
        } else {
          stop();
        }
      }
    }
  }

  /// Stop playback
  Future<void> stop() async {
    _isPlaying = false;
    _playheadPosition = Duration.zero;
    await videoManager.pause();
    await audioManager.pauseAll();
    await audioManager.seekAll(Duration.zero);
    notifyListeners();
  }

  /// Find the clip at a specific playhead position
  TimelineItem? _findClipAtPosition(
      List<TimelineItem> clips,
      Duration position,
      ) {
    for (final clip in clips) {
      final effectiveDuration = Duration(
        milliseconds: (clip.duration.inMilliseconds / clip.speed).round(),
      );
      if (position >= clip.startTime &&
          position < clip.startTime + effectiveDuration) {
        return clip;
      }
    }
    return null;
  }

  /// Find the next clip after a given time
  TimelineItem? _findNextClip(List<TimelineItem> clips, Duration currentEnd) {
    if (clips.isEmpty) return null;
    var sortedClips = [...clips]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    for (final clip in sortedClips) {
      if (clip.startTime >= currentEnd) {
        return clip;
      }
    }
    return null;
  }

  /// Get total timeline duration
  double getTotalDuration(List<List<TimelineItem>> allTracks) {
    double max = 0;
    for (final track in allTracks) {
      if (track.isEmpty) continue;
      final end = track
          .map((e) => (e.startTime + e.duration).inSeconds.toDouble())
          .reduce((a, b) => a > b ? a : b);
      if (end > max) max = end;
    }
    return max;
  }
}