// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import '../model/timeline_item.dart';
//
// /// Manages all VideoPlayerController instances and operations
// class VideoManager extends ChangeNotifier {
//   final Map<String, VideoPlayerController> _controllers = {};
//   VideoPlayerController? _activeController;
//   TimelineItem? _activeItem;
//
//   bool _isInitialized = false;
//   bool get isInitialized => _isInitialized;
//
//   VideoPlayerController? get activeController => _activeController;
//   TimelineItem? get activeItem => _activeItem;
//
//   /// Check if current video has a visible frame
//   bool get isVideoFrameReady {
//     final ctrl = _activeController;
//     if (ctrl == null || !ctrl.value.isInitialized) return false;
//     return ctrl.value.position > Duration.zero;
//   }
//
//   /// Returns the aspect ratio of the currently active video, or null if not available
//   double? get aspectRatio {
//     final controller = _activeController;
//     if (controller == null || !controller.value.isInitialized) {
//       return null;
//     }
//
//     final size = controller.value.size;
//     if (size.width <= 0 || size.height <= 0) return null;
//
//     return size.width / size.height;
//   }
//   /// Initialize a video controller for a timeline item
//   Future<VideoPlayerController?> initializeController(
//       TimelineItem item,
//       ) async {
//     if (_controllers.containsKey(item.id)) {
//       return _controllers[item.id];
//     }
//
//     try {
//       final controller = VideoPlayerController.file(item.file!);
//       await controller.initialize();
//
//       // Seek to start to ensure frame is loaded
//       await controller.seekTo(const Duration(milliseconds: 100));
//       await Future.delayed(const Duration(milliseconds: 250));
//       await controller.seekTo(Duration.zero);
//
//       _controllers[item.id] = controller;
//       notifyListeners();
//
//       return controller;
//     } catch (e) {
//       debugPrint('❌ VideoManager: Failed to initialize ${item.id}: $e');
//       return null;
//     }
//   }
//
//   /// Switch to a different video clip
//   Future<void> switchToClip(
//       TimelineItem item, {
//         required Duration playheadPosition,
//         required bool isPlaying,
//         VoidCallback? onFrameReady,
//       }) async {
//     final ctrl = _controllers[item.id];
//     if (ctrl == null || !ctrl.value.isInitialized) {
//       debugPrint('❌ VideoManager: Controller not ready for ${item.id}');
//       return;
//     }
//
//     // Remove listener from old controller
//     _activeController?.removeListener(() {});
//
//     _activeController = ctrl;
//     _activeItem = item;
//
//     // Calculate local position within clip
//     final local = (playheadPosition - item.startTime).clamp(
//       Duration.zero,
//       item.duration,
//     );
//
//     final sourcePos = item.trimStart +
//         Duration(milliseconds: (local.inMilliseconds / item.speed).round());
//
//     final targetSpeed = _getCurrentSpeed(item, local).clamp(0.25, 2.0);
//
//     try {
//       await ctrl.setVolume(item.volume);
//       await ctrl.setPlaybackSpeed(targetSpeed);
//       await Future.delayed(const Duration(milliseconds: 80));
//
//       // Handle seeking to start position
//       if (sourcePos <= Duration.zero) {
//         await ctrl.seekTo(const Duration(milliseconds: 100));
//         await Future.delayed(const Duration(milliseconds: 150));
//         await ctrl.seekTo(Duration.zero);
//       } else {
//         await ctrl.seekTo(sourcePos);
//       }
//
//       // Wait for frame to be ready
//       int attempts = 0;
//       while (attempts < 30 && !isVideoFrameReady) {
//         await Future.delayed(const Duration(milliseconds: 50));
//         attempts++;
//       }
//
//       if (isPlaying) {
//         await ctrl.play();
//       }
//
//       onFrameReady?.call();
//       notifyListeners();
//     } catch (e) {
//       debugPrint('❌ VideoManager: Switch error: $e');
//     }
//   }
//
//   /// Update video position and speed
//   Future<void> updatePlayback(
//       TimelineItem item, {
//         required Duration localPosition,
//         required bool isPlaying,
//       }) async {
//     final ctrl = _controllers[item.id];
//     if (ctrl == null || !ctrl.value.isInitialized) return;
//
//     final currentSpeed = _getCurrentSpeed(item, localPosition);
//     final sourcePos = item.trimStart +
//         Duration(milliseconds: (localPosition.inMilliseconds / currentSpeed).round());
//
//     final targetSpeed = currentSpeed.clamp(0.25, 2.0);
//
//     try {
//       // Update speed if changed significantly
//       if ((ctrl.value.playbackSpeed - targetSpeed).abs() > 0.05) {
//         await ctrl.setPlaybackSpeed(targetSpeed);
//         await Future.delayed(const Duration(milliseconds: 60));
//       }
//
//       // Seek if position drift is too large
//       final diff = (sourcePos - ctrl.value.position).abs();
//       if (diff > const Duration(milliseconds: 300)) {
//         await ctrl.seekTo(sourcePos);
//         await Future.delayed(const Duration(milliseconds: 50));
//       }
//
//       notifyListeners();
//     } catch (e) {
//       debugPrint('❌ VideoManager: Update error: $e');
//     }
//   }
//
//   /// Get current speed considering speed curves
//   double _getCurrentSpeed(TimelineItem item, Duration localTime) {
//     if (item.speedPoints.isEmpty) return item.speed;
//
//     final progress = localTime.inMilliseconds / item.originalDuration.inMilliseconds;
//     SpeedPoint? prev;
//
//     for (final point in item.speedPoints) {
//       if (progress <= point.time) {
//         if (prev == null) return point.speed.clamp(0.25, 2.0);
//         final t = (progress - prev.time) / (point.time - prev.time);
//         return (prev.speed + (point.speed - prev.speed) * t).clamp(0.25, 2.0);
//       }
//       prev = point;
//     }
//
//     return item.speedPoints.last.speed.clamp(0.25, 2.0);
//   }
//
//   /// Play all active controllers
//   Future<void> play() async {
//     if (_activeController?.value.isInitialized == true) {
//       await _activeController!.play();
//       notifyListeners();
//     }
//   }
//
//   /// Pause all active controllers
//   Future<void> pause() async {
//     if (_activeController?.value.isInitialized == true) {
//       await _activeController!.pause();
//       notifyListeners();
//     }
//   }
//
//   /// Seek active controller to position
//   Future<void> seek(Duration position) async {
//     if (_activeController?.value.isInitialized == true) {
//       await _activeController!.seekTo(position);
//       notifyListeners();
//     }
//   }
//
//   /// Get controller for a specific item
//   VideoPlayerController? getController(String itemId) {
//     return _controllers[itemId];
//   }
//
//   /// Remove controller for an item
//   void removeController(String itemId) {
//     final ctrl = _controllers.remove(itemId);
//     if (ctrl != null) {
//       ctrl.pause();
//       ctrl.dispose();
//
//       if (_activeController == ctrl) {
//         _activeController = null;
//         _activeItem = null;
//       }
//
//       notifyListeners();
//     }
//   }
//
//   /// Share controller between duplicate items
//   void shareController(String sourceId, String targetId) {
//     final ctrl = _controllers[sourceId];
//     if (ctrl != null) {
//       _controllers[targetId] = ctrl;
//       notifyListeners();
//     }
//   }
//
//   /// Clear all controllers
//   @override
//   void dispose() {
//     for (final ctrl in _controllers.values) {
//       ctrl.pause();
//       ctrl.dispose();
//     }
//     _controllers.clear();
//     _activeController = null;
//     _activeItem = null;
//     super.dispose();
//   }
// }

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../model/timeline_item.dart';

