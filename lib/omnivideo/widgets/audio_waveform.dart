import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';

class AudioWaveformPainter extends CustomPainter {
  final Waveform waveform;
  final Color color;
  final double pixelsPerStep;

  AudioWaveformPainter({
    required this.waveform,
    required this.color,
    this.pixelsPerStep = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;
    final peaks = waveform.data;

    if (peaks.isEmpty) return;

    final maxAmp = peaks.map((p) => p.abs()).reduce((a, b) => a > b ? a : b).toDouble();

    if (maxAmp == 0) return;

    for (int i = 0; i < peaks.length; i += 2) { // step by 2: min/max pair
      final x = (i ~/ 2) * pixelsPerStep;
      if (x > size.width) break;

      final minVal = peaks[i];
      final maxVal = peaks[i + 1];

      final minAmp = (minVal.abs() / maxAmp) * midY;
      final maxAmpNormalized = (maxVal.abs() / maxAmp) * midY;

      canvas.drawLine(
        Offset(x, midY - maxAmpNormalized),
        Offset(x, midY + minAmp),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AudioWaveformPainter oldDelegate) {
    return oldDelegate.waveform != waveform || oldDelegate.color != color;
  }
}