import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';

class AudioWaveformPainter extends CustomPainter {
  final Waveform waveform; // <- must be Waveform
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
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;

    final peaks = waveform.data; // List<int> in latest just_waveform

    if (peaks.isEmpty) return;

    final maxAmp = peaks.map((p) => p.abs()).reduce((a, b) => a > b ? a : b).toDouble();

    for (int i = 0; i < peaks.length; i++) {
      final x = i * pixelsPerStep;
      if (x > size.width) break;

      final amp = (peaks[i].abs() / maxAmp) * midY;
      canvas.drawLine(
        Offset(x, midY - amp),
        Offset(x, midY + amp),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AudioWaveformPainter oldDelegate) =>
      oldDelegate.waveform != waveform || oldDelegate.color != color;
}


class AudioWaveform extends StatelessWidget {
  final Waveform waveform; // <- must match painter
  final Color color;
  final double height;

  const AudioWaveform({
    super.key,
    required this.waveform,
    this.color = Colors.white,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: AudioWaveformPainter(
          waveform: waveform,
          color: color,
        ),
      ),
    );
  }
}
