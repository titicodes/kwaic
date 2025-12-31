import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;  // Track current position
  String _currentTool = '';
  bool _showContextToolbar = false;
  bool _showBottomSheet = false;
  double _rotation = 0;
  bool _flipHorizontal = false;
  bool _flipVertical = false;



  EditorMode _mode = EditorMode.idle;
  String? _activeTool;

  EditorMode get mode => _mode;
  String? get activeTool => _activeTool;

  // Getters
  VideoPlayerController? get videoController => _videoController;
  List<VideoTrack> get videoTracks => _videoTracks;
  int get selectedTrackIndex => _selectedTrackIndex;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;  // Get current position
  String get currentTool => _currentTool;
  bool get showContextToolbar => _showContextToolbar;
  bool get showBottomSheet => _showBottomSheet;
  double get rotation => _rotation;
  bool get flipHorizontal => _flipHorizontal;
  bool get flipVertical => _flipVertical;

  final AudioManager audioManager = AudioManager();
  // ================= CAPCUT CAMERA =================
  double timelineCameraSeconds = 0.0;

  final Map<String, List<Uint8List>> _clipThumbnailCache = {};


  // ================= SPEED =================
  double _previewSpeed = 1.0; // Live preview speed
  double _appliedSpeed = 1.0; // Final committed speed

  String _speedMode = 'normal'; // normal | curve

  double get previewSpeed => _previewSpeed;
  double get appliedSpeed => _appliedSpeed;
  String get speedMode => _speedMode;
  bool _isLoadingVideo = false;
  bool get isLoadingVideo => _isLoadingVideo;


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

// Make sure this exists and updates properly when scrolling
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

    generateThumbnailsForAllClips(); // 🚀 parallel background loading
  }

  void seekTo(Duration position) {
    _currentPosition = position;
    _videoController?.seekTo(position);
    notifyListeners();
  }
  // 🔹 DRAG CLIP
  void moveClip(VideoTrack track, Duration newStart) {
    final index = _videoTracks.indexWhere((t) => t.id == track.id);
    if (index == -1) return;

    final updated = track.copyWith(
      startTime: newStart,
      endTime: newStart + track.duration,
    );

    _videoTracks[index] = updated;
    notifyListeners();
  }

  // 🔹 ADD AUDIO
  void addAudioTrack(AudioTrack track) {
    audioTracks.add(track);
    notifyListeners();
  }

  // 🔹 TOTAL TIMELINE
  double get totalTimelineSeconds {
    double maxEnd = 0;
    for (final v in videoTracks) {
      maxEnd = maxEnd < v.endTime.inSeconds
          ? v.endTime.inSeconds.toDouble()
          : maxEnd;
    }
    return maxEnd + 2;
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

  void togglePlayPause() {
    if (_videoController == null) return;
    if (_isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  Timer? _playbackTimer;

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

  Future<void> loadVideo(String path) async {

    // Then, start loading the full video
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(path));
    await _videoController!.initialize();
    _videoController!.addListener(_updatePosition);

    // Generate thumbnails only if they are not cached
    final duration = _videoController!.value.duration;
    final thumbs = await generateClipThumbnails(videoPath: path, duration: duration);


    // Update the current track with new thumbnails
    final currentIndex = selectedTrackIndex;
    final track = videoTracks[currentIndex];
    final updatedTrack = track.copyWith(timelineThumbnails: thumbs);
    replaceTrack(currentIndex, updatedTrack);

    _currentPosition = Duration.zero;
    _currentTimeSeconds = 0.0;
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

  void _updatePosition() {
    if (_videoController == null) return;
    final pos = _videoController!.value.position;
    _currentTimeSeconds = pos.inSeconds.toDouble();
    _currentPosition = pos;
    _isPlaying = _videoController!.value.isPlaying;
    notifyListeners();
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

  void selectCover() {
    if (_videoTracks.isNotEmpty && _selectedTrackIndex < _videoTracks.length) {
      _selectedCover = _videoTracks[_selectedTrackIndex].thumbnail;
      notifyListeners();
    }
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
    _playbackTimer?.cancel();
    super.dispose();
  }

  set currentTime(Duration time) {
    currentTime = time;
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
  })
  async {
    if (ThumbnailCache.has(videoPath)) {
      return ThumbnailCache.get(videoPath);
    }

    final int count = math.min(30, duration.inSeconds + 1); // adjust as needed
    final tempDir = (await getTemporaryDirectory()).path;
    final pattern = '$tempDir/thumb_%03d.jpg'; // thumb_001.jpg, etc.

    // Single FFmpeg command: extract thumbnails at ~1 per second
    final command = '-i "$videoPath" -vf fps=1/$count -q:v 2 "$pattern"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      final List<Uint8List> thumbs = [];
      for (int i = 1; i <= count; i++) {
        final filePath = '$tempDir/thumb_${i.toString().padLeft(3, '0')}.jpg';
        final file = File(filePath);
        if (file.existsSync()) {
          thumbs.add(await file.readAsBytes());
          await file.delete(); // clean up
        }
      }
      ThumbnailCache.put(videoPath, thumbs);
      return thumbs;
    } else {
      // Fallback to old method or throw
      debugPrint('FFmpeg thumbnail failed');
      return await compute(generateThumbnailsTask, ThumbnailArgs(videoPath, count));
    }
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

  void generateThumbnailsForAllClips() async {
    _pendingThumbnailJobs.clear();
    for (int i = 0; i < videoTracks.length; i++) {
      final track = videoTracks[i];
      if (track.timelineThumbnails.isNotEmpty) continue;

      final job = generateClipThumbnails(
        videoPath: track.path,
        duration: track.duration,
      ).then((thumbs) {
        final updated = track.copyWith(timelineThumbnails: thumbs);
        replaceTrack(i, updated);
      });
      _pendingThumbnailJobs.add(job);
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

      final newTrack = AudioTrack(
        id: const Uuid().v4(),
        path: file.path,
        duration: durationSeconds,
        start: startSeconds,
        waveform: waveform, // Can be null if extraction failed
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
    double maxEnd = 0;

    for (final v in videoTracks) {
      final end = v.endTime.inMilliseconds / 1000.0;
      // seconds
      if (end > maxEnd) maxEnd = end;
    }

    for (final a in audioTracks) {
      final end = a.start + a.duration;   // seconds
      if (end > maxEnd) maxEnd = end;
    }

    return (maxEnd * pixelsPerSecond) + 400;
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

  List<TextTrack> textTracks = [];

  TextTrack? selectedTextTrack;

  void addTextTrack(TextTrack track) {
    textTracks.add(track);
    selectTextTrack(track.id);
    notifyListeners();
  }

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
}

