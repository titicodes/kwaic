// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// class TextTrack {
//   final String id;
//   String text;
//   Duration startTime;
//   Duration duration;
//   Color color;
//   String fontFamily;
//   double fontSize;
//   TextAlign alignment;
//   Offset position; // normalized 0-1
//   double rotation;
//   double scale;
//
//   TextTrack({
//     required this.id,
//     this.text = 'Text',
//     required this.startTime,
//     this.duration = const Duration(seconds: 5),
//     this.color = Colors.white,
//     this.fontFamily = 'Roboto',
//     this.fontSize = 40,
//     this.alignment = TextAlign.center,
//     this.position = const Offset(0.5, 0.5),
//     this.rotation = 0.0,
//     this.scale = 1.0,
//   });
//
//   Duration get endTime => startTime + duration;
//
//   TextTrack copyWith({
//     String? text,
//     Duration? startTime,
//     Duration? duration,
//     Color? color,
//     String? fontFamily,
//     double? fontSize,
//     TextAlign? alignment,
//     Offset? position,
//     double? rotation,
//     double? scale,
//   }) {
//     return TextTrack(
//       id: id,
//       text: text ?? this.text,
//       startTime: startTime ?? this.startTime,
//       duration: duration ?? this.duration,
//       color: color ?? this.color,
//       fontFamily: fontFamily ?? this.fontFamily,
//       fontSize: fontSize ?? this.fontSize,
//       alignment: alignment ?? this.alignment,
//       position: position ?? this.position,
//       rotation: rotation ?? this.rotation,
//       scale: scale ?? this.scale,
//     );
//   }
// }

// model/text_track.dart
import 'package:flutter/material.dart';

class TextTrack {
  final String id;
  final String text;
  final Duration startTime;
  final Duration duration;
  final Color color;
  final String fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final TextAlign alignment;
  final bool hasShadow;
  final bool hasStroke;
  final Color strokeColor;
  final double strokeWidth;
  final Offset position; // normalized 0-1
  final double scale;
  final double rotation;
  final String animationIn;
  final String animationOut;

  TextTrack({
    required this.id,
    this.text = 'Tap to edit',
    required this.startTime,
    this.duration = const Duration(seconds: 5),
    this.color = Colors.white,
    this.fontFamily = 'Roboto',
    this.fontSize = 40,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
    this.alignment = TextAlign.center,
    this.hasShadow = true,
    this.hasStroke = false,
    this.strokeColor = Colors.black,
    this.strokeWidth = 4.0,
    this.position = const Offset(0.5, 0.5),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.animationIn = 'fade',
    this.animationOut = 'fade',
  });

  Duration get endTime => startTime + duration;

  TextTrack copyWith({
    String? id,
    String? text,
    Duration? startTime,
    Duration? duration,
    Color? color,
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextAlign? alignment,
    bool? hasShadow,
    bool? hasStroke,
    Color? strokeColor,
    double? strokeWidth,
    Offset? position,
    double? scale,
    double? rotation,
    String? animationIn,
    String? animationOut,
  }) {
    return TextTrack(
      id: id ?? this.id,
      text: text ?? this.text,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      color: color ?? this.color,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      alignment: alignment ?? this.alignment,
      hasShadow: hasShadow ?? this.hasShadow,
      hasStroke: hasStroke ?? this.hasStroke,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      animationIn: animationIn ?? this.animationIn,
      animationOut: animationOut ?? this.animationOut,
    );
  }
}