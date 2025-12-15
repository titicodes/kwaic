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
import '../model/timeline_item.dart';
import '../screen/were.dart';
import 'video_manager.dart';
import 'audio_manager.dart';

/// Manages CRUD operations on timeline clips
class ClipController extends ChangeNotifier {
  final VideoManager videoManager;
  final AudioManager audioManager;

  late final TimelineController timelineController;

  List<TimelineItem> _videoClips = [];
  List<TimelineItem> _audioClips = [];
  List<TimelineItem> _textClips = [];
  List<TimelineItem> _overlayClips = [];

  List<TimelineItem> _stickerClips = [];

  String? _selectedClipId;
  TimelineItemType? _selectedClipType;

  List<TimelineItem> get videoClips => List.unmodifiable(_videoClips);
  List<TimelineItem> get audioClips => List.unmodifiable(_audioClips);
  List<TimelineItem> get textClips => List.unmodifiable(_textClips);
  List<TimelineItem> get overlayClips => List.unmodifiable(_overlayClips);
  List<TimelineItem> get stickerClips => List.unmodifiable(_stickerClips);

  String? get selectedClipId => _selectedClipId;
  TimelineItemType? get selectedClipType => _selectedClipType;

  String? currentFilter = 'none'; // 'none', 'vintage', 'cinematic', 'warm', 'cool', 'bw'

  String? currentEffect; // 'none', 'shake', 'glitch', etc.

  void applyEffect(String? effect) {
    currentEffect = effect;
    notifyListeners();
  }

  void applyFilter(String filter) {
    currentFilter = filter;
    notifyListeners();
  }

  ClipController({
    required this.videoManager,
    required this.audioManager,
    required this.timelineController,
  });

  // Get any clip by ID and type
  TimelineItem? getClipById(String id) {
    // Search all lists
    for (var clip in videoClips) if (clip.id == id) return clip;
    for (var clip in audioClips) if (clip.id == id) return clip;
    for (var clip in textClips) if (clip.id == id) return clip;
    for (var clip in overlayClips) if (clip.id == id) return clip;
    return null;
  }

  Future<List<Uint8List>> generateRobustThumbnails(
    String videoPath,
    Duration duration,
  ) async {
    final thumbnails = <Uint8List>[];
    final tempDir = await getTemporaryDirectory();
    final outputDir = Directory(
      '${tempDir.path}/thumbs_${DateTime.now().millisecondsSinceEpoch}',
    );
    await outputDir.create(recursive: true);

    final futures = <Future>[];
    const count = 12;

    for (int i = 0; i < count; i++) {
      final progress = i / (count - 1);
      final timeSec = (duration.inSeconds * progress).toStringAsFixed(3);
      final outputPath = '${outputDir.path}/thumb_$i.jpg';

      final command =
          '-ss $timeSec -i "$videoPath" -vframes 1 -q:v 3 -y "$outputPath"';

      futures.add(
        FFmpegKit.execute(command).then((session) async {
          if (ReturnCode.isSuccess(await session.getReturnCode())) {
            final file = File(outputPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              if (bytes.length > 1000) thumbnails.add(bytes);
            }
          }
        }),
      );
    }

    await Future.wait(futures);
    await outputDir.delete(recursive: true);
    return thumbnails;
  }

  void splitClip(TimelineItem clip, Duration globalPosition) {
    if (clip.type != TimelineItemType.video) return;

    final localSplit = globalPosition - clip.startTime;
    if (localSplit <= Duration.zero || localSplit >= clip.duration) return;

    // Left clip - shorten duration
    final leftClip = TimelineItem(
      id: const Uuid().v4(),
      type: clip.type,
      file: clip.file,
      startTime: clip.startTime,
      trimStart: clip.trimStart,
      duration: localSplit,
      originalDuration: clip.originalDuration,
      speed: clip.speed,
      volume: clip.volume,
      thumbnailBytes: clip.thumbnailBytes,
    );

    // Right clip - shift startTime and trimStart
    final rightClip = TimelineItem(
      id: const Uuid().v4(),
      type: clip.type,
      file: clip.file,
      startTime: globalPosition,
      trimStart: clip.trimStart + localSplit,
      duration: clip.duration - localSplit,
      originalDuration: clip.originalDuration,
      speed: clip.speed,
      volume: clip.volume,
      thumbnailBytes: clip.thumbnailBytes,
    );

    final index = _videoClips.indexWhere((c) => c.id == clip.id);
    if (index != -1) {
      _videoClips.removeAt(index);
      _videoClips.insert(index, leftClip);
      _videoClips.insert(index + 1, rightClip);

      // Share the same controller for performance
      videoManager.shareController(clip.id, leftClip.id);
      videoManager.shareController(clip.id, rightClip.id);

      // Optional: remove old controller if not shared elsewhere
      // videoManager.removeController(clip.id);
    }

    _updateTotalDuration();
    _selectedClipId = rightClip.id; // Auto-select the right part after split
    _selectedClipType = rightClip.type;

    notifyListeners();
  }

  void _updateTotalDuration() {
    double maxEnd = 0;
    final allTracks = [videoClips, audioClips, textClips, overlayClips];
    for (final track in allTracks) {
      if (track.isEmpty) continue;
      final trackEnd = track
          .map((e) => (e.startTime.inSeconds + e.duration.inSeconds).toDouble())
          .reduce(math.max);
      if (trackEnd > maxEnd) maxEnd = trackEnd;
    }
    timelineController.totalDuration = Duration(seconds: maxEnd.toInt());
  }

  /// Add a video clip
  Future<void> addVideoClip(TimelineItem clip) async {
    _videoClips.add(clip);
    _sortClips(_videoClips);

    await videoManager.initializeController(clip);
    notifyListeners();
  }

