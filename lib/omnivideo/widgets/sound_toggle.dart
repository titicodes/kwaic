import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/video_editor_provider.dart';

class SoundToggleBox extends StatelessWidget {
  const SoundToggleBox({super.key});

  @override
  Widget build(BuildContext context) {
    final isSoundOn = context.select<VideoEditorProvider, bool>(
          (p) => p.isSoundOn,
    );

    return GestureDetector(
      onTap: context.read<VideoEditorProvider>().toggleSound,
      child: _box(
        Column(
          children: [
            Icon(
              isSoundOn ? Icons.volume_up : Icons.volume_off,
              size: 16,
              color: Colors.white,
            ),
            Text(
              isSoundOn ? 'Sound\nOn' : 'Sound\nOff',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8, color: Colors.white70),
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