import 'edit_command.dart';
import '../model/timeline_item.dart';

class UndoManager {
  final List<EditCommand> _undo = [];
  final List<EditCommand> _redo = [];

  void execute(EditCommand cmd, List<TimelineItem> clips) {
    cmd.apply(clips);
    _undo.add(cmd);
    _redo.clear();
  }

  void undo(List<TimelineItem> clips) {
    if (_undo.isEmpty) return;
    final cmd = _undo.removeLast();
    cmd.undo(clips);
    _redo.add(cmd);
  }

  void redo(List<TimelineItem> clips) {
    if (_redo.isEmpty) return;
    final cmd = _redo.removeLast();
    cmd.apply(clips);
    _undo.add(cmd);
  }
}
