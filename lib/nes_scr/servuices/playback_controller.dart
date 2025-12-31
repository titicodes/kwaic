import 'package:flutter/material.dart';
import 'audio_manager.dart';
import 'video_manager.dart';
import '../model/timeline_item.dart';
import '../servuices/time_line_controller.dart';
import '../servuices/clip_controller.dart'; // ← ADD THIS IMPORT

class PlaybackController extends ChangeNotifier {
  final VideoManager videoManager;
  final AudioManager audioManager;
  final TimelineController timelineController;
  final ClipController clipController; // ← ADD THIS

  bool _isPlaying = false;

  PlaybackController({
    required this.videoManager,
    required this.audioManager,
    required this.timelineController,
    required this.clipController, // ← ADD THIS
  }) {
    // Listen to timeline currentTime changes (scrubbing, tap)
    timelineController.addListener(_onTimelineTimeChanged);

    // Video position updates timeline during playback
    videoManager.onGlobalPositionUpdated = _handleVideoPositionUpdate;
  }

  bool get isPlaying => _isPlaying;

  // Master time comes from timeline
  Duration get playheadPosition => timelineController.currentTime;

  Future<void> togglePlayPause() async {
    if (videoManager.activeController == null ||
        !videoManager.activeController!.value.isInitialized) {
      return;
    }

    _isPlaying = !_isPlaying;
    notifyListeners();

    if (_isPlaying) {
      await videoManager.play();
      await audioManager.playAll(
        audioItems: clipController.audioClips,
        playheadPosition: timelineController.currentTime,
      );
    } else {
      await videoManager.pause();
      await audioManager.pauseAll();
    }
  }

  // Called when user scrubs or taps timeline
  Future<void> seekTo(Duration position) async {
    timelineController.currentTime = position;
    final clip = clipController.getActiveVideoClip(position);
    if (clip == null) {
      videoManager.clear();
      return;
    }
    await videoManager.forceFrameAt(position);
  }


  // During playback: video position drives timeline time
  void _handleVideoPositionUpdate(Duration globalPosition) {
    if (!_isPlaying) return;

    // Quiet update to avoid excessive rebuilds
    timelineController.updateTimeQuietly(globalPosition);
    notifyListeners();

    final activeItem = videoManager.activeItem;
    if (activeItem == null) return;

    final effectiveDuration = Duration(
      milliseconds: (activeItem.duration.inMilliseconds / activeItem.speed).round(),
    );

    if (globalPosition >=
        activeItem.startTime + effectiveDuration - const Duration(milliseconds: 50)) {
      final nextClip = _findNextClip(
        clipController.videoClips,
        activeItem.startTime + effectiveDuration,
      );

      if (nextClip != null) {
        videoManager.switchToClip(
          nextClip,
          playheadPosition: nextClip.startTime,
          isPlaying: true,
        );
        timelineController.currentTime = nextClip.startTime;
      } else {
        _isPlaying = false;
        stop();
        notifyListeners();
      }
    } else {
      if ((timelineController.currentTime - globalPosition).abs() > const Duration(milliseconds: 80)) {
        videoManager.syncToPlayhead(globalPosition);
      }
      notifyListeners();
    }
  }

  // When timeline time changes (scrubbing/tap), force preview to match
  void _onTimelineTimeChanged() {
    if (_isPlaying) return; // Let video drive during playback
    final time = timelineController.currentTime;
    videoManager.forceFrameAt(time);
  }

  Future<void> stop() async {
    _isPlaying = false;
    timelineController.currentTime = Duration.zero;
    await videoManager.pause();
    await audioManager.pauseAll();
    await audioManager.seekAll(Duration.zero);
    videoManager.refreshCurrentFrame(); // Ensure state update after pause
    notifyListeners();
  }


  TimelineItem? _findNextClip(List<TimelineItem> clips, Duration currentEnd) {
    final sorted = [...clips]..sort((a, b) => a.startTime.compareTo(b.startTime));
    for (final clip in sorted) {
      if (clip.startTime >= currentEnd) return clip;
    }
    return null;
  }

  @override
  void dispose() {
    timelineController.removeListener(_onTimelineTimeChanged);
    super.dispose();
  }
}
