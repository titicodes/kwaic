

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kwaic/nes_scr/screen/video_editor_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

class VideoSelectionScreen extends StatefulWidget {
  const VideoSelectionScreen({super.key});

  @override
  State<VideoSelectionScreen> createState() => _VideoSelectionScreenState();
}

class _VideoSelectionScreenState extends State<VideoSelectionScreen> {
  final List<XFile> _selectedVideos = [];
  final Map<String, Duration?> _durations = {};
  final Map<String, String?> _thumbnails = {};
  bool _isLoading = false;
  String _projectName = 'Untitled Project';

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

      // Add videos and get metadata
      for (final video in videoFiles) {
        if (!_selectedVideos.any((v) => v.path == video.path)) {
          _selectedVideos.add(video);
          await _getVideoMetadata(video);
        }
      }

      // Auto-generate project name based on date/time
      if (_projectName == 'Untitled Project' && _selectedVideos.isNotEmpty) {
        final now = DateTime.now();
        setState(() {
          _projectName = 'Project ${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
        });
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

  Future<void> _getVideoMetadata(XFile video) async {
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
      debugPrint('Error getting metadata: $e');
    } finally {
      await controller?.dispose();
    }
  }

  void _removeVideo(int index) {
    setState(() {
      final video = _selectedVideos[index];
      _selectedVideos.removeAt(index);
      _durations.remove(video.path);
      _thumbnails.remove(video.path);
    });
  }

  void _reorderVideo(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final video = _selectedVideos.removeAt(oldIndex);
      _selectedVideos.insert(newIndex, video);
    });
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _editProjectName() async {
    final controller = TextEditingController(text: _projectName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Project Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter project name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() => _projectName = newName);
    }
  }

  void _navigateToEditor() async {
    if (_selectedVideos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one video'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              SizedBox(height: 16),
              Text(
                'Preparing videos...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final List<XFile> safeVideos = [];
      final Directory appDir = await getTemporaryDirectory();

      // Copy videos to app directory for persistent access
      for (int i = 0; i < _selectedVideos.length; i++) {
        final video = _selectedVideos[i];
        try {
          final bytes = await video.readAsBytes();
          final String newPath = '${appDir.path}/video_${DateTime.now().millisecondsSinceEpoch}_$i.mp4';
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
            const SnackBar(
              content: Text('Failed to prepare videos'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Generate unique project ID
      final projectId = DateTime.now().millisecondsSinceEpoch.toString();

      // Navigate to editor with project info
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoEditorScreen(
              initialVideos: safeVideos,
              projectId: projectId,
              projectName: _projectName,
            ),
          ),
        ).then((_) {
          // Clear selection when returning
          if (mounted) {
            setState(() {
              _selectedVideos.clear();
              _durations.clear();
              _thumbnails.clear();
              _projectName = 'Untitled Project';
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration = _durations.values
        .where((d) => d != null)
        .fold<Duration>(Duration.zero, (prev, curr) => prev + curr!);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _editProjectName,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _projectName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.edit,
                    size: 16,
                    color: Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
            if (_selectedVideos.isNotEmpty)
              Text(
                '${_selectedVideos.length} video${_selectedVideos.length > 1 ? 's' : ''} • ${_formatDuration(totalDuration)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          if (_selectedVideos.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedVideos.clear();
                  _durations.clear();
                  _thumbnails.clear();
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
          // Info banner
          if (_selectedVideos.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFF3E5FF),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Drag videos to reorder • Long press for options',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Selected videos
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF8B5CF6)),
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
                : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _selectedVideos.length,
              onReorder: _reorderVideo,
              itemBuilder: (context, index) {
                final video = _selectedVideos[index];
                final duration = _durations[video.path];

                return Container(
                  key: ValueKey(video.path),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.video_library,
                              color: Colors.white70,
                              size: 30,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      video.name.length > 25
                          ? '${video.name.substring(0, 25)}...'
                          : video.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      duration != null
                          ? _formatDuration(duration)
                          : 'Loading...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.drag_handle,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeVideo(index),
                        ),
                      ],
                    ),
                  ),
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
                      label: Text(
                        _selectedVideos.isEmpty ? 'Select Videos' : 'Add More',
                      ),
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
                      child: ElevatedButton.icon(
                        onPressed: _navigateToEditor,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Start Editing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
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
    super.dispose();
  }
}