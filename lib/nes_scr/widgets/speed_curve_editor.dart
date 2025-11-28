
import 'package:flutter/material.dart';


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
                  points.add(SpeedPoint(x.clamp(0.0, 1.0),  speed));
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
    if (points.length < 2) return;

    final paint = Paint()
      ..color = const Color(0xFF00D9FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final double w = size.width;
    final double h = size.height;

    // Start point
    path.moveTo(0, h - (points.first.speed / 4.0) * h);

    // Curve through points
    for (var p in points) {
      final x = p.time * w;
      final y = h - (p.speed / 4.0) * h;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Draw points
    for (var p in points) {
      canvas.drawCircle(
        Offset(p.time * w, h - (p.speed / 4.0) * h),
        4,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}