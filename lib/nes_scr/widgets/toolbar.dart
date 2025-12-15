import 'package:flutter/material.dart';

import '../model/timeline_item.dart';

class BottomNav extends StatelessWidget {
  final BottomNavMode currentMode;
  final Function(BottomNavMode) onModeChanged;

  const BottomNav({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.black,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _navButton(
              Icons.edit,
              'Edit',
              () => onModeChanged(BottomNavMode.edit),
              currentMode == BottomNavMode.edit,
            ),
            _navButton(
              Icons.audiotrack,
              'Audio',
              () => onModeChanged(BottomNavMode.audio),
              currentMode == BottomNavMode.audio,
            ),
            _navButton(
              Icons.text_fields,
              'Text',
              () => onModeChanged(BottomNavMode.text),
              currentMode == BottomNavMode.text,
            ),
            _navButton(
              Icons.emoji_emotions,
              'Stickers',
              () => onModeChanged(BottomNavMode.stickers),
              currentMode == BottomNavMode.stickers,
            ),
            _navButton(
              Icons.layers,
              'Overlay',
              () => onModeChanged(BottomNavMode.overlay),
              currentMode == BottomNavMode.overlay,
            ),
            _navButton(
              Icons.auto_awesome,
              'Effects',
              () => onModeChanged(BottomNavMode.effects),
              currentMode == BottomNavMode.effects,
            ),
            _navButton(
              Icons.filter,
              'Filters',
              () => onModeChanged(BottomNavMode.filters),
              currentMode == BottomNavMode.filters,
            ),
            _navButton(
              Icons.animation,
              'Animation',
              () => onModeChanged(BottomNavMode.animation),
              currentMode == BottomNavMode.animation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    bool isActive,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isActive
                        ? const Color(0xFF00D9FF).withOpacity(0.2)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isActive ? const Color(0xFF00D9FF) : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? const Color(0xFF00D9FF) : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
