import 'dart:io';

import 'package:flutter/material.dart';

import '../model/timeline_item.dart';


class Timeline extends StatefulWidget {
  final List<TimelineItem> clips;
  final List<TimelineItem> audioItems;
  final List<TimelineItem> textItems;
  final List<TimelineItem> overlayItems;
  final Duration playheadPosition;
  final int? selectedClip;
  final Function(Duration) onSeek;
  final Function(TimelineItem) onClipSelected;
  final Function(TimelineItem) onSplitClip;
  final Function(TimelineItem, double) onClipDragged;
  final Function(TimelineItem, double) onClipTrimStart;
  final Function(TimelineItem, double) onClipTrimEnd;

  const Timeline({
    Key? key,
    required this.clips,
    required this.audioItems,
    required this.textItems,
    required this.overlayItems,
    required this.playheadPosition,
    required this.selectedClip,
    required this.onSeek,
    required this.onClipSelected,
    required this.onSplitClip,
    required this.onClipDragged,
    required this.onClipTrimStart,
    required this.onClipTrimEnd,
  }) : super(key: key);

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  late ScrollController _scrollController;
  double _zoomLevel = 1.0;
  double _trackHeight = 60.0;
  double? _dragStartX;
  TimelineItem? _draggedClip;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildZoomControls(),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            child: Stack(
              children: [
                _buildTracks(),
                _buildPlayhead(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoomControls() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.zoom_out),
          onPressed: () => setState(() => _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 2.0)),
        ),
        IconButton(
          icon: const Icon(Icons.zoom_in),
          onPressed: () => setState(() => _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 2.0)),
        ),
      ],
    );
  }

  Widget _buildTracks() {
    return Column(
      children: [
        _buildTrack('Video', widget.clips, Colors.blue),
        _buildTrack('Audio', widget.audioItems, Colors.green),
        _buildTrack('Text', widget.textItems, Colors.orange),
        _buildTrack('Overlay', widget.overlayItems, Colors.purple),
      ],
    );
  }

  Widget _buildTrack(String label, List<TimelineItem> clips, Color color) {
    return SizedBox(
      height: _trackHeight,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(label, style: TextStyle(color: color)),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ...clips.map((clip) => _buildClip(clip, color)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClip(TimelineItem clip, Color color) {
    final clipWidth = clip.duration.inMilliseconds / 500 * _zoomLevel;
    final isSelected = widget.selectedClip == int.tryParse(clip.id);

    return Positioned(
      left: clip.startTime.inMilliseconds / 500,
      child: GestureDetector(
        onTap: () => widget.onClipSelected(clip),
        onLongPressStart: (details) => _startDrag(clip, details.globalPosition.dx),
        onLongPressMoveUpdate: (details) => _updateDrag(clip, details.globalPosition.dx),
        child: Container(
          width: clipWidth,
          height: _trackHeight - 10,
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.7) : color.withOpacity(0.3),
            border: Border.all(color: color, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              if (clip.thumbnailPaths.isNotEmpty && clip.type == TimelineItemType.video)
                Positioned.fill(
                  child: Image.file(File(clip.thumbnailPaths.first), fit: BoxFit.cover),
                ),
              if (clip.type == TimelineItemType.image && clip.file != null)
                Positioned.fill(
                  child: Image.file(clip.file!, fit: BoxFit.cover),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => widget.onSplitClip(clip),
                  child: Container(
                    width: 20,
                    color: Colors.black54,
                    child: const Icon(Icons.content_cut, size: 16),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    GestureDetector(
                      onHorizontalDragUpdate: (details) =>
                          widget.onClipTrimStart(clip, details.delta.dx),
                      child: Container(width: 10, color: Colors.black26),
                    ),
                    Expanded(child: Container()),
                    GestureDetector(
                      onHorizontalDragUpdate: (details) =>
                          widget.onClipTrimEnd(clip, details.delta.dx),
                      child: Container(width: 10, color: Colors.black26),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayhead() {
    return Positioned(
      left: widget.playheadPosition.inMilliseconds / 500,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onPanUpdate: (details) => widget.onSeek(
          Duration(milliseconds: (details.globalPosition.dx * 500).toInt()),
        ),
        child: Container(
          width: 2,
          color: Colors.red,
          child: const Icon(Icons.play_arrow, color: Colors.red, size: 20),
        ),
      ),
    );
  }

  void _startDrag(TimelineItem clip, double startX) {
    setState(() {
      _dragStartX = startX;
      _draggedClip = clip;
    });
  }

  void _updateDrag(TimelineItem clip, double currentX) {
    if (_dragStartX == null) return;
    final delta = currentX - _dragStartX!;
    widget.onClipDragged(clip, delta);
    _dragStartX = currentX;
  }
}
