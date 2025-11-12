import 'dart:ui' as ui;

import 'package:flutter/material.dart';



class WaveformPainter extends CustomPainter {
  final List<double> data;
  WaveformPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final barWidth = size.width / data.length;
    for (int i = 0; i < data.length; i++) {
      final h = data[i] * size.height;
      final x = i * barWidth;
      final y1 = (size.height - h) / 2;
      final y2 = y1 + h;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}