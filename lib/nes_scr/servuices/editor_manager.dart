import '../model/new_editor_state.dart';

import '../model/new_editor_state.dart';

class EditorStateManager {
  final List<EditorState> _history = [];
  int _historyIndex = -1;
  final int maxHistory = 50;

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  void saveState(EditorState state) {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(state);

    if (_history.length > maxHistory) {
      _history.removeAt(0);
    } else {
      _historyIndex++;
    }
  }

  EditorState? undo() {
    if (canUndo) {
      _historyIndex--;
      return _history[_historyIndex];
    }
    return null;
  }

  EditorState? redo() {
    if (canRedo) {
      _historyIndex++;
      return _history[_historyIndex];
    }
    return null;
  }
}
