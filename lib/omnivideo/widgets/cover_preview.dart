import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../provider/video_editor_provider.dart';

class CoverBox extends StatelessWidget {
  const CoverBox({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<VideoEditorProvider>();

    return GestureDetector(
      onTap: provider.selectCover,
      child: _box(
        Column(
          children: [
            SizedBox(
              height: 25,
              child: provider.videoController != null &&
                  provider.videoController!.value.isInitialized
                  ? VideoPlayer(provider.videoController!) // ✅ SAFE NOW
                  : provider.selectedCover != null
                  ? Image.memory(
                provider.selectedCover!,
                fit: BoxFit.cover,
              )
                  : const Icon(Icons.photo, color: Colors.white),
            ),
            const Text(
              'Cover',
              style: TextStyle(fontSize: 8, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(Widget child) {
    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
