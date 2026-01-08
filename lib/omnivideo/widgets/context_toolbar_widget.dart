// widgets/edit_context_toolbar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/video_editor_provider.dart';

class EditContextToolbar extends StatelessWidget {
  const EditContextToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VideoEditorProvider>(context);
    final bool hasSelection = provider.selectedVideoTrackId != null || provider.selectedAudioTrack != null;

    // Only show if something is selected
    if (!hasSelection) return const SizedBox.shrink();

    final bool isVideo = provider.selectedVideoTrackId != null;
    final bool isAudio = provider.selectedAudioTrack != null;

    return Container(
      height: 80,
      color: Colors.black.withOpacity(0.95),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 16),
            // Common tools
            _tool(Icons.content_cut, 'Trim', () => provider.selectTool('trim')),
            const SizedBox(width: 12),
            _tool(Icons.call_split, 'Split', () {
              final pos = provider.currentPosition;
              if (provider.selectedVideoTrackId != null) {
                provider.splitVideoAt(pos);
              } else if (provider.selectedAudioTrack != null) {
                provider.splitAudioAt(pos);
              }
            }),
            const SizedBox(width: 12),
            _tool(Icons.swap_horiz, 'Replace', () {
              if (isAudio) provider.openTool('audio'); // Replace mode
              // Video replace can be added later
            }),
            const SizedBox(width: 12),

            // Video-only tools
            if (isVideo) ...[
              _tool(Icons.rotate_90_degrees_ccw, 'Rotate', () => provider.selectTool('rotate')),
              const SizedBox(width: 12),
              _tool(Icons.flip, 'Flip', () => provider.selectTool('flip')),
              const SizedBox(width: 12),
              _tool(Icons.fit_screen, 'Fill', () => provider.selectTool('fill')),
              const SizedBox(width: 12),
            ],
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