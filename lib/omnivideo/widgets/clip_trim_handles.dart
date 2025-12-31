import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ClipTrimHandles extends StatelessWidget {
  final VoidCallback onLeftDrag;
  final VoidCallback onRightDrag;

  const ClipTrimHandles({
    super.key,
    required this.onLeftDrag,
    required this.onRightDrag,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (_) => onLeftDrag(),
            child: Container(width: 16, color: Colors.blueAccent),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (_) => onRightDrag(),
            child: Container(width: 16, color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }
}
