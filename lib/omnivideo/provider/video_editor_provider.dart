import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:kwaic/nes_scr/model/timeline_item.dart';
import 'package:kwaic/omnivideo/model/video_track.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../nes_scr/screen/new.dart';
import '../../nes_scr/servuices/audio_manager.dart';
import '../model/audio_track.dart';
import '../model/text_track.dart';
import '../model/thumbnail_arg.dart';
import '../service/audio_waveform_service.dart';
import '../service/thumbnail_cache.dart';
import '../service/video_editor_service.dart';
import '../timeline_constants.dart';

enum EditorMode {
  idle,        // Only bottom nav
  toolBar,     // Context toolbar open
  toolSheet    // A tool bottom sheet open
}


class VideoEditorProvider with ChangeNotifier {
  VideoPlayerController? _videoController;
  List<VideoTrack> _videoTracks = [];
  List<AudioTrack> audioTracks = [];
  int _selectedTrackIndex = 0;
  Duration _currentPosition = Duration.zero;  // Track current position
  String _currentTool = '';
  bool _showContextToolbar = false;
  bool _showBottomSheet = false;
  double _rotation = 0;
  bool _flipHorizontal = false;
  bool _flipVertical = false;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;


  EditorMode _mode = EditorMode.idle;
  String? _activeTool;

  EditorMode get mode => _mode;
  String? get activeTool => _activeTool;

  // Getters
  VideoPlayerController? get videoController => _videoController;
  List<VideoTrack> get videoTracks => _videoTracks;
  int get selectedTrackIndex => _selectedTrackIndex;
  Duration get currentPosition => _currentPosition;  // Get current position
  String get currentTool => _currentTool;
  bool get showContextToolbar => _showContextToolbar;
  bool get showBottomSheet => _showBottomSheet;
  double get rotation => _rotation;
  bool get flipHorizontal => _flipHorizontal;
  bool get flipVertical => _flipVertical;
  bool freezeHeavyTasksDuringPlayback = true;
  bool _isSwitchingClip = false;
  bool isScrubbingTimeline = false;     // Current playing clip
  VideoPlayerController? _nextClipController;  // Preloaded next clip
  bool _userScrollingTimeline = false;


  final AudioManager audioManager = AudioManager();
  // ================= CAPCUT CAMERA =================
  double timelineCameraSeconds = 0.0;

  final Map<String, List<Uint8List>> _clipThumbnailCache = {};
  final ScrollController _timelineScrollController = ScrollController();

  // ================= SPEED =================
  double _previewSpeed = 1.0; // Live preview speed
  double _appliedSpeed = 1.0; // Final committed speed

  String _speedMode = 'normal'; // normal | curve

  double get previewSpeed => _previewSpeed;
  double get appliedSpeed => _appliedSpeed;
  String get speedMode => _speedMode;
  bool _isLoadingVideo = false;
  bool get isLoadingVideo => _isLoadingVideo;
  ScrollController get timelineScrollController => _timelineScrollController;
  final List<TextTrack> textTracks = [];
  TextTrack? selectedText;


  bool _isDraggingClip = false;

  bool get isDraggingClip => _isDraggingClip;

  set isDraggingClip(bool value) {
    if (_isDraggingClip == value) return;
    _isDraggingClip = value;
    notifyListeners();
  }

  bool _isTrimming = false;
  bool get isTrimming => _isTrimming;

  void startTrimPreview() {
    _isTrimming = true;
    pause();
  }

  void pause() {
    if (_videoController == null) return;

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  void endTrimPreview() {
    _isTrimming = false;
  }

  void previewTrimStart(Duration start) {
    _trimStart = snapToFrame(start);
    _videoController?.seekTo(_trimStart);
    notifyListeners();
  }

  void previewTrimEnd(Duration end) {
    _trimEnd = snapToFrame(end);
    notifyListeners();
  }

  Duration get globalPosition {
    if (_videoController == null) return Duration.zero;

    final clip = videoTracks[selectedTrackIndex];
    return clip.startTime + _videoController!.value.position;
  }


  void togglePlayPause() {
    if (_videoController == null) return;

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
      _isPlaying = false;
    } else {
      _videoController!.play();
      _isPlaying = true;
    }

    notifyListeners();
  }

  void seekTo(Duration time) {
    if (_videoController == null) return;
    _videoController!.seekTo(time);
  }


  void updateActiveClip(Duration globalTime) {
    final index = videoTracks.indexWhere(
          (t) => globalTime >= t.startTime && globalTime < t.endTime,
    );

    if (index == selectedTrackIndex) return;

    switchToClip(videoTracks[index], seekToGlobal: globalTime);
  }

  void _updatePosition() {
    if (_videoController == null) return;

    final pos = _videoController!.value.position;
    _currentPosition = pos;
    _currentTimeSeconds = pos.inMilliseconds / 1000.0;
    _isPlaying = _videoController!.value.isPlaying;

    notifyListeners();
  }

