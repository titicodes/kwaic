import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import 'dart:io';

import 'package:kwaic/nes_scr/model/speed_point.dart';

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'keyframe.dart';

enum TimelineItemType { video, audio, image, text, overlay, stickers }

// model/speed_point.dart
class SpeedPoint {
  final double time; // 0.0 to 1.0
  final double speed; // e.g. 0.5x, 2.0x

  SpeedPoint({required this.time, required this.speed});

  SpeedPoint copyWith({double? time, double? speed}) {
    return SpeedPoint(time: time ?? this.time, speed: speed ?? this.speed);
  }

  Map<String, dynamic> toJson() => {'time': time, 'speed': speed};

  factory SpeedPoint.fromJson(Map<String, dynamic> json) {
    return SpeedPoint(
      time: (json['time'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
    );
  }
}

enum BottomNavMode {
  normal,
  edit,
  audio,
  text,
  stickers,
  overlay,
  effects,
  filters,
  animation,
}

// Add this new enum for timeline modes
enum TimelineDisplayMode {
  allTracks,
  videoOnly, // NEW for effects/speed
  videoAudioOnly,
  videoTextOnly,
  videoOverlayOnly,
}

extension DurationJson on Duration {
  int toJson() => inMilliseconds;
  static Duration fromJson(int ms) => Duration(milliseconds: ms);
}

extension ColorJson on Color {
  int toJson() => value;

  static Color fromJson(int value) => Color(value);
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
  bool? flipHorizontal;
  bool? flipVertical;
  String? animationIn;
  Waveform? waveformData;
  List<Uint8List>? thumbnailBytes;
  List<String>? thumbnailPaths;
  List<ui.Image>? thumbnailImages;
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
  String? text;
  Color? textColor;
  double? fontSize;
  String? fontFamily;
  double? opacity;
  double? x;
  double? y;
  int layerIndex;
  double? endX;
  double? endY;
  double? endScale;
  double? endRotation;
  List<SpeedPoint> speedPoints;
  List<Keyframe> keyframes;

  Color? shadowColor;
  double? shadowBlur;
  double? strokeWidth;
  Color? strokeColor;
  String? animation;
  double? brightness;    // -100 to 100
  double? contrast;      // 0 to 200 (100 = normal)
  double? saturation;    // 0 to 200 (100 = normal)
  double? exposure;      // -100 to 100

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
    this.thumbnailImages,
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
    this.opacity,
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
    List<Keyframe>? keyframes,
    this.flipHorizontal,
    this.flipVertical,
    this.animationIn,
    this.animation,
    this.shadowBlur,
    this.shadowColor,
    this.strokeColor,
    this.strokeWidth,
    this.brightness,
    this.contrast,
    this.saturation,
    this.exposure,
  }) : trimEnd = trimEnd ?? duration,
        speedPoints = speedPoints ?? [SpeedPoint(time: 0, speed: 1.0)],
        keyframes = keyframes ?? [];

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    debugPrint('Received JSON: $json');

    // File Path Handling
    String? filePath = json['filePath'];
    if (filePath == null || filePath is! String) {
      debugPrint('Invalid filePath: $filePath');
    }

    // Parse thumbnail paths
    List<String> thumbnailPaths = [];
    if (json['thumbnailPaths'] is List) {
      try {
        thumbnailPaths = List<String>.from(json['thumbnailPaths']);
      } catch (e) {
        debugPrint('Error parsing thumbnailPaths: $e');
      }
    }

    // Parse thumbnail bytes as base64 encoded strings
    List<Uint8List>? thumbnailBytes;
    if (json['thumbnailBytes'] is List) {
      try {
        thumbnailBytes = (json['thumbnailBytes'] as List<dynamic>)
            .map((e) => base64Decode(e as String))
            .toList();
      } catch (e) {
        debugPrint('Error decoding thumbnailBytes: $e');
      }
    }