/// Manages all VideoPlayerController instances and operations
class VideoManager extends ChangeNotifier {
  final Map<String, VideoPlayerController> _controllers = {};
  VideoPlayerController? _activeController;
  TimelineItem? _activeItem;
  bool _isInitialized = false;

  late void Function(Duration) onGlobalPositionUpdated;

  bool get isInitialized => _isInitialized;
  VideoPlayerController? get activeController => _activeController;
  TimelineItem? get activeItem => _activeItem;

  /// Check if current video has a visible frame
  bool get isVideoFrameReady {
    final ctrl = _activeController;
    if (ctrl == null || !ctrl.value.isInitialized) return false;
    return ctrl.value.position > Duration.zero;
  }

  /// Returns the aspect ratio of the currently active video, or null if not available
  double? get aspectRatio {
    final controller = _activeController;
    if (controller == null || !controller.value.isInitialized) {
      return null;
    }
    final size = controller.value.size;
    if (size.width <= 0 || size.height <= 0) return null;
    return size.width / size.height;
  }

  /// Initialize a video controller for a timeline item
  Future<VideoPlayerController?> initializeController(
      TimelineItem item,
      ) async {
    if (_controllers.containsKey(item.id)) {
      return _controllers[item.id];
    }

    try {
      final controller = VideoPlayerController.file(item.file!);
      await controller.initialize();
      // Seek to start to ensure frame is loaded
      await controller.seekTo(const Duration(milliseconds: 100));
      await Future.delayed(const Duration(milliseconds: 250));
      await controller.seekTo(Duration.zero);

      _controllers[item.id] = controller;
      notifyListeners();
      return controller;
    } catch (e) {
      debugPrint('❌ VideoManager: Failed to initialize ${item.id}: $e');
      return null;
    }
  }

  /// Switch to a different video clip
  Future<void> switchToClip(
      TimelineItem item, {
        required Duration playheadPosition,
        required bool isPlaying,
        VoidCallback? onFrameReady,
      }) async {
    final ctrl = _controllers[item.id];
    if (ctrl == null || !ctrl.value.isInitialized) {
      debugPrint('❌ VideoManager: Controller not ready for ${item.id}');
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
      }

      onFrameReady?.call();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ VideoManager: Switch error: $e');
    }
  }

  /// Listener for video position changes
  void _positionListener() {
    if (_activeController == null ||
        _activeItem == null ||
        !_activeController!.value.isPlaying) {
      return;
    }

    final sourcePos = _activeController!.value.position;
    final localMs = (sourcePos.inMilliseconds - _activeItem!.trimStart.inMilliseconds) *
        _activeItem!.speed;
    final local = Duration(milliseconds: localMs.round());
    final global = _activeItem!.startTime + local;

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
    }
  }

  /// Pause all active controllers
  Future<void> pause() async {
    if (_activeController?.value.isInitialized == true) {
      await _activeController!.pause();
      notifyListeners();
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
      ctrl.pause();
      ctrl.dispose();
      if (_activeController == ctrl) {
        _activeController = null;
        _activeItem = null;
      }
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