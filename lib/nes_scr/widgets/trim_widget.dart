import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoTrimWidget extends StatefulWidget {
  final String videoPath;
  final Duration startValue;
  final Duration endValue;
  final Duration maxDuration;
  final Function(Duration start, Duration end) onTrimChanged;

  const VideoTrimWidget({
    super.key,
    required this.videoPath,
    required this.startValue,
    required this.endValue,
    required this.maxDuration,
    required this.onTrimChanged,
  });

  @override
  State<VideoTrimWidget> createState() => _VideoTrimWidgetState();
}

class _VideoTrimWidgetState extends State<VideoTrimWidget> {
  late Duration _startValue;
  late Duration _endValue;
  VideoPlayerController? _thumbnailController;
  List<Widget> _thumbnails = [];
  bool _isGeneratingThumbnails = false;

  @override
  void initState() {
    super.initState();
    _startValue = widget.startValue;
    _endValue = widget.endValue;
    _initializeThumbnails();
  }

  Future<void> _initializeThumbnails() async {
    setState(() {
      _isGeneratingThumbnails = true;
    });

    _thumbnailController = VideoPlayerController.file(File(widget.videoPath));
    await _thumbnailController!.initialize();

    // Generate thumbnail frames
    final thumbnailCount = 20;
    final interval = widget.maxDuration.inMilliseconds / thumbnailCount;

    List<Widget> thumbs = [];
    for (int i = 0; i < thumbnailCount; i++) {
      thumbs.add(
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }

    setState(() {
      _thumbnails = thumbs;
      _isGeneratingThumbnails = false;
    });
  }

  void _onLeftDragUpdate(DragUpdateDetails details, double containerWidth) {
    final dx = details.delta.dx;
    final totalWidth = containerWidth - 40; // Subtract handle widths
    final durationPerPixel = widget.maxDuration.inMilliseconds / totalWidth;
    final durationChange = (dx * durationPerPixel).round();

    setState(() {
      var newStart = Duration(
        milliseconds: _startValue.inMilliseconds + durationChange,
      );

      if (newStart.isNegative) {
        newStart = Duration.zero;
      }

      if (newStart < _endValue - const Duration(seconds: 1)) {
        _startValue = newStart;
        widget.onTrimChanged(_startValue, _endValue);
      }
    });
  }

  void _onRightDragUpdate(DragUpdateDetails details, double containerWidth) {
    final dx = details.delta.dx;
    final totalWidth = containerWidth - 40;
    final durationPerPixel = widget.maxDuration.inMilliseconds / totalWidth;
    final durationChange = (dx * durationPerPixel).round();

    setState(() {
      var newEnd = Duration(
        milliseconds: _endValue.inMilliseconds + durationChange,
      );

      if (newEnd > widget.maxDuration) {
        newEnd = widget.maxDuration;
      }

      if (newEnd > _startValue + const Duration(seconds: 1)) {
        _endValue = newEnd;
        widget.onTrimChanged(_startValue, _endValue);
      }
    });
  }

  @override
  void dispose() {
    _thumbnailController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final containerWidth = MediaQuery.of(context).size.width - 32;
    final leftPosition = (_startValue.inMilliseconds / widget.maxDuration.inMilliseconds) * (containerWidth - 40);
    final rightPosition = ((_endValue.inMilliseconds / widget.maxDuration.inMilliseconds) * (containerWidth - 40));

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          // Thumbnail strip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _isGeneratingThumbnails
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Row(children: _thumbnails),
            ),
          ),

          // Left trimmer handle
          Positioned(
            left: leftPosition,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) =>
                  _onLeftDragUpdate(details, containerWidth),
              child: Container(
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.drag_handle,
                    color: Colors.black,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),

          // Right trimmer handle
          Positioned(
            left: rightPosition + 20,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) =>
                  _onRightDragUpdate(details, containerWidth),
              child: Container(
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.drag_handle,
                    color: Colors.black,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),

          // Overlay outside trim area - left
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: leftPosition + 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          ),

          // Overlay outside trim area - right
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: containerWidth - rightPosition - 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          ),

          // Time labels
          Positioned(
            left: leftPosition,
            top: -20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDuration(_startValue),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            left: rightPosition + 20,
            top: -20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDuration(_endValue),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}