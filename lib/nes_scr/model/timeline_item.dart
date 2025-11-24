import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:kwaic/nes_scr/model/speed_point.dart';

enum TimelineItemType { video, audio, image, text }

class TimelineItem {
  String id;
  TimelineItemType type;
  File? file;
  Duration startTime;
  Duration duration;
  Duration originalDuration;
  Duration trimStart;
  Duration trimEnd;
  double volume;
  String? text;
  Color? textColor;
  double? fontSize;
  double? x;
  double? y;
  double rotation;
  double scale;
  String? effect;
  List<String> thumbnailPaths;
  List<double>? waveformData;
  List<Keyframe> keyframes;
  int trackIndex;
  List<Uint8List>? thumbnailBytes; // field

  // Keyframe end values
  double? endX;
  double? endY;
  double? endScale;
  double? endRotation;

  // Crop values
  double cropLeft;
  double cropTop;
  double cropRight;
  double cropBottom;

  // NEW: Layer index for multi-track layering
  int? layerIndex;

  double speed = 1.0;
  List<SpeedPoint> speedPoints = [
    SpeedPoint(time: 0.0, speed: 1.0),
    SpeedPoint(time: 1.0, speed: 1.0),
  ];

  TimelineItem({
    required this.id,
    required this.type,
    this.file,
    required this.startTime,
    required this.duration,
    required this.originalDuration,
    Duration? trimStart,
    Duration? trimEnd,
    this.speed = 1.0,
    this.volume = 1.0,
    this.text,
    this.textColor,
    this.fontSize,
    this.x,
    this.y,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.effect,
    List<String>? thumbnailPaths,
    this.waveformData,
    this.keyframes = const [],
    this.trackIndex = 0,
    this.thumbnailBytes,
    this.endX,
    this.endY,
    this.endScale,
    this.endRotation,
    this.cropLeft = 0.0,
    this.cropTop = 0.0,
    this.cropRight = 0.0,
    this.cropBottom = 0.0,
    this.layerIndex,
    List<SpeedPoint>? speedPoints, // Make this nullable in the constructor
  })  : trimStart = trimStart ?? Duration.zero,
        trimEnd = trimEnd ?? originalDuration,
        thumbnailPaths = thumbnailPaths ?? [],
        speedPoints = speedPoints ?? [
          SpeedPoint(time: 0.0, speed: 1.0),
          SpeedPoint(time: 1.0, speed: 1.0),
        ]; // Provide a default non-null value


  TimelineItem copyWith({
    String? id,
    TimelineItemType? type,
    File? file,
    Duration? startTime,
    Duration? duration,
    Duration? originalDuration,
    Duration? trimStart,
    Duration? trimEnd,
    double? speed,
    double? volume,
    String? text,
    Color? textColor,
    double? fontSize,
    double? x,
    double? y,
    double? rotation,
    double? scale,
    String? effect,
    List<String>? thumbnailPaths,
    List<double>? waveformData,
    List<Keyframe>? keyframes,
    int? trackIndex,
    List<Uint8List>? thumbnailBytes, // <-- add here
    double? endX,
    double? endY,
    double? endScale,
    double? endRotation,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
    int? layerIndex,
    List<SpeedPoint>? speedPoints,
  }) {
    return TimelineItem(
      id: id ?? this.id,
      type: type ?? this.type,
      file: file ?? this.file,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      originalDuration: originalDuration ?? this.originalDuration,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      text: text ?? this.text,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      x: x ?? this.x,
      y: y ?? this.y,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      effect: effect ?? this.effect,
      thumbnailPaths: thumbnailPaths ?? List.from(this.thumbnailPaths),
      waveformData: waveformData ?? this.waveformData,
      keyframes: keyframes ?? this.keyframes,
      trackIndex: trackIndex ?? this.trackIndex,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes, // copy here
      endX: endX ?? this.endX,
      endY: endY ?? this.endY,
      endScale: endScale ?? this.endScale,
      endRotation: endRotation ?? this.endRotation,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
      layerIndex: layerIndex ?? this.layerIndex,
      speedPoints: speedPoints ?? this.speedPoints,
    );
  }
}

class Keyframe {
  Duration time;
  Map<String, dynamic> properties;

  Keyframe({required this.time, required this.properties});
}

extension DurationMath on Duration {
  Duration multiply(double factor) =>
      Duration(milliseconds: (inMilliseconds * factor).round());

  Duration divide(double divisor) => divisor == 0
      ? this
      : Duration(milliseconds: (inMilliseconds / divisor).round());

  Duration clamp(Duration min, Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}

extension TimelineItemFileName on TimelineItem {
  String get fileName => file?.path.split(Platform.pathSeparator).last ?? 'Media';
}
