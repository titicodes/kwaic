class Keyframe {
  final double time; // 0.0 → 1.0
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

  /// Copy this keyframe with updated fields
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

  /// Interpolate between two keyframes
  Keyframe lerp(Keyframe other, double t) {
    return Keyframe(
      time: time + (other.time - time) * t,
      x: _lerpDouble(x, other.x, t),
      y: _lerpDouble(y, other.y, t),
      scale: _lerpDouble(scale, other.scale, t),
      rotation: _lerpDouble(rotation, other.rotation, t),
      opacity: _lerpDouble(opacity, other.opacity, t),
    );
  }

  double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a + (b - a) * t;
  }

  /// JSON Serialization
  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'x': x,
      'y': y,
      'scale': scale,
      'rotation': rotation,
      'opacity': opacity,
    };
  }

  /// JSON Deserialization
  factory Keyframe.fromJson(Map<String, dynamic> json) {
    return Keyframe(
      time: json['time'],
      x: json['x'],
      y: json['y'],
      scale: json['scale'],
      rotation: json['rotation'],
      opacity: json['opacity'],
    );
  }
}
