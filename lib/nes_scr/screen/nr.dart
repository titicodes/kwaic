import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
import '../widgets/wave_form_painter.dart' show WaveformPainter;

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> with TickerProviderStateMixin {
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
  VideoPlayerController? _activeVideoController; // Only video
  VideoPlayerController? _activeAudioController; // Only audio

  // Export settings
  String exportResolution = '1080p';
  int exportBitrate = 5000; // kbps
  bool removeWatermark = false; // Pro feature simulation

  @override
  void initState() {
    super.initState();
    _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
    _playbackTicker = createTicker(_playbackFrame); // DO NOT start here
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
    _playbackTicker.stop(); // Always stop
    _playbackTicker.dispose();
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
      final maxDuration = _getTotalDuration();
      if (playheadPosition.inMilliseconds >= maxDuration * 1000) {
        playheadPosition = Duration(milliseconds: (maxDuration * 1000).toInt());
        isPlaying = false;
        _playbackTicker.stop();
      }
      timelineOffset = playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
    });
    _updatePreview();
  }

  double _getTotalDuration() {
    double maxDur = 0.0;
    if (clips.isNotEmpty) {
      final clipEnd = clips
          .map((c) => (c.startTime + c.duration).inSeconds.toDouble())
          .reduce(math.max);
      maxDur = math.max(maxDur, clipEnd);
    }
    if (audioItems.isNotEmpty) {
      final audioEnd = audioItems
          .map((a) => (a.startTime + a.duration).inSeconds.toDouble())
          .reduce(math.max);
      maxDur = math.max(maxDur, audioEnd);
    }
    if (textItems.isNotEmpty) {
      final textEnd = textItems
          .map((t) => (t.startTime + t.duration).inSeconds.toDouble())
          .reduce(math.max);
      maxDur = math.max(maxDur, textEnd);
    }
    if (overlayItems.isNotEmpty) {
      final overlayEnd = overlayItems
          .map((o) => (o.startTime + o.duration).inSeconds.toDouble())
          .reduce(math.max);
      maxDur = math.max(maxDur, overlayEnd);
    }
    return maxDur;
  }

  void _updatePreview() {
    if (!mounted) return;
    final activeVideo = _findActiveVideo();
    final activeAudio = _findActiveAudio(); // New helper

    // === VIDEO ===
    if (activeVideo != null && _controllers.containsKey(activeVideo.id)) {
      final ctrl = _controllers[activeVideo.id]!;
      final local = playheadPosition - activeVideo.startTime;
      final source = activeVideo.trimStart + Duration(milliseconds: (local.inMilliseconds * activeVideo.speed).round());
      if ((ctrl.value.position - source).inMilliseconds.abs() > 100) {
        ctrl.seekTo(source);
      }
      ctrl.setPlaybackSpeed(activeVideo.speed);
      ctrl.setVolume(activeVideo.volume);
      if (isPlaying && !ctrl.value.isPlaying) ctrl.play();
      if (!isPlaying && ctrl.value.isPlaying) ctrl.pause();
      if (_activeVideoController != ctrl) {
        _activeVideoController?.pause();
        setState(() {
          _activeVideoController = ctrl;
          _activeItem = activeVideo; // Fixed: Update _activeItem to match active video
        });
      }
    } else {
      _activeVideoController?.pause();
      setState(() {
        _activeVideoController = null;
        _activeItem = null; // Fixed: Clear _activeItem when no active video
      });
    }

    // === AUDIO ===
    for (final item in audioItems) {
      if (_audioControllers.containsKey(item.id)) {
        final ctrl = _audioControllers[item.id]!;
        final effectiveDur = Duration(milliseconds: (item.duration.inMilliseconds / item.speed).round());
        if (playheadPosition >= item.startTime && playheadPosition < item.startTime + effectiveDur) {
          final local = playheadPosition - item.startTime;
          final source = item.trimStart + Duration(milliseconds: (local.inMilliseconds * item.speed).round());
          if ((ctrl.value.position - source).inMilliseconds.abs() > 100) {
            ctrl.seekTo(source);
          }
          ctrl.setPlaybackSpeed(item.speed);
          ctrl.setVolume(item.volume);
          if (isPlaying && !ctrl.value.isPlaying) ctrl.play();
          if (!isPlaying && ctrl.value.isPlaying) ctrl.pause();
        } else {
          ctrl.pause();
        }
      }
    }
  }

  TimelineItem? _findActiveVideo() {
    for (final item in clips) {
      final effectiveDur = Duration(
        milliseconds: (item.duration.inMilliseconds / item.speed).round(),
      );
      if (playheadPosition >= item.startTime && playheadPosition < item.startTime + effectiveDur) {
        return item;
      }
    }
    return null;
  }

  TimelineItem? _findActiveAudio() {
    for (final item in audioItems) {
      final effectiveDur = Duration(milliseconds: (item.duration.inMilliseconds / item.speed).round());
      if (playheadPosition >= item.startTime && playheadPosition < item.startTime + effectiveDur) {
        return item;
      }
    }
    return null;
  }

  TimelineItem? getClipAtPlayhead() {
    for (final clip in clips) {
      if (playheadPosition >= clip.startTime && playheadPosition < clip.startTime + clip.duration) {
        return clip;
      }
    }
    return null;
  }

  void splitClipAtPlayhead() {
    final clip = getClipAtPlayhead();
    if (clip == null || playheadPosition <= clip.startTime || playheadPosition >= clip.startTime + clip.duration) return;
    final splitPoint = playheadPosition - clip.startTime;
    setState(() {
      clips.removeWhere((c) => c.id == clip.id);
      clips.add(clip.copyWith(duration: splitPoint));
      clips.add(
        clip.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          startTime: playheadPosition,
          duration: clip.duration - splitPoint,
          trimStart: clip.trimStart + splitPoint,
        ),
      );
      clips.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
    _showMessage('Clip split');
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
      for (int i = 0; i < 5; i++) { // Reduced to 5 for performance
        final ms = (duration.inMilliseconds * i / 4).round();
        final path = await VideoThumbnail.thumbnailFile(
          video: file.path,
          thumbnailPath: dir.path,
          imageFormat: ImageFormat.PNG,
          maxWidth: 100,
          timeMs: ms,
        );
        if (path != null) thumbs.add(path);
      }
      final startTime = clips.isEmpty ? Duration.zero : clips
          .map((i) => i.startTime + i.duration)
          .reduce((a, b) => a > b ? a : b);
      final item = TimelineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TimelineItemType.video,
        file: File(file.path),
        startTime: startTime,
        duration: duration,
        originalDuration: duration,
        trimStart: Duration.zero,
        trimEnd: duration,
        thumbnailPaths: thumbs,
        cropLeft: 0.0,
        cropTop: 0.0,
        cropRight: 0.0,
        cropBottom: 0.0,
      );
      _controllers[item.id] = tempCtrl;
      await tempCtrl.setLooping(false);
      setState(() {
        clips.add(item);
        clips.sort((a, b) => a.startTime.compareTo(b.startTime));
        selectedClip = int.parse(item.id);
        _activeItem = item;
        _activePreviewController = tempCtrl;
        playheadPosition = startTime;
        timelineOffset = playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
      });
      _updatePreview();
      _hideLoading();
      _showMessage('Video added: ${file.name}');
    } catch (e) {
      _hideLoading();
      _showError('Failed to add video: $e');
    }
  }

  Future<void> _updateThumbnails(TimelineItem item) async {
    if (item.type != TimelineItemType.video || item.file == null) return;
    final dir = await getTemporaryDirectory();
    final thumbs = <String>[];
    final effectiveDur = item.duration.inMilliseconds;
    for (int i = 0; i < 5; i++) { // Reduced to 5 for performance
      final ms = item.trimStart.inMilliseconds + (effectiveDur * i / 4).round();
      final path = await VideoThumbnail.thumbnailFile(
        video: item.file!.path,
        thumbnailPath: dir.path,
        imageFormat: ImageFormat.PNG,
        maxWidth: 100,
        timeMs: ms,
      );
      if (path != null) thumbs.add(path);
    }
    setState(() {
      item.thumbnailPaths = thumbs;
    });
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

  void _showLoading() => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
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

  // New: Export functionality
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
      final outputPath = '${dir.path}/exported_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

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
      command += '-filter_complex "concat=n=${clips.length}:v=1:a=0[outv];[0:a]'; // Video concat
      if (audioItems.isNotEmpty) {
        command += '[1:a]amix=inputs=2:duration=longest[outa]'; // Simple audio mix
      }
      command += '" -map "[outv]" -map "[outa]" -c:v libx264 -preset fast -crf 23 -c:a aac -b:v ${exportBitrate}k $outputPath';

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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Export Settings', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: exportResolution,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  items: ['720p', '1080p', '4K'].map((String value) {
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
                  title: const Text('Remove Watermark (Pro)', style: TextStyle(color: Colors.white)),
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
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportVideo();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D9FF)),
            child: const Text('Export', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF000000),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 380;
          return Row(
            children: [
              const Row(
                children: [
                  Icon(Icons.arrow_back, size: 24, color: Colors.white),
                  SizedBox(width: 16),
                  Icon(Icons.help_outline, size: 24, color: Colors.white),
                ],
              ),
              const Spacer(),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.more_horiz,
                              size: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showExportSettings, // Updated to actual export
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Export',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPreview() {
    final screenSize = MediaQuery.of(context).size;
    final visualItems = [...textItems, ...overlayItems]
      ..sort((a, b) => (a.layerIndex ?? 999999).compareTo(b.layerIndex ?? 999999));
    Widget videoWidget;
    if (_activeVideoController != null && _activeVideoController!.value.isInitialized) {
      videoWidget = _buildCroppedVideoPlayer(_activeVideoController!, _activeItem!);
    } else {
      videoWidget = Container(
        color: const Color(0xFF1A1A1A),
        child: const Center(
          child: Text(
            'Add a video to start editing',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ),
      );
    }
    // Apply real-time effect preview
    if (selectedEffect != null) {
      videoWidget = _applyEffect(videoWidget);
    }
    return Container(
      width: double.infinity,
      color: const Color(0xFF000000),
      child: Stack(
        fit: StackFit.expand,
        children: [
          videoWidget,
          // Overlays
          ..._buildVisualOverlays(screenSize, visualItems),
        ],
      ),
    );
  }

  Widget _applyEffect(Widget child) {
    switch (selectedEffect) {
      case 'Blur':
        return ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: child,
          ),
        );
      case 'Vintage':
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.393, 0.769, 0.189, 0, 0,
            0.349, 0.686, 0.168, 0, 0,
            0.272, 0.534, 0.131, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: child,
        );
      case 'B&W':
        return ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: child,
        );
      case 'Glitch':
      // Simple glitch simulation using overlay color shifts
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.red, BlendMode.colorDodge),
                child: Transform.translate(
                  offset: const Offset(2, 0),
                  child: child,
                ),
              ),
            ),
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.blue, BlendMode.colorDodge),
                child: Transform.translate(
                  offset: const Offset(-2, 0),
                  child: child,
                ),
              ),
            ),
          ],
        );
    // Add more effects as needed
      default:
        return child;
    }
  }

  List<Widget> _buildVisualOverlays(
      Size screenSize,
      List<TimelineItem> visualItems,
      ) {
    final List<Widget> list = [];
    for (final item in visualItems) {
      if (playheadPosition >= item.startTime && playheadPosition < item.startTime + item.duration) {
        double currX = item.x ?? (item.type == TimelineItemType.text ? 100 : 50);
        double currY = item.y ?? (item.type == TimelineItemType.text ? 200 : 100);
        double currScale = item.scale;
        double currRotation = item.rotation;
        if (item.endX != null) {
          double fraction = ((playheadPosition - item.startTime)
              .inMilliseconds /
              item.duration.inMilliseconds)
              .clamp(0.0, 1.0);
          currX = (item.x ?? currX) + fraction * (item.endX! - (item.x ?? currX));
        }
        if (item.endY != null) {
          double fraction = ((playheadPosition - item.startTime)
              .inMilliseconds /
              item.duration.inMilliseconds)
              .clamp(0.0, 1.0);
          currY = (item.y ?? currY) + fraction * (item.endY! - (item.y ?? currY));
        }
        if (item.endScale != null) {
          double fraction = ((playheadPosition - item.startTime)
              .inMilliseconds /
              item.duration.inMilliseconds)
              .clamp(0.0, 1.0);
          currScale = item.scale + fraction * (item.endScale! - item.scale);
        }
        if (item.endRotation != null) {
          double fraction = ((playheadPosition - item.startTime)
              .inMilliseconds /
              item.duration.inMilliseconds)
              .clamp(0.0, 1.0);
          currRotation = item.rotation + fraction * (item.endRotation! - item.rotation);
        }
        Widget child;
        if (item.type == TimelineItemType.text) {
          child = Transform.rotate(
            angle: currRotation * math.pi / 180,
            child: Transform.scale(
              scale: currScale,
              child: Text(
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
              ),
            ),
          );
        } else { // image
          child = Transform.rotate(
            angle: currRotation * math.pi / 180,
            child: Transform.scale(
              scale: currScale,
              child: item.file != null
                  ? Image.file(
                item.file!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(); // Prevent errors from breaking UI
                },
              )
                  : const SizedBox(),
            ),
          );
        }
        if (selectedClip == int.tryParse(item.id)) {
          child = RawGestureDetector(
            gestures: <Type, GestureRecognizerFactory>{
              ScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                  ScaleGestureRecognizer>(
                    () => ScaleGestureRecognizer(),
                    (instance) {
                  instance
                    ..onStart = (details) {
                      _initialRotation = item.rotation;
                      _initialScale = item.scale;
                    }
                    ..onUpdate = (details) {
                      setState(() {
                        item.rotation = _initialRotation + details.rotation * 180 / math.pi;
                        item.scale = (_initialScale * details.scale).clamp(
                          0.3,
                          3.0,
                        );
                        item.x = (item.x ?? 0) + details.focalPointDelta.dx;
                        item.y = (item.y ?? 0) + details.focalPointDelta.dy;
                        item.x = item.x!.clamp(
                          0.0,
                          screenSize.width - 200 * item.scale,
                        );
                        item.y = item.y!.clamp(
                          0.0,
                          screenSize.height - 200 * item.scale,
                        );
                      });
                    };
                },
              ),
              PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                    () => PanGestureRecognizer(),
                    (instance) {
                  instance.onUpdate = (details) {
                    setState(() {
                      item.x = (item.x ?? 0) + details.delta.dx;
                      item.y = (item.y ?? 0) + details.delta.dy;
                      item.x = item.x!.clamp(
                        0.0,
                        screenSize.width - 200 * item.scale,
                      );
                      item.y = item.y!.clamp(
                        0.0,
                        screenSize.height - 200 * item.scale,
                      );
                    });
                  };
                },
              ),
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00D9FF), width: 2),
              ),
              child: child,
            ),
          );
        }
        list.add(Positioned(left: currX, top: currY, child: child));
      }
    }
    return list;
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

  Widget _buildPlaybackControls() {
    final selectedItem = getSelectedItem();
    String timeText = '${_formatTime(playheadPosition)} / ${_formatTime(Duration(seconds: _getTotalDuration().toInt()))}';
    if (selectedItem != null) {
      timeText = '${_formatTime(selectedItem.startTime)} / ${_formatTime(selectedItem.startTime + selectedItem.duration)}';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF000000),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: togglePlayPause,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            timeText,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ON',
                  style: TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _undo,
                child: const Icon(Icons.undo, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _redo,
                child: const Icon(Icons.redo, size: 22, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      height: 300,
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
          final centerSec = timelineOffset / oldPps + MediaQuery.of(context).size.width / 2 / oldPps;
          timelineOffset = (centerSec - MediaQuery.of(context).size.width / 2 / newPps) * newPps;
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
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    _buildDurationRuler(),
                    const SizedBox(height: 8),
                    _buildVideoTrack(),
                    const SizedBox(height: 8),
                    _buildAudioTrack(),
                    const SizedBox(height: 8),
                    _buildOverlayTrack(),
                    const SizedBox(height: 8),
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
    final durationText = selectedItem != null ? _formatTime(selectedItem.duration) : '';
    return Positioned(
      left: screenWidth / 2 - 1,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 2),
            if (durationText.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  durationText,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                width: 2,
                decoration: const BoxDecoration(
                  color: Colors.white,
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
    double step = pixelsPerSecond > 150 ? 0.1 : pixelsPerSecond > 80 ? 0.5 : 1.0;
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
              Container(
                width: 1,
                height: isMajor ? 6 : 3,
                color: Colors.white,
              ),
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

  Widget _clippedTrack({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) => ClipRect(child: child),
    );
  }

  Widget _buildVideoTrack() {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;
    return Container(
      height: 70,
      child: _clippedTrack(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  width: math.max(
                    screenWidth,
                    _getTotalDuration() * pixelsPerSecond + screenWidth,
                  ),
                  child: Stack(
                    children: [
                      if (clips.isNotEmpty)
                        Positioned(
                          left: centerX - timelineOffset - 120,
                          top: 5,
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
                      ...clips.map((clip) => _buildVideoClip(clip, centerX)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  _saveToHistory();
                  _addVideo();
                },
                child: const Icon(Icons.add, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoClip(TimelineItem item, double centerX) {
    final selected = selectedClip == int.tryParse(item.id);
    final startX = item.startTime.inMilliseconds / 1000 * pixelsPerSecond - timelineOffset;
    final width = _clipWidth(item);
    final minDuration = const Duration(seconds: 1);
    return Positioned(
      left: startX + centerX,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => selectedClip = int.tryParse(item.id)),
            onHorizontalDragUpdate: (d) {
              final deltaSec = d.delta.dx / pixelsPerSecond;
              final newStart = item.startTime + Duration(milliseconds: (deltaSec * 1000).round());
              if (newStart >= Duration.zero) {
                setState(() {
                  item.startTime = newStart;
                  clips.sort((a, b) => a.startTime.compareTo(b.startTime));
                });
              }
            },
            child: Container(
              width: width,
              height: 60,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: item.thumbnailPaths.isNotEmpty
                    ? Row(
                  children: item.thumbnailPaths
                      .map(
                        (p) => Expanded(
                      child: Image.file(
                        File(p),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(); // Prevent errors
                        },
                      ),
                    ),
                  )
                      .toList(),
                )
                    : Container(
                  color: const Color(0xFF2A2A2A),
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
          if (selected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  final deltaSec = d.delta.dx / pixelsPerSecond;
                  final newStart = item.startTime + Duration(milliseconds: (deltaSec * 1000).round());
                  final newTrimStart = item.trimStart - Duration(milliseconds: (deltaSec * 1000).round());
                  final newDuration = item.duration - Duration(milliseconds: (deltaSec * 1000).round());
                  if (newStart >= Duration.zero &&
                      newDuration >= minDuration &&
                      newTrimStart >= Duration.zero &&
                      newTrimStart <= item.originalDuration - newDuration) {
                    setState(() {
                      item.startTime = newStart;
                      item.trimStart = newTrimStart;
                      item.duration = newDuration;
                      clips.sort((a, b) => a.startTime.compareTo(b.startTime));
                    });
                    _updateThumbnails(item);
                  }
                },
                child: Container(width: 20, color: Colors.transparent),
              ),
            ),
          if (selected)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  final deltaSec = d.delta.dx / pixelsPerSecond;
                  final newTrimEnd = item.trimEnd + Duration(milliseconds: (deltaSec * 1000).round());
                  Duration newDuration = item.duration + Duration(milliseconds: (deltaSec * 1000).round());
                  if (newTrimEnd <= item.originalDuration && newDuration >= minDuration) {
                    setState(() {
                      item.trimEnd = newTrimEnd;
                      item.duration = newDuration;
                      clips.sort((a, b) => a.startTime.compareTo(b.startTime));
                    });
                    _updateThumbnails(item);
                  }
                },
                child: Container(width: 20, color: Colors.transparent),
              ),
            ),
        ],
      ),
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
    TimelineItem? selectedItem;
    if (selectedClip != null) {
      for (final clip in clips) {
        if (int.tryParse(clip.id) == selectedClip) {
          selectedItem = clip;
          break;
        }
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
            if (selectedItem != null && selectedItem.thumbnailPaths.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Image.file(
                  File(selectedItem.thumbnailPaths.first),
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
                child: const Icon(Icons.edit, size: 18, color: Colors.white),
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
      child: _clippedTrack(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  width: math.max(
                    screenWidth,
                    _getTotalDuration() * pixelsPerSecond + screenWidth,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: centerX - timelineOffset - 70,
                        top: 5,
                        child: GestureDetector(
                          onTap: () {
                            _saveToHistory();
                            _addAudio();
                          },
                          child: Container(
                            width: 50,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.music_note,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Add audio',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ...audioItems.map(
                            (audio) => _buildAudioClip(audio, centerX),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioClip(TimelineItem item, double centerX) {
    final selected = selectedClip == int.tryParse(item.id);
    final startX = item.startTime.inMilliseconds / 1000 * pixelsPerSecond - timelineOffset;
    final width = _clipWidth(item);
    final minDuration = const Duration(seconds: 1);
    return Positioned(
      left: startX + centerX,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => selectedClip = int.tryParse(item.id)),
            onHorizontalDragUpdate: (d) {
              final deltaSec = d.delta.dx / pixelsPerSecond;
              final newStart = item.startTime + Duration(milliseconds: (deltaSec * 1000).round());
              if (newStart >= Duration.zero) {
                setState(() {
                  item.startTime = newStart;
                  audioItems.sort((a, b) => a.startTime.compareTo(b.startTime));
                });
              }
            },
            child: Container(
              width: width,
              height: 40,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: item.waveformData != null && item.waveformData!.isNotEmpty
                    ? CustomPaint(
                  painter: WaveformPainter(item.waveformData!),
                )
                    : const Center(
                  child: Icon(
                    Icons.audiotrack,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          if (selected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  final deltaSec = d.delta.dx / pixelsPerSecond;
                  final newStart = item.startTime + Duration(milliseconds: (deltaSec * 1000).round());
                  final newTrimStart = item.trimStart - Duration(milliseconds: (deltaSec * 1000).round());
                  final newDuration = item.duration - Duration(milliseconds: (deltaSec * 1000).round());
                  if (newStart >= Duration.zero &&
                      newDuration >= minDuration &&
                      newTrimStart >= Duration.zero &&
                      newTrimStart <= item.originalDuration - newDuration) {
                    setState(() {
                      item.startTime = newStart;
                      item.trimStart = newTrimStart;
                      item.duration = newDuration;
                      audioItems.sort(
                            (a, b) => a.startTime.compareTo(b.startTime),
                      );
                    });
                  }
                },
                child: Container(width: 20, color: Colors.transparent),
              ),
            ),
          if (selected)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  final deltaSec = d.delta.dx / pixelsPerSecond;
                  final newTrimEnd = item.trimEnd + Duration(milliseconds: (deltaSec * 1000).round());
                  Duration newDuration = item.duration + Duration(milliseconds: (deltaSec * 1000).round());
                  if (newTrimEnd <= item.originalDuration && newDuration >= minDuration) {
                    setState(() {
                      item.trimEnd = newTrimEnd;
                      item.duration = newDuration;
                      audioItems.sort(
                            (a, b) => a.startTime.compareTo(b.startTime),
                      );
                    });
                  }
                },
                child: Container(width: 20, color: Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlayTrack() {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;
    return Container(
      height: 50,
      child: _clippedTrack(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  width: math.max(
                    screenWidth,
                    _getTotalDuration() * pixelsPerSecond + screenWidth,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: centerX - timelineOffset - 70,
                        top: 5,
                        child: GestureDetector(
                          onTap: () {
                            _saveToHistory();
                            _addImage();
                          },
                          child: Container(
                            width: 50,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.layers,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Add overlay',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ...overlayItems.map(
                            (overlay) => _buildOverlayClip(overlay, centerX),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayClip(TimelineItem item, double centerX) {
    final selected = selectedClip == int.tryParse(item.id);
    final startX = item.startTime.inMilliseconds / 1000 * pixelsPerSecond - timelineOffset;
    final width = item.duration.inMilliseconds / 1000 * pixelsPerSecond.clamp(60.0, double.infinity);
    final minDuration = const Duration(seconds: 1);
    return Positioned(
      left: startX + centerX,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => selectedClip = int.tryParse(item.id)),
            onHorizontalDragUpdate: (d) {
              final deltaSec = d.delta.dx / pixelsPerSecond;
              final newStart = item.startTime + Duration(milliseconds: (deltaSec * 1000).round());
              if (newStart >= Duration.zero) {
                setState(() {
                  item.startTime = newStart;
                  overlayItems.sort(
                        (a, b) => a.startTime.compareTo(b.startTime),
                  );
                });
              }
            },
            child: Container(
              width: width,
              height: 40,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFFF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: item.file != null
                    ? Image.file(item.file!, fit: BoxFit.cover)
                    : const Text(
                  'Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          if (selected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  final deltaSec = d.delta.dx / pixelsPerSecond;
                  final newStart = item.startTime + Duration(milliseconds: (deltaSec * 1000).round());
                  final newDuration = item.duration - Duration(milliseconds: (deltaSec * 1000).round());
                  if (newStart >= Duration.zero && newDuration >= minDuration) {
                    setState(() {
                      item.startTime = newStart;
                      item.duration = newDuration;
                      overlayItems.sort(
                            (a, b) => a.startTime.compareTo(b.startTime),
                      );
                    });
                  }
                },
                child: Container(width: 20, color: Colors.transparent),
              ),
            ),
          if (selected)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  final deltaSec = d.delta.dx / pixelsPerSecond;
                  Duration newDuration = item.duration + Duration(milliseconds: (deltaSec * 1000).round());
                  if (newDuration >= minDuration) {
                    Duration snapDur = Duration.zero;
                    for (var c in clips) {
                      if (item.startTime >= c.startTime && item.startTime < c.startTime + c.duration) {
                        snapDur = c.startTime + c.duration - item.startTime;
                      }
                    }
                    if (snapDur > Duration.zero) {
                      final delta = (newDuration - snapDur).inMilliseconds.abs();
                      if (delta < 500) {
                        newDuration = snapDur;
                      }
                    }
                    setState(() {
                      item.duration = newDuration;
                      overlayItems.sort(
                            (a, b) => a.startTime.compareTo(b.startTime),
                      );
                    });
                  }
                },
                child: Container(width: 20, color: Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextTrack() {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;
    return Container(
      height: 50,
      child: _clippedTrack(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  width: math.max(
                    screenWidth,
                    _getTotalDuration() * pixelsPerSecond + screenWidth,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: centerX - timelineOffset - 70,
                        top: 5,
                        child: GestureDetector(
                          onTap: () {
                            _saveToHistory();
                            _addText();
                          },
                          child: Container(
                            width: 50,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.text_fields,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Add text',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ...textItems.map((text) => _buildTextClip(text, centerX)),
                    ],
                  ),
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
    final startX = item.startTime.inMilliseconds / 1000 * pixelsPerSecond - timelineOffset;
    final width = item.duration.inMilliseconds / 1000 * pixelsPerSecond.clamp(60.0, double.infinity);
    final minDuration = const Duration(seconds: 1);
    return Positioned(
      left: startX + centerX,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => selectedClip = int.tryParse(item.id)),
            onHorizontalDragUpdate: (d) {
              final deltaSec = d.delta.dx / pixelsPerSecond;
              final newStart = item.startTime + Duration(milliseconds: (deltaSec * 1000).round());
              if (newStart >= Duration.zero) {
                setState(() {
                  item.startTime = newStart;
                  textItems.sort((a, b) => a.startTime.compareTo(b.startTime));
                });
              }
            },
            child: Container(
              width: width,
              height: 40,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          if (selected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  final deltaSec = d.delta.dx / pixelsPerSecond;
                  final newStart = item.startTime + Duration(milliseconds: (deltaSec * 1000).round());
                  final newDuration = item.duration - Duration(milliseconds: (deltaSec * 1000).round());
                  if (newStart >= Duration.zero && newDuration >= minDuration) {
                    setState(() {
                      item.startTime = newStart;
                      item.duration = newDuration;
                      textItems.sort(
                            (a, b) => a.startTime.compareTo(b.startTime),
                      );
                    });
                  }
                },
                child: Container(width: 20, color: Colors.transparent),
              ),
            ),
          if (selected)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  final deltaSec = d.delta.dx / pixelsPerSecond;
                  Duration newDuration = item.duration + Duration(milliseconds: (deltaSec * 1000).round());
                  if (newDuration >= minDuration) {
                    setState(() {
                      item.duration = newDuration;
                      textItems.sort(
                            (a, b) => a.startTime.compareTo(b.startTime),
                      );
                    });
                  }
                },
                child: Container(width: 20, color: Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }

  double _clipWidth(TimelineItem item) {
    final secs = item.duration.inMilliseconds / 1000.0 / item.speed;
    return (secs * pixelsPerSecond).clamp(60.0, double.infinity);
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
        border: Border(top: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: SingleChildScrollView(
        controller: _bottomNavController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _navBtn(Icons.content_cut, 'Edit', () => _showEditOptions()),
            const SizedBox(width: 24),
            _navBtn(Icons.audiotrack, 'Audio', _addAudio),
            const SizedBox(width: 24),
            _navBtn(Icons.text_fields, 'Text', () {
              _saveToHistory();
              _addText();
            }),
            const SizedBox(width: 24),
            _navBtn(Icons.auto_awesome, 'Effects', () => _showEffects()),
            const SizedBox(width: 24),
            _navBtn(Icons.filter, 'Filters', () => _showFilters()),
            const SizedBox(width: 24),
            _navBtn(Icons.animation, 'Animation', () => _showAnimations()),
            const SizedBox(width: 24),
            _navBtn(Icons.timeline, 'Keyframe', () => _showKeyframeEditor()),
            const SizedBox(width: 24),
            _navBtn(Icons.swap_horiz, 'Transition', () => _showTransitions()),
            const SizedBox(width: 24),
            _navBtn(Icons.emoji_emotions, 'Stickers', () => _showStickers()),
            const SizedBox(width: 24),
            _navBtn(Icons.layers, 'Layers', () => _showLayerManager()),
            const SizedBox(width: 24),
            _navBtn(Icons.layers, 'Overlay', _addImage),
            const SizedBox(width: 24),
            _navBtn(Icons.photo_library, 'Photo Edit', () => _showPhotoEdit()),
            const SizedBox(width: 24),
            _navBtn(Icons.subtitles, 'Captions', () => _showCaptions()),
            const SizedBox(width: 24),
            _navBtn(Icons.volume_up, 'Volume', _showVolumeEditor),
            const SizedBox(width: 24),
            _navBtn(Icons.speed, 'Speed', _showSpeedEditor),
            const SizedBox(width: 24),
            _navBtn(Icons.wallpaper, 'Green Screen', () => _showGreenScreen()),
            const SizedBox(width: 24),
            _navBtn(
              Icons.person_remove,
              'Remove BG',
                  () => _showBackgroundRemoval(),
            ),
          ],
        ),
      ),
    );
  }

  void _showLayerManager() {
    List<TimelineItem> visualItems = [...textItems, ...overlayItems]
      ..sort((a, b) {
        final int aIndex = a.layerIndex ?? 999999;
        final int bIndex = b.layerIndex ?? 999999;
        return aIndex.compareTo(bIndex);
      });
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setM) => Container(
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Layer Manager',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Drag to reorder layers • Lower = behind',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setM(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = visualItems.removeAt(oldIndex);
                      visualItems.insert(newIndex, item);
                      // Reassign layerIndex: 0, 10, 20, ... (lower = drawn first = behind)
                      for (int i = 0; i < visualItems.length; i++) {
                        visualItems[i].layerIndex = i * 10;
                      }
                    });
                    // Sync back to original lists
                    setState(() {
                      textItems = visualItems
                          .where(
                            (e) => e.type == TimelineItemType.text,
                      )
                          .toList();
                      overlayItems = visualItems
                          .where(
                            (e) => e.type != TimelineItemType.text,
                      )
                          .toList();
                    });
                  },
                  children: visualItems.map((item) {
                    return ListTile(
                      key: ValueKey(item.id),
                      leading: Icon(
                        item.type == TimelineItemType.text ? Icons.text_fields : Icons.image,
                        color: Colors.white,
                      ),
                      title: Text(
                        item.type == TimelineItemType.text
                            ? (item.text?.isNotEmpty == true ? item.text! : 'Text')
                            : 'Image',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: item.layerIndex != null
                          ? Text(
                        'Layer ${item.layerIndex! ~/ 10}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      )
                          : null,
                      trailing: const Icon(
                        Icons.drag_handle,
                        color: Colors.white,
                      ),
                      tileColor: const Color(0xFF2A2A2A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, String label, VoidCallback? onTap) {
    return InkWell(
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
    );
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _editOption(Icons.content_cut, 'Split', splitClipAtPlayhead),
            _editOption(Icons.volume_up, 'Volume', _showVolumeEditor),
            _editOption(Icons.speed, 'Speed', _showSpeedEditor),
            _editOption(Icons.crop, 'Crop', _showCropEditor),
            _editOption(Icons.delete, 'Delete', _deleteSelected),
          ],
        ),
      ),
    );
  }

  Widget _editOption(IconData icon, String label, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        if (onTap != null) onTap();
      },
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
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Container(
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

  void _showKeyframeEditor() {
    TimelineItem? item = getSelectedItem();
    if (item == null || (item.type != TimelineItemType.text && item.type != TimelineItemType.image)) {
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
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Container(
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
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Container(
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

  void _showSpeedEditor() {
    if (selectedClip == null) return;
    TimelineItem? item = getSelectedItem();
    if (item == null) return;
    double temp = item.speed;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Speed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${temp.toStringAsFixed(2)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
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
                      backgroundColor: temp == s ? const Color(0xFF00D9FF) : const Color(0xFF2A2A2A),
                      foregroundColor: temp == s ? Colors.black : Colors.white,
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
                    item.speed = temp;
                    item.duration = Duration(
                      milliseconds: (oldDur.inMilliseconds / temp).round(),
                    );
                  });
                  Navigator.pop(ctx);
                  _showMessage('Speed: ${temp.toStringAsFixed(2)}x');
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
                            color: sel ? const Color(0xFF00D9FF) : Colors.transparent,
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

  void _deleteSelected() {
    if (selectedClip == null) return;
    final id = selectedClip.toString();
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

  // Updated: Expanded effects library inspired by CapCut
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
      builder: (context) => Container(
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                            color: isSelected ? const Color(0xFF00D9FF) : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00D9FF) : Colors.transparent,
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
                            color: isSelected ? const Color(0xFF00D9FF) : Colors.white70,
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
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Container(
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
                                  color: isSelected ? const Color(0xFF00D9FF) : Colors.transparent,
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
                                color: isSelected ? const Color(0xFF00D9FF) : Colors.white70,
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
      builder: (context) => Container(
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Container(
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
      builder: (context) => Container(
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

  void _showPhotoEdit() {
    if (selectedClip == null || clips.isEmpty) {
      _showMessage('Select an image or video clip first');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Photo Edit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _photoEditOption(Icons.brightness_6, 'Brightness', () {
              Navigator.pop(context);
              _showAdjustmentSlider('Brightness', 0, 2);
            }),
            _photoEditOption(Icons.contrast, 'Contrast', () {
              Navigator.pop(context);
              _showAdjustmentSlider('Contrast', 0, 2);
            }),
            _photoEditOption(Icons.palette, 'Saturation', () {
              Navigator.pop(context);
              _showAdjustmentSlider('Saturation', 0, 2);
            }),
            _photoEditOption(Icons.opacity, 'Exposure', () {
              Navigator.pop(context);
              _showAdjustmentSlider('Exposure', -2, 2);
            }),
            _photoEditOption(Icons.wb_sunny, 'Temperature', () {
              Navigator.pop(context);
              _showAdjustmentSlider('Temperature', -100, 100);
            }),
            _photoEditOption(Icons.tune, 'Sharpness', () {
              Navigator.pop(context);
              _showAdjustmentSlider('Sharpness', 0, 2);
            }),
            _photoEditOption(Icons.crop, 'Crop', () {
              Navigator.pop(context);
              _showMessage('Crop tool opened');
            }),
            _photoEditOption(Icons.rotate_90_degrees_ccw, 'Rotate', () {
              Navigator.pop(context);
              _showMessage('Rotating...');
            }),
          ],
        ),
      ),
    );
  }

  Widget _photoEditOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00D9FF)),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: onTap,
    );
  }

  void _showAdjustmentSlider(String name, double min, double max) {
    double value = (min + max) / 2;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                value.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
              Slider(
                value: value,
                min: min,
                max: max,
                divisions: 40,
                activeColor: const Color(0xFF00D9FF),
                onChanged: (v) => setM(() => value = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showMessage(
                    '$name: ${value.toStringAsFixed(2)} applied',
                  );
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

  void _showCaptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Captions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _captionOption(
              Icons.auto_awesome,
              'Auto Captions',
              'AI-generated subtitles',
                  () {
                Navigator.pop(context);
                _showMessage('Generating auto captions...');
              },
            ),
            _captionOption(
              Icons.text_fields,
              'Manual Captions',
              'Add captions manually',
                  () {
                Navigator.pop(context);
                _addText();
              },
            ),
            _captionOption(
              Icons.translate,
              'Translate',
              'Translate captions',
                  () {
                Navigator.pop(context);
                _showMessage('Translation feature');
              },
            ),
            _captionOption(
              Icons.style,
              'Caption Styles',
              'Customize appearance',
                  () {
                Navigator.pop(context);
                _showMessage('Caption styles');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _captionOption(
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
        child: Icon(icon, color: const Color(0xFF00D9FF), size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      onTap: onTap,
    );
  }

  void _showGreenScreen() {
    if (selectedClip == null) {
      _showMessage('Select a clip first');
      return;
    }
    double sensitivity = 0.5;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Green Screen (Chroma Key)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Remove colored backgrounds from your video',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Color to Remove',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _colorOption(Colors.green, 'Green', setM),
                  _colorOption(Colors.blue, 'Blue', setM),
                  _colorOption(Colors.red, 'Red', setM),
                  _colorOption(Colors.white, 'White', setM),
                  _colorOption(Colors.black, 'Black', setM),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Sensitivity',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: sensitivity,
                      min: 0,
                      max: 1,
                      divisions: 10,
                      activeColor: const Color(0xFF00D9FF),
                      onChanged: (v) => setM(() => sensitivity = v),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${(sensitivity * 100).toInt()}%',
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
                        Navigator.pop(ctx);
                        _showMessage(
                          'Green screen applied with ${(sensitivity * 100).toInt()}% sensitivity',
                        );
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

  Widget _colorOption(Color color, String label, StateSetter setM) {
    return GestureDetector(
      onTap: () => _showMessage('$label selected'),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showBackgroundRemoval() {
    if (selectedClip == null) {
      _showMessage('Select a clip first');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Background Removal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Automatically remove backgrounds using AI',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _bgRemovalOption(
              Icons.person,
              'Remove Person BG',
              'AI removes background from people',
                  () {
                Navigator.pop(context);
                _showLoading();
                Future.delayed(const Duration(seconds: 2), () {
                  _hideLoading();
                  _showMessage('Background removed successfully');
                });
              },
            ),
            _bgRemovalOption(
              Icons.landscape,
              'Remove Object BG',
              'AI removes background from objects',
                  () {
                Navigator.pop(context);
                _showLoading();
                Future.delayed(const Duration(seconds: 2), () {
                  _hideLoading();
                  _showMessage('Background removed successfully');
                });
              },
            ),
            _bgRemovalOption(
              Icons.auto_fix_high,
              'Smart Cutout',
              'Automatically detect and cut subject',
                  () {
                Navigator.pop(context);
                _showMessage('Smart cutout processing...');
              },
            ),
            _bgRemovalOption(
              Icons.color_lens,
              'Replace Background',
              'Add custom background',
                  () {
                Navigator.pop(context);
                _showBackgroundReplace();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _bgRemovalOption(
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
        child: Icon(icon, color: const Color(0xFF00D9FF), size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: onTap,
    );
  }

  void _showBackgroundReplace() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Replace Background',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final colors = [
                    Colors.white,
                    Colors.black,
                    Colors.blue,
                    Colors.red,
                    Colors.green,
                    Colors.purple,
                    Colors.orange,
                    Colors.pink,
                    Colors.teal,
                    Colors.amber,
                    Colors.indigo,
                    Colors.cyan,
                  ];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showMessage('Background replaced');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors[index],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: index == 0
                          ? const Icon(
                        Icons.add_photo_alternate,
                        color: Colors.black87,
                        size: 40,
                      )
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final XFile? file = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (file != null) {
                  _showMessage('Custom background added');
                }
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}