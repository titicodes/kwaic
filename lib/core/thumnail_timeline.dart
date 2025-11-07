// lib/widgets/thumbnail_timeline.dart
import 'dart:io';
import 'package:flutter/material.dart';

class ThumbnailTimeline extends StatefulWidget {
  final List<String> thumbs;
  final double durationMs;
  final double startMs;
  final double endMs;
  final ValueChanged<double> onStart;
  final ValueChanged<double> onEnd;
  final ValueChanged<double>? onSeek;
  final double currentMs; // playback position (ms)
  final ValueChanged<double>? onPlayheadDrag; // when user drags playhead

  const ThumbnailTimeline({
    super.key,
    required this.thumbs,
    required this.durationMs,
    required this.startMs,
    required this.endMs,
    required this.onStart,
    required this.onEnd,
    this.onSeek,
    this.currentMs = 0,
    this.onPlayheadDrag,
  });

  @override
  State<ThumbnailTimeline> createState() => _ThumbnailTimelineState();
}

class _ThumbnailTimelineState extends State<ThumbnailTimeline> {
  late double _localStart;
  late double _localEnd;
  bool _draggingPlayhead = false;

  @override
  void initState() {
    super.initState();
    _localStart = widget.startMs;
    _localEnd = widget.endMs;
  }

  @override
  void didUpdateWidget(covariant ThumbnailTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if not dragging, reflect external updates
    if (!_draggingPlayhead) {
      _localStart = widget.startMs;
      _localEnd = widget.endMs;
    }
  }

  double _msToX(double ms, double width) => (ms / widget.durationMs) * width;
  double _xToMs(double x, double width) => (x / width) * widget.durationMs;

  @override
  Widget build(BuildContext context) {
    if (widget.thumbs.isEmpty) {
      return SizedBox(height: 88, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    return LayoutBuilder(builder: (context, cons) {
      final width = cons.maxWidth;
      final thumbW = width / widget.thumbs.length;
      final startX = _msToX(_localStart, width);
      final endX = _msToX(_localEnd, width);
      final playheadX = _msToX(widget.currentMs.clamp(0, widget.durationMs), width);

      return GestureDetector(
        onTapDown: (ev) {
          final ms = _xToMs(ev.localPosition.dx, width);
          widget.onSeek?.call(ms);
        },
        child: Stack(
          children: [
            Row(children: widget.thumbs.map((p) => Image.file(File(p), width: thumbW, height: 88, fit: BoxFit.cover)).toList()),
            // outside shaded
            Positioned.fill(
              child: IgnorePointer(
                child: Row(children: [
                  Container(width: startX, color: Colors.black.withOpacity(0.5)),
                  Container(width: (endX - startX).clamp(0.0, width), color: Colors.transparent),
                  Expanded(child: Container(color: Colors.black.withOpacity(0.5))),
                ]),
              ),
            ),
            // Start handle
            Positioned(
              left: startX - 12,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (d) {
                  final nx = (startX + d.delta.dx).clamp(0.0, endX - 24.0);
                  final newMs = _xToMs(nx, width);
                  setState(() => _localStart = newMs);
                  widget.onStart(newMs);
                },
                onHorizontalDragEnd: (_) {
                  // final sync
                },
                child: Container(width: 24, color: Colors.purpleAccent),
              ),
            ),
            // End handle
            Positioned(
              left: endX - 12,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (d) {
                  final nx = (endX + d.delta.dx).clamp(startX + 24.0, width);
                  final newMs = _xToMs(nx, width);
                  setState(() => _localEnd = newMs);
                  widget.onEnd(newMs);
                },
                child: Container(width: 24, color: Colors.purpleAccent),
              ),
            ),
            // Playhead draggable
            Positioned(
              left: (playheadX - 1).clamp(0.0, width - 2),
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: (_) {
                  _draggingPlayhead = true;
                },
                onHorizontalDragUpdate: (d) {
                  final nx = (playheadX + d.delta.dx).clamp(0.0, width);
                  final newMs = _xToMs(nx, width);
                  widget.onPlayheadDrag?.call(newMs);
                },
                onHorizontalDragEnd: (_) {
                  _draggingPlayhead = false;
                },
                child: Container(width: 2, color: Colors.white),
              ),
            ),
            // Centered visual marker (optional) - removed to use movable playhead
          ],
        ),
      );
    });
  }
}
