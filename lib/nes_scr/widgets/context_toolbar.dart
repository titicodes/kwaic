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
  final VoidCallback? onAddText; // ← ADD THESE
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

  const ContextToolbar({
    super.key,
    required this.mode,
    this.onSplit,
    this.onSound,
    this.onSoundFX,
    this.onRecord,
    this.onTextToAudio,
    this.onExtract,
    this.onAddText, // ← ADD
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
        _tool('Delete', Icons.delete, onDelete, color: Colors.red),
        _tool('Speed', Icons.speed, onSpeed),
        _tool('Beats', Icons.music_note, onBeats),
        _tool('Crop', Icons.crop, onCrop),
        _tool('Duplicate', Icons.copy, onDuplicate),
        _tool('Replace', Icons.swap_horiz, onReplace),
        _tool('Adjust', Icons.tune, onAdjust),
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
        _tool(
          'Add Text',
          Icons.text_increase,
          onAddText,
        ), // ← Now passed correctly
        _tool('Auto Caption', Icons.closed_caption, onAutoCaption),
        _tool('Stickers', Icons.emoji_emotions_outlined, onStickers),
        _tool('Draw', Icons.draw, () {}),
        _tool('Text to Audio', Icons.record_voice_over, onTextToAudio),
      ]);
    } else if (mode == BottomNavMode.filters) {
      tools.addAll([
        _tool('Original', Icons.filter_none, () => onApplyFilter?.call('none')),
        _tool('Vintage', Icons.camera, () => onApplyFilter?.call('vintage')),
        _tool(
          'Cinematic',
          Icons.movie_filter,
          () => onApplyFilter?.call('cinematic'),
        ),
        _tool('Warm', Icons.wb_sunny, () => onApplyFilter?.call('warm')),
        _tool('Cool', Icons.ac_unit, () => onApplyFilter?.call('cool')),
        _tool('B&W', Icons.grain, () => onApplyFilter?.call('bw')),
      ]);
    }

    return Container(
      height: 70,
      color: const Color(0xFF1A1A1A),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? const Color(0xFF00D9FF), size: 28),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: color ?? Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
