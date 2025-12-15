import 'edit_command.dart';

class TrimClipCommand extends EditCommand {
  final String clipId;
  final Duration oldTrim;
  final Duration newTrim;

  TrimClipCommand(this.clipId, this.oldTrim, this.newTrim);

  @override
  void apply(List clips) {
    final i = clips.indexWhere((c) => c.id == clipId);
    clips[i] = clips[i].copyWith(trimStart: newTrim);
  }

  @override
  void undo(List clips) {
    final i = clips.indexWhere((c) => c.id == clipId);
    clips[i] = clips[i].copyWith(trimStart: oldTrim);
  }
}
