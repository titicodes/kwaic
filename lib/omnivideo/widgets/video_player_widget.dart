// widgets/video_player_widget.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../model/video_track.dart';
import '../model/text_track.dart';
import '../provider/video_editor_provider.dart';
import 'draggable_resizable_text.dart';

class VideoPlayerWidget extends StatelessWidget {
  const VideoPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoEditorProvider>(
      builder: (context, provider, _) {
        final VideoPlayerController? controller = provider.videoController;
        final bool isInitialized = controller != null && controller.value.isInitialized;
        final Size videoSize = isInitialized ? controller.value.size : const Size(720, 1280);

        // Find currently playing video track
        VideoTrack? activeTrack;
        for (final track in provider.videoTracks) {
          if (provider.currentPosition >= track.startTime &&
              provider.currentPosition < track.endTime) {
            activeTrack = track;
            break;
          }
        }
        activeTrack ??= provider.videoTracks.firstOrNull;

        if (activeTrack == null || !isInitialized) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                "No video clips",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ),
          );
        }

        // Apply live preview transforms (rotate/flip/fill) if tool is open
        final double rotation = provider.currentTool == 'rotate'
            ? activeTrack.rotation + provider.rotation
            : activeTrack.rotation;

        final bool flipH = provider.currentTool == 'flip'
            ? provider.flipHorizontal
            : activeTrack.flipHorizontal;

        final bool flipV = provider.currentTool == 'flip'
            ? provider.flipVertical
            : activeTrack.flipVertical;

        final Rect cropRect = provider.currentTool == 'fill'
            ? provider.previewCropRect
            : activeTrack.cropRect;

        final double cropZoom = provider.currentTool == 'fill'
            ? provider.previewCropZoom
            : activeTrack.cropZoom;

        return Container(
          color: Colors.black,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background thumbnail (blurred or static)
                    if (activeTrack.thumbnail != null)
                      Image.memory(
                        activeTrack.thumbnail!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),

                    // Video with transforms
                    FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: videoSize.width,
                        height: videoSize.height,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..rotateZ(rotation * 3.14159 / 180)
                            ..scale(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0),
                          child: _buildCroppedVideo(controller, cropRect, cropZoom, videoSize),
                        ),
                      ),
                    ),

                    // Text Overlays — Rebuild only when time changes
                    Selector<VideoEditorProvider, Duration>(
                      selector: (_, p) => p.currentPosition,
                      builder: (_, currentTime, __) {
                        return Stack(
                          children: provider.textTracks.where((text) {
                            return currentTime >= text.startTime &&
                                currentTime < text.startTime + text.duration;
                          }).map((textTrack) {
                            return DraggableResizableText(
                              key: ValueKey(textTrack.id),
                              textTrack: textTrack,
                              videoSize: videoSize,
                              isSelected: provider.selectedTextTrack?.id == textTrack.id,
                              onUpdate: (updated) {
                                provider.updateTextTrack(updated);
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),

                    // Loading indicator
                    if (provider.isLoadingVideo)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),

                    // Selection border (optional visual feedback)
                    if (provider.selectedVideoTrackId == activeTrack.id)
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFB700FF), width: 3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCroppedVideo(
      VideoPlayerController controller,
      Rect normalizedCrop,
      double zoom,
      Size videoSize,
      ) {
    if (normalizedCrop == const Rect.fromLTWH(0, 0, 1, 1) && zoom == 1.0) {
      return VideoPlayer(controller);
    }

    final cropPixels = Rect.fromLTWH(
      normalizedCrop.left * videoSize.width,
      normalizedCrop.top * videoSize.height,
      normalizedCrop.width * videoSize.width / zoom,
      normalizedCrop.height * videoSize.height / zoom,
    );

    final offsetX = (videoSize.width - cropPixels.width) / 2 - cropPixels.left;
    final offsetY = (videoSize.height - cropPixels.height) / 2 - cropPixels.top;

    return OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: Transform.translate(
        offset: Offset(offsetX, offsetY),
        child: VideoPlayer(controller),
      ),
    );
  }
}