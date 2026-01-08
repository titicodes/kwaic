// model/audio_track.dart
import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:uuid/uuid.dart';

class AudioTrack {
  final String id;
  final String path;
  double duration;                 // Current visible/trimmed duration
  final double originalDuration;   // Full original length (never changes)
  double start;                    // ← NOW MUTABLE (not final)
  final String? linkedClipId;
  final AudioPlayer player;
  Waveform? waveform;

  AudioTrack({
    required this.id,
    required this.path,
    required this.duration,
    required this.originalDuration,
    required this.start,
    this.linkedClipId,
    AudioPlayer? player,
    this.waveform,
  }) : player = player ?? AudioPlayer();

  Duration get startTime => Duration(milliseconds: (start * 1000).round());
  Duration get endTime => Duration(milliseconds: ((start + duration) * 1000).round());

  AudioTrack copyWith({
    String? id,
    String? path,
    double? duration,
    double? originalDuration,
    double? start,
    Waveform? waveform,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      originalDuration: originalDuration ?? this.originalDuration,
      start: start ?? this.start,
      linkedClipId: linkedClipId,
      player: player,
      waveform: waveform ?? this.waveform,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'duration': duration,
      'originalDuration': originalDuration,
      'start': start,
      'linkedClipId': linkedClipId,
    };
  }
}