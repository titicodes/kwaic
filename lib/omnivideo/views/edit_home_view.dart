import 'package:flutter/material.dart';
import 'package:kwaic/omnivideo/model/video_track.dart';
import 'package:provider/provider.dart';
import '../../nes_scr/widgets/audio_library_sheet.dart';
import '../provider/video_editor_provider.dart';
import '../widgets/bottom_navbar_widget.dart';
import '../widgets/edit_context_toolbar.dart';
import '../widgets/fill_bottom_sheet.dart' as fill;
import '../widgets/flip_bottom_sheet.dart' as flip;
import '../widgets/rotate_bottom_sheet.dart' as rotate;
import '../widgets/speed_bottom_sheet.dart';
import '../widgets/text_bottom_sheet.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/trim_bottom_sheet.dart';
import '../widgets/video_player_widget.dart';

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
  late List<VideoTrack> _videoTracks;
  final ScrollController _timelineScrollController = ScrollController();
  int _selectedTrackIndex = 0;

  @override
  void initState() {
    super.initState();

    _initializeVideos().then((_) {
      // _provider.generateThumbnailsForAllClips(); // Add this line
    });
  }

  Future<void> _initializeVideos() async {
    final provider = context.read<VideoEditorProvider>(); // ← read from context
    _videoTracks =
        widget.videosWithThumbs.asMap().entries.map((entry) {
          final index = entry.key;
          final video = entry.value;
          return VideoTrack(
            id: '${widget.projectId}_$index',
            path: video['file'].path,
            startTime: Duration.zero,
            endTime: const Duration(seconds: 10),
            thumbnail: video['thumbnail'],
            timelineThumbnails: [],
          );
        }).toList();

    provider.videoTracks = _videoTracks;
    if (_videoTracks.isNotEmpty) {
      _selectedTrackIndex = 0;
      provider.selectedTrackIndex = 0;
      await provider.loadVideo(_videoTracks[0].path);
      provider.generateThumbnailsForAllClips();
    }
  }

  @override
  void dispose() {
    _timelineScrollController.dispose();
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
                // Main content column
                Column(
                  children: [
                    _TopBar(projectName: widget.projectName),
                    Expanded(
                      child: Container(
                        color: Colors.black,
                        child: VideoPlayerWidget(
                          controller: provider.videoController!,
                        ),
                      ),
                    ),
                    _PlaybackControls(provider: provider),
                    const SizedBox(height: 4),
                    TimelineWidget(),
                    const SizedBox(height: 80), // Space for bottom navbar
                  ],
                ),
                // Bottom navbar (always visible)
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: BottomNavBarWidget(),
                ),
                // Trim bottom sheet (replaces context toolbar when needed)

                // Replace the conditional positioned widgets with:
                if (provider.showBottomSheet)
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: _buildActiveBottomSheet(
                      provider.currentTool,
                      provider,
                    ),
                  )
                else if (provider.showContextToolbar)
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: const EditContextToolbar(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveBottomSheet(String tool, VideoEditorProvider provider) {
    switch (tool) {
      case 'trim':
        return const TrimBottomSheet();

      case 'rotate':
        return rotate.RotateBottomSheet(
          onClose: () {
            provider.rotation = 0; // Reset preview on cancel
            provider
              ..showBottomSheet = false
              ..showContextToolbar = true;
          },
          onApply: () {
            final current = provider.videoTracks[provider.selectedTrackIndex];
            final updated = current.copyWith(
              rotation: current.rotation + provider.rotation, // Apply accumulated preview
            );
            provider.replaceTrack(provider.selectedTrackIndex, updated);
            provider.rotation = 0; // Reset preview

            provider
              ..showBottomSheet = false
              ..showContextToolbar = true;
          },
          onRotate: (angle) {
            provider.rotation += angle; // Live preview update
          },
          onFlip: () {
            // Flip is handled in flip sheet
          },
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
              flipHorizontal: current.flipHorizontal != provider.flipHorizontal
                  ? provider.flipHorizontal
                  : current.flipHorizontal,
              flipVertical: current.flipVertical != provider.flipVertical
                  ? provider.flipVertical
                  : current.flipVertical,
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
            provider.resetCrop(); // Reset preview on cancel
            provider
              ..showBottomSheet = false
              ..showContextToolbar = true;
          },
          onApply: () {
            final currentTrack = provider.videoTracks[provider.selectedTrackIndex];
            final updated = currentTrack.copyWith(
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

      default:
        return const SizedBox();
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
            child: const Text(
              'Export',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
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
          // Play/Pause button
          IconButton(
            icon: Icon(
              provider.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () {
              provider.togglePlayPause();
              // Also control native player for sound
              if (provider.isPlaying) {
                provider.videoController?.play();
              } else {
                provider.videoController?.pause();
              }
            },
          ),
          const SizedBox(width: 8),
          // Time display
          StreamBuilder(
            stream: Stream.periodic(
              const Duration(milliseconds: 500),
              (i) => i,
            ),
            builder: (context, snapshot) {
              return Text(
                '${_formatDuration(provider.currentPosition)} | '
                '${_formatDuration(provider.videoController?.value.duration ?? Duration.zero)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              );
            },
          ),
          const Spacer(),
          // Undo/Redo buttons
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
