import 'package:kwaic/nes_scr/model/timeline_item.dart';

class EditorState {
  final List<TimelineItem> clips;
  final List<TimelineItem> audioItems;
  final List<TimelineItem> textItems;
  final List<TimelineItem> overlayItems;
  final int? selectedClip;
  final Duration playheadPosition;

  EditorState({
    required this.clips,
    required this.audioItems,
    required this.textItems,
    required this.overlayItems,
    required this.selectedClip,
    required this.playheadPosition,
  });
}