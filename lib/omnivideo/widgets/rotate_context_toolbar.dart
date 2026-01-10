// widgets/rotate_context_toolbar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/video_editor_provider.dart';

class RotateContextToolbar extends StatelessWidget {
  const RotateContextToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VideoEditorProvider>(context);

    return Container(
      height: 80,
      color: Colors.black.withOpacity(0.95),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolItem(Icons.rotate_left, '-90°', () => provider.applyRotation(-90)),
          _toolItem(Icons.rotate_right, '+90°', () => provider.applyRotation(90)),
          _toolItem(Icons.refresh, 'Reset', () {
            provider.rotation = 0;
            provider.closeContextToolbar();
          }),
        ],
      ),
    );
  }

  Widget _toolItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}