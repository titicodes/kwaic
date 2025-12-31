import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/video_editor_provider.dart';
import 'curve_speed_editor.dart';

class SpeedBottomSheet extends StatelessWidget {
  const SpeedBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VideoEditorProvider>();

    if (!p.showBottomSheet || p.currentTool != 'speed') {
      return const SizedBox.shrink();
    }
    return Container(
      height: 280, // 🔴 EXACT CAPCUT-LIKE HEIGHT
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _header(context, p),
          const SizedBox(height: 8),
          _tabs(p),
          const SizedBox(height: 12),
          Expanded(
            child: p.speedMode == 'normal'
                ? const _NormalSpeedView()
                : const CurveSpeedEditor(),
          )

        ],
      ),
    );
  }

  Widget _header(BuildContext context, VideoEditorProvider p) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            p.cancelSpeedPreview();
            p
              ..showBottomSheet = false
              ..showContextToolbar = true;
          },
        ),
        const Spacer(),
        Text(
          '${p.previewSpeed.toStringAsFixed(1)}x',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.white),
          onPressed: () {
            p.applySpeedToSelectedTrack();
            p
              ..showBottomSheet = false
              ..showContextToolbar = true;
          },
        ),
      ],
    );
  }

  Widget _tabs(VideoEditorProvider p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TabButton(
          label: 'Normal',
          active: p.speedMode == 'normal',
          onTap: () => p.setSpeedMode('normal'),
        ),
        const SizedBox(width: 16),
        _TabButton(
          label: 'Curve',
          active: p.speedMode == 'curve',
          onTap: () => p.setSpeedMode('curve'),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF8B5CF6) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NormalSpeedView extends StatelessWidget {
  const _NormalSpeedView();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VideoEditorProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${p.previewSpeed.toStringAsFixed(1)}x',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 0),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              activeTrackColor: const Color(0xFF8B5CF6),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFF8B5CF6),
              overlayColor: const Color(0xFF8B5CF6).withOpacity(0.2),
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 5),
              activeTickMarkColor: Colors.white,
              inactiveTickMarkColor: Colors.white38,
            ),
            child: Slider(
              value: p.previewSpeed,
              min: 0.1,
              max: 8.0,
              divisions: 79,
              onChanged: p.setPreviewSpeed,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0.2x', style: TextStyle(color: Colors.white54, fontSize: 13)),
              Text('0.5x', style: TextStyle(color: Colors.white54, fontSize: 13)),
              Text('1x', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              Text('2x', style: TextStyle(color: Colors.white54, fontSize: 13)),
              Text('4x', style: TextStyle(color: Colors.white54, fontSize: 13)),
              Text('8x', style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Scale extends StatelessWidget {
  final String label;
  const _Scale(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(color: Colors.white54, fontSize: 10),
    );
  }
}

