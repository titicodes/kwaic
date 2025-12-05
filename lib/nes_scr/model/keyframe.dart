// model/keyframe.dart
class Keyframe {
  final double time; // 0.0 to 1.0
  final double? x;
  final double? y;
  final double? scale;
  final double? rotation;
  final double? opacity;

  Keyframe({
    required this.time,
    this.x,
    this.y,
    this.scale,
    this.rotation,
    this.opacity,
  });

  Keyframe copyWith({
    double? time,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    double? opacity,
  }) {
    return Keyframe(
      time: time ?? this.time,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
    );
  }

  Keyframe lerp(Keyframe other, double t) {
    return Keyframe(
      time: time,
      x: x == null || other.x == null ? null : x! + (other.x! - x!) * t,
      y: y == null || other.y == null ? null : y! + (other.y! - y!) * t,
      scale: scale == null || other.scale == null ? null : scale! + (other.scale! - scale!) * t,
      rotation: rotation == null || other.rotation == null ? null : rotation! + (other.rotation! - rotation!) * t,
      opacity: opacity == null || other.opacity == null ? null : opacity! + (other.opacity! - opacity!) * t,
    );
  }
}