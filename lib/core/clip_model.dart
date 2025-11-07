// clip_model.dart
import 'package:get/get.dart';

class ClipModel {
  // ────── BASIC ──────
  final String path;
  List<String> thumbs;                     // ← NOT final
  double startMs;
  double endMs;
  final double originalDurationMs;

  // ────── AUDIO / SPEED ──────
  double volume;
  double speed;

  // ────── TRANSFORMS ──────
  bool flipHorizontal;
  bool flipVertical;
  int rotation;

  // ────── CROP ──────
  Map<String, double>? cropParams;

  // ────── FILTER ──────
  String filter;
  String filterName;

  // ────── CHROMA KEY ──────
  String? colorKey;

  // ────── TRANSITION ──────
  String transitionType;
  double transitionDuration;

  // ────── OVERLAYS ──────
  List<TextOverlay> textOverlays;
  List<StickerOverlay> stickerOverlays;

  // ────── CONSTRUCTOR ──────
  ClipModel({
    required this.path,
    this.thumbs = const [],               // ← mutable
    this.startMs = 0,
    required this.endMs,
    required this.originalDurationMs,
    this.volume = 1.0,
    this.speed = 1.0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.rotation = 0,
    this.cropParams,
    this.filter = '',
    this.filterName = 'None',
    this.colorKey,
    this.transitionType = 'none',
    this.transitionDuration = 0.5,
    this.textOverlays = const [],
    this.stickerOverlays = const [],
  });

  // ────── COPY (for undo/redo) ──────
  ClipModel copy() {
    return ClipModel(
      path: path,
      thumbs: List.from(thumbs),          // deep copy
      startMs: startMs,
      endMs: endMs,
      originalDurationMs: originalDurationMs,
      volume: volume,
      speed: speed,
      flipHorizontal: flipHorizontal,
      flipVertical: flipVertical,
      rotation: rotation,
      cropParams: cropParams != null ? Map.from(cropParams!) : null,
      filter: filter,
      filterName: filterName,
      colorKey: colorKey,
      transitionType: transitionType,
      transitionDuration: transitionDuration,
      textOverlays: textOverlays.map((e) => e.copy()).toList(),
      stickerOverlays: stickerOverlays.map((e) => e.copy()).toList(),
    );
  }

  // ────── COPY-WITH ──────
  ClipModel copyWith({
    String? path,
    List<String>? thumbs,
    double? startMs,
    double? endMs,
    double? originalDurationMs,
    double? volume,
    double? speed,
    bool? flipHorizontal,
    bool? flipVertical,
    int? rotation,
    Map<String, double>? cropParams,
    String? filter,
    String? filterName,
    String? colorKey,
    String? transitionType,
    double? transitionDuration,
    List<TextOverlay>? textOverlays,
    List<StickerOverlay>? stickerOverlays,
  }) {
    return ClipModel(
      path: path ?? this.path,
      thumbs: thumbs ?? List.from(this.thumbs),
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      originalDurationMs: originalDurationMs ?? this.originalDurationMs,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      rotation: rotation ?? this.rotation,
      cropParams: cropParams ?? (this.cropParams != null ? Map.from(this.cropParams!) : null),
      filter: filter ?? this.filter,
      filterName: filterName ?? this.filterName,
      colorKey: colorKey ?? this.colorKey,
      transitionType: transitionType ?? this.transitionType,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      textOverlays: textOverlays?.map((e) => e.copy()).toList() ??
          this.textOverlays.map((e) => e.copy()).toList(),
      stickerOverlays: stickerOverlays?.map((e) => e.copy()).toList() ??
          this.stickerOverlays.map((e) => e.copy()).toList(),
    );
  }
}

// ─────────────────────── TEXT OVERLAY ───────────────────────
class TextOverlay {
  String text;
  double startMs;
  double durationMs;
  double x;
  double y;
  double fontSize;
  int color;

  TextOverlay({
    required this.text,
    this.startMs = 0,
    this.durationMs = 3000,
    this.x = 0.5,
    this.y = 0.5,
    this.fontSize = 32,
    this.color = 0xFFFFFFFF,
  });

  TextOverlay copy() => TextOverlay(
    text: text,
    startMs: startMs,
    durationMs: durationMs,
    x: x,
    y: y,
    fontSize: fontSize,
    color: color,
  );
}

// ─────────────────────── STICKER OVERLAY ───────────────────────
class StickerOverlay {
  String assetPath;
  double startMs;
  double durationMs;
  double x;
  double y;
  double scale;
  double rotation;

  StickerOverlay({
    required this.assetPath,
    this.startMs = 0,
    this.durationMs = 5000,
    this.x = 0.5,
    this.y = 0.5,
    this.scale = 1.0,
    this.rotation = 0,
  });

  StickerOverlay copy() => StickerOverlay(
    assetPath: assetPath,
    startMs: startMs,
    durationMs: durationMs,
    x: x,
    y: y,
    scale: scale,
    rotation: rotation,
  );
}