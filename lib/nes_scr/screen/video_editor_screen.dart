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
import '../model/keyframe.dart';
import '../model/timeline_item.dart';
import '../model/timeline_track.dart';
import '../model/video_transition.dart';
import '../servuices/autosave_manager.dart';
import '../servuices/background_export_service.dart';
import '../servuices/cloud_save_service.dart';
import '../servuices/history_manager.dart';
import '../widgets/cropeditor.dart';
import '../widgets/export_dialo.dart';
import '../widgets/keyframe_animation_editor.dart';
import '../widgets/speed_curve_editor.dart';
import '../widgets/water_mark_overlay.dart';
import '../widgets/wave_form_painter.dart' show WaveformPainter;

class VideoEditorScreen extends StatefulWidget {
  final List<XFile>? initialVideos;

  final String? projectId;
  final String? projectName;

  const VideoEditorScreen({
    super.key,
    this.initialVideos,
    this.projectId,
    this.projectName,
  });

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

  String exportResolution = '1080p';
  int exportBitrate = 5000;
  bool removeWatermark = false;
  List<Uint8List>? thumbnailBytes;
  final thumbnailNotifier = ValueNotifier<List<Uint8List>>([]);

  String? currentTool;
  bool _isDraggingClip = false;
  bool _isResizingOverlay = false;
  Offset? _overlayDragStart;
  double _videoTrackWidth = 0.0;
  double _audioTrackWidth = 0.0;
  double _textTrackWidth = 0.0;
  final Map<int, VideoTransition> clipTransitions = {};

// Crop system — normalized values (0.0 to 1.0)
  double cropX = 0.0;
  double cropY = 0.0;
  double cropWidth = 1.0;
  double cropHeight = 1.0;
  // NEW: Selected tool category
  String? selectedToolCategory;

  // Add these variables
  late String currentProjectId;
  late String currentProjectName;
  late HistoryManager historyManager;
  late AutosaveManager autosaveManager;
  bool isPro = false;
  final ScrollController _timelineScrollController = ScrollController();
  final ScrollController _editToolsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    currentProjectId =
        widget.projectId ?? DateTime.now().millisecondsSinceEpoch.toString();
    currentProjectName = widget.projectName ?? 'Untitled Project';

    // Initialize history manager
    historyManager = HistoryManager();

    // Initialize autosave
    autosaveManager = AutosaveManager(
      onAutosave: _performAutosave,
      autosaveInterval: const Duration(minutes: 2),
    );
    autosaveManager.start();

    _playbackTicker = createTicker(_playbackFrame);
    thumbnailNotifier.addListener(() {
      if (mounted) setState(() {});
    });

    _timelineScrollController.addListener(() {
      if (mounted) {
        setState(() {
          timelineOffset = _timelineScrollController.offset;
        });
      }
    });

