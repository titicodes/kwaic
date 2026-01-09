// widgets/text_to_audio_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../model/audio_track.dart';
import '../provider/video_editor_provider.dart';

class TextToAudioSheet extends StatefulWidget {
  final Duration insertPosition;
  const TextToAudioSheet({super.key, required this.insertPosition});

  @override
  State<TextToAudioSheet> createState() => _TextToAudioSheetState();
}

class _TextToAudioSheetState extends State<TextToAudioSheet> {
  final TextEditingController _controller = TextEditingController();
  late FlutterTts _tts;
  List<dynamic> _voices = [];
  dynamic _selectedVoice;
  double _rate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    _voices = (await _tts.getVoices) ?? [];
    if (_voices.isNotEmpty) {
      _selectedVoice = _voices.first;
    }
    setState(() {});
  }

  IconData _getAvatarIcon(dynamic voice) {
    final gender = voice['gender']?.toString().toLowerCase();
    if (gender == 'male') return Icons.man;
    if (gender == 'female') return Icons.woman;
    return Icons.person;
  }

  Future<void> _generateAudio() async {
    if (_controller.text.isEmpty) return;

    setState(() => _isLoading = true);

    final provider = context.read<VideoEditorProvider>();
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.wav';

    final Map<String, String> voiceMap = {
      'name': _selectedVoice['name'].toString(),
      if (_selectedVoice['identifier'] != null)
        'identifier': _selectedVoice['identifier'].toString(),
    };

    await _tts.setVoice(voiceMap);
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(_pitch);
    await _tts.setVolume(_volume);

    final success = await _tts.synthesizeToFile(_controller.text, path);

    if (success == 1) {
      final file = File(path);
      final player = AudioPlayer();
      await player.setFilePath(path);
      final duration = player.duration ?? const Duration(seconds: 10);
      final durationSec = duration.inMilliseconds / 1000.0;

      // Generate waveform
      final waveFile = File('${tempDir.path}/wave_${const Uuid().v4()}.wave');
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
    }

    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        color: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Text to Audio',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.grey),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: 'Enter text to convert to speech...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 120,
              child: _voices.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _voices.length,
                itemBuilder: (_, i) {
                  final voice = _voices[i];
                  final name = voice['name'] ?? 'Voice ${i + 1}';
                  final isSelected = _selectedVoice == voice;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedVoice = voice),
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00D9FF) : Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_getAvatarIcon(voice), size: 48, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _sliderRow('Rate', _rate, 0.1, 1.0, (v) => setState(() => _rate = v)),
                  _sliderRow('Pitch', _pitch, 0.5, 2.0, (v) => setState(() => _pitch = v)),
                  _sliderRow('Volume', _volume, 0.0, 1.0, (v) => setState(() => _volume = v)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateAudio,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D9FF)),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Generate Audio', style: TextStyle(fontSize: 18, color: Colors.black)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow(String label, double value, double min, double max, Function(double) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        Slider(value: value, min: min, max: max, onChanged: onChange, activeColor: const Color(0xFF00D9FF)),
        Text(value.toStringAsFixed(2), style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _controller.dispose();
    super.dispose();
  }
}