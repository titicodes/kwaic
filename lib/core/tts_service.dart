import 'package:flutter/services.dart';

class TTSService {
  static const _channel = MethodChannel('kwaic_tts');

  static Future<String?> speakToFile(String text, String fileName) async {
    try {
      final String? path = await _channel.invokeMethod('speakToFile', {
        'text': text,
        'fileName': fileName,
      });
      return path;
    } on PlatformException catch (e) {
      print("TTS error: $e");
      return null;
    }
  }
}
