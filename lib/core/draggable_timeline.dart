// video_editor_screen.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:undo/undo.dart';

import 'clip_model.dart';
import 'editor_controller.dart';

/// ---------------------------------------------------------------
///  DRAGGABLE TIMELINE (CapCut style)
/// ---------------------------------------------------------------
class DraggableTimeline extends StatefulWidget {
  final File videoFile;
  final double durationMs;
  final double startMs;
  final double endMs;
  final ValueChanged<double> onStartChanged;
  final ValueChanged<double> onEndChanged;

  const DraggableTimeline({
    super.key,
    required this.videoFile,
    required this.durationMs,
    required this.startMs,
    required this.endMs,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  State<DraggableTimeline> createState() => _DraggableTimelineState();
}

class _DraggableTimelineState extends State<DraggableTimeline> {
  final List<File> _thumbs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnails();
  }

  Future<void> _generateThumbnails() async {
    final thumbs = <File>[];
    const frameCount = 12;
    for (int i = 0; i < frameCount; i++) {
      final ms = (i / frameCount) * widget.durationMs;
      final path = await VideoThumbnail.thumbnailFile(
        video: widget.videoFile.path,
        timeMs: ms.toInt(),
        imageFormat: ImageFormat.JPEG,
        quality: 70,
      );
      if (path != null) thumbs.add(File(path));
    }
    setState(() {
      _thumbs.clear();
      _thumbs.addAll(thumbs);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final startX = (widget.startMs / widget.durationMs) * width;
      final endX = (widget.endMs / widget.durationMs) * width;

      return Stack(
        children: [
          // ---- thumbnails ----
          Row(
            children: _thumbs
                .map((f) => Image.file(
              f,
              width: width / _thumbs.length,
              height: 80,
              fit: BoxFit.cover,
            ))
                .toList(),
          ),

          // ---- dark overlay outside trim ----
          Positioned.fill(
            child: Row(
              children: [
                Container(width: startX, color: Colors.black54),
                Container(width: endX - startX, color: Colors.transparent),
                Expanded(child: Container(color: Colors.black54)),
              ],
            ),
          ),

          // ---- start handle ----
          Positioned(
            left: startX - 8,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) {
                final newX = startX + d.delta.dx;
                final newMs = (newX / width) * widget.durationMs;
                if (newMs >= 0 && newMs < widget.endMs) {
                  widget.onStartChanged(newMs);
                }
              },
              child: Container(width: 16, color: Colors.orangeAccent),
            ),
          ),

          // ---- end handle ----
          Positioned(
            left: endX - 8,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) {
                final newX = endX + d.delta.dx;
                final newMs = (newX / width) * widget.durationMs;
                if (newMs <= widget.durationMs && newMs > widget.startMs) {
                  widget.onEndChanged(newMs);
                }
              },
              child: Container(width: 16, color: Colors.orangeAccent),
            ),
          ),
        ],
      );
    });
  }
}

/// ---------------------------------------------------------------
///  MAIN EDITOR SCREEN
/// ---------------------------------------------------------------
