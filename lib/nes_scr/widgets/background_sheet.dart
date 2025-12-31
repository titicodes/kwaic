import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../model/timeline_item.dart';
import '../servuices/clip_controller.dart';
import '../servuices/video_manager.dart';

class BackgroundSheet extends StatefulWidget {
  final ClipController clipController;
  final VideoManager videoManager;

  const BackgroundSheet({
    super.key,
    required this.clipController,
    required this.videoManager,
  });

  @override
  State<BackgroundSheet> createState() => _BackgroundSheetState();
}

class _BackgroundSheetState extends State<BackgroundSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      builder: (_, controller) => Container(
        color: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Background', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                padding: const EdgeInsets.all(16),
                children: [
                  _bgOption(Colors.black, 'Black'),
                  _bgOption(Colors.white, 'White'),
                  _bgOption(Colors.blue, 'Blue'),
                  _bgOption(Colors.red, 'Red'),
                  _bgOption(Colors.green, 'Green'),
                  _bgOption(Colors.purple, 'Purple'),
                  _bgOption(null, 'Blur', icon: Icons.blur_on),
                  _bgOption(null, 'Image', icon: Icons.image),
                  _bgOption(null, 'Video', icon: Icons.videocam),
                  if (widget.clipController.backgroundVisual != null)
                    _bgOption(null, 'Remove', icon: Icons.delete,),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bgOption(Color? color, String label, {IconData? icon, Color? colorOverride}) {
    return GestureDetector(
      onTap: () async {
        if (label == 'Remove') {
          widget.clipController.removeBackgroundVisual();
          Navigator.pop(context);
          return;
        }

        if (label == 'Blur') {
          final sigma = await _showBlurSlider();
          if (sigma != null) {
            final item = TimelineItem(
              id: 'bg_blur',
              type: TimelineItemType.backgroundVisual,
              blurSigma: sigma,
            );
            widget.clipController.setBackgroundVisual(item);
          }
        } else if (label == 'Image') {
          final picker = ImagePicker();
          final xfile = await picker.pickImage(source: ImageSource.gallery);
          if (xfile != null) {
            final item = TimelineItem(
              id: 'bg_image',
              type: TimelineItemType.backgroundVisual,
              file: File(xfile.path),
            );
            widget.clipController.setBackgroundVisual(item);
          }
        } else if (label == 'Video') {
          final picker = ImagePicker();
          final xfile = await picker.pickVideo(source: ImageSource.gallery);
          if (xfile != null) {
            final item = TimelineItem(
              id: 'bg_video',
              type: TimelineItemType.backgroundVisual,
              file: File(xfile.path),
            );
            widget.clipController.setBackgroundVisual(item);
            await widget.videoManager.initializeBackgroundController(File(xfile.path));
          }
        } else if (color != null) {
          final item = TimelineItem(
            id: 'bg_color',
            type: TimelineItemType.backgroundVisual,
            backgroundColor: color,
          );
          widget.clipController.setBackgroundVisual(item);
        }

        if (mounted) Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color ?? Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: colorOverride ?? Colors.white, size: 32),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Future<double?> _showBlurSlider() async {
    double sigma = 10.0;
    return showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Blur Intensity', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (_, setState) => Slider(
            value: sigma,
            min: 0,
            max: 30,
            divisions: 30,
            label: sigma.toStringAsFixed(1),
            onChanged: (v) => setState(() => sigma = v),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, sigma), child: const Text('Apply')),
        ],
      ),
    );
  }
}