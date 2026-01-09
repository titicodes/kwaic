// widgets/voiceover_recorder.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:just_waveform/just_waveform.dart';
import '../model/audio_track.dart';
import '../provider/video_editor_provider.dart';

class VoiceoverRecorder extends StatefulWidget {
  const VoiceoverRecorder({super.key});

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
    final provider = context.read<VideoEditorProvider>();

    if (_isRecording) {
      final path = await _recorder.stop();
      if (path != null && mounted) {
        final file = File(path);
        final player = AudioPlayer();
        await player.setFilePath(path);
        final duration = player.duration ?? Duration.zero;
        final durationSec = duration.inMilliseconds / 1000.0;

        // Generate waveform
        final waveFile = File('${(await getTemporaryDirectory()).path}/wave_${const Uuid().v4()}.wave');
        Waveform? waveform;
        try {
          final stream = JustWaveform.extract(audioInFile: file, waveOutFile: waveFile);
          await for (final progress in stream) {
            if (progress.waveform != null) waveform = progress.waveform;
          }
        } catch (_) {}
        if (await waveFile.exists()) await waveFile.delete();

        final audioTrack = AudioTrack(
          id: const Uuid().v4(),
          path: path,
          duration: durationSec,
          start: provider.currentPosition.inMilliseconds / 1000.0,
          waveform: waveform,
          player: player,
          originalDuration: durationSec,
        );

        provider.addAudioTrack(audioTrack);
        Navigator.pop(context);
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
        color: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 5, color: Colors.grey),
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