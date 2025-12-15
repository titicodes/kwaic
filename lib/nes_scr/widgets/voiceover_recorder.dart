import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../model/timeline_item.dart';
import '../servuices/audio_manager.dart';
import '../servuices/clip_controller.dart';


class VoiceoverRecorder extends StatefulWidget {
  final ClipController clipController;
  final AudioManager audioManager;
  final Duration insertPosition;

  const VoiceoverRecorder({
    super.key,
    required this.clipController,
    required this.audioManager,
    required this.insertPosition,
  });

  @override
  State<VoiceoverRecorder> createState() => _VoiceoverRecorderState();
}

class _VoiceoverRecorderState extends State<VoiceoverRecorder> {
  late AudioRecorder _recorder;
  bool _isRecording = false;
  String? _path;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      if (path != null) {
        final file = File(path);
        final player = AudioPlayer();
        await player.setFilePath(path);
        final duration = player.duration ?? Duration.zero;

        final item = TimelineItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: TimelineItemType.audio,
          file: file,
          startTime: widget.insertPosition,
          duration: duration,
          originalDuration: duration,
          trimStart: Duration.zero,
        );

        await widget.clipController.addAudioClip(item);
        if (mounted) Navigator.pop(context);
      }
    } else {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _path = '${dir.path}/voiceover_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(), path: _path!);
      }
    }
    setState(() => _isRecording = !_isRecording);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      builder: (_, controller) => Container(
        color: Color(0xFF1A1A1A),
        child: Column(
          children: [
            Container(margin: EdgeInsets.only(top: 12), width: 40, height: 5, color: Colors.grey),
            const Text('Record Voiceover', style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _toggleRecording,
              child: Icon(
                _isRecording ? Icons.stop_circle : Icons.mic_sharp,
                size: 120,
                color: _isRecording ? Colors.red : const Color(0xFF00D9FF),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isRecording ? 'Recording...' : 'Tap to record',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}