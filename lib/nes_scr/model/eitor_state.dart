import 'package:collection/collection.dart';
import 'package:kwaic/nes_scr/model/timeline_item.dart';

import 'clip_selection_state.dart';

class EditorState {
  final List<TimelineItem> clips;
  final List<TimelineItem> audioItems;
  final List<TimelineItem> textItems;
  final List<TimelineItem> overlayItems;

  // LEGACY: Keep this for loading old saved projects
  final int? selectedClip;

  // CURRENT: This is what you actually use in the app
  final ClipSelectionState selection;

  final Duration playheadPosition;

  EditorState({
    required this.clips,
    required this.audioItems,
    required this.textItems,
    required this.overlayItems,
    this.selectedClip,                     // ← can be null (legacy)
    required this.selection,               // ← always valid
    required this.playheadPosition,
  });

  // ─────────────────────────────────────────────────────────────
  // JSON Serialization — supports BOTH old and new formats
  // ─────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'clips': clips.map((c) => c.toJson()).toList(),
    'audioItems': audioItems.map((a) => a.toJson()).toList(),
    'textItems': textItems.map((t) => t.toJson()).toList(),
    'overlayItems': overlayItems.map((o) => o.toJson()).toList(),

    // Save BOTH — future-proof and backward compatible
    'selectedClip': selection.clipId != null
        ? int.tryParse(selection.clipId!) // fallback to old format if possible
        : selectedClip?.toString(),       // or keep legacy value

    'playheadPosition': playheadPosition.inMilliseconds,

    // Optional: Save modern selection too (recommended!)
    // Remove this line if you want to stay 100% minimal
    // 'selectionId': selection.clipId,
    // 'selectionType': selection.clipType?.toString().split('.').last,
  };

  factory EditorState.fromJson(Map<String, dynamic> json) {
    // First, try to parse modern selection (if saved)
    final String? modernId = json['selectionId'] as String?;
    final String? modernTypeStr = json['selectionType'] as String?;
    final TimelineItemType? modernType = modernTypeStr != null
        ? TimelineItemType.values.firstWhereOrNull(
            (t) => t.toString() == 'TimelineItemType.$modernTypeStr')
        : null;

    // Fallback to legacy int-based selection
    int? legacyId;
    final dynamic legacyValue = json['selectedClip'];
    if (legacyValue is num) {
      legacyId = legacyValue.toInt();
    } else if (legacyValue is String && legacyValue.isNotEmpty) {
      legacyId = int.tryParse(legacyValue);
    }

    // Build selection state — prefer modern, fallback to legacy
    final selection = ClipSelectionState();
    if (modernId != null && modernType != null) {
      selection.select(modernId, modernType);
    } else if (legacyId != null) {
      // Try to find item with this legacy numeric ID
      final allItems = [
        ...json['clips'] as List,
        ...json['audioItems'] as List,
        ...json['textItems'] as List,
        ...json['overlayItems'] as List,
      ];

      for (final itemJson in allItems) {
        final item = TimelineItem.fromJson(itemJson);
        if (int.tryParse(item.id) == legacyId) {
          selection.select(item.id, item.type);
          break;
        }
      }
    }

    return EditorState(
      clips: (json['clips'] as List)
          .map((c) => TimelineItem.fromJson(c))
          .toList(),
      audioItems: (json['audioItems'] as List)
          .map((a) => TimelineItem.fromJson(a))
          .toList(),
      textItems: (json['textItems'] as List)
          .map((t) => TimelineItem.fromJson(t))
          .toList(),
      overlayItems: (json['overlayItems'] as List)
          .map((o) => TimelineItem.fromJson(o))
          .toList(),
      selectedClip: legacyId,  // keep for compatibility
      selection: selection,    // ← this is what you actually use
      playheadPosition: Duration(
        milliseconds: (json['playheadPosition'] as num).toInt(),
      ),
    );
  }


}