  Future<void> loadVideo(String path) async {
    final oldController = _videoController;

    final newController = VideoPlayerController.file(File(path));
    await newController.initialize();

    _videoController = newController;
    _attachVideoListener(newController);

    notifyListeners();

    if (oldController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController.dispose();
      });
    }

    _videoController!.addListener(_updatePosition);

    // In loadVideo(), after initialize():
    final thumbs = await generateClipThumbnails(
      videoPath: path,
      duration: _videoController!.value.duration,
    );

    final currentIndex = selectedTrackIndex;
    final track = videoTracks[currentIndex];
    final updatedTrack = track.copyWith(timelineThumbnails: thumbs);
    replaceTrack(currentIndex, updatedTrack);

    _isLoadingVideo = false;
    notifyListeners();

    if (oldController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await oldController.dispose();
      });
    }
  }


  Duration get totalTimelineDuration {
    return Duration(seconds: totalTimelineSeconds.toInt());
  }

  double get totalTimelineSeconds {
    double maxEnd = 0.0;

    // Video tracks
    for (final v in videoTracks) {
      final end = v.endTime.inMilliseconds / 1000.0;
      maxEnd = math.max(maxEnd, end);
    }

    // Audio tracks
    for (final a in audioTracks) {
      final end = a.start + a.duration;
      maxEnd = math.max(maxEnd, end);
    }

    // Text tracks
    for (final t in textTracks) {
      final end = (t.startTime + t.duration).inMilliseconds / 1000.0;
      maxEnd = math.max(maxEnd, end);
    }

    return maxEnd + 2; // padding
  }

  void openTool(String tool) {
    _currentTool = tool;
    _showBottomSheet = true;
    notifyListeners();
  }

  void closeTool() {
    _showBottomSheet = false;
    _currentTool = '';
    notifyListeners();
  }

  void panTimeline(double dx) {
    timelineCameraSeconds -= dx / pixelsPerSecond;
    final max = totalTimelineSeconds - 5; // some padding
    timelineCameraSeconds = timelineCameraSeconds.clamp(0.0, max > 0 ? max : 0.0);
    notifyListeners();
  }

  void setMode(EditorMode newMode) {
    _mode = newMode;
    notifyListeners();
  }

  void setActiveTool(String? tool) {
    _activeTool = tool;
    notifyListeners();
  }

  void setPreviewSpeed(double speed) {
    _previewSpeed = speed;
    _videoController?.setPlaybackSpeed(speed);
    notifyListeners();
  }

  void setSpeedMode(String mode) {
    _speedMode = mode;
    notifyListeners();
  }

  void commitSpeed() {
    _appliedSpeed = _previewSpeed;
    notifyListeners();
  }

  void moveAudio(AudioTrack track, double newStart) {
    track.start = newStart;
    notifyListeners();
  }

  void applySpeedToSelectedTrack() {
    final track = videoTracks[selectedTrackIndex];

    final newDuration = track.duration ~/ appliedSpeed.toInt();

    videoTracks[selectedTrackIndex] = track.copyWith(
      speed: appliedSpeed,
      endTime: track.startTime + newDuration,
    );

    videoController?.setPlaybackSpeed(appliedSpeed);

    notifyListeners();
  }

  void addVideo(File file, Duration start, Duration end) {
    final track = VideoTrack(
      id: const Uuid().v4(),
      path: file.path,
      startTime: start,
      endTime: end,
    );

    videoTracks.add(track);
    notifyListeners();

    generateThumbnailsForAllClips();
  }

  // 🔹 DRAG CLIP
  void moveClip(VideoTrack clip, Duration newStart) {
    final index = videoTracks.indexWhere((t) => t.id == clip.id);
    if (index == -1) return;

    final oldStart = clip.startTime;
    final delta = newStart - oldStart;

    // 1️⃣ Move the video clip
    final updatedClip = clip.copyWith(
      startTime: newStart,
      endTime: newStart + clip.duration,
    );

    videoTracks[index] = updatedClip;

    // 2️⃣ Move linked audio tracks
    for (final audio in audioTracks) {
      if (audio.linkedClipId == clip.id) {
        audio.start = newStart.inMilliseconds / 1000;
      }
    }

    // 3️⃣ Re-sort timeline
    videoTracks.sort((a, b) => a.startTime.compareTo(b.startTime));
    audioTracks.sort((a, b) => a.start.compareTo(b.start));

    notifyListeners();
  }

  // 🔹 ADD AUDIO
  void addAudioTrack(AudioTrack track) {
    audioTracks.add(track);
    notifyListeners();
  }

  double _previewRotation = 0;
  bool _previewFlipH = false;
  bool _previewFlipV = false;

// Add these public getters
  Rect get previewCropRect => _previewCropRect;
  double get previewCropZoom => _previewCropZoom;


  void openToolbar() {
    _mode = EditorMode.toolBar;
    _activeTool = null;
    notifyListeners();
  }

  void closeToolbar() {
    _mode = EditorMode.idle;
    _activeTool = null;
    notifyListeners();
  }

  Duration snapToFrame(Duration raw) {
    const fps = 30.0;
    final frameMs = (1000 / fps).round();
    final snapped = (raw.inMilliseconds / frameMs).round() * frameMs;
    return Duration(milliseconds: snapped);
  }

// Existing private variables
  Rect _previewCropRect = const Rect.fromLTWH(0, 0, 1, 1);
  double _previewCropZoom = 1.0;

  bool _isSoundOn = true;
  Uint8List? _selectedCover;

  bool get isSoundOn => _isSoundOn;
  Uint8List? get selectedCover => _selectedCover;

  // Master current time (in seconds, double for precision)
  double _currentTimeSeconds = 0.0;
  double get currentTimeSeconds => _currentTimeSeconds;

  set currentTimeSeconds(double seconds) {
    _currentTimeSeconds = seconds.clamp(0.0, totalDurationSeconds);
    if (_videoController != null) {
      final pos = Duration(seconds: _currentTimeSeconds.round());
      _videoController!.seekTo(pos);
    }
    notifyListeners();
  }

