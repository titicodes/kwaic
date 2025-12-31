

import 'dart:typed_data';

import 'package:just_waveform/just_waveform.dart';

class AudioTrack {
  final String id;
  final String path;
  final double duration;
  double start;                 // seconds on timeline
  Waveform? waveform;           // ← changed to Waveform?

  AudioTrack({
    required this.id,
    required this.path,
    required this.duration,
    required this.start,
    this.waveform,              // nullable
  });

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
    );
  }

  Duration get startTime => Duration(milliseconds: (start * 1000).round());
  Duration get uiDuration => Duration(milliseconds: (duration * 1000).round());
}