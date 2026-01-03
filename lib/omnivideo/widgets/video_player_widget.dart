
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../provider/video_editor_provider.dart';
import 'draggable_resizable_text.dart';

class VideoPlayerWidget extends StatelessWidget {
  final VideoPlayerController controller;
  const VideoPlayerWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // final provider = context.watch<VideoEditorProvider>();
    final provider = context.read<VideoEditorProvider>();

    final currentTrack = provider.videoTracks[provider.selectedTrackIndex];
    final bool isInitialized = controller.value.isInitialized;
    final isSelectedClip = provider.selectedVideoTrackId != null;
    // Effective values (preview during edit, saved otherwise)
    final double effectiveRotation = provider.currentTool == 'rotate'
        ? currentTrack.rotation + provider.rotation
        : currentTrack.rotation;
    final bool effectiveFlipH = provider.currentTool == 'flip'
        ? provider.flipHorizontal
        : currentTrack.flipHorizontal;
    final bool effectiveFlipV = provider.currentTool == 'flip'
        ? provider.flipVertical
        : currentTrack.flipVertical;
    final Rect effectiveCrop = provider.currentTool == 'fill'
        ? provider.previewCropRect
        : currentTrack.cropRect;
    final double effectiveZoom = provider.currentTool == 'fill'
        ? provider.previewCropZoom
        : currentTrack.cropZoom;
    final Size videoSize = isInitialized ? controller.value.size : Size.zero;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16), // Perfect spacing like screenshot
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Thumbnail background (shows instantly)
            if (currentTrack.thumbnail != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  currentTrack.thumbnail!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            // Video player — letterboxed, rounded, centered
            if (isInitialized)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: FittedBox(
                    fit: BoxFit.contain, // Letterbox, no crop
                    child: SizedBox(
                      width: videoSize.width,
                      height: videoSize.height,
                      child:Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translate(
                            currentTrack.position.dx * videoSize.width / 2,
                            currentTrack.position.dy * videoSize.height / 2,
                          )
                          ..scale(currentTrack.scale)
                          ..rotateZ(effectiveRotation * 3.14159 / 180)
                          ..scale(
                            effectiveFlipH ? -1.0 : 1.0,
                            effectiveFlipV ? -1.0 : 1.0,
                          ),
                        child: _buildCropOverlay(effectiveCrop, effectiveZoom, videoSize),
                      ),

                    ),
                  ),
                ),
              ),
            // Text overlays
            // Text overlays (CapCut-style timeline synced)
            Selector<VideoEditorProvider, Duration>(
              selector: (_, p) => p.currentPosition,
              builder: (_, currentTime, __) {
                if (videoSize == Size.zero) return const SizedBox.shrink();

                return Stack(
                  children: provider.textTracks.map((textTrack) {
                    if (currentTime < textTrack.startTime ||
                        currentTime > textTrack.startTime + textTrack.duration) {
                      return const SizedBox.shrink();
                    }

                    return DraggableResizableText(
                      textTrack: textTrack,
                      videoSize: videoSize,
                      onUpdate: provider.updateTextTrack,
                    );
                  }).toList(),
                );
              },
            ),

            // Loading overlay
            if (!isInitialized || provider.isLoadingVideo)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      SizedBox(height: 16),
                      Text(
                        "Loading video...",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            // Selection border
            if (isSelectedClip)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropOverlay(Rect crop, double zoom, Size videoSize) {
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
    final offsetY = -cropPixels.top + (videoSize.height - cropPixels.height) / 2;
    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: VideoPlayer(controller),
    );
  }
}