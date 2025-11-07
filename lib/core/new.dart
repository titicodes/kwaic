// editor_controller.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:get/get.dart';
import 'package:undo/undo.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

import 'clip_model.dart';

class EditorControllers extends GetxController {
  // ────────────────────────────────────── OBSERVABLES ──────────────────────────────────────
  final RxList<ClipModel> clips = <ClipModel>[].obs;
  final selectedIndex = (-1).obs;
  final selectedToolTab = 0.obs;

  VideoPlayerController? player;
  final isPlaying = false.obs;
  final currentMs = 0.0.obs;
  final exporting = false.obs;

  String? bgMusicPath;
  String? voiceoverPath;
  String? ttsPath;

  StreamSubscription? _posSub;
  final ChangeStack _cs = ChangeStack();

  // ────────────────────────────────────── UNDO / REDO ──────────────────────────────────────
  void addChange(Change change) => _cs.add(change);
  void undo() => _cs.undo();
  void redo() => _cs.redo();
  bool get canUndo => _cs.canUndo;
  bool get canRedo => _cs.canRedo;

  // ────────────────────────────────────── LIFECYCLE ──────────────────────────────────────
  @override
  void onClose() {
    _stopPlayerListener();
    player?.dispose();
    super.onClose();
  }

  // ────────────────────────────────────── VIDEO PICK & THUMBNAILS ──────────────────────────────────────
  Future<void> pickVideo() async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        Get.snackbar('Permission', 'Storage access denied');
        return;
      }

      final res = await FilePicker.platform.pickFiles(type: FileType.video);
      if (res == null || res.files.isEmpty) return;

      final path = res.files.single.path!;
      final durationMs = await _getVideoDurationMs(path);
      if (durationMs <= 0) {
        Get.snackbar('Error', 'Invalid video duration');
        return;
      }

      final newClip = ClipModel(
        path: path,
        startMs: 0,
        endMs: durationMs.toDouble(),
        originalDurationMs: durationMs.toDouble(),
      );

      clips.add(newClip);
      selectedIndex.value = clips.length - 1;

      // Generate thumbnails in background
      unawaited(_generateThumbnailsForClip(newClip));

      await loadSelectedToPlayer();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load video: $e');
    }
  }

  Future<int> _getVideoDurationMs(String path) async {
    final tmp = VideoPlayerController.file(File(path));
    try {
      await tmp.initialize();
      return tmp.value.duration.inMilliseconds;
    } finally {
      await tmp.dispose();
    }
  }

  Future<void> _generateThumbnailsForClip(
    ClipModel clip, {
    int count = 12,
  }) async {
    try {
      final thumbs = <String>[];
      for (int i = 0; i < count; i++) {
        final time = ((i / (count - 1)) * clip.endMs).toInt();
        final thumb = await VideoThumbnail.thumbnailFile(
          video: clip.path,
          imageFormat: ImageFormat.PNG,
          timeMs: time,
          quality: 75,
        );
        if (thumb != null) thumbs.add(thumb);
      }

      // Use copyWith to update thumbs
      final updated = clip.copyWith(thumbs: thumbs);
      final idx = clips.indexOf(clip);
      if (idx != -1) {
        clips[idx] = updated;
        clips.refresh();
      }
    } catch (e) {
      print('Thumbnail error: $e');
    }
  }

  // ────────────────────────────────────── PLAYER & POSITION ──────────────────────────────────────
  Future<void> loadSelectedToPlayer() async {
    final idx = selectedIndex.value;
    if (idx < 0 || idx >= clips.length) return;

    final clip = clips[idx];
    await player?.dispose();
    player = VideoPlayerController.file(File(clip.path));

    try {
      await player!.initialize();
      player!.setLooping(false);
      player!.setPlaybackSpeed(clip.speed);
      player!.setVolume(clip.volume);
      await player!.seekTo(Duration(milliseconds: clip.startMs.toInt()));
      _startPlayerListener();
      if (isPlaying.value) player!.play();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load video: $e');
    }
  }

  void _startPlayerListener() {
    _stopPlayerListener();
    _posSub = Stream.periodic(const Duration(milliseconds: 100)).listen((_) {
      if (player == null || !player!.value.isInitialized) return;

      final pos = player!.value.position.inMilliseconds.toDouble();
      currentMs.value = pos;

      final idx = selectedIndex.value;
      if (idx < 0 || idx >= clips.length) return;

      final clip = clips[idx];
      final localPos = pos - clip.startMs;

      // Auto-loop within trim range
      if (localPos >= clip.endMs - clip.startMs) {
        player!.seekTo(Duration(milliseconds: clip.startMs.toInt()));
      }
    });
  }

  void _stopPlayerListener() {
    _posSub?.cancel();
    _posSub = null;
  }

  void togglePlayPause() {
    if (player == null || !player!.value.isInitialized) return;
    if (player!.value.isPlaying) {
      player!.pause();
      isPlaying.value = false;
    } else {
      player!.play();
      isPlaying.value = true;
    }
  }

  Future<void> seekToMs(double ms) async {
    if (player == null || !player!.value.isInitialized) return;
    final dur = player!.value.duration.inMilliseconds.toDouble();
    final target = ms.clamp(0.0, dur).toInt();
    await player!.seekTo(Duration(milliseconds: target));
    currentMs.value = target.toDouble();
  }

  // ────────────────────────────────────── UNDO-WRAPPED ACTIONS ──────────────────────────────────────
  // ────────────────────────────────────── UNDO-WRAPPED ACTIONS ──────────────────────────────────────
  VoidCallback _wrap(VoidCallback fn) {
    return () {
      final idx = selectedIndex.value;
      if (idx < 0 || idx >= clips.length) return;

      final before = clips[idx].copy();
      fn();
      final after = clips[idx];

      addChange(
        Change<ClipModel>(
          before,
          () {
            // REDO
            _replaceClip(idx, after);
          },
          (ClipModel oldClip) {
            // UNDO
            _replaceClip(idx, oldClip);
          },
        ),
      );
    };
  }

  void _replaceClip(int idx, ClipModel clip) {
    clips[idx] = clip;
    clips.refresh();
    loadSelectedToPlayer();
  }

  // ────────────────────────────────────── TRIM ──────────────────────────────────────
  void setTrimStart(double ms) =>
      _wrap(() {
        final clip = clips[selectedIndex.value];
        clip.startMs = ms.clamp(0.0, clip.endMs - 100);
        seekToMs(clip.startMs);
      })();

  void setTrimEnd(double ms) =>
      _wrap(() {
        final clip = clips[selectedIndex.value];
        final max = clip.originalDurationMs;
        clip.endMs = ms.clamp(clip.startMs + 100, max);
        seekToMs(clip.endMs);
      })();

  // ────────────────────────────────────── SPLIT ──────────────────────────────────────
  Future<void> splitClip() async {
    final idx = selectedIndex.value;
    if (idx < 0) return;

    final clip = clips[idx];
    final splitPoint = currentMs.value - clip.startMs;
    if (splitPoint <= 100 || splitPoint >= clip.endMs - clip.startMs - 100)
      return;

    final firstEnd = clip.startMs + splitPoint;
    final secondStart = firstEnd;

    final firstClip = clip.copyWith(endMs: firstEnd);
    final secondClip = clip.copyWith(startMs: secondStart, endMs: clip.endMs);

    await _generateThumbnailsForClip(firstClip);
    await _generateThumbnailsForClip(secondClip);

    // Capture full state
    final beforeClips = clips.map((c) => c.copy()).toList();
    final beforeIndex = selectedIndex.value;

    // Perform split
    clips.removeAt(idx);
    clips.insert(idx, firstClip);
    clips.insert(idx + 1, secondClip);
    selectedIndex.value = idx + 1;

    final afterClips = clips.map((c) => c.copy()).toList();
    final afterIndex = selectedIndex.value;

    addChange(
      Change<List<ClipModel>>(
        beforeClips,
        () {
          // REDO
          clips.clear();
          clips.addAll(afterClips);
          selectedIndex.value = afterIndex;
          clips.refresh();
          loadSelectedToPlayer();
        },
        (List<ClipModel> oldClips) {
          // UNDO
          clips.clear();
          clips.addAll(oldClips);
          selectedIndex.value = beforeIndex;
          clips.refresh();
          loadSelectedToPlayer();
        },
      ),
    );

    await loadSelectedToPlayer();
  }

  // ────────────────────────────────────── SPEED & VOLUME ──────────────────────────────────────
  void setSpeed(double speed) =>
      _wrap(() {
        final clip = clips[selectedIndex.value];
        clip.speed = speed.clamp(0.25, 4.0);
        player?.setPlaybackSpeed(clip.speed);
      })();

  void setVolume(double volume) =>
      _wrap(() {
        final clip = clips[selectedIndex.value];
        clip.volume = volume.clamp(0.0, 2.0);
        player?.setVolume(clip.volume);
      })();

  // ────────────────────────────────────── FLIP & ROTATE ──────────────────────────────────────
  void toggleFlipHorizontal() =>
      _wrap(() {
        final clip = clips[selectedIndex.value];
        clip.flipHorizontal = !clip.flipHorizontal;
      })();

  void toggleFlipVertical() =>
      _wrap(() {
        final clip = clips[selectedIndex.value];
        clip.flipVertical = !clip.flipVertical;
      })();

  void rotateClip(int degrees) =>
      _wrap(() {
        final clip = clips[selectedIndex.value];
        clip.rotation = (clip.rotation + degrees) % 360;
      })();

  // ────────────────────────────────────── CROP & CHROMA ──────────────────────────────────────
  void setCrop(Map<String, double> params) =>
      _wrap(() {
        final clip = clips[selectedIndex.value];
        clip.cropParams = Map.from(params);
      })();

  void setColorKey(String color) =>
      _wrap(() {
        final clip = clips[selectedIndex.value];
        clip.colorKey = color;
      })();

  // ────────────────────────────────────── TRANSITION ──────────────────────────────────────
  void setTransition(String type, double durationSec) =>
      _wrap(() {
        final idx = selectedIndex.value;
        if (idx >= clips.length - 1) return;
        final clip = clips[idx];
        clip.transitionType = type;
        clip.transitionDuration = durationSec;
      })();

  // ────────────────────────────────────── FILTER ──────────────────────────────────────
  void setFilter(String name) =>
      _wrap(() {
        final clip = clips[selectedIndex.value];
        clip.filterName = name;
        clip.filter = _getFilterId(name);
      })();

  String _getFilterId(String name) {
    const map = {
      'B&W': 'hue=s=0',
      'Sepia':
          'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131',
      'Vintage': 'curves=vintage',
      'Glitch': 'rgbashift',
    };
    return map[name] ?? '';
  }

  // ────────────────────────────────────── OVERLAYS ──────────────────────────────────────
  void addTextOverlay(TextOverlay overlay) {
    final idx = selectedIndex.value;
    if (idx < 0) return;

    final before = clips[idx].copy();
    final newOverlays = List<TextOverlay>.from(clips[idx].textOverlays)
      ..add(overlay);
    clips[idx] = clips[idx].copyWith(textOverlays: newOverlays);
    clips.refresh();

    final after = clips[idx].copy();

    addChange(
      Change<ClipModel>(
        before,
        () {
          // REDO
          _replaceClip(idx, after);
        },
        (ClipModel oldClip) {
          // UNDO
          _replaceClip(idx, oldClip);
        },
      ),
    );
  }

  void addStickerOverlay(StickerOverlay overlay) {
    final idx = selectedIndex.value;
    if (idx < 0) return;

    final before = clips[idx].copy();
    final newOverlays = List<StickerOverlay>.from(clips[idx].stickerOverlays)
      ..add(overlay);
    clips[idx] = clips[idx].copyWith(stickerOverlays: newOverlays);
    clips.refresh();

    final after = clips[idx].copy();

    addChange(
      Change<ClipModel>(
        before,
        () {
          // REDO
          _replaceClip(idx, after);
        },
        (ClipModel oldClip) {
          // UNDO
          _replaceClip(idx, oldClip);
        },
      ),
    );
  }

  // ────────────────────────────────────── AUDIO ──────────────────────────────────────
  Future<void> pickBackgroundMusic() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (res?.files.single.path != null) {
      bgMusicPath = res!.files.single.path!;
      Get.snackbar('Music', 'Background music selected');
    }
  }

  Future<void> pickVoiceover() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (res?.files.single.path != null) {
      voiceoverPath = res!.files.single.path!;
      Get.snackbar('Voiceover', 'Voiceover selected');
    }
  }

  Future<void> generateAndSaveTTS(String text) async {
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
      // TODO: Replace with real TTS
      await Future.delayed(const Duration(seconds: 1));
      ttsPath = path;
      Get.snackbar('TTS', 'Generated (placeholder)');
    } catch (e) {
      Get.snackbar('TTS', 'Failed: $e');
    }
  }

  // ────────────────────────────────────── EXPORT (ROBUST) ──────────────────────────────────────
  Future<String?> exportProject() async {
    if (clips.isEmpty) {
      Get.snackbar('Export', 'No clips to export');
      return null;
    }

    exporting.value = true;
    final tmpDir = await getTemporaryDirectory();
    final processed = <String>[];

    try {
      for (int i = 0; i < clips.length; i++) {
        final clip = clips[i];
        final outPath = '${tmpDir.path}/clip_$i.mp4';

        final cmd = await _buildClipCommand(clip, outPath);
        final session = await FFmpegKit.execute(cmd);
        final rc = await session.getReturnCode();

        if (!ReturnCode.isSuccess(rc)) {
          throw Exception('FFmpeg failed on clip $i');
        }
        processed.add(outPath);
      }

      // Concatenate
      final concatFile = await _createConcatList(processed, tmpDir.path);
      final finalOut = '${tmpDir.path}/final_export.mp4';
      final concatCmd =
          '-f concat -safe 0 -i "$concatFile" -c copy -y "$finalOut"';
      var session = await FFmpegKit.execute(concatCmd);
      var rc = await session.getReturnCode();

      if (!ReturnCode.isSuccess(rc)) {
        // Fallback: re-encode
        final inputs = processed.map((p) => '-i "$p"').join(' ');
        final filter =
            List.generate(processed.length, (i) => '[$i:v][$i:a]').join();
        final concatCmd2 =
            '$inputs -filter_complex "$filter concat=n=${processed.length}:v=1:a=1[outv][outa]" -map "[outv]" -map "[outa]" -c:v libx264 -preset fast -crf 23 -c:a aac -y "$finalOut"';
        session = await FFmpegKit.execute(concatCmd2);
        rc = await session.getReturnCode();
        if (!ReturnCode.isSuccess(rc)) throw Exception('Concat failed');
      }

      // Merge audio
      if (bgMusicPath != null || voiceoverPath != null || ttsPath != null) {
        final merged = '${tmpDir.path}/final_with_audio.mp4';
        final cmd = await _buildAudioMergeCommand(finalOut, merged);
        final s = await FFmpegKit.execute(cmd);
        final r = await s.getReturnCode();
        return ReturnCode.isSuccess(r) ? merged : finalOut;
      }

      return finalOut;
    } catch (e) {
      Get.snackbar('Export Failed', e.toString());
      return null;
    } finally {
      exporting.value = false;
    }
  }

  Future<String> _buildClipCommand(ClipModel clip, String outPath) async {
    final start = (clip.startMs / 1000).toStringAsFixed(3);
    final duration = ((clip.endMs - clip.startMs) / 1000).toStringAsFixed(3);
    final speed = clip.speed;

    var vFilter = 'setpts=${(1 / speed).toStringAsFixed(6)}*PTS';
    if (clip.flipHorizontal) vFilter += ',hflip';
    if (clip.flipVertical) vFilter += ',vflip';
    if (clip.rotation != 0) {
      final rad = clip.rotation * 3.14159 / 180;
      vFilter += ',rotate=$rad:ow=rotw(iw):oh=roth(ih)';
    }
    if (clip.cropParams != null) {
      final c = clip.cropParams!;
      vFilter += ',crop=${c['w']}:${c['h']}:${c['x']}:${c['y']}';
    }
    if (clip.filter.isNotEmpty) vFilter += ',${clip.filter}';

    var aFilter = 'atempo=$speed,volume=${clip.volume}';

    return '-ss $start -t $duration -i "${clip.path}" '
        '-filter_complex "[0:v]$vFilter[v];[0:a]$aFilter[a]" '
        '-map "[v]" -map "[a]" -c:v libx264 -preset fast -crf 23 -c:a aac -y "$outPath"';
  }

  Future<String> _createConcatList(List<String> files, String dir) async {
    final path = '$dir/concat.txt';
    final content = files.map((f) => "file '$f'").join('\n');
    await File(path).writeAsString(content);
    return path;
  }

  Future<String> _buildAudioMergeCommand(
    String videoPath,
    String outPath,
  ) async {
    final inputs = ['-i "$videoPath"'];
    if (bgMusicPath != null) inputs.add('-i "$bgMusicPath"');
    if (voiceoverPath != null) inputs.add('-i "$voiceoverPath"');
    if (ttsPath != null) inputs.add('-i "$ttsPath"');

    final count = inputs.length;
    final amix = List.generate(count, (i) => '[$i:a]').join();
    final filter = '$amix amix=inputs=$count:duration=shortest[aout]';

    return '${inputs.join(' ')} -filter_complex "$filter" '
        '-map 0:v -map "[aout]" -c:v copy -c:a aac -shortest -y "$outPath"';
  }

  // ────────────────────────────────────── UTILITIES ──────────────────────────────────────
  Future<void> denoiseClip() async {
    Get.snackbar('Denoise', 'Applied (placeholder)');
  }

  Future<void> autoCaption() async {
    Get.snackbar('Auto Caption', 'Generated (placeholder)');
  }
}
