// bottom_navbar_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../nes_scr/widgets/audio_library_sheet.dart';
import '../provider/video_editor_provider.dart';

class BottomNavBarWidget extends StatelessWidget {
  const BottomNavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VideoEditorProvider>(context);

    return Container(
      height: 72,
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Ensures even spacing
        children: [
          // Back / Edit button
          if (provider.showContextToolbar)
            Expanded(
              child: _NavItem(
                Icons.arrow_back,
                'Back',
                onTap: () => provider.hideAllToolbars(),
                active: true,
              ),
            )
          else
            Expanded(
              child: _NavItem(
                Icons.content_cut,
                'Edit',
                onTap: () => provider.showToolbar(),
                active: false,
              ),
            ),

          // Speed
          Expanded(
            child: _NavItem(
              Icons.speed,
              'Speed',
              onTap: () => provider.openTool('speed'),
              active: provider.currentTool == 'speed',
            ),
          ),

          // Audio
          Expanded(
            child: _NavItem(
              Icons.music_note,
              'Audio',
              onTap: () {
                if (provider.selectedVideoTrackId == null && provider.selectedAudioTrack == null) {
                  provider.openAudioContextToolbar();
                } else {
                  provider.openTool('audio');
                }
              },
              active: provider.currentTool == 'audio' || provider.showAudioContextToolbar,
            ),
          ),

          // Text
          Expanded(
            child: _NavItem(
              Icons.text_fields,
              'Text',
              onTap: () => provider.openTool('text'),
              active: provider.currentTool == 'text',
            ),
          ),

          // Effect
          Expanded(
            child: _NavItem(
              Icons.auto_awesome,
              'Effect',
              onTap: () => provider.openTool('effect'),
              active: provider.currentTool == 'effect',
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem(
      this.icon,
      this.label, {
        this.active = false,
        this.onTap,
      });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF8B5CF6) : Colors.white54;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}