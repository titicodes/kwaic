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
import 'package:kwaic/nes_scr/screen/video_editor_helpers.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../model/clip_selection_state.dart';
import '../model/debouncer.dart';
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
import '../widgets/speed_curve_editor.dart';
import '../widgets/thumbnail_strip_painter.dart';
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
  double pixelsPerSecond = 100.0; // current zoom level
  double minPixelsPerSecond = 50.0;
  double maxPixelsPerSecond = 300.0;
  double timelineOffset = 0.0;

  // Changed from VlcPlayerController to VideoPlayerController
  final Map<String, VideoPlayerController> _controllers = {};
  VideoPlayerController? _activeVideoController;
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
  bool _isBottomNavCollapsed = false;
  String? _selectedClipId;

  // Crop system — normalized values (0.0 to 1.0)
  double cropX = 0.0;
  double cropY = 0.0;
  double cropWidth = 1.0;
  double cropHeight = 1.0;

  // NEW: Selected tool category
  String? selectedToolCategory;
  String? selectedClipId;

  // Add these variables
  late String currentProjectId;
  late String currentProjectName;
  late HistoryManager historyManager;
  late AutosaveManager autosaveManager;
  bool isPro = false;

  final ScrollController _timelineScrollController = ScrollController();
  final ScrollController _editToolsScrollController = ScrollController();
  bool _isBottomNavVisible = true; // Toggle hide/show
  bool _isImmersiveMode = false; // Fullscreen preview

  late AnimationController _bottomNavAnimController;
  late Animation<double> _bottomNavHeightAnim;
  late AnimationController _previewAnimationController;

  // Context toolbar state
  TimelineItem? _selectedTimelineItem; // null = global tools
  String? _selectedToolCategory;
  bool _showContextToolbar = true;

  late ScrollController timelineController;

  // Replace your current bottom nav state with these:
  bool _isToolPanelOpen = false;
  String?
  _activeToolCategory; // 'edit', 'audio', 'text', 'stickers', 'effects', etc.

  late AnimationController _toolPanelController;
  late Animation<double> _toolPanelHeight;

  final DraggableScrollableController _draggableController =
      DraggableScrollableController();

  bool _isBottomNavExpanded = true;
  bool _showEditTools = false;

  ClipSelectionState _selection = ClipSelectionState();
  BottomNavMode _currentNavMode = BottomNavMode.normal;

  bool _isResizingClip = false;
  String? _resizingClipId;
  bool _isResizingLeft = false;
  double _resizeStartX = 0;

  late Debouncer _previewDebouncer;
  bool _isPreviewReady = false;

  @override
  void initState() {
    super.initState();

    currentProjectId =
        widget.projectId ?? DateTime.now().millisecondsSinceEpoch.toString();
    currentProjectName = widget.projectName ?? 'Untitled Project';
    historyManager = HistoryManager();

    _previewDebouncer = Debouncer(milliseconds: 50);

    // Dummy controller
    _activeVideoController = VideoPlayerController.file(File(''))
      ..initialize().then((_) => setState(() {}));

    autosaveManager = AutosaveManager(
      onAutosave: _performAutosave,
      autosaveInterval: const Duration(minutes: 2),
    );
    autosaveManager.start();

    _playbackTicker = createTicker(_playbackFrame);

    thumbnailNotifier.addListener(() => mounted ? setState(() {}) : null);

    _timelineScrollController.addListener(() {
      setState(() => timelineOffset = _timelineScrollController.offset);
    });

    if (widget.initialVideos != null && widget.initialVideos!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _processInitialVideos(),
      );
    }

    _toolPanelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _toolPanelHeight = Tween<double>(begin: 0.0, end: 0.55).animate(
      CurvedAnimation(parent: _toolPanelController, curve: Curves.easeOutCubic),
    );

    _draggableController.addListener(() {
      if (_draggableController.pixels < 100 &&
          _toolPanelController.isAnimating == false) {
        closeToolPanel();
      }
    });
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

  // --------------------------------------------------------------------- Video loading
  Future<void> _processInitialVideos() async {
    if (_isInitializing) return;
    setState(() => _isInitializing = true);

    try {
      Duration currentStart = Duration.zero;
      for (var video in widget.initialVideos!) {
        final path = video.path;
        final controller = VideoPlayerController.file(File(path));
        await controller.initialize();

        await controller.seekTo(const Duration(milliseconds: 100));
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 50));
        await controller.pause();

        // Optional: seek back to start if you want to show the very first frame
        await controller.seekTo(Duration.zero);

        final duration = controller.value.duration;

        final thumbs = await _generateRobustThumbnails(path, duration);

        final item = TimelineItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: TimelineItemType.video,
          file: File(path),
          startTime: currentStart,
          duration: duration,
          originalDuration: duration,
          trimStart: Duration.zero,
          trimEnd: duration,
          thumbnailBytes: thumbs,
        );

        _controllers[item.id] = controller;
        clips.add(item);
        currentStart += duration;
      }

      if (mounted && clips.isNotEmpty) {
        clips.sort((a, b) => a.startTime.compareTo(b.startTime));
        final first = clips.first;
        _activeItem = first;
        _activeVideoController = _controllers[first.id];
        _switchToClip(first);
        setState(() => _isPreviewReady = true);
      }
    } catch (e) {
      debugPrint('Load error: $e');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  void _switchToClip(TimelineItem item) async {
    final ctrl = _controllers[item.id];
    if (ctrl == null) return;

    _activeVideoController = ctrl;
    _activeItem = item;

    // Force real frame
    await ctrl.seekTo(const Duration(milliseconds: 100));
    await ctrl.play();
    await Future.delayed(const Duration(milliseconds: 50));
    await ctrl.pause();

    // Go to correct time
    final localTime = (playheadPosition - item.startTime).clamp(
      Duration.zero,
      item.duration,
    );
    final posMs = (item.trimStart + localTime).inMilliseconds;
    await ctrl.seekTo(Duration(milliseconds: posMs));

    setState(() {});
  }

  Future<List<Uint8List>> _generateRobustThumbnails(
      String videoPath,
      Duration duration,
      )
  async {
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

  Future<List<Uint8List>> _generateFallbackThumbnails(
    String videoPath,
    Duration duration,
  ) async {
    final List<Uint8List> thumbs = [];
    final ms = duration.inMilliseconds;
    final count = (duration.inSeconds / 2).clamp(8.0, 25.0).toInt();

    for (int i = 0; i < count; i++) {
      final timeMs = ((ms * i) / (count - 1)).round().clamp(1000, ms - 1000);
      final bytes = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 160,
        timeMs: timeMs,
        quality: 70,
      );
      if (bytes != null) thumbs.add(bytes);
    }
    return thumbs;
  }

  void togglePlayPause() {
    setState(() => isPlaying = !isPlaying);
    if (isPlaying) {
      _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
      if (!_playbackTicker.isActive) _playbackTicker.start();
      _activeVideoController?.play();
    } else {
      _playbackTicker.stop();
      _activeVideoController?.pause();
      _updatePreview();
    }
  }

  @override
  void dispose() {
    _playbackTicker.stop();
    _playbackTicker.dispose();
    thumbnailNotifier.dispose();
    _bottomNavAnimController.dispose();
    _timelineScrollController.dispose();
    _previewAnimationController.dispose();
    timelineController.dispose();
    _toolPanelController.dispose();
    _draggableController.dispose();
    _previewDebouncer.dispose();

    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    for (final controller in _audioControllers.values) {
      controller.dispose();
    }
    _audioControllers.clear();

    autosaveManager.stop();
    super.dispose();
  }

  void _saveToHistory() {
    final state = EditorState(
      clips: clips.map((c) => c.copyWith()).toList(),
      audioItems: audioItems.map((a) => a.copyWith()).toList(),
      textItems: textItems.map((t) => t.copyWith()).toList(),
      overlayItems: overlayItems.map((o) => o.copyWith()).toList(),
      selectedClip: null, // legacy field — can be null
      selection: _selection.copy(), // ← this is the real one
      playheadPosition: playheadPosition,
    );
    historyManager.saveState(state);
    autosaveManager.markChanged();
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
    if (item.speedPoints.isEmpty) return item.speed;
    final progress =
        localTime.inMilliseconds / item.originalDuration.inMilliseconds;
    SpeedPoint? prev;
    for (final point in item.speedPoints) {
      if (progress <= point.time) {
        if (prev == null) return point.speed;
        final t = (progress - prev.time) / (point.time - prev.time);
        return prev.speed + (point.speed - prev.speed) * t;
      }
      prev = point;
    }
    return item.speedPoints.last.speed;
  }

  void _updatePreview() {
    _previewDebouncer.run(() => _updatePreviewImmediate());
  }

  int vlcVolume(double v) {
    return (v.clamp(0.0, 1.0) * 100).round();
  }

  void _updatePreviewImmediate() async {
    if (!mounted || !_isPreviewReady) return;

    final active = _findActiveVideo();
    if (active == null || !_controllers.containsKey(active.id)) return;

    final ctrl = _controllers[active.id]!;
    if (!ctrl.value.isInitialized) return;

    final local = (playheadPosition - active.startTime).clamp(
      Duration.zero,
      active.duration,
    );
    final speed = getCurrentSpeed(active, local).clamp(0.5, 2.0);
    final sourceMs =
        (active.trimStart +
                Duration(milliseconds: (local.inMilliseconds / speed).round()))
            .inMilliseconds;

    await ctrl.seekTo(Duration(milliseconds: sourceMs));
    await ctrl.setPlaybackSpeed(speed);
    await ctrl.setVolume(active.volume);

    if (isPlaying)
      ctrl.play();
    else
      ctrl.pause();

    if (_activeItem?.id != active.id) _switchToClip(active);
  }

  TimelineItem? _findActiveVideo() {
    for (final item in clips) {
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

  // --------------------------------------------------------------------- Real-time split / trim / selection
  void splitClipAtPlayhead() {
    final clip = getClipAtPlayhead();
    if (clip == null) return;

    final local = playheadPosition - clip.startTime;
    if (local <= Duration.zero || local >= clip.duration) return;

    _saveToHistory();

    final first = clip.copyWith(duration: local);
    final second = clip.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: playheadPosition,
      duration: clip.duration - local,
      trimStart: clip.trimStart + local,
    );

    _controllers[second.id] = _controllers[clip.id]!;

    setState(() {
      clips.remove(clip);
      clips.addAll([first, second]);
      clips.sort((a, b) => a.startTime.compareTo(b.startTime));
      _selection.select(second.id, second.type);
      _activeItem = second;
    });
    _updatePreview();
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildPreview()),
            _buildPlaybackControls(),
            SizedBox(height: 240, child: _buildTimelineSection()),
            if (_currentNavMode != BottomNavMode.normal)
              Container(
                height: 70,
                color: const Color(0xFF1A1A1A),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _getContextTools(), // Now it's correct: Row expects List<Widget>
                  ),
                ),
              ),
            Container(
              height: 80,
              color: Colors.black,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _currentNavMode == BottomNavMode.normal
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                    onPressed:
                        () => setState(
                          () => _currentNavMode = BottomNavMode.normal,
                        ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _navButton(
                            Icons.edit,
                            'Edit',
                            () => _openNavMode(BottomNavMode.edit),
                          ),
                          _navButton(
                            Icons.audiotrack,
                            'Audio',
                            () => _openNavMode(BottomNavMode.audio),
                          ),
                          _navButton(
                            Icons.text_fields,
                            'Text',
                            () => _openNavMode(BottomNavMode.text),
                          ),
                          _navButton(
                            Icons.emoji_emotions,
                            'Stickers',
                            () => _openNavMode(BottomNavMode.stickers),
                          ),
                          _navButton(
                            Icons.layers,
                            'Overlay',
                            () => _openNavMode(BottomNavMode.overlay),
                          ),
                          _navButton(
                            Icons.auto_awesome,
                            'Effects',
                            () => _openNavMode(BottomNavMode.effects),
                          ),
                          _navButton(
                            Icons.filter,
                            'Filters',
                            () => _openNavMode(BottomNavMode.filters),
                          ),
                          _navButton(
                            Icons.animation,
                            'Animation',
                            () => _openNavMode(BottomNavMode.animation),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56 + MediaQuery.of(context).padding.top,
      color: Colors.black,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          // Back arrow
          GestureDetector(
            onTap: () async {
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
                if (save == true) await _saveProject();
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Spacer(),
          // Project Name (centered-ish)
          // Expanded(
          //   flex: 3,
          //   child: Center(
          //     child: Text(
          //       currentProjectName,
          //       style: const TextStyle(
          //         color: Colors.white,
          //         fontSize: 17,
          //         fontWeight: FontWeight.w600,
          //       ),
          //       maxLines: 1,
          //       overflow: TextOverflow.ellipsis,
          //     ),
          //   ),
          // ),
          //
          // const Spacer(),
          // ? Help button
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              _showMessage('Help & Tips coming soon');
            },
          ),
          // ... More menu
          // IconButton(
          //   icon: const Icon(Icons.more_vert, color: Colors.white),
          //   onPressed: () {
          //     // Optional: show more options
          //   },
          // ),
          const SizedBox(width: 8),
          // Export button (purple capsule)
          GestureDetector(
            onTap: _exportVideoEnhanced,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF9F70FF), // Exact purple from screenshot
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Export',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
          '-filter_complex "concat=n=${clips.length}:v=1:a=0[outv];[0:a]';

      // Video concat
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
      }
      // Add more filters as needed

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

  Widget _buildPreview() {
    final screenSize = MediaQuery.of(context).size;

    Widget videoWidget;
    if (_activeVideoController != null &&
        _activeVideoController!.value.isInitialized) {
      videoWidget = AspectRatio(
        aspectRatio: _activeVideoController!.value.aspectRatio ?? 16 / 9,
        child: VideoPlayer(_activeVideoController!),
      );
    } else if (_activeItem?.thumbnailBytes != null &&
        _activeItem!.thumbnailBytes!.isNotEmpty) {
      videoWidget = Image.memory(
        _activeItem!.thumbnailBytes!.first,
        fit: BoxFit.contain,
      );
    } else {
      videoWidget = _buildPlaceholder();
    }

    // Highlight selected video clip
    final selectedClip = getSelectedItem();
    final isVideoSelected =
        selectedClip?.type == TimelineItemType.video && _selection.isEditMode;

    if (isVideoSelected) {
      videoWidget = Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00D9FF), width: 4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: videoWidget,
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: videoWidget),
          ..._buildInteractiveOverlays(screenSize, [
            ...textItems,
            ...overlayItems,
          ]),
          if (_selection.isEditMode && selectedClip != null)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Edit Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCropEditor() {
    final item = getSelectedItem();
    if (item == null || item.type != TimelineItemType.video) {
      _showMessage('Please select a video clip');
      return;
    }

    double tempX = item.cropX ?? 0.0;
    double tempY = item.cropY ?? 0.0;
    double tempW = item.cropWidth ?? 1.0;
    double tempH = item.cropHeight ?? 1.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header unchanged...
                      // Crop preview area
                      Expanded(
                        child:
                            _controllers.containsKey(item.id) &&
                                    _controllers[item.id]!.value.isInitialized
                                ? GestureDetector(
                                  onPanUpdate: (details) {
                                    setModalState(() {
                                      tempX += details.delta.dx / 300;
                                      tempY += details.delta.dy / 300;
                                      tempX = tempX.clamp(0.0, 1.0 - tempW);
                                      tempY = tempY.clamp(0.0, 1.0 - tempH);
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(16),
                                    child: ClipRect(
                                      child: Align(
                                        alignment: Alignment(
                                          -1 + 2 * tempX / (1 - tempW),
                                          -1 + 2 * tempY / (1 - tempH),
                                        ),
                                        widthFactor: 1 / tempW,
                                        heightFactor: 1 / tempH,
                                        child: AspectRatio(
                                          aspectRatio:
                                              _controllers[item.id]!
                                                  .value
                                                  .aspectRatio ??
                                              16 / 9,
                                          child: VideoPlayer(
                                            _controllers[item.id]!,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                : const Center(
                                  child: Text(
                                    'Video not available',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                      ),
                      // Aspect ratio buttons unchanged...
                    ],
                  ),
                ),
          ),
    );
  }

  void _showTextSizeEditor(TimelineItem item) {
    double tempSize = item.fontSize ?? 32;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  height: 220,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Font Size',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${tempSize.toInt()}',
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Slider(
                        value: tempSize,
                        min: 10,
                        max: 100,
                        activeColor: const Color(0xFF00D9FF),
                        onChanged: (v) => setState(() => tempSize = v),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          _saveToHistory();
                          this.setState(() => item.fontSize = tempSize);
                          Navigator.pop(context);
                          _showMessage('Font size updated');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9FF),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showTextColorPicker(TimelineItem item) {
    Color tempColor = item.textColor ?? Colors.white;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  height: 280,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Text Color',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children:
                            [
                              Colors.white,
                              Colors.black,
                              Colors.red,
                              Colors.blue,
                              Colors.green,
                              Colors.yellow,
                              Colors.purple,
                              Colors.orange,
                              Colors.pink,
                              Colors.cyan,
                              Colors.lime,
                              Colors.indigo,
                            ].map((c) {
                              final selected = c == tempColor;
                              return GestureDetector(
                                onTap: () => setState(() => tempColor = c),
                                child: Container(
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          selected
                                              ? const Color(0xFF00D9FF)
                                              : Colors.white24,
                                      width: selected ? 4 : 2,
                                    ),
                                    boxShadow:
                                        selected
                                            ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF00D9FF,
                                                ).withOpacity(0.5),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                            : null,
                                  ),
                                  child:
                                      selected
                                          ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 28,
                                          )
                                          : null,
                                ),
                              );
                            }).toList(),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          _saveToHistory();
                          this.setState(() => item.textColor = tempColor);
                          Navigator.pop(context);
                          _showMessage('Color updated');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9FF),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  List<Widget> _getContextTools() {
    switch (_currentNavMode) {
      case BottomNavMode.edit:
        return [
          _toolBtn(Icons.content_cut, 'Split', _smartSplit),
          _toolBtn(
            Icons.cut,
            'Trim',
            () => _showMessage('Use handles to trim'),
          ),
          _toolBtn(Icons.speed, 'Speed', _smartSpeed),
          _toolBtn(Icons.crop, 'Crop', _smartCrop),
          _toolBtn(Icons.rotate_90_degrees_ccw, 'Rotate', _smartRotate),
          _toolBtn(Icons.volume_up, 'Volume', _smartVolume),
          _toolBtn(Icons.flip, 'Flip', _smartFlip),
          _toolBtn(Icons.content_copy, 'Duplicate', _smartDuplicate),
          _toolBtn(Icons.delete, 'Delete', _smartDelete, color: Colors.red),
        ];
      case BottomNavMode.audio:
        return [
          _toolBtn(Icons.add, 'Add', _addAudio),
          _toolBtn(Icons.volume_up, 'Volume', _smartVolume),
          _toolBtn(Icons.delete, 'Delete', _smartDelete, color: Colors.red),
        ];
      case BottomNavMode.text:
        return [
          _toolBtn(Icons.add, 'Add', _addText),
          _toolBtn(Icons.edit, 'Edit', _smartTextEdit),
          _toolBtn(Icons.format_size, 'Size', _smartTextSize),
          _toolBtn(Icons.color_lens, 'Color', _smartTextColor),
          _toolBtn(Icons.delete, 'Delete', _smartDelete, color: Colors.red),
        ];
      default:
        return [];
    }
  }

  Widget _toolBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color ?? const Color(0xFF00D9FF), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, String label, VoidCallback onTap) {
    final isActive =
        (_currentNavMode == BottomNavMode.edit && label == 'Edit') ||
        (_currentNavMode == BottomNavMode.audio && label == 'Audio') ||
        (_currentNavMode == BottomNavMode.text && label == 'Text');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isActive
                        ? const Color(0xFF00D9FF).withOpacity(0.2)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isActive ? const Color(0xFF00D9FF) : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? const Color(0xFF00D9FF) : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNavMode(BottomNavMode mode) {
    setState(() => _currentNavMode = mode);

    // Auto-select clip at playhead
    final clip = getClipAtPlayhead();
    if (clip != null) {
      _selection.select(clip.id, clip.type);
      _activeItem = clip;
    }
  }

  // SMART OPERATIONS (work on active clip automatically)
  void _smartSplit() {
    final item = _activeItem ?? _getClipAtPlayhead();
    if (item == null || item.type != TimelineItemType.video) {
      _showMessage('Select a video clip');
      return;
    }

    final local = playheadPosition - item.startTime;
    if (local <= Duration.zero || local >= item.duration) {
      _showMessage('Move playhead inside clip');
      return;
    }

    _saveToHistory();

    final first = item.copyWith(duration: local);
    final second = item.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: playheadPosition,
      duration: item.duration - local,
      trimStart: item.trimStart + local,
    );

    _controllers[second.id] = _controllers[item.id]!;

    setState(() {
      clips.remove(item);
      clips.addAll([first, second]);
      clips.sort((a, b) => a.startTime.compareTo(b.startTime));
      _selection.select(second.id, second.type);
      _activeItem = second;
    });

    _showMessage('Split complete');
  }

  void _smartSpeed() {
    final item = _activeItem ?? _getClipAtPlayhead();
    if (item == null) return;
    _showCompactSpeedEditor(item);
  }

  void _smartCrop() {
    final item = _activeItem ?? _getClipAtPlayhead();
    if (item == null || item.type != TimelineItemType.video) return;
    _showCropEditor();
  }

  void _smartRotate() {
    final item = _activeItem ?? _getClipAtPlayhead();
    if (item == null) return;

    _saveToHistory();
    setState(() {
      item.rotation += 90;
      if (item.rotation >= 360) item.rotation = 0;
    });
    _updatePreview();
    _showMessage('Rotated ${item.rotation}°');
  }

  void _smartVolume() {
    final item = _activeItem ?? _getClipAtPlayhead();
    if (item == null) return;
    _showCompactVolumeEditor(item);
  }

  void _smartFlip() {
    final item = _activeItem ?? _getClipAtPlayhead();
    if (item == null) return;

    _saveToHistory();
    setState(() {
      item.flipHorizontal = !(item.flipHorizontal ?? false);
    });
    _updatePreview();
    _showMessage('Flipped');
  }

  void _smartDuplicate() {
    final item = _activeItem ?? _getClipAtPlayhead();
    if (item == null) return;

    final newItem = item.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: item.startTime + item.duration,
    );

    if (_controllers.containsKey(item.id)) {
      _controllers[newItem.id] = _controllers[item.id]!;
    }

    _saveToHistory();
    setState(() {
      if (item.type == TimelineItemType.video) {
        clips.add(newItem);
        clips.sort((a, b) => a.startTime.compareTo(b.startTime));
      } else if (item.type == TimelineItemType.audio) {
        audioItems.add(newItem);
      }
    });

    _showMessage('Duplicated');
  }

  void _smartDelete() {
    final item = _activeItem ?? _getClipAtPlayhead();
    if (item == null) return;

    _saveToHistory();
    setState(() {
      clips.removeWhere((c) => c.id == item.id);
      audioItems.removeWhere((c) => c.id == item.id);
      textItems.removeWhere((c) => c.id == item.id);
      overlayItems.removeWhere((c) => c.id == item.id);

      _activeItem = null;
      _selection.clear();
    });

    _showMessage('Deleted');
  }

  void _smartTextEdit() {
    final item = _activeItem ?? _getClipAtPlayhead();
    if (item == null || item.type != TimelineItemType.text) return;
    _showTextEditor(item);
  }

  void _smartTextSize() {
    final item = _activeItem ?? _getClipAtPlayhead();
    if (item == null || item.type != TimelineItemType.text) return;
    _showTextSizeEditor(item);
  }

  void _smartTextColor() {
    final item = _activeItem ?? _getClipAtPlayhead();
    if (item == null || item.type != TimelineItemType.text) return;
    _showTextColorPicker(item);
  }

  TimelineItem? _getClipAtPlayhead() {
    for (final clip in [
      ...clips,
      ...audioItems,
      ...textItems,
      ...overlayItems,
    ]) {
      if (playheadPosition >= clip.startTime &&
          playheadPosition < clip.startTime + clip.duration) {
        return clip;
      }
    }
    return null;
  }

  Widget _buildVideoClip(TimelineItem item, double centerX) {
    final isSelected = _selection.clipId == item.id;
    final startX = item.startTime.inSeconds * pixelsPerSecond - timelineOffset;
    final width = math.max(
      item.duration.inSeconds * pixelsPerSecond / item.speed,
      60.0,
    );

    return Positioned(
      left: startX + centerX,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selection.select(item.id, item.type);
            _activeItem = item;
            playheadPosition = item.startTime;
          });
          _updatePreview();
        },
        onHorizontalDragStart: (d) {
          final localX = d.localPosition.dx;
          if (localX < 24) {
            _isResizingClip = true;
            _isResizingLeft = true;
            _resizingClipId = item.id;
          } else if (localX > width - 24) {
            _isResizingClip = true;
            _isResizingLeft = false;
            _resizingClipId = item.id;
          }
        },
        onHorizontalDragUpdate: (d) {
          if (_isResizingClip && _resizingClipId == item.id) {
            final deltaSec = Duration(
              milliseconds: (d.delta.dx / pixelsPerSecond * 1000).round(),
            );
            setState(() {
              if (_isResizingLeft) {
                final newDur = item.duration - deltaSec;
                if (newDur > const Duration(seconds: 1)) {
                  item.startTime += deltaSec;
                  item.trimStart += deltaSec;
                  item.duration = newDur;
                }
              } else {
                final newDur = item.duration + deltaSec;
                if (newDur > const Duration(seconds: 1) &&
                    item.trimStart + newDur <= item.originalDuration) {
                  item.duration = newDur;
                }
              }
            });
            _updatePreview();
          } else if (!_isResizingClip) {
            // Move whole clip
            final deltaSec = Duration(
              milliseconds: (d.delta.dx / pixelsPerSecond * 1000).round(),
            );
            final newStart = item.startTime + deltaSec;
            if (newStart >= Duration.zero) {
              setState(() => item.startTime = newStart);
            }
          }
        },
        onHorizontalDragEnd: (_) {
          _isResizingClip = false;
          _resizingClipId = null;
          _saveToHistory();
        },
        child: Container(
          width: width,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
            border:
                isSelected
                    ? Border.all(color: const Color(0xFF00D9FF), width: 3)
                    : null,
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildThumbnailStrip(item, width),
              ),
              if (width > 80) ...[
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 6, color: Colors.white),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 6, color: Colors.white),
                ),
              ],
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  color: Colors.black54,
                  child: Text(
                    _formatTime(item.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioClip(TimelineItem item, double centerX) {
    final selected = _selection.clipId == item.id;
    final startX =
        item.startTime.inMilliseconds / 1000 * pixelsPerSecond - timelineOffset;
    final width = _clipWidth(item);

    return Positioned(
      left: startX + centerX,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selection.select(item.id, item.type);
            _activeItem = item;
          });
        },
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
        onLongPress: () => _showClipOptions(item),
        child: Container(
          width: width,
          height: 46,
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              if (item.waveformData != null)
                CustomPaint(painter: WaveformPainter(item.waveformData!)),
              if (item.text != null)
                Padding(
                  padding: const EdgeInsets.all(4),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showCompactSpeedEditor(TimelineItem item) {
    double tempSpeed = item.speed;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder:
          (_) => Container(
            height: 280,
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder:
                  (ctx, setM) => Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const Text(
                            'Speed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _saveToHistory();
                              setState(() {
                                item.speed = tempSpeed;
                                item.duration = Duration(
                                  milliseconds:
                                      (item.originalDuration.inMilliseconds /
                                              tempSpeed)
                                          .round(),
                                );
                              });
                              Navigator.pop(ctx);
                              _showMessage(
                                'Speed: ${tempSpeed.toStringAsFixed(1)}x',
                              );
                            },
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                color: Color(0xFF00D9FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${tempSpeed.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Slider(
                        value: tempSpeed,
                        min: 0.1,
                        max: 5.0,
                        activeColor: const Color(0xFF00D9FF),
                        onChanged: (v) => setM(() => tempSpeed = v),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children:
                            [0.25, 0.5, 1.0, 1.5, 2.0].map((s) {
                              final selected = (tempSpeed - s).abs() < 0.01;
                              return GestureDetector(
                                onTap: () => setM(() => tempSpeed = s),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        selected
                                            ? const Color(0xFF00D9FF)
                                            : const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${s}x',
                                    style: TextStyle(
                                      color:
                                          selected
                                              ? Colors.black
                                              : Colors.white,
                                      fontWeight:
                                          selected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
            ),
          ),
    );
  }

  void _showCompactVolumeEditor(TimelineItem item) {
    double tempVolume = item.volume;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder:
          (_) => Container(
            height: 250,
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder:
                  (ctx, setM) => Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Volume',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              tempVolume == 0
                                  ? Icons.volume_off
                                  : Icons.volume_up,
                              color: const Color(0xFF00D9FF),
                            ),
                            onPressed:
                                () => setM(
                                  () =>
                                      tempVolume = tempVolume == 0 ? 1.0 : 0.0,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${(tempVolume * 100).toInt()}%',
                        style: TextStyle(
                          color:
                              tempVolume == 0
                                  ? Colors.red
                                  : const Color(0xFF00D9FF),
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Slider(
                        value: tempVolume,
                        min: 0.0,
                        max: 2.0,
                        activeColor: const Color(0xFF00D9FF),
                        onChanged: (v) => setM(() => tempVolume = v),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          _saveToHistory();
                          setState(() => item.volume = tempVolume);
                          Navigator.pop(ctx);
                          _showMessage(
                            'Volume: ${(tempVolume * 100).toInt()}%',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9FF),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
    );
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

        final isSelected = selectedClipId == item.id;
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
          // Handle rotation
          item.rotation = _initialRotation + details.rotation * 180 / math.pi;

          // Handle scale (REAL-TIME RESIZE)
          item.scale = (_initialScale * details.scale).clamp(0.3, 5.0);

          // Handle position
          item.x = (item.x ?? 0) + details.focalPointDelta.dx;
          item.y = (item.y ?? 0) + details.focalPointDelta.dy;

          // Keep within bounds
          final maxW =
              screenSize.width -
              (item.type == TimelineItemType.text ? 50 : 100) * item.scale;
          final maxH =
              screenSize.height -
              (item.type == TimelineItemType.text ? 30 : 100) * item.scale;
          item.x = item.x!.clamp(0.0, maxW);
          item.y = item.y!.clamp(0.0, maxH);
        });
      },
      onTap: () {
        if (item.type == TimelineItemType.text) {
          _showTextEditor(item);
        }
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00D9FF), width: 2),
            ),
            child: child,
          ),
          // Resize handle (bottom-right)
          Positioned(
            right: -8,
            bottom: -8,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF00D9FF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.open_in_full,
                size: 12,
                color: Colors.black,
              ),
            ),
          ),
          // Rotation handle (top-right)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.rotate_right,
                size: 12,
                color: Colors.white,
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

  void _showResizeDialog(TimelineItem item) {
    double tempDuration = item.duration.inSeconds.toDouble();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  padding: const EdgeInsets.all(20),
                  height: 280,
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
                      Text(
                        '${tempDuration.toInt()} seconds',
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Slider(
                        value: tempDuration,
                        min: 1,
                        max: 30,
                        divisions: 29,
                        activeColor: const Color(0xFF00D9FF),
                        label: '${tempDuration.toInt()}s',
                        onChanged: (v) {
                          setState(() => tempDuration = v);
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A2A2A),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _saveToHistory();
                                this.setState(() {
                                  item.duration = Duration(
                                    seconds: tempDuration.toInt(),
                                  );
                                });
                                Navigator.pop(context);
                                _showMessage('Duration updated');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D9FF),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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

  Widget _buildTimelineSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalDuration = _getTotalDuration();
    final totalWidth = math.max(totalDuration * pixelsPerSecond, screenWidth);

    return Container(
      color: const Color(0xFF000000),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          final deltaPx = details.delta.dx;
          final deltaSec = deltaPx / pixelsPerSecond;
          setState(() {
            playheadPosition += Duration(
              milliseconds: (deltaSec * 1000).round(),
            );
            final total = Duration(seconds: _getTotalDuration().toInt());
            playheadPosition = Duration(
              milliseconds: playheadPosition.inMilliseconds.clamp(
                0,
                total.inMilliseconds,
              ),
            );
            timelineOffset =
                playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
            if (_timelineScrollController.hasClients) {
              _timelineScrollController.jumpTo(timelineOffset);
            }
          });
          _updatePreview();
        },
        onScaleUpdate: (details) {
          if (details.scale == 1.0) return;
          setState(() {
            final oldPps = pixelsPerSecond;
            pixelsPerSecond = (pixelsPerSecond * details.scale).clamp(
              50.0,
              200.0,
            );
            final centerSec =
                timelineOffset / oldPps + screenWidth / 2 / oldPps;
            timelineOffset =
                (centerSec - screenWidth / 2 / pixelsPerSecond) *
                pixelsPerSecond;
            timelineOffset = timelineOffset.clamp(
              0.0,
              _getTotalDuration() * pixelsPerSecond,
            );
          });
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _timelineScrollController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: screenWidth,
                  maxWidth: math.max(totalWidth + screenWidth, screenWidth),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDurationRuler(),
                      const SizedBox(height: 8),
                      _buildVideoTrack(),
                      const SizedBox(height: 4),
                      _buildAudioTrack(),
                      const SizedBox(height: 4),
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
                    'Sound\nOn',
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
            right: 0,
            top: 0,
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
          // ...overlayItems.map((overlay) => _buildOverlayClip(overlay, centerX)),
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
    final selected = selectedClipId == item.id;
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

  void _showClipOptions(TimelineItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.content_cut,
                    color: Color(0xFF00D9FF),
                  ),
                  title: const Text(
                    'Split',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Move playhead to clip start before splitting
                    setState(() {
                      playheadPosition = item.startTime + (item.duration ~/ 2);
                      timelineOffset =
                          playheadPosition.inMilliseconds /
                          1000 *
                          pixelsPerSecond;
                    });
                    splitClipAtPlayhead();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.content_copy,
                    color: Color(0xFF00D9FF),
                  ),
                  title: const Text(
                    'Duplicate',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _duplicateClip();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.crop, color: Color(0xFF00D9FF)),
                  title: const Text(
                    'Crop',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showCropEditor();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.speed, color: Color(0xFF00D9FF)),
                  title: const Text(
                    'Speed',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showSpeedEditor();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteSelected();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTextClip(TimelineItem item, double centerX) {
    final selected = selectedClipId == item.id;
    final startX =
        item.startTime.inMilliseconds / 1000 * pixelsPerSecond - timelineOffset;
    final width = _clipWidth(item);

    return Positioned(
      left: startX + centerX,
      child: GestureDetector(
        onHorizontalDragStart: (_) => _isDraggingClip = true,
        onHorizontalDragUpdate: (d) {
          if (!_isDraggingClip) return;
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
        onHorizontalDragEnd: (_) => _isDraggingClip = false,
        onTap:
            () => setState(() {
              selectedClip = int.tryParse(item.id);
              // DO NOT change playheadPosition or timelineOffset
            }),
        onLongPress: () {
          setState(() => selectedClip = int.tryParse(item.id));
          _showResizeDialog(item);
        },
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
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;
    final totalSec = _getTotalDuration();
    final visibleSec = screenWidth / pixelsPerSecond;
    final centreSecond = timelineOffset / pixelsPerSecond;
    final halfScreenSec = visibleSec / 2;

    double step =
        pixelsPerSecond > 150
            ? 0.1
            : pixelsPerSecond > 80
            ? 0.5
            : 1.0;
    double start = (centreSecond - halfScreenSec).floorToDouble();
    double end = (centreSecond + halfScreenSec).ceilToDouble();

    List<Widget> ticks = [];
    for (double s = start; s <= end; s += step) {
      if (s < 0 || s > totalSec + 2) continue;
      final isMajor = (s % 1 == 0);
      final posX = centerX + (s * pixelsPerSecond) - timelineOffset;
      if (posX < 0 || posX > screenWidth) continue;

      ticks.add(
        Positioned(
          left: posX,
          top: 0,
          child: Column(
            children: [
              if (isMajor)
                Text(
                  _formatTime(Duration(seconds: s.toInt())),
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              const SizedBox(height: 4),
              Container(width: 1, height: isMajor ? 6 : 3, color: Colors.white),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 30,
      child: Stack(
        children: [
          Positioned.fill(
            top: 20,
            child: Container(height: 1, color: Colors.white30),
          ),
          ...ticks,
        ],
      ),
    );
  }

  void _duplicateClip() {
    final item = _activeItem;
    if (item == null) return;

    final newItem = item.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: item.startTime + item.duration,
    );

    // Share the same controller (safe)
    _controllers[newItem.id] = _controllers[item.id]!;

    _saveToHistory();
    setState(() => clips.add(newItem));
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

  Future<void> _addVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    _showLoading();
    try {
      final videoPath = file.path;
      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      await controller.seekTo(const Duration(milliseconds: 100));
      await controller.play();
      await Future.delayed(const Duration(milliseconds: 50));
      await controller.pause();

      // Optional: seek back to start if you want to show the very first frame
      await controller.seekTo(Duration.zero);

      final duration = controller.value.duration;

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
        cropX: 0.0,
        cropY: 0.0,
        cropWidth: 1.0,
        cropHeight: 1.0,
      );

      _controllers[item.id] = controller;
      _saveToHistory();

      setState(() {
        clips.add(item);
        clips.sort((a, b) => a.startTime.compareTo(b.startTime));
        selectedClip = int.parse(item.id);
        _activeItem = item;
        _activeVideoController = controller;
        playheadPosition = startTime;
        timelineOffset =
            playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
      });

      _updatePreview();
      _hideLoading();
      _showMessage('Video added: ${file.name}');
    } catch (e) {
      debugPrint('Error adding video: $e');
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

  void _addText() {
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
      fontSize: 36,
      scale: 1.0,
      layerIndex: _nextLayerIndex++,
    );

    setState(() {
      textItems.add(item);
      textItems.sort((a, b) => a.startTime.compareTo(b.startTime));
      _selection.select(item.id, item.type);
    });

    // Open text editor bottom sheet
    _showTextBottomSheet(item);
  }

  void _showTextBottomSheet(TimelineItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder:
                (_, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        // Header with search + Done
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search fonts, templates, animations...',
                                    hintStyle: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF2A2A2A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Done',
                                  style: TextStyle(
                                    color: Color(0xFF00D9FF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tab bar
                        const TabBar(
                          tabs: [
                            Tab(text: 'Templates'),
                            Tab(text: 'Fonts'),
                            Tab(text: 'Animation'),
                          ],
                          labelColor: Color(0xFF00D9FF),
                          unselectedLabelColor: Colors.white70,
                          indicatorColor: Color(0xFF00D9FF),
                        ),

                        // Tab content
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Templates
                              GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 1,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                    ),
                                itemCount: 15,
                                itemBuilder:
                                    (_, i) => Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Template',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                              ),

                              // Fonts
                              ListView.builder(
                                itemBuilder:
                                    (_, i) => ListTile(
                                      title: Text(
                                        'Font Style $i',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      onTap: () {
                                        setState(
                                          () => item.fontSize = 28.0 + i * 4,
                                        );
                                      },
                                    ),
                                itemCount: 30,
                              ),

                              // Animations
                              ListView(
                                children: [
                                  ListTile(
                                    title: const Text('Fade In'),
                                    onTap:
                                        () => setState(
                                          () => item.animationIn = 'fade_in',
                                        ),
                                  ),
                                  ListTile(
                                    title: const Text('Slide Up'),
                                    onTap:
                                        () => setState(
                                          () => item.animationIn = 'slide_up',
                                        ),
                                  ),
                                  ListTile(
                                    title: const Text('Bounce'),
                                    onTap:
                                        () => setState(
                                          () => item.animationIn = 'bounce',
                                        ),
                                  ),
                                  ListTile(
                                    title: const Text('Zoom In'),
                                    onTap:
                                        () => setState(
                                          () => item.animationIn = 'zoom_in',
                                        ),
                                  ),
                                  // Add more as needed
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
    bool useSpeedCurve = item.speedPoints.length > 2;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setM) => Container(
                  height: 500,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const Text(
                            'Speed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
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
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                color: Color(0xFF00D9FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${tempSpeed.toStringAsFixed(2)}x',
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Slider(
                        value: tempSpeed,
                        min: 0.1,
                        max: 10.0,
                        divisions: 99,
                        activeColor: const Color(0xFF00D9FF),
                        inactiveColor: Colors.white24,
                        label: '${tempSpeed.toStringAsFixed(2)}x',
                        onChanged: (v) => setM(() => tempSpeed = v),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children:
                            [
                              0.1,
                              0.25,
                              0.5,
                              0.75,
                              1.0,
                              1.25,
                              1.5,
                              2.0,
                              3.0,
                              5.0,
                              10.0,
                            ].map((s) {
                              final isSelected = (tempSpeed - s).abs() < 0.01;
                              return GestureDetector(
                                onTap: () => setM(() => tempSpeed = s),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
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
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const Spacer(),
                      // Advanced: Speed Curve button
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showSpeedCurveEditor();
                        },
                        icon: const Icon(
                          Icons.timeline,
                          color: Color(0xFF00D9FF),
                        ),
                        label: const Text(
                          'Advanced Speed Curve',
                          style: TextStyle(color: Color(0xFF00D9FF)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00D9FF)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showSpeedCurveEditor() {
    final item = getSelectedItem();
    if (item == null) return;

    // Initialize speed points if needed
    if (item.speedPoints.isEmpty) {
      item.speedPoints = [
        SpeedPoint(time: 0.0, speed: item.speed),
        SpeedPoint(time: 1.0, speed: item.speed),
      ];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SpeedCurveEditor(
              item: item,
              onSave: (points) {
                _saveToHistory();
                setState(() {
                  item.speedPoints = points;
                  // ✔ points is now defined
                });
                _showMessage('Speed curve applied');
              },
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

  void openToolPanel(String category) {
    setState(() {
      _activeToolCategory = category;
      _isToolPanelOpen = true;
      _isBottomNavCollapsed = true;
    });
    _toolPanelController.forward();
    _draggableController.animateTo(
      0.75,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void closeToolPanel() {
    _toolPanelController.reverse().then((_) {
      setState(() {
        _isToolPanelOpen = false;
        _activeToolCategory = null;
        _isBottomNavCollapsed = false;
      });
    });
    _draggableController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }
}
