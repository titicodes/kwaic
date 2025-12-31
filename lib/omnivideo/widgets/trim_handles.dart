import 'package:flutter/material.dart';

class TrimHandle extends StatelessWidget {
  final bool isStart;
  final VoidCallback onDrag;

  const TrimHandle({
    super.key,
    required this.isStart,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (_) => onDrag(),
      child: Container(
        width: 10,
        color: Colors.blueAccent,
        child: Icon(
          isStart ? Icons.chevron_left : Icons.chevron_right,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}
