import 'package:flutter/material.dart';

class TimelineScrollController with ChangeNotifier {
  double _offset = 0;
  double get offset => _offset;

  void scroll(double delta) {
    _offset += delta;
    notifyListeners();
  }

  void jumpTo(double offset) {
    _offset = offset;
    notifyListeners();
  }
}

enum EditorContext {
  none,
  trim,
  split,
  speed,
}

class EditorUIState extends ChangeNotifier {
  EditorContext _context = EditorContext.none;

  EditorContext get context => _context;
  bool get inContext => _context != EditorContext.none;

  void openContext(EditorContext c) {
    _context = c;
    notifyListeners();
  }

  void closeContext() {
    _context = EditorContext.none;
    notifyListeners();
  }
}
