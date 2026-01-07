import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/video_editor_provider.dart';
import '../model/text_track.dart';

class TextOverlayLayer extends StatelessWidget {
  const TextOverlayLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();
    final pos = provider.currentPosition;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: provider.textTracks
              .where((t) => pos >= t.startTime && pos <= t.endTime)
              .map((track) => _TextItem(
            track: track,
            size: constraints.biggest,
          ))
              .toList(),
        );
      },
    );
  }
}

class _TextItem extends StatelessWidget {
  final TextTrack track;
  final Size size;

  const _TextItem({required this.track, required this.size});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<VideoEditorProvider>();

    final left = track.position.dx * size.width;
    final top = track.position.dy * size.height;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => provider.selectedText = track,
        onPanUpdate: (d) {
          final dx = (left + d.delta.dx).clamp(0.0, size.width);
          final dy = (top + d.delta.dy).clamp(0.0, size.height);

          provider.updateTextPosition(
            track,
            Offset(dx / size.width, dy / size.height),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: provider.selectedText?.id == track.id
              ? BoxDecoration(
            border: Border.all(color: const Color(0xFF8B5CF6)),
          )
              : null,
          child: Text(
            track.text,
            style: TextStyle(
              fontSize: track.fontSize,
              color: track.color,
            ),
          ),
        ),
      ),
    );
  }
}
