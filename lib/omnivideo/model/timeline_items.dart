import 'dart:io';

import '../../nes_scr/model/timeline_item.dart';

class TimelineItem {
  final String id;
  final TimelineItemType type;
  final File file;

  Duration startTime;
  Duration duration;
  Duration originalDuration;

  Duration trimStart;
  Duration trimEnd;

  double volume;

  // 🔥 ADD THIS
  List<double>? waveform; // normalized values (0.0 – 1.0)

  TimelineItem({
    required this.id,
    required this.type,
    required this.file,
    required this.startTime,
    required this.duration,
    required this.originalDuration,
    this.trimStart = Duration.zero,
    Duration? trimEnd,
    this.volume = 1.0,
    this.waveform,
  }) : trimEnd = trimEnd ?? duration;
}
