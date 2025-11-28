import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:kwaic/nes_scr/model/speed_point.dart';

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'keyframe.dart';

enum TimelineItemType { video, audio, image, text }

class SpeedPoint {
  final double time;
  final double speed;
  SpeedPoint(this.time, this.speed);
}

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

  // Video/Image properties
  List<Uint8List>? thumbnailBytes;
  List<String>? thumbnailPaths;
  double cropLeft;
  double cropTop;
  double cropRight;
  double cropBottom;
  double rotation;
  double scale;
  double? cropX;
  double? cropY;
  double? cropWidth;
  double? cropHeight;
  // Text properties
  String? text;
  Color? textColor;
  double? fontSize;
  String? fontFamily;

  // Position
  double? x;
  double? y;
  int layerIndex;

  // Animation keyframes
  double? endX;
  double? endY;
  double? endScale;
  double? endRotation;

  // Audio
  List<double>? waveformData;

  // Speed curve
  List<SpeedPoint> speedPoints;
  List<Keyframe> keyframes = [];

  TimelineItem({
    required this.id,
    required this.type,
    this.file,
    required this.startTime,
    required this.duration,
    required this.originalDuration,
    this.trimStart = Duration.zero,
    Duration? trimEnd,
    this.speed = 1.0,
    this.volume = 1.0,
    this.thumbnailBytes,
    this.thumbnailPaths,
    this.cropLeft = 0.0,
    this.cropTop = 0.0,
    this.cropRight = 0.0,
    this.cropBottom = 0.0,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.text,
    this.textColor,
    this.fontSize,
    this.fontFamily,
    this.x,
    this.y,
    this.layerIndex = 0,
    this.endX,
    this.endY,
    this.endScale,
    this.endRotation,
    this.waveformData,
    this.cropX,
    this.cropY,
    this.cropWidth,
    this.cropHeight,
    List<SpeedPoint>? speedPoints,
    this.keyframes = const <Keyframe>[],  // <-- This should be a valid empty list of Keyframe
  }) : trimEnd = trimEnd ?? duration,
        speedPoints = speedPoints ?? [SpeedPoint(0, 1.0), SpeedPoint(1, 1.0)];


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
    List<Uint8List>? thumbnailBytes,
    List<String>? thumbnailPaths,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
    double? rotation,
    double? scale,
    String? text,
    Color? textColor,
    double? fontSize,
    String? fontFamily,
    double? x,
    double? y,
    int? layerIndex,
    double? endX,
    double? endY,
    double? endScale,
    double? endRotation,
    List<double>? waveformData,
    List<SpeedPoint>? speedPoints,
    double? cropX,
    double? cropY,
    double? cropWidth,
    double? cropHeight,
    List<Keyframe>? keyframes,
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
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      thumbnailPaths: thumbnailPaths ?? this.thumbnailPaths,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      text: text ?? this.text,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      x: x ?? this.x,
      y: y ?? this.y,
      layerIndex: layerIndex ?? this.layerIndex,
      endX: endX ?? this.endX,
      endY: endY ?? this.endY,
      endScale: endScale ?? this.endScale,
      endRotation: endRotation ?? this.endRotation,
      waveformData: waveformData ?? this.waveformData,
      speedPoints: speedPoints ?? this.speedPoints,
      cropX: cropX ?? this.cropX,
      cropY: cropY ?? this.cropY,
      cropWidth: cropWidth ?? this.cropWidth,
      cropHeight: cropHeight ?? this.cropHeight,
      keyframes: keyframes ?? this.keyframes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'filePath': file?.path,
      'startTime': startTime.inMilliseconds,
      'duration': duration.inMilliseconds,
      'originalDuration': originalDuration.inMilliseconds,
      'trimStart': trimStart.inMilliseconds,
      'trimEnd': trimEnd.inMilliseconds,
      'speed': speed,
      'volume': volume,
      'cropLeft': cropLeft,
      'cropTop': cropTop,
      'cropRight': cropRight,
      'cropBottom': cropBottom,
      'rotation': rotation,
      'scale': scale,
      'text': text,
      'textColor': textColor?.value,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'x': x,
      'y': y,
      'layerIndex': layerIndex,
      'cropX': cropX,
      'cropY': cropY,
      'cropWidth': cropWidth,
      'cropHeight': cropHeight,
      'keyframes': keyframes.map((k) => {
        'time': k.time,
        'x': k.x,
        'y': k.y,
        'scale': k.scale,
        'rotation': k.rotation,
        'opacity': k.opacity,
      }).toList(),
    };
  }

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      id: json['id'],
      type: TimelineItemType.values.firstWhere(
            (e) => e.toString() == json['type'],
      ),
      file: json['filePath'] != null ? File(json['filePath']) : null,
      startTime: Duration(milliseconds: json['startTime']),
      duration: Duration(milliseconds: json['duration']),
      originalDuration: Duration(milliseconds: json['originalDuration']),
      trimStart: Duration(milliseconds: json['trimStart']),
      trimEnd: Duration(milliseconds: json['trimEnd']),
      speed: json['speed'] ?? 1.0,
      volume: json['volume'] ?? 1.0,
      cropLeft: json['cropLeft'] ?? 0.0,
      cropTop: json['cropTop'] ?? 0.0,
      cropRight: json['cropRight'] ?? 0.0,
      cropBottom: json['cropBottom'] ?? 0.0,
      rotation: json['rotation'] ?? 0.0,
      scale: json['scale'] ?? 1.0,
      text: json['text'],
      textColor: json['textColor'] != null ? Color(json['textColor']) : null,
      fontSize: json['fontSize'],
      fontFamily: json['fontFamily'],
      x: json['x'],
      y: json['y'],
      layerIndex: json['layerIndex'] ?? 0,
      cropX: json['cropX'],
      cropY: json['cropY'],
      cropWidth: json['cropWidth'],
      cropHeight: json['cropHeight'],
      keyframes: json['keyframes'] != null
          ? (json['keyframes'] as List).map((k) => Keyframe(
        time: k['time'],
        x: k['x'],
        y: k['y'],
        scale: k['scale'],
        rotation: k['rotation'],
        opacity: k['opacity'],
      )).toList()
          : <Keyframe>[],


    );
  }
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
