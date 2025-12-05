// PART 1: Core Performance & Preview Fixes
// Add this to your existing imports
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../model/timeline_item.dart';

// =============================================================================
// 1. ROBUST VIDEO INITIALIZATION FOR LARGE FILES
// =============================================================================

class VideoInitializer {
  static Future<VideoPlayerController> initializeRobustly(String path) async {
    debugPrint('🎬 Initializing video: $path');

    final file = File(path);
    final fileSize = await file.length();
    debugPrint(
      '📦 File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
    );

    final controller = VideoPlayerController.file(file);

    // Timeout based on file size
    final timeoutSeconds = _calculateTimeout(fileSize);

    try {
      await controller.initialize().timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          throw TimeoutException('Video initialization timed out');
        },
      );

      // CRITICAL: Wait for frame to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Force seek to ensure frame loads
      await controller.seekTo(Duration.zero);
      await Future.delayed(const Duration(milliseconds: 300));

      debugPrint('✅ Video initialized: ${controller.value.duration}');
      return controller;
    } catch (e) {
      debugPrint('❌ Initialization failed: $e');
      await controller.dispose();
      rethrow;
    }
  }

  static int _calculateTimeout(int fileSize) {
    // 1-10MB: 10s, 10-50MB: 20s, 50-100MB: 30s, 100MB+: 45s
    if (fileSize < 10 * 1024 * 1024) return 10;
    if (fileSize < 50 * 1024 * 1024) return 20;
    if (fileSize < 100 * 1024 * 1024) return 30;
    return 45;
  }
}

// =============================================================================
// 2. OPTIMIZED THUMBNAIL GENERATION FOR LARGE FILES
// =============================================================================

class ThumbnailGenerator {
  static Future<List<Uint8List>> generateOptimized({
    required String videoPath,
    required Duration duration,
    int? maxThumbnails,
  }) async {
    final fileSize = await File(videoPath).length();
    final durationSec = duration.inSeconds;

    // Smart count based on file size and duration
    int count;
    if (fileSize > 100 * 1024 * 1024) {
      // Large files: 8-12 thumbnails
      count = math.min(12, math.max(8, durationSec ~/ 10));
    } else if (fileSize > 50 * 1024 * 1024) {
      // Medium files: 12-20 thumbnails
      count = math.min(20, math.max(12, durationSec ~/ 5));
    } else {
      // Small files: 15-30 thumbnails
      count = math.min(30, math.max(15, durationSec ~/ 2));
    }

    if (maxThumbnails != null) count = math.min(count, maxThumbnails);

    debugPrint('📸 Generating $count thumbnails for ${durationSec}s video');

    // Use isolate for large files
    if (fileSize > 50 * 1024 * 1024) {
      return _generateInIsolate(videoPath, duration, count);
    }

    return _generateDirect(videoPath, duration, count);
  }

  static Future<List<Uint8List>> _generateDirect(
    String path,
    Duration duration,
    int count,
  ) async {
    final thumbnails = <Uint8List>[];
    final durationMs = duration.inMilliseconds;

    for (int i = 0; i < count; i++) {
      try {
        final progress = i / (count - 1);
        final timeMs = (durationMs * progress).round().clamp(
          100,
          durationMs - 100,
        );

        final bytes = await VideoThumbnail.thumbnailData(
          video: path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 120,
          maxHeight: 120,
          timeMs: timeMs,
          quality: 70,
        ).timeout(const Duration(seconds: 5), onTimeout: () => null);

        if (bytes != null && bytes.length > 500) {
          thumbnails.add(bytes);
        }
      } catch (e) {
        debugPrint('⚠️ Thumbnail $i failed: $e');
      }
    }

    return thumbnails;
  }

  static Future<List<Uint8List>> _generateInIsolate(
    String path,
    Duration duration,
    int count,
  ) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _thumbnailIsolate,
      _ThumbnailParams(
        sendPort: receivePort.sendPort,
        videoPath: path,
        duration: duration,
        count: count,
      ),
    );

    final result = await receivePort.first as List<Uint8List>;
    return result;
  }

  static void _thumbnailIsolate(_ThumbnailParams params) async {
    final thumbnails = await _generateDirect(
      params.videoPath,
      params.duration,
      params.count,
    );
    params.sendPort.send(thumbnails);
  }
}

class _ThumbnailParams {
  final SendPort sendPort;
  final String videoPath;
  final Duration duration;
  final int count;

  _ThumbnailParams({
    required this.sendPort,
    required this.videoPath,
    required this.duration,
    required this.count,
  });
}

// =============================================================================
// 3. OPTIMIZED PREVIEW CONTROLLER
// =============================================================================

class PreviewController extends ChangeNotifier {
  VideoPlayerController? _activeController;
  TimelineItem? _activeItem;
  bool _isReady = false;
  bool _isUpdating = false;

  VideoPlayerController? get activeController => _activeController;
  TimelineItem? get activeItem => _activeItem;
  bool get isReady => _isReady;

  Future<void> updatePreview({
    required Duration playheadPosition,
    required List<TimelineItem> clips,
    required Map<String, VideoPlayerController> controllers,
    required bool isPlaying,
  }) async {
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      TimelineItem? newActive;
      for (final clip in clips) {
        final effective = Duration(
          milliseconds: (clip.duration.inMilliseconds / clip.speed).round(),
        );
        if (playheadPosition >= clip.startTime &&
            playheadPosition < clip.startTime + effective) {
          newActive = clip;
          break;
        }
      }

      if (newActive != null && controllers.containsKey(newActive.id)) {
        final newController = controllers[newActive.id]!;

        if (!newController.value.isInitialized) {
          _isUpdating = false;
          return;
        }

        if (_activeController != null && _activeController != newController) {
          await _activeController!.pause();
        }

        _activeController = newController;
        _activeItem = newActive;
        _isReady = true;

        await _updatePlaybackState(playheadPosition, isPlaying, newActive);
        notifyListeners();
      }
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _updatePlaybackState(
      Duration playheadPosition,
      bool isPlaying,
      TimelineItem item,
      ) async {
    if (_activeController == null) return;

    final local = (playheadPosition - item.startTime).clamp(
      Duration.zero,
      item.duration,
    );

    final speed = item.speed;
    final source = item.trimStart + Duration(
      milliseconds: (local.inMilliseconds * speed).round(),
    );

    final currentPos = _activeController!.value.position;
    final diff = (source - currentPos).inMilliseconds.abs();

    if (diff > 100) {
      await _activeController!.seekTo(source);
    }

    await _activeController!.setPlaybackSpeed(speed);
    await _activeController!.setVolume(item.volume);

    if (isPlaying && !_activeController!.value.isPlaying) {
      await _activeController!.play();
    } else if (!isPlaying && _activeController!.value.isPlaying) {
      await _activeController!.pause();
    }
  }

  @override
  void dispose() {
    _activeController = null;
    _activeItem = null;
    super.dispose();
  }
}
