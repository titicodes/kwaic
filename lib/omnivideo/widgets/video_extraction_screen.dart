// widgets/video_extraction_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoExtractionScreen extends StatefulWidget {
  final List<String> selectedVideos;
  final VoidCallback onExtract;

  const VideoExtractionScreen({
    super.key,
    required this.selectedVideos,
    required this.onExtract,
  });

  @override
  State<VideoExtractionScreen> createState() => _VideoExtractionScreenState();
}

class _VideoExtractionScreenState extends State<VideoExtractionScreen> {
  final Map<String, VideoPlayerController?> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final path in widget.selectedVideos) {
      final controller = VideoPlayerController.file(File(path))
        ..initialize().then((_) => setState(() {}));
      _controllers[path] = controller;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.selectedVideos.length} video${widget.selectedVideos.length > 1 ? 's' : ''} selected',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: widget.selectedVideos.length,
        itemBuilder: (_, i) {
          final path = widget.selectedVideos[i];
          final controller = _controllers[path];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 100,
                    height: 60,
                    child: controller != null && controller.value.isInitialized
                        ? AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    )
                        : const ColoredBox(
                      color: Colors.grey,
                      child: Icon(Icons.videocam, color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    path.split('/').last,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: widget.onExtract,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6), // Purple
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Extract and add',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}