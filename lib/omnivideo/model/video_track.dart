import 'dart:typed_data';
import 'dart:ui';

class VideoTrack {
  final String id;
  final String path;

  final Duration startTime;
  final Duration endTime;

  final Uint8List? thumbnail;
  final List<Uint8List> timelineThumbnails;

  // ===== Transform (CapCut-style, normalized) =====
  final Offset position; // (-1..1) relative to center
  final double scale;    // 1.0 = original size
  final double rotation; // degrees
  final bool flipHorizontal;
  final bool flipVertical;

  final Rect cropRect;   // normalized 0..1
  final double cropZoom;

  // ===== Speed / Trim =====
  final double speed;
  final List<SpeedSegment> speedCurve;

  final Duration trimStart;
  final Duration trimEnd;

  VideoTrack({
    required this.id,
    required this.path,
    required this.startTime,
    required this.endTime,

    this.thumbnail,
    this.timelineThumbnails = const [],

    this.position = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.flipHorizontal = false,
    this.flipVertical = false,

    this.cropRect = const Rect.fromLTWH(0, 0, 1, 1),
    this.cropZoom = 1.0,

    this.speed = 1.0,
    this.speedCurve = const [],

    this.trimStart = Duration.zero,
    Duration? trimEnd,
  }) : trimEnd = trimEnd ?? endTime - startTime;

  /// ✅ CapCut-correct visible duration
  Duration get duration => endTime - startTime;

  VideoTrack copyWith({
    String? path,
    Duration? startTime,
    Duration? endTime,
    Uint8List? thumbnail,
    List<Uint8List>? timelineThumbnails,

    Offset? position,
    double? scale,
    double? rotation,
    bool? flipHorizontal,
    bool? flipVertical,

    Rect? cropRect,
    double? cropZoom,

    double? speed,
    List<SpeedSegment>? speedCurve,

    Duration? trimStart,
    Duration? trimEnd,
  }) {
    return VideoTrack(
      id: id,
      path: path ?? this.path,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,

      thumbnail: thumbnail ?? this.thumbnail,
      timelineThumbnails:
      timelineThumbnails ?? this.timelineThumbnails,

      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,

      cropRect: cropRect ?? this.cropRect,
      cropZoom: cropZoom ?? this.cropZoom,

      speed: speed ?? this.speed,
      speedCurve: speedCurve ?? this.speedCurve,

      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
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

