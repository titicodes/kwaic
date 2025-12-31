import 'package:flutter/material.dart';
import '../model/timeline_item.dart';

class ContextToolbar extends StatelessWidget {
  final BottomNavMode mode;
  final VoidCallback? onSplit;
  final VoidCallback? onSound;
  final VoidCallback? onSoundFX;
  final VoidCallback? onRecord;
  final VoidCallback? onTextToAudio;
  final VoidCallback? onExtract;
  final VoidCallback? onAddText;
  final VoidCallback? onAutoCaption;
  final VoidCallback? onStickers;
  final Function(String)? onApplyFilter;
  final VoidCallback? onEffects;
  final VoidCallback? onVolume;
  final VoidCallback? onAnimation;
  final VoidCallback? onEffect;
  final VoidCallback? onDelete;
  final VoidCallback? onSpeed;
  final VoidCallback? onBeats;
  final VoidCallback? onCrop;
  final VoidCallback? onDuplicate;
  final VoidCallback? onReplace;
  final VoidCallback? onAdjust;
  final VoidCallback? onBackgroundMusic;
  final VoidCallback? onBackground;
  final VoidCallback? onAddOverlay;

  const ContextToolbar({
    super.key,
    required this.mode,
    this.onSplit,
    this.onSound,
    this.onSoundFX,
    this.onRecord,
    this.onTextToAudio,
    this.onExtract,
    this.onAddText,
    this.onAutoCaption,
    this.onStickers,
    this.onApplyFilter,
    this.onEffects,
    this.onVolume,
    this.onAnimation,
    this.onEffect,
    this.onDelete,
    this.onSpeed,
    this.onBeats,
    this.onCrop,
    this.onDuplicate,
    this.onReplace,
    this.onAdjust,
    this.onBackgroundMusic,
    this.onBackground, this.onAddOverlay,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == BottomNavMode.normal) return const SizedBox.shrink();

    final tools = <Widget>[];

    if (mode == BottomNavMode.edit) {
      tools.addAll([
        _tool('Split', Icons.content_cut, onSplit),
        _tool('Volume', Icons.volume_up, onVolume),
        _tool('Animation', Icons.auto_awesome, onAnimation),
        _tool('Effect', Icons.filter_vintage, onEffect),
        _tool('Speed', Icons.speed, onSpeed),
        _tool('Crop', Icons.crop, onCrop),
        _tool('Duplicate', Icons.copy, onDuplicate),
        _tool('Replace', Icons.swap_horiz, onReplace),
        _tool('Adjust', Icons.tune, onAdjust),
        _tool('Overlay', Icons.format_overline, onAddOverlay),
        _tool('Delete', Icons.delete, onDelete, color: Colors.red),
      ]);
    } else if (mode == BottomNavMode.audio) {
      tools.addAll([
        _tool('Extract', Icons.audiotrack, onExtract),
        _tool('Sound', Icons.music_note, onSound),
        _tool('Sound FX', Icons.graphic_eq, onSoundFX),
        _tool('Record', Icons.mic, onRecord),
        _tool('Text to Audio', Icons.record_voice_over, onTextToAudio),
      ]);
    } else if (mode == BottomNavMode.text) {
      tools.addAll([
        _tool('Add Text', Icons.text_fields, onAddText),
        _tool('Auto Caption', Icons.closed_caption, onAutoCaption),
        _tool('Stickers', Icons.emoji_emotions_outlined, onStickers),
      ]);
    } else if (mode == BottomNavMode.backgroundMusic) {
      tools.addAll([
        _tool('Add Music', Icons.library_music, onBackgroundMusic),
        if (onBackgroundMusic != null) // Optional: show only if needed
          _tool('Replace', Icons.refresh, onBackgroundMusic),
      ]);
    } else if (mode == BottomNavMode.overlay ||
        mode == BottomNavMode.stickers) {
      // You can add background here too if you want quick access
      tools.add(_tool('Background', Icons.palette, onBackground));
    }

    return Container(
      height: 80,
      color: const Color(0xFF1A1A1A),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: tools),
      ),
    );
  }

  Widget _tool(
    String label,
    IconData icon,
    VoidCallback? onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? const Color(0xFF00D9FF), size: 32),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: color ?? Colors.white, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
