import 'package:kwaic/nes_scr/model/timeline_item.dart';

class ClipSelectionState {
  String? clipId;
  TimelineItemType? clipType;
  bool isEditMode = false;

  bool get hasSelection => clipId != null;

  // THIS IS THE ONLY METHOD YOU WERE MISSING
  bool isSelected(String id, TimelineItemType type) {
    return clipId == id && clipType == type;
  }

  void select(String id, TimelineItemType type) {
    clipId = id;
    clipType = type;
    // No notifyListeners() needed — you're calling setState() manually in the UI
  }

  void clear() {
    clipId = null;
    clipType = null;
    isEditMode = false;
  }

  ClipSelectionState copy() {
    return ClipSelectionState()
      ..clipId = clipId
      ..clipType = clipType
      ..isEditMode = isEditMode;
  }

  // Optional: for debugging
  @override
  String toString() => 'Selection(id: $clipId, type: $clipType)';


}