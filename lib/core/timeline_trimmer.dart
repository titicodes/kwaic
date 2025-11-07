import 'package:flutter/material.dart';

class TimelineTrimmer extends StatefulWidget {
  final double durationMs;
  final double startMs;
  final double endMs;
  final ValueChanged<double> onStartChanged;
  final ValueChanged<double> onEndChanged;

  const TimelineTrimmer({
    super.key,
    required this.durationMs,
    required this.startMs,
    required this.endMs,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  State<TimelineTrimmer> createState() => _TimelineTrimmerState();
}

class _TimelineTrimmerState extends State<TimelineTrimmer> {
  double? _dragStart;
  bool draggingStart = false;

  @override
  Widget build(BuildContext context) {
    final totalWidth = MediaQuery.of(context).size.width - 60;
    final startPos = (widget.startMs / widget.durationMs) * totalWidth;
    final endPos = (widget.endMs / widget.durationMs) * totalWidth;

    return Container(
      height: 50,
      color: Colors.black54,
      child: Stack(
        children: [
          Positioned(left: startPos, right: totalWidth - endPos, child: Container(color: Colors.blueAccent.withOpacity(0.3))),
          Positioned(
            left: startPos - 10,
            child: GestureDetector(
              onHorizontalDragUpdate: (d) {
                final newStart = ((startPos + d.localPosition.dx) / totalWidth) * widget.durationMs;
                widget.onStartChanged(newStart.clamp(0, widget.endMs - 100));
              },
              child: Container(width: 20, color: Colors.blue),
            ),
          ),
          Positioned(
            left: endPos - 10,
            child: GestureDetector(
              onHorizontalDragUpdate: (d) {
                final newEnd = ((endPos + d.localPosition.dx) / totalWidth) * widget.durationMs;
                widget.onEndChanged(newEnd.clamp(widget.startMs + 100, widget.durationMs));
              },
              child: Container(width: 20, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
