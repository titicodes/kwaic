import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/text_track.dart';

class DraggableResizableText extends StatefulWidget {
  final TextTrack textTrack;
  final Size videoSize;
  final Function(TextTrack updated) onUpdate;

  const DraggableResizableText({
    super.key,
    required this.textTrack,
    required this.videoSize,
    required this.onUpdate,
  });

  @override
  State<DraggableResizableText> createState() => _DraggableResizableTextState();
}

class _DraggableResizableTextState extends State<DraggableResizableText> {
  late Offset position;
  late double fontSize;

  @override
  void initState() {
    super.initState();
    position = widget.textTrack.position;
    fontSize = widget.textTrack.fontSize;
  }

  @override
  void didUpdateWidget(covariant DraggableResizableText old) {
    super.didUpdateWidget(old);
    if (old.textTrack.position != widget.textTrack.position) {
      position = widget.textTrack.position;
    }
    if (old.textTrack.fontSize != widget.textTrack.fontSize) {
      fontSize = widget.textTrack.fontSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double x = position.dx * widget.videoSize.width;
    final double y = position.dy * widget.videoSize.height;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Use ONLY onScaleUpdate — it handles pan + pinch perfectly
        onScaleUpdate: (details) {
          setState(() {
            // Pan (translation)
            position += Offset(
              details.focalPointDelta.dx / widget.videoSize.width,
              details.focalPointDelta.dy / widget.videoSize.height,
            );
            position = Offset(
              position.dx.clamp(0.0, 1.0),
              position.dy.clamp(0.0, 1.0),
            );

            // Scale (resize)
            if (details.scale != 1.0) {
              fontSize = (fontSize * details.scale).clamp(20.0, 200.0);
            }
          });

          widget.onUpdate(widget.textTrack.copyWith(
            position: position,
            fontSize: fontSize,
          ));
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white54, width: 1),
          ),
          child: Text(
            widget.textTrack.text,
            style: TextStyle(
              color: widget.textTrack.color,
              fontSize: fontSize,
              fontFamily: widget.textTrack.fontFamily,
              shadows: const [
                Shadow(color: Colors.black87, offset: Offset(2, 2), blurRadius: 6),
              ],
            ),
            textAlign: widget.textTrack.alignment,
          ),
        ),
      ),
    );
  }
}