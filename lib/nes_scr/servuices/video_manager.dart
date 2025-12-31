import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kwaic/nes_scr/servuices/time_line_controller.dart';
import 'package:video_player/video_player.dart';
import '../model/timeline_item.dart';
import 'clip_controller.dart';

/// Manages all VideoPlayerController instances and operations
class VideoManager extends ChangeNotifier {
  final Map<String, VideoPlayerController> _controllers = {};
  VideoPlayerController? _activeController;
  TimelineItem? _activeItem;
  bool _isInitialized = false;
  final ClipController clipController;
  final TimelineController timelineController;
  Timer? _driftCorrectionTimer;

  VideoManager({
    required this.clipController,
    required this.timelineController
  });

  late void Function(Duration) onGlobalPositionUpdated;

  bool get isInitialized => _isInitialized;
  VideoPlayerController? get activeController => _activeController;
  TimelineItem? get activeItem => _activeItem;

  VideoPlayerController? backgroundVideoController;


  VideoPlayerController getControllerForClip(TimelineItem clip) {
    return _controllers[clip.id]!;
  }

  Future<VideoPlayerController?> initializeController(TimelineItem item) async {
    if (_controllers.containsKey(item.id)) return _controllers[item.id];

    try {
      final controller = VideoPlayerController.file(item.file!);
      await controller.initialize();

      // FINAL FIX: Eliminate black first frame
      await controller.seekTo(const Duration(milliseconds: 100));
      await Future.delayed(const Duration(milliseconds: 400)); // Critical wait
      await controller.seekTo(Duration.zero);
      await Future.delayed(const Duration(milliseconds: 100)); // Extra safety

      _controllers[item.id] = controller;
      notifyListeners();
      return controller;
    } catch (e) {
      debugPrint('Failed to initialize ${item.id}: $e');
      return null;
    }
  }

  Future<void> forceFrameAt(Duration globalTime) async {
    final clip = clipController.getActiveVideoClip(globalTime);

    if (clip == null) {
      await clearAndHoldBlack();
      return;
    }

    // Switch clip if needed
    if (activeItem?.id != clip.id) {
      await switchToClip(
        clip,
        playheadPosition: globalTime,
        isPlaying: false,
      );
    }

    final controller = activeController;
    if (controller == null || !controller.value.isInitialized) return;

    final localTime =
    (globalTime - clip.startTime).clamp(Duration.zero, clip.duration);

    // 🔑 FORCE SEEK EVEN IF PAUSED
    await controller.seekTo(localTime);
  }

  Future<void> clearAndHoldBlack() async {
    await pause();
    // Do NOT dispose controller
    // Just stop rendering
  }

  Timer? _scrubTimer;
  Duration? _pendingScrubPosition;
  TimelineItem? _pendingScrubItem;
  double _aspectRatio = 16 / 9;
  double get aspectRatio => _aspectRatio;


  bool isVideoFrameReady = false;

  bool isScrubbing = false;

  void clear() {
    if (activeController != null) {
      activeController!.pause();
    }

    activeController = null;
    activeItem = null;
    isVideoFrameReady = false;

    notifyListeners();
  }

  TimelineItem? getActiveClip(Duration position) {
    for (final clip in clipController.videoClips) {
      final end = clip.startTime + clip.duration;
      if (position >= clip.startTime && position < end) {
        return clip;
      }
    }
    return null;
  }


  bool _isScrubbing = false;

  void beginScrub() {
    _isScrubbing = true;
  }

  void endScrub() {
    _isScrubbing = false;
  }

  Timer? _scrubFrameTimer;

  void setAspectRatio(double ratio) {
    if (_aspectRatio != ratio) {
      _aspectRatio = ratio;
      notifyListeners();
    }
  }

  void requestScrub(Duration globalPosition, TimelineItem item) {
    _pendingScrubPosition = globalPosition;
    _pendingScrubItem = item;

    // Throttle to ~30fps
    _scrubTimer ??= Timer(const Duration(milliseconds: 32), () async {
      final pos = _pendingScrubPosition;
      final clip = _pendingScrubItem;

      _pendingScrubPosition = null;
      _pendingScrubItem = null;
      _scrubTimer = null;

      if (pos != null && clip != null) {
        await forceFrameUpdateForScrub(pos, clip);
      }
    });
  }


  Future<void> initializeBackgroundController(File file) async {
    backgroundVideoController?.dispose();
    backgroundVideoController = VideoPlayerController.file(file);
    await backgroundVideoController!.initialize();
    backgroundVideoController!.setLooping(true);
    backgroundVideoController!.play();
  }