// Total duration of current clip (for bounds)
  double get totalDurationSeconds {
    return _videoController!.value.duration.inMilliseconds.toDouble() / 1000.0 ?? 10.0;
  }

  void selectClip(int i) async {
    if (i == selectedTrackIndex) return; // Avoid unnecessary reload

    selectedTrackIndex = i;

    final track = videoTracks[i];
    final videoPath = track.path;

    // 🔥 STEP 1: Immediately show the single thumbnail (from selection screen)
    // This ensures preview + timeline never go blank
    final Uint8List? firstThumbnail = track.thumbnail;

    // 🔥 STEP 2: Trigger loading state
    _isLoadingVideo = true;
    notifyListeners();

    // 🔥 STEP 3: Load full video in background
    await loadVideo(videoPath);

    // 🔥 STEP 4: Loading complete
    _isLoadingVideo = false;
    notifyListeners();
  }

  // Setters with notify
  set previewCropRect(Rect rect) {
    _previewCropRect = rect;
    notifyListeners();
  }

  set previewCropZoom(double zoom) {
    _previewCropZoom = zoom;
    notifyListeners();
  }

// Reset for new session
  void resetCrop() {
    _cropRect = const Rect.fromLTWH(0, 0, 1, 1);
    _cropZoom = 1.0;
    _previewCropRect = _cropRect;
    _previewCropZoom = _cropZoom;
    notifyListeners();
  }


