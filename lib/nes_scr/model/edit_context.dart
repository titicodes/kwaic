import 'package:kwaic/nes_scr/model/timeline_item.dart';

class EditingContext {
  String? activeItemId;
  TimelineItemType? activeItemType;
  String? activeEditMode; // 'split', 'trim', 'rotate', 'crop', etc.

  void clear() {
    activeItemId = null;
    activeItemType = null;
    activeEditMode = null;
  }

  bool isActive(String itemId) => activeItemId == itemId;
}
