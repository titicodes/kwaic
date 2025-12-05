import 'dart:typed_data';
import 'dart:ui' as ui;

class ThumbnailData {
  final Uint8List bytes;
  final ui.Image? image;  // Make the image property nullable

  ThumbnailData(this.bytes, this.image);
}
