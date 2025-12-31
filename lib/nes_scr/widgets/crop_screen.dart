import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_editor_2/ui/video_viewer.dart';
import 'package:video_editor_2/video_editor.dart';
import 'package:cross_file/cross_file.dart';
import '../model/timeline_item.dart';

class CropScreen extends StatefulWidget {
  final File videoFile;
  final TimelineItem clip;

  const CropScreen({
    super.key,
    required this.videoFile,
    required this.clip,
  });

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  late VideoEditorController _controller;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  void _createController() async {
    try {
      final xfile = XFile(widget.videoFile.path);
      _controller = VideoEditorController.file(
        xfile,
        minDuration: Duration.zero,
        maxDuration: const Duration(hours: 10),
      );

      // Restore rotation
      if (widget.clip.rotation != 0) {
        final turns = (widget.clip.rotation! ~/ 90).abs() % 4;
        for (int i = 0; i < turns; i++) {
          _controller.rotate90Degrees(RotateDirection.right);
        }
      }

      // Restore aspect ratio
      if (widget.clip.cropAspectRatio != null) {
        _controller.preferredCropAspectRatio = widget.clip.cropAspectRatio!;
      }

      // Restore crop from Rect
      if (widget.clip.cropRect != null) {
        _controller.updateCrop(
          Offset(widget.clip.cropRect!.left, widget.clip.cropRect!.top),
          Offset(widget.clip.cropRect!.right, widget.clip.cropRect!.bottom),
        );
      }

      await _controller.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Crop init error: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.initialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Resize', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.cyan),
            onPressed: () async {
              // Correct crop values from video_editor_2
              final min = _controller.minCrop;
              final max = _controller.maxCrop;

              // Save as normalized Rect (0.0–1.0)
              widget.clip.cropRect = Rect.fromLTRB(
                min.dx,  // left
                min.dy,  // top
                max.dx,  // right
                max.dy,  // bottom
              );

              widget.clip.rotation = _controller.rotation * 90;
              widget.clip.cropAspectRatio = _controller.preferredCropAspectRatio;

              // Just pop — parent will update the clip
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // MAIN FIX: Use VideoEditorPreview + CropGridViewer together
          Expanded(
            child: Stack(
              children: [
                CropGridViewer.preview( // ← Preview the video
                  controller: _controller,
                ),
                CropGridViewer.edit( // ← Overlay crop grid
                  controller: _controller,
                  rotateCropArea: true,
                ),
              ],
            ),
          ),
          // Bottom controls — matching your screenshot
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _tabButton('Crop', true),
                    const SizedBox(width: 32),
                    _tabButton('AI expand', false),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    const Text('Rotate', style: TextStyle(color: Colors.white)),
                    Expanded(
                      child: Slider(
                        value: _controller.rotation * 90,
                        min: -20,
                        max: 20,
                        divisions: 40,
                        activeColor: Colors.cyan,
                        onChanged: (value) {
                          final targetTurns = (value / 90).round();
                          final diff = targetTurns - _controller.rotation;
                          if (diff > 0) {
                            for (int i = 0; i < diff; i++) {
                              _controller.rotate90Degrees(RotateDirection.right);
                            }
                          } else {
                            for (int i = 0; i < -diff; i++) {
                              _controller.rotate90Degrees(RotateDirection.left);
                            }
                          }
                          setState(() {});
                        },
                      ),
                    ),
                    Text('${(_controller.rotation * 90).toInt()}°', style: const TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 20),

                const Text('Aspect ratio', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _aspectButton(null, 'Custom'),
                    _aspectButton(9 / 16, '9:16'),
                    _aspectButton(16 / 9, '16:9'),
                    _aspectButton(1 / 1, '1:1'),
                    _aspectButton(4 / 3, '4:3'),
                  ],
                ),
                const SizedBox(height: 16),

                TextButton.icon(
                  onPressed: () async {
                    await _controller.dispose();
                     _createController();
                  },
                  icon: const Icon(Icons.restore, color: Colors.white),
                  label: const Text('Reset', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ... keep your _tabButton and _aspectButton as before


  Widget _tabButton(String title, bool selected) {
    return GestureDetector(
      onTap: () {}, // Only Crop tab active
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: selected ? Colors.cyan : Colors.white70,
              fontSize: 16,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (selected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 60,
              color: Colors.cyan,
            ),
        ],
      ),
    );
  }

  Widget _aspectButton(double? ratio, String label) {
    final isSelected = _controller.preferredCropAspectRatio == ratio;
    return GestureDetector(
      onTap: () => setState(() => _controller.preferredCropAspectRatio = ratio),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.cyan : Colors.grey),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}