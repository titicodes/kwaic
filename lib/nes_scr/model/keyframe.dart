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

  // Convert a Keyframe to JSON
  Map<String, dynamic> toJson() => {
    'time': time,
    'x': x,
    'y': y,
    'scale': scale,
    'rotation': rotation,
    'opacity': opacity,
  };

  // Create a Keyframe from JSON
  factory Keyframe.fromJson(Map<String, dynamic> json) {
    return Keyframe(
      time: (json['time'] as num).toDouble(),
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      scale: (json['scale'] as num?)?.toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble(),
    );
  }
}
