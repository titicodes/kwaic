import 'package:kwaic/nes_scr/model/timeline_item.dart';

class TimelineTrack {
  final TimelineItemType type;
  final List<TimelineItem> items;
  TimelineTrack({required this.type, required this.items});
}