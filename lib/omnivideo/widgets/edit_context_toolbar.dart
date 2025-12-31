// edit_context_toolbar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/video_editor_provider.dart';

class EditContextToolbar extends StatelessWidget {
  const EditContextToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VideoEditorProvider>(context);

    return Container(
      height: 80,
      color: Colors.black.withOpacity(0.95),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToolItem(Icons.content_cut, 'Trim', 'trim', provider),
                  const SizedBox(width: 16),
                  _buildToolItem(
                    Icons.rotate_90_degrees_ccw,
                    'Rotate',
                    'rotate',
                    provider,
                  ),
                  const SizedBox(width: 16),
                  _buildToolItem(Icons.flip, 'Flip', 'flip', provider),
                  const SizedBox(width: 16),
                  _buildToolItem(Icons.fit_screen, 'Fill', 'fill', provider),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildToolItem(
    IconData icon,
    String label,
    String tool,
    VideoEditorProvider provider,
  ) {
    return GestureDetector(
      onTap: () {
        provider.currentTool = tool;

        if (tool == 'trim') {
          // Reset trim values to current clip duration
          final duration = provider.videoController!.value.duration;
          provider.trimStart = Duration.zero;
          provider.trimEnd = duration;

          provider.showBottomSheet = true;
          provider.showContextToolbar = false;
        } else {
          // For rotate, flip, fill → show bottom sheet, hide toolbar
          provider.showBottomSheet = true;
          provider.showContextToolbar = false;
        }
      },

      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
