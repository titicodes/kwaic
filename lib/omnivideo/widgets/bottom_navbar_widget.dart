// bottom_navbar_widget.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../nes_scr/widgets/audio_library_sheet.dart';
import '../provider/video_editor_provider.dart';

class BottomNavBarWidget extends StatelessWidget {
  const BottomNavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VideoEditorProvider>(context);
    final bool isToolbarOpen = provider.showContextToolbar;

    return Container(
      height: 72,
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (isToolbarOpen)
            _NavItem(
              Icons.arrow_back,
              'Back',
              onTap: () => provider.hideToolbar(),
            )
          else
            _NavItem(
              Icons.content_cut,
              'Edit',
              onTap: () {
                final p = Provider.of<VideoEditorProvider>(
                  context,
                  listen: false,
                );
                final currentPos = p.currentPosition;
                final currentTrack = p.videoTracks.firstWhereOrNull(
                  (t) => currentPos >= t.startTime && currentPos < t.endTime,
                );
                if (currentTrack != null) {
                  p.selectVideoTrack(currentTrack.id);
                }
                p.openEditContextToolbar(); // ← New method
              },
            ),

          _NavItem(
            Icons.speed,
            'Speed',
            onTap: () {
              final p = Provider.of<VideoEditorProvider>(
                context,
                listen: false,
              );

              // Optional: auto-select current clip if none selected
              if (p.selectedVideoTrackId == null) {
                final currentPos = p.currentPosition;
                final currentTrack = p.videoTracks.firstWhereOrNull(
                  (t) => currentPos >= t.startTime && currentPos < t.endTime,
                );
                if (currentTrack != null) {
                  p.selectVideoTrack(currentTrack.id);
                }
              }

              p.openEditContextToolbar(); // ← Only this!
            },
          ),
          _NavItem(
            Icons.music_note,
            'Audio',
            onTap: () => provider.openAudioContextToolbar(),
          ),

          _NavItem(
            Icons.text_fields,
            'Text',
            onTap:
                () =>
                    provider
                        .openEditContextToolbar(), // or make 'text' mode later
            active: provider.currentTool == 'text',
          ),

          _NavItem(
            Icons.auto_awesome,
            'Effect',
            onTap: () => provider.openEditContextToolbar(),
            active: provider.currentTool == 'effect',
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

  const _NavItem(this.icon, this.label, {this.active = false, this.onTap});

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
