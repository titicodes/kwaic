// video_editor_bloc.dart
import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kwaic/bloc/video_editor_event.dart';
import 'package:kwaic/bloc/video_editor_state.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:collection/collection.dart';

// Add Undo/Redo support
class HistoryState {
  final VideoEditorLoaded state;
  HistoryState(this.state);
}

class VideoEditorBloc extends Bloc<VideoEditorEvent, VideoEditorState> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  Timer? _playbackTimer;
  final _uuid = const Uuid();

  final List<HistoryState> _history = [];
  int _historyIndex = -1;

  VideoEditorBloc() : super(const VideoEditorInitial()) {
    // Video Management
    on<LoadVideoEvent>(_onLoadVideo);
    on<AddVideoClipEvent>(_onAddVideoClip);
    on<RemoveClipEvent>(_onRemoveClip);
    on<SelectClipEvent>(_onSelectClip);
    on<DuplicateClipEvent>(_onDuplicateClip);
    on<ReorderClipsEvent>(_onReorderClips);

    // Playback
    on<PlayVideoEvent>(_onPlayVideo);
    on<PauseVideoEvent>(_onPauseVideo);
    on<TogglePlayPauseEvent>(_onTogglePlayPause);
    on<SeekToPositionEvent>(_onSeekToPosition);
    on<UpdatePlaybackPositionEvent>(_onUpdatePlaybackPosition);

    // Editing
    on<SplitClipEvent>(_onSplitClip);
    on<TrimClipEvent>(_onTrimClip);
    on<SetClipSpeedEvent>(_onSetClipSpeed);
    on<SetClipVolumeEvent>(_onSetClipVolume);
    on<RotateClipEvent>(_onRotateClip);
    on<FlipClipEvent>(_onFlipClip);
    on<ApplyFilterEvent>(_onApplyFilter);
    on<SetTransitionEvent>(_onSetTransition);

    // Text Overlays
    on<AddTextOverlayEvent>(_onAddTextOverlay);
    on<UpdateTextOverlayEvent>(_onUpdateTextOverlay);
    on<RemoveTextOverlayEvent>(_onRemoveTextOverlay);

    // Stickers
    on<AddStickerOverlayEvent>(_onAddStickerOverlay);
    on<UpdateStickerOverlayEvent>(_onUpdateStickerOverlay);
    on<RemoveStickerOverlayEvent>(_onRemoveStickerOverlay);

    // Audio
    on<AddBackgroundMusicEvent>(_onAddBackgroundMusic);
    on<RemoveBackgroundMusicEvent>(_onRemoveBackgroundMusic);
    on<SetBackgroundMusicVolumeEvent>(_onSetBackgroundMusicVolume);
    on<AddVoiceOverEvent>(_onAddVoiceOver);
    on<StartVoiceRecordingEvent>(_onStartVoiceRecording);
    on<StopVoiceRecordingEvent>(_onStopVoiceRecording);
    on<GenerateTTSEvent>(_onGenerateTTS);

    // Timeline
    on<ZoomTimelineEvent>(_onZoomTimeline);
    on<SetTimelineZoomEvent>(_onSetTimelineZoom);
    on<ChangeToolTabEvent>(_onChangeToolTab);

    // Export
    on<ExportVideoEvent>(_onExportVideo);
    on<CancelExportEvent>(_onCancelExport);
    on<UpdateExportProgressEvent>(_onUpdateExportProgress);

    // Project
    on<SaveProjectEvent>(_onSaveProject);
    on<LoadProjectEvent>(_onLoadProject);
    on<ResetProjectEvent>(_onResetProject);

    on<UndoEvent>(_onUndo);
    on<RedoEvent>(_onRedo);
    on<AddHistoryStateEvent>(_onAddHistoryState);

    on<AddTrackFromSourceEvent>(_onAddTrackFromSource);
    on<MoveTrackEvent>(_onMoveTrack);
    on<ResizeTrackEvent>(_onResizeTrack);
    on<RemoveTrackEvent>(_onRemoveTrack);
  }

  void _addToHistory(VideoEditorLoaded state) {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(HistoryState(state));
    _historyIndex++;
    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  Future<void> _onUndo(UndoEvent event, Emitter<VideoEditorState> emit) async {
    if (_historyIndex > 0) {
      _historyIndex--;
      emit(_history[_historyIndex].state.copyWith(clearError: true));
    }
  }

  Future<void> _onRedo(RedoEvent event, Emitter<VideoEditorState> emit) async {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      emit(_history[_historyIndex].state.copyWith(clearError: true));
    }
  }

  Future<void> _onAddHistoryState(AddHistoryStateEvent event, Emitter<VideoEditorState> emit) async {
    if (state is VideoEditorLoaded) {
      _addToHistory(state as VideoEditorLoaded);
    }
  }


  VideoEditorLoaded get _loadedState {
    if (state is VideoEditorLoaded) {
      return state as VideoEditorLoaded;
    }
    return const VideoEditorLoaded();
  }

  // ==================== VIDEO MANAGEMENT ====================

  Future<void> _onLoadVideo(LoadVideoEvent event, Emitter<VideoEditorState> emit) async {
    emit(const VideoEditorLoading());

    try {
      final controller = VideoPlayerController.file(event.videoFile);
      await controller.initialize();

      final duration = controller.value.duration.inMilliseconds.toDouble();
      final thumbnails = await _generateThumbnails(event.videoFile.path, duration);

      final clip = VideoClip(
        id: _uuid.v4(),
        path: event.videoFile.path,
        startMs: 0,
        endMs: duration,
        originalDurationMs: duration,
        thumbnails: thumbnails,
      );

      emit(VideoEditorLoaded(
        clips: [clip],
        selectedClipIndex: 0,
        videoController: controller,
      ));
    } catch (e) {
      emit(VideoEditorError('Failed to load video: $e'));
    }
  }

  Future<void> _onAddVideoClip(AddVideoClipEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    try {
      final controller = VideoPlayerController.file(event.videoFile);
      await controller.initialize();

      final duration = controller.value.duration.inMilliseconds.toDouble();
      final thumbnails = await _generateThumbnails(event.videoFile.path, duration);

      final clip = VideoClip(
        id: _uuid.v4(),
        path: event.videoFile.path,
        startMs: 0,
        endMs: duration,
        originalDurationMs: duration,
        thumbnails: thumbnails,
      );

      final updatedClips = List<VideoClip>.from(currentState.clips)..add(clip);

      await controller.dispose();

      emit(currentState.copyWith(
        clips: updatedClips,
        selectedClipIndex: updatedClips.length - 1,
      ));
    } catch (e) {
      emit(currentState.copyWith(errorMessage: 'Failed to add video clip: $e'));
    }
  }

  Future<void> _onRemoveClip(RemoveClipEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final updatedClips = List<VideoClip>.from(currentState.clips)..removeAt(event.clipIndex);

    emit(currentState.copyWith(
      clips: updatedClips,
      selectedClipIndex: updatedClips.isEmpty ? null : 0,
    ));
  }

  Future<void> _onSelectClip(SelectClipEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    final controller = VideoPlayerController.file(File(clip.path));
    await controller.initialize();

    // Dispose old controller
    await currentState.videoController?.dispose();

    emit(currentState.copyWith(
      selectedClipIndex: event.clipIndex,
      videoController: controller,
      currentPositionMs: clip.startMs,
    ));
  }

  Future<void> _onDuplicateClip(DuplicateClipEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final originalClip = currentState.clips[event.clipIndex];
    final duplicatedClip = originalClip.copyWith(id: _uuid.v4());

    final updatedClips = List<VideoClip>.from(currentState.clips)
      ..insert(event.clipIndex + 1, duplicatedClip);

    emit(currentState.copyWith(clips: updatedClips));
  }

  Future<void> _onReorderClips(ReorderClipsEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    final updatedClips = List<VideoClip>.from(currentState.clips);
    final clip = updatedClips.removeAt(event.oldIndex);
    updatedClips.insert(event.newIndex, clip);

    emit(currentState.copyWith(clips: updatedClips));
  }

  // ==================== PLAYBACK ====================

  Future<void> _onPlayVideo(PlayVideoEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (currentState.videoController == null) return;

    await currentState.videoController!.play();
    emit(currentState.copyWith(isPlaying: true));

    _startPlaybackTimer();
  }

  Future<void> _onPauseVideo(PauseVideoEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (currentState.videoController == null) return;

    await currentState.videoController!.pause();
    emit(currentState.copyWith(isPlaying: false));

    _stopPlaybackTimer();
  }

  Future<void> _onTogglePlayPause(TogglePlayPauseEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (currentState.isPlaying) {
      add(PauseVideoEvent());
    } else {
      add(PlayVideoEvent());
    }
  }

  Future<void> _onSeekToPosition(SeekToPositionEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (currentState.videoController == null) return;

    final duration = Duration(milliseconds: event.milliseconds.toInt());
    await currentState.videoController!.seekTo(duration);

    emit(currentState.copyWith(currentPositionMs: event.milliseconds));
  }

  Future<void> _onUpdatePlaybackPosition(UpdatePlaybackPositionEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    emit(currentState.copyWith(currentPositionMs: event.milliseconds));
  }

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (state is VideoEditorLoaded) {
        final currentState = state as VideoEditorLoaded;
        if (currentState.videoController != null && currentState.isPlaying) {
          final position = currentState.videoController!.value.position.inMilliseconds.toDouble();
          add(UpdatePlaybackPositionEvent(position));
        }
      }
    });
  }

  void _stopPlaybackTimer() {
    _playbackTimer?.cancel();
  }

  // ==================== EDITING ====================

  Future<void> _onSplitClip(SplitClipEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    final splitPoint = event.splitPositionMs;

    if (splitPoint <= clip.startMs || splitPoint >= clip.endMs) return;

    final firstClip = clip.copyWith(
      id: _uuid.v4(),
      endMs: splitPoint,
    );

    final secondClip = clip.copyWith(
      id: _uuid.v4(),
      startMs: splitPoint,
    );

    final updatedClips = List<VideoClip>.from(currentState.clips);
    updatedClips[event.clipIndex] = firstClip;
    updatedClips.insert(event.clipIndex + 1, secondClip);

    emit(currentState.copyWith(clips: updatedClips));
  }

  Future<void> _onTrimClip(TrimClipEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    final updatedClip = clip.copyWith(
      startMs: event.startMs,
      endMs: event.endMs,
    );

    final updatedClips = List<VideoClip>.from(currentState.clips);
    updatedClips[event.clipIndex] = updatedClip;

    emit(currentState.copyWith(clips: updatedClips));
  }

  Future<void> _onSetClipSpeed(SetClipSpeedEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    final updatedClip = clip.copyWith(speed: event.speed);

    final updatedClips = List<VideoClip>.from(currentState.clips);
    updatedClips[event.clipIndex] = updatedClip;

    emit(currentState.copyWith(clips: updatedClips));
  }

  Future<void> _onSetClipVolume(SetClipVolumeEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    final updatedClip = clip.copyWith(volume: event.volume);

    final updatedClips = List<VideoClip>.from(currentState.clips);
    updatedClips[event.clipIndex] = updatedClip;

    // Update video player volume
    if (currentState.selectedClipIndex == event.clipIndex) {
      await currentState.videoController?.setVolume(event.volume);
    }

    emit(currentState.copyWith(clips: updatedClips));
  }

  Future<void> _onRotateClip(RotateClipEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    final newRotation = (clip.rotation + event.degrees) % 360;
    final updatedClip = clip.copyWith(rotation: newRotation);

    final updatedClips = List<VideoClip>.from(currentState.clips);
    updatedClips[event.clipIndex] = updatedClip;

    emit(currentState.copyWith(clips: updatedClips));
  }

  Future<void> _onFlipClip(FlipClipEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    final updatedClip = event.horizontal
        ? clip.copyWith(flipHorizontal: !clip.flipHorizontal)
        : clip.copyWith(flipVertical: !clip.flipVertical);

    final updatedClips = List<VideoClip>.from(currentState.clips);
    updatedClips[event.clipIndex] = updatedClip;

    emit(currentState.copyWith(clips: updatedClips));
  }

  Future<void> _onApplyFilter(ApplyFilterEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    final updatedClip = clip.copyWith(filter: event.filterName);

    final updatedClips = List<VideoClip>.from(currentState.clips);
    updatedClips[event.clipIndex] = updatedClip;

    emit(currentState.copyWith(clips: updatedClips));
  }

  Future<void> _onSetTransition(SetTransitionEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    final transition = TransitionModel(
      type: event.transitionType,
      durationSeconds: event.durationSeconds,
    );
    final updatedClip = clip.copyWith(transition: transition);

    final updatedClips = List<VideoClip>.from(currentState.clips);
    updatedClips[event.clipIndex] = updatedClip;

    emit(currentState.copyWith(clips: updatedClips));
  }

  // ==================== TEXT OVERLAYS ====================

  Future<void> _onAddTextOverlay(AddTextOverlayEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    final overlay = TextOverlay(
      id: _uuid.v4(),
      text: event.text,
      x: event.x,
      y: event.y,
      fontSize: event.fontSize,
      color: event.color,
      startMs: event.startMs,
      durationMs: event.durationMs,
    );

    final updatedClip = clip.copyWith(
      textOverlays: [...clip.textOverlays, overlay],
    );

    final updatedClips = List<VideoClip>.from(currentState.clips);
    updatedClips[event.clipIndex] = updatedClip;

    emit(currentState.copyWith(clips: updatedClips));
  }

  Future<void> _onUpdateTextOverlay(UpdateTextOverlayEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    if (event.overlayIndex < 0 || event.overlayIndex >= clip.textOverlays.length) return;

    final overlay = clip.textOverlays[event.overlayIndex];
    final updatedOverlay = overlay.copyWith(
      text: event.text,
      x: event.x,
      y: event.y,
      fontSize: event.fontSize,
      color: event.color,
      startMs: event.startMs,
      durationMs: event.durationMs,
    );

    final updatedOverlays = List<TextOverlay>.from(clip.textOverlays);
    updatedOverlays[event.overlayIndex] = updatedOverlay;

    final updatedClip = clip.copyWith(textOverlays: updatedOverlays);
    final updatedClips = List<VideoClip>.from(currentState.clips);
    updatedClips[event.clipIndex] = updatedClip;

    emit(currentState.copyWith(clips: updatedClips));
  }

  Future<void> _onRemoveTextOverlay(RemoveTextOverlayEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;

    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    if (event.overlayIndex < 0 || event.overlayIndex >= clip.textOverlays.length) return;

    final updatedOverlays = List<TextOverlay>.from(clip.textOverlays)
      ..removeAt(event.overlayIndex);

    final updatedClip = clip.copyWith(textOverlays: updatedOverlays);
    final updatedClips = List<VideoClip>.from(currentState.clips);
    updatedClips[event.clipIndex] = updatedClip;

    emit(currentState.copyWith(clips: updatedClips));
  }

  // Continue in next comment with remaining handlers...

  @override
  Future<void> close() {
    _stopPlaybackTimer();
    if (state is VideoEditorLoaded) {
      (state as VideoEditorLoaded).videoController?.dispose();
    }
    _recorder.closeRecorder();
    return super.close();
  }

  // Helper methods
  Future<List<String>> _generateThumbnails(String videoPath, double durationMs) async {
    final thumbnails = <String>[];
    final tempDir = await getTemporaryDirectory();

    for (int i = 0; i < 6; i++) {
      final timestamp = (durationMs / 6 * i / 1000).toStringAsFixed(2);
      final outputPath = '${tempDir.path}/thumb_${_uuid.v4()}.jpg';

      final command = '-i $videoPath -ss $timestamp -vframes 1 -q:v 2 $outputPath';

      await FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          thumbnails.add(outputPath);
        }
      });
    }

    return thumbnails;
  }

  // Add remaining event handlers (stickers, audio, timeline, export, etc.)
  // See the bloc_handlers_continued artifact for the full implementation

  // STICKERS
  Future<void> _onAddStickerOverlay(AddStickerOverlayEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    final overlay = StickerOverlay(
      id: _uuid.v4(),
      assetPath: event.assetPath,
      x: event.x,
      y: event.y,
      startMs: event.startMs,
      durationMs: event.durationMs,
    );

    final updatedClip = clip.copyWith(
      stickerOverlays: [...clip.stickerOverlays, overlay],
    );

    final updatedClips = List<VideoClip>.from(currentState.clips);
    updatedClips[event.clipIndex] = updatedClip;

    emit(currentState.copyWith(clips: updatedClips));
  }

  Future<void> _onUpdateStickerOverlay(UpdateStickerOverlayEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    if (event.overlayIndex < 0 || event.overlayIndex >= clip.stickerOverlays.length) return;

    final overlay = clip.stickerOverlays[event.overlayIndex];
    final updatedOverlay = overlay.copyWith(
      x: event.x,
      y: event.y,
      scale: event.scale,
      rotation: event.rotation,
    );

    final updatedOverlays = List<StickerOverlay>.from(clip.stickerOverlays);
    updatedOverlays[event.overlayIndex] = updatedOverlay;

    final updatedClip = clip.copyWith(stickerOverlays: updatedOverlays);
    final updatedClips = List<VideoClip>.from(currentState.clips);
    updatedClips[event.clipIndex] = updatedClip;

    emit(currentState.copyWith(clips: updatedClips));
  }

  Future<void> _onRemoveStickerOverlay(RemoveStickerOverlayEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    if (event.clipIndex < 0 || event.clipIndex >= currentState.clips.length) return;

    final clip = currentState.clips[event.clipIndex];
    if (event.overlayIndex < 0 || event.overlayIndex >= clip.stickerOverlays.length) return;

    final updatedOverlays = List<StickerOverlay>.from(clip.stickerOverlays)
      ..removeAt(event.overlayIndex);

    final updatedClip = clip.copyWith(stickerOverlays: updatedOverlays);
    final updatedClips = List<VideoClip>.from(currentState.clips);
    updatedClips[event.clipIndex] = updatedClip;

    emit(currentState.copyWith(clips: updatedClips));
  }

  // AUDIO
  Future<void> _onAddBackgroundMusic(AddBackgroundMusicEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    try {
      // Get audio duration using FFprobe
      final command = '-i ${event.audioFile.path} -show_entries format=duration -v quiet -of csv="p=0"';

      double audioDuration = currentState.totalDurationMs;

      await FFmpegKit.execute(command).then((session) async {
        final output = await session.getOutput();
        if (output != null && output.isNotEmpty) {
          audioDuration = double.tryParse(output.trim()) ?? currentState.totalDurationMs;
        }
      });

      final audioTrack = AudioTrack(
        id: _uuid.v4(),
        path: event.audioFile.path,
        durationMs: audioDuration * 1000,
        volume: event.volume,
      );

      emit(currentState.copyWith(backgroundMusic: audioTrack));
    } catch (e) {
      emit(currentState.copyWith(errorMessage: 'Failed to add background music: $e'));
    }
  }

  Future<void> _onRemoveBackgroundMusic(RemoveBackgroundMusicEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    emit(currentState.copyWith(backgroundMusic: null));
  }

  Future<void> _onSetBackgroundMusicVolume(SetBackgroundMusicVolumeEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    if (currentState.backgroundMusic == null) return;

    final updatedMusic = currentState.backgroundMusic!.copyWith(volume: event.volume);
    emit(currentState.copyWith(backgroundMusic: updatedMusic));
  }

  Future<void> _onAddVoiceOver(AddVoiceOverEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    final voiceOver = AudioTrack(
      id: _uuid.v4(),
      path: event.audioFile.path,
      startMs: event.startMs,
      durationMs: 5000,
    );

    final updatedVoiceOvers = List<AudioTrack>.from(currentState.voiceOvers)..add(voiceOver);
    emit(currentState.copyWith(voiceOvers: updatedVoiceOvers));
  }

  Future<void> _onStartVoiceRecording(StartVoiceRecordingEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    try {
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder.openRecorder();
      await _recorder.startRecorder(toFile: path);

      emit(currentState.copyWith(isRecording: true));
    } catch (e) {
      emit(currentState.copyWith(errorMessage: 'Failed to start recording: $e'));
    }
  }

  Future<void> _onStopVoiceRecording(StopVoiceRecordingEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    try {
      final path = await _recorder.stopRecorder();
      await _recorder.closeRecorder();

      if (path != null) {
        final voiceOver = AudioTrack(
          id: _uuid.v4(),
          path: path,
          startMs: currentState.currentPositionMs,
          durationMs: 5000,
        );

        final updatedVoiceOvers = List<AudioTrack>.from(currentState.voiceOvers)..add(voiceOver);
        emit(currentState.copyWith(
          voiceOvers: updatedVoiceOvers,
          isRecording: false,
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Failed to stop recording: $e',
        isRecording: false,
      ));
    }
  }

  Future<void> _onGenerateTTS(GenerateTTSEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3';

      // TODO: Implement TTS generation with your preferred service

      final ttsTrack = AudioTrack(
        id: _uuid.v4(),
        path: outputPath,
        startMs: event.startMs,
        durationMs: 5000,
      );

      final updatedVoiceOvers = List<AudioTrack>.from(currentState.voiceOvers)..add(ttsTrack);
      emit(currentState.copyWith(voiceOvers: updatedVoiceOvers));
    } catch (e) {
      emit(currentState.copyWith(errorMessage: 'Failed to generate TTS: $e'));
    }
  }

  // TIMELINE
  Future<void> _onZoomTimeline(ZoomTimelineEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    final currentZoom = currentState.pixelsPerSecond;
    final newZoom = event.zoomIn
        ? (currentZoom * 1.2).clamp(50.0, 500.0)
        : (currentZoom / 1.2).clamp(50.0, 500.0);

    emit(currentState.copyWith(pixelsPerSecond: newZoom));
  }

  Future<void> _onSetTimelineZoom(SetTimelineZoomEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    emit(currentState.copyWith(pixelsPerSecond: event.pixelsPerSecond));
  }

  Future<void> _onChangeToolTab(ChangeToolTabEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    emit(currentState.copyWith(selectedToolTab: event.tabIndex));
  }

  // EXPORT
  Future<void> _onExportVideo(ExportVideoEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    emit(currentState.copyWith(isExporting: true, exportProgress: 0));

    try {
      final tempDir = await getTemporaryDirectory();
      final List<String> clipPaths = [];

      // Process each clip
      for (int i = 0; i < currentState.clips.length; i++) {
        final clip = currentState.clips[i];
        final processedPath = '${tempDir.path}/processed_$i.mp4';

        // Build FFmpeg filter complex
        final filters = _buildFilterComplex(clip);

        // Process clip with filters
        final command = '-i ${clip.path} '
            '-ss ${clip.startMs / 1000} '
            '-t ${(clip.endMs - clip.startMs) / 1000} '
            '-filter_complex "$filters" '
            '-c:v libx264 -preset fast -crf 23 '
            '-c:a aac -b:a 192k '
            '$processedPath';

        await FFmpegKit.execute(command).then((session) async {
          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            clipPaths.add(processedPath);
          }
        });

        // Update progress
        final progress = (i + 1) / currentState.clips.length * 0.7;
        emit(currentState.copyWith(exportProgress: progress));
      }

      // Concatenate clips
      final concatFile = '${tempDir.path}/concat.txt';
      final concatContent = clipPaths.map((p) => "file '$p'").join('\n');
      await File(concatFile).writeAsString(concatContent);

      final concatOutput = '${tempDir.path}/concatenated.mp4';
      final concatCommand = '-f concat -safe 0 -i $concatFile -c copy $concatOutput';

      await FFmpegKit.execute(concatCommand);

      emit(currentState.copyWith(exportProgress: 0.8));

      // Add background music if exists
      String finalOutput = concatOutput;
      if (currentState.backgroundMusic != null) {
        finalOutput = '${tempDir.path}/with_music.mp4';
        final musicCommand = '-i $concatOutput '
            '-i ${currentState.backgroundMusic!.path} '
            '-filter_complex "[1:a]volume=${currentState.backgroundMusic!.volume}[a1];[0:a][a1]amix=inputs=2:duration=shortest" '
            '-c:v copy -c:a aac -b:a 192k '
            '$finalOutput';

        await FFmpegKit.execute(musicCommand);
      }

      emit(currentState.copyWith(exportProgress: 0.9));

      // Copy to final output location
      await File(finalOutput).copy(event.outputPath);

      emit(currentState.copyWith(
        isExporting: false,
        exportProgress: 1.0,
      ));

      // Clean up temp files
      for (final path in clipPaths) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
    } catch (e) {
      emit(currentState.copyWith(
        isExporting: false,
        exportProgress: 0,
        errorMessage: 'Export failed: $e',
      ));
    }
  }

  String _buildFilterComplex(VideoClip clip) {
    final filters = <String>[];

    // Speed
    if (clip.speed != 1.0) {
      filters.add('setpts=${1 / clip.speed}*PTS');
    }

    // Rotation
    if (clip.rotation != 0) {
      final rotateMap = {
        0: 'noop',
        90: 'transpose=1',
        180: 'vflip,hflip',
        270: 'transpose=2'
      };
      filters.add(rotateMap[clip.rotation] ?? 'noop');
    }

    // Flip
    if (clip.flipHorizontal) filters.add('hflip');
    if (clip.flipVertical) filters.add('vflip');

    // Filter effects
    if (clip.filter != null) {
      final filterMap = {
        'black & white': 'colorchannelmixer=.3:.4:.3:0:.3:.4:.3:0:.3:.4:.3',
        'sepia': 'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131',
        'vintage': 'curves=vintage',
        'blur': 'boxblur=5:1',
        'sharpen': 'unsharp=5:5:1.0:5:5:0.0',
      };
      if (filterMap.containsKey(clip.filter!.toLowerCase())) {
        filters.add(filterMap[clip.filter!.toLowerCase()]!);
      }
    }


    return filters.isEmpty ? 'null' : filters.join(',');
  }

  Future<void> _onCancelExport(CancelExportEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    // Cancel all FFmpeg sessions
    await FFmpegKit.cancel();
    emit(currentState.copyWith(isExporting: false, exportProgress: 0));
  }

  Future<void> _onUpdateExportProgress(UpdateExportProgressEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    emit(currentState.copyWith(exportProgress: event.progress));
  }

  // PROJECT
  Future<void> _onSaveProject(SaveProjectEvent event, Emitter<VideoEditorState> emit) async {
    final currentState = _loadedState;
    try {
      final projectDir = await getApplicationDocumentsDirectory();
      final projectPath = '${projectDir.path}/${event.projectName}.json';

      final projectData = {
        'name': event.projectName,
        'clips': currentState.clips.map((c) => _serializeClip(c)).toList(),
        'backgroundMusic': currentState.backgroundMusic != null
            ? _serializeAudioTrack(currentState.backgroundMusic!)
            : null,
        'voiceOvers': currentState.voiceOvers.map((v) => _serializeAudioTrack(v)).toList(),
        'settings': {
          'aspectRatio': currentState.projectSettings.aspectRatio,
          'quality': currentState.projectSettings.exportQuality,
          'fps': currentState.projectSettings.fps,
        },
      };

      await File(projectPath).writeAsString(jsonEncode(projectData));
    } catch (e) {
      emit(currentState.copyWith(errorMessage: 'Failed to save project: $e'));
    }
  }

  Future<void> _onLoadProject(LoadProjectEvent event, Emitter<VideoEditorState> emit) async {
    try {
      final projectData = jsonDecode(await File(event.projectPath).readAsString());
      // TODO: Deserialize and restore state
    } catch (e) {
      emit(VideoEditorError('Failed to load project: $e'));
    }
  }

  Future<void> _onResetProject(ResetProjectEvent event, Emitter<VideoEditorState> emit) async {
    if (state is VideoEditorLoaded) {
      await (state as VideoEditorLoaded).videoController?.dispose();
    }
    emit(const VideoEditorInitial());
  }

  // Serialization helpers
  Map<String, dynamic> _serializeClip(VideoClip clip) {
    return {
      'id': clip.id,
      'path': clip.path,
      'startMs': clip.startMs,
      'endMs': clip.endMs,
      'speed': clip.speed,
      'volume': clip.volume,
      'rotation': clip.rotation,
      'flipHorizontal': clip.flipHorizontal,
      'flipVertical': clip.flipVertical,
      'filter': clip.filter,
    };
  }

  Map<String, dynamic> _serializeAudioTrack(AudioTrack track) {
    return {
      'id': track.id,
      'path': track.path,
      'startMs': track.startMs,
      'volume': track.volume,
    };
  }

  // Wrap all state changes with history
  @override
  void onChange(Change<VideoEditorState> change) {
    super.onChange(change);
    if (change.nextState is VideoEditorLoaded && change.currentState is VideoEditorLoaded) {
      final current = change.currentState as VideoEditorLoaded;
      final next = change.nextState as VideoEditorLoaded;
      if (!_areStatesEqual(current, next)) {
        add(AddHistoryStateEvent(next));
      }
    }
  }

  bool _areStatesEqual(VideoEditorLoaded a, VideoEditorLoaded b) {
    return a.clips.length == b.clips.length &&
        a.selectedClipIndex == b.selectedClipIndex &&
        a.backgroundMusic?.id == b.backgroundMusic?.id;
  }

  // ──────────────────────────────────────────────────────────────
