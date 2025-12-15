import '../model/timeline_item.dart';

abstract class EditCommand {
  void apply(List<TimelineItem> clips);
  void undo(List<TimelineItem> clips);
}
