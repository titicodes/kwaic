// widgets/draggable_resizable_text.dart
import 'package:flutter/material.dart';
import '../model/text_track.dart';
import '../provider/video_editor_provider.dart';
import 'package:provider/provider.dart';

class DraggableResizableText extends StatefulWidget {
  final TextTrack textTrack;
  final Size videoSize;
  final Function(TextTrack) onUpdate;
  final bool isSelected;

  const DraggableResizableText({
    super.key,
    required this.textTrack,
    required this.videoSize,
    required this.onUpdate,
    this.isSelected = false,
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
      left: position.dx * width - 100, // rough centering offset
      top: position.dy * height - 50,
      child: GestureDetector(
        // SINGLE scale gesture handles pan + pinch + rotate
        onScaleUpdate: (details) {
          // Pan (drag)
          final newX = (position.dx + details.focalPointDelta.dx / width).clamp(0.0, 1.0);
          final newY = (position.dy + details.focalPointDelta.dy / height).clamp(0.0, 1.0);
          position = Offset(newX, newY);

          // Scale (pinch)
          scale = (scale * details.scale).clamp(0.5, 4.0);

          // Rotation
          rotation += details.rotation;

          widget.onUpdate(widget.textTrack.copyWith(
            position: position,
            scale: scale,
            rotation: rotation,
          ));
        },
        onTap: () {
          // Select text when tapped
          context.read<VideoEditorProvider>().selectTextTrack(widget.textTrack.id);
        },
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: widget.isSelected
                  ? BoxDecoration(
                border: Border.all(color: const Color(0xFF8B5CF6), width: 3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
                  : null,
              child: Text(
                widget.textTrack.text,
                textAlign: widget.textTrack.alignment,
                style: TextStyle(
                  color: widget.textTrack.color,
                  fontFamily: widget.textTrack.fontFamily,
                  fontSize: widget.textTrack.fontSize,
                  fontWeight: widget.textTrack.fontWeight,
                  fontStyle: widget.textTrack.fontStyle,
                  shadows: widget.textTrack.hasShadow
                      ? [
                    const Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 6,
                      color: Colors.black87,
                    ),
                  ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}