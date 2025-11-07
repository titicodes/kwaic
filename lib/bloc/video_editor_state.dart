// video_editor_state.dart
import 'package:equatable/equatable.dart';
import 'package:video_player/video_player.dart';

// Models
class VideoClip extends Equatable {
  final String id;
  final String path;
  final double startMs;
  final double endMs;
  final double originalDurationMs;
  final double speed;
  final double volume;
  final int rotation;
  final bool flipHorizontal;
  final bool flipVertical;
  final String? filter;
  final TransitionModel? transition;
  final List<TextOverlay> textOverlays;
  final List<StickerOverlay> stickerOverlays;
  final List<String> thumbnails;

  const VideoClip({
    required this.id,
    required this.path,
    required this.startMs,
    required this.endMs,
    required this.originalDurationMs,
    this.speed = 1.0,
    this.volume = 1.0,
    this.rotation = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.filter,
    this.transition,
    this.textOverlays = const [],
    this.stickerOverlays = const [],
    this.thumbnails = const [],
  });

  double get durationMs => (endMs - startMs) / speed;

  VideoClip copyWith({
    String? id,
    String? path,
    double? startMs,
    double? endMs,
    double? originalDurationMs,
    double? speed,
    double? volume,
    int? rotation,
    bool? flipHorizontal,
    bool? flipVertical,
    String? filter,
    TransitionModel? transition,
    List<TextOverlay>? textOverlays,
    List<StickerOverlay>? stickerOverlays,
    List<String>? thumbnails,
  }) {
    return VideoClip(
      id: id ?? this.id,
      path: path ?? this.path,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      originalDurationMs: originalDurationMs ?? this.originalDurationMs,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      rotation: rotation ?? this.rotation,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      filter: filter ?? this.filter,
      transition: transition ?? this.transition,
      textOverlays: textOverlays ?? this.textOverlays,
      stickerOverlays: stickerOverlays ?? this.stickerOverlays,
      thumbnails: thumbnails ?? this.thumbnails,
    );
  }

  @override
  List<Object?> get props => [
    id,
    path,
    startMs,
    endMs,
    originalDurationMs,
    speed,
    volume,
    rotation,
    flipHorizontal,
    flipVertical,
    filter,
    transition,
    textOverlays,
    stickerOverlays,
    thumbnails,
  ];
}

class TextOverlay extends Equatable {
  final String id;
  final String text;
  final double x;
  final double y;
  final double fontSize;
  final int color;
  final String fontFamily;
  final bool bold;
  final bool italic;
  final double startMs;
  final double durationMs;
  final String? animation;
  final double opacity;
  final double rotation;

  const TextOverlay({
    required this.id,
    required this.text,
    this.x = 0.5,
    this.y = 0.5,
    this.fontSize = 32,
    this.color = 0xFFFFFFFF,
    this.fontFamily = 'Arial',
    this.bold = false,
    this.italic = false,
    required this.startMs,
    required this.durationMs,
    this.animation,
    this.opacity = 1.0,
    this.rotation = 0,
  });

  TextOverlay copyWith({
    String? id,
    String? text,
    double? x,
    double? y,
    double? fontSize,
    int? color,
    String? fontFamily,
    bool? bold,
    bool? italic,
    double? startMs,
    double? durationMs,
    String? animation,
    double? opacity,
    double? rotation,
  }) {
    return TextOverlay(
      id: id ?? this.id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      fontFamily: fontFamily ?? this.fontFamily,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      startMs: startMs ?? this.startMs,
      durationMs: durationMs ?? this.durationMs,
      animation: animation ?? this.animation,
      opacity: opacity ?? this.opacity,
      rotation: rotation ?? this.rotation,
    );
  }

  @override
  List<Object?> get props => [
    id,
    text,
    x,
    y,
    fontSize,
    color,
    fontFamily,
    bold,
    italic,
    startMs,
    durationMs,
    animation,
    opacity,
    rotation,
  ];
}

