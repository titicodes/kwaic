package com.example.kwaic

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.speech.tts.TextToSpeech
import java.io.File
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "kwaic_tts"
    private var tts: TextToSpeech? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "speakToFile") {
                val text = call.argument<String>("text")
                val fileName = call.argument<String>("fileName")
                if (text != null && fileName != null) {
                    val file = File(applicationContext.cacheDir, "$fileName.wav")
                    tts = TextToSpeech(applicationContext) { status ->
                        if (status == TextToSpeech.SUCCESS) {
                            tts?.language = Locale.US
                            val res = tts?.synthesizeToFile(text, null, file, "ttsFile")
                            result.success(file.absolutePath)
                        } else {
                            result.error("TTS_ERROR", "TTS initialization failed", null)
                        }
                    }
                } else {
                    result.error("INVALID_ARGS", "Missing text or fileName", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        tts?.stop()
        tts?.shutdown()
        super.onDestroy()
    }
}
