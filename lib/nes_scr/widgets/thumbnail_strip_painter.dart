import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ThumbnailStripPainter extends CustomPainter {
  final List<ui.Image> images;
  final int imageCount;

  ThumbnailStripPainter(this.images, this.imageCount);

  @override
  void paint(Canvas canvas, Size size) {
    if (images.isEmpty) return;

    final paint = Paint()..filterQuality = FilterQuality.low;
    final thumbWidth = size.width / imageCount;

    for (int i = 0; i < imageCount && i < images.length; i++) {
      final image = images[i];
      final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final dst = Rect.fromLTWH(i * thumbWidth, 0, thumbWidth, size.height);
      canvas.drawImageRect(image, src, dst, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ThumbnailStripPainter old) => false;
}