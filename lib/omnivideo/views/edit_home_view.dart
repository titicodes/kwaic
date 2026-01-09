import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kwaic/omnivideo/model/video_track.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../nes_scr/widgets/sound_fx_sheet.dart';
import '../provider/video_editor_provider.dart';
import '../widgets/audio_context_toolbar.dart';
import '../widgets/audio_sheet.dart';
import '../widgets/bottom_navbar_widget.dart';
import '../widgets/context_toolbar_widget.dart'; // EditContextToolbar
import '../widgets/fill_bottom_sheet.dart' as fill;
import '../widgets/flip_bottom_sheet.dart' as flip;
import '../widgets/rotate_bottom_sheet.dart' as rotate;
import '../widgets/speed_bottom_sheet.dart';
import '../widgets/text_bottom_sheet.dart';
import '../widgets/text_to_audio_sheet.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/trim_bottom_sheet.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/voiceover_recorder.dart'; // VoiceoverRecorder

class VideoEditorScreens extends StatefulWidget {
  final List<Map<String, dynamic>> videosWithThumbs;
  final String projectId;
  final String projectName;

  const VideoEditorScreens({
    super.key,
    required this.videosWithThumbs,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<VideoEditorScreens> createState() => _VideoEditorScreensState();
}

class _VideoEditorScreensState extends State<VideoEditorScreens> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideos();
    });
  }

  Future<void> _initializeVideos() async {
    final provider = context.read<VideoEditorProvider>();
    provider.videoTracks = [];

    Duration currentStart = Duration.zero;
    for (int i = 0; i < widget.videosWithThumbs.length; i++) {
      final videoData = widget.videosWithThumbs[i];
      final XFile xfile = videoData['file'];
      final Uint8List? thumbnail = videoData['thumbnail'];

      final tempController = VideoPlayerController.file(File(xfile.path));
      try {
        await tempController.initialize();
        final Duration videoDuration = tempController.value.duration;

        final VideoTrack track = VideoTrack(
          id: '${widget.projectId}_$i',
          path: xfile.path,
          startTime: currentStart,
          endTime: currentStart + videoDuration,
          thumbnail: thumbnail,
          timelineThumbnails: [],
        );

        provider.videoTracks.add(track);
        currentStart += videoDuration;
      } finally {
        await tempController.dispose();
      }
    }

    provider.notifyListeners();

    if (provider.videoTracks.isNotEmpty) {
      final firstTrack = provider.videoTracks.first;
      await provider.switchToClip(firstTrack);
      provider.selectedTrackIndex = 0;
      provider.generateThumbnailsForAllClips();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.timelineScrollController.jumpTo(0.0);
        provider.seekTo(Duration.zero);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoEditorProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                // Main content — now takes full height
                Column(
                  children: [
                    _TopBar(projectName: widget.projectName),
                    Expanded(
                      child: Container(
                        color: Colors.black,
                        child: const VideoPlayerWidget(),
                      ),
                    ),
                    _PlaybackControls(provider: provider),
                    const SizedBox(height: 4),
                    const TimelineWidget(),
                    // REMOVE THE FIXED SizedBox(height: 160)
                    // No extra space needed — Stack handles overlays
                  ],
                ),

                // Bottom Nav Bar — always at bottom
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: BottomNavBarWidget(),
                ),

                // Bottom Sheets (Speed, Audio, Text, etc.)
                if (provider.showBottomSheet)
                  Positioned(
                    bottom: provider.showContextToolbar ? 80 : 72, // Above toolbar or nav
                    left: 0,
                    right: 0,
                    child: _buildActiveBottomSheet(provider.currentTool, provider),
                  ),

                // Context Toolbars — only when visible
                if (provider.showContextToolbar)
                  Positioned(
                    bottom: 72, // Always just above BottomNavBar
                    left: 0,
                    right: 0,
                    child: provider.showAudioContextToolbar
                        ? const AudioContextToolbar()
                        : const EditContextToolbar(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveBottomSheet(String tool, VideoEditorProvider provider) {
    // Video tools require selection
    if (['trim', 'rotate', 'flip', 'fill', 'speed'].contains(tool)) {
      if (provider.selectedVideoTrackId == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider
            ..showBottomSheet = false
            ..showContextToolbar = true;
        });
        return const Center(
          child: Text(
            'Please select a video clip first',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      }
    }

    switch (tool) {
      case 'trim':
        return const TrimBottomSheet();

      case 'rotate':
        return rotate.RotateBottomSheet(
          onClose: () {
            provider.rotation = 0.0;
            provider
              ..showBottomSheet = false
              ..showContextToolbar = true;
          },
          onApply: () {
            final current = provider.videoTracks[provider.selectedTrackIndex];
            final updated = current.copyWith(
              rotation: current.rotation + provider.rotation,
            );
            provider.replaceTrack(provider.selectedTrackIndex, updated);
            provider.rotation = 0.0;
            provider
              ..showBottomSheet = false
              ..showContextToolbar = true;
          },
          onRotate: (angle) {
            provider.rotation += angle;
          },
          onFlip: () {},
        );

      case 'flip':
        return flip.FlipBottomSheet(
          onClose: () {
            provider.flipHorizontal = false;
            provider.flipVertical = false;
            provider
              ..showBottomSheet = false
              ..showContextToolbar = true;
          },
          onApply: () {
            final current = provider.videoTracks[provider.selectedTrackIndex];
            final updated = current.copyWith(
              flipHorizontal: provider.flipHorizontal,
              flipVertical: provider.flipVertical,
            );
            provider.replaceTrack(provider.selectedTrackIndex, updated);
            provider.flipHorizontal = false;
            provider.flipVertical = false;
            provider
              ..showBottomSheet = false
              ..showContextToolbar = true;
          },
          onFlip: (bool horizontal) {
            if (horizontal) {
              provider.flipHorizontal = !provider.flipHorizontal;
            } else {
              provider.flipVertical = !provider.flipVertical;
            }
          },
        );

      case 'fill':
        return fill.FillBottomSheet(
          onClose: () {
            provider.resetCrop();
            provider
              ..showBottomSheet = false
              ..showContextToolbar = true;
          },
          onApply: () {
            final current = provider.videoTracks[provider.selectedTrackIndex];
            final updated = current.copyWith(
              cropRect: provider.previewCropRect,
              cropZoom: provider.previewCropZoom,
            );
            provider.replaceTrack(provider.selectedTrackIndex, updated);
            provider
              ..showBottomSheet = false
              ..showContextToolbar = true;
          },
        );

      case 'audio':
        return AudioLibrarySheet(insertPosition: provider.currentPosition);

      case 'speed':
        return const SpeedBottomSheet();

      case 'text':
        return const TextBottomSheet();

      case 'soundfx':
        return const SoundFXSheet();

      case 'record':
        return const VoiceoverRecorder();

      case 'texttoaudio':
        return TextToAudioSheet(insertPosition: provider.currentPosition);

      default:
        return const SizedBox.shrink();
    }
  }
}

class _TopBar extends StatelessWidget {
  final String projectName;

  const _TopBar({required this.projectName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            projectName,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: GestureDetector(
              onTap: () async {
                final provider = context.read<VideoEditorProvider>();
                final outputPath = await provider.exportProject();
                if (outputPath != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Exported to: $outputPath')),
                  );
                }
              },
              child: const Text(
                'Export',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  final VideoEditorProvider provider;

  const _PlaybackControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              provider.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () => provider.togglePlayPause(),
          ),
          const SizedBox(width: 8),
          StreamBuilder(
            stream: Stream.periodic(const Duration(milliseconds: 500), (i) => i),
            builder: (context, snapshot) {
              return Text(
                '${_formatDuration(provider.currentPosition)} | '
                    '${_formatDuration(provider.videoController?.value.duration ?? Duration.zero)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              );
            },
          ),
          const Spacer(),
          const Icon(Icons.undo, color: Colors.white70, size: 18),
          const SizedBox(width: 12),
          const Icon(Icons.redo, color: Colors.white70, size: 18),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}