    try {
      return TimelineItem(
        id: json['id'],
        type: TimelineItemType.values.firstWhere(
              (e) => e.toString() == 'TimelineItemType.${json['type']}',
          orElse: () => TimelineItemType.video,
        ),
        file: filePath != null ? File(filePath) : null, // Use filePath
        startTime: DurationJson.fromJson(json['startTime']),
        duration: DurationJson.fromJson(json['duration']),
        originalDuration: DurationJson.fromJson(json['originalDuration']),
        trimStart: DurationJson.fromJson(json['trimStart']),
        trimEnd: DurationJson.fromJson(json['trimEnd']),
        speed: (json['speed'] ?? 1.0).toDouble(),
        volume: (json['volume'] ?? 1.0).toDouble(),
        flipHorizontal: json['flipHorizontal'],
        flipVertical: json['flipVertical'],
        animationIn: json['animationIn'],
        cropLeft: (json['cropLeft'] ?? 0.0).toDouble(),
        cropTop: (json['cropTop'] ?? 0.0).toDouble(),
        cropRight: (json['cropRight'] ?? 0.0).toDouble(),
        cropBottom: (json['cropBottom'] ?? 0.0).toDouble(),
        rotation: (json['rotation'] ?? 0.0).toDouble(),
        scale: (json['scale'] ?? 1.0).toDouble(),
        cropX: (json['cropX'] as num?)?.toDouble(),
        cropY: (json['cropY'] as num?)?.toDouble(),
        cropWidth: (json['cropWidth'] as num?)?.toDouble(),
        cropHeight: (json['cropHeight'] as num?)?.toDouble(),
        text: json['text'],
        textColor: json['textColor'] != null
            ? ColorJson.fromJson(json['textColor'])
            : null,
        fontSize: (json['fontSize'] as num?)?.toDouble(),
        fontFamily: json['fontFamily'],
        opacity: (json['opacity'] as num?)?.toDouble(),
        x: (json['x'] as num?)?.toDouble(),
        y: (json['y'] as num?)?.toDouble(),
        layerIndex: json['layerIndex'] ?? 0,
        endX: (json['endX'] as num?)?.toDouble(),
        endY: (json['endY'] as num?)?.toDouble(),
        endScale: (json['endScale'] as num?)?.toDouble(),
        endRotation: (json['endRotation'] as num?)?.toDouble(),
        thumbnailPaths: thumbnailPaths,
        thumbnailBytes: thumbnailBytes,
        speedPoints: (json['speedPoints'] as List<dynamic>?)
            ?.map((e) => SpeedPoint.fromJson(e))
            .toList() ??
            [],
        keyframes: (json['keyframes'] as List<dynamic>?)
            ?.map((e) => Keyframe.fromJson(e))
            .toList() ??
            [],
        shadowColor: json['shadowColor'] != null ? Color(json['shadowColor']) : null,
        shadowBlur: (json['shadowBlur'] as num?)?.toDouble(),
        strokeWidth: (json['strokeWidth'] as num?)?.toDouble(),
        strokeColor: json['strokeColor'] != null ? Color(json['strokeColor']) : null,
        animation: json['animation'],
        brightness: (json['brightness'] as num?)?.toDouble(),
        contrast: (json['contrast'] as num?)?.toDouble(),
        saturation: (json['saturation'] as num?)?.toDouble(),
        exposure: (json['exposure'] as num?)?.toDouble(),
      );
    } catch (e) {
      debugPrint('Error while parsing TimelineItem: $e');
      rethrow; // Propagate the error
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'file': file?.path,
      'startTime': startTime.toJson(),
      'duration': duration.toJson(),
      'originalDuration': originalDuration.toJson(),
      'trimStart': trimStart.toJson(),
      'trimEnd': trimEnd.toJson(),
      'speed': speed,
      'volume': volume,
      'flipHorizontal': flipHorizontal,
      'flipVertical': flipVertical,
      'animationIn': animationIn,
      'cropLeft': cropLeft,
      'cropTop': cropTop,
      'cropRight': cropRight,
      'cropBottom': cropBottom,
      'rotation': rotation,
      'scale': scale,
      'cropX': cropX,
      'cropY': cropY,
      'cropWidth': cropWidth,
      'cropHeight': cropHeight,
      'text': text,
      'textColor': textColor?.toJson(),
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'opacity': opacity,
      'x': x,
      'y': y,
      'layerIndex': layerIndex,
      'endX': endX,
      'endY': endY,
      'endScale': endScale,
      'endRotation': endRotation,
      'thumbnailPaths': thumbnailPaths,
      'thumbnailBytes': thumbnailBytes?.map((e) => base64Encode(e)).toList(),
      'speedPoints': speedPoints.map((e) => e.toJson()).toList(),
      'keyframes': keyframes.map((e) => e.toJson()).toList(),
      'shadowColor': shadowColor?.value,
      'shadowBlur': shadowBlur,
      'strokeWidth': strokeWidth,
      'strokeColor': strokeColor?.value,
      'animation': animation,
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'exposure': exposure,
      //'waveformData': waveformData?.toJson(),
    };
  }

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
    bool? flipHorizontal,
    bool? flipVertical,
    String? animationIn,
    Waveform? waveformData,
    List<Uint8List>? thumbnailBytes,
    List<String>? thumbnailPaths,
    List<ui.Image>? thumbnailImages,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
    double? rotation,
    double? scale,
    double? cropX,
    double? cropY,
    double? cropWidth,
    double? cropHeight,
    String? text,
    Color? textColor,
    double? fontSize,
    String? fontFamily,
    double? opacity,
    double? x,
    double? y,
    int? layerIndex,
    double? endX,
    double? endY,
    double? endScale,
    double? endRotation,
    List<SpeedPoint>? speedPoints,
    List<Keyframe>? keyframes,
    Color? shadowColor,
    double? shadowBlur,
    double? strokeWidth,
    Color? strokeColor,
    String? animation,

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
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      animationIn: animationIn ?? this.animationIn,
      waveformData: waveformData ?? this.waveformData,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      thumbnailPaths: thumbnailPaths ?? this.thumbnailPaths,
      thumbnailImages: thumbnailImages ?? this.thumbnailImages,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      cropX: cropX ?? this.cropX,
      cropY: cropY ?? this.cropY,
      cropWidth: cropWidth ?? this.cropWidth,
      cropHeight: cropHeight ?? this.cropHeight,
      text: text ?? this.text,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      opacity: opacity ?? this.opacity,
      x: x ?? this.x,
      y: y ?? this.y,
      layerIndex: layerIndex ?? this.layerIndex,
      endX: endX ?? this.endX,
      endY: endY ?? this.endY,
      endScale: endScale ?? this.endScale,
      endRotation: endRotation ?? this.endRotation,
      speedPoints: speedPoints ?? this.speedPoints,
      keyframes: keyframes ?? this.keyframes,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeColor: strokeColor ?? this.strokeColor,
      animation: animation ?? this.animation,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      exposure: exposure ?? this.exposure,
    );
  }

}

extension DurationMath on Duration {
  Duration multiply(double factor) =>
      Duration(milliseconds: (inMilliseconds * factor).round());

  Duration divide(double divisor) =>
      divisor == 0
          ? this
          : Duration(milliseconds: (inMilliseconds / divisor).round());

  Duration clamp(Duration min, Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}

extension TimelineItemFileName on TimelineItem {
  String get fileName =>
      file?.path.split(Platform.pathSeparator).last ?? 'Media';
}
