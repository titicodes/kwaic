// ========================================
// PRODUCTION ENHANCEMENT 3: WATERMARK OVERLAY
// ========================================

import 'package:flutter/material.dart';

class WatermarkOverlay extends StatelessWidget {
  final bool isPro;
  final String text;
  final Alignment alignment;
  final double opacity;

  const WatermarkOverlay({
    super.key,
    this.isPro = false,
    this.text = 'Made with VideoEditor',
    this.alignment = Alignment.bottomRight,
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    if (isPro) return const SizedBox.shrink();

    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam,
                  size: 16,
                  color: Colors.white.withOpacity(opacity),
                ),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(opacity),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
