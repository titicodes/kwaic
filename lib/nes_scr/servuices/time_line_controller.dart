
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kwaic/nes_scr/servuices/playback_controller.dart';
import '../model/timeline_item.dart';

/// TimelineController - The MASTER time source
/// All time flows through here. Preview is a slave that follows.
class TimelineController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();

  double _pixelsPerSecond = 90.0;
  final double _minPixelsPerSecond = 40.0;
  final double _maxPixelsPerSecond = 420.0;
  double _timelineOffset = 0.0;

  TimelineDisplayMode _displayMode = TimelineDisplayMode.allTracks;
  bool _isTrimMode = false;
  String? _trimClipId;
  bool _trimAtStart = false;

  // 🎯 MASTER CURRENT TIME — single source of truth
  Duration _currentTime = Duration.zero;

  // 🎯 REAL TOTAL DURATION — calculated from longest clip + speed
  Duration _totalDuration = const Duration(seconds: 30);

  // Track if time was changed externally (for preventing loops)
  bool _isUpdatingTime = false;

  TimelineController() {
    scrollController.addListener(() {
      _timelineOffset = scrollController.offset;
      notifyListeners();
    });
  }

// 🎯 MAIN currentTime setter — single source of truth
  set currentTime(Duration value) {
    if (_isUpdatingTime) return;

    final clamped = value.clamp(Duration.zero, _totalDuration);
    if (_currentTime != clamped) {
      _isUpdatingTime = true;
      _currentTime = clamped;
      notifyListeners();  // Always notify — PlaybackController will control quiet updates
      _isUpdatingTime = false;
    }
  }

  // Getters
  double get pixelsPerSecond => _pixelsPerSecond;
  double get timelineOffset => _timelineOffset;
  TimelineDisplayMode get displayMode => _displayMode;
  bool get isTrimMode => _isTrimMode;
  String? get trimClipId => _trimClipId;
  bool get trimAtStart => _trimAtStart;
  Duration get totalDuration => _totalDuration;
  Duration get currentTime => _currentTime;

  // 🎯 Setter for totalDuration — clips update this
  set totalDuration(Duration value) {
    if (_totalDuration != value) {
      _totalDuration = value;
      // Clamp current time if it exceeds new total
      if (_currentTime > _totalDuration) {
        _currentTime = _totalDuration;
      }
      notifyListeners();
    }
  }

  // 🎯 Update time without notifying (used during playback to reduce overhead)
  void updateTimeQuietly(Duration value) {
    final clamped = value.clamp(Duration.zero, _totalDuration);
    if (_currentTime != clamped) {
      _currentTime = clamped;
      // Don't call notifyListeners() — let the playback loop handle it
    }
  }

  // 🎯 Tap → update master time
  Duration handleTimelineTap(Offset tapPosition, double screenWidth) {
    final centerX = screenWidth / 2;
    final tapX = tapPosition.dx;
    final seconds = (_timelineOffset + tapX - centerX) / _pixelsPerSecond;
    final newTime = Duration(
      milliseconds: (seconds.clamp(0, totalDuration.inSeconds) * 1000).round(),
    );
    currentTime = newTime;
    return newTime;
  }

  void handleZoom(double scale) {
    final newValue = (_pixelsPerSecond * scale)
        .clamp(_minPixelsPerSecond, _maxPixelsPerSecond);
    if (_pixelsPerSecond != newValue) {
      _pixelsPerSecond = newValue;
      notifyListeners();
    }
  }

  void scrollToTime(Duration time, double screenWidth, {bool animate = false}) {
    if (!scrollController.hasClients) return;

    final centerX = screenWidth / 2;
    final targetOffset = (time.inMilliseconds / 1000 * _pixelsPerSecond) - centerX;
    final clamped = targetOffset.clamp(0.0, scrollController.position.maxScrollExtent);

    if (animate) {
      scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    } else {
      scrollController.jumpTo(clamped);
    }
  }

  void setDisplayMode(TimelineDisplayMode mode) {
    _displayMode = mode;
    notifyListeners();
  }

  bool shouldShowVideoTrack() => true;
  bool shouldShowAudioTrack() =>
      _displayMode == TimelineDisplayMode.allTracks ||
          _displayMode == TimelineDisplayMode.videoAudioOnly;
  bool shouldShowTextTrack() =>
      _displayMode == TimelineDisplayMode.allTracks ||
          _displayMode == TimelineDisplayMode.videoTextOnly;
  bool shouldShowOverlayTrack() =>
      _displayMode == TimelineDisplayMode.allTracks ||
          _displayMode == TimelineDisplayMode.videoOverlayOnly;

  // TRIM MODE
  void enterTrimMode(String clipId, {bool atStart = true}) {
    _isTrimMode = true;
    _trimClipId = clipId;
    _trimAtStart = atStart;
    notifyListeners();
  }

  void exitTrimMode() {
    _isTrimMode = false;
    _trimClipId = null;
    _trimAtStart = false;
    notifyListeners();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}