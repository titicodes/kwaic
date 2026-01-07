import 'package:flutter/material.dart';
import '../model/text_track.dart';

class DraggableResizableText extends StatefulWidget {
  final TextTrack textTrack;
  final Size videoSize;
  final Function(TextTrack) onUpdate;

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
  late double scale;
  late double rotation;

  @override
  void initState() {
    super.initState();
    position = widget.textTrack.position;
    scale = widget.textTrack.scale;
    rotation = widget.textTrack.rotation;
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.videoSize.width;
    final height = widget.videoSize.height;

    return Positioned(
      left: position.dx * width,
      top: position.dy * height,
      child: GestureDetector(
        onPanUpdate: (details) {
          final dx = ((position.dx * width + details.delta.dx) / width).clamp(0.0, 1.0);
          final dy = ((position.dy * height + details.delta.dy) / height).clamp(0.0, 1.0);
          setState(() => position = Offset(dx, dy));
          widget.onUpdate(widget.textTrack.copyWith(position: position));
        },
        onScaleUpdate: (details) {
          setState(() {
            scale = (scale * details.scale).clamp(0.5, 5.0);
            rotation += details.rotation;
          });
          widget.onUpdate(widget.textTrack.copyWith(scale: scale, rotation: rotation));
        },
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: widget.textTrack == widget.textTrack
                  ? BoxDecoration(
                border: Border.all(color: const Color(0xFF8B5CF6)),
              )
                  : null,
              child: Text(
                widget.textTrack.text,
                textAlign: widget.textTrack.alignment,
                style: TextStyle(
                  color: widget.textTrack.color,
                  fontFamily: widget.textTrack.fontFamily,
                  fontSize: widget.textTrack.fontSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
