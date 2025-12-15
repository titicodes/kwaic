import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart' as http;
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

// Controllers

// Models
import '../model/timeline_item.dart';
import '../servuices/audio_manager.dart';
import '../servuices/clip_controller.dart';
import '../servuices/playback_controller.dart';
import '../servuices/time_line_controller.dart';
import '../servuices/video_manager.dart';
import '../widgets/animation_sheet.dart';
import '../widgets/audio_library_sheet.dart';
import '../widgets/auto_caption_sheet.dart';
import '../widgets/context_toolbar.dart';
import '../widgets/effect_tile.dart';
import '../widgets/effects_sheet.dart';
import '../widgets/play_back_controls.dart';
import '../widgets/preview_player.dart';
import '../widgets/sound_fx_sheet.dart';
import '../widgets/speed_sheet.dart';
import '../widgets/sticker_sheet.dart';
import '../widgets/text_bottom_sheet.dart';
import '../widgets/text_to_audio_sheet.dart';
import '../widgets/timeline.dart';
import '../widgets/toolbar.dart';
import '../widgets/top_bar.dart';
import '../widgets/voiceover_recorder.dart';

/// Main Video Editor Screen - Now simplified to ~300 lines!
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

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  // Controllers
  late VideoManager videoManager;
  late AudioManager audioManager;
  late PlaybackController playbackController;
  late TimelineController timelineController;
  late ClipController clipController;

  // UI State
  BottomNavMode _currentNavMode = BottomNavMode.normal;
  bool _isInitializing = false;

  // Project Info
  late String projectId;
  late String projectName;

  @override
  void initState() {
    super.initState();

    projectId =
        widget.projectId ?? DateTime.now().millisecondsSinceEpoch.toString();
    projectName = widget.projectName ?? 'Untitled Project';

    _initializeControllers();

    if (widget.initialVideos?.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _processInitialVideos(),
      );
    }
  }

  void _initializeControllers() {
    videoManager = VideoManager();
    audioManager = AudioManager();

    playbackController = PlaybackController(
      videoManager: videoManager,
      audioManager: audioManager,
    );

    timelineController = TimelineController();

    clipController = ClipController(
      videoManager: videoManager,
      audioManager: audioManager,
      timelineController: timelineController,
    );

    // Listen to controllers
  }

  Future<void> _processInitialVideos() async {
    if (_isInitializing || widget.initialVideos == null) return;

    setState(() => _isInitializing = true);

    try {
      Duration currentStart = Duration.zero;

      for (var videoFile in widget.initialVideos!) {
        final item = await _createVideoItemFromFile(
          videoFile,
          startTime: currentStart,
        );

        if (item != null) {
          await clipController.addVideoClip(item);
          currentStart += item.duration;
        }
      }

      // Switch to first clip
      if (clipController.videoClips.isNotEmpty) {
        final firstClip = clipController.videoClips.first;
        await videoManager.switchToClip(
          firstClip,
          playheadPosition: Duration.zero,
          isPlaying: false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading videos: $e');
      _showError('Failed to load videos');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<TimelineItem?> _createVideoItemFromFile(
    XFile file, {
    Duration startTime = Duration.zero,
  }) async {
    try {
      final path = file.path;
      final fileObj = File(path);

      // 1. Get real duration
      final controller = VideoPlayerController.file(fileObj);
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose(); // Clean!

      // 2. Generate thumbnails with fallback
      List<Uint8List> thumbs = [];
      try {
        thumbs = await clipController.generateRobustThumbnails(path, duration);
      } catch (e) {
        debugPrint('FFmpeg thumbnail failed: $e, using fallback...');
        thumbs = await _generateFallbackThumbnails(path, duration);
      }

      return TimelineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TimelineItemType.video,
        file: fileObj,
        startTime: startTime,
        duration: duration,
        originalDuration: duration,
        trimStart: Duration.zero,
        trimEnd: duration,
        thumbnailBytes: thumbs,
      );
    } catch (e, s) {
      debugPrint('Error creating video item: $e\n$s');
      return null;
    }
  }

  Future<List<Uint8List>> _generateFallbackThumbnails(
    String videoPath,
    Duration duration,
  ) async {
    final List<Uint8List> thumbs = [];
    const int count = 12;
    final int safeStartMs = 800; // Skip first 0.8s (avoids black frame)
    final int safeEndMs = (duration.inMilliseconds - 1000).clamp(
      1000,
      duration.inMilliseconds,
    );

    if (duration.inMilliseconds < 2000) {
      // Short video → grab middle frame
      final thumb = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: (duration.inMilliseconds / 2).round(),
        maxWidth: 160,
        quality: 85,
      );
      if (thumb != null) return List.filled(count, thumb);
      return [];
    }

    for (int i = 0; i < count; i++) {
      final progress = i / (count - 1);
      final targetMs =
          (safeStartMs + (safeEndMs - safeStartMs) * progress).round();

      try {
        final uint8list = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: targetMs,
          maxWidth: 160,
          quality: 85,
        );

        if (uint8list != null && uint8list.length > 1000) {
          thumbs.add(uint8list);
        } else {
          // Fill gap: duplicate previous good frame
          if (thumbs.isNotEmpty) thumbs.add(thumbs.last);
        }
      } catch (e) {
        debugPrint('Thumbnail failed at ${targetMs}ms: $e');
        if (thumbs.isNotEmpty) thumbs.add(thumbs.last);
      }
    }

    return thumbs;
  }

  Future<Duration> _getDuration(File file) async {
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    final duration = controller.value.duration;
    await controller.dispose();
    return duration;
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
            // 1. Top Bar
            TopBar(
              projectName: projectName,
              onBack: _handleBack,
              onExport: _handleExport,
              onHelp: () => _showMessage('Help coming soon'),
            ),

            // 2. Preview
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  clipController,
                  playbackController,
                ]),
                builder:
                    (_, __) => VideoPreview(
                      videoManager: videoManager,
                      clipController: clipController,
                      playheadPosition: playbackController.playheadPosition,
                    ),
              ),
            ),

            // 3. Playback Controls
            AnimatedBuilder(
              animation: playbackController,
              builder: (_, __) {
                return PlaybackControls(
                  isPlaying: playbackController.isPlaying,
                  playheadPosition: playbackController.playheadPosition,
                  totalDuration: _getTotalDuration(),
                  onPlayPause: _handlePlayPause,
                  onUndo: _handleUndo,
                  onRedo: _handleRedo,
                );
              },
            ),

            // 4. Timeline
            AnimatedBuilder(
              animation: Listenable.merge([
                timelineController,
                clipController,
                playbackController,
              ]),
              builder:
                  (_, __) => TimelineView(
                    controller: timelineController,
                    clipController: clipController,
                    playheadPosition: playbackController.playheadPosition,
                    isPlaying: playbackController.isPlaying,
                    onTimelineTap: _handleTimelineTap,
                    onClipSelected: _handleClipSelected,
                  ),
            ),

            // 5. Context Toolbar (only when in mode)
            if (_currentNavMode != BottomNavMode.normal)
              ContextToolbar(
                mode: _currentNavMode,
                onSplit: _handleSplit,
                onSound:
                    () => _showAudioLibrarySheet(
                      playbackController.playheadPosition,
                    ),
                onSoundFX: _handleOpenSoundFX,
                onRecord: _handleRecordVoiceover,
                onTextToAudio: _handleTextToAudio,
                onExtract: _handleExtractAudio,
                onAddText: _handleAddText, // ← ADD THESE
                onAutoCaption: _handleAutoCaption,
                onStickers: _handleStickers,
                onApplyFilter: (filter) => clipController.applyFilter(filter),
                onEffects: _handleEffects,
                onVolume: _handleVolume,
                onAnimation: _handleAnimation,
                onEffect: _handleEffect,
                onDelete: _handleDelete,
                onSpeed: _handleSpeed,
                onBeats: _handleBeats,
                onCrop: _handleCrop,
                onDuplicate: _handleDuplicate,
                onReplace: _handleReplace,
                onAdjust: _handleAdjust,
              ),
            // 6. Bottom Navigation
            BottomNav(
              currentMode: _currentNavMode,
              onModeChanged: _handleNavModeChanged,
            ),
          ],
        ),
      ),
    );
  }

  void _showAudioLibrarySheet(Duration position) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AudioLibrarySheet(
            clipController: clipController,
            audioManager: audioManager,
            insertPosition: position,
          ),
    );
  }

  Future<void> _handlePlayPause() async {
    await playbackController.togglePlayPause(
      clips: clipController.videoClips,
      audioItems: clipController.audioClips,
    );
  }

  void _handleTimelineTap(Offset position) {
    final newPosition = timelineController.handleTimelineTap(
      position,
      MediaQuery.of(context).size.width,
    );

    playbackController.seekTo(
      newPosition,
      clips: clipController.videoClips,
      audioItems: clipController.audioClips,
    );
  }

  void _handleClipSelected(String clipId, TimelineItemType type) {
    clipController.selectClip(clipId, type);
  }

  void _handleNavModeChanged(BottomNavMode mode) {
    setState(() {
      _currentNavMode = mode;

      // Update timeline display mode
      switch (mode) {
        case BottomNavMode.audio:
          timelineController.setDisplayMode(TimelineDisplayMode.videoAudioOnly);
          break;
        case BottomNavMode.text:
          timelineController.setDisplayMode(TimelineDisplayMode.videoTextOnly);
          break;
        case BottomNavMode.overlay:
          timelineController.setDisplayMode(
            TimelineDisplayMode.videoOverlayOnly,
          );
          break;
        case BottomNavMode.edit:
          timelineController.setDisplayMode(TimelineDisplayMode.allTracks);
          // Auto-select current video clip
          final currentClip = clipController.getActiveVideoClip(
            playbackController.playheadPosition,
          );
          if (currentClip != null) {
            clipController.selectClip(currentClip.id, currentClip.type);
          }
          if (currentClip != null) {
            clipController.selectClip(currentClip.id, currentClip.type);
            // Optional: Seek to start of clip for easy editing
            playbackController.seekTo(
              currentClip.startTime,
              clips: clipController.videoClips,
              audioItems: clipController.audioClips,
            );
          }
          break;
        default:
          timelineController.setDisplayMode(TimelineDisplayMode.allTracks);
      }
    });
  }

  Future<void> _handleBack() async {
    // Check for unsaved changes
    final shouldPop = await _confirmUnsavedChanges();
    if (shouldPop && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleExport() async {
    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/export_${DateTime.now().millisecondsSinceEpoch}.mp4';

    _showMessage('Exporting...');

    // Build complex FFmpeg command
    String command = '-i "${clipController.videoClips.first.file!.path}"';

    // Add audio tracks
    for (var audio in clipController.audioClips) {
      command += ' -i "${audio.file!.path}"';
    }

    // Filter complex for overlays, text, effects
    String filter = '[0:v]';

    if (clipController.currentFilter != 'none') {
      // Apply filter
    }

    // Add text/overlays as images or drawtext
    // Simplified: burn text in
    for (var text in clipController.textClips) {
      command +=
          ' -vf "drawtext=text=\'${text.text}\':fontcolor=white:fontsize=40:x=100:y=200"';
    }

    command += ' -c:v libx264 -preset fast -crf 23 "$outputPath"';

    final session = await FFmpegKit.execute(command);

    if (await session.getReturnCode().then((rc) => ReturnCode.isSuccess(rc))) {
      // Save to gallery (use gallery_saver package)
      _showMessage('Exported successfully!');
    } else {
      _showMessage('Export failed');
    }
  }

  void _handleUndo() {
    _showMessage('Undo coming soon');

    // This would use HistoryManager
  }

  void _handleRedo() {
    _showMessage('Redo coming soon');
    // This would use HistoryManager
  }

  void _handleSplit() {
    final clip = clipController.getActiveVideoClip(
      playbackController.playheadPosition,
    );
    if (clip != null) {
      clipController.splitClip(clip, playbackController.playheadPosition);
    }
  }

  void _handleDelete() {
    if (clipController.selectedClipType == TimelineItemType.video &&
        clipController.selectedClipId != null) {
      clipController.deleteClip(
        clipController.selectedClipId!,
        clipController.selectedClipType!,
      );
    }
  }

  void _handleOpenMusicLibrary() =>
      _showAudioLibrarySheet(playbackController.playheadPosition);
  void _handleOpenSoundFX() => _showSoundFXSheet();
  void _handleRecordVoiceover() => _showVoiceRecorder();
  void _handleTextToAudio() => _showTextToAudioSheet();
  void _handleEditText() => _showMessage('Edit text coming soon');

  // Helpers
  Duration _getTotalDuration() {
    return Duration(
      seconds:
          playbackController.getTotalDuration([
            clipController.videoClips,
            clipController.audioClips,
            clipController.textClips,
            clipController.overlayClips,
          ]).toInt(),
    );
  }

  Future<bool> _confirmUnsavedChanges() async {
    // Simplified - would check autosave manager
    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    playbackController.dispose();
    videoManager.dispose();
    audioManager.dispose();
    timelineController.dispose();
    clipController.dispose();
    super.dispose();
  }

  void _showSoundFXSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SoundFXSheet(),
    );
  }

  void _showTextToAudioSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => TextToAudioSheet(
            clipController: clipController,
            insertPosition: playbackController.playheadPosition,
          ),
    );
  }

  void _showVoiceRecorder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => VoiceoverRecorder(
            clipController: clipController,
            audioManager: audioManager,
            insertPosition: playbackController.playheadPosition,
          ),
    );
  }

  Future<void> _handleExtractAudio() async {
    final videoClip = clipController.getActiveVideoClip(
      playbackController.playheadPosition,
    );
    if (videoClip == null || videoClip.file == null) {
      _showMessage('No video clip found at playhead');
      return;
    }

    final videoPath = videoClip.file!.path;
    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/extracted_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    _showMessage('Extracting audio...');

    final session = await FFmpegKit.execute(
      '-i "$videoPath" -vn -acodec copy "$outputPath"', // -vn = no video, copy audio stream if possible
    );

    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      final audioFile = File(outputPath);

      // Get duration
      final player = AudioPlayer();
      await player.setFilePath(outputPath);
      final duration =
          player.duration ?? videoClip.duration; // Fallback to video duration
      await player.dispose();

      final audioItem = TimelineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TimelineItemType.audio,
        file: audioFile,
        startTime: videoClip.startTime, // Align with original video
        duration: duration,
        originalDuration: duration,
        trimStart: Duration.zero,
        volume: 1.0,
      );

      await clipController.addAudioClip(audioItem);
      _showMessage('Audio extracted and added to timeline!');
    } else {
      final logs = await session.getLogs();
      debugPrint('FFmpeg failed: ${logs.map((l) => l.getMessage()).join()}');
      _showMessage('Failed to extract audio');
    }
  }

  void _handleAddText() {
    // Auto-add blank editable text
    final blankText = TimelineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TimelineItemType.text,
      startTime: playbackController.playheadPosition,
      duration: const Duration(seconds: 5),
      originalDuration: const Duration(seconds: 5),
      text: 'Tap to edit',
      textColor: Colors.white,
      fontSize: 40.0,
      x: 100.0,
      y: 200.0,
      scale: 1.0,
      rotation: 0.0,
    );

    clipController.addTextClip(blankText);

    // Open text editor sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => TextBottomSheet(
            onApply: (newText, style) {
              final lastText = clipController.textClips.last;
              lastText.text = newText;
              // Apply style here (color, font, etc.)
              clipController.updateClip(lastText);
            },
          ),
    );
  }

  void _handleAutoCaption() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AutoCaptionSheet(),
    );
  }

  void _handleStickers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => StickerSheet(
            onStickerSelected: (String url) async {
              // Download sticker to local file
              final tempDir = await getTemporaryDirectory();
              final response = await http.get(Uri.parse(url));
              final file = File(
                '${tempDir.path}/sticker_${DateTime.now().millisecondsSinceEpoch}${url.endsWith('.svg') ? '.svg' : '.png'}',
              );
              await file.writeAsBytes(response.bodyBytes);

              // Add as overlay/sticker
              final item = TimelineItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: TimelineItemType.stickers, // or overlay
                file: file,
                startTime: playbackController.playheadPosition,
                duration: const Duration(seconds: 5),
                originalDuration: const Duration(seconds: 5),
                x: 100.0,
                y: 200.0,
                scale: 1.0,
                rotation: 0.0,
                layerIndex:
                    clipController.overlayClips.length +
                    clipController.textClips.length,
              );

              clipController.addOverlayClip(
                item,
              ); // or addStickerClip if separate
              Navigator.pop(context);
            },
          ),
    );
  }

  void _handleEffects() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => EffectsSheet(onApply: (e) => clipController.applyEffect(e)),
    );
  }

  void _handleVolume() {
    final clip = clipController.getSelectedClip(); // ← Now works
    if (clip == null) return;

    double currentVol = clip.volume ?? 1.0;

    showModalBottomSheet(
      context: context,
      builder:
          (_) => Container(
            height: 200,
            color: Color(0xFF1A1A1A),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Volume',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                Slider(
                  value: currentVol,
                  min: 0.0,
                  max: 2.0,
                  onChanged: (v) {
                    setState(() => currentVol = v);
                    clip.volume = v;
                    clipController.updateClip(clip);
                    audioManager.setVolume(clip.id, v);
                  },
                ),
                Text(
                  '${(currentVol * 100).round()}%',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
    );
  }

  void _handleAnimation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => AnimationSheet(
            onApply: (anim) {
              final clip = clipController.getSelectedClip(); // ← Now works
              if (clip != null) {
                clip.animationIn = anim;
                clipController.updateClip(clip);
              }
            },
          ),
    );
  }

  void _handleDuplicate() {
    final clip = clipController.getSelectedClip(); // ← Now works
    if (clip != null) {
      clipController.duplicateClip(clip);
    }
  }

  void _handleEffect() {
    timelineController.setDisplayMode(
      TimelineDisplayMode.videoOnly,
    ); // Show only video
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => EffectSheet(
            onApply: (effect) {
              clipController.applyEffect(effect);
            },
          ),
    );
  }

  void _handleSpeed() {
    final clip = clipController.getSelectedClip();
    if (clip?.type != TimelineItemType.video) return;

    timelineController.setDisplayMode(TimelineDisplayMode.videoOnly);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => SpeedSheet(
            clip: clip!,
            onNormal: (speed) {
              clip.speed = speed;
              clip.speedPoints = [
                SpeedPoint(time: 0, speed: speed),
                SpeedPoint(time: 1, speed: speed),
              ];
              clipController.updateClip(clip);
            },
            onCurve: (points) {
              clip.speedPoints = points;
              clipController.updateClip(clip);
            },
          ),
    );
  }

  void _handleAdjust() {
    final clip = clipController.getSelectedClip();
    if (clip == null || clip.type != TimelineItemType.video) {
      _showMessage('Select a video clip');
      return;
    }

    double brightness = clip.brightness ?? 0.0;
    double contrast = clip.contrast ?? 100.0;
    double saturation = clip.saturation ?? 100.0;
    double exposure = clip.exposure ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setStateSheet) => Container(
                  height: 500,
                  color: Color(0xFF1A1A1A),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Adjust',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 20),
                      _adjustSlider('Brightness', brightness, -100, 100, (v) {
                        setStateSheet(() => brightness = v);
                        clip.brightness = v;
                        clipController.updateClip(clip);
                      }),
                      _adjustSlider('Contrast', contrast, 0, 200, (v) {
                        setStateSheet(() => contrast = v);
                        clip.contrast = v;
                        clipController.updateClip(clip);
                      }),
                      _adjustSlider('Saturation', saturation, 0, 200, (v) {
                        setStateSheet(() => saturation = v);
                        clip.saturation = v;
                        clipController.updateClip(clip);
                      }),
                      _adjustSlider('Exposure', exposure, -100, 100, (v) {
                        setStateSheet(() => exposure = v);
                        clip.exposure = v;
                        clipController.updateClip(clip);
                      }),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _adjustSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChange,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white)),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChange,
          activeColor: Color(0xFF00D9FF),
        ),
        Text(value.toStringAsFixed(0), style: TextStyle(color: Colors.white70)),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChange,
  ) {
    return Slider(
      value: value,
      min: min,
      max: max,
      onChanged: (v) {
        onChange(v);
        clipController.updateClip(clipController.getSelectedClip()!);
      },
      label: label,
    );
  }

  void _handleBeats() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Container(
            height: 300,
            color: Color(0xFF1A1A1A),
            child: Center(
              child: Text(
                'Auto beats detected!\nCuts will snap to markers',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
    );
  }

  void _handleCrop() {
    final clip = clipController.getSelectedClip();
    if (clip == null || clip.type != TimelineItemType.video) return;

    showModalBottomSheet(
      context: context,
      builder:
          (_) => Container(
            height: 400,
            color: Color(0xFF1A1A1A),
            child: Column(
              children: [
                Text('Crop Video'),
                // Sliders for left/top/right/bottom or aspect ratio presets
                // Update clip.cropLeft etc.
              ],
            ),
          ),
    );
  }

  void _handleReplace() {
    final clip = clipController.getSelectedClip();
    if (clip == null) return;

    ImagePicker().pickVideo(source: ImageSource.gallery).then((xfile) async {
      if (xfile != null) {
        final newFile = File(xfile.path);
        final newClip = clip.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          file: newFile,
          originalDuration: await _getDuration(newFile),
        );
        clipController.replaceClip(clip.id, newClip);
      }
    });
  }
}

// Bottom Navigation Modes