  void disposeBackgroundController() {
    backgroundVideoController?.dispose();
    backgroundVideoController = null;
  }


  // In VideoManager class
  set activeController(VideoPlayerController? controller) {
    _activeController = controller;
    notifyListeners();
  }

  // In VideoManager class
  set activeItem(TimelineItem? item) {
    _activeItem = item;
    notifyListeners();
  }

  Future<void> syncToPlayhead(Duration position) async {
    final clip = getActiveClip(position);

    if (clip == null) return;

    if (activeItem?.id != clip.id) {
      await switchToClip(
        clip,
        playheadPosition: position,
        isPlaying: false,
      );
      return;
    }

    final controller = activeController;
    if (controller == null || !controller.value.isInitialized) return;

    final local =
    (position - clip.startTime).clamp(Duration.zero, clip.duration);

    final diff =
    (controller.value.position.inMilliseconds - local.inMilliseconds).abs();

    if (diff > 80) {
      await controller.seekTo(local);
    }
  }


  Future<void> seekTo(Duration globalPosition) async {
    final active = activeController;
    if (active != null && active.value.isInitialized) {
      final local = globalPosition - (activeItem?.startTime ?? Duration.zero);
      final clamped = local.clamp(Duration.zero, activeItem?.duration ?? Duration.zero);
      await active.seekTo(clamped);
      notifyListeners();
    }
  }

  /// Force refresh current frame (critical for scrubbing & end-of-playback)
  Future<void> refreshCurrentFrame() async {
    final ctrl = _activeController;
    if (ctrl == null || !ctrl.value.isInitialized) {
      notifyListeners();
      return;
    }
    final pos = ctrl.value.position;
    await ctrl.seekTo(pos + const Duration(milliseconds: 1));
    await Future.delayed(const Duration(milliseconds: 30));
    await ctrl.seekTo(pos);
    notifyListeners();
  }

