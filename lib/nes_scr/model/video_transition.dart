// ADD THIS CLASS — Video Transition between clips
class VideoTransition {
  final String type; // "dissolve", "slide_left", "zoom_in", "wipe_right"
  final Duration duration;

  VideoTransition({
    required this.type,
    this.duration = const Duration(milliseconds: 800),
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'duration': duration.inMilliseconds,
  };

  factory VideoTransition.fromJson(Map<String, dynamic> json) => VideoTransition(
    type: json['type'],
    duration: Duration(milliseconds: json['duration']),
  );
}