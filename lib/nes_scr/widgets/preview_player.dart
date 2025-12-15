import 'dart:math' as math;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../model/timeline_item.dart';
import '../servuices/clip_controller.dart';
import '../servuices/video_manager.dart';

class VideoPreview extends StatelessWidget {
  final VideoManager videoManager;
  final ClipController clipController;
  final Duration playheadPosition;

  const VideoPreview({
    super.key,
    required this.videoManager,
    required this.clipController,
    required this.playheadPosition,
  });

  @override
  Widget build(BuildContext context) {
    // Your existing full stack (video + overlays)
    Widget preview = SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: videoManager.aspectRatio ?? 16 / 9,
              child: _buildVideoContent(),
            ),
          ),
          ..._buildInteractiveOverlays(),
        ],
      ),
    );

    // === APPLY EFFECTS ===
    String? effect = clipController.currentEffect;

    if (effect == 'shake') {
      // Simple shake using animation based on time
      final bool shakeRight = (DateTime.now().millisecondsSinceEpoch ~/ 50) % 2 == 0;
      preview = Transform.translate(
        offset: Offset(shakeRight ? 8 : -8, 0),
        child: preview,
      );
    } else if (effect == 'glitch') {
      // Simple glitch using ColorFiltered + opacity flicker
      final bool flicker = (DateTime.now().millisecondsSinceEpoch ~/ 100) % 2 == 0;
      preview = Opacity(
        opacity: flicker ? 0.9 : 1.0,
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix([
            1.5, 0, 0, 0, 0,
            0, 1, 0, 0, 0,
            0, 0, 1, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: preview,
        ),
      );
    }
    // Add more effects here (zoom, flash, etc.)

    return preview;
  }

  Widget _buildVideoContent() {
    final controller = videoManager.activeController;
    final activeItem = videoManager.activeItem;

    final bool isSelected = activeItem != null &&
        clipController.selectedClipId == activeItem.id &&
        clipController.selectedClipType == TimelineItemType.video;

    Widget videoWidget;
    if (controller != null && controller.value.isInitialized && videoManager.isVideoFrameReady) {
      videoWidget = VideoPlayer(controller);
    } else if (activeItem?.thumbnailBytes?.isNotEmpty == true) {
      videoWidget = Image.memory(
        activeItem!.thumbnailBytes!.first,
        fit: BoxFit.contain,
      );
    } else {
      videoWidget = Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_file, size: 64, color: Colors.white38),
              SizedBox(height: 16),
              Text('Add video to start', style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      );
    }

    // === APPLY FILTER ===
    String currentFilter = clipController.currentFilter ?? 'none';
    Widget filteredVideo = videoWidget;

    switch (currentFilter) {
      case 'vintage':
        filteredVideo = ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.9, 0.2, 0.0, 0, 20,
            0.2, 0.8, 0.1, 0, 10,
            0.0, 0.1, 0.7, 0, 30,
            0,   0,   0,   1, 0,
          ]),
          child: videoWidget,
        );
        break;
      case 'cinematic':
        filteredVideo = ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.blue.withOpacity(0.1), BlendMode.hue),
          child: videoWidget,
        );
        break;
      case 'warm':
        filteredVideo = ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            1.2, 0,   0,   0, 20,
            0,   1.1, 0,   0, 10,
            0,   0,   1.0, 0, 0,
            0,   0,   0,   1, 0,
          ]),
          child: videoWidget,
        );
        break;
      case 'cool':
        filteredVideo = ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.9, 0,   0.2, 0, 0,
            0,   1.0, 0,   0, 0,
            0,   0.1, 1.1, 0, 10,
            0,   0,   0,   1, 0,
          ]),
          child: videoWidget,
        );
        break;
      case 'bw':
        filteredVideo = ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: videoWidget,
        );
        break;
      default:
        filteredVideo = videoWidget;
    }

    return Container(
      decoration: BoxDecoration(
        border: isSelected
            ? Border.all(color: const Color(0xFF00D9FF), width: 5)
            : null,
      ),
      child: ClipRRect(child: filteredVideo),
    );
  }

  List<Widget> _buildInteractiveOverlays() {
    final List<Widget> overlays = [];

    final List<TimelineItem> itemsToShow = [
      ...clipController.textClips,
      ...clipController.overlayClips,
       ...clipController.stickerClips, // Uncomment when you have stickers
    ]..sort((a, b) => a.layerIndex.compareTo(b.layerIndex));

    for (final item in itemsToShow) {
      final bool isInTimeRange = playheadPosition >= item.startTime &&
          playheadPosition < item.startTime + item.duration;

      if (!isInTimeRange) continue;

      overlays.add(_buildDraggableItem(item));
    }

    return overlays;
  }

  Widget _buildDraggableItem(TimelineItem item) {
    final bool isSelected = clipController.selectedClipId == item.id;

    Widget content;

    // Build content depending on type
    if (item.type == TimelineItemType.text) {
      TextStyle baseStyle = TextStyle(
        color: item.textColor ?? Colors.white,
        fontSize: (item.fontSize ?? 40.0) * (item.scale ?? 1.0),
        fontFamily: item.fontFamily ?? 'Roboto',
        shadows: item.shadowBlur != null && item.shadowBlur! > 0
            ? [
          Shadow(
            color: item.shadowColor ?? Colors.black,
            blurRadius: item.shadowBlur ?? 4.0,
            offset: const Offset(2, 2),
          )
        ]
            : null,
        foreground: item.strokeWidth != null && item.strokeWidth! > 0
            ? (Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = item.strokeWidth!
          ..color = item.strokeColor ?? Colors.black)
            : null,
      );

      switch (item.animation ?? 'none') {
        case 'typewriter':
          content = AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                item.text ?? '',
                textStyle: baseStyle,
                speed: const Duration(milliseconds: 100),
              )
            ],
            totalRepeatCount: 1,
          );
          break;
        case 'fade':
          content = AnimatedTextKit(
            animatedTexts: [FadeAnimatedText(item.text ?? '', textStyle: baseStyle)],
          );
          break;
        case 'wave':
          content = AnimatedTextKit(
            animatedTexts: [WavyAnimatedText(item.text ?? '', textStyle: baseStyle)],
          );
          break;
        default:
          content = Text(item.text ?? '', style: baseStyle);
      }
    } else {
      content = Image.file(
        item.file!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 100 * (item.scale ?? 1.0)),
      );
    }

    // Apply rotation
    if (item.rotation != null && item.rotation != 0) {
      content = Transform.rotate(
        angle: item.rotation! * math.pi / 180,
        child: content,
      );
    }

    return Positioned(
      left: item.x ?? 100.0,
      top: item.y ?? 200.0,
      child: GestureDetector(
        onTap: () => clipController.selectClip(item.id, item.type),
        onScaleUpdate: (details) {
          // Move
          item.x = (item.x ?? 100.0) + details.focalPointDelta.dx;
          item.y = (item.y ?? 200.0) + details.focalPointDelta.dy;

          // Scale
          item.scale = (item.scale ?? 1.0) * details.scale;

          // Rotate
          item.rotation = (item.rotation ?? 0.0) + (details.rotation * 180 / math.pi);

          clipController.updateClip(item);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: isSelected
              ? BoxDecoration(
            border: Border.all(color: const Color(0xFF00D9FF), width: 3),
            borderRadius: BorderRadius.circular(8),
          )
              : null,
          child: content,
        ),
      ),
    );
  }

}