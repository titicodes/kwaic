import 'package:flutter/material.dart';

import '../provider/video_editor_provider.dart';
import 'package:provider/provider.dart';

import 'curve_canvas.dart';

class CurveSpeedEditor extends StatelessWidget {
  const CurveSpeedEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VideoEditorProvider>();

    final presets = [
      'Montage',
      'Custom',
      'Jump Cut',
      'Bullet',
      'Flash In',
      'Flash Out',
    ];

    return Column(
      children: [
        // 🔹 PRESET GRID
        SizedBox(
          height: 90,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.7,
            ),
            itemCount: presets.length,
            itemBuilder: (_, i) {
              return GestureDetector(
                onTap: () {
                  p.applyCurvePreset(presets[i]); // ✅ THIS IS NOW CORRECT
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    presets[i],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // 🔹 CURVE CANVAS
        SizedBox(
          height: 50,
          child: CurveCanvas(
            points: p.curvePoints,
            onPointMoved: p.updateCurvePoint,
          ),
        ),
      ],
    );
  }
}
