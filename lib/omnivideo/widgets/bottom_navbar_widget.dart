// bottom_navbar_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../nes_scr/widgets/audio_library_sheet.dart';
import '../provider/video_editor_provider.dart';

// bottom_navbar_widget.dart
class BottomNavBarWidget extends StatelessWidget {
  const BottomNavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VideoEditorProvider>(context);

    return Container(
      height: 72,
      color: Colors.black,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Back button when toolbar open, Edit when closed
            if (provider.showContextToolbar)
              _NavItem(
                Icons.arrow_back,
                'Back',
                onTap: () => provider.hideToolbar(),
                active: true,
              )
            else
              _NavItem(
                Icons.content_cut,
                'Edit',
                onTap: () => provider.showToolbar(),
                active: false,
              ),

            _NavItem(
              Icons.speed,
              'Speed',
              onTap: () {
                provider.openTool('speed');
              },
            ),

            _NavItem(
              Icons.music_note,
              'Audio',
              onTap: () {
                final provider = context.read<VideoEditorProvider>();

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AudioLibrarySheet(
                    insertPosition: provider.currentPosition,
                  ),
                );
              },
            ),

            _NavItem(Icons.text_fields, 'Text', onTap: () => provider.openTool('text')),
            _NavItem(Icons.auto_awesome, 'Effect', onTap: () => provider.openTool('effect')),


          ],
        ),
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
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
