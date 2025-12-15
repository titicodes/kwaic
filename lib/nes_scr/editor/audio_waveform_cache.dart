import 'package:just_waveform/just_waveform.dart';

class WaveformCache {
  static final Map<String, Waveform> _cache = {};

  static Waveform? get(String clipId) => _cache[clipId];

  static void put(String clipId, Waveform waveform) {
    _cache[clipId] = waveform;
  }

  static void clear(String clipId) {
    _cache.remove(clipId);
  }
}
