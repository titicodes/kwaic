
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:kwaic/nes_scr/servuices/time_line_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../model/timeline_item.dart';
import 'video_manager.dart';
import 'audio_manager.dart';

/// ClipController - Manages clips and updates TimelineController.totalDuration
/// Professional architecture: Updates master timeline duration when clips change
class ClipController extends ChangeNotifier {
  late VideoManager videoManager;
  final AudioManager audioManager;
  final TimelineController timelineController;

  List<TimelineItem> _videoClips = [];
  List<TimelineItem> _audioClips = [];
  List<TimelineItem> _textClips = [];
  List<TimelineItem> _overlayClips = [];
  List<TimelineItem> _stickerClips = [];
  TimelineItem? backgroundMusic;  // Only one background music
  TimelineItem? backgroundVisual;

  String? _selectedClipId;
  TimelineItemType? _selectedClipType;

  List<TimelineItem> get videoClips => List.unmodifiable(_videoClips);
  List<TimelineItem> get audioClips => List.unmodifiable(_audioClips);
  List<TimelineItem> get textClips => List.unmodifiable(_textClips);
  List<TimelineItem> get overlayClips => List.unmodifiable(_overlayClips);
  List<TimelineItem> get stickerClips => List.unmodifiable(_stickerClips);


  String? get selectedClipId => _selectedClipId;
  TimelineItemType? get selectedClipType => _selectedClipType;

  String? currentFilter = 'none';
  String? currentEffect;

  void applyEffect(String? effect) {
    currentEffect = effect;
    notifyListeners();
  }

  void applyFilter(String filter) {
    currentFilter = filter;
    notifyListeners();
  }

  ClipController({
    VideoManager? videoManager,
    required this.audioManager,
    required this.timelineController,
  });

  void setVideoManager(VideoManager manager) {
    videoManager = manager;
  }


  TimelineItem? getClipById(String id) {
    for (var clip in videoClips) if (clip.id == id) return clip;
    for (var clip in audioClips) if (clip.id == id) return clip;
    for (var clip in textClips) if (clip.id == id) return clip;
    for (var clip in overlayClips) if (clip.id == id) return clip;
    return null;
  }

  // === Background Music ===
  void setBackgroundMusic(TimelineItem music) {
    // Clean up old background music file (optional, saves storage)
    backgroundMusic?.file?.deleteSync(recursive: false);

    backgroundMusic = music.copyWith(
      type: TimelineItemType.backgroundMusic,
      startTime: Duration.zero, // Always starts at beginning
    );

    // Initialize player and generate waveform
    audioManager.initializePlayer(backgroundMusic!);
    _generateWaveformForBGM();

    notifyListeners();
  }

  void removeBackgroundMusic() {
    if (backgroundMusic != null) {
      audioManager.removePlayer(backgroundMusic!.id);
      backgroundMusic!.file?.deleteSync(recursive: false);
      backgroundMusic = null;
      notifyListeners();
    }
  }

  void setBackgroundVisual(TimelineItem background) {
    backgroundVisual?.file?.deleteSync(recursive: false);
    backgroundVisual = background.copyWith(
      type: TimelineItemType.backgroundVisual,
      startTime: Duration.zero,
      duration: timelineController.totalDuration,
    );
    notifyListeners();
  }

  void removeBackgroundVisual() {
    backgroundVisual = null;
    notifyListeners();
  }