// Optional: reset on tool open
  void resetPreviewCrop() {
    _previewCropRect = const Rect.fromLTWH(0, 0, 1, 1);
    _previewCropZoom = 1.0;
    notifyListeners();
  }

  // Commit preview to permanent
  void commitCrop() {
    _cropRect = _previewCropRect;
    _cropZoom = _previewCropZoom;
  }

  // When opening rotate/flip sheet, reset preview
  void resetPreviewTransforms() {
    _previewRotation = 0;
    _previewFlipH = false;
    _previewFlipV = false;
    notifyListeners();
  }
  // Setters
  set videoController(VideoPlayerController? controller) {
    _videoController?.removeListener(_updatePosition);
    _videoController = controller;
    _videoController?.addListener(_updatePosition);
    notifyListeners();
  }

  void showToolbar() {
    _showContextToolbar = true;
    notifyListeners();
  }

  void hideToolbar() {
    _showContextToolbar = false;
    _showBottomSheet = false;
    _currentTool = '';
    notifyListeners();
  }

  void toggleToolbar() {
    _showContextToolbar = !_showContextToolbar;
    notifyListeners();
  }

  // Add this method to handle tool selection
  void selectTool(String tool) {
    _currentTool = tool;
    _showBottomSheet = true;
    notifyListeners();
  }


  void replaceTrack(int index, VideoTrack newTrack) {
    _videoTracks[index] = newTrack;
    notifyListeners();
  }

  void syncPlaybackSpeed() {
    if (videoController == null) return;
    videoController!.setPlaybackSpeed(appliedSpeed);
  }

  void selectCover() {
    final pos = currentPosition;
    for (final track in videoTracks) {
      if (pos >= track.startTime && pos < track.endTime) {
        _selectedCover = track.thumbnail;
        notifyListeners();
        return;
      }
    }
    if (videoTracks.isNotEmpty) {
      _selectedCover = videoTracks.first.thumbnail;
      notifyListeners();
    }
  }

  set videoTracks(List<VideoTrack> tracks) {
    _videoTracks = tracks;
    notifyListeners();
  }

  set selectedTrackIndex(int index) {
    _selectedTrackIndex = index;
    notifyListeners();
  }

  set isPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  set isSoundOn(bool soundOn) {
    _isSoundOn = soundOn;
    notifyListeners();
  }

  set selectedCover(Uint8List? cover) {
    _selectedCover = cover;
    notifyListeners();
  }

  set currentTool(String tool) {
    _currentTool = tool;
    notifyListeners();
  }

  set showContextToolbar(bool show) {
    _showContextToolbar = show;
    notifyListeners();
  }

  set showBottomSheet(bool show) {
    _showBottomSheet = show;
    notifyListeners();
  }

  set rotation(double angle) {
    _rotation = angle;
    notifyListeners();
  }

  set flipHorizontal(bool flip) {
    _flipHorizontal = flip;
    notifyListeners();
  }

  set flipVertical(bool flip) {
    _flipVertical = flip;
    notifyListeners();
  }


  void _updateVideoPosition() {
    if (_videoController == null) return;

    if (_videoController!.value.isPlaying != _isPlaying) {
      _isPlaying = _videoController!.value.isPlaying;
      notifyListeners();
    }

    // Notify listeners on position change
    notifyListeners();
  }

  void toggleSound() {
    _isSoundOn = !_isSoundOn;
    notifyListeners();
  }

  // Crop / Fill state
  Rect _cropRect = const Rect.fromLTWH(0, 0, 1, 1); // Normalized 0-1
  double _cropZoom = 1.0; // Zoom level for fill

  Rect get cropRect => _cropRect;
  double get cropZoom => _cropZoom;

  set cropRect(Rect rect) {
    _cropRect = rect;
    notifyListeners();
  }

  set cropZoom(double zoom) {
    _cropZoom = zoom;
    notifyListeners();
  }


  void startCropPreview() {
    _previewCropRect = _cropRect;
    _previewCropZoom = _cropZoom;
  }

  void cancelCropPreview() {
    _previewCropRect = _cropRect;
    _previewCropZoom = _cropZoom;
    notifyListeners();
  }

  @override
  void dispose() {
    _videoController?.removeListener(_updateVideoPosition);
    _videoController?.dispose();
    _pendingThumbnailJobs.clear();
    for (final track in audioTracks) {
      track.player.dispose();
    }

    super.dispose();
  }

  set currentTime(Duration time) {
    _currentPosition = time;
    _currentTimeSeconds = time.inMilliseconds / 1000.0;
    _videoController?.seekTo(time);
    notifyListeners();
  }

  Duration _trimStart = Duration.zero;
  Duration _trimEnd = const Duration(seconds: 10);

  set trimStart(Duration start) {
    _trimStart = start;
    notifyListeners();
  }

  set trimEnd(Duration end) {
    _trimEnd = end;
    notifyListeners();
  }


  Duration get trimStart => _trimStart;
  Duration get trimEnd => _trimEnd;


  // Trim video using FFmpeg
  Future<bool> trimVideo({
    required String inputPath,
    required String outputPath,
    required Duration start,
    required Duration end,
  })
  async {
    final command =
        '-i "$inputPath" -ss ${start.inSeconds} -to ${end.inSeconds} -c copy "$outputPath"';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    return returnCode != null && ReturnCode.isSuccess(returnCode);
  }

  // Rotate video using FFmpeg
  Future<bool> rotateVideo({
    required String inputPath,
    required String outputPath,
    required double angle,
  })
  async {
    final command =
        '-i "$inputPath" -vf "rotate=${angle * 3.14159 / 180}:c=black@0" "$outputPath"';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    return returnCode != null && ReturnCode.isSuccess(returnCode);
  }

  // Flip video using FFmpeg
  Future<bool> flipVideo({
    required String inputPath,
    required String outputPath,
    required bool flipHorizontal,
  })
  async {
    final command =
        '-i "$inputPath" -vf "${flipHorizontal ? "hflip" : "vflip"}" "$outputPath"';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    return returnCode != null && ReturnCode.isSuccess(returnCode);
  }

  // Apply trim
  Future<void> applyTrim() async {
    if (_videoTracks.isEmpty) return;

    final track = _videoTracks[_selectedTrackIndex];
    final outputPath = '${track.path}_trimmed.mp4';

    // First use easy_video_editor to get the exact trim points
    // Then apply with FFmpeg for final export
    final success = await VideoEditorService.trimVideo(
      inputPath: track.path,
      outputPath: outputPath,
      start: _trimStart,
      end: _trimEnd,
    );

    if (success) {
      // Update the track with new path and duration
      _videoTracks[_selectedTrackIndex] = VideoTrack(
        id: track.id,
        path: outputPath,
        startTime: Duration.zero,
        endTime: _trimEnd - _trimStart,
        thumbnail: track.thumbnail,
      );

      // Reload the video
      await loadVideo(outputPath);
    }
  }
  // Apply rotation
  Future<void> applyRotation(double angle) async {
    if (_videoTracks.isEmpty) return;
    final track = _videoTracks[_selectedTrackIndex];
    final outputPath = '${track.path}_rotated.mp4';
    final success = await rotateVideo(
      inputPath: track.path,
      outputPath: outputPath,
      angle: angle,
    );
    if (success) {
      await _loadVideo(outputPath);
      _rotation = (_rotation + angle) % 360;
      notifyListeners();
    }
  }

  // Apply flip
  Future<void> applyFlip(bool horizontal) async {
    if (_videoTracks.isEmpty) return;
    final track = _videoTracks[_selectedTrackIndex];
    final outputPath = '${track.path}_flipped.mp4';
    final success = await flipVideo(
      inputPath: track.path,
      outputPath: outputPath,
      flipHorizontal: horizontal,
    );
    if (success) {
      await _loadVideo(outputPath);
      if (horizontal) {
        _flipHorizontal = !_flipHorizontal;
      } else {
        _flipVertical = !_flipVertical;
      }
      notifyListeners();
    }
  }



  Future<List<Uint8List>> generateClipThumbnails({
    required String videoPath,
    required Duration duration,
  }) async {

    if (freezeHeavyTasksDuringPlayback && _isPlaying) {
      return <Uint8List>[];
    }

    if (ThumbnailCache.has(videoPath)) {
      return ThumbnailCache.get(videoPath)!;
    }

    final int thumbnailsPerSecond = 3;
    final int targetCount =
    (duration.inSeconds * thumbnailsPerSecond).clamp(12, 80);

    final double intervalSeconds = duration.inSeconds / targetCount;
    final List<Uint8List> thumbs = [];

    for (int i = 0; i < targetCount; i++) {
      if (_isPlaying) break;

      final double timeSeconds = i * intervalSeconds;

      final data = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: (timeSeconds * 1000).toInt(),
        quality: 65,
        maxWidth: 120,
      );

      if (data != null) thumbs.add(data);

      if (i % 2 == 0) {
        await Future.delayed(const Duration(milliseconds: 16));
      }
    }

    ThumbnailCache.put(videoPath, thumbs);
    return thumbs;
  }

  // Load video into player
  Future<void> _loadVideo(String path) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(path));
    await _videoController!.initialize();
    _trimEnd = _videoController!.value.duration;
    notifyListeners();
  }

  Future<void> applyCrop() async {
    if (_videoTracks.isEmpty || _videoController == null) return;

    final track = _videoTracks[_selectedTrackIndex];
    final outputPath = '${track.path}_cropped_${DateTime.now().millisecondsSinceEpoch}.mp4';

    // 1. Get actual video dimensions
    final double vWidth = _videoController!.value.size.width;
    final double vHeight = _videoController!.value.size.height;

    // 2. Calculate raw pixel values from normalized coordinates
    // We use the 'preview' values because that's what the user adjusted
    double rawW = (vWidth * _previewCropRect.width) / _previewCropZoom;
    double rawH = (vHeight * _previewCropRect.height) / _previewCropZoom;
    double rawX = _previewCropRect.left * vWidth;
    double rawY = _previewCropRect.top * vHeight;

    // 3. SANITIZE: Force even numbers (Required by H.264 and most codecs)
    int finalW = (rawW.round() ~/ 2) * 2;
    int finalH = (rawH.round() ~/ 2) * 2;
    int finalX = (rawX.round() ~/ 2) * 2;
    int finalY = (rawY.round() ~/ 2) * 2;

    // 4. VALIDATE: Ensure we don't exceed boundaries
    // If X + Width > Video Width, we shrink the width
    if (finalX + finalW > vWidth) {
      finalW = (vWidth.toInt() - finalX);
      finalW = (finalW ~/ 2) * 2; // Re-force even
    }
    if (finalY + finalH > vHeight) {
      finalH = (vHeight.toInt() - finalY);
      finalH = (finalH ~/ 2) * 2; // Re-force even
    }

    // Final fallback: Ensure dimensions are at least 2 pixels
    if (finalW < 2) finalW = 2;
    if (finalH < 2) finalH = 2;

    debugPrint('FFmpeg Crop: ${finalW}x${finalH} at $finalX,$finalY');

    // 5. Execute FFmpeg command
    // -vf "crop=w:h:x:y"
    // -c:a copy: keeps the original audio without re-encoding (faster)
    final command = '-i "${track.path}" -vf "crop=$finalW:$finalH:$finalX:$finalY" -c:a copy "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      final updatedTrack = track.copyWith(path: outputPath);
      replaceTrack(_selectedTrackIndex, updatedTrack);
      await loadVideo(outputPath);
      commitCrop(); // Moves preview values to actual crop values
    } else {
      final logs = await session.getLogs();
      debugPrint('FFmpeg Error: ${logs.last.getMessage()}');
    }
  }

  final List<Future<void>> _pendingThumbnailJobs = [];

  Future<void> generateThumbnailsForAllClips() async {
    for (final track in videoTracks) {
      if (track.timelineThumbnails.isNotEmpty) continue;

      // Wait until NOT playing
      while (_isPlaying) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final thumbs = await generateClipThumbnails(
        videoPath: track.path,
        duration: track.duration,
      );

      final index =
      videoTracks.indexWhere((t) => t.id == track.id);

      if (index != -1) {
        _videoTracks[index] =
            _videoTracks[index].copyWith(
              timelineThumbnails: thumbs,
            );
        notifyListeners();
      }
    }
  }


  void setCurrentTime(Duration time) {
    if (_videoController == null) return;
    _videoController!.seekTo(time);
    _currentPosition = time;
    _currentTimeSeconds = time.inMilliseconds / 1000.0;
    notifyListeners();
  }

  void cancelSpeedPreview() {
    _previewSpeed = _appliedSpeed;
    _videoController?.setPlaybackSpeed(_appliedSpeed);
    notifyListeners();
  }

  Future<void> addAudio({
    required File file,
    required Duration start,
    required Duration duration,
  })
  async {
    try {
      final tmp = await getTemporaryDirectory();

      final double startSeconds = start.inMilliseconds / 1000.0;
      final double durationSeconds = duration.inMilliseconds / 1000.0;

      final waveFile = File('${tmp.path}/wave_${DateTime.now().millisecondsSinceEpoch}.wave');

      Waveform? waveform;

      final stream = JustWaveform.extract(
        audioInFile: file,
        waveOutFile: waveFile,
        // Optional: adjust zoom for better waveform detail
        // zoom: const WaveformZoom.pixelsPerSecond(100),
      );

      await for (final progress in stream) {
        if (progress.waveform != null) {
          waveform = progress.waveform!;
          // You can break here if you want the final result only
          // break;
        }
      }

      // Clean up the temporary .wave file (optional, saves storage)
      if (await waveFile.exists()) {
        await waveFile.delete();
      }

      final player = AudioPlayer();
      await player.setFilePath(file.path);

      final newTrack = AudioTrack(
        id: const Uuid().v4(),
        path: file.path,
        duration: durationSeconds,
        start: startSeconds,
        waveform: waveform,
        player: player,
      );

      audioTracks.add(newTrack);

      if (waveform != null) {
        debugPrint('✅ Audio added with waveform: ${waveform.length} pixels, '
            '${waveform.samplesPerPixel} samples/pixel, '
            'duration: ${waveform.duration.inSeconds}s');
      } else {
        debugPrint('⚠️ Audio added WITHOUT waveform (extraction failed)');
      }

      notifyListeners();
    } catch (e, stack) {
      debugPrint('❌ Error adding audio: $e');
      debugPrint(stack.toString());
    }
  }

  // Curve editor control points (0–1 normalized)
  List<Offset> curvePoints = [
    const Offset(0.0, 1.0),
    const Offset(0.33, 0.8),
    const Offset(0.66, 0.4),
    const Offset(1.0, 1.0),
  ];

  void updateCurvePoint(int index, Offset value) {
    curvePoints[index] = Offset(
      value.dx.clamp(0.0, 1.0),
      value.dy.clamp(0.0, 1.0),
    );

    final track = videoTracks[selectedTrackIndex];
    final curve = generateSpeedCurve(track);

    final newDuration = computeCurveAdjustedDuration(
      track.copyWith(speedCurve: curve),
    );

    videoTracks[selectedTrackIndex] = track.copyWith(
      speedCurve: curve,
      endTime: track.startTime + newDuration,
    );
    previewCurveSpeed();

    notifyListeners(); // 🔥 timeline animates automatically
  }

  List<SpeedSegment> generateSpeedCurve(VideoTrack track) {
    final segments = <SpeedSegment>[];
    final totalMs = track.duration.inMilliseconds;
    for (int i = 0; i < curvePoints.length - 1; i++) {
      final p1 = curvePoints[i];
      final p2 = curvePoints[i + 1];
      final startMs = (p1.dx * totalMs).toInt();
      final endMs = (p2.dx * totalMs).toInt();
      // Invert Y: top = fast, bottom = slow
      // Clamp speed between 0.1x and 10x
      final speed = (0.1 + (1.0 - p1.dy) * 9.9).clamp(0.1, 10.0);
      segments.add(
        SpeedSegment(
          start: Duration(milliseconds: startMs),
          end: Duration(milliseconds: endMs),
          speed: speed,
        ),
      );
    }
    return segments;
  }

  void applyCurveSpeedToSelectedTrack() {
    final track = videoTracks[selectedTrackIndex];

    final curve = generateSpeedCurve(track);

    videoTracks[selectedTrackIndex] = track.copyWith(
      speedCurve: curve,
    );

    notifyListeners();
  }

  Duration computeCurveAdjustedDuration(VideoTrack track) {
    if (track.speedCurve == null || track.speedCurve!.isEmpty) {
      return track.duration ~/ track.speed.toInt();
    }

    Duration total = Duration.zero;
    for (final segment in track.speedCurve!) {
      final original = segment.end - segment.start;
      // Clamp speed to avoid division by zero
      final safeSpeed = segment.speed.clamp(0.1, 100.0);
      total += Duration(milliseconds: (original.inMilliseconds / safeSpeed).round());
    }
    return total;
  }

  void previewCurveSpeed() {
    if (videoController == null) return;
    final track = videoTracks[selectedTrackIndex];

    if (track.speedCurve == null) return;

    videoController!.addListener(() {
      final pos = videoController!.value.position;

      for (final seg in track.speedCurve!) {
        if (pos >= seg.start && pos <= seg.end) {
          videoController!.setPlaybackSpeed(seg.speed);
          break;
        }
      }
    });
  }

  void applyCurvePreset(String preset) {
    switch (preset) {
      case 'Montage':
        curvePoints = const [
          Offset(0.0, 1.0),
          Offset(0.3, 0.2),
          Offset(0.6, 0.8),
          Offset(1.0, 1.0),
        ];
        break;

      case 'Bullet':
        curvePoints = const [
          Offset(0.0, 1.0),
          Offset(0.45, 0.9),
          Offset(0.5, 0.1),
          Offset(0.55, 0.9),
          Offset(1.0, 1.0),
        ];
        break;
    }

    updateCurvePoint(0, curvePoints.first);
  }

  AudioTrack? selectedAudioTrack;

  void selectAudio(AudioTrack track) {
    selectedAudioTrack = track;
    notifyListeners();
  }

  void clearAudioSelection() {
    selectedAudioTrack = null;
    notifyListeners();
  }


  double timeToX(Duration t, double screenWidth) {
    return ((t.inMilliseconds / 1000) - timelineCameraSeconds) *
        pixelsPerSecond + screenWidth / 2;
  }

  Duration xToTime(double x, double screenWidth) {
    final seconds =
        ((x - screenWidth / 2) / pixelsPerSecond) + timelineCameraSeconds;
    return Duration(milliseconds: (seconds * 1000).round());
  }


  double get timelineWorldWidth {
    if (videoTracks.isEmpty && audioTracks.isEmpty) return 2000;

    double maxEnd = 0.0;
    for (final v in videoTracks) {
      maxEnd = math.max(maxEnd, v.endTime.inMilliseconds / 1000.0);
    }
    for (final a in audioTracks) {
      maxEnd = math.max(maxEnd, a.start + a.duration);
    }

    // Ensure minimum width and generous right padding
    return math.max((maxEnd * pixelsPerSecond) + 3000, 4000);
  }

  Future<void> loadTimelineThumbnails(VideoTrack track) async {
    if (_clipThumbnailCache.containsKey(track.id)) {
      final index = videoTracks.indexWhere((t) => t.id == track.id);
      if (index != -1) {
        videoTracks[index] =
            videoTracks[index].copyWith(timelineThumbnails: _clipThumbnailCache[track.id]!);
        notifyListeners();
      }
      return;
    }

    final thumbs = await generateClipThumbnails(
      videoPath: track.path,
      duration: track.duration,
    );

    _clipThumbnailCache[track.id] = thumbs;

    final index = videoTracks.indexWhere((t) => t.id == track.id);
    if (index != -1) {
      videoTracks[index] = videoTracks[index].copyWith(timelineThumbnails: thumbs);
      notifyListeners();
    }
  }

  void setTrimRangeSilently(Duration start, Duration end) {
    _trimStart = start;
    _trimEnd = end;
  }

  String? selectedVideoTrackId;

  void selectVideoTrack(String? trackId) {
    selectedVideoTrackId = trackId;
    selectedTrackIndex = videoTracks.indexWhere((t) => t.id == trackId);
    notifyListeners();
  }

  void clearSelection() {
    selectedVideoTrackId = null;
    notifyListeners();
  }

  void addTextTrack(TextTrack track) {
    textTracks.add(track);
    selectedText = track;
    notifyListeners();
  }

  void updateTextPosition(TextTrack track, Offset normalized) {
    final index = textTracks.indexWhere((t) => t.id == track.id);
    if (index == -1) return;

    textTracks[index] = track.copyWith(position: normalized);
    notifyListeners();
  }

  TextTrack? selectedTextTrack;
  
  void selectTextTrack(String? id) {
    selectedTextTrack = textTracks.firstWhereOrNull((t) => t.id == id);
    notifyListeners();
  }

  void updateTextTrack(TextTrack updated) {
    final index = textTracks.indexWhere((t) => t.id == updated.id);
    if (index != -1) textTracks[index] = updated;
    notifyListeners();
  }

  void deleteTextTrack(String id) {
    textTracks.removeWhere((t) => t.id == id);
    if (selectedTextTrack?.id == id) selectedTextTrack = null;
    notifyListeners();
  }

  Future<String?> exportProject() async {
    if (videoTracks.isEmpty) return null;

    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/export_${DateTime.now().millisecondsSinceEpoch}.mp4';

    // Build complex FFmpeg command
    final inputs = <String>[];
    final filters = <String>[];

    // Add video inputs
    for (int i = 0; i < videoTracks.length; i++) {
      final track = videoTracks[i];
      inputs.add('-i "${track.path}"');

      String filter = '[${i}:v]';

      // Trim
      if (track.trimStart > Duration.zero || track.trimEnd < track.duration) {
        filter += 'trim=start=${track.trimStart.inMilliseconds / 1000}:end=${track.trimEnd.inMilliseconds / 1000},setpts=PTS-STARTPTS';
      }

      // Speed (simple uniform speed)
      if (track.speed != 1.0) {
        filter += ',setpts=${1 / track.speed}*PTS';
      }

      // Crop + Zoom
      if (track.cropRect != const Rect.fromLTWH(0, 0, 1, 1) || track.cropZoom != 1.0) {
        final w = 'iw/${track.cropZoom}';
        final h = 'ih/${track.cropZoom}';
        final x = 'iw*${track.cropRect.left}';
        final y = 'ih*${track.cropRect.top}';
        filter += ",crop=$w:$h:$x:$y";
      }

      // Rotate + Flip
      String transform = '';
      if (track.flipHorizontal) transform += 'hflip,';
      if (track.flipVertical) transform += 'vflip,';
      if (track.rotation != 0) transform += 'rotate=${track.rotation * math.pi / 180},';
      if (transform.isNotEmpty) {
        filter += ',${transform.substring(0, transform.length - 1)}';
      }

      filters.add('$filter[v$i]');
    }

    // Concatenate video
    final videoConcat = filters.map((f) => '[$f]').join();
    final videoFilter = '$videoConcat concat=n=${videoTracks.length}:v=1:a=0 [vout]';

// Audio inputs and mixing
    String audioFilter = '';
    if (audioTracks.isNotEmpty) {
      for (int i = 0; i < audioTracks.length; i++) {
        inputs.add('-i "${audioTracks[i].path}"');
      }

      final audioIndices = List.generate(audioTracks.length, (i) => videoTracks.length + i);
      final audioMix = audioIndices.map((i) => '[$i:a]').join();
      audioFilter = '$audioMix amix=inputs=${audioTracks.length}[aout]';
    }

// Final command
    final command = [
      ...inputs,
      '-filter_complex',
      '"$videoFilter${audioFilter.isEmpty ? '' : ';$audioFilter'}"',
      '-map "[vout]"',
      if (audioFilter.isNotEmpty) '-map "[aout]"',
      '-c:v libx264 -preset veryfast -crf 23',
      '-c:a aac -b:a 128k',
      outputPath,
    ].join(' ');


    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    } else {
      debugPrint('Export failed: ${await session.getLogsAsString()}');
      return null;
    }
  }

  void _attachVideoListener(VideoPlayerController controller) {
    controller.removeListener(_updateVideoPosition);

    controller.addListener(() {
      if (!controller.value.isInitialized) return;

      // 🔒 TRIM LOOP GUARD (CRITICAL)
      if (_isTrimming && controller.value.isPlaying) {
        final pos = controller.value.position;
        if (pos >= _trimEnd) {
          controller.seekTo(_trimStart);
          return;
        }
      }

      final track = videoTracks[selectedTrackIndex];
      final localPos = controller.value.position;
      final localDuration = controller.value.duration;

      _currentPosition = track.startTime + localPos;
      _syncAudioTracks(_currentPosition);

      _currentTimeSeconds = _currentPosition.inMilliseconds / 1000.0;

      _isPlaying = controller.value.isPlaying;

      if (!_isSwitchingClip &&
          localPos >= localDuration - const Duration(milliseconds: 16)) {
        _handleClipEnd();
      }

      if (_isPlaying &&
          !isDraggingClip &&
          !isScrubbingTimeline &&
          timelineScrollController.hasClients) {
        final viewportCenter =
            timelineScrollController.position.viewportDimension / 2;

        final offset =
            (_currentPosition.inMilliseconds / 1000.0) *
                pixelsPerSecond -
                viewportCenter;

        timelineScrollController.jumpTo(
          offset.clamp(
            0.0,
            timelineScrollController.position.maxScrollExtent,
          ),
        );
      }

      notifyListeners();
    });
  }

  Future<void> _handleClipEnd() async {
    if (_isSwitchingClip) return;

    final nextIndex = selectedTrackIndex + 1;

    if (nextIndex >= videoTracks.length) {
      // End of timeline
      _isPlaying = false;
      notifyListeners();
      return;
    }

    _isSwitchingClip = true;

    try {
      selectedTrackIndex = nextIndex;

      await switchToClip(
        videoTracks[nextIndex],
        seekToGlobal: videoTracks[nextIndex].startTime,
      );
    } finally {
      _isSwitchingClip = false;
    }
  }

  // =================== SWITCH CLIPS ===================
  Future<void> switchToClip(VideoTrack track, {Duration? seekToGlobal}) async {
    if (_videoController != null) {
      // Pause and remove listener before disposing
      _videoController!.pause();
      _videoController!.removeListener(_updatePosition);

      final old = _videoController;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        old?.dispose();
      });

    }

    // Create new controller
    final controller = VideoPlayerController.file(File(track.path));
    _videoController = controller;

    _isLoadingVideo = true;
    notifyListeners();

    try {
      await controller.initialize();

      // Attach listener
      _attachVideoListener(controller);

      // Seek to proper position
      if (seekToGlobal != null) {
        final clipPosition = seekToGlobal - track.startTime;
        if (clipPosition >= Duration.zero && clipPosition <= track.duration) {
          controller.seekTo(clipPosition);
        }
      }

      // Resume playback automatically if playing
      if (_isPlaying) {
        await controller.play();
      }
    } catch (e, st) {
      debugPrint('❌ Error switching clip: $e');
      debugPrint(st.toString());
    } finally {
      _isLoadingVideo = false;
      notifyListeners();
    }
  }


  Future<void> _switchToClip(VideoTrack track) async {
    final oldController = _videoController;

    // Create and initialize the new one
    _videoController = VideoPlayerController.file(File(track.path));
    await _videoController!.initialize();
    _videoController!.setVolume(isSoundOn ? 1.0 : 0.0);

    // Notify first – UI now uses the new controller
    notifyListeners();

    // Dispose old one safely after the frame/build cycle
    if (oldController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await oldController.dispose();
      });
      // Or simpler short delay:
      // Future.delayed(const Duration(milliseconds: 100), () => oldController.dispose());
    }
  }

  /// Add multiple videos sequentially to the timeline
  Future<void> addMultipleVideosSequentially(List<Map<String, dynamic>> videosWithThumbs) async {
    _videoTracks.clear();
    _selectedTrackIndex = 0;

    Duration currentStart = Duration.zero;

    for (final videoData in videosWithThumbs) {
      final XFile xfile = videoData['file'];
      final Uint8List? thumb = videoData['thumbnail'];

      // Initialize video controller temporarily to get duration
      final tempController = VideoPlayerController.file(File(xfile.path));
      await tempController.initialize();
      final duration = tempController.value.duration;
      await tempController.dispose();

      final track = VideoTrack(
        id: const Uuid().v4(),
        path: xfile.path,
        startTime: currentStart,
        endTime: currentStart + duration,
        thumbnail: thumb,
        timelineThumbnails: [], // Will be generated later
      );

      _videoTracks.add(track);
      currentStart += duration;
    }

    // Generate thumbnails for all clips in background
    generateThumbnailsForAllClips();

    // Load the FIRST clip into preview
    if (_videoTracks.isNotEmpty) {
      await _switchToClip(_videoTracks.first);
      _selectedTrackIndex = 0;
      selectedVideoTrackId = _videoTracks.first.id;
    }

    notifyListeners();
  }


  void clampTrimToClip(VideoTrack track) {
    if (_trimStart < Duration.zero) {
      _trimStart = Duration.zero;
    }
    if (_trimEnd > track.duration) {
      _trimEnd = track.duration;
    }
    if (_trimEnd <= _trimStart) {
      _trimEnd = _trimStart + const Duration(milliseconds: 33);
    }
  }

  void _syncAudioTracks(Duration timelinePosition) {
    for (final track in audioTracks) {
      final audioStart = Duration(
        milliseconds: (track.start * 1000).round(),
      );
      final audioEnd = audioStart +
          Duration(milliseconds: (track.duration * 1000).round());

      final isInside =
          timelinePosition >= audioStart &&
              timelinePosition < audioEnd;

      if (!isInside) {
        // 🔇 Ensure silence outside range
        if (track.player.playing) {
          track.player.pause();
        }
        continue;
      }

      // 🎯 Compute local audio offset
      final localAudioPos = timelinePosition - audioStart;

      // 🔄 Seek if drifted (important)
      final current = track.player.position;
      if ((current - localAudioPos).abs() >
          const Duration(milliseconds: 40)) {
        track.player.seek(localAudioPos);
      }

      // ▶️ Play only if timeline is playing
      if (_isPlaying && !track.player.playing) {
        track.player.play();
      }

      // ⏸ Pause if timeline paused
      if (!_isPlaying && track.player.playing) {
        track.player.pause();
      }
    }
  }

}