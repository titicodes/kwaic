import 'dart:typed_data';

class AudioWaveCache {
  final Float32List low;
  final Float32List mid;
  final Float32List high;

  AudioWaveCache({
    required this.low,
    required this.mid,
    required this.high,
  });

  Float32List forZoom(double pxPerSecond) {
    if (pxPerSecond < 80) return low;
    if (pxPerSecond < 200) return mid;
    return high;
  }
}
