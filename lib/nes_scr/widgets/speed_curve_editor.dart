
import 'package:flutter/material.dart';

import '../model/speed_point.dart';
import '../model/timeline_item.dart';

class SpeedCurveEditor extends StatefulWidget {
  final TimelineItem item;
  const SpeedCurveEditor({Key? key, required this.item}) : super(key: key);

  @override
  State<SpeedCurveEditor> createState() => _SpeedCurveEditorState();
}

class _SpeedCurveEditorState extends State<SpeedCurveEditor> {
  late List<SpeedPoint> points;

  @override
  void initState() {
    super.initState();
    points = List.from(widget.item.speedPoints);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Speed Curve", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget.item.speedPoints = points;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D9FF)),
                child: const Text("Apply", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                final box = context.findRenderObject() as RenderBox;
                final offset = details.localPosition;
                final x = offset.dx / box.size.width;
                final y = 1 - (offset.dy / box.size.height);
                final speed = (y * 7.75 + 0.25).clamp(0.25, 8.0);

                setState(() {
                  points.add(SpeedPoint(time: x.clamp(0.0, 1.0), speed: speed));
                  points.sort((a, b) => a.time.compareTo(b.time));
                });
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: SpeedCurvePainter(points),
              ),
            ),
          ),
          const Text("Tap to add point • Drag to move • Double-tap to delete", style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

class SpeedCurvePainter extends CustomPainter {
  final List<SpeedPoint> points;
  SpeedCurvePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D9FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (points.isEmpty) return;

    path.moveTo(0, size.height * (1 - (1.0 - 0.25) / 7.75));

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final x1 = p1.time * size.width;
      final x2 = p2.time * size.width;
      final y1 = size.height * (1 - (p1.speed - 0.25) / 7.75);
      final y2 = size.height * (1 - (p2.speed - 0.25) / 7.75);

      final cx = (x1 + x2) / 2;
      path.cubicTo(cx, y1, cx, y2, x2, y2);
    }

    canvas.drawPath(path, paint..style = PaintingStyle.stroke);

    // Draw points
    for (var p in points) {
      final x = p.time * size.width;
      final y = size.height * (1 - (p.speed - 0.25) / 7.75);
      canvas.drawCircle(Offset(x, y), 10, paint..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(x, y), 10, paint..color = Colors.black ..strokeWidth = 2 ..style = PaintingStyle.stroke);
      canvas.drawLine(
        Offset(x, y - 20),
        Offset(x, y + 20),
        paint..color = Colors.white70 ..strokeWidth = 1,
      );
      canvas.drawLine(
        Offset(x - 20, y),
        Offset(x + 20, y),
        paint..color = Colors.white70 ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}