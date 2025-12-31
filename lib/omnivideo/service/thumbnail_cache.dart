import 'dart:typed_data';

class ThumbnailCache {
  static final Map<String, List<Uint8List>> _cache = {};
  static final int _maxCacheSize = 100;  // Limit the number of cached videos

  static bool has(String path) => _cache.containsKey(path);

  static List<Uint8List> get(String path) => _cache[path] ?? [];

  static void put(String path, List<Uint8List> thumbs) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);  // Remove the oldest entry
    }
    _cache[path] = thumbs;
  }

  static void clear(String path) {
    _cache.remove(path);
  }
}
