class TimelineClip {
  final String id;
  final String videoPath;

  // Visuals
  final List<String> frameThumbnails; // multi-frame strip
  final String? waveformPath;

  // Timing
  Duration timelineStart;
  Duration duration;
  Duration trimStart = Duration.zero;
  Duration trimEnd; // = full duration initially
  Duration get trimmedDuration => trimEnd - trimStart;

  TimelineClip({
    required this.id,
    required this.videoPath,
    required this.frameThumbnails,
    this.waveformPath,
    required this.timelineStart,
    required this.duration,
    required this.trimStart,
    required this.trimEnd,
  });
}
