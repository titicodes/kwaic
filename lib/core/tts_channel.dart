import 'package:flutter/services.dart';

class TtsChannel {
  static const _channel = MethodChannel('com.yourapp.tts');

  static Future<String?> synthesizeToFile(String text) async {
    try {
      final path = await _channel.invokeMethod('synthesizeToFile', {'text': text});
      return path;
    } catch (e) {
      print('TTS error: $e');
      return null;
    }
  }
}
