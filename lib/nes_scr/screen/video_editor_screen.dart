import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/gestures.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../model/eitor_state.dart';
import '../model/timeline_item.dart';
import '../model/timeline_track.dart';
import '../widgets/speed_curve_editor.dart';
import '../widgets/wave_form_painter.dart' show WaveformPainter;

class VideoEditorScreen extends StatefulWidget {
  final List<XFile>? initialVideos;

  const VideoEditorScreen({super.key, this.initialVideos});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen>
    with TickerProviderStateMixin {
  bool isPlaying = false;
  Duration playheadPosition = Duration.zero;
  int? selectedClip;
  double pixelsPerSecond = 100.0;
  double timelineOffset = 0.0;
  final Map<String, VideoPlayerController> _controllers = {};
  VideoPlayerController? _activePreviewController;
  TimelineItem? _activeItem;
  late Ticker _playbackTicker;
  int _lastFrameTime = 0;
  double _initialRotation = 0.0;
  double _initialScale = 1.0;
  List<EditorState> history = [];
  int historyIndex = -1;
  final ScrollController _bottomNavController = ScrollController();
  List<TimelineItem> clips = [];
  List<TimelineItem> audioItems = [];
  List<TimelineItem> overlayItems = [];
  List<TimelineItem> textItems = [];
  Timer? playbackTimer;
  final ImagePicker _picker = ImagePicker();
  final Map<String, VideoPlayerController> _audioControllers = {};
  String? selectedEffect;
  String? selectedFilter;
  double filterIntensity = 1.0;
  int _nextLayerIndex = 0;
  VideoPlayerController? _activeVideoController;
  VideoPlayerController? _activeAudioController;
  bool _isInitializing = false;

  // Export settings
  String exportResolution = '1080p';
  int exportBitrate = 5000;
  bool removeWatermark = false;
  List<Uint8List>? thumbnailBytes;
  final thumbnailNotifier = ValueNotifier<List<Uint8List>>([]);

  // NEW: Current editing tool state
  String? currentTool;
  bool _isDraggingClip = false;
  bool _isResizingOverlay = false;
  Offset? _overlayDragStart;


  @override
  void initState() {
    super.initState();
    _playbackTicker = createTicker(_playbackFrame);
    thumbnailNotifier.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.initialVideos != null && widget.initialVideos!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processInitialVideos();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (clips.isNotEmpty && mounted) {
          playheadPosition = Duration.zero;
          timelineOffset = 0.0;
          _updatePreview();
          if (clips.isNotEmpty) {
            selectedClip = int.parse(clips.first.id);
          }
          setState(() {});
        }
      });
    }
  }

  Future<void> _processInitialVideos() async {
    if (_isInitializing) return;

    setState(() => _isInitializing = true);

    try {
      Duration currentStartTime = Duration.zero;

      for (int index = 0; index < widget.initialVideos!.length; index++) {
        final video = widget.initialVideos![index];
        final videoPath = video.path;

        final controller = VideoPlayerController.file(File(videoPath));
        await _initializeVideoController(controller);
        await controller.initialize();

        await controller.seekTo(const Duration(milliseconds: 500));
        await Future.delayed(const Duration(milliseconds: 300));

        final duration = controller.value.duration;

        Duration clipStartTime = currentStartTime;

        final item = TimelineItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_$index',
          type: TimelineItemType.video,
          file: File(videoPath),
          startTime: clipStartTime,
          duration: duration,
          originalDuration: duration,
          trimStart: Duration.zero,
          trimEnd: duration,
          thumbnailBytes: [],
          thumbnailPaths: [],
          cropLeft: 0.0,
          cropTop: 0.0,
          cropRight: 0.0,
          cropBottom: 0.0,
        );

        var bytesList = await _generateThumbnailsBatchFFmpeg(
          videoPath,
          duration,
        );
        if (bytesList.isNotEmpty && mounted) {
          item.thumbnailBytes = bytesList;
          thumbnailNotifier.value = List.from(bytesList);
        } else {
          bytesList = await _generateThumbnailsHybrid(videoPath, duration);
          if (bytesList.isNotEmpty) item.thumbnailBytes = bytesList;
        }

        _controllers[item.id] = controller;
        await controller.setLooping(false);

        clips.add(item);
        currentStartTime += duration;
      }

      if (mounted && clips.isNotEmpty) {
        clips.sort((a, b) => a.startTime.compareTo(b.startTime));
        selectedClip = int.parse(clips.first.id.split('_')[0]);
        playheadPosition = Duration.zero;
        timelineOffset = 0.0;

        final firstCtrl = _controllers[clips.first.id]!;
        _activeVideoController = firstCtrl;
        _activeItem = clips.first;

        await firstCtrl.seekTo(const Duration(seconds: 1));
        await Future.delayed(const Duration(milliseconds: 300));

        setState(() => _isInitializing = false);

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() {});
        });

        _showMessage('${clips.length} video(s) loaded successfully');
      }
    } catch (e) {
      debugPrint('❌ Error processing initial videos: $e');
      if (mounted) {
        setState(() => _isInitializing = false);
        _showError('Failed to load videos: $e');
      }
    }
  }

  void togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
      final maxDuration = _getTotalDuration();
      if (isPlaying && playheadPosition.inMilliseconds >= maxDuration * 1000) {
        playheadPosition = Duration.zero;
        timelineOffset = 0.0;
      }
    });
    if (isPlaying) {
      _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
      if (!_playbackTicker.isActive) {
        _playbackTicker.start();
      }
    } else {
      if (_playbackTicker.isActive) {
        _playbackTicker.stop();
      }
    }
  }

  @override
  void dispose() {
    _playbackTicker.stop();
    _playbackTicker.dispose();
    thumbnailNotifier.dispose();

    for (final controller in _controllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        debugPrint('Error disposing controller: $e');
      }
    }
    _controllers.clear();

    for (final controller in _audioControllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        debugPrint('Error disposing audio controller: $e');
      }
    }
    _audioControllers.clear();

    super.dispose();
  }

  void _saveToHistory() {
    final current = EditorState(
      clips: clips.map((c) => c.copyWith()).toList(),
      audioItems: audioItems.map((a) => a.copyWith()).toList(),
      textItems: textItems.map((t) => t.copyWith()).toList(),
      overlayItems: overlayItems.map((o) => o.copyWith()).toList(),
      selectedClip: selectedClip,
      playheadPosition: playheadPosition,
    );
    if (historyIndex < history.length - 1) {
      history = history.sublist(0, historyIndex + 1);
    }
    history.add(current);
    historyIndex = history.length - 1;
  }

  void _undo() {
    if (historyIndex > 0) {
      historyIndex--;
      final state = history[historyIndex];
      setState(() {
        clips = state.clips.map((c) => c.copyWith()).toList();
        audioItems = state.audioItems.map((a) => a.copyWith()).toList();
        textItems = state.textItems.map((t) => t.copyWith()).toList();
        overlayItems = state.overlayItems.map((o) => o.copyWith()).toList();
        selectedClip = state.selectedClip;
        playheadPosition = state.playheadPosition;
      });
    }
  }

  void _redo() {
    if (historyIndex < history.length - 1) {
      historyIndex++;
      final state = history[historyIndex];
      setState(() {
        clips = state.clips.map((c) => c.copyWith()).toList();
        audioItems = state.audioItems.map((a) => a.copyWith()).toList();
        textItems = state.textItems.map((t) => t.copyWith()).toList();
        overlayItems = state.overlayItems.map((o) => o.copyWith()).toList();
        selectedClip = state.selectedClip;
        playheadPosition = state.playheadPosition;
      });
    }
  }

  void _playbackFrame(Duration elapsed) {
    if (!mounted || !isPlaying) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final deltaMs = now - _lastFrameTime;
    _lastFrameTime = now;
    if (deltaMs <= 0 || deltaMs > 100) return;

    setState(() {
      playheadPosition += Duration(milliseconds: deltaMs);
      final max = _getTotalDuration();
      if (playheadPosition.inMilliseconds >= max * 1000) {
        playheadPosition = Duration(milliseconds: (max * 1000).toInt()); // Ensure the Duration is an integer
        isPlaying = false;
        _playbackTicker.stop();
      }

      // Fix: Ensure timelineOffset is a double
      timelineOffset = (playheadPosition.inMilliseconds / 1000 * pixelsPerSecond).toDouble();
    });
    _updatePreview();
  }



  double _getTotalDuration() {
    double max = 0;
    for (var list in [clips, audioItems, overlayItems, textItems]) {
      if (list.isNotEmpty) {
        final end = list.map((e) => (e.startTime + e.duration).inSeconds.toDouble()).reduce(math.max);
        if (end > max) max = end;
      }
    }
    return max;
  }

  double getCurrentSpeed(TimelineItem item, Duration localTime) {
    if (item.speedPoints.length < 2) return item.speed;
    final progress = localTime.inMilliseconds / item.duration.inMilliseconds;
    for (int i = 0; i < item.speedPoints.length - 1; i++) {
      final a = item.speedPoints[i];
      final b = item.speedPoints[i + 1];
      if (progress >= a.time && progress <= b.time) {
        final t = (progress - a.time) / (b.time - a.time);
        return a.speed + (b.speed - a.speed) * t;
      }
    }
    return item.speed;
  }

  void _updatePreview() {
    if (!mounted) return;
    final active = _findActiveVideo();
    if (active != null && _controllers.containsKey(active.id)) {
      final ctrl = _controllers[active.id]!;
      final local = playheadPosition - active.startTime;
      final speed = getCurrentSpeed(active, local);
      final source = active.trimStart + Duration(milliseconds: (local.inMilliseconds * speed).round());

      if ((ctrl.value.position - source).inMilliseconds.abs() > 100) {
        ctrl.seekTo(source);
      }
      ctrl.setPlaybackSpeed(speed);
      ctrl.setVolume(active.volume);

      if (isPlaying && !ctrl.value.isPlaying) ctrl.play();
      if (!isPlaying && ctrl.value.isPlaying) ctrl.pause();

      if (_activeVideoController != ctrl) {
        _activeVideoController?.pause();
        _activeVideoController = ctrl;
        _activeItem = active;
        setState(() {});
      }
    } else {
      _activeVideoController?.pause();
      _activeVideoController = null;
      _activeItem = null;
      setState(() {});
    }
  }

  TimelineItem? _findActiveVideo() {
    for (final item in clips) {
      final effective = Duration(milliseconds: (item.duration.inMilliseconds / item.speed).round());
      if (playheadPosition >= item.startTime && playheadPosition < item.startTime + effective) {
        return item;
      }
    }
    return null;
  }

  TimelineItem? _findActiveAudio() {
    for (final item in audioItems) {
      final effectiveDur = Duration(
        milliseconds: (item.duration.inMilliseconds / item.speed).round(),
      );
      if (playheadPosition >= item.startTime &&
          playheadPosition < item.startTime + effectiveDur) {
        return item;
      }
    }
    return null;
  }

  TimelineItem? getClipAtPlayhead() {
    for (final clip in clips) {
      if (playheadPosition >= clip.startTime &&
          playheadPosition < clip.startTime + clip.duration) {
        return clip;
      }
    }
    return null;
  }

  Widget _applyEffect(Widget child) {
    final effect = selectedEffect ?? selectedFilter;
    switch (effect) {
      case 'Blur':
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 6 * filterIntensity, sigmaY: 6 * filterIntensity),
          child: child,
        );
      case 'Vivid':
        return ColorFiltered(
          colorFilter: ColorFilter.matrix([
            1.3 + filterIntensity * 0.7, 0, 0, 0, 0,
            0, 1.0, 0, 0, 0,
            0, 0, 1.0, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: child,
        );
      case 'Warm':
        return ColorFiltered(
          colorFilter: ColorFilter.matrix([
            1.1, 0.05, -0.05, 0, 0,
            0.02, 1.08, 0.02, 0, 0,
            -0.05, 0.02, 1.1, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: child,
        );
      case 'Cool':
        return ColorFiltered(
          colorFilter: ColorFilter.matrix([
            1.1, -0.03, 0.05, 0, 0,
            -0.03, 1.08, -0.03, 0, 0,
            0.05, -0.03, 1.1, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: child,
        );
      case 'B&W':
        return ColorFiltered(colorFilter: ColorFilter.mode(Colors.grey, BlendMode.saturation), child: child);
      case 'Vintage':
        return ColorFiltered(
          colorFilter: ColorFilter.matrix([
            0.393, 0.769, 0.189, 0, 0,
            0.349, 0.686, 0.168, 0, 0,
            0.272, 0.534, 0.131, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: child,
        );
      case 'Cinematic':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.7 - filterIntensity * 0.3,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        );
      case 'Glitch':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(Colors.red, BlendMode.colorDodge),
                child: Transform.translate(offset: Offset(3 * filterIntensity, 0), child: child),
              ),
            ),
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(Colors.cyan, BlendMode.colorDodge),
                child: Transform.translate(offset: Offset(-3 * filterIntensity, 0), child: child),
              ),
            ),
          ],
        );
      default:
        return child;
    }
  }

  void splitClipAtPlayhead() {
    final clip = getClipAtPlayhead();
    if (clip == null ||
        playheadPosition <= clip.startTime ||
        playheadPosition >= clip.startTime + clip.duration)
      return;

    final splitPoint = playheadPosition - clip.startTime;

    _saveToHistory();

    setState(() {
      clips.removeWhere((c) => c.id == clip.id);

      // First part
      clips.add(clip.copyWith(duration: splitPoint));

      // Second part
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      clips.add(
        clip.copyWith(
          id: newId,
          startTime: playheadPosition,
          duration: clip.duration - splitPoint,
          trimStart: clip.trimStart + splitPoint,
        ),
      );

      clips.sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    _showMessage('Clip split successfully');
  }

  Future<void> _addVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    _showLoading();

    try {
      final videoPath = file.path;
      debugPrint('\n🎬 Adding video: $videoPath');

      final tempCtrl = VideoPlayerController.file(File(videoPath));
      await tempCtrl.initialize();
      await tempCtrl.seekTo(const Duration(milliseconds: 500));
      await Future.delayed(const Duration(milliseconds: 300));

      final duration = tempCtrl.value.duration;
      debugPrint('✅ Video duration: ${duration.inSeconds}s');

      List<Uint8List> bytesList = await _generateThumbnailsBatchFFmpeg(
        videoPath,
        duration,
      );

      if (bytesList.isEmpty) {
        bytesList = await _generateThumbnailsHybrid(videoPath, duration);
      }

      if (bytesList.isEmpty) {
        _hideLoading();
        _showError('Could not generate thumbnails');
        return;
      }

      await tempCtrl.seekTo(const Duration(seconds: 1));
      await tempCtrl.pause();
      await Future.delayed(const Duration(milliseconds: 300));

      final startTime =
          clips.isEmpty
              ? Duration.zero
              : clips
                  .map((i) => i.startTime + i.duration)
                  .reduce((a, b) => a > b ? a : b);

      final item = TimelineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TimelineItemType.video,
        file: File(videoPath),
        startTime: startTime,
        duration: duration,
        originalDuration: duration,
        trimStart: Duration.zero,
        trimEnd: duration,
        thumbnailBytes: bytesList,
        thumbnailPaths: [],
        cropLeft: 0.0,
        cropTop: 0.0,
        cropRight: 0.0,
        cropBottom: 0.0,
      );

      _controllers[item.id] = tempCtrl;
      await tempCtrl.setLooping(false);

      _saveToHistory();

      setState(() {
        clips.add(item);
        clips.sort((a, b) => a.startTime.compareTo(b.startTime));
        selectedClip = int.parse(item.id);
        _activeItem = item;
        _activeVideoController = tempCtrl;
        playheadPosition = startTime;
        timelineOffset =
            playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
      });

      _updatePreview();
      _hideLoading();
      _showMessage('Video added: ${file.name}');

      debugPrint('✅ Video added with ${bytesList.length} thumbnails');
    } catch (e) {
      debugPrint('❌ Error adding video: $e');
      _hideLoading();
      _showError('Failed to add video: $e');
    }
  }


  Future<void> _initializeVideoController(
    VideoPlayerController controller,
  ) async {
    try {
      await controller.initialize();

      await controller.seekTo(const Duration(milliseconds: 500));
      await Future.delayed(const Duration(milliseconds: 400));

      if (controller.value.size.width < 100) {
        await controller.seekTo(const Duration(seconds: 1));
        await Future.delayed(const Duration(milliseconds: 400));
      }
    } catch (e) {
      debugPrint('Controller init failed: $e');
    }
  }

  String? getIdAsString(int? clipId) {
    if (clipId == null) return null;
    return clipId.toString();
  }

  Future<void> _addAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    _showLoading();
    try {
      final file = File(path);
      final ctrl = VideoPlayerController.file(file);
      await ctrl.initialize();
      final duration = ctrl.value.duration;
      final waveform = await _generateWaveform(path);
      final item = TimelineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TimelineItemType.audio,
        file: file,
        startTime: playheadPosition,
        duration: duration,
        originalDuration: duration,
        trimStart: Duration.zero,
        trimEnd: duration,
        waveformData: waveform,
        volume: 1.0,
      );
      _audioControllers[item.id] = ctrl;
      ctrl.setLooping(false);
      ctrl.setVolume(0); // Mute preview (optional)
      setState(() {
        audioItems.add(item);
        audioItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      });
      _updatePreview();
      _hideLoading();
      _showMessage('Audio added');
    } catch (e) {
      _hideLoading();
      _showError('Failed to load audio: $e');
    }
  }

  Future<List<double>> _generateWaveform(String path) async {
    final random = math.Random();
    return List.generate(200, (_) => random.nextDouble() * 0.8 + 0.1);
  }

  // Thumbnail generation methods
  Future<List<Uint8List>> _generateThumbnailsHybrid(
    String videoPath,
    Duration duration,
  ) async {
    final file = File(videoPath);
    final fileSizeInMB = await file.length() / (1024 * 1024);

    debugPrint('📹 Video: ${fileSizeInMB.toStringAsFixed(2)} MB');

    if (fileSizeInMB > 1.0) {
      debugPrint('⚡ Using FFmpeg for large video');
      return await _generateThumbnailsWithFFmpeg(videoPath, duration);
    } else {
      debugPrint('⚡ Using video_thumbnail for small video');
      return await _generateThumbnailsWithPlugin(videoPath, duration);
    }
  }

  Future<List<Uint8List>> _generateThumbnailsWithFFmpeg(
    String videoPath,
    Duration duration,
  ) async {
    List<Uint8List> thumbnails = [];
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      final totalThumbnails = 10;
      final durationInSeconds = duration.inSeconds;

      for (int i = 0; i < totalThumbnails; i++) {
        final timeInSeconds =
            i == 0
                ? 1
                : ((durationInSeconds - 2) * i / (totalThumbnails - 1) + 1)
                    .round();

        final outputPath = '${tempDir.path}/thumb_${timestamp}_$i.jpg';

        final command =
            '-ss $timeInSeconds -i "$videoPath" -vframes 1 -vf "scale=150:-1" -q:v 2 "$outputPath"';

        final session = await FFmpegKit.execute(command);
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          final file = File(outputPath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            thumbnails.add(bytes);
            await file.delete();
          }
        }

        if (thumbnails.length >= 10) break;
      }

      debugPrint('✅ FFmpeg generated ${thumbnails.length} thumbnails');
      return thumbnails;
    } catch (e) {
      debugPrint('❌ FFmpeg error: $e');
      return thumbnails;
    }
  }

  Future<List<Uint8List>> _generateThumbnailsWithPlugin(
    String videoPath,
    Duration duration,
  ) async {
    List<Uint8List> thumbnails = [];

    try {
      final totalThumbnails = 10;
      final durationInMs = duration.inMilliseconds;

      for (int i = 0; i < totalThumbnails; i++) {
        final timeMs =
            i == 0
                ? 500
                : ((durationInMs - 1000) * i / (totalThumbnails - 1) + 500)
                    .round();

        try {
          final bytes = await VideoThumbnail.thumbnailData(
            video: videoPath,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 150,
            timeMs: timeMs,
            quality: 75,
          ).timeout(const Duration(seconds: 3), onTimeout: () => null);

          if (bytes != null && bytes.isNotEmpty) {
            thumbnails.add(bytes);
          }
        } catch (e) {
          debugPrint('⚠️ Skip $i: $e');
        }
      }

      debugPrint('✅ Plugin generated ${thumbnails.length} thumbnails');
      return thumbnails;
    } catch (e) {
      debugPrint('❌ Plugin error: $e');
      return thumbnails;
    }
  }

  Future<List<Uint8List>> _generateThumbnailsBatchFFmpeg(
    String videoPath,
    Duration duration,
  ) async {
    final thumbnails = <Uint8List>[];
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPattern = '${tempDir.path}/thumb_$timestamp/%03d.jpg';

    final totalSeconds = duration.inMilliseconds / 1000.0;
    final safeSeconds = totalSeconds < 0.5 ? 0.5 : totalSeconds;
    final targetFrames = 10;
    final interval = safeSeconds / (targetFrames - 1);

    try {
      final command = '''
-i "$videoPath" 
-vf "fps=1/$interval,scale=120:120:force_original_aspect_ratio=decrease,pad=120:120:(ow-iw)/2:(oh-ih)/2,format=yuv420p" 
-vframes 6 -q:v 8 -y "$outputPattern"
''';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final dir = Directory('${tempDir.path}/thumb_$timestamp');
        if (await dir.exists()) {
          final files =
              (await dir.list().toList())
                  .whereType<File>()
                  .where((f) => f.path.endsWith('.jpg'))
                  .toList();
          files.sort((a, b) => a.path.compareTo(b.path));

          for (final file in files) {
            try {
              final bytes = await file.readAsBytes();
              if (bytes.length > 2000) thumbnails.add(bytes);
              await file.delete();
            } catch (_) {}
          }
          await dir.delete(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('Safe thumbnail batch failed: $e');
    }

    if (thumbnails.length < 3) {
      return await _generateThumbnailsWithFFmpeg(videoPath, duration);
    }

    return thumbnails;
  }

  Future<void> _addImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    Duration imageDur = const Duration(seconds: 5);
    final activeVideo = _findActiveVideo();
    if (activeVideo != null) {
      imageDur = activeVideo.duration;
    }
    final item = TimelineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TimelineItemType.image,
      file: File(file.path),
      startTime: playheadPosition,
      duration: imageDur,
      originalDuration: imageDur,
      x: 50,
      y: 100,
      scale: 1.0,
      rotation: 0.0,
      layerIndex: _nextLayerIndex++,
    );
    setState(() {
      overlayItems.add(item);
      overlayItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      selectedClip = int.parse(item.id);
      playheadPosition = item.startTime;
      timelineOffset = playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
    });
    _showMessage('Image added');
  }

  Future<void> _addText() async {
    final item = TimelineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TimelineItemType.text,
      text: "New Text",
      startTime: playheadPosition,
      duration: const Duration(seconds: 5),
      originalDuration: const Duration(seconds: 5),
      x: 100,
      y: 200,
      textColor: Colors.white,
      fontSize: 32,
      scale: 1.0,
      rotation: 0.0,
      layerIndex: _nextLayerIndex++,
    );
    setState(() {
      textItems.add(item);
      textItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      selectedClip = int.parse(item.id);
      playheadPosition = item.startTime;
      timelineOffset = playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
    });
    _showMessage('Text added');
    Future.delayed(const Duration(milliseconds: 100), () {
      if (textItems.isNotEmpty) _showTextEditor(textItems.last);
    });
  }

  // NEW: Show edit tools in bottom sheet
  void _showEditTools() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.7,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Edit Tools',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _toolTile(
                              Icons.content_cut,
                              'Split',
                              'Split clip at playhead',
                              splitClipAtPlayhead,
                            ),
                            _toolTile(
                              Icons.cut,
                              'Trim',
                              'Adjust clip duration',
                              () {
                                Navigator.pop(context);
                                _showMessage('Use timeline handles to trim');
                              },
                            ),
                            _toolTile(
                              Icons.speed,
                              'Speed Ramp',
                              'Advanced speed control',
                              () {
                                final item = getSelectedItem();
                                if (item?.type == TimelineItemType.video) {
                                  Navigator.pop(context);
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder:
                                        (_) => SpeedCurveEditor(item: item!),
                                  );
                                }
                              },
                            ),
                            _toolTile(
                              Icons.crop,
                              'Crop',
                              'Crop video frame',
                              _showCropEditor,
                            ),
                            _toolTile(
                              Icons.rotate_90_degrees_ccw,
                              'Rotate',
                              'Rotate video',
                              () {
                                final item = getSelectedItem();
                                if (item != null) {
                                  _saveToHistory();
                                  setState(() => item.rotation += 90);
                                  _showMessage('Rotated 90°');
                                }
                              },
                            ),
                            _toolTile(
                              Icons.flip,
                              'Flip',
                              'Flip horizontal/vertical',
                              () {
                                Navigator.pop(context);
                                _showMessage('Flip applied');
                              },
                            ),
                            _toolTile(
                              Icons.delete,
                              'Delete',
                              'Remove selected item',
                              _deleteSelected,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showCropEditor() {
    TimelineItem? item = getSelectedItem();
    if (item == null || item.type != TimelineItemType.video) {
      _showMessage('Select a video clip to crop');
      return;
    }
    double tempLeft = item.cropLeft;
    double tempTop = item.cropTop;
    double tempRight = item.cropRight;
    double tempBottom = item.cropBottom;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setM) => Container(
                  height: 400,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Crop Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Left: ${tempLeft.toStringAsFixed(2)}'),
                      Slider(
                        value: tempLeft,
                        min: 0,
                        max: 0.5,
                        onChanged: (v) => setM(() => tempLeft = v),
                      ),
                      Text('Top: ${tempTop.toStringAsFixed(2)}'),
                      Slider(
                        value: tempTop,
                        min: 0,
                        max: 0.5,
                        onChanged: (v) => setM(() => tempTop = v),
                      ),
                      Text('Right: ${tempRight.toStringAsFixed(2)}'),
                      Slider(
                        value: tempRight,
                        min: 0,
                        max: 0.5,
                        onChanged: (v) => setM(() => tempRight = v),
                      ),
                      Text('Bottom: ${tempBottom.toStringAsFixed(2)}'),
                      Slider(
                        value: tempBottom,
                        min: 0,
                        max: 0.5,
                        onChanged: (v) => setM(() => tempBottom = v),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            item!.cropLeft = tempLeft;
                            item.cropTop = tempTop;
                            item.cropRight = tempRight;
                            item.cropBottom = tempBottom;
                          });
                          Navigator.pop(ctx);
                          _showMessage('Crop applied');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showSpeedEditor() {
    final item = getSelectedItem();
    if (item == null || item.type != TimelineItemType.video) {
      _showMessage('Select a video clip first');
      return;
    }

    double tempSpeed = item.speed;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setM) => Container(
                  height: 380,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Speed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${tempSpeed.toStringAsFixed(2)}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Slider(
                        value: tempSpeed,
                        min: 0.25,
                        max: 4.0,
                        divisions: 15,
                        activeColor: const Color(0xFF00D9FF),
                        onChanged: (v) => setM(() => tempSpeed = v),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 4.0].map((
                              s,
                            ) {
                              final isSelected = (tempSpeed - s).abs() < 0.01;
                              return GestureDetector(
                                onTap: () => setM(() => tempSpeed = s),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? const Color(0xFF00D9FF)
                                            : const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Colors.transparent
                                              : Colors.white24,
                                    ),
                                  ),
                                  child: Text(
                                    '${s}x',
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.black
                                              : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A2A2A),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  final oldDuration = item.duration;
                                  item.speed = tempSpeed;
                                  // Recalculate duration based on speed
                                  item.duration = Duration(
                                    milliseconds:
                                        (oldDuration.inMilliseconds / tempSpeed)
                                            .round(),
                                  );
                                });
                                Navigator.pop(ctx);
                                _showMessage(
                                  'Speed: ${tempSpeed.toStringAsFixed(2)}x',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D9FF),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _toolTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF00D9FF), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 11),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  // IMPROVED: Build preview with proper overlay interaction
  Widget _buildPreview() {
    final screenSize = MediaQuery.of(context).size;

    return ValueListenableBuilder<List<Uint8List>>(
      valueListenable: thumbnailNotifier,
      builder: (context, thumbs, child) {
        Widget videoWidget;

        if (_activeVideoController != null &&
            _activeVideoController!.value.isInitialized) {
          videoWidget = AspectRatio(
            aspectRatio: _activeVideoController!.value.aspectRatio,
            child: _buildCroppedVideoPlayer(_activeVideoController!, _activeItem!),
          );
        } else if (thumbs.isNotEmpty) {
          videoWidget = Image.memory(thumbs.first, fit: BoxFit.contain);
        } else if (clips.isNotEmpty && clips.first.thumbnailBytes?.isNotEmpty == true) {
          videoWidget = Image.memory(clips.first.thumbnailBytes!.first, fit: BoxFit.contain);
        } else {
          videoWidget = _buildPlaceholder();
        }

        // APPLY ENHANCED CPU FILTERS (works instantly)
        if (selectedFilter != null && selectedFilter != 'None') {
          videoWidget = _applyEffect(videoWidget);
        } else if (selectedEffect != null) {
          videoWidget = _applyEffect(videoWidget);
        } else if (thumbs.isNotEmpty) {
          videoWidget = Image.memory(
            thumbs.first,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          );
        } else if (clips.isNotEmpty &&
            clips.first.thumbnailBytes?.isNotEmpty == true) {
          videoWidget = Image.memory(
            clips.first.thumbnailBytes!.first,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          );
        } else {
          videoWidget = _buildPlaceholder();
        }

        if (selectedEffect != null) {
          videoWidget = _applyEffect(videoWidget);
        }

        return Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              videoWidget,
              ..._buildInteractiveOverlays(screenSize, [
                ...textItems,
                ...overlayItems,
              ]),
            ],
          ),
        );
      },
    );
  }

  // NEW: Interactive overlays with resize handles
  List<Widget> _buildInteractiveOverlays(
    Size screenSize,
    List<TimelineItem> visualItems,
  ) {
    final List<Widget> list = [];

    for (final item in visualItems) {
      if (playheadPosition >= item.startTime &&
          playheadPosition < item.startTime + item.duration) {
        double currX =
            item.x ?? (item.type == TimelineItemType.text ? 100 : 50);
        double currY =
            item.y ?? (item.type == TimelineItemType.text ? 200 : 100);
        double currScale = item.scale;
        double currRotation = item.rotation;

        // Apply animations if present
        if (item.endX != null ||
            item.endY != null ||
            item.endScale != null ||
            item.endRotation != null) {
          double fraction = ((playheadPosition - item.startTime)
                      .inMilliseconds /
                  item.duration.inMilliseconds)
              .clamp(0.0, 1.0);

          if (item.endX != null) {
            currX =
                (item.x ?? currX) + fraction * (item.endX! - (item.x ?? currX));
          }
          if (item.endY != null) {
            currY =
                (item.y ?? currY) + fraction * (item.endY! - (item.y ?? currY));
          }
          if (item.endScale != null) {
            currScale = item.scale + fraction * (item.endScale! - item.scale);
          }
          if (item.endRotation != null) {
            currRotation =
                item.rotation + fraction * (item.endRotation! - item.rotation);
          }
        }

        Widget child;
        if (item.type == TimelineItemType.text) {
          child = Text(
            item.text ?? '',
            style: TextStyle(
              color: item.textColor ?? Colors.white,
              fontSize: item.fontSize ?? 32,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          );
        } else {
          child =
              item.file != null
                  ? Image.file(
                    item.file!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) => const SizedBox(),
                  )
                  : const SizedBox();
        }

        // Wrap in transform
        child = Transform.rotate(
          angle: currRotation * math.pi / 180,
          child: Transform.scale(scale: currScale, child: child),
        );

        // Add interaction for selected items
        final isSelected = selectedClip == int.tryParse(item.id);
        if (isSelected) {
          child = _buildResizableOverlay(item, child, screenSize);
        }

        list.add(Positioned(left: currX, top: currY, child: child));
      }
    }

    return list;
  }

  // NEW: Resizable overlay with handles
  Widget _buildResizableOverlay(
    TimelineItem item,
    Widget child,
    Size screenSize,
  ) {
    return GestureDetector(
      onScaleStart: (details) {
        _saveToHistory();
        _initialRotation = item.rotation;
        _initialScale = item.scale;
      },
      onScaleUpdate: (details) {
        setState(() {
          item.rotation = _initialRotation + details.rotation * 180 / math.pi;
          item.scale = (_initialScale * details.scale).clamp(0.3, 3.0);
          item.x = (item.x ?? 0) + details.focalPointDelta.dx;
          item.y = (item.y ?? 0) + details.focalPointDelta.dy;
          item.x = item.x!.clamp(0.0, screenSize.width - 200 * item.scale);
          item.y = item.y!.clamp(0.0, screenSize.height - 200 * item.scale);
        });
      },
      onTap: () => _showTextEditor(item),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00D9FF), width: 2),
            ),
            child: child,
          ),
          // Corner resize handle
          Positioned(
            right: -6,
            bottom: -6,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF00D9FF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          // Rotation handle
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTextEditor(TimelineItem item) {
    final ctrl = TextEditingController(text: item.text);
    Color tempColor = item.textColor ?? Colors.white;
    double tempSize = item.fontSize ?? 32;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setM) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    height: 450,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Edit Text',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: ctrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter text',
                            hintStyle: TextStyle(color: Colors.white54),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF00D9FF)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Color',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children:
                              [
                                Colors.white,
                                Colors.red,
                                Colors.yellow,
                                Colors.blue,
                                Colors.green,
                                Colors.purple,
                                Colors.orange,
                                Colors.pink,
                              ].map((c) {
                                final sel = c == tempColor;
                                return GestureDetector(
                                  onTap: () => setM(() => tempColor = c),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            sel
                                                ? const Color(0xFF00D9FF)
                                                : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Font Size',
                          style: TextStyle(color: Colors.white),
                        ),
                        Slider(
                          value: tempSize,
                          min: 10,
                          max: 100,
                          activeColor: const Color(0xFF00D9FF),
                          onChanged: (v) => setM(() => tempSize = v),
                        ),
                        Text(
                          '${tempSize.toInt()}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              item.text = ctrl.text;
                              item.textColor = tempColor;
                              item.fontSize = tempSize;
                            });
                            Navigator.pop(ctx);
                            _showMessage('Text updated');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D9FF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'Add a video to start editing',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrackReordering() {
    final tracks = [
      {'name': 'Video', 'icon': Icons.videocam, 'items': clips},
      {'name': 'Audio', 'icon': Icons.audiotrack, 'items': audioItems},
      {'name': 'Overlays', 'icon': Icons.layers, 'items': overlayItems},
      {'name': 'Text', 'icon': Icons.text_fields, 'items': textItems},
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => ReorderableListView(
        onReorder: (old, newIndex) {
          setState(() {
            if (newIndex > old) newIndex--;
            final track = tracks.removeAt(old);
            tracks.insert(newIndex, track);
            // Rebuild lists (simple swap for now)
            clips = tracks[0]['items'] as List<TimelineItem>;
            audioItems = tracks[1]['items'] as List<TimelineItem>;
            // etc...
          });
          Navigator.pop(ctx);
        },
        children: tracks.map((t) => ListTile(key: ValueKey(t), title: Text(t['name']  as String))).toList(),
      ),
    );
  }

  Widget _buildCroppedVideoPlayer(
    VideoPlayerController controller,
    TimelineItem item,
  ) {
    final videoSize = controller.value.size;
    final cropLeft = item.cropLeft;
    final cropTop = item.cropTop;
    final cropRight = item.cropRight;
    final cropBottom = item.cropBottom;

    if (cropLeft + cropRight >= 1 || cropTop + cropBottom >= 1) {
      return VideoPlayer(controller);
    }

    final cropFactorX = 1 - cropLeft - cropRight;
    final cropFactorY = 1 - cropTop - cropBottom;

    return OverflowBox(
      alignment: Alignment.center,
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: SizedBox(
        width: videoSize.width / cropFactorX,
        height: videoSize.height / cropFactorY,
        child: Transform.translate(
          offset: Offset(
            -videoSize.width * cropLeft / cropFactorX,
            -videoSize.height * cropTop / cropFactorY,
          ),
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  // Helper methods
  void _showLoading() => showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
        ),
  );

  void _hideLoading() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _showError(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _showMessage(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: const Color(0xFF10B981)),
  );

  String _formatTime(Duration duration) {
    final totalSeconds = duration.inMilliseconds / 1000.0;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toStringAsFixed(2).padLeft(5, '0')}';
  }

  TimelineItem? getSelectedItem() {
    for (final clip in clips) {
      if (int.tryParse(clip.id) == selectedClip) return clip;
    }
    for (final audio in audioItems) {
      if (int.tryParse(audio.id) == selectedClip) return audio;
    }
    for (final text in textItems) {
      if (int.tryParse(text.id) == selectedClip) return text;
    }
    for (final overlay in overlayItems) {
      if (int.tryParse(overlay.id) == selectedClip) return overlay;
    }
    return null;
  }

  void _deleteSelected() {
    if (selectedClip == null) return;
    final id = selectedClip.toString();

    _saveToHistory();

    setState(() {
      clips.removeWhere((c) => c.id == id);
      if (_controllers.containsKey(id)) {
        _controllers[id]!.dispose();
        _controllers.remove(id);
      }
      audioItems.removeWhere((c) => c.id == id);
      if (_audioControllers.containsKey(id)) {
        _audioControllers[id]!.dispose();
        _audioControllers.remove(id);
      }
      textItems.removeWhere((c) => c.id == id);
      overlayItems.removeWhere((c) => c.id == id);
      selectedClip = null;
    });

    _showMessage('Deleted');
  }

  double _clipWidth(TimelineItem item) {
    final secs = item.duration.inMilliseconds / 1000.0 / item.speed;
    return (secs * pixelsPerSecond).clamp(60.0, double.infinity);
  }

  Future<void> _exportVideo() async {
    if (clips.isEmpty) {
      _showMessage('No video to export');
      return;
    }

    // Show export settings dialog
    await _showExportSettings();

    _showLoading();
    try {
      final dir = await getTemporaryDirectory();
      final outputPath =
          '${dir.path}/exported_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Simple FFmpeg command for basic compositing (merge clips, add audio)
      // For full features, extend with overlays, effects via FFmpeg filters
      String command = '-i ${clips.first.file!.path} '; // Start with first clip
      for (int i = 1; i < clips.length; i++) {
        command += '-i ${clips[i].file!.path} ';
      }
      if (audioItems.isNotEmpty) {
        command += '-i ${audioItems.first.file!.path} ';
      }

      // Basic concat filter (assume same format)
      command +=
          '-filter_complex "concat=n=${clips.length}:v=1:a=0[outv];[0:a]'; // Video concat
      if (audioItems.isNotEmpty) {
        command +=
            '[1:a]amix=inputs=2:duration=longest[outa]'; // Simple audio mix
      }
      command +=
          '" -map "[outv]" -map "[outa]" -c:v libx264 -preset fast -crf 23 -c:a aac -b:v ${exportBitrate}k $outputPath';

      // Apply effect if selected (simple example: glitch via vignette or something)
      if (selectedEffect == 'Glitch') {
        command += ' -vf "noise=alls=20:allf=t+u" '; // Simple noise for glitch
      } else if (selectedEffect == 'Blur') {
        command += ' -vf "boxblur=2:1" ';
      } // Add more filters as needed

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        _showMessage('Video exported to $outputPath');
        // Optionally, save to gallery using image_gallery_saver or similar
      } else {
        _showError('Export failed');
      }
    } catch (e) {
      _showError('Export error: $e');
    } finally {
      _hideLoading();
    }
  }

  Future<void> _showExportSettings() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Export Settings',
              style: TextStyle(color: Colors.white),
            ),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: exportResolution,
                      dropdownColor: const Color(0xFF1A1A1A),
                      style: const TextStyle(color: Colors.white),
                      items:
                          ['720p', '1080p', '4K'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          exportResolution = newValue!;
                        });
                        this.setState(() {
                          exportResolution = newValue!;
                        });
                      },
                    ),
                    Slider(
                      value: exportBitrate.toDouble(),
                      min: 1000,
                      max: 10000,
                      divisions: 9,
                      activeColor: const Color(0xFF00D9FF),
                      label: '$exportBitrate kbps',
                      onChanged: (double value) {
                        setState(() {
                          exportBitrate = value.round();
                        });
                        this.setState(() {
                          exportBitrate = value.round();
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text(
                        'Remove Watermark (Pro)',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: removeWatermark,
                      activeColor: const Color(0xFF00D9FF),
                      onChanged: (bool? value) {
                        setState(() {
                          removeWatermark = value ?? false;
                        });
                        this.setState(() {
                          removeWatermark = value ?? false;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _exportVideo();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                ),
                child: const Text(
                  'Export',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Color(0xFF00D9FF)),
              SizedBox(height: 16),
              Text(
                'Loading videos...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildPreview()),
            _buildPlaybackControls(),
            _buildTimelineSection(),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF000000),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.help_outline, size: 24, color: Colors.white),
          const Spacer(),

          // More options button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.more_horiz, size: 16, color: Colors.white),
          ),

          const SizedBox(width: 8),

          // Resolution dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '1080P',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Export button
          GestureDetector(
            onTap: _showExportSettings,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00D9FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Export',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    final selectedItem = getSelectedItem();
    String timeText =
        '${_formatTime(playheadPosition)} / ${_formatTime(Duration(seconds: _getTotalDuration().toInt()))}';

    if (selectedItem != null) {
      timeText =
          '${_formatTime(selectedItem.startTime)} / ${_formatTime(selectedItem.startTime + selectedItem.duration)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF000000),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: togglePlayPause,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),

          // Time display
          Text(
            timeText,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),

          // Right controls
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ON',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _undo,
                child: const Icon(Icons.undo, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _redo,
                child: const Icon(Icons.redo, size: 20, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      height: 280,
      color: const Color(0xFF000000),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            timelineOffset -= details.delta.dx;
            timelineOffset = timelineOffset.clamp(
              0.0,
              _getTotalDuration() * pixelsPerSecond,
            );
            playheadPosition = Duration(
              milliseconds: (timelineOffset * 1000 / pixelsPerSecond).round(),
            );
          });
          _updatePreview();
        },
        onScaleUpdate: (details) {
          if (details.scale == 1.0) return;
          final oldPps = pixelsPerSecond;
          double newPps = pixelsPerSecond * details.scale;
          newPps = newPps.clamp(50.0, 200.0);
          final centerSec =
              timelineOffset / oldPps +
              MediaQuery.of(context).size.width / 2 / oldPps;
          timelineOffset =
              (centerSec - MediaQuery.of(context).size.width / 2 / newPps) *
              newPps;
          timelineOffset = timelineOffset.clamp(
            0.0,
            _getTotalDuration() * newPps,
          );
          setState(() => pixelsPerSecond = newPps);
          playheadPosition = Duration(
            milliseconds: (timelineOffset * 1000 / pixelsPerSecond).round(),
          );
          _updatePreview();
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    _buildDurationRuler(),
                    const SizedBox(height: 6),
                    _buildVideoTrack(),
                    const SizedBox(height: 4),
                    _buildAudioTrack(),
                    const SizedBox(height: 4),
                    _buildOverlayTrack(),
                    const SizedBox(height: 4),
                    _buildTextTrack(),
                  ],
                ),
              ),
            ),
            _buildCenteredPlayhead(),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredPlayhead() {
    final screenWidth = MediaQuery.of(context).size.width;
    final selectedItem = getSelectedItem();
    final durationText =
        selectedItem != null ? _formatTime(selectedItem.duration) : '';

    return Positioned(
      left: screenWidth / 2 - 1,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Playhead circle
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF00D9FF),
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(height: 2),

            // Duration label
            if (durationText.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  durationText,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 2),

            // Vertical line
            Expanded(
              child: Container(
                width: 2,
                decoration: const BoxDecoration(
                  color: Color(0xFF00D9FF),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white30,
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationRuler() {
    final totalSec = _getTotalDuration();
    final visibleSec = MediaQuery.of(context).size.width / pixelsPerSecond;
    final centreSecond = timelineOffset / pixelsPerSecond;

    return Container(
      height: 36,
      color: const Color(0xFF0A0A0A),
      child: CustomPaint(
        painter: _DurationRulerPainter(
          totalSeconds: totalSec,
          visibleSeconds: visibleSec,
          offsetSeconds: centreSecond,
          pixelsPerSecond: pixelsPerSecond,
          formatTime: _formatTime,
        ),
      ),
    );
  }

  Widget _buildVideoTrack() {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: Stack(
        children: [
          // Video clips
          ...clips.map((clip) => _buildVideoClip(clip, centerX)),

          // LEFT: Mute + Cover (belongs to video track)
          if (clips.isNotEmpty)
            Positioned(
              left: centerX - timelineOffset - 120,
              top: 8,
              child: Row(
                children: [
                  _sideButton(
                    Icons.volume_off,
                    'Mute\nclip',
                    () => _showMessage('Mute'),
                  ),
                  const SizedBox(width: 8),
                  _buildCoverButton(),
                ],
              ),
            ),
          Positioned(
            right: 12,
            top: 16,
            child: GestureDetector(
              onTap: () {
                _saveToHistory();
                _addVideo();
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoClip(TimelineItem item, double centerX) {
    final selected = selectedClip == int.tryParse(item.id);
    final startX = item.startTime.inMilliseconds / 1000 * pixelsPerSecond - timelineOffset;
    final width = _clipWidth(item);

    return Positioned(
      left: startX + centerX,
      child: GestureDetector(
        // DRAG TO MOVE CLIP
        onHorizontalDragUpdate: (d) {
          final deltaSec = d.delta.dx / pixelsPerSecond;
          final newStart = item.startTime + Duration(milliseconds: (deltaSec * 1000).round());
          if (newStart >= Duration.zero) {
            setState(() {
              item.startTime = newStart;
              clips.sort((a, b) => a.startTime.compareTo(b.startTime));
            });
            _updatePreview();
          }
        },
        // TAP TO SELECT + HIGHLIGHT
        onTap: () {
          setState(() {
            selectedClip = int.tryParse(item.id);
            playheadPosition = item.startTime + const Duration(milliseconds: 100);
            timelineOffset = playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
          });
          _updatePreview(); // This highlights preview
        },
        child: Container(
          width: width,
          height: 70,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: selected ? Border.all(color: const Color(0xFF00D9FF), width: 3) : null,
            boxShadow: selected
                ? [BoxShadow(color: const Color(0xFF00D9FF).withOpacity(0.4), blurRadius: 12)]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildThumbnailStrip(item),
          ),
        ),
      ),
    );
  }

// Helper to build thumbnail strip for timeline
  Widget _buildThumbnailStrip(TimelineItem item) {
    if (item.thumbnailBytes == null || item.thumbnailBytes!.isEmpty) {
      return Container(color: const Color(0xFF2A2A2A));
    }

    return Row(
      children: List.generate(10, (i) {
        final bytes = item.thumbnailBytes![i % item.thumbnailBytes!.length];
        return Expanded(
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        );
      }),
    );
  }

  Widget _sideButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverButton() {
    // Show current frame from active video controller
    Uint8List? coverBytes;
    if (_activeVideoController != null &&
        _activeVideoController!.value.isInitialized &&
        _activeVideoController!.value.size.width > 100) {
      // We'll use the first thumbnail as cover (closest to current position
      final active = _findActiveVideo();
      if (active != null && active.thumbnailBytes?.isNotEmpty == true) {
        final index =
            ((playheadPosition - active.startTime).inMilliseconds /
                    active.duration.inMilliseconds *
                    active.thumbnailBytes!.length)
                .clamp(0, active.thumbnailBytes!.length - 1)
                .floor();
        coverBytes = active.thumbnailBytes![index];
      }
    }

    return GestureDetector(
      onTap: () => _showCoverSelector(),
      child: Container(
        width: 50,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (coverBytes != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Image.memory(
                  coverBytes,
                  width: 50,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 50,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: const Icon(Icons.photo, size: 18, color: Colors.white),
              ),
            const SizedBox(height: 2),
            const Text(
              'Cover',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  void _showCoverSelector() {
    if (selectedClip == null) {
      _showMessage('Select a clip first');
      return;
    }
    _showMessage('Cover selector');
  }

  Widget _buildAudioTrack() {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: Stack(
        children: [
          ...audioItems.map((audio) => _buildAudioClip(audio, centerX)),
        ],
      ),
    );
  }

  Widget _buildAudioClip(TimelineItem item, double centerX) {
    final selected = selectedClip == int.tryParse(item.id);
    final startX =
        item.startTime.inMilliseconds / 1000 * pixelsPerSecond - timelineOffset;
    final width = _clipWidth(item);

    return Positioned(
      left: startX + centerX,
      child: GestureDetector(
        onTap: () => setState(() => selectedClip = int.tryParse(item.id)),
        onHorizontalDragStart: (_) => _saveToHistory(),
        onHorizontalDragUpdate: (d) {
          final deltaSec = d.delta.dx / pixelsPerSecond;
          final newStart =
              item.startTime +
              Duration(milliseconds: (deltaSec * 1000).round());
          if (newStart >= Duration.zero) {
            setState(() {
              item.startTime = newStart;
              audioItems.sort((a, b) => a.startTime.compareTo(b.startTime));
            });
          }
        },
        child: Container(
          width: width,
          height: 46,
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? const Color(0xFF00D9FF) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Waveform
              if (item.waveformData != null && item.waveformData!.isNotEmpty)
                CustomPaint(painter: WaveformPainter(item.waveformData!)),

              // Audio name overlay
              if (item.text != null && item.text!.isNotEmpty)
                Positioned(
                  left: 4,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      item.text!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayTrack() {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;

    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: Stack(
        children:
            overlayItems
                .map((overlay) => _buildOverlayClip(overlay, centerX))
                .toList(),
      ),
    );
  }

  Widget _buildOverlayClip(TimelineItem item, double centerX) {
    final selected = selectedClip == int.tryParse(item.id);
    final startX =
        item.startTime.inMilliseconds / 1000 * pixelsPerSecond - timelineOffset;
    final width = _clipWidth(item);

    return Positioned(
      left: startX + centerX,
      child: GestureDetector(
        onTap: () => setState(() => selectedClip = int.tryParse(item.id)),
        onHorizontalDragStart: (_) => _saveToHistory(),
        onHorizontalDragUpdate: (d) {
          final deltaSec = d.delta.dx / pixelsPerSecond;
          final newStart =
              item.startTime +
              Duration(milliseconds: (deltaSec * 1000).round());
          if (newStart >= Duration.zero) {
            setState(() {
              item.startTime = newStart;
              overlayItems.sort((a, b) => a.startTime.compareTo(b.startTime));
            });
          }
        },
        child: Container(
          width: width,
          height: 41,
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF9333EA),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? const Color(0xFF00D9FF) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child:
                item.file != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(item.file!, fit: BoxFit.cover),
                    )
                    : const Icon(Icons.image, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildTextTrack() {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;

    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: Stack(
        children:
            textItems.map((text) => _buildTextClip(text, centerX)).toList(),
      ),
    );
  }

  Widget _buildTextClip(TimelineItem item, double centerX) {
    final selected = selectedClip == int.tryParse(item.id);
    final startX =
        item.startTime.inMilliseconds / 1000 * pixelsPerSecond - timelineOffset;
    final width = _clipWidth(item);

    return Positioned(
      left: startX + centerX,
      child: GestureDetector(
        onTap: () => setState(() => selectedClip = int.tryParse(item.id)),
        onHorizontalDragStart: (_) => _saveToHistory(),
        onHorizontalDragUpdate: (d) {
          final deltaSec = d.delta.dx / pixelsPerSecond;
          final newStart =
              item.startTime +
              Duration(milliseconds: (deltaSec * 1000).round());
          if (newStart >= Duration.zero) {
            setState(() {
              item.startTime = newStart;
              textItems.sort((a, b) => a.startTime.compareTo(b.startTime));
            });
          }
        },
        child: Container(
          width: width,
          height: 41,
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? const Color(0xFF00D9FF) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              item.text ?? 'Text',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
        border: Border(top: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _navBtn(Icons.content_cut, 'Edit', _showEditTools),
          _navBtn(Icons.audiotrack, 'Audio', _addAudio),
          _navBtn(Icons.text_fields, 'Text', _addText),
          _navBtn(Icons.auto_awesome, 'Effects', _showEffects),
          _navBtn(Icons.layers, 'Reorder Tracks', _showTrackReordering),
          _navBtn(Icons.filter, 'Filters', _showFilters),
          _navBtn(Icons.animation, 'Animation', _showAnimations),
          _navBtn(Icons.timeline, 'Keyframe', _showKeyframeEditor),
          _navBtn(Icons.swap_horiz, 'Transition', _showTransitions),
          _navBtn(Icons.emoji_emotions, 'Stickers', _showStickers),
          _navBtn(Icons.layers, 'Overlay', _addImage),
          _navBtn(Icons.speed, 'Speed', _showSpeedEditor),
          _navBtn(Icons.volume_up, 'Volume', _showVolumeEditor),
        ],
      ),
    );
  }

  void _showEffects() {
    if (selectedClip == null) {
      _showMessage('Select a clip first');
      return;
    }
    final effects = [
      {'name': 'Glitch', 'icon': Icons.electrical_services},
      {'name': 'Blur', 'icon': Icons.blur_on},
      {'name': 'Sharpen', 'icon': Icons.auto_fix_high},
      {'name': 'Vintage', 'icon': Icons.camera_alt},
      {'name': 'Neon', 'icon': Icons.lightbulb},
      {'name': 'VHS', 'icon': Icons.videocam},
      {'name': 'RGB Split', 'icon': Icons.gradient},
      {'name': 'Pixelate', 'icon': Icons.grid_on},
      {'name': 'Mirror', 'icon': Icons.flip},
      {'name': 'Zoom Blur', 'icon': Icons.zoom_out_map},
      {'name': 'Chromatic', 'icon': Icons.color_lens},
      {'name': 'Glow', 'icon': Icons.wb_sunny},
      // Added more CapCut-inspired effects
      {'name': 'Thunderbolt', 'icon': Icons.flash_on},
      {'name': 'Flicker', 'icon': Icons.invert_colors},
      {'name': 'Slit Lightning', 'icon': Icons.bolt},
      {'name': 'Butterfly', 'icon': Icons.local_florist},
      {'name': 'Pulse Line', 'icon': Icons.show_chart},
      {'name': 'Color Isolation', 'icon': Icons.palette},
      {'name': 'Neon Flash', 'icon': Icons.flashlight_on},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: 500, // Increased height for more effects
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Effects Library',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (selectedEffect != null)
                      TextButton(
                        onPressed: () {
                          setState(() => selectedEffect = null);
                          _showMessage('Effect removed');
                        },
                        child: const Text(
                          'Remove',
                          style: TextStyle(color: Color(0xFF00D9FF)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: effects.length,
                    itemBuilder: (context, index) {
                      final effect = effects[index];
                      final isSelected = selectedEffect == effect['name'];
                      return GestureDetector(
                        onTap: () {
                          setState(
                            () => selectedEffect = effect['name'] as String,
                          );
                          Navigator.pop(context);
                          _showMessage('Effect: ${effect['name']} applied');
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? const Color(0xFF00D9FF)
                                        : const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? const Color(0xFF00D9FF)
                                          : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                effect['icon'] as IconData,
                                color: isSelected ? Colors.black : Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              effect['name'] as String,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? const Color(0xFF00D9FF)
                                        : Colors.white70,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

   void _showFilters() {
    if (selectedClip == null) {
      _showMessage('Select a clip first');
      return;
    }
    final filters = [
      'None',
      'Vivid',
      'Warm',
      'Cool',
      'B&W',
      'Sepia',
      'Cinematic',
      'Sunset',
      'Arctic',
      'Urban',
      'Retro',
      'Moody',
      'Bright',
      'Fade',
      'Contrast',
      'Soft',
    ];
    String tempFilter = selectedFilter ?? 'None';
    double tempIntensity = filterIntensity;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setM) => Container(
                  height: 450,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: filters.length,
                          itemBuilder: (context, index) {
                            final filter = filters[index];
                            final isSelected = tempFilter == filter;
                            return GestureDetector(
                              onTap: () => setM(() => tempFilter = filter),
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A2A2A),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? const Color(0xFF00D9FF)
                                                  : Colors.transparent,
                                          width: 3,
                                        ),
                                        gradient: LinearGradient(
                                          colors: [
                                            Color.fromARGB(
                                              255,
                                              (index * 30 + 100).clamp(0, 255),
                                              (index * 20 + 80).clamp(0, 255),
                                              (index * 40 + 120).clamp(0, 255),
                                            ),
                                            Color.fromARGB(
                                              255,
                                              (index * 40 + 80).clamp(0, 255),
                                              (index * 30 + 100).clamp(0, 255),
                                              (index * 20 + 90).clamp(0, 255),
                                            ),
                                          ],
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          filter[0],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      filter,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? const Color(0xFF00D9FF)
                                                : Colors.white70,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Intensity',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: tempIntensity,
                              min: 0,
                              max: 1,
                              divisions: 10,
                              activeColor: const Color(0xFF00D9FF),
                              onChanged: (v) => setM(() => tempIntensity = v),
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${(tempIntensity * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A2A2A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedFilter = tempFilter;
                                  filterIntensity = tempIntensity;
                                });
                                Navigator.pop(ctx);
                                _showMessage('Filter: $tempFilter applied');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D9FF),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showAnimations() {
    if (selectedClip == null) {
      _showMessage('Select a clip first');
      return;
    }
    final animations = [
      {'name': 'Fade In', 'icon': Icons.blur_on},
      {'name': 'Fade Out', 'icon': Icons.blur_off},
      {'name': 'Slide Left', 'icon': Icons.arrow_back},
      {'name': 'Slide Right', 'icon': Icons.arrow_forward},
      {'name': 'Slide Up', 'icon': Icons.arrow_upward},
      {'name': 'Slide Down', 'icon': Icons.arrow_downward},
      {'name': 'Zoom In', 'icon': Icons.zoom_in},
      {'name': 'Zoom Out', 'icon': Icons.zoom_out},
      {'name': 'Rotate', 'icon': Icons.rotate_right},
      {'name': 'Bounce', 'icon': Icons.sports_basketball},
      {'name': 'Shake', 'icon': Icons.vibration},
      {'name': 'Pop', 'icon': Icons.bubble_chart},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: 450,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Animations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add smooth animations to your clips',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: animations.length,
                    itemBuilder: (context, index) {
                      final animation = animations[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showMessage(
                            '${animation['name']} animation applied',
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                animation['icon'] as IconData,
                                color: const Color(0xFF00D9FF),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              animation['name'] as String,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showTransitions() {
    final transitions = [
      {'name': 'Dissolve', 'icon': Icons.blur_circular},
      {'name': 'Wipe', 'icon': Icons.swipe},
      {'name': 'Slide', 'icon': Icons.view_carousel},
      {'name': 'Zoom', 'icon': Icons.zoom_out_map},
      {'name': 'Fade', 'icon': Icons.gradient},
      {'name': 'Blur', 'icon': Icons.blur_on},
      {'name': 'Push', 'icon': Icons.push_pin},
      {'name': 'Iris', 'icon': Icons.camera},
      {'name': 'Spin', 'icon': Icons.rotate_90_degrees_ccw},
      {'name': 'Cube', 'icon': Icons.view_in_ar},
      {'name': 'Flip', 'icon': Icons.flip_camera_android},
      {'name': 'Glitch', 'icon': Icons.broken_image},
    ];
    double duration = 0.5;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setM) => Container(
                  height: 500,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transitions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Smoothly join your clips',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: transitions.length,
                          itemBuilder: (context, index) {
                            final transition = transitions[index];
                            return GestureDetector(
                              onTap: () {
                                _showMessage(
                                  '${transition['name']} transition added',
                                );
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2A2A),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      transition['icon'] as IconData,
                                      color: const Color(0xFF00D9FF),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    transition['name'] as String,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Duration',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: duration,
                              min: 0.1,
                              max: 3.0,
                              divisions: 29,
                              activeColor: const Color(0xFF00D9FF),
                              onChanged: (v) => setM(() => duration = v),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              '${duration.toStringAsFixed(1)}s',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showStickers() {
    final stickers = [
      {'emoji': '😀', 'name': 'Happy'},
      {'emoji': '😎', 'name': 'Cool'},
      {'emoji': '🎉', 'name': 'Party'},
      {'emoji': '❤️', 'name': 'Love'},
      {'emoji': '⭐', 'name': 'Star'},
      {'emoji': '🔥', 'name': 'Fire'},
      {'emoji': '💯', 'name': '100'},
      {'emoji': '👍', 'name': 'Like'},
      {'emoji': '🎵', 'name': 'Music'},
      {'emoji': '📸', 'name': 'Camera'},
      {'emoji': '✨', 'name': 'Sparkle'},
      {'emoji': '🌈', 'name': 'Rainbow'},
      {'emoji': '🚀', 'name': 'Rocket'},
      {'emoji': '💡', 'name': 'Idea'},
      {'emoji': '🎬', 'name': 'Film'},
      {'emoji': '🌟', 'name': 'Glowing'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: 450,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stickers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add animated stickers to your video',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    itemCount: stickers.length,
                    itemBuilder: (context, index) {
                      final sticker = stickers[index];
                      return GestureDetector(
                        onTap: () {
                          _addSticker(sticker['emoji']!);
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              sticker['emoji']!,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _addSticker(String emoji) {
    final item = TimelineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TimelineItemType.text,
      text: emoji,
      startTime: playheadPosition,
      duration: const Duration(seconds: 3),
      originalDuration: const Duration(seconds: 3),
      x: 150,
      y: 200,
      fontSize: 60,
      layerIndex: _nextLayerIndex++,
    );
    setState(() {
      textItems.add(item);
      textItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      selectedClip = int.parse(item.id);
      playheadPosition = item.startTime;
      timelineOffset = playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
    });
    _showMessage('Sticker added');
  }

  void _showKeyframeEditor() {
    TimelineItem? item = getSelectedItem();
    if (item == null ||
        (item.type != TimelineItemType.text &&
            item.type != TimelineItemType.image)) {
      _showMessage('Select a text or overlay to add keyframe');
      return;
    }
    double tempEndX = item.endX ?? (item.x ?? 0);
    double tempEndY = item.endY ?? (item.y ?? 0);
    double tempEndScale = item.endScale ?? item.scale;
    double tempEndRotation = item.endRotation ?? item.rotation;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setM) => Container(
                  height: 400,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Keyframe Editor (End Values)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('End X: ${tempEndX.toStringAsFixed(2)}'),
                      Slider(
                        value: tempEndX,
                        min: 0,
                        max: 500,
                        onChanged: (v) => setM(() => tempEndX = v),
                      ),
                      Text('End Y: ${tempEndY.toStringAsFixed(2)}'),
                      Slider(
                        value: tempEndY,
                        min: 0,
                        max: 500,
                        onChanged: (v) => setM(() => tempEndY = v),
                      ),
                      Text('End Scale: ${tempEndScale.toStringAsFixed(2)}'),
                      Slider(
                        value: tempEndScale,
                        min: 0.5,
                        max: 3.0,
                        onChanged: (v) => setM(() => tempEndScale = v),
                      ),
                      Text(
                        'End Rotation: ${tempEndRotation.toStringAsFixed(2)}',
                      ),
                      Slider(
                        value: tempEndRotation,
                        min: -360,
                        max: 360,
                        onChanged: (v) => setM(() => tempEndRotation = v),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            item!.endX = tempEndX;
                            item.endY = tempEndY;
                            item.endScale = tempEndScale;
                            item.endRotation = tempEndRotation;
                          });
                          Navigator.pop(ctx);
                          _showMessage('Keyframe applied');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showVolumeEditor() {
    if (selectedClip == null) return;
    TimelineItem? item = getSelectedItem();
    if (item == null) return;
    double temp = item.volume;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setM) => Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Volume',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${(temp * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      Slider(
                        value: temp,
                        min: 0,
                        max: 2,
                        divisions: 20,
                        activeColor: const Color(0xFF00D9FF),
                        onChanged: (v) => setM(() => temp = v),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => item!.volume = temp);
                          Navigator.pop(ctx);
                          _showMessage('Volume: ${(temp * 100).toInt()}%');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _navBtn(IconData icon, String label, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationRulerPainter extends CustomPainter {
  final double totalSeconds, visibleSeconds, offsetSeconds, pixelsPerSecond;
  final String Function(Duration) formatTime;

  _DurationRulerPainter({
    required this.totalSeconds,
    required this.visibleSeconds,
    required this.offsetSeconds,
    required this.pixelsPerSecond,
    required this.formatTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white24;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (
      double s = (offsetSeconds - visibleSeconds / 2).floorToDouble();
      s <= (offsetSeconds + visibleSeconds / 2).ceilToDouble();
      s += 0.5
    ) {
      if (s < 0 || s > totalSeconds) continue;

      final x = (s - offsetSeconds) * pixelsPerSecond + size.width / 2;

      if (s % 1 == 0) {
        canvas.drawLine(Offset(x, 24), Offset(x, 36), paint);
        textPainter.text = TextSpan(
          text: formatTime(Duration(seconds: s.toInt())),
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, 6));
      } else {
        canvas.drawLine(Offset(x, 28), Offset(x, 36), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
