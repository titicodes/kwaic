import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../provider/video_editor_provider.dart';

class VideoPlayerWidget extends StatelessWidget {
  final VideoPlayerController controller;

  const VideoPlayerWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();
    final currentTrack = provider.videoTracks[provider.selectedTrackIndex];
    final bool isInitialized = controller.value.isInitialized;
    final isSelectedClip = provider.selectedVideoTrackId != null;

    // Use preview values if we're in rotate/flip/fill tool, otherwise use saved track values
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

    return Stack(
      fit: StackFit.expand,
      children: [
        if (currentTrack.thumbnail != null)
          Image.memory(
            currentTrack.thumbnail!,
            fit: BoxFit.cover,
          ),

        if (isInitialized)
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateZ(effectiveRotation * 3.14159 / 180)
                      ..scale(effectiveFlipH ? -1.0 : 1.0, effectiveFlipV ? -1.0 : 1.0),
                    child: _buildCropOverlay(effectiveCrop, effectiveZoom, controller.value.size),
                  ),
                ),
              ),
            ),
          ),
        // After video layer
// Text overlays
        ...provider.textTracks.map((text) {
          final currentTime = provider.currentPosition;
          if (currentTime < text.startTime || currentTime > text.startTime + text.duration) {
            return const SizedBox.shrink();
          }

          final videoSize = controller.value.size;
          final double centerX = text.position.dx * videoSize.width;
          final double centerY = text.position.dy * videoSize.height;

          return Positioned(
            left: centerX - 150, // rough centering (adjust based on text length)
            top: centerY - 50,
            child: Transform.rotate(
              angle: text.rotation,
              child: Text(
                text.text,
                style: TextStyle(
                  color: text.color,
                  fontSize: text.fontSize,
                  fontFamily: text.fontFamily,
                  shadows: const [
                    Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4),
                  ],
                ),
                textAlign: text.alignment,
              ),
            ),
          );
        }).toList(),
        if (!isInitialized || provider.isLoadingVideo)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  SizedBox(height: 16),
                  Text("Loading video...", style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ),

        if (isSelectedClip)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00D9FF), width: 4),
              ),
            ),
          ),
      ],
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