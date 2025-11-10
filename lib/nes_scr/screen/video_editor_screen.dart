import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../model/eitor_state.dart';
import '../model/timeline_item.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen>
    with TickerProviderStateMixin {
  // ────── STATE ──────
  bool isPlaying = false;
  Duration playheadPosition = Duration.zero;
  int? selectedClip;
  double pixelsPerSecond = 80.0;
  double _totalDuration = 12.0;
  final ScrollController timelineScrollController = ScrollController();
  final Map<String, VideoPlayerController> _controllers = {};
  VideoPlayerController? _activePreviewController;
  List<VideoPlayerController> _activeAudioControllers = [];
  TimelineItem? _activeItem;
  late Ticker _playbackTicker;
  int _lastFrameTime = 0;
  double _initialRotation = 0.0;
  double _initialScale = 1.0;
  List<EditorState> history = [];
  int historyIndex = -1;

  // Tracks
  List<TimelineItem> clips = []; // Video
  List<TimelineItem> audioItems = []; // Audio (layered)
  List<TimelineItem> overlayItems = []; // Images
  List<TimelineItem> textItems = []; // Text

  // Resize state
  String? _resizeMode;
  Duration _initialStartTime = Duration.zero;
  Duration _initialDuration = Duration.zero;

  final double totalDuration = 12.0;

  Timer? playbackTimer;

  final ImagePicker _picker = ImagePicker();

  final Map<String, dynamic> _audioControllers = {};

  // ────── LIFECYCLE ──────
  @override
  void initState() {
    super.initState();
    _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
    _playbackTicker = createTicker(_playbackFrame)..start();
    _updateTotalDuration();
  }

  @override
  void dispose() {
    _playbackTicker.dispose();
    timelineScrollController.dispose();
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  // ────── HISTORY ──────
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
        _updateTotalDuration();
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
        _updateTotalDuration();
      });
    }
  }

  // ────── PLAYBACK ──────
  void _playbackFrame(Duration elapsed) {
    if (!mounted || !isPlaying) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final deltaMs = now - _lastFrameTime;
    _lastFrameTime = now;
    if (deltaMs <= 0 || deltaMs > 100) return;

    setState(() {
      playheadPosition += Duration(milliseconds: deltaMs);
      if (playheadPosition.inSeconds > _totalDuration) {
        playheadPosition = Duration(seconds: _totalDuration.toInt());
        isPlaying = false;
        _playbackTicker.stop();
      }
      selectedClip =
      getClipAtPlayhead()?.id != null
          ? int.parse(getClipAtPlayhead()!.id)
          : null;
    });
    _autoScrollTimeline();
    _updatePreview();
  }

  void togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
      if (isPlaying && playheadPosition.inSeconds >= _totalDuration) {
        playheadPosition = Duration.zero;
      }
    });
    if (isPlaying) {
      _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
      _playbackTicker.start();
    } else {
      _playbackTicker.stop();
    }
  }

  void _autoScrollTimeline() {
    if (!timelineScrollController.hasClients) return;
    const double leftPanelWidth = 180.0;
    final double playheadPixel =
        playheadPosition.inSeconds.toDouble() * pixelsPerSecond;
    final double target =
        leftPanelWidth + playheadPixel - MediaQuery.of(context).size.width / 2;
    final double maxScroll = timelineScrollController.position.maxScrollExtent;
    final double clamped = target.clamp(0.0, maxScroll);
    if ((clamped - timelineScrollController.offset).abs() > 5) {
      timelineScrollController.jumpTo(clamped);
    }
  }

  List<TimelineItem> _findActiveAudios() {
    return audioItems.where((item) {
      final effectiveDur = Duration(
        milliseconds: (item.duration.inMilliseconds / item.speed).round(),
      );
      return playheadPosition >= item.startTime &&
          playheadPosition < item.startTime + effectiveDur;
    }).toList();
  }
  void _updatePreview() {
    if (!mounted) return;
    final activeVideo = _findActiveVideo();
    setState(() => _activeItem = activeVideo);

    // Video
    if (activeVideo != null && _controllers.containsKey(activeVideo.id)) {
      final ctrl = _controllers[activeVideo.id]!;
      final local = playheadPosition - activeVideo.startTime;
      final source =
          activeVideo.trimStart +
              Duration(
                milliseconds: (local.inMilliseconds * activeVideo.speed).round(),
              );

      if ((ctrl.value.position - source).inMilliseconds.abs() > 100) {
        ctrl.seekTo(source);
      }
      ctrl.setPlaybackSpeed(activeVideo.speed);
      ctrl.setVolume(activeVideo.volume);

      if (isPlaying && !ctrl.value.isPlaying) ctrl.play();
      if (!isPlaying && ctrl.value.isPlaying) ctrl.pause();

      if (_activePreviewController != ctrl) {
        _activePreviewController?.pause();
        setState(() => _activePreviewController = ctrl);
      }
    } else {
      _activePreviewController?.pause();
      setState(() => _activePreviewController = null);
    }

    // Audio
    final activeAudios = _findActiveAudios();
    for (var ctrl in _activeAudioControllers) {
      if (!activeAudios.any((a) => _controllers[a.id] == ctrl)) ctrl.pause();
    }
    _activeAudioControllers = [];
    for (var item in activeAudios) {
      if (_controllers.containsKey(item.id)) {
        final ctrl = _controllers[item.id]!;
        final local = playheadPosition - item.startTime;
        final source =
            item.trimStart +
                Duration(milliseconds: (local.inMilliseconds * item.speed).round());
        if ((ctrl.value.position - source).inMilliseconds.abs() > 100) {
          ctrl.seekTo(source);
        }
        ctrl.setPlaybackSpeed(item.speed);
        ctrl.setVolume(item.volume);
        if (isPlaying && !ctrl.value.isPlaying) ctrl.play();
        if (!isPlaying && ctrl.value.isPlaying) ctrl.pause();
        _activeAudioControllers.add(ctrl);
      }
    }
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

  void _updateTotalDuration() {
    double maxEnd = 0.0;
    for (var list in [clips, audioItems, overlayItems, textItems]) {
      for (var item in list) {
        final end =
            item.startTime.inSeconds +
                (item.duration.inMilliseconds / 1000 / item.speed);
        if (end > maxEnd) maxEnd = end;
      }
    }
    _totalDuration = maxEnd > 0 ? maxEnd : 12.0;
  }

  // ────── TIMELINE INTERACTION ──────
  void handleTimelineClick(double localX) {
    if (timelineScrollController.hasClients) {
      final scrollOffset = timelineScrollController.offset;
      const double leftPanelWidth = 180.0;
      final clickPos =
          (localX + scrollOffset - leftPanelWidth) / pixelsPerSecond;
      setState(() {
        playheadPosition = Duration(
          seconds: (clickPos).clamp(0.0, _totalDuration).toInt(),
        );
        isPlaying = false;
        selectedClip =
        getClipAtPlayhead()?.id != null
            ? int.parse(getClipAtPlayhead()!.id)
            : null;
      });
    }
  }

  TimelineItem? getClipAtPlayhead() {
    for (final list in [clips, audioItems, overlayItems, textItems]) {
      for (final item in list) {
        final effectiveDur = Duration(
          milliseconds: (item.duration.inMilliseconds / item.speed).round(),
        );
        if (playheadPosition >= item.startTime &&
            playheadPosition < item.startTime + effectiveDur) {
          return item;
        }
      }
    }
    return null;
  }

  void splitClipAtPlayhead() {
    final clip = getClipAtPlayhead();
    if (clip == null || clip.type != TimelineItemType.video) return;
    final splitPoint = playheadPosition - clip.startTime;
    setState(() {
      clips.removeWhere((c) => c.id == clip.id);
      clips.add(clip.copyWith(duration: splitPoint));
      clips.add(
        clip.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          startTime: playheadPosition,
          duration: clip.duration - splitPoint,
        ),
      );
      clips.sort((a, b) => a.startTime.compareTo(b.startTime));
      _updateTotalDuration();
    });
    _showMessage('Clip split');
  }

  // ────── ADD MEDIA ──────
  Future<void> _addMedia(FileType type) async {
    final result = await FilePicker.platform.pickFiles(
      type: type,
      allowMultiple: true,
      allowedExtensions:
      type == FileType.video
          ? ['mp4', 'mov']
          : type == FileType.audio
          ? ['mp3', 'wav']
          : ['jpg', 'png', 'gif'],
    );
    if (result == null || result.files.isEmpty) return;
    _showLoading();
    try {
      List<TimelineItem> newItems = [];
      Duration maxDur = Duration.zero;

      for (var f in result.files) {
        final path = f.path!;
        final file = File(path);
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        TimelineItemType itemType;
        Duration dur = const Duration(seconds: 5);
        List<String> thumbs = [];
        VideoPlayerController? ctrl;

        if (path.endsWith('.mp4') || path.endsWith('.mov')) {
          itemType = TimelineItemType.video;
          ctrl = VideoPlayerController.file(file);
          await ctrl.initialize();
          dur = ctrl.value.duration;
          final dir = await getTemporaryDirectory();
          for (int i = 0; i < 10; i++) {
            final ms = (dur.inMilliseconds * i / 9).round();
            final thumbPath = await VideoThumbnail.thumbnailFile(
              video: path,
              thumbnailPath: dir.path,
              imageFormat: ImageFormat.PNG,
              maxWidth: 100,
              timeMs: ms,
            );
            if (thumbPath != null) thumbs.add(thumbPath);
          }
          _controllers[id] = ctrl;
          await ctrl.setLooping(false);
        } else if (path.endsWith('.mp3') || path.endsWith('.wav')) {
          itemType = TimelineItemType.audio;
          ctrl = VideoPlayerController.file(file);
          await ctrl.initialize();
          dur = ctrl.value.duration;
          _controllers[id] = ctrl;
          await ctrl.setLooping(false);
        } else {
          itemType = TimelineItemType.image;
          thumbs = [path];
        }

        final item = TimelineItem(
          id: id,
          type: itemType,
          file: file,
          startTime: Duration.zero,
          duration: dur,
          originalDuration: dur,
          thumbnailPaths: thumbs,
        );
        newItems.add(item);
        if (dur > maxDur) maxDur = dur;
      }

      setState(() {
        if (clips.isEmpty &&
            audioItems.isEmpty &&
            overlayItems.isEmpty &&
            textItems.isEmpty) {
          // New project → align all at 0, same duration
          for (var item in newItems) {
            item.startTime = Duration.zero;
            item.duration = maxDur;
            _addToTrack(item);
          }
        } else {
          Duration pos = playheadPosition;
          for (var item in newItems) {
            item.startTime = pos;
            if (item.type == TimelineItemType.audio) {
              item.startTime = Duration.zero;
              item.duration =
                  Duration(seconds: _totalDuration.toInt()) + maxDur;
            } else if (item.type == TimelineItemType.image) {
              item.duration =
              maxDur > Duration.zero ? maxDur : const Duration(seconds: 5);
            }
            _addToTrack(item);
            pos += item.duration;
          }
        }
        _updateTotalDuration();
        if (newItems.isNotEmpty) selectedClip = int.parse(newItems.last.id);
      });
      _hideLoading();
      _showMessage('Media added');
    } catch (e) {
      _hideLoading();
      _showError('Failed: $e');
    }
  }
  void _addToTrack(TimelineItem item) {
    switch (item.type) {
      case TimelineItemType.video:
        clips.add(item);
        break;
      case TimelineItemType.audio:
        audioItems.add(item);
        break;
      case TimelineItemType.image:
        overlayItems.add(item);
        break;
      case TimelineItemType.text:
        textItems.add(item);
        break;
    }
  }

  Future<void> _addVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    _showLoading();
    try {
      final tempCtrl = VideoPlayerController.file(File(file.path));
      await tempCtrl.initialize();
      final duration = tempCtrl.value.duration;
      final dir = await getTemporaryDirectory();
      final thumbs = <String>[];
      for (int i = 0; i < 10; i++) {
        final ms = (duration.inMilliseconds * i / 9).round();
        final path = await VideoThumbnail.thumbnailFile(
          video: file.path,
          thumbnailPath: dir.path,
          imageFormat: ImageFormat.PNG,
          maxWidth: 100,
          timeMs: ms,
        );
        if (path != null) thumbs.add(path);
      }
      final startTime = clips.isEmpty
          ? Duration.zero
          : clips
          .map((i) => i.startTime + i.duration)
          .reduce((a, b) => a > b ? a : b);
      final item = TimelineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TimelineItemType.video,
        file: File(file.path),
        startTime: startTime,
        duration: duration,
        originalDuration: duration,
        thumbnailPaths: thumbs,
      );
      _controllers[item.id] = tempCtrl;
      await tempCtrl.setLooping(false);
      setState(() {
        clips.add(item);
        selectedClip = int.parse(item.id);
        _activePreviewController = tempCtrl;
      });
      _hideLoading();
      _showMessage('Video added: ${file.name}');
    } catch (e) {
      _hideLoading();
      _showError('Failed to pick video: $e');
    }
  }

  Future<void> _addAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) {
      _showError('Invalid file path');
      return;
    }
    final item = TimelineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TimelineItemType.audio,
      file: File(path),
      startTime: Duration.zero,
      duration: const Duration(seconds: 10),
      originalDuration: const Duration(seconds: 10),
    );
    setState(() {
      audioItems.add(item);
      selectedClip = int.parse(item.id);
    });
    _showMessage('Audio added: ${result.files.first.name}');
  }

  Future<void> _addImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final item = TimelineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TimelineItemType.image,
      file: File(file.path),
      startTime: playheadPosition,
      duration: const Duration(seconds: 5),
      originalDuration: const Duration(seconds: 5),
      x: 50,
      y: 100,
    );
    setState(() {
      overlayItems.add(item);
      selectedClip = int.parse(item.id);
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
    );
    setState(() {
      textItems.add(item);
      selectedClip = int.parse(item.id);
      _updateTotalDuration();
    });
    _showMessage('Text added');
    Future.delayed(const Duration(milliseconds: 100), () {
      if (textItems.isNotEmpty) _showTextEditor(textItems.last);
    });
  }

  // ────── UI HELPERS ──────
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

  String _formatTime(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).floor();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _resizeHandle({required bool isLeft}) {
    return Container(
      width: 16,
      height: double.infinity,
      color: Colors.white.withOpacity(0.4),
      alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
      child: Icon(
        isLeft ? Icons.chevron_left : Icons.chevron_right,
        size: 14,
        color: Colors.black87,
      ),
    );
  }

  // ────── CLIP WIDGET (with handles) ──────
  Widget _buildClipWidget(TimelineItem item, TimelineItemType trackType) {
    final isSel = selectedClip == int.tryParse(item.id);
    final width =
        (item.duration.inMilliseconds / 1000 / item.speed) * pixelsPerSecond;

    late Color bgColor;
    late Widget inner;
    final double height = trackType == TimelineItemType.video ? 56.0 : 26.0;

    switch (trackType) {
      case TimelineItemType.video:
        bgColor = Colors.grey[800]!;
        inner =
        item.thumbnailPaths.isNotEmpty
            ? Image.file(File(item.thumbnailPaths.first), fit: BoxFit.cover)
            : const Icon(Icons.videocam, color: Colors.white70);
        break;
      case TimelineItemType.audio:
        bgColor = Colors.blue[900]!;
        inner = Text(
          item.fileName,
          style: const TextStyle(fontSize: 10, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        );
        break;
      case TimelineItemType.image:
        bgColor = Colors.green[900]!;
        inner =
        item.thumbnailPaths.isNotEmpty
            ? Image.file(File(item.thumbnailPaths.first), fit: BoxFit.cover)
            : const Icon(Icons.image, color: Colors.white70);
        break;
      case TimelineItemType.text:
        bgColor = Colors.yellow[900]!;
        inner = Text(
          item.text ?? 'Text',
          style: const TextStyle(fontSize: 10, color: Colors.black),
        );
        break;
      default:
        bgColor = Colors.grey;
        inner = const SizedBox();
    }

    return GestureDetector(
      onPanStart: (d) {
        _resizeMode = null;
        final box = context.findRenderObject() as RenderBox;
        final localX = box.globalToLocal(d.globalPosition).dx;
        if (localX < 20) {
          _resizeMode = 'left';
        } else if (localX > width - 20) {
          _resizeMode = 'right';
        } else {
          _resizeMode = 'move';
        }
        _initialStartTime = item.startTime;
        _initialDuration = item.duration;
      },
      onPanUpdate: (d) {
        final deltaSec = d.delta.dx / pixelsPerSecond;
        final delta = Duration(milliseconds: (deltaSec * 1000).round());
        setState(() {
          if (_resizeMode == 'left') {
            final newStart = _initialStartTime + delta;
            final newDur = _initialDuration - delta;
            if (newStart >= Duration.zero && newDur.inSeconds > 1) {
              item.startTime = newStart;
              item.duration = newDur;
            }
          } else if (_resizeMode == 'right') {
            final newDur = _initialDuration + delta;
            if (newDur.inSeconds > 1) item.duration = newDur;
          } else if (_resizeMode == 'move') {
            final newStart = _initialStartTime + delta;
            if (newStart >= Duration.zero &&
                newStart + Duration(seconds: item.duration.inSeconds) <=
                    Duration(seconds: _totalDuration.toInt() + 10)) {
              item.startTime = newStart;
            }
          }
          _updateTotalDuration();
        });
      },
      onTap: () => setState(() => selectedClip = int.tryParse(item.id)),
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSel ? const Color(0xFF8B5CF6) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Center(child: inner),
            ),
            if (isSel) ...[
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: _resizeHandle(isLeft: true),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: _resizeHandle(isLeft: false),
              ),
            ],
          ],
        ),
      ),
    );
  }


  // ────── BUILD ──────
  @override
  Widget build(BuildContext context) {
    final clipAtHead = getClipAtPlayhead();
    final showSplit =
        clipAtHead != null &&
            !isPlaying &&
            clipAtHead.type == TimelineItemType.video;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildPreview()),
            _buildPlaybackControls(),
            _buildTimeline(showSplit),
            if (selectedClip != null) _buildBottomToolbar(showSplit),
            _buildBottomNavigation(),
            _buildSystemBar(),
          ],
        ),
      ),
    );
  }

  // ────── TOP BAR ──────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.close, size: 22),
              SizedBox(width: 12),
              Icon(Icons.help_outline, size: 22),
            ],
          ),
          GestureDetector(
            onTap: () => _showMessage('Exporting...'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  // ────── PREVIEW ──────
  Widget _buildPreview() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_activePreviewController != null &&
                      _activePreviewController!.value.isInitialized)
                    VideoPlayer(_activePreviewController!)
                  else
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.video_library,
                              size: 60,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              clips.isEmpty ? 'Add media to start' : 'Preview',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ..._buildTextOverlays(),
                  ..._buildImageOverlays(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTextOverlays() {
    final List<Widget> list = [];
    for (final item in textItems) {
      if (playheadPosition >= item.startTime &&
          playheadPosition < item.startTime + item.duration) {
        Widget child = Transform.rotate(
          angle: item.rotation * math.pi / 180,
          child: Transform.scale(
            scale: item.scale,
            child: Text(
              item.text ?? '',
              style: TextStyle(
                color: item.textColor ?? Colors.white,
                fontSize: item.fontSize ?? 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        if (selectedClip == int.tryParse(item.id)) {
          child = GestureDetector(
            onPanUpdate:
                (d) => setState(() {
              item.x = (item.x ?? 0) + d.delta.dx;
              item.y = (item.y ?? 0) + d.delta.dy;
            }),
            onScaleStart: (d) {
              _initialRotation = item.rotation;
              _initialScale = item.scale;
            },
            onScaleUpdate:
                (d) => setState(() {
              item.rotation = _initialRotation + d.rotation * 180 / math.pi;
              item.scale = (_initialScale * d.scale).clamp(0.5, 3.0);
            }),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00D9FF), width: 2),
              ),
              child: child,
            ),
          );
        }
        list.add(
          Positioned(left: item.x ?? 100, top: item.y ?? 200, child: child),
        );
      }
    }
    return list;
  }

  List<Widget> _buildImageOverlays() {
    final List<Widget> list = [];
    for (final item in overlayItems) {
      if (playheadPosition >= item.startTime &&
          playheadPosition < item.startTime + item.duration &&
          item.file != null) {
        Widget child = Transform.rotate(
          angle: item.rotation * math.pi / 180,
          child: Transform.scale(
            scale: item.scale,
            child: Image.file(
              item.file!,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
        );
        if (selectedClip == int.tryParse(item.id)) {
          child = GestureDetector(
            onPanUpdate:
                (d) => setState(() {
              item.x = (item.x ?? 0) + d.delta.dx;
              item.y = (item.y ?? 0) + d.delta.dy;
            }),
            onScaleStart: (d) {
              _initialRotation = item.rotation;
              _initialScale = item.scale;
            },
            onScaleUpdate:
                (d) => setState(() {
              item.rotation = _initialRotation + d.rotation * 180 / math.pi;
              item.scale = (_initialScale * d.scale).clamp(0.3, 2.0);
            }),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00D9FF), width: 2),
              ),
              child: child,
            ),
          );
        }
        list.add(
          Positioned(left: item.x ?? 50, top: item.y ?? 100, child: child),
        );
      }
    }
    return list;
  }

  // ────── PLAYBACK CONTROLS ──────
  Widget _buildPlaybackControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: togglePlayPause,
            child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 32),
          ),
          _buildTimeDisplay(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ON',
                  style: TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.rotate_left, size: 20),
              const SizedBox(width: 16),
              const Icon(Icons.rotate_right, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  // ────── TIME DISPLAY ──────
  Widget _buildTimeDisplay() {
    return Row(
      children: [
        Text(
          _formatTime(playheadPosition.inSeconds.toDouble()),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const Text(
          ' / ',
          style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        Text(
          _formatTime(_totalDuration),
          style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
        ),
      ],
    );
  }

  // ────── TIMELINE ──────
  Widget _buildTimeline(bool showSplit) {
    const double leftPanelWidth = 180.0;
    final double playheadX =
        playheadPosition.inSeconds.toDouble() * pixelsPerSecond;

    return Container(
      height: 140,
      color: const Color(0xFF0A0A0A),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left panel
          Container(
            width: leftPanelWidth,
            color: const Color(0xFF1A1A1A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_buildMuteButton(), _buildCoverButton()],
            ),
          ),
          // Scrollable tracks
          Expanded(
            child: SingleChildScrollView(
              controller: timelineScrollController,
              scrollDirection: Axis.horizontal,
              child: GestureDetector(
                onTapDown: (d) => handleTimelineClick(d.localPosition.dx),
                child: Stack(
                  children: [
                    // Tracks
                    Column(
                      children: [
                        // Video
                        Container(
                          height: 60,
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: Stack(
                            children: [
                              ...clips.map(
                                    (c) => Positioned(
                                  left: c.startTime.inSeconds * pixelsPerSecond,
                                  child: _buildClipWidget(
                                    c,
                                    TimelineItemType.video,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                child: _buildAddClipButton(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Audio
                        Container(
                          height: 30,
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: Stack(
                            children: [
                              ...audioItems.map(
                                    (a) => Positioned(
                                  left: a.startTime.inSeconds * pixelsPerSecond,
                                  child: _buildClipWidget(
                                    a,
                                    TimelineItemType.audio,
                                  ),
                                ),
                              ),
                              if (audioItems.isEmpty)
                                 Positioned(
                                  left: 0,
                                  child: _buildAudioPlaceholder(),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Overlay (images + text)
                        Container(
                          height: 30,
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: Stack(
                            children: [
                              ...overlayItems.map(
                                    (o) => Positioned(
                                  left: o.startTime.inSeconds * pixelsPerSecond,
                                  child: _buildClipWidget(
                                    o,
                                    TimelineItemType.image,
                                  ),
                                ),
                              ),
                              ...textItems.map(
                                    (t) => Positioned(
                                  left: t.startTime.inSeconds * pixelsPerSecond,
                                  child: _buildClipWidget(
                                    t,
                                    TimelineItemType.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Playhead
                    Positioned(
                      left: playheadX,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          final deltaSec = d.delta.dx / pixelsPerSecond;
                          final newPos =
                              playheadPosition +
                                  Duration(milliseconds: (deltaSec * 1000).round());
                          setState(() {
                            playheadPosition = newPos.clamp(
                              Duration.zero,
                              Duration(seconds: _totalDuration.toInt()),
                            );
                            selectedClip =
                            getClipAtPlayhead()?.id != null
                                ? int.parse(getClipAtPlayhead()!.id)
                                : null;
                          });
                        },
                        child: Container(
                          width: 2,
                          color: const Color(0xFF8B5CF6),
                          child: const Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                    ),
                    // Split button
                    if (showSplit)
                      Positioned(
                        left: playheadX - 40,
                        top: 20,
                        child: GestureDetector(
                          onTap: () {
                            _saveToHistory();
                            splitClipAtPlayhead();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D9FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.content_cut,
                                  size: 12,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Split',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildMuteButton() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: const [
      Icon(Icons.volume_up, size: 18, color: Colors.white),
      Text('ON', style: TextStyle(fontSize: 10, color: Colors.white)),
    ],
  );

  Widget _buildCoverButton() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 32,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white30),
        ),
        child:
        clips.isNotEmpty && clips[0].thumbnailPaths.isNotEmpty
            ? ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(
            File(clips[0].thumbnailPaths[0]),
            fit: BoxFit.cover,
          ),
        )
            : const Icon(Icons.image, size: 14, color: Colors.white30),
      ),
      const Text('Cover', style: TextStyle(fontSize: 10, color: Colors.white)),
    ],
  );



  Widget _buildAddClipButton() => GestureDetector(
    onTap: () {
      _saveToHistory();
      _addMedia(FileType.video);
    },
    child: Container(
      width: 50,
      height: 56,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: const Center(
        child: Icon(Icons.add, color: Colors.white, size: 24),
      ),
    ),
  );

  Widget _buildAudioPlaceholder() => InkWell(
    onTap: () {
      _saveToHistory();
      _addMedia(FileType.audio);
    },
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.audiotrack, size: 16, color: Colors.white54),
          SizedBox(width: 6),
          Text(
            'Add Audio',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    ),
  );

  // ────── BOTTOM TOOLBAR ──────
  Widget _buildBottomToolbar(bool showSplit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF444444))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolbarBtn(Icons.audiotrack, 'Sounds',
                    () => _showMessage('Sounds')),
            _toolbarBtn(Icons.content_cut, 'Split',
                showSplit ? splitClipAtPlayhead : null,
                enabled: showSplit),
            _toolbarBtn(Icons.volume_up, 'Volume', _showVolumeEditor),
            _toolbarBtn(Icons.auto_awesome, 'Fade',
                    () => _showMessage('Fade')),
            _toolbarBtn(Icons.delete, 'Delete', _deleteSelected,
                color: Colors.red),
            _toolbarBtn(Icons.speed, 'Speed', _showSpeedEditor),
            _toolbarBtn(Icons.crop, 'Crop', () => _showMessage('Crop')),
            _toolbarBtn(Icons.more_horiz, 'More',
                    () => _showMessage('More')),
          ],
        ),
      ),
    );
  }

  Widget _toolbarBtn(IconData icon, String label, VoidCallback? onTap,
      {bool enabled = true, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(fontSize: 11, color: color ?? Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  // ────── BOTTOM NAVIGATION ──────
  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navBtn(Icons.content_cut, 'Edit',
                  () => _showMessage('Edit tools')),
          _navBtn(Icons.audiotrack, 'Audio', _addAudio),
          _navBtn(Icons.text_fields, 'Text', () {
            _saveToHistory();
            _addText();
          }),
          _navBtn(Icons.auto_awesome, 'Effects',
                  () => _showMessage('Effects')),
          _navBtn(Icons.layers, 'Overlay', _addImage),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  // ────── SYSTEM BAR ──────
  Widget _buildSystemBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Icon(Icons.menu, size: 24),
          GestureDetector(onTap: _undo, child: const Icon(Icons.undo, size: 24)),
          GestureDetector(
              onTap: togglePlayPause,
              child:
              Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 24)),
          GestureDetector(onTap: _redo, child: const Icon(Icons.redo, size: 24)),
        ],
      ),
    );
  }

  // ────── EDITORS (Volume / Speed / Text) ──────
  void _showVolumeEditor() {
    if (selectedClip == null) return;
    TimelineItem? item;
    for (final c in [...clips, ...audioItems]) {
      if (int.tryParse(c.id) == selectedClip) {
        item = c;
        break;
      }
    }
    if (item == null) return;
    double temp = item.volume;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Volume',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text('${(temp * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 24)),
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Apply',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpeedEditor() {
    if (selectedClip == null) return;
    TimelineItem? item;
    for (final c in [...clips, ...audioItems]) {
      if (int.tryParse(c.id) == selectedClip) {
        item = c;
        break;
      }
    }
    if (item == null) return;
    double temp = item.speed;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Container(
          height: 300,
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              const Text('Speed',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text('${temp.toStringAsFixed(2)}x',
                  style: const TextStyle(color: Colors.white, fontSize: 24)),
              Slider(
                value: temp,
                min: 0.25,
                max: 4,
                divisions: 15,
                activeColor: const Color(0xFF00D9FF),
                onChanged: (v) => setM(() => temp = v),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [0.25, 0.5, 1.0, 2.0, 4.0].map((s) {
                  return ElevatedButton(
                    onPressed: () => setM(() => temp = s),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      temp == s ? const Color(0xFF00D9FF) : const Color(0xFF2A2A2A),
                      foregroundColor:
                      temp == s ? Colors.black : Colors.white,
                    ),
                    child: Text('${s}x'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final oldDur = item!.duration;
                  setState(() {
                    item?.speed = temp;
                    item?.duration = Duration(
                      milliseconds: (oldDur.inMilliseconds / temp).round(),
                    );
                  });
                  Navigator.pop(ctx);
                  _showMessage('Speed: ${temp.toStringAsFixed(2)}x');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  foregroundColor: Colors.black,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Apply',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
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
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: 450,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Edit Text',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter text',
                    hintStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00D9FF))),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Color',
                    style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
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
                              color: sel
                                  ? const Color(0xFF00D9FF)
                                  : Colors.transparent,
                              width: 3),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Font Size',
                    style: TextStyle(color: Colors.white)),
                Slider(
                  value: tempSize,
                  min: 10,
                  max: 100,
                  activeColor: const Color(0xFF00D9FF),
                  onChanged: (v) => setM(() => tempSize = v),
                ),
                Text('${tempSize.toInt()}',
                    style: const TextStyle(color: Colors.white)),
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
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Apply',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteSelected() {
    if (selectedClip == null) return;
    setState(() {
      clips.removeWhere((c) => int.tryParse(c.id) == selectedClip);
      audioItems.removeWhere((c) => int.tryParse(c.id) == selectedClip);
      textItems.removeWhere((c) => int.tryParse(c.id) == selectedClip);
      overlayItems.removeWhere((c) => int.tryParse(c.id) == selectedClip);
      selectedClip = null;
    });
    _showMessage('Deleted');
  }
}

class _TimelineRulerPainter extends CustomPainter {
  final double pixelsPerSecond;
  final double totalDuration;

  _TimelineRulerPainter({
    required this.pixelsPerSecond,
    required this.totalDuration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final double width = size.width;

    // Draw second lines and labels
    for (int sec = 0; sec <= totalDuration; sec++) {
      final double x = sec * pixelsPerSecond;

      // Long tick (every 1 second)
      canvas.drawLine(
        Offset(x, 20),
        Offset(x, 30),
        paint..strokeWidth = 1.5,
      );

      // Short tick (every 0.2s)
      for (double sub = 0.2; sub < 1.0; sub += 0.2) {
        final double subX = x + sub * pixelsPerSecond;
        if (subX < width) {
          canvas.drawLine(
            Offset(subX, 25),
            Offset(subX, 30),
            paint..strokeWidth = 1,
          );
        }
      }

      // Time label (every 1 second)
      if (x < width) {
        final String label = _formatTime(sec.toDouble());
        textPainter.text = TextSpan(
          text: label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, 4));
      }
    }
  }

  String _formatTime(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).floor();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}