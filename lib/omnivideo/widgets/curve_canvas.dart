import 'package:flutter/material.dart';

class CurveCanvas extends StatelessWidget {
  final List<Offset> points;
  final Function(int, Offset) onPointMoved;

  const CurveCanvas({
    super.key,
    required this.points,
    required this.onPointMoved,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);

        return Stack(
          children: [
            CustomPaint(
              size: size,
              painter: _CurvePainter(points),
            ),
            ...points.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;

              return Positioned(
                left: p.dx * size.width - 8,
                top: p.dy * size.height - 8,
                child: GestureDetector(
                  onPanUpdate: (d) {
                    onPointMoved(
                      i,
                      Offset(
                        (p.dx + d.delta.dx / size.width),
                        (p.dy + d.delta.dy / size.height),
                      ),
                    );
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _CurvePainter extends CustomPainter {
  final List<Offset> points;

  _CurvePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(points.first.dx * size.width,
          points.first.dy * size.height);

    for (final p in points.skip(1)) {
      path.lineTo(p.dx * size.width, p.dy * size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => true;
}
