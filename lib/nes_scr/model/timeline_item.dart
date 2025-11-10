import 'package:flutter/material.dart';
import 'dart:io';

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
  double speed;
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
  })  : trimStart = trimStart ?? Duration.zero,
        trimEnd = trimEnd ?? originalDuration,
        thumbnailPaths = thumbnailPaths ?? [];

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
  /// Returns the file name without the path.
  /// If the file is null we return a fallback string.
  String get fileName => file?.path.split(Platform.pathSeparator).last ?? 'Media';
}