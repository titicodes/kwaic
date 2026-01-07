import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';

class AudioTrack {
  final String id;
  final String path;
  final double duration;
  double start;
  Waveform? waveform;

  final String? linkedClipId; // 🔥 ADD THIS
  final AudioPlayer player;

  AudioTrack({
    required this.id,
    required this.path,
    required this.duration,
    required this.start,
    this.waveform,
    this.linkedClipId, // 🔥 ADD THIS
    AudioPlayer? player,
  }) : player = player ?? AudioPlayer();

  AudioTrack copyWith({
    double? start,
    Waveform? waveform,
  }) {
    return AudioTrack(
      id: id,
      path: path,
      duration: duration,
      start: start ?? this.start,
      waveform: waveform ?? this.waveform,
      linkedClipId: linkedClipId,
      player: player,
    );
  }

  Duration get startTime =>
      Duration(milliseconds: (start * 1000).round());

  Duration get uiDuration =>
      Duration(milliseconds: (duration * 1000).round());
}
