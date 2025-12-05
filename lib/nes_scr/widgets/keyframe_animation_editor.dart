// widgets/keyframe_animation_editor.dart
import 'package:flutter/material.dart';
import '../model/keyframe.dart';
import '../model/timeline_item.dart';

class KeyframeAnimationEditor extends StatefulWidget {
  final TimelineItem item;
  final VoidCallback? onUpdate; // Optional now

  const KeyframeAnimationEditor({
    super.key,
    required this.item,
    this.onUpdate,
  });

  @override
  State<KeyframeAnimationEditor> createState() => _KeyframeAnimationEditorState();
}

class _KeyframeAnimationEditorState extends State<KeyframeAnimationEditor> {
  late List<Keyframe> keyframes;

  @override
  void initState() {
    super.initState();
    keyframes = widget.item.keyframes.isEmpty
        ? [
      Keyframe(time: 0.0, x: widget.item.x ?? 100, y: widget.item.y ?? 200, scale: widget.item.scale, rotation: widget.item.rotation, opacity: 1.0),
      Keyframe(time: 1.0, x: widget.item.x ?? 100, y: widget.item.y ?? 200, scale: widget.item.scale, rotation: widget.item.rotation, opacity: 1.0),
    ]
        : widget.item.keyframes.map((k) => k.copyWith()).toList();
  }

  Keyframe _getInterpolated(double progress) {
    if (keyframes.length == 1) return keyframes[0];
    for (int i = 0; i < keyframes.length - 1; i++) {
      final a = keyframes[i];
      final b = keyframes[i + 1];
      if (progress <= b.time) {
        final t = (progress - a.time) / (b.time - a.time);
        return a.lerp(b, t);
      }
    }
    return keyframes.last;
  }

  @override
  Widget build(BuildContext context) {
    final end = keyframes.last;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Keyframe Animation'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              widget.item.keyframes = keyframes;
              // Apply final values for live preview
              widget.item.x = end.x;
              widget.item.y = end.y;
              widget.item.scale = end.scale ?? 1.0;
              widget.item.rotation = end.rotation ?? 0.0;
              widget.item.opacity = end.opacity ?? 1.0;

              widget.onUpdate?.call();
              if (mounted) setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Animation applied'), backgroundColor: Color(0xFF10B981)),
              );
            },
            child: const Text('Apply', style: TextStyle(color: Color(0xFF00D9FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('End State (animation goes from start → end)', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 24),
          _slider('X Position', end.x ?? 100, -500, 1000, (v) => setState(() => keyframes[keyframes.length - 1] = keyframes.last.copyWith(x: v))),
          _slider('Y Position', end.y ?? 200, -500, 1000, (v) => setState(() => keyframes[keyframes.length - 1] = keyframes.last.copyWith(y: v))),
          _slider('Scale', end.scale ?? 1.0, 0.1, 8.0, (v) => setState(() => keyframes.last = keyframes.last.copyWith(scale: v))),
          _slider('Rotation (°)', end.rotation ?? 0, -360, 360, (v) => setState(() => keyframes.last = keyframes.last.copyWith(rotation: v))),
          _slider('Opacity', end.opacity ?? 1.0, 0.0, 1.0, (v) => setState(() => keyframes.last = keyframes.last.copyWith(opacity: v))),
        ],
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max, Function(double) onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16)),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) * 10).toInt(),
            activeColor: const Color(0xFF00D9FF),
            onChanged: onChange,
          ),
        ],
      ),
    );
  }
}