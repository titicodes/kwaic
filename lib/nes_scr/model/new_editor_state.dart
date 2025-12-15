
import '../screen/hh.dart';

class EditorState {
  final List<TimelineClip> videoClips;
  final List<TimelineClip> audioClips;
  final List<TimelineClip> overlayClips;
  final List<TimelineClip> textClips;
  final double playheadPosition;

  EditorState({
    required this.videoClips,
    required this.audioClips,
    required this.overlayClips,
    required this.textClips,
    required this.playheadPosition,
  });
}