  /// Add an audio clip

  Future<void> addAudioClip(TimelineItem clip) async {
    _audioClips.add(clip);
    _sortClips(_audioClips);

    await audioManager.initializePlayer(clip);

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
          notifyListeners(); // timeline repaint
        }
      }
    } catch (e) {
      debugPrint('Waveform generation failed: $e');
    }

    _updateTotalDuration();
    notifyListeners();
  }

  /// Add a text clip
  void addTextClip(TimelineItem clip) {
    _textClips.add(clip);
    _sortClips(_textClips);
    notifyListeners();
  }

  /// Add an overlay/image clip
  void addOverlayClip(TimelineItem clip) {
    _overlayClips.add(clip);
    _sortClips(_overlayClips);
    notifyListeners();
  }

  /// Update a clip
  void updateClip(TimelineItem updatedClip) {
    _updateInList(_videoClips, updatedClip);
    _updateInList(_audioClips, updatedClip);
    _updateInList(_textClips, updatedClip);
    _updateInList(_overlayClips, updatedClip);
    notifyListeners();
  }

  /// Delete a clip
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

      case TimelineItemType.image:
        _overlayClips.removeWhere((c) => c.id == clipId);
        break;

      case TimelineItemType.text:
        _textClips.removeWhere((c) => c.id == clipId);
        break;

      case TimelineItemType.overlay:
        _overlayClips.removeWhere((c) => c.id == clipId);
        break;

      case TimelineItemType.stickers:
        _overlayClips.removeWhere((c) => c.id == clipId);
        break;
    }

    if (_selectedClipId == clipId) {
      _selectedClipId = null;
      _selectedClipType = null;
    }

    notifyListeners();
  }

  void replaceClip(String oldId, TimelineItem newClip) {
    // Find and replace in correct list
    // Then notifyListeners()
  }

  Future<void> detectBeats(TimelineItem audioClip) async {
    // Simple beat detection using audio waveform peaks
    // Placeholder: generate markers every 0.5-1s
    final beats = <Duration>[];
    for (double t = 0; t < audioClip.duration.inSeconds; t += 0.6) {
      beats.add(Duration(seconds: t.toInt()));
    }
    // Store beats in audioClip.customData or separate list
  }

  /// Duplicate a clip
  void duplicateClip(TimelineItem clip) {
    final newClip = clip.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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

      case TimelineItemType.image:
      case TimelineItemType.overlay:
      case TimelineItemType.stickers:
        _overlayClips.add(newClip);
        _sortClips(_overlayClips);
        break;
    }

    notifyListeners();
  }

  /// Move a clip to a new position
  void moveClip(String clipId, TimelineItemType type, Duration newStartTime) {
    TimelineItem? clip;

    switch (type) {
      case TimelineItemType.video:
        clip = _videoClips.firstWhere((c) => c.id == clipId);
        _sortClips(_videoClips);
        break;

      case TimelineItemType.audio:
        clip = _audioClips.firstWhere((c) => c.id == clipId);
        _sortClips(_audioClips);
        break;

      case TimelineItemType.text:
        clip = _textClips.firstWhere((c) => c.id == clipId);
        _sortClips(_textClips);
        break;

      case TimelineItemType.image:
      case TimelineItemType.overlay:
      case TimelineItemType.stickers:
        clip = _overlayClips.firstWhere((c) => c.id == clipId);
        _sortClips(_overlayClips);
        break;
    }

    clip?.startTime = newStartTime;

    notifyListeners();
  }

  /// Select a clip
  void selectClip(String? clipId, TimelineItemType? type) {
    _selectedClipId = clipId;
    _selectedClipType = type;
    notifyListeners();
  }

  /// Get clip by ID
  TimelineItem? getClip(String clipId) {
    for (final list in [_videoClips, _audioClips, _textClips, _overlayClips]) {
      try {
        return list.firstWhere((c) => c.id == clipId);
      } catch (_) {}
    }
    return null;
  }

  /// Get clip at playhead position
  TimelineItem? getClipAtPosition(Duration position) {
    for (final list in [_videoClips, _audioClips, _textClips, _overlayClips]) {
      for (final clip in list) {
        if (position >= clip.startTime &&
            position < clip.startTime + clip.duration) {
          return clip;
        }
      }
    }
    return null;
  }

  /// Get active video clip at position
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

  /// Helper: Sort clips by start time
  void _sortClips(List<TimelineItem> clips) {
    clips.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Helper: Update clip in list
  void _updateInList(List<TimelineItem> list, TimelineItem updated) {
    final index = list.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      list[index] = updated;
      _sortClips(list);
    }
  }

  // Get the currently selected clip (any type)
  TimelineItem? getSelectedClip() {
    if (selectedClipId == null || selectedClipType == null) return null;

    switch (selectedClipType!) {
      case TimelineItemType.video:
        return videoClips.firstWhereOrNull((c) => c.id == selectedClipId);
      case TimelineItemType.audio:
        return audioClips.firstWhereOrNull((c) => c.id == selectedClipId);
      case TimelineItemType.text:
        return textClips.firstWhereOrNull((c) => c.id == selectedClipId);
      case TimelineItemType.overlay:
      case TimelineItemType.stickers:
        return overlayClips.firstWhereOrNull((c) => c.id == selectedClipId);
      default:
        return null;
    }
  }

  /// Clear all clips
  void clearAll() {
    _videoClips.clear();
    _audioClips.clear();
    _textClips.clear();
    _overlayClips.clear();
    _selectedClipId = null;
    _selectedClipType = null;
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