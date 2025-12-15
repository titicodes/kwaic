import 'edit_command.dart';

class MoveClipCommand extends EditCommand {
  final String clipId;
  final Duration from;
  final Duration to;

  MoveClipCommand(this.clipId, this.from, this.to);

  @override
  void apply(List clips) {
    final i = clips.indexWhere((c) => c.id == clipId);
    clips[i] = clips[i].copyWith(startTime: to);
  }

  @override
  void undo(List clips) {
    final i = clips.indexWhere((c) => c.id == clipId);
    clips[i] = clips[i].copyWith(startTime: from);
  }
}