  Future<void> _generateWaveformForBGM() async {
    if (backgroundMusic == null) return;

    final tempDir = await getTemporaryDirectory();
    final waveFile = File('${tempDir.path}/wave_bgm_${backgroundMusic!.id}.wave');

    try {
      final stream = JustWaveform.extract(
        audioInFile: backgroundMusic!.file!,
        waveOutFile: waveFile,
      );
      await for (final progress in stream) {
        if (progress.waveform != null) {
          backgroundMusic!.waveformData = progress.waveform!;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Waveform generation failed for BGM: $e');
    }
  }

  Future<List<Uint8List>> generateTimelineThumbnails({
    required String videoPath,
    required Duration duration,
    required double pixelsPerSecond,
  })
  async {

    const double thumbWidth = 90.0;

    final double clipWidth =
        (duration.inMilliseconds / 1000.0) * pixelsPerSecond;

    final int thumbCount =
    math.max(1, (clipWidth / thumbWidth).ceil());

    final double intervalMs =
        duration.inMilliseconds / thumbCount;

    final List<Uint8List> thumbs = [];

    for (int i = 0; i < thumbCount; i++) {
      final int timeMs = (i * intervalMs).round();

      Uint8List? data = await VideoThumbnail.thumbnailData(
        video: videoPath,
        timeMs: timeMs,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 160,
        quality: 75,
      );

      if (data != null) {
        thumbs.add(data);
      } else if (thumbs.isNotEmpty) {
        thumbs.add(thumbs.last); // gap fill
      }
    }

    return thumbs;
  }

// Helper for FFmpeg thumbnail
  Future<Uint8List?> _generateThumbnailFFmpeg(String videoPath, double timeSec) async {
    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final command = '-ss $timeSec -i "$videoPath" -frames:v 1 -q:v 3 -y "$outputPath"';
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();

    if (ReturnCode.isSuccess(rc) && await File(outputPath).exists()) {
      final bytes = await File(outputPath).readAsBytes();
      await File(outputPath).delete();
      return bytes;
    }
    return null;
  }


  void splitClip(TimelineItem clip, Duration globalPosition) {
    if (clip.type != TimelineItemType.video) return;

    final localSplit = globalPosition - clip.startTime;
    if (localSplit <= Duration.zero || localSplit >= clip.duration) return;

    final leftClip = clip.copyWith(
      id: const Uuid().v4(),
      duration: localSplit,
    );

    final rightClip = clip.copyWith(
      id: const Uuid().v4(),
      startTime: globalPosition,
      trimStart: clip.trimStart + localSplit,
      duration: clip.duration - localSplit,
    );

    final index = _videoClips.indexOf(clip);
    if (index != -1) {
      _videoClips
        ..removeAt(index)
        ..insert(index, leftClip)
        ..insert(index + 1, rightClip);

      videoManager.shareController(clip.id, leftClip.id);
      videoManager.shareController(clip.id, rightClip.id);
    }

    _updateTotalDuration();
    selectClip(rightClip.id, rightClip.type);
    _syncPreview(); // Force preview update after split
    notifyListeners();
  }


  /// 🎯 CRITICAL: Update timeline total duration when clips change
  void _updateTotalDuration() {
    double maxEnd = 0.0;

    final allClips = [
      ..._videoClips,
      ..._audioClips,
      ..._textClips,
      ..._overlayClips,
      ..._stickerClips,
    ];

    if (allClips.isEmpty) {
      timelineController.totalDuration = const Duration(seconds: 30);
      return;
    }

    // Find the longest clip end considering speed
    for (final clip in allClips) {
      final effectiveMs = clip.duration.inMilliseconds / clip.speed;
      final clipEndMs = clip.startTime.inMilliseconds + effectiveMs;
      if (clipEndMs > maxEnd) maxEnd = clipEndMs;
    }

    final newTotal = Duration(milliseconds: maxEnd.ceil());

    // 🎯 Update timeline controller (master)
    timelineController.totalDuration = newTotal;
  }

  Future<void> addVideoClip(TimelineItem clip) async {
    // ⛔ STOP playback immediately
    videoManager.pause();

    _videoClips.add(clip);
    _sortClips(_videoClips);

    await videoManager.initializeController(clip);

    // 🎯 Move playhead to clip start
    timelineController.currentTime = clip.startTime;

    // 🎯 Force preview sync (NO PLAY)
    await videoManager.syncToPlayhead(timelineController.currentTime);

    _updateTotalDuration();
    notifyListeners();
  }

  void _syncPreview() {
    videoManager.pause();
    videoManager.syncToPlayhead(timelineController.currentTime);
  }

  Future<void> addAudioClip(TimelineItem clip) async {
    _audioClips.add(clip);
    _sortClips(_audioClips);
    await audioManager.initializePlayer(clip);

    // Generate waveform
    final tempDir = await getTemporaryDirectory();
    final waveFile = File('${tempDir.path}/wave_${clip.id}.wave');
    try {
      final stream = JustWaveform.extract(
        audioInFile: clip.file!,
        waveOutFile: waveFile,
      );
      await for (final progress in stream) {
        if (progress.waveform != null) {
          clip.waveformData = progress.waveform!;
          notifyListeners(); // Update UI as waveform loads
        }
      }
    } catch (e) {
      debugPrint('Waveform failed: $e');
    }

    _updateTotalDuration();
    notifyListeners(); // ← This makes the audio clip appear immediately
  }

  void addTextClip(TimelineItem clip) {
    _textClips.add(clip);
    _sortClips(_textClips);
    _updateTotalDuration();
    notifyListeners();
  }

  void addOverlayClip(TimelineItem clip) {
    _overlayClips.add(clip);
    _sortClips(_overlayClips);
    _updateTotalDuration();
    notifyListeners();
  }

  void updateClip(TimelineItem updatedClip) {
    _updateInList(_videoClips, updatedClip);
    _updateInList(_audioClips, updatedClip);
    _updateInList(_textClips, updatedClip);
    _updateInList(_overlayClips, updatedClip);
    _updateTotalDuration();
    notifyListeners();
  }

  void deleteClip(String clipId, TimelineItemType type) {
    switch (type) {
      case TimelineItemType.video:
        _videoClips.removeWhere((c) => c.id == clipId);
        videoManager.removeController(clipId);
        break;
      case TimelineItemType.audio:
        _audioClips.removeWhere((c) => c.id == clipId);
        audioManager.removePlayer(clipId);
        break;
      case TimelineItemType.text:
        _textClips.removeWhere((c) => c.id == clipId);
        break;
      case TimelineItemType.overlay:
      case TimelineItemType.stickers:
      case TimelineItemType.image:
        _overlayClips.removeWhere((c) => c.id == clipId);
        break;
      case TimelineItemType.backgroundMusic:
        removeBackgroundMusic();
        return; // Early return — no need to deselect or update duration
      case TimelineItemType.backgroundVisual:
        removeBackgroundVisual();
        return; // Early return
    }

    // Only deselect if it wasn't background music/visual
    if (_selectedClipId == clipId) {
      _selectedClipId = null;
      _selectedClipType = null;
    }

    _updateTotalDuration();
    _syncPreview();
    notifyListeners();
  }

  void duplicateClip(TimelineItem clip) {
    // Background music and background visual should NOT be duplicated
    if (clip.type == TimelineItemType.backgroundMusic ||
        clip.type == TimelineItemType.backgroundVisual) {
      // Optionally show a message
      // _showMessage('Background cannot be duplicated');
      return;
    }

    final newClip = clip.copyWith(
      id: const Uuid().v4(),
      startTime: clip.startTime + clip.duration,
    );

    switch (clip.type) {
      case TimelineItemType.video:
        _videoClips.add(newClip);
        _sortClips(_videoClips);
        videoManager.shareController(clip.id, newClip.id);
        break;
      case TimelineItemType.audio:
        _audioClips.add(newClip);
        _sortClips(_audioClips);
        audioManager.initializePlayer(newClip);
        break;
      case TimelineItemType.text:
        _textClips.add(newClip);
        _sortClips(_textClips);
        break;
      case TimelineItemType.overlay:
      case TimelineItemType.stickers:
      case TimelineItemType.image:
        _overlayClips.add(newClip);
        _sortClips(_overlayClips);
        break;
      case TimelineItemType.backgroundMusic:
      case TimelineItemType.backgroundVisual:
      // Already handled above — do nothing
        return;
    }

    _updateTotalDuration();
    _syncPreview();
    notifyListeners();
  }

  void moveClip(String clipId, TimelineItemType type, Duration newStartTime) {
    final clip = getClip(clipId);
    if (clip != null) {
      clip.startTime = newStartTime;
      _updateTotalDuration();
      _syncPreview();
      notifyListeners();
    }
  }

  void selectClip(String? clipId, TimelineItemType? type) {
    _selectedClipId = clipId;
    _selectedClipType = type;
    notifyListeners();
  }

  TimelineItem? getClip(String clipId) {
    for (final list in [_videoClips, _audioClips, _textClips, _overlayClips]) {
      try {
        return list.firstWhere((c) => c.id == clipId);
      } catch (_) {}
    }
    return null;
  }

  TimelineItem? getActiveVideoClip(Duration position) {
    for (final clip in _videoClips) {
      final effectiveDuration = Duration(
        milliseconds: (clip.duration.inMilliseconds / clip.speed).round(),
      );
      if (position >= clip.startTime &&
          position < clip.startTime + effectiveDuration) {
        return clip;
      }
    }
    return null;
  }

  void _sortClips(List<TimelineItem> clips) {
    clips.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void _updateInList(List<TimelineItem> list, TimelineItem updated) {
    final index = list.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      list[index] = updated;
      _sortClips(list);
    }
  }

  TimelineItem? getSelectedClip() {
    if (selectedClipId == null || selectedClipType == null) return null;
    return getClip(selectedClipId!);
  }

  void replaceClip(String oldClipId, TimelineItem newClip) {
    TimelineItem? oldClip;

    if (_videoClips.any((c) => c.id == oldClipId)) {
      final index = _videoClips.indexWhere((c) => c.id == oldClipId);
      oldClip = _videoClips[index];
      _videoClips[index] = newClip;
    } else if (_audioClips.any((c) => c.id == oldClipId)) {
      final index = _audioClips.indexWhere((c) => c.id == oldClipId);
      oldClip = _audioClips[index];
      _audioClips[index] = newClip;
    } else if (_overlayClips.any((c) => c.id == oldClipId)) {
      final index = _overlayClips.indexWhere((c) => c.id == oldClipId);
      oldClip = _overlayClips[index];
      _overlayClips[index] = newClip;
    } else if (_textClips.any((c) => c.id == oldClipId)) {
      final index = _textClips.indexWhere((c) => c.id == oldClipId);
      oldClip = _textClips[index];
      _textClips[index] = newClip;
    }

    if (oldClip != null) {
      if (oldClip.type == TimelineItemType.video &&
          newClip.type == TimelineItemType.video) {
        videoManager.shareController(oldClip.id, newClip.id);
      }

      if (newClip.type == TimelineItemType.video) {
        videoManager.initializeController(newClip);
      } else if (newClip.type == TimelineItemType.audio) {
        audioManager.initializePlayer(newClip);
      }

      if (_selectedClipId == oldClipId) {
        _selectedClipId = newClip.id;
        _selectedClipType = newClip.type;
      }
    }

    _updateTotalDuration();
    notifyListeners();
  }


  List<TimelineItem> getActiveVideoStack(Duration position) {
    final videos = videoClips.where((clip) {
      final effectiveDuration = Duration(
        milliseconds: (clip.duration.inMilliseconds / clip.speed).round(),
      );
      final end = clip.startTime + effectiveDuration;
      return position >= clip.startTime && position < end;
    }).toList();

    videos.sort((a, b) => a.layerIndex.compareTo(b.layerIndex));
    return videos;
  }

  void clearAll() {
    _videoClips.clear();
    _audioClips.clear();
    _textClips.clear();
    _overlayClips.clear();
    _selectedClipId = null;
    _selectedClipType = null;
    _updateTotalDuration();
    notifyListeners();
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
