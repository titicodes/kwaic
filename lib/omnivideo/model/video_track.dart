import 'dart:typed_data';
import 'dart:ui';

class VideoTrack {
  final String id;
  final String path;
  final Duration startTime;
  final Duration endTime;
  final Uint8List? thumbnail;
  final List<Uint8List> timelineThumbnails;
  final double speed;
  final List<SpeedSegment> speedCurve;
  Duration trimStart = Duration.zero;     // relative to original clip
  Duration trimEnd;                       // relative to original clip (default = full duration)
  double rotation = 0.0;                  // degrees
  bool flipHorizontal = false;
  bool flipVertical = false;
  Rect cropRect = const Rect.fromLTWH(0, 0, 1, 1); // normalized 0-1
  double cropZoom = 1.0;



  VideoTrack({
    required this.id,
    required this.path,
    required this.startTime,
    required this.endTime,
    this.thumbnail,
    this.timelineThumbnails = const [],
    this.speed = 1.0,
    this.speedCurve = const [],
    this.trimStart = Duration.zero,
    Duration? trimEnd,
    this.rotation = 0.0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.cropRect = const Rect.fromLTWH(0, 0, 1, 1),
    this.cropZoom = 1.0,
  }): trimEnd = trimEnd ?? endTime - startTime;

  /// ✅ CAPCUT-CORRECT
  Duration get duration => endTime - startTime;

  VideoTrack copyWith({
    String? path,
    Duration? startTime,
    Duration? endTime,
    Uint8List? thumbnail,
    double? speed,
    List<SpeedSegment>? speedCurve,

    List<Uint8List>? timelineThumbnails,
    Duration? trimStart,
    Duration? trimEnd,
    double? rotation,
    bool? flipHorizontal,
    bool? flipVertical,
    Rect? cropRect,
    double? cropZoom,
  }) {
    return VideoTrack(
      id: id,
      path: path ?? this.path,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      thumbnail: thumbnail ?? this.thumbnail,
      speed: speed ?? this.speed,
      timelineThumbnails: timelineThumbnails ?? this.timelineThumbnails,
      speedCurve: speedCurve?? this.speedCurve,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      rotation: rotation ?? this.rotation,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      cropRect: cropRect ?? this.cropRect,
      cropZoom: cropZoom ?? this.cropZoom,
    );
  }
}


class SpeedSegment {
  final Duration start;
  final Duration end;
  final double speed;

  SpeedSegment({
    required this.start,
    required this.end,
    required this.speed,
  });
}