class StickerOverlay extends Equatable {
  final String id;
  final String assetPath;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final double startMs;
  final double durationMs;
  final double opacity;

  const StickerOverlay({
    required this.id,
    required this.assetPath,
    this.x = 0.5,
    this.y = 0.5,
    this.scale = 1.0,
    this.rotation = 0,
    required this.startMs,
    required this.durationMs,
    this.opacity = 1.0,
  });

  StickerOverlay copyWith({
    String? id,
    String? assetPath,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    double? startMs,
    double? durationMs,
    double? opacity,
  }) {
    return StickerOverlay(
      id: id ?? this.id,
      assetPath: assetPath ?? this.assetPath,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      startMs: startMs ?? this.startMs,
      durationMs: durationMs ?? this.durationMs,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  List<Object?> get props => [
    id,
    assetPath,
    x,
    y,
    scale,
    rotation,
    startMs,
    durationMs,
    opacity,
  ];
}

class TransitionModel extends Equatable {
  final String type;
  final double durationSeconds;

  const TransitionModel({
    required this.type,
    this.durationSeconds = 0.5,
  });

  @override
  List<Object?> get props => [type, durationSeconds];
}

class AudioTrack extends Equatable {
  final String id;
  final String path;
  final double startMs;
  final double durationMs;
  final double volume;
  final bool isMuted;

  const AudioTrack({
    required this.id,
    required this.path,
    this.startMs = 0,
    required this.durationMs,
    this.volume = 1.0,
    this.isMuted = false,
  });

  AudioTrack copyWith({
    String? id,
    String? path,
    double? startMs,
    double? durationMs,
    double? volume,
    bool? isMuted,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      path: path ?? this.path,
      startMs: startMs ?? this.startMs,
      durationMs: durationMs ?? this.durationMs,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  @override
  List<Object?> get props => [id, path, startMs, durationMs, volume, isMuted];
}

class ProjectSettings extends Equatable {
  final double aspectRatio;
  final int exportQuality;
  final int fps;
  final String projectName;

  const ProjectSettings({
    this.aspectRatio = 9 / 16,
    this.exportQuality = 1080,
    this.fps = 30,
    this.projectName = 'Untitled Project',
  });

  ProjectSettings copyWith({
    double? aspectRatio,
    int? exportQuality,
    int? fps,
    String? projectName,
  }) {
    return ProjectSettings(
      aspectRatio: aspectRatio ?? this.aspectRatio,
      exportQuality: exportQuality ?? this.exportQuality,
      fps: fps ?? this.fps,
      projectName: projectName ?? this.projectName,
    );
  }

  @override
  List<Object?> get props => [aspectRatio, exportQuality, fps, projectName];
}

// ──────────────────────────────────────────────────────────────
// 1. TimelineTrack – a generic track that lives on the timeline
// ──────────────────────────────────────────────────────────────
class TimelineTrack extends Equatable {
  final String id;
  final TrackType type;               // video | sticker | voiceOver | bgMusic | text
  final String sourceId;              // id of the source (VideoClip.id, StickerOverlay.id …)
  final double startMs;               // start on the global timeline
  final double endMs;                 // end on the global timeline
  final double volume;                // 0-1 (only for audio tracks)
  final bool muted;

  const TimelineTrack({
    required this.id,
    required this.type,
    required this.sourceId,
    required this.startMs,
    required this.endMs,
    this.volume = 1.0,
    this.muted = false,
  });

  double get durationMs => endMs - startMs;

  TimelineTrack copyWith({
    String? id,
    TrackType? type,
    String? sourceId,
    double? startMs,
    double? endMs,
    double? volume,
    bool? muted,
  }) {
    return TimelineTrack(
      id: id ?? this.id,
      type: type ?? this.type,
      sourceId: sourceId ?? this.sourceId,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      volume: volume ?? this.volume,
      muted: muted ?? this.muted,
    );
  }

  @override
  List<Object?> get props => [id, type, sourceId, startMs, endMs, volume, muted];
}

enum TrackType { video, sticker, voiceOver, bgMusic, text }
// Main State Classes
abstract class VideoEditorState extends Equatable {
  const VideoEditorState();

  @override
  List<Object?> get props => [];
}

class VideoEditorInitial extends VideoEditorState {
  const VideoEditorInitial();
}

class VideoEditorLoading extends VideoEditorState {
  const VideoEditorLoading();
}

class VideoEditorLoaded extends VideoEditorState {
  final List<VideoClip> clips;
  final int? selectedClipIndex;
  final VideoPlayerController? videoController;
  final bool isPlaying;
  final double currentPositionMs;
  final double pixelsPerSecond;
  final int selectedToolTab;
  final AudioTrack? backgroundMusic;
  final List<AudioTrack> voiceOvers;
  final bool isRecording;
  final bool isExporting;
  final double exportProgress;
  final String? errorMessage;
  final ProjectSettings projectSettings;
  final List<TimelineTrack> timelineTracks;   // NEW

  const VideoEditorLoaded({
    this.clips = const [],
    this.selectedClipIndex,
    this.videoController,
    this.isPlaying = false,
    this.currentPositionMs = 0,
    this.pixelsPerSecond = 100,
    this.selectedToolTab = 0,
    this.backgroundMusic,
    this.voiceOvers = const [],
    this.isRecording = false,
    this.isExporting = false,
    this.exportProgress = 0,
    this.errorMessage,
    this.projectSettings = const ProjectSettings(),
    this.timelineTracks = const [],
  });

  double get totalDurationMs {
    return clips.fold(0.0, (sum, clip) => sum + clip.durationMs);
  }

  VideoClip? get selectedClip {
    if (selectedClipIndex == null || selectedClipIndex! < 0 || selectedClipIndex! >= clips.length) {
      return null;
    }
    return clips[selectedClipIndex!];
  }

  VideoEditorLoaded copyWith({
    List<VideoClip>? clips,
    int? selectedClipIndex,
    VideoPlayerController? videoController,
    bool? isPlaying,
    double? currentPositionMs,
    double? pixelsPerSecond,
    int? selectedToolTab,
    AudioTrack? backgroundMusic,
    List<AudioTrack>? voiceOvers,
    bool? isRecording,
    bool? isExporting,
    double? exportProgress,
    String? errorMessage,
    ProjectSettings? projectSettings,
    bool clearError = false,
    List<TimelineTrack>? timelineTracks,
  }) {
    return VideoEditorLoaded(
      clips: clips ?? this.clips,
      selectedClipIndex: selectedClipIndex ?? this.selectedClipIndex,
      videoController: videoController ?? this.videoController,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPositionMs: currentPositionMs ?? this.currentPositionMs,
      pixelsPerSecond: pixelsPerSecond ?? this.pixelsPerSecond,
      selectedToolTab: selectedToolTab ?? this.selectedToolTab,
      backgroundMusic: backgroundMusic ?? this.backgroundMusic,
      voiceOvers: voiceOvers ?? this.voiceOvers,
      isRecording: isRecording ?? this.isRecording,
      isExporting: isExporting ?? this.isExporting,
      exportProgress: exportProgress ?? this.exportProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      projectSettings: projectSettings ?? this.projectSettings,
      timelineTracks: timelineTracks ?? this.timelineTracks,
    );
  }

  @override
  List<Object?> get props => [
    clips,
    selectedClipIndex,
    videoController,
    isPlaying,
    currentPositionMs,
    pixelsPerSecond,
    selectedToolTab,
    backgroundMusic,
    voiceOvers,
    isRecording,
    isExporting,
    exportProgress,
    errorMessage,
    projectSettings,
    timelineTracks,
  ];
}

class VideoEditorError extends VideoEditorState {
  final String message;

  const VideoEditorError(this.message);

  @override
  List<Object?> get props => [message];
}