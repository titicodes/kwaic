// widgets/audio_context_toolbar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/video_editor_provider.dart';

class AudioContextToolbar extends StatelessWidget {
  const AudioContextToolbar({super.key});

  Widget _toolItem({
    required IconData icon,
    required String label,
    required String action,
  }) {
    return Consumer<VideoEditorProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: () {
            provider.handleAudioToolTap(action, context: context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.black.withOpacity(0.95),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 16),
            _toolItem(icon: Icons.audiotrack, label: 'Extract', action: 'extract'),
            const SizedBox(width: 16),
            _toolItem(icon: Icons.music_note, label: 'Sound', action: 'sound'),
            const SizedBox(width: 16),
            _toolItem(icon: Icons.graphic_eq, label: 'Sound FX', action: 'soundfx'),
            const SizedBox(width: 16),
            _toolItem(icon: Icons.mic, label: 'Record', action: 'record'),
            const SizedBox(width: 16),
            _toolItem(icon: Icons.record_voice_over, label: 'Text to Audio', action: 'texttoaudio'),
            const SizedBox(width: 16),
            _toolItem(
              icon: Icons.content_cut,
              label: 'Trim',
              action: '',
            ),
          ],
        ),
      ),
    );
  }
}