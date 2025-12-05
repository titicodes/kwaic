// widgets/speed_curve_editor.dart
import 'package:flutter/material.dart';
import '../model/timeline_item.dart';
import '../model/speed_point.dart';

class SpeedCurveEditor extends StatefulWidget {
  final TimelineItem item;
  final Function(List<SpeedPoint>)? onSave;

  const SpeedCurveEditor({super.key, required this.item, this.onSave});

  @override
  State<SpeedCurveEditor> createState() => _SpeedCurveEditorState();
}

class _SpeedCurveEditorState extends State<SpeedCurveEditor> {
  late List<SpeedPoint> points;

  @override
  void initState() {
    super.initState();
    points = widget.item.speedPoints.isEmpty
        ? [SpeedPoint(time: 0.0, speed: 1.0), SpeedPoint(time: 1.0, speed: 1.0)]
        : widget.item.speedPoints.map((p) => p.copyWith()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Speed Curve'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              widget.item.speedPoints = points;
              widget.onSave?.call(points);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Speed curve applied'), backgroundColor: Color(0xFF10B981)),
              );
            },
            child: const Text('Apply', style: TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Average Speed: ${(points.map((p) => p.speed).reduce((a, b) => a + b) / points.length).toStringAsFixed(2)}x',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _SpeedCurvePainter(points),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Drag points to create speed ramps\nFirst & last points are locked',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedCurvePainter extends CustomPainter {
  final List<SpeedPoint> points;
  _SpeedCurvePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D9FF)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height - (points[0].speed / 8.0).clamp(0.0, 1.0) * size.height);

    for (int i = 1; i < points.length; i++) {
    final x = points[i].time * size.width;
    final y = size.height - (points[i].speed / 8.0).clamp(0.0, 1.0) * size.height;
    path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Draw points
    for (final p in points) {
    final x = p.time * size.width;
    final y = size.height - (p.speed / 8.0).clamp(0.0, 1.0) * size.height;

    canvas.drawCircle(Offset(x, y), 12, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(x, y), 8, Paint()..color = const Color(0xFF00D9FF));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}