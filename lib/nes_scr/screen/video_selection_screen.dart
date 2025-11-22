import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kwaic/nes_scr/screen/video_editor_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class VideoSelectionScreen extends StatefulWidget {
  const VideoSelectionScreen({super.key});

  @override
  State<VideoSelectionScreen> createState() => _VideoSelectionScreenState();
}

class _VideoSelectionScreenState extends State<VideoSelectionScreen> {
  final List<XFile> _selectedVideos = [];
  final Map<String, Duration?> _durations = {};
  bool _isLoading = false;

  Future<void> _pickVideos() async {
    try {
      final picker = ImagePicker();
      final List<XFile>? pickedFiles = await picker.pickMultipleMedia();

      if (pickedFiles == null || pickedFiles.isEmpty) return;

      setState(() => _isLoading = true);

      // Filter video files
      final videoFiles = pickedFiles.where((f) {
        final path = f.path.toLowerCase();
        return path.endsWith('.mp4') ||
            path.endsWith('.mov') ||
            path.endsWith('.avi') ||
            path.endsWith('.mkv') ||
            path.endsWith('.webm') ||
            path.endsWith('.m4v') ||
            path.endsWith('.3gp');
      }).toList();

      if (videoFiles.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No video files found'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Add videos and generate thumbnails
      for (final video in videoFiles) {
        if (!_selectedVideos.any((v) => v.path == video.path)) {
          _selectedVideos.add(video);
          await _getVideoDuration(video);
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking videos: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }



  Future<void> _getVideoDuration(XFile video) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(video.path));
      await controller.initialize();

      if (mounted) {
        setState(() {
          _durations[video.path] = controller?.value.duration;
        });
      }
    } catch (e) {
      debugPrint('Error getting duration: $e');
    } finally {
      await controller?.dispose();
    }
  }

  void _removeVideo(int index) {
    setState(() {
      final video = _selectedVideos[index];
      _selectedVideos.removeAt(index);
          _durations.remove(video.path);
    });
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _navigateToEditor() async {
    if (_selectedVideos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one video'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            SizedBox(height: 16),
            Text('Preparing videos...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    final List<XFile> safeVideos = [];

    // ← THIS LINE WAS MISSING ←
    final Directory appDir = await getTemporaryDirectory();

    for (final video in _selectedVideos) {
      try {
        final bytes = await video.readAsBytes();
        final String newPath = '${appDir.path}/video_${DateTime.now().millisecondsSinceEpoch}_${video.name}';
        await File(newPath).writeAsBytes(bytes);
        safeVideos.add(XFile(newPath));
      } catch (e) {
        debugPrint('Failed to copy video: $e');
      }
    }

    // Close loading dialog
    if (mounted) Navigator.of(context).pop();

    if (safeVideos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to prepare videos'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Navigate with permanent safe paths
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoEditorScreen(initialVideos: safeVideos),
        ),
      ).then((_) {
        // Optional: clear selection when returning
        setState(() {
          _selectedVideos.clear();
          _durations.clear();
        });
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selectedVideos.isEmpty
              ? 'Select Videos'
              : '${_selectedVideos.length} selected',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_selectedVideos.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedVideos.clear();
                                   _durations.clear();
                });
              },
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Selected videos grid
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF8B5CF6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading videos...',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : _selectedVideos.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No videos selected',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button below to add videos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: _selectedVideos.length,
              itemBuilder: (context, index) {
                final video = _selectedVideos[index];
                final duration = _durations[video.path];

                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.video_library, color: Colors.white70, size: 40),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removeVideo(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    if (duration != null)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            _formatDuration(duration),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Add more videos button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _pickVideos,
                      icon: const Icon(Icons.add),
                      label: Text(_selectedVideos.isEmpty
                          ? 'Select Videos'
                          : 'Add More'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5CF6),
                        side: const BorderSide(
                          color: Color(0xFF8B5CF6),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  if (_selectedVideos.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    // Next button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _navigateToEditor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up thumbnails
    super.dispose();
  }
}