  /// Switch to a different video clip
  Future<void> switchToClip(
      TimelineItem item, {
        required Duration playheadPosition,
        required bool isPlaying,
        VoidCallback? onFrameReady,
      })
  async {

    if (_isScrubbing) {
      _activeItem = item;
      _activeController = _controllers[item.id];
      notifyListeners();
      return;
    }

    final ctrl = _controllers[item.id];
    if (ctrl == null || !ctrl.value.isInitialized) {
      debugPrint('Controller not ready or disposed for ${item.id}');
      _activeController = null;
      _activeItem = null;
      notifyListeners();
      return;
    }
    // Remove listener from old controller
    _activeController?.removeListener(_positionListener);

    _activeController = ctrl;
    _activeItem = item;

    // Add new listener
    _activeController!.addListener(_positionListener);

    // Calculate local position within clip
    final local = (playheadPosition - item.startTime).clamp(
      Duration.zero,
      item.duration,
    );
    final sourcePos = item.trimStart +
        Duration(milliseconds: (local.inMilliseconds / item.speed).round());
    final targetSpeed = _getCurrentSpeed(item, local).clamp(0.25, 2.0);

    try {
      await ctrl.setVolume(item.volume);
      await ctrl.setPlaybackSpeed(targetSpeed);
      await Future.delayed(const Duration(milliseconds: 80));

      // Handle seeking to start position
      if (sourcePos <= Duration.zero) {
        await ctrl.seekTo(const Duration(milliseconds: 100));
        await Future.delayed(const Duration(milliseconds: 150));
        await ctrl.seekTo(Duration.zero);
      } else {
        await ctrl.seekTo(sourcePos);
      }

      // Wait for frame to be ready
      int attempts = 0;
      while (attempts < 30 && !isVideoFrameReady) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }

      if (isPlaying) {
        await ctrl.play();
      } else {
        await ctrl.pause();
      }

      // Always force frame refresh after switch
      await refreshCurrentFrame();
      onFrameReady?.call();

      notifyListeners();
    } catch (e) {
      debugPrint('❌ VideoManager: Switch error: $e');
    }
  }

  /// Force refresh when scrubbing same clip
  Future<void> forceFrameUpdateForScrub(Duration playheadPosition, TimelineItem item) async {
    final local = (playheadPosition - item.startTime).clamp(Duration.zero, item.duration);
    final sourcePos = item.trimStart + Duration(milliseconds: (local.inMilliseconds / item.speed).round());

    final ctrl = _activeController;
    if (ctrl != null && ctrl.value.isInitialized) {
      await ctrl.seekTo(sourcePos);
      await refreshCurrentFrame(); // Double refresh trick
    }
  }


  /// Listener for video position changes
  void _positionListener() {
    if (_isScrubbing) return;
    if (_activeController == null || _activeItem == null || !_activeController!.value.isPlaying) {
      return;
    }

    final sourcePos = _activeController!.value.position;
    final localDuration = sourcePos - _activeItem!.trimStart;

    // IMPROVED: Use current speed at local position (handles speed curves)
    final currentSpeed = _getCurrentSpeed(_activeItem!, localDuration);
    final localMs = localDuration.inMilliseconds * currentSpeed;

    final global = _activeItem!.startTime + Duration(milliseconds: localMs.round());
    onGlobalPositionUpdated(global);
  }

  /// Update video position and speed
  Future<void> updatePlayback(
      TimelineItem item, {
        required Duration localPosition,
        required bool isPlaying,
      }) async {
    final ctrl = _controllers[item.id];
    if (ctrl == null || !ctrl.value.isInitialized) return;
    await ctrl.setVolume(item.volume);
    final currentSpeed = _getCurrentSpeed(item, localPosition);
    final sourcePos = item.trimStart +
        Duration(milliseconds: (localPosition.inMilliseconds / currentSpeed).round());
    final targetSpeed = currentSpeed.clamp(0.25, 2.0);

    try {
      // Update speed if changed significantly
      if ((ctrl.value.playbackSpeed - targetSpeed).abs() > 0.05) {
        await ctrl.setPlaybackSpeed(targetSpeed);
        await Future.delayed(const Duration(milliseconds: 60));
      }

      // Seek if position drift is too large
      final diff = (sourcePos - ctrl.value.position).abs();
      if (diff > const Duration(milliseconds: 300)) {
        await ctrl.seekTo(sourcePos);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ VideoManager: Update error: $e');
    }
  }

  /// Get current speed considering speed curves
  double _getCurrentSpeed(TimelineItem item, Duration localTime) {
    if (item.speedPoints.isEmpty) return item.speed;

    final progress = localTime.inMilliseconds / item.originalDuration.inMilliseconds;
    SpeedPoint? prev;
    for (final point in item.speedPoints) {
      if (progress <= point.time) {
        if (prev == null) return point.speed.clamp(0.25, 2.0);
        final t = (progress - prev.time) / (point.time - prev.time);
        return (prev.speed + (point.speed - prev.speed) * t).clamp(0.25, 2.0);
      }
      prev = point;
    }
    return item.speedPoints.last.speed.clamp(0.25, 2.0);
  }

  /// Play all active controllers
  Future<void> play() async {
    if (_activeController?.value.isInitialized == true) {
      await _activeController!.play();
      notifyListeners();

      _driftCorrectionTimer?.cancel();
      _driftCorrectionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (_activeController?.value.isPlaying ?? false) {
          syncToPlayhead(timelineController.currentTime);
        }
      });
    }
  }

  /// Pause all active controllers
  Future<void> pause() async {
    if (_activeController?.value.isInitialized == true) {
      await _activeController!.pause();
      notifyListeners();
      _driftCorrectionTimer?.cancel();
      _driftCorrectionTimer = null;
    }
  }

  /// Seek active controller to position
  Future<void> seek(Duration position) async {
    if (_activeController?.value.isInitialized == true) {
      await _activeController!.seekTo(position);
      notifyListeners();
    }
  }

  /// Get controller for a specific item
  VideoPlayerController? getController(String itemId) {
    return _controllers[itemId];
  }

  /// Remove controller for an item
  void removeController(String itemId) {
    final ctrl = _controllers.remove(itemId);
    if (ctrl != null) {
      if (_activeController == ctrl) {
        _activeController?.removeListener(_positionListener);
        _activeController = null;
        _activeItem = null;
      }
      ctrl.pause();
      ctrl.dispose();
      notifyListeners();
    }
  }

  /// Share controller between duplicate items
  void shareController(String sourceId, String targetId) {
    final ctrl = _controllers[sourceId];
    if (ctrl != null) {
      _controllers[targetId] = ctrl;
      notifyListeners();
    }
  }

  /// Clear all controllers
  @override
  void dispose() {
    _driftCorrectionTimer?.cancel();
    _activeController?.removeListener(_positionListener);
    for (final ctrl in _controllers.values) {
      ctrl.pause();
      ctrl.dispose();
    }
    _controllers.clear();
    _activeController = null;
    _activeItem = null;
    super.dispose();
  }
}