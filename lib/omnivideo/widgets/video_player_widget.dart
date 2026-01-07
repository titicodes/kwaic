import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../model/video_track.dart';
import '../provider/video_editor_provider.dart';
import 'draggable_resizable_text.dart';

class VideoPlayerWidget extends StatelessWidget {
  const VideoPlayerWidget({super.key, required this.controller});

  final VideoPlayerController?
  controller; // Can be null briefly during switches

  // Helper: Find active track based on current global position
  VideoTrack? _getActiveTrack(VideoEditorProvider provider) {
    final pos = provider.currentPosition;
    for (final track in provider.videoTracks) {
      if (pos >= track.startTime && pos < track.endTime) {
        return track;
      }
    }
    // Fallback to first track if no match (e.g. at end)
    return provider.videoTracks.isNotEmpty ? provider.videoTracks.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoEditorProvider>(
      builder: (context, provider, _) {
        // Find currently active clip
        final VideoTrack? activeTrack = _getActiveTrack(provider);
        final bool isInitialized =
            controller != null && controller!.value.isInitialized;
        final Size videoSize = isInitialized ? controller!.value.size : Size.zero;

        final controllerSafe =
            controller != null &&
                controller!.value.isInitialized &&
                !provider.isLoadingVideo;

        // Fallback to first clip if no active
        final VideoTrack? currentTrack =
            activeTrack ?? provider.videoTracks.firstOrNull;

        if (currentTrack == null) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                "No video clips added",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          );
        }

        // Transform values
        final double effectiveRotation =
        provider.currentTool == 'rotate'
            ? currentTrack.rotation + provider.rotation
            : currentTrack.rotation;

        final bool effectiveFlipH =
        provider.currentTool == 'flip'
            ? provider.flipHorizontal
            : currentTrack.flipHorizontal;

        final bool effectiveFlipV =
        provider.currentTool == 'flip'
            ? provider.flipVertical
            : currentTrack.flipVertical;

        final Rect effectiveCrop =
        provider.currentTool == 'fill'
            ? provider.previewCropRect
            : currentTrack.cropRect;

        final double effectiveZoom =
        provider.currentTool == 'fill'
            ? provider.previewCropZoom
            : currentTrack.cropZoom;

        return Container(
          color: Colors.black,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background thumbnail
                if (currentTrack.thumbnail != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      currentTrack.thumbnail!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      gaplessPlayback: true,
                    ),
                  ),

                // Video + text overlay
                if (controllerSafe)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: controller!.value.aspectRatio,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: videoSize.width,
                          height: videoSize.height,
                          child: Stack(
                            children: [
                              // Video clip (with all transforms)
                              Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..translate(
                                    currentTrack.position.dx *
                                        videoSize.width / 2,
                                    currentTrack.position.dy *
                                        videoSize.height / 2,
                                  )
                                  ..scale(currentTrack.scale)
                                  ..rotateZ(effectiveRotation * 3.14159 / 180)
                                  ..scale(
                                    effectiveFlipH ? -1.0 : 1.0,
                                    effectiveFlipV ? -1.0 : 1.0,
                                  ),
                                child: _buildCropOverlay(
                                  effectiveCrop,
                                  effectiveZoom,
                                  videoSize,
                                  controller!,
                                ),
                              ),

                              // Draggable/resizable text overlays
                              // Text overlays (synced to global currentPosition)
                              Builder(
                                builder: (context) {
                                  final currentTime = context.watch<VideoEditorProvider>().currentPosition;
                                  final provider = context.read<VideoEditorProvider>();

                                  return Stack(
                                    children: provider.textTracks
                                        .where((t) => currentTime >= t.startTime && currentTime <= t.endTime)
                                        .map((track) => DraggableResizableText(
                                      textTrack: track,
                                      videoSize: videoSize,
                                      onUpdate: provider.updateTextTrack,
                                    ))
                                        .toList(),
                                  );
                                },
                              ),

                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Loading overlay
                if (provider.isLoadingVideo ||
                    (provider.isPlaying && !isInitialized))
                  Container(
                    color: Colors.black.withOpacity(0.6),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),

                // Optional: Selection border
                if (provider.selectedVideoTrackId != null)
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCropOverlay(
    Rect crop,
    double zoom,
    Size videoSize,
    VideoPlayerController controller,
  ) {
    if (crop == const Rect.fromLTWH(0, 0, 1, 1) && zoom == 1.0) {
      return VideoPlayer(controller);
    }

    final cropPixels = Rect.fromLTWH(
      crop.left * videoSize.width,
      crop.top * videoSize.height,
      crop.width * videoSize.width / zoom,
      crop.height * videoSize.height / zoom,
    );

    final offsetX = -cropPixels.left + (videoSize.width - cropPixels.width) / 2;
    final offsetY =
        -cropPixels.top + (videoSize.height - cropPixels.height) / 2;

    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: VideoPlayer(controller),
    );
  }
}
