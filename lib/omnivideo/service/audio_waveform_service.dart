import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path_provider/path_provider.dart';

class AudioWaveformService {
  static final Map<String, Waveform> _cache = {};

  static Future<Waveform> extractWaveform(File file) async {
    final path = file.path;

    if (_cache.containsKey(path)) {
      return _cache[path]!;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final waveOutFile = File('${tempDir.path}/waveform_${DateTime.now().millisecondsSinceEpoch}.wave');

      final progressStream = JustWaveform.extract(
        audioInFile: file,
        waveOutFile: waveOutFile,
      );

      Waveform? waveform;
      await for (final progress in progressStream) {
        if (progress.waveform != null) {
          waveform = progress.waveform;
        }
      }

      if (waveform == null) {
        throw Exception('Failed to extract waveform');
      }

      // Clean up the temporary file
      if (await waveOutFile.exists()) {
        await waveOutFile.delete();
      }

      _cache[path] = waveform;
      return waveform;
    } catch (e) {
      debugPrint('Waveform extraction failed: $e');
      // Fallback silent waveform
      return Waveform(
        version: 1,
        flags: 0,
        sampleRate: 44100,
        samplesPerPixel: 1000,
        length: 1000,
        data: List.filled(1000, 0),
      );
    }
  }
}