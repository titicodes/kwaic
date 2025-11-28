import 'package:flutter/material.dart';

import '../model/keyframe.dart';
import '../model/timeline_item.dart';

class KeyframeAnimationEditor extends StatefulWidget {
  final TimelineItem item;
  final VoidCallback onSave;        // To call _saveToHistory()
  final Function(String) showMessage; // To call _showMessage()

  const KeyframeAnimationEditor({
    super.key,
    required this.item,
    required this.onSave,
    required this.showMessage,
  });

  @override
  State<KeyframeAnimationEditor> createState() => _KeyframeAnimationEditorState();
}

class _KeyframeAnimationEditorState extends State<KeyframeAnimationEditor> {
  late List<Keyframe> keyframes;

  @override
  void initState() {
    super.initState();
    // Deep copy keyframes
    keyframes = widget.item.keyframes.map((k) => Keyframe(
      time: k.time,
      x: k.x,
      y: k.y,
      scale: k.scale,
      rotation: k.rotation,
      opacity: k.opacity,
    )).toList();

    // Ensure we have at least 2 keyframes
    if (keyframes.isEmpty) {
      keyframes = [
        Keyframe(time: 0.0, x: widget.item.x ?? 100, y: widget.item.y ?? 200, scale: widget.item.scale, rotation: widget.item.rotation, opacity: 1.0),
        Keyframe(time: 1.0, x: widget.item.x ?? 100, y: widget.item.y ?? 200, scale: widget.item.scale, rotation: widget.item.rotation, opacity: 1.0),
      ];
    }
  }

  Keyframe _getCurrentKeyframe() {
    // This is just for preview — we use playhead from parent
    final progress = 0.5; // You can pass playhead later if needed
    for (int i = 0; i < keyframes.length - 1; i++) {
      if (progress >= keyframes[i].time && progress <= keyframes[i + 1].time) {
        final t = (progress - keyframes[i].time) / (keyframes[i + 1].time - keyframes[i].time);
        return keyframes[i].lerp(keyframes[i + 1], t);
      }
    }
    return keyframes.last;
  }

  @override
  Widget build(BuildContext context) {
    final current = keyframes.last; // We're editing the END keyframe (most common)

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 20, bottom: 10),
          child: Text('Keyframe Animation', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        const Text('Adjust the END values → animation plays from start to end', style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 20),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _slider('X Position', current.x ?? 100, -500, 1000, (v) => setState(() => keyframes[1] = keyframes[1].copyWith(x: v))),
              _slider('Y', current.y ?? 200, -500, 1000, (v) => setState(() => keyframes[1] = keyframes[1].copyWith(y: v))),
              _slider('Scale', current.scale ?? 1.0, 0.1, 8.0, (v) => setState(() => keyframes[1] = keyframes[1].copyWith(scale: v))),
              _slider('Rotation (°)', current.rotation ?? 0, -360, 360, (v) => setState(() => keyframes[1] = keyframes[1].copyWith(rotation: v))),
              _slider('Opacity', current.opacity ?? 1.0, 0.0, 1.0, (v) => setState(() => keyframes[1] = keyframes[1].copyWith(opacity: v))),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave(); // This calls _saveToHistory() from parent
                    setState(() {
                      widget.item.keyframes = keyframes;
                      // Apply final values for preview
                      widget.item.x = keyframes.last.x;
                      widget.item.y = keyframes.last.y;
                      widget.item.scale = keyframes.last.scale ?? 1.0;
                      widget.item.rotation = keyframes.last.rotation ?? 0;
                    });
                    widget.showMessage('Animation applied');
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D9FF)),
                  child: const Text('Apply', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _slider(String label, double value, double min, double max, Function(double) onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 15)),
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