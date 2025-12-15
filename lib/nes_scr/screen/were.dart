// import 'package:flutter/material.dart';
// import '../model/timeline_item.dart';
//
// class TimelineController extends ChangeNotifier {
//   final ScrollController scrollController = ScrollController();
//
//   double _pixelsPerSecond = 90.0;
//   final double _minPixelsPerSecond = 40.0;
//   final double _maxPixelsPerSecond = 420.0;
//
//   double _timelineOffset = 0.0;
//
//   TimelineDisplayMode _displayMode = TimelineDisplayMode.allTracks;
//
//   bool _isTrimMode = false;
//   String? _trimClipId;
//   bool _trimAtStart = false;
//
//   Duration _totalDuration = const Duration(seconds: 60);
//
//   TimelineController() {
//     scrollController.addListener(() {
//       _timelineOffset = scrollController.offset;
//       notifyListeners();
//     });
//   }
//
//   double get pixelsPerSecond => _pixelsPerSecond;
//   double get timelineOffset => _timelineOffset;
//   TimelineDisplayMode get displayMode => _displayMode;
//
//   bool get isTrimMode => _isTrimMode;
//   String? get trimClipId => _trimClipId;
//   bool get trimAtStart => _trimAtStart;
//
//   Duration get totalDuration => _totalDuration;
//
//   set totalDuration(Duration value) {
//     _totalDuration = value;
//     notifyListeners();
//   }
//
//   Duration handleTimelineTap(
//       Offset tapPosition,
//       double screenWidth,
//       ) {
//     final centerX = screenWidth / 2;
//     final tapX = tapPosition.dx;
//
//     final seconds =
//         (_timelineOffset + tapX - centerX) / _pixelsPerSecond;
//
//     final safe = Duration(
//         milliseconds: (seconds.clamp(0, totalDuration.inSeconds) * 1000).round()
//     );
//
//     return safe;
//   }
//
//   Duration handleTimelineDrag(
//       double deltaPx,
//       Duration currentPosition,
//       ) {
//     final deltaSec = deltaPx / _pixelsPerSecond;
//
//     final newPos = currentPosition +
//         Duration(milliseconds: (deltaSec * 1000).round());
//
//     return newPos.clamp(
//       Duration.zero,
//       totalDuration,
//     );
//   }
//
//   void handleZoom(double scale) {
//     final newValue = (_pixelsPerSecond * scale)
//         .clamp(_minPixelsPerSecond, _maxPixelsPerSecond);
//
//     _pixelsPerSecond = newValue;
//     notifyListeners();
//   }
//
//   void scrollToTime(
//       Duration time,
//       double screenWidth, {
//         bool animate = false,
//       }) {
//     if (!scrollController.hasClients) return;
//
//     final centerX = screenWidth / 2;
//     final targetOffset =
//         (time.inMilliseconds / 1000 * _pixelsPerSecond) - centerX;
//
//     final clampedOffset = targetOffset.clamp(
//       0.0,
//       scrollController.position.maxScrollExtent,
//     );
//
//     if (animate) {
//       scrollController.animateTo(
//         clampedOffset,
//         duration: const Duration(milliseconds: 260),
//         curve: Curves.easeOut,
//       );
//     } else {
//       scrollController.jumpTo(clampedOffset);
//     }
//   }
//
//   void setDisplayMode(TimelineDisplayMode mode) {
//     _displayMode = mode;
//     notifyListeners();
//   }
//
//   bool shouldShowVideoTrack() => true;
//   bool shouldShowAudioTrack() =>
//       _displayMode == TimelineDisplayMode.allTracks ||
//           _displayMode == TimelineDisplayMode.videoAudioOnly;
//   bool shouldShowTextTrack() =>
//       _displayMode == TimelineDisplayMode.allTracks ||
//           _displayMode == TimelineDisplayMode.videoTextOnly;
//   bool shouldShowOverlayTrack() =>
//       _displayMode == TimelineDisplayMode.allTracks ||
//           _displayMode == TimelineDisplayMode.videoOverlayOnly;
//
//   // TRIM MODE
//   void enterTrimMode(String clipId, {bool atStart = true}) {
//     _isTrimMode = true;
//     _trimClipId = clipId;
//     _trimAtStart = atStart;
//     notifyListeners();
//   }
//
//   void exitTrimMode() {
//     _isTrimMode = false;
//     _trimClipId = null;
//     _trimAtStart = false;
//     notifyListeners();
//   }
//
//   void setTrimSide(bool isStart) {
//     _trimAtStart = isStart;
//     notifyListeners();
//   }
//
//   // Helpers to compute clip metrics for UI
//   double getClipWidth(TimelineItem clip) {
//     final seconds = clip.duration.inMilliseconds / 1000 / clip.speed;
//     return (seconds * _pixelsPerSecond).clamp(50, double.infinity);
//   }
//
//   double getClipPosition(
//       TimelineItem clip,
//       double screenWidth,
//       ) {
//     final centerX = screenWidth / 2;
//
//     return clip.startTime.inMilliseconds / 1000 * _pixelsPerSecond -
//         _timelineOffset +
//         centerX;
//   }
//
//   @override
//   void dispose() {
//     scrollController.dispose();
//     super.dispose();
//   }
// }
//
// // Display mode enum (if not already declared)
// enum TimelineDisplayMode {
//   allTracks,
//   videoAudioOnly,
//   videoTextOnly,
//   videoOverlayOnly,
// }