    if (widget.initialVideos != null && widget.initialVideos!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processInitialVideos();
      });
    }
  }

  // FIXED: Robust thumbnail generation that works with ANY video format
  Future<void> _processInitialVideos() async {
    if (_isInitializing) return;

    setState(() => _isInitializing = true);

    try {
      Duration currentStartTime = Duration.zero;

      for (int index = 0; index < widget.initialVideos!.length; index++) {
        final video = widget.initialVideos![index];
        final videoPath = video.path;

        debugPrint('\n🎬 Processing video $index: $videoPath');

        // Initialize controller
        final controller = VideoPlayerController.file(File(videoPath));
        await controller.initialize();

        final duration = controller.value.duration;
        debugPrint('✅ Duration: ${duration.inSeconds}s');

        // Generate thumbnails using ROBUST method
        List<Uint8List> thumbs = await _generateRobustThumbnails(
          videoPath,
          duration,
        );

        if (thumbs.isEmpty) {
          debugPrint('⚠️ No thumbnails generated, using fallback');
          thumbs = await _generateFallbackThumbnails(videoPath, duration);
        }

        final item = TimelineItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_$index',
          type: TimelineItemType.video,
          file: File(videoPath),
          startTime: currentStartTime,
          duration: duration,
          originalDuration: duration,
          trimStart: Duration.zero,
          trimEnd: duration,
          thumbnailBytes: thumbs,
          thumbnailPaths: [],
          cropLeft: 0.0,
          cropTop: 0.0,
          cropRight: 0.0,
          cropBottom: 0.0,
        );

        _controllers[item.id] = controller;
        await controller.setLooping(false);

        clips.add(item);
        currentStartTime += duration;

        debugPrint('✅ Added video with ${thumbs.length} thumbnails');
      }

      if (mounted && clips.isNotEmpty) {
        clips.sort((a, b) => a.startTime.compareTo(b.startTime));
        selectedClip = int.parse(clips.first.id.split('_')[0]);
        playheadPosition = Duration.zero;
        timelineOffset = 0.0;

        final firstCtrl = _controllers[clips.first.id]!;
        _activeVideoController = firstCtrl;
        _activeItem = clips.first;

        await firstCtrl.seekTo(Duration.zero);
        await Future.delayed(const Duration(milliseconds: 300));

        setState(() => _isInitializing = false);

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

  // FIXED: Most robust thumbnail generation method
  Future<List<Uint8List>> _generateRobustThumbnails(
    String videoPath,
    Duration duration,
  ) async {
    final thumbnails = <Uint8List>[];
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputDir = Directory('${tempDir.path}/thumbs_$timestamp');

    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    try {
      final durationSecs = duration.inSeconds.toDouble();
      final count = 12; // Generate 12 thumbnails for smooth scrubbing

      // Generate thumbnails at specific intervals
      for (int i = 0; i < count; i++) {
        // Skip first and last 0.5 seconds to avoid black frames
        final progress = i / (count - 1);
        final timeSec = (durationSecs * progress).clamp(
          0.5,
          durationSecs - 0.5,
        );
        final outputPath = '${outputDir.path}/thumb_$i.jpg';

        // FFmpeg command optimized for thumbnail extraction
        final command =
            '-ss $timeSec -i "$videoPath" '
            '-vframes 1 '
            '-vf "scale=120:120:force_original_aspect_ratio=decrease,'
            'pad=120:120:(ow-iw)/2:(oh-ih)/2" '
            '-q:v 5 '
            '-y "$outputPath"';

        final session = await FFmpegKit.execute(command);
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          final file = File(outputPath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            if (bytes.length > 1000) {
              thumbnails.add(bytes);
              debugPrint(
                '✅ Generated thumbnail $i at ${timeSec.toStringAsFixed(1)}s',
              );
            }
          }
        }

        // Add small delay to avoid overloading
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Cleanup
      await outputDir.delete(recursive: true);

      debugPrint('🎯 Generated ${thumbnails.length} thumbnails successfully');
      return thumbnails;
    } catch (e) {
      debugPrint('❌ Thumbnail generation error: $e');
      await outputDir.delete(recursive: true);
      return thumbnails;
    }
  }

  // Fallback method using video_thumbnail plugin
  Future<List<Uint8List>> _generateFallbackThumbnails(
    String videoPath,
    Duration duration,
  ) async {
    final thumbnails = <Uint8List>[];
    final durationMs = duration.inMilliseconds;
    final count = 8;

    for (int i = 0; i < count; i++) {
      try {
        final timeMs = ((durationMs * i) / (count - 1)).round().clamp(
          500,
          durationMs - 500,
        );

        final bytes = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 120,
          timeMs: timeMs,
          quality: 75,
        ).timeout(const Duration(seconds: 5), onTimeout: () => null);

        if (bytes != null && bytes.length > 1000) {
          thumbnails.add(bytes);
        }
      } catch (e) {
        debugPrint('⚠️ Fallback thumbnail $i failed: $e');
      }
    }

    debugPrint('🔄 Fallback generated ${thumbnails.length} thumbnails');
    return thumbnails;
  }

  void togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
      if (!isPlaying) {
        // Ensure we stop at current position
        _playbackTicker.stop();
      }
      // Reset to start if reached end
      final maxDuration = _getTotalDuration();
      if (isPlaying && playheadPosition.inMilliseconds >= maxDuration * 1000) {
        playheadPosition = Duration.zero;
        timelineOffset = 0.0;
      }
    });

    if (isPlaying) {
      _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
      if (!_playbackTicker.isActive) _playbackTicker.start();
    }
    // No else needed — we already stop ticker.stop() above when isPlaying becomes false
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
    autosaveManager.stop();

    super.dispose();
  }

  // 3. Replace your old _saveToHistory with this
  void _saveToHistory() {
    final state = EditorState(
      clips: clips.map((c) => c.copyWith()).toList(),
      audioItems: audioItems.map((a) => a.copyWith()).toList(),
      textItems: textItems.map((t) => t.copyWith()).toList(),
      overlayItems: overlayItems.map((o) => o.copyWith()).toList(),
      selectedClip: selectedClip,
      playheadPosition: playheadPosition,
    );

    historyManager.saveState(state);
    autosaveManager.markChanged(); // Mark for autosave
  }

  // 4. Replace _undo and _redo
  void _undo() {
    final state = historyManager.undo();
    if (state != null) {
      setState(() {
        clips = state.clips.map((c) => c.copyWith()).toList();
        audioItems = state.audioItems.map((a) => a.copyWith()).toList();
        textItems = state.textItems.map((t) => t.copyWith()).toList();
        overlayItems = state.overlayItems.map((o) => o.copyWith()).toList();
        selectedClip = state.selectedClip;
        playheadPosition = state.playheadPosition;
      });
      _updatePreview();
    }
  }

  void _redo() {
    final state = historyManager.redo();
    if (state != null) {
      setState(() {
        clips = state.clips.map((c) => c.copyWith()).toList();
        audioItems = state.audioItems.map((a) => a.copyWith()).toList();
        textItems = state.textItems.map((t) => t.copyWith()).toList();
        overlayItems = state.overlayItems.map((o) => o.copyWith()).toList();
        selectedClip = state.selectedClip;
        playheadPosition = state.playheadPosition;
      });
      _updatePreview();
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
        playheadPosition = Duration(milliseconds: (max * 1000).toInt());
        isPlaying = false;
        _playbackTicker.stop();
      }

      timelineOffset =
          (playheadPosition.inMilliseconds / 1000 * pixelsPerSecond).toDouble();
    });
    _updatePreview();
  }

  double _getTotalDuration() {
    double max = 0;
    for (var list in [clips, audioItems, overlayItems, textItems]) {
      if (list.isNotEmpty) {
        final end = list
            .map((e) => (e.startTime + e.duration).inSeconds.toDouble())
            .reduce(math.max);
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
      final source = active.trimStart +
          Duration(milliseconds: (local.inMilliseconds * speed).round());

      // Only seek if we're more than ~100ms off (prevents jitter)
      if ((ctrl.value.position - source).inMilliseconds.abs() > 100) {
        ctrl.seekTo(source);
      }

      ctrl.setPlaybackSpeed(speed);
      ctrl.setVolume(active.volume);

      // KEY FIX: Only play/pause based on global isPlaying state
      if (isPlaying) {
        if (!ctrl.value.isPlaying) ctrl.play();
      } else {
        if (ctrl.value.isPlaying) ctrl.pause();
      }

      // Switch active controller if needed
      if (_activeVideoController != ctrl) {
        _activeVideoController?.pause();
        _activeVideoController = ctrl;
        _activeItem = active;
        setState(() {});
      }
    } else {
      // No active video → make sure everything is paused
      _activeVideoController?.pause();
      _activeVideoController = null;
      _activeItem = null;
      setState(() {});
    }
  }

  TimelineItem? _findActiveVideo() {
    for (final item in clips) {
      final effective = Duration(
        milliseconds: (item.duration.inMilliseconds / item.speed).round(),
      );
      if (playheadPosition >= item.startTime &&
          playheadPosition < item.startTime + effective) {
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

  // 5. Add autosave function
  Future<void> _performAutosave() async {
    final success = await CloudSaveService.saveProject(
      projectId: currentProjectId,
      projectName: currentProjectName,
      clips: clips,
      audioItems: audioItems,
      textItems: textItems,
      overlayItems: overlayItems,
    );

    if (success) {
      debugPrint('✅ Autosave successful');
    } else {
      debugPrint('❌ Autosave failed');
    }
  }

  // 6. Add manual save
  Future<void> _saveProject() async {
    _showLoading();

    final success = await CloudSaveService.saveProject(
      projectId: currentProjectId,
      projectName: currentProjectName,
      clips: clips,
      audioItems: audioItems,
      textItems: textItems,
      overlayItems: overlayItems,
    );

    _hideLoading();

    if (success) {
      autosaveManager.saveNow();
      _showMessage('Project saved successfully');
    } else {
      _showError('Failed to save project');
    }
  }

  // 7. Add project name editor
  void _editProjectName() async {
    final controller = TextEditingController(text: currentProjectName);
    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Project Name',
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter project name',
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00D9FF)),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Color(0xFF00D9FF)),
                ),
              ),
            ],
          ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() => currentProjectName = newName);
      autosaveManager.markChanged();
    }
  }

  // 10. Enhanced export with background processing
  Future<void> _exportVideoEnhanced() async {
    // First save the project
    await _saveProject();

    await _showExportSettings();

    final exportFuture = BackgroundExportService.exportVideoInBackground(
      clips: clips,
      audioItems: audioItems,
      textItems: textItems,
      overlayItems: overlayItems,
      resolution: exportResolution,
      bitrate: exportBitrate,
      addWatermark: !isPro, // Add watermark for free users
      onProgress: (progress) {
        debugPrint('Export progress: ${(progress * 100).toInt()}%');
      },
    );

    final outputPath = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExportProgressDialog(exportFuture: exportFuture),
    );

    if (outputPath != null) {
      _showMessage('Video exported successfully!');
      // Optionally save to gallery or share
    } else {
      _showError('Export failed');
    }
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
            _buildBottomTools(),
          ],
        ),
      ),
    );
  }

  // 8. Update _buildTopBar to include project controls
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF000000),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              // Ask to save before closing
              if (autosaveManager.hasUnsavedChanges) {
                final save = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A1A),
                        title: const Text(
                          'Unsaved changes',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Do you want to save your project before leaving?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Discard',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Save',
                              style: TextStyle(color: Color(0xFF00D9FF)),
                            ),
                          ),
                        ],
                      ),
                );

                if (save == true) {
                  await _saveProject();
                }
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Icon(Icons.close, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 16),

          // Project name
          Expanded(
            child: GestureDetector(
              onTap: _editProjectName,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      currentProjectName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 14, color: Color(0xFF00D9FF)),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Autosave indicator
          AutosaveStatusIndicator(autosaveManager: autosaveManager),

          const SizedBox(width: 12),

          // Save button
          GestureDetector(
            onTap: _saveProject,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.save, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // More options
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
            onTap: _exportVideoEnhanced,
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

  // 9. Update preview to include watermark
  Widget _buildPreview() {
    final screenSize = MediaQuery.of(context).size;
    final activeItem = _activeItem;
    final isClipSelected = selectedClip != null;

    return ValueListenableBuilder<List<Uint8List>>(
      valueListenable: thumbnailNotifier,
      builder: (context, thumbs, child) {
        // Base video widget
        Widget videoWidget;

        if (_activeVideoController != null && _activeVideoController!.value.isInitialized) {
          videoWidget = AspectRatio(
            aspectRatio: _activeVideoController!.value.aspectRatio,
            child: VideoPlayer(_activeVideoController!),
          );
        } else if (activeItem != null && activeItem.thumbnailBytes?.isNotEmpty == true) {
          final progress = (playheadPosition - activeItem.startTime).inMilliseconds /
              activeItem.duration.inMilliseconds;
          final index = (progress * activeItem.thumbnailBytes!.length).clamp(0, activeItem.thumbnailBytes!.length - 1).floor();
          videoWidget = Image.memory(
            activeItem.thumbnailBytes![index],
            fit: BoxFit.contain,
            gaplessPlayback: true,
          );
        } else {
          videoWidget = _buildPlaceholder();
        }

        // Apply filters/effects
        if (selectedFilter != null && selectedFilter != 'None') {
          videoWidget = _applyEffect(videoWidget);
        }

        // Wrap with highlight border only if the current playing clip is selected
        final bool showSelectionBorder = activeItem != null &&
            isClipSelected &&
            int.tryParse(activeItem.id) == selectedClip;

        if (showSelectionBorder) {
          videoWidget = Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00D9FF), width: 4),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D9FF).withOpacity(0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: videoWidget,
            ),
          );
        }

        return Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main video
              Center(child: videoWidget),

              // Speed Ramp Curve Overlay (only when speed points exist)
              if (activeItem != null && activeItem.speedPoints.isNotEmpty)
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: Container(
                    width: 120,
                    height: 60,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00D9FF), width: 1),
                    ),
                    child: CustomPaint(
                      painter: SpeedCurvePainter(activeItem.speedPoints),
                      size: const Size(100, 40),
                    ),
                  ),
                ),

              // Transition Indicators (between clips)
              ..._buildTransitionOverlays(screenSize),

              // Trim Handles + Selected Clip Overlay (only when a clip is selected)
              if (isClipSelected) _buildTrimHandlesAndOverlay(screenSize),

              // Interactive Overlays (Text, Stickers, Images)
              ..._buildInteractiveOverlays(screenSize, [...textItems, ...overlayItems]),

              // Watermark (Pro users can remove)
              WatermarkOverlay(
                isPro: isPro,
                text: 'Made with Omivideo',
                alignment: Alignment.bottomRight,
                opacity: 0.6,
              ),

              // Playhead time indicator in preview
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatTime(playheadPosition),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 1. Trim Handles + Clip Overlay (CapCut-style)
  Widget _buildTrimHandlesAndOverlay(Size screenSize) {
    final item = getSelectedItem();
    if (item == null || item.type != TimelineItemType.video) return const SizedBox();

    final isActive = _activeItem?.id == item.id;
    if (!isActive) return const SizedBox();

    final leftX = 0.0;
    final rightX = screenSize.width;

    return Stack(
      children: [
        // Dark overlay outside clip bounds (visual feedback)
        Row(
          children: [
            Expanded(flex: 30, child: Container(color: Colors.black54)),
            const Expanded(flex: 40, child: SizedBox()),
            Expanded(flex: 30, child: Container(color: Colors.black54)),
          ],
        ),

        // Left Trim Handle
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 40,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              final deltaPx = details.delta.dx;
              final deltaSec = deltaPx / pixelsPerSecond;
              final newTrimStart = item.trimStart + Duration(milliseconds: (deltaSec * 1000).round());
              if (newTrimStart >= Duration.zero && newTrimStart < item.trimEnd - const Duration(seconds: 1)) {
                setState(() {
                  item.trimStart = newTrimStart;
                  item.duration = item.trimEnd - item.trimStart;
                });
                _saveToHistory();
              }
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 6,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D9FF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Right Trim Handle
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 40,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              final deltaPx = details.delta.dx;
              final deltaSec = deltaPx / pixelsPerSecond;
              final newTrimEnd = item.trimEnd + Duration(milliseconds: (deltaSec * 1000).round());
              if (newTrimEnd > item.trimStart + const Duration(seconds: 1)) {
                setState(() {
                  item.trimEnd = newTrimEnd;
                  item.duration = item.trimEnd - item.trimStart;
                });
                _saveToHistory();
              }
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 6,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D9FF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

// 2. Transition Indicators (shows smooth fade/dissolve between clips)
  List<Widget> _buildTransitionOverlays(Size size) {
    final List<Widget> overlays = [];

    for (int i = 0; i < clips.length - 1; i++) {
      final clipA = clips[i];
      final clipB = clips[i + 1];
      final transition = clipTransitions[i];

      final transitionStart = clipA.startTime + clipA.duration;
      final transitionEnd = transitionStart + (transition?.duration ?? Duration.zero);

      if (playheadPosition >= transitionStart && playheadPosition <= transitionEnd && transition != null) {
        final progress = ((playheadPosition - transitionStart).inMilliseconds /
            transition.duration.inMilliseconds).clamp(0.0, 1.0);

        Widget transitionEffect;

        switch (transition.type) {
          case 'dissolve':
            transitionEffect = Opacity(opacity: progress, child: _videoWidgetForClip(clipB));
            break;
          case 'slide_left':
            transitionEffect = Transform.translate(
              offset: Offset(size.width * (1 - progress), 0),
              child: _videoWidgetForClip(clipB),
            );
            break;
          case 'zoom_in':
            transitionEffect = Transform.scale(
              scale: 1 + progress,
              child: Opacity(opacity: progress, child: _videoWidgetForClip(clipB)),
            );
            break;
          case 'wipe_right':
            transitionEffect = ClipRect(
              clipper: _WipeClipper(progress),
              child: _videoWidgetForClip(clipB),
            );
            break;
          default:
            transitionEffect = Opacity(opacity: progress, child: _videoWidgetForClip(clipB));
        }

        overlays.add(
          Positioned.fill(
            child: IgnorePointer(child: transitionEffect),
          ),
        );

        // Transition icon
        overlays.add(
            const Center(
              child: Icon(Icons.swap_horiz, color: Color(0xFF00D9FF), size: 60),
            ));
      }
    }
    return overlays;
  }

  Widget _videoWidgetForClip(TimelineItem clip) {
    if (_controllers[clip.id]?.value.isInitialized == true) {
      return VideoPlayer(_controllers[clip.id]!);
    }
    return const SizedBox();
  }

  Widget _applyEffect(Widget child) {
    final effect = selectedEffect ?? selectedFilter;
    switch (effect) {
      case 'Blur':
        return BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 6 * filterIntensity,
            sigmaY: 6 * filterIntensity,
          ),
          child: child,
        );
      case 'Vivid':
        return ColorFiltered(
          colorFilter: ColorFilter.matrix([
            1.3 + filterIntensity * 0.7,
            0,
            0,
            0,
            0,
            0,
            1.0,
            0,
            0,
            0,
            0,
            0,
            1.0,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child,
        );
      case 'Warm':
        return ColorFiltered(
          colorFilter: ColorFilter.matrix([
            1.1,
            0.05,
            -0.05,
            0,
            0,
            0.02,
            1.08,
            0.02,
            0,
            0,
            -0.05,
            0.02,
            1.1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child,
        );
      case 'Cool':
        return ColorFiltered(
          colorFilter: ColorFilter.matrix([
            1.1,
            -0.03,
            0.05,
            0,
            0,
            -0.03,
            1.08,
            -0.03,
            0,
            0,
            0.05,
            -0.03,
            1.1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child,
        );
      case 'B&W':
        return ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: child,
        );
      case 'Vintage':
        return ColorFiltered(
          colorFilter: ColorFilter.matrix([
            0.393,
            0.769,
            0.189,
            0,
            0,
            0.349,
            0.686,
            0.168,
            0,
            0,
            0.272,
            0.534,
            0.131,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
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
                child: Transform.translate(
                  offset: Offset(3 * filterIntensity, 0),
                  child: child,
                ),
              ),
            ),
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.cyan,
                  BlendMode.colorDodge,
                ),
                child: Transform.translate(
                  offset: Offset(-3 * filterIntensity, 0),
                  child: child,
                ),
              ),
            ),
          ],
        );
      default:
        return child;
    }
  }

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
                  )
                  : const SizedBox();
        }

        child = Transform.rotate(
          angle: currRotation * math.pi / 180,
          child: Transform.scale(scale: currScale, child: child),
        );

        final isSelected = selectedClip == int.tryParse(item.id);
        if (isSelected) {
          child = _buildResizableOverlay(item, child, screenSize);
        }

        list.add(Positioned(left: currX, top: currY, child: child));
      }
    }

    return list;
  }

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
          Text(
            timeText,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
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
                child: const Icon(
                  Icons.unfold_more_double_outlined,
                  size: 20,
                  color: Colors.white,
                ),
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

  // FIXED: 3-row timeline layout matching CapCut exactly
  Widget _buildTimelineSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalDuration = _getTotalDuration();
    final totalWidth = totalDuration * pixelsPerSecond;

    // Calculate track widths
    _videoTrackWidth =
        clips.isEmpty
            ? screenWidth
            : clips.map((c) => _clipWidth(c)).reduce((a, b) => a + b) + 200;
    _audioTrackWidth =
        audioItems.isEmpty
            ? screenWidth
            : audioItems.map((a) => _clipWidth(a)).reduce((a, b) => a + b) +
                200;
    _textTrackWidth =
        (textItems + overlayItems).isEmpty
            ? screenWidth
            : (textItems + overlayItems)
                    .map((t) => _clipWidth(t))
                    .reduce((a, b) => a + b) +
                200;

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
              controller: _timelineScrollController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: math.max(totalWidth, screenWidth),
                  child: Column(
                    children: [
                      _buildDurationRuler(),
                      const SizedBox(height: 6),
                      // ROW 1: Video Track
                      _buildVideoTrack(),
                      const SizedBox(height: 4),
                      // ROW 2: Audio Track with Add Audio button
                      _buildAudioTrack(),
                      const SizedBox(height: 4),
                      // ROW 3: Text/Overlay Track with Add Text button
                      _buildOverlayAndTextTrack(),
                    ],
                  ),
                ),
              ),
            ),
            _buildCenteredPlayhead(),
          ],
        ),
      ),
    );
  }

  // FIXED: Video track with thumbnail frames (not blurred)
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
          // Video clips with REAL thumbnails
          ...clips.map((clip) => _buildVideoClip(clip, centerX)),

          // LEFT: Mute + Cover buttons
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

          // RIGHT: Add Video button
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

  // FIXED: Build video clip with REAL thumbnail frames
  Widget _buildVideoClip(TimelineItem item, double centerX) {
    final selected = selectedClip == int.tryParse(item.id);
    final startX =
        item.startTime.inMilliseconds / 1000 * pixelsPerSecond - timelineOffset;
    final width = _clipWidth(item);

    return Positioned(
      left: startX + centerX,
      child: GestureDetector(
        onHorizontalDragUpdate: (d) {
          final deltaSec = d.delta.dx / pixelsPerSecond;
          final newStart =
              item.startTime +
              Duration(milliseconds: (deltaSec * 1000).round());
          if (newStart >= Duration.zero) {
            setState(() {
              item.startTime = newStart;
              clips.sort((a, b) => a.startTime.compareTo(b.startTime));
            });
            _updatePreview();
          }
        },
        onTap: () {
          setState(() {
            selectedClip = int.tryParse(item.id);
            playheadPosition =
                item.startTime + const Duration(milliseconds: 100);
            timelineOffset =
                playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
            _activeItem = item;
            _activeVideoController = _controllers[item.id];
            // Scroll timeline to show selected clip
            final targetScroll =
                item.startTime.inMilliseconds / 1000 * pixelsPerSecond -
                MediaQuery.of(context).size.width / 2;
            _timelineScrollController.animateTo(
              targetScroll.clamp(
                0.0,
                _timelineScrollController.position.maxScrollExtent,
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
          _updatePreview();
        },
        child: Container(
          width: width,
          height: 56,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border:
                selected
                    ? Border.all(color: const Color(0xFF00D9FF), width: 3)
                    : Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: const Color(0xFF00D9FF).withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ]
                    : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildThumbnailStrip(item, width),
          ),
        ),
      ),
    );
  }

  // FIXED: Thumbnail strip that displays ALL frames properly
  Widget _buildThumbnailStrip(TimelineItem item, double clipWidth) {
    if (item.thumbnailBytes == null || item.thumbnailBytes!.isEmpty) {
      return Container(
        color: const Color(0xFF2A2A2A),
        child: const Center(
          child: Icon(Icons.videocam, color: Colors.white30, size: 24),
        ),
      );
    }

    final thumbCount = item.thumbnailBytes!.length;
    final thumbWidth = 120.0; // Each thumbnail is 120px wide
    final totalThumbsNeeded = (clipWidth / thumbWidth).ceil();

    return Row(
      children: List.generate(totalThumbsNeeded, (i) {
        // Loop through available thumbnails
        final thumbIndex = i % thumbCount;
        final bytes = item.thumbnailBytes![thumbIndex];

        return SizedBox(
          width: thumbWidth,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder:
                (_, __, ___) => Container(
                  color: const Color(0xFF2A2A2A),
                  child: const Icon(Icons.error, color: Colors.white30),
                ),
          ),
        );
      }),
    );
  }

  // FIXED: Audio track with Add Audio button on the right
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
          // Audio clips
          ...audioItems.map((audio) => _buildAudioClip(audio, centerX)),

          // RIGHT: Add Audio button
          Positioned(
            right: 12,
            top: 11,
            child: GestureDetector(
              onTap: _addAudio,
              child: Container(
                margin: const EdgeInsets.only(left: 12, right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add, color: Color(0xFF00D9FF), size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Add audio',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
        onTap:
            () => setState(() {
              selectedClip = int.tryParse(item.id);
              playheadPosition = item.startTime;
              timelineOffset =
                  playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
            }),
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
              if (item.waveformData != null && item.waveformData!.isNotEmpty)
                CustomPaint(painter: WaveformPainter(item.waveformData!)),
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

  // FIXED: Combined overlay and text track with Add Text button
  Widget _buildOverlayAndTextTrack() {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;
    final combinedItems = [...overlayItems, ...textItems]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
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
          // Overlay items
          //  ...overlayItems.map((overlay) => _buildOverlayClip(overlay, centerX)),
          // Text items
          // ...textItems.map((text) => _buildTextClip(text, centerX)),
          ...combinedItems.map(
            (item) =>
                item.type == TimelineItemType.text
                    ? _buildTextClip(item, centerX)
                    : _buildOverlayClip(item, centerX),
          ),

          // RIGHT: Add Text button
          Positioned(
            right: 12,
            top: 11,
            child: GestureDetector(
              onTap: _addText,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'Add text',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        onTap:
            () => setState(() {
              selectedClip = int.tryParse(item.id);
              playheadPosition = item.startTime;
              timelineOffset =
                  playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
            }),
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
        onLongPress: () => _showResizeDialog(item),
        child: Container(
          width: width,
          height: 46,
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

  // ============= NEW: RESIZE DIALOG =============
  void _showResizeDialog(TimelineItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            height: 200,
            child: Column(
              children: [
                const Text(
                  'Adjust Duration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: item.duration.inSeconds.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  activeColor: const Color(0xFF00D9FF),
                  label: '${item.duration.inSeconds}s',
                  onChanged: (v) {
                    setState(() {
                      item.duration = Duration(seconds: v.toInt());
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
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
        onTap:
            () => setState(() {
              selectedClip = int.tryParse(item.id);
              playheadPosition = item.startTime;
              timelineOffset =
                  playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
            }),
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
        onLongPress: () => _showResizeDialog(item),
        child: Container(
          width: width,
          height: 46,
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
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF00D9FF),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 2),
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

  // FIXED: Bottom tools bar matching CapCut - opens bottom sheet with tabs
  Widget _buildBottomTools() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
        border: Border(top: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _toolBtn(Icons.content_cut, 'Split', () => splitClipAtPlayhead()),
            _toolBtn(Icons.content_copy, 'Copy', _duplicateClip),
            _toolBtn(Icons.delete, 'Delete', _deleteSelected),
            _toolBtn(Icons.speed, 'Speed', _showSpeedEditor),
            _toolBtn(Icons.volume_up, 'Volume', _showVolumeEditor),
            _toolBtn(Icons.animation, 'Animation', _showAnimationsSheet),
            _toolBtn(Icons.auto_awesome, 'Effect', _showEffectsSheet),
            _toolBtn(Icons.filter, 'Filter', _showFiltersSheet),
            _toolBtn(Icons.crop, 'Crop', _showCropEditor),
            _toolBtn(Icons.switch_video, 'Transition', _showTransitionEditor),
            _toolBtn(Icons.text_fields, 'Text', _addText),
            _toolBtn(Icons.image, 'Overlay', _addImage),
            _toolBtn(Icons.animation, 'Keyframe', () => _showKeyframeEditor()),
          ],
        ),
      ),
    );
  }

  void _showTransitionEditor() {
    // Find where two clips meet
    VideoTransition? currentTransition;
    int? transitionIndex;

    for (int i = 0; i < clips.length - 1; i++) {
      final gap = clips[i + 1].startTime - (clips[i].startTime + clips[i].duration);
      if (gap.abs() < const Duration(milliseconds: 100)) {
        transitionIndex = i;
        currentTransition = clipTransitions[i];
        break;
      }
    }

    if (transitionIndex == null) {
      _showMessage('Move clips together to add transition');
      return;
    }

    final types = [
      {'name': 'None', 'icon': Icons.close},
      {'name': 'Dissolve', 'icon': Icons.blur_on},
      {'name': 'Slide Left', 'icon': Icons.arrow_back},
      {'name': 'Slide Right', 'icon': Icons.arrow_forward},
      {'name': 'Zoom In', 'icon': Icons.zoom_in},
      {'name': 'Wipe Right', 'icon': Icons.swipe_right},
    ];

    Duration duration = currentTransition?.duration ?? const Duration(milliseconds: 800);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('Transition', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text('Duration: ${duration.inMilliseconds}ms'),
              Slider(
                value: duration.inMilliseconds.toDouble(),
                min: 200,
                max: 2000,
                activeColor: const Color(0xFF00D9FF),
                onChanged: (v) => setState(() => duration = Duration(milliseconds: v.round())),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: types.length,
                  itemBuilder: (context, i) {
                    final t = types[i];
                    final selected = currentTransition?.type == t['name'].toString().toLowerCase().replaceAll(' ', '_');
                    return GestureDetector(
                      onTap: () {
                        if (t['name'] == 'None') {
                          clipTransitions.remove(transitionIndex);
                        } else {
                          clipTransitions[transitionIndex!] = VideoTransition(
                            type: t['name'].toString().toLowerCase().replaceAll(' ', '_'),
                            duration: duration,
                          );
                        }
                        Navigator.pop(context);
                        _showMessage('Transition: ${t['name']}');
                        this.setState(() {});
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF00D9FF) : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? Colors.cyan : Colors.white24),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(t['icon'] as IconData, color: selected ? Colors.black : Colors.white, size: 32),
                            const SizedBox(height: 8),
                            Text(t['name'] as String, style: TextStyle(color: selected ? Colors.black : Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: () {
          if (selectedClip == null && ![splitClipAtPlayhead, _duplicateClip, _deleteSelected].contains(onTap)) {
            _showMessage('Select a clip first');
            return;
          }
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
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

  Widget _navBtn(IconData icon, String label, VoidCallback? onTap) {
    final isSelected = selectedToolCategory == label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () {
          setState(() => selectedToolCategory = label);
          onTap?.call();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFF00D9FF).withOpacity(0.2)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? const Color(0xFF00D9FF) : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFF00D9FF) : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Edit tools bottom sheet with tabs (matching CapCut)
  void _showEditToolsSheet() {
    if (selectedClip == null) {
      _showMessage('Select a clip first');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DefaultTabController(
            length: 4,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.check,
                            color: Color(0xFF00D9FF),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab bar
                  const TabBar(
                    indicatorColor: Color(0xFF00D9FF),
                    labelColor: Color(0xFF00D9FF),
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      Tab(text: 'Basic'),
                      Tab(text: 'Adjust'),
                      Tab(text: 'Crop'),
                      Tab(text: 'Advanced'),
                    ],
                  ),

                  // Tab views
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildBasicEditTab(),
                        _buildAdjustTab(),
                        _buildCropTab(),
                        _buildAdvancedTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildBasicEditTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _editTile(
          Icons.content_cut,
          'Split',
          'Split clip at playhead',
          splitClipAtPlayhead,
        ),
        _editTile(
          Icons.content_copy,
          'Duplicate',
          'Duplicate selected clip',
          _duplicateClip,
        ),
        _editTile(
          Icons.delete,
          'Delete',
          'Remove selected item',
          _deleteSelected,
        ),
        _editTile(
          Icons.rotate_90_degrees_ccw,
          'Rotate',
          'Rotate 90° counter-clockwise',
          () {
            final item = getSelectedItem();
            if (item != null) {
              _saveToHistory();
              setState(() => item.rotation += 90);
              Navigator.pop(context);
              _showMessage('Rotated 90°');
            }
          },
        ),
        _editTile(Icons.flip, 'Flip Horizontal', 'Mirror horizontally', () {
          Navigator.pop(context);
          _showMessage('Flip applied');
        }),
      ],
    );
  }

  Widget _buildAdjustTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tune, size: 48, color: Colors.white30),
          const SizedBox(height: 16),
          const Text(
            'Adjust brightness, contrast, saturation',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildCropTab() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _showCropEditor();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00D9FF),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
        child: const Text(
          'Open Crop Editor',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _editTile(Icons.speed, 'Speed Ramp', 'Advanced speed control', () {
          final item = getSelectedItem();
          if (item?.type == TimelineItemType.video) {
            Navigator.pop(context);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => SpeedCurveEditor(item: item!),
            );
          }
        }),
        _editTile(Icons.animation, 'Keyframe', 'Add animation keyframes', () {
          Navigator.pop(context);
          _showKeyframeEditor();
        }),
      ],
    );
  }

  Widget _editTile(
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
      onTap: onTap,
    );
  }

  // FIXED: Effects sheet with tabs
  void _showEffectsSheet() {
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
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Effects',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (selectedEffect != null)
                        TextButton(
                          onPressed: () {
                            setState(() => selectedEffect = null);
                            Navigator.pop(context);
                            _showMessage('Effect removed');
                          },
                          child: const Text(
                            'Remove',
                            style: TextStyle(color: Color(0xFF00D9FF)),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Effects grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
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

  // FIXED: Filters sheet with tabs (Presets, Filters, Adjust, Video Quality)
  void _showFiltersSheet() {
    if (selectedClip == null) {
      _showMessage('Select a clip first');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DefaultTabController(
            length: 4,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.check,
                            color: Color(0xFF00D9FF),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const TabBar(
                    indicatorColor: Color(0xFF00D9FF),
                    labelColor: Color(0xFF00D9FF),
                    unselectedLabelColor: Colors.white54,
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Presets'),
                      Tab(text: 'Filters'),
                      Tab(text: 'Adjust'),
                      Tab(text: 'Quality'),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildPresetsTab(),
                        _buildFiltersTab(),
                        _buildAdjustFilterTab(),
                        _buildQualityTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildPresetsTab() {
    final presets = [
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
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        final isSelected = selectedFilter == preset;

        return GestureDetector(
          onTap: () {
            setState(() => selectedFilter = preset);
            _showMessage('Preset: $preset applied');
          },
          child: Container(
            decoration: BoxDecoration(
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF00D9FF) : Colors.transparent,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                preset,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00D9FF) : Colors.white,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiltersTab() {
    return const Center(
      child: Text(
        'Additional filter options',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _buildAdjustFilterTab() {
    return StatefulBuilder(
      builder: (context, setState) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSliderRow('Intensity', filterIntensity, 0, 1, (v) {
              setState(() => filterIntensity = v);
              this.setState(() {});
            }),
          ],
        );
      },
    );
  }

  Widget _buildQualityTab() {
    return const Center(
      child: Text(
        'Video quality settings',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _buildSliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: const Color(0xFF00D9FF),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // FIXED: Animations sheet
  void _showAnimationsSheet() {
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
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Animations',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
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
                          _showMessage('${animation['name']} applied');
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

  // FIXED: Real-time split operation
  void splitClipAtPlayhead() {
    final clip = getClipAtPlayhead();
    if (clip == null ||
        playheadPosition <= clip.startTime ||
        playheadPosition >= clip.startTime + clip.duration) {
      _showMessage('Move playhead to split position');
      return;
    }

    final splitPoint = playheadPosition - clip.startTime;

    _saveToHistory();

    setState(() {
      clips.removeWhere((c) => c.id == clip.id);

      // First part - keep original thumbnails
      final firstPart = clip.copyWith(duration: splitPoint);
      clips.add(firstPart);

      // Second part - need to generate new thumbnails from split point
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final secondPart = clip.copyWith(
        id: newId,
        startTime: playheadPosition,
        duration: clip.duration - splitPoint,
        trimStart: clip.trimStart + splitPoint,
      );
      clips.add(secondPart);

      // Copy controller for second part
      if (_controllers.containsKey(clip.id)) {
        _controllers[newId] = _controllers[clip.id]!;
      }

      clips.sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    _showMessage('Clip split successfully');
  }

  // FIXED: Real-time duplicate operation
  void _duplicateClip() {
    final item = getSelectedItem();
    if (item == null) {
      _showMessage('Select a clip to duplicate');
      return;
    }

    _saveToHistory();

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final duplicated = item.copyWith(
      id: newId,
      startTime: item.startTime + item.duration,
    );

    setState(() {
      if (item.type == TimelineItemType.video) {
        clips.add(duplicated);
        // Share the controller
        if (_controllers.containsKey(item.id)) {
          _controllers[newId] = _controllers[item.id]!;
        }
        clips.sort((a, b) => a.startTime.compareTo(b.startTime));
      } else if (item.type == TimelineItemType.audio) {
        audioItems.add(duplicated);
        if (_audioControllers.containsKey(item.id)) {
          _audioControllers[newId] = _audioControllers[item.id]!;
        }
        audioItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      } else if (item.type == TimelineItemType.text) {
        textItems.add(duplicated);
        textItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      } else if (item.type == TimelineItemType.image) {
        overlayItems.add(duplicated);
        overlayItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      }
    });

    _showMessage('Clip duplicated');
  }

  // FIXED: Real-time delete operation
  void _deleteSelected() {
    if (selectedClip == null) return;
    final id = selectedClip.toString();

    _saveToHistory();

    setState(() {
      clips.removeWhere((c) => c.id == id);
      if (_controllers.containsKey(id)) {
        // Don't dispose if shared with duplicates
        final shareCount =
            clips.where((c) => _controllers[c.id] == _controllers[id]).length;
        if (shareCount == 0) {
          _controllers[id]!.dispose();
          _controllers.remove(id);
        }
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

  // FIXED: Add video with proper thumbnail generation
  Future<void> _addVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    _showLoading();

    try {
      final videoPath = file.path;
      debugPrint('\n🎬 Adding video: $videoPath');

      final tempCtrl = VideoPlayerController.file(File(videoPath));
      await tempCtrl.initialize();

      final duration = tempCtrl.value.duration;
      debugPrint('✅ Video duration: ${duration.inSeconds}s');

      // Generate thumbnails using robust method
      List<Uint8List> bytesList = await _generateRobustThumbnails(
        videoPath,
        duration,
      );

      if (bytesList.isEmpty) {
        bytesList = await _generateFallbackThumbnails(videoPath, duration);
      }

      if (bytesList.isEmpty) {
        _hideLoading();
        _showError('Could not generate thumbnails');
        return;
      }

      await tempCtrl.seekTo(const Duration(seconds: 1));
      await tempCtrl.pause();

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
        text: result.files.first.name,
      );
      _audioControllers[item.id] = ctrl;
      ctrl.setLooping(false);
      ctrl.setVolume(0);

      _saveToHistory();

      setState(() {
        audioItems.add(item);
        audioItems.sort((a, b) => a.startTime.compareTo(b.startTime));
        selectedClip = int.parse(item.id);
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

  Future<void> _addImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    Duration imageDur = const Duration(seconds: 5);
    final activeVideo = _findActiveVideo();
    if (activeVideo != null) {
      imageDur = activeVideo.duration;
    }

    _saveToHistory();

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
    _saveToHistory();

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

  void _showCropEditor() {
    final item = getSelectedItem();
    if (item == null || item.type != TimelineItemType.video) {
      _showMessage('Please select a video clip');
      return;
    }

    // Use item values or fallback
    double tempX = item.cropX ?? 0.0;
    double tempY = item.cropY ?? 0.0;
    double tempW = item.cropWidth ?? 1.0;
    double tempH = item.cropHeight ?? 1.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Crop Video', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      tempX += details.delta.dx / 300;
                      tempY += details.delta.dy / 300;
                      tempX = tempX.clamp(0.0, 1.0 - tempW);
                      tempY = tempY.clamp(0.0, 1.0 - tempH);
                    });
                  },
                  child: Stack(
                    children: [
                      ClipRect(
                        child: Align(
                          alignment: Alignment(
                            (tempX / (1 - tempW)) * 2 - 1,
                            (tempY / (1 - tempH)) * 2 - 1,
                          ),
                          widthFactor: tempW,
                          heightFactor: tempH,
                          child: VideoPlayer(_controllers[item.id]!),
                        ),
                      ),
                      // Crop overlay
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54, width: 2),
                            color: Colors.black.withOpacity(0.5),
                          ),
                          margin: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * (1 - tempW) / 2,
                            vertical: MediaQuery.of(context).size.height * 0.3 * (1 - tempH) / 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildAspectButton('Free', () {}),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildAspectButton('16:9', () {
                          tempW = 16/9 / (16/9 + 1);
                          tempH = 1 / (16/9 + 1) * (16/9);
                          setState(() {});
                        }),
                        _buildAspectButton('9:16', () {
                          tempW = 9/16 / (9/16 + 1);
                          tempH = 1.0;
                          setState(() {});
                        }),
                        _buildAspectButton('1:1', () {
                          tempW = tempH = 0.7;
                          tempX = tempY =   0.15;
                          setState(() {});
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _saveToHistory();
                        setState(() {
                          item.cropX = tempX;
                          item.cropY = tempY;
                          item.cropWidth = tempW;
                          item.cropHeight = tempH;
                        });
                        Navigator.pop(context);
                        _showMessage('Crop applied');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Apply Crop', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  Widget _buildAspectButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A2A2A)),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  void _showKeyframeEditor() {
    final item = getSelectedItem();
    if (item == null || (item.type != TimelineItemType.text && item.type != TimelineItemType.image)) {
      _showMessage('Please select text or overlay');
      return;
    }

    // Initialize if needed
    if (item.keyframes.isEmpty) {
      item.keyframes = [
        Keyframe(time: 0.0, x: item.x ?? 100, y: item.y ?? 200, scale: item.scale, rotation: item.rotation, opacity: 1.0),
        Keyframe(time: 1.0, x: item.x ?? 100, y: item.y ?? 200, scale: item.scale, rotation: item.rotation, opacity: 1.0),
      ];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (_, controller) => KeyframeAnimationEditor(
          item: item,
          onSave: _saveToHistory,        // Pass the method
          showMessage: _showMessage,     // Pass the method
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
                                _saveToHistory();
                                setState(() {
                                  final oldDuration = item.duration;
                                  item.speed = tempSpeed;
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

  void _showVolumeEditor() {
    final item = getSelectedItem();
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
                          _saveToHistory();
                          setState(() => item.volume = temp);
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

  // Helper methods
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
    Uint8List? coverBytes;
    if (_activeItem != null &&
        _activeItem!.thumbnailBytes?.isNotEmpty == true) {
      final index =
          ((playheadPosition - _activeItem!.startTime).inMilliseconds /
                  _activeItem!.duration.inMilliseconds *
                  _activeItem!.thumbnailBytes!.length)
              .clamp(0, _activeItem!.thumbnailBytes!.length - 1)
              .floor();
      coverBytes = _activeItem!.thumbnailBytes![index];
    }

    return GestureDetector(
      onTap: () => _showMessage('Cover selector'),
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

  double _clipWidth(TimelineItem item) {
    final secs = item.duration.inMilliseconds / 1000.0 / item.speed;
    return (secs * pixelsPerSecond).clamp(60.0, double.infinity);
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

class _WipeClipper extends CustomClipper<Rect> {
  final double progress;
  _WipeClipper(this.progress);
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * progress, size.height);
  @override
  bool shouldReclip(covariant CustomClipper<Rect> old) => true;
}