// 3. Inside VideoEditorBloc (add after the existing handlers)
// ──────────────────────────────────────────────────────────────
  Future<void> _onAddTrackFromSource(
      AddTrackFromSourceEvent event,
      Emitter<VideoEditorState> emit) async {
    final s = _loadedState;
    final uuid = const Uuid();

    double start = event.startMs;
    double end = event.endMs;

    // ---- resolve source duration -------------------------------------------------
    double sourceDuration = 0;
    switch (event.type) {
      case TrackType.video:
        final clip = s.clips.firstWhereOrNull((c) => c.id == event.sourceId);
        sourceDuration = clip?.durationMs ?? 0;
        break;
      case TrackType.sticker:
        final sticker = s.clips
            .expand((c) => c.stickerOverlays)
            .firstWhereOrNull((o) => o.id == event.sourceId);
        sourceDuration = sticker?.durationMs ?? 3000;
        break;
      case TrackType.voiceOver:
        final vo = s.voiceOvers.firstWhereOrNull((a) => a.id == event.sourceId);
        sourceDuration = vo?.durationMs ?? 0;
        break;
      case TrackType.bgMusic:
        sourceDuration = s.backgroundMusic?.durationMs ?? 0;
        break;
      case TrackType.text:
        final txt = s.clips
            .expand((c) => c.textOverlays)
            .firstWhereOrNull((o) => o.id == event.sourceId);
        sourceDuration = txt?.durationMs ?? 3000;
        break;
    }

    if (end < 0) end = start + sourceDuration;   // default = full source length

    final track = TimelineTrack(
      id: uuid.v4(),
      type: event.type,
      sourceId: event.sourceId,
      startMs: start,
      endMs: end,
      volume: 1.0,
    );

    emit(s.copyWith(timelineTracks: [...s.timelineTracks, track]));
  }

  Future<void> _onMoveTrack(MoveTrackEvent event, Emitter<VideoEditorState> emit) async {
    final s = _loadedState;
    final idx = s.timelineTracks.indexWhere((t) => t.id == event.trackId);
    if (idx == -1) return;

    final old = s.timelineTracks[idx];
    final delta = event.newStartMs - old.startMs;
    final newTrack = old.copyWith(startMs: event.newStartMs, endMs: old.endMs + delta);

    final newList = List<TimelineTrack>.from(s.timelineTracks)
      ..[idx] = newTrack;

    emit(s.copyWith(timelineTracks: newList));
  }

  Future<void> _onResizeTrack(ResizeTrackEvent event, Emitter<VideoEditorState> emit) async {
    final s = _loadedState;
    final idx = s.timelineTracks.indexWhere((t) => t.id == event.trackId);
    if (idx == -1) return;

    final old = s.timelineTracks[idx];
    final newTrack = old.copyWith(endMs: event.newEndMs);

    final newList = List<TimelineTrack>.from(s.timelineTracks)..[idx] = newTrack;
    emit(s.copyWith(timelineTracks: newList));
  }

  Future<void> _onRemoveTrack(RemoveTrackEvent event, Emitter<VideoEditorState> emit) async {
    final s = _loadedState;
    emit(s.copyWith(
        timelineTracks: s.timelineTracks.where((t) => t.id != event.trackId).toList()));
  }
}