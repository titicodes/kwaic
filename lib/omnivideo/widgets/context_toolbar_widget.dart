import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/video_editor_provider.dart';

class EditContextToolbar extends StatelessWidget {
  const EditContextToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VideoEditorProvider>(context);
    final toolbarType = provider.toolbarType;

    // Show only when toolbar is requested
    if (!provider.showContextToolbar) return const SizedBox.shrink();

    if (toolbarType == 'audio') {
      return _buildAudioToolbar(context, provider);
    }

    // Default to edit mode (requires selection)
    if (provider.selectedVideoTrackId == null) {
      return const SizedBox.shrink();
    }

    return _buildEditToolbar(context, provider);
  }

  Widget _buildAudioToolbar(BuildContext context, VideoEditorProvider provider) {
    return Container(
      height: 80,
      color: Colors.black.withOpacity(0.95),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 16),
            _tool(Icons.audiotrack, 'Extract', () {
              // provider.openToolSheet('extract'); // if you have extract sheet
            }),
            _tool(Icons.music_note, 'Sound', () => provider.openToolSheet('audio')),
            _tool(Icons.graphic_eq, 'Sound FX', () {}),
            _tool(Icons.mic, 'Record', () {}),
            _tool(Icons.record_voice_over, 'Text to Audio', () {}),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEditToolbar(BuildContext context, VideoEditorProvider provider) {
    return Container(
      height: 80,
      color: Colors.black.withOpacity(0.95),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 16),
            _tool(Icons.content_cut, 'Trim', () => provider.openToolSheet('trim')),
            _tool(Icons.speed, 'Speed', () {
              provider.openToolSheet('speed');  // ← This method must exist
            }),
            _tool(Icons.rotate_90_degrees_ccw, 'Rotate', () {
              provider.openToolSheet('rotate');
            }),
            _tool(Icons.flip, 'Flip', () => provider.openToolSheet('flip')),
            _tool(Icons.fit_screen, 'Fill', () => provider.openToolSheet('fill')),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _tool(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
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
      ),
    );
  }
}