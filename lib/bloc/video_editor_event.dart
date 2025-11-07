// video_editor_event.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:kwaic/bloc/video_editor_state.dart';

abstract class VideoEditorEvent extends Equatable {
  const VideoEditorEvent();

  @override
  List<Object?> get props => [];
}

// Video Management Events
class LoadVideoEvent extends VideoEditorEvent {
  final File videoFile;
  const LoadVideoEvent(this.videoFile);

  @override
  List<Object?> get props => [videoFile];
}

class AddVideoClipEvent extends VideoEditorEvent {
  final File videoFile;
  const AddVideoClipEvent(this.videoFile);

  @override
  List<Object?> get props => [videoFile];
}

class RemoveClipEvent extends VideoEditorEvent {
  final int clipIndex;
  const RemoveClipEvent(this.clipIndex);

  @override
  List<Object?> get props => [clipIndex];
}

class SelectClipEvent extends VideoEditorEvent {
  final int clipIndex;
  const SelectClipEvent(this.clipIndex);

  @override
  List<Object?> get props => [clipIndex];
}

class DuplicateClipEvent extends VideoEditorEvent {
  final int clipIndex;
  const DuplicateClipEvent(this.clipIndex);

  @override
  List<Object?> get props => [clipIndex];
}

class ReorderClipsEvent extends VideoEditorEvent {
  final int oldIndex;
  final int newIndex;
  const ReorderClipsEvent(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

// Playback Events
class PlayVideoEvent extends VideoEditorEvent {}

class PauseVideoEvent extends VideoEditorEvent {}

class TogglePlayPauseEvent extends VideoEditorEvent {}

class SeekToPositionEvent extends VideoEditorEvent {
  final double milliseconds;
  const SeekToPositionEvent(this.milliseconds);

  @override
  List<Object?> get props => [milliseconds];
}

class UpdatePlaybackPositionEvent extends VideoEditorEvent {
  final double milliseconds;
  const UpdatePlaybackPositionEvent(this.milliseconds);

  @override
  List<Object?> get props => [milliseconds];
}

// Editing Events
class SplitClipEvent extends VideoEditorEvent {
  final int clipIndex;
  final double splitPositionMs;
  const SplitClipEvent(this.clipIndex, this.splitPositionMs);

  @override
  List<Object?> get props => [clipIndex, splitPositionMs];
}

class TrimClipEvent extends VideoEditorEvent {
  final int clipIndex;
  final double startMs;
  final double endMs;
  const TrimClipEvent(this.clipIndex, this.startMs, this.endMs);

  @override
  List<Object?> get props => [clipIndex, startMs, endMs];
}

class SetClipSpeedEvent extends VideoEditorEvent {
  final int clipIndex;
  final double speed;
  const SetClipSpeedEvent(this.clipIndex, this.speed);

  @override
  List<Object?> get props => [clipIndex, speed];
}

class SetClipVolumeEvent extends VideoEditorEvent {
  final int clipIndex;
  final double volume;
  const SetClipVolumeEvent(this.clipIndex, this.volume);

  @override
  List<Object?> get props => [clipIndex, volume];
}

class RotateClipEvent extends VideoEditorEvent {
  final int clipIndex;
  final int degrees;
  const RotateClipEvent(this.clipIndex, this.degrees);

  @override
  List<Object?> get props => [clipIndex, degrees];
}

class FlipClipEvent extends VideoEditorEvent {
  final int clipIndex;
  final bool horizontal;
  const FlipClipEvent(this.clipIndex, {this.horizontal = true});

  @override
  List<Object?> get props => [clipIndex, horizontal];
}

class ApplyFilterEvent extends VideoEditorEvent {
  final int clipIndex;
  final String filterName;
  const ApplyFilterEvent(this.clipIndex, this.filterName);

  @override
  List<Object?> get props => [clipIndex, filterName];
}

class SetTransitionEvent extends VideoEditorEvent {
  final int clipIndex;
  final String transitionType;
  final double durationSeconds;
  const SetTransitionEvent(this.clipIndex, this.transitionType, this.durationSeconds);

  @override
  List<Object?> get props => [clipIndex, transitionType, durationSeconds];
}

// Text Overlay Events
class AddTextOverlayEvent extends VideoEditorEvent {
  final int clipIndex;
  final String text;
  final double startMs;
  final double durationMs;
  final double x;
  final double y;
  final double fontSize;
  final int color;
  const AddTextOverlayEvent({
    required this.clipIndex,
    required this.text,
    required this.startMs,
    required this.durationMs,
    this.x = 0.5,
    this.y = 0.5,
    this.fontSize = 32,
    this.color = 0xFFFFFFFF,
  });

  @override
  List<Object?> get props => [clipIndex, text, startMs, durationMs, x, y, fontSize, color];
}

class UpdateTextOverlayEvent extends VideoEditorEvent {
  final int clipIndex;
  final int overlayIndex;
  final String? text;
  final double? x;
  final double? y;
  final double? fontSize;
  final int? color;
  final double? startMs;
  final double? durationMs;
  const UpdateTextOverlayEvent({
    required this.clipIndex,
    required this.overlayIndex,
    this.text,
    this.x,
    this.y,
    this.fontSize,
    this.color,
    this.startMs,
    this.durationMs,
  });

  @override
  List<Object?> get props => [clipIndex, overlayIndex, text, x, y, fontSize, color, startMs, durationMs];
}

class RemoveTextOverlayEvent extends VideoEditorEvent {
  final int clipIndex;
  final int overlayIndex;
  const RemoveTextOverlayEvent(this.clipIndex, this.overlayIndex);

  @override
  List<Object?> get props => [clipIndex, overlayIndex];
}

// Sticker Events
class AddStickerOverlayEvent extends VideoEditorEvent {
  final int clipIndex;
  final String assetPath;
  final double startMs;
  final double durationMs;
  final double x;
  final double y;
  const AddStickerOverlayEvent({
    required this.clipIndex,
    required this.assetPath,
    required this.startMs,
    required this.durationMs,
    this.x = 0.5,
    this.y = 0.5,
  });

  @override
  List<Object?> get props => [clipIndex, assetPath, startMs, durationMs, x, y];
}

class UpdateStickerOverlayEvent extends VideoEditorEvent {
  final int clipIndex;
  final int overlayIndex;
  final double? x;
  final double? y;
  final double? scale;
  final double? rotation;
  const UpdateStickerOverlayEvent({
    required this.clipIndex,
    required this.overlayIndex,
    this.x,
    this.y,
    this.scale,
    this.rotation,
  });

  @override
  List<Object?> get props => [clipIndex, overlayIndex, x, y, scale, rotation];
}

class RemoveStickerOverlayEvent extends VideoEditorEvent {
  final int clipIndex;
  final int overlayIndex;
  const RemoveStickerOverlayEvent(this.clipIndex, this.overlayIndex);

  @override
  List<Object?> get props => [clipIndex, overlayIndex];
}

// Audio Events
class AddBackgroundMusicEvent extends VideoEditorEvent {
  final File audioFile;
  final double volume;
  const AddBackgroundMusicEvent(this.audioFile, {this.volume = 1.0});

  @override
  List<Object?> get props => [audioFile, volume];
}

class RemoveBackgroundMusicEvent extends VideoEditorEvent {}

class SetBackgroundMusicVolumeEvent extends VideoEditorEvent {
  final double volume;
  const SetBackgroundMusicVolumeEvent(this.volume);

  @override
  List<Object?> get props => [volume];
}

class AddVoiceOverEvent extends VideoEditorEvent {
  final File audioFile;
  final double startMs;
  const AddVoiceOverEvent(this.audioFile, this.startMs);

  @override
  List<Object?> get props => [audioFile, startMs];
}

class StartVoiceRecordingEvent extends VideoEditorEvent {}

class StopVoiceRecordingEvent extends VideoEditorEvent {}

class GenerateTTSEvent extends VideoEditorEvent {
  final String text;
  final String voice;
  final double startMs;
  const GenerateTTSEvent(this.text, {this.voice = 'default', this.startMs = 0});

  @override
  List<Object?> get props => [text, voice, startMs];
}

// Timeline Events
class ZoomTimelineEvent extends VideoEditorEvent {
  final bool zoomIn;
  const ZoomTimelineEvent({required this.zoomIn});

  @override
  List<Object?> get props => [zoomIn];
}

class SetTimelineZoomEvent extends VideoEditorEvent {
  final double pixelsPerSecond;
  const SetTimelineZoomEvent(this.pixelsPerSecond);

  @override
  List<Object?> get props => [pixelsPerSecond];
}

class ChangeToolTabEvent extends VideoEditorEvent {
  final int tabIndex;
  const ChangeToolTabEvent(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

// Export Events
class ExportVideoEvent extends VideoEditorEvent {
  final String outputPath;
  final int quality;
  final int fps;
  const ExportVideoEvent({
    required this.outputPath,
    this.quality = 1080,
    this.fps = 30,
  });

  @override
  List<Object?> get props => [outputPath, quality, fps];
}

class CancelExportEvent extends VideoEditorEvent {}

class UpdateExportProgressEvent extends VideoEditorEvent {
  final double progress;
  const UpdateExportProgressEvent(this.progress);

  @override
  List<Object?> get props => [progress];
}

// Undo/Redo Events
class UndoEvent extends VideoEditorEvent {}

class RedoEvent extends VideoEditorEvent {}

class AddHistoryStateEvent extends VideoEditorEvent {
  final dynamic state;
  const AddHistoryStateEvent(this.state);

  @override
  List<Object?> get props => [state];
}

// Project Events
class SaveProjectEvent extends VideoEditorEvent {
  final String projectName;
  const SaveProjectEvent(this.projectName);

  @override
  List<Object?> get props => [projectName];
}

class LoadProjectEvent extends VideoEditorEvent {
  final String projectPath;
  const LoadProjectEvent(this.projectPath);

  @override
  List<Object?> get props => [projectPath];
}

class ResetProjectEvent extends VideoEditorEvent {}

// ──────────────────────────────────────────────────────────────
// 2. Drag-to-timeline events
// ──────────────────────────────────────────────────────────────
class AddTrackFromSourceEvent extends VideoEditorEvent {
  final TrackType type;
  final String sourceId;          // e.g. clip.id, sticker.id, audio.id
  final double startMs;           // where the user released the drag
  final double endMs;             // optional – if omitted → source duration
  const AddTrackFromSourceEvent(this.type, this.sourceId, this.startMs, {this.endMs = -1});
  @override List<Object?> get props => [type, sourceId, startMs, endMs];
}

class MoveTrackEvent extends VideoEditorEvent {
  final String trackId;
  final double newStartMs;
  const MoveTrackEvent(this.trackId, this.newStartMs);
  @override List<Object?> get props => [trackId, newStartMs];
}

class ResizeTrackEvent extends VideoEditorEvent {
  final String trackId;
  final double newEndMs;          // stretch/shorten
  const ResizeTrackEvent(this.trackId, this.newEndMs);
  @override List<Object?> get props => [trackId, newEndMs];
}

class RemoveTrackEvent extends VideoEditorEvent {
  final String trackId;
  const RemoveTrackEvent(this.trackId);
  @override List<Object?> get props => [trackId];
}