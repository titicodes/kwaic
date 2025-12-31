import 'package:flutter/material.dart';

class TextTrack {
  final String id;
  String text;
  Duration startTime;
  Duration duration;
  Color color;
  String fontFamily;
  double fontSize;
  TextAlign alignment;
  Offset position; // normalized 0-1
  double rotation;
  // Animation, style, etc. later

  TextTrack({
    required this.id,
    this.text = 'Text',
    required this.startTime,
    this.duration = const Duration(seconds: 5),
    this.color = Colors.white,
    this.fontFamily = 'Roboto',
    this.fontSize = 40,
    this.alignment = TextAlign.center,
    this.position = const Offset(0.5, 0.5),
    this.rotation = 0.0,
  });

  TextTrack copyWith({
    String? text,
    Duration? startTime,
    Duration? duration,
    Color? color,
    String? fontFamily,
    double? fontSize,
    TextAlign? alignment,
    Offset? position,
    double? rotation,
  }) {
    return TextTrack(
      id: id,
      text: text ?? this.text,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      color: color ?? this.color,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      alignment: alignment ?? this.alignment,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
    );
  }
}