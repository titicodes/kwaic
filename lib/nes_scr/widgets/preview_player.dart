import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kwaic/nes_scr/widgets/animation_sheet.dart';
import 'package:video_editor_2/domain/bloc/controller.dart';
import 'package:video_editor_2/ui/crop/crop_grid.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../model/timeline_item.dart';
import '../servuices/clip_controller.dart';
import '../servuices/video_manager.dart';

/// VideoPreview - Slave to timeline, displays current frame
/// Professional architecture: Always shows the frame at playheadPosition
class VideoPreview extends StatefulWidget {
  final VideoManager videoManager;
  final ClipController clipController;
  final Duration playheadPosition;
  final VideoEditorController? cropController;

  const VideoPreview({
    super.key,
    required this.videoManager,
    required this.clipController,
    required this.playheadPosition,
    this.cropController,
  });

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  Duration? _lastSyncedPosition;

  @override
  void initState() {
    super.initState();
    // Initial sync after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPreview();
    });
  }

  @override
  void didUpdateWidget(covariant VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Schedule sync after build completes when playhead changes
    if (oldWidget.playheadPosition != widget.playheadPosition) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncPreview();
      });
    }
  }

  void _syncPreview() {
    if (_lastSyncedPosition == widget.playheadPosition) return;
    _lastSyncedPosition = widget.playheadPosition;

    final isPlaying = widget.videoManager.activeController?.value.isPlaying ?? false;
    if (!isPlaying) {
      widget.videoManager.forceFrameAt(widget.playheadPosition);
    } else {
      widget.videoManager.syncToPlayhead(widget.playheadPosition);
    }
  }

  double get _aspectRatio {
    final item = widget.videoManager.activeItem;
    if (item != null) {
      final controller = widget.videoManager.getControllerForClip(item);
      if (controller != null && controller.value.isInitialized) {
        final size = controller.value.size;
        if (size.width > 0 && size.height > 0) {
          return size.width / size.height;
        }
      }
    }
    return 16 / 9;
  }


  @override
  Widget build(BuildContext context) {

    // Build full preview stack
    Widget preview = SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.clipController.backgroundVisual != null)
            _buildBackgroundVisual(),
          Center(
            child: AnimatedBuilder(
              animation: widget.videoManager,
              builder: (_, __) {
                return AspectRatio(
                  aspectRatio: _aspectRatio,
                  child: _buildVideoContent(),
                );
              },
            ),
          ),

          ..._buildInteractiveOverlays(),
        ],
      ),
    );
    // 🎯 Apply effects
    String? effect = widget.clipController.currentEffect;

    if (effect == 'shake') {
      final bool shakeRight =
          (DateTime.now().millisecondsSinceEpoch ~/ 50) % 2 == 0;
      preview = Transform.translate(
        offset: Offset(shakeRight ? 8 : -8, 0),
        child: preview,
      );
    } else if (effect == 'glitch') {
      final bool flicker =
          (DateTime.now().millisecondsSinceEpoch ~/ 100) % 2 == 0;
      preview = Opacity(
        opacity: flicker ? 0.9 : 1.0,
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix([
            1.5,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: preview,
        ),
      );
    }

    return preview;
  }

  Widget _buildVideoContent() {
    final clip = widget.videoManager.getActiveClip(widget.playheadPosition);
    if (clip == null) return Container(color: Colors.black);

    // Base video (always constrained)
    Widget baseVideo = _buildBaseVideo(clip);

    // Apply crop
    if (clip.cropRect != null) {
      baseVideo = ClipRect(
        clipper: _CropClipper(clip.cropRect!),
        child: baseVideo,
      );
    }

    // Apply rotation
    if (clip.rotation != null && clip.rotation! % 360 != 0) {
      baseVideo = RotatedBox(
        quarterTurns: (clip.rotation! ~/ 90) % 4,
        child: baseVideo,
      );
    }

    // Constrain the video to screen size
    final double videoWidth = MediaQuery.of(context).size.width;
    final double videoHeight = videoWidth / _aspectRatio;

    Widget constrainedVideo = SizedBox(
      width: videoWidth,
      height: videoHeight,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: videoWidth,
          height: videoHeight,
          child: baseVideo,
        ),
      ),
    );

    final bool isSelected = widget.clipController.selectedClipId == clip.id;

    if (!isSelected || clip.type != TimelineItemType.video) {
      return constrainedVideo; // Normal full-screen mode
    }

    // Selected: Show draggable/resizable overlay
    return Stack(
      children: [
        // Background (full screen, dimmed)
        Opacity(
          opacity: 0.3,
          child: constrainedVideo,
        ),
        // Draggable overlay
        Positioned(
          left: (clip.x ?? 50.0).clamp(0.0, videoWidth - 200),
          top: (clip.y ?? 100.0).clamp(0.0, videoHeight - 200),
          child: GestureDetector(
            onTap: () => widget.clipController.selectClip(clip.id, clip.type),
            onScaleUpdate: (details) {
              clip.x = (clip.x ?? 50.0) + details.focalPointDelta.dx;
              clip.y = (clip.y ?? 100.0) + details.focalPointDelta.dy; // ← Add vertical drag
              if (details.scale != 1.0) {
                clip.scale = (clip.scale ?? 1.0) * details.scale.clamp(0.3, 3.0);
              }
              clip.rotation = (clip.rotation ?? 0.0) + (details.rotation * 180 / math.pi);
              widget.clipController.updateClip(clip);
            },
            child: Transform(
              transform: Matrix4.identity()
                ..translate(clip.x ?? 50.0, clip.y ?? 100.0)
                ..scale(clip.scale ?? 1.0)
                ..rotateZ((clip.rotation ?? 0.0) * math.pi / 180),
              alignment: Alignment.center,
              child: Container(
                width: 300,
                height: 300 / _aspectRatio,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00D9FF), width: 4),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 300,
                      height: 300 / _aspectRatio,
                      child: baseVideo,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBaseVideo(TimelineItem clip) {
    final controller = widget.videoManager.getControllerForClip(clip);

    Widget videoWidget = (controller != null &&
        controller.value.isInitialized &&
        controller.value.size.width > 0)
        ? VideoPlayer(controller)
        : _buildThumbnailFallback(clip);  // ← We'll define this below

    // Apply crop
    if (clip.cropRect != null) {
      videoWidget = ClipRect(
        clipper: _CropClipper(clip.cropRect!),
        child: videoWidget,
      );
    }

    // Apply rotation
    if (clip.rotation != null && clip.rotation! % 360 != 0) {
      videoWidget = RotatedBox(
        quarterTurns: (clip.rotation! ~/ 90) % 4,
        child: videoWidget,
      );
    }

    return videoWidget;
  }

  List<Widget> _buildInteractiveOverlays() {
    final List<Widget> overlays = [];

    final List<TimelineItem> itemsToShow = [
      ...widget.clipController.textClips,
      ...widget.clipController.overlayClips,
      ...widget.clipController.stickerClips,
    ]..sort((a, b) => a.layerIndex.compareTo(b.layerIndex));

    for (final item in itemsToShow) {
      final bool isInTimeRange =
          widget.playheadPosition >= item.startTime &&
          widget.playheadPosition < item.startTime + item.duration;

      if (!isInTimeRange) continue;

      overlays.add(_buildDraggableItem(item));
    }

    return overlays;
  }

  Widget _buildDraggableItem(TimelineItem item) {
    final bool isSelected = widget.clipController.selectedClipId == item.id;

    Widget content;

    if (item.type == TimelineItemType.text) {
      TextStyle baseStyle = TextStyle(
        color: item.textColor ?? Colors.white,
        fontSize: (item.fontSize ?? 40.0) * (item.scale ?? 1.0),
        fontFamily: item.fontFamily ?? 'Roboto',
        shadows:
            item.shadowBlur != null && item.shadowBlur! > 0
                ? [
                  Shadow(
                    color: item.shadowColor ?? Colors.black,
                    blurRadius: item.shadowBlur ?? 4.0,
                    offset: const Offset(2, 2),
                  ),
                ]
                : null,
        foreground:
            item.strokeWidth != null && item.strokeWidth! > 0
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
              ),
            ],
            totalRepeatCount: 1,
          );
          break;
        case 'fade':
          content = AnimatedTextKit(
            animatedTexts: [
              FadeAnimatedText(item.text ?? '', textStyle: baseStyle),
            ],
          );
          break;
        case 'wave':
          content = AnimatedTextKit(
            animatedTexts: [
              WavyAnimatedText(item.text ?? '', textStyle: baseStyle),
            ],
          );
          break;
        default:
          content = Text(item.text ?? '', style: baseStyle);
      }
    } else {
      // IMAGE OVERLAY
      content = Image.file(
        item.file!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
      );
    }

    // Apply scale (for both text and image)
    if (item.scale != null && item.scale != 1.0) {
      content = Transform.scale(scale: item.scale!, child: content);
    }

    // Apply rotation (for both text and image)
    if (item.rotation != null && item.rotation != 0) {
      content = Transform.rotate(
        angle: item.rotation! * math.pi / 180,
        child: content,
      );
    }

    if (item.animation != null && item.animation != 'none') {
      content = content.animate().applyEffect(item.animation!, 800.ms);
    }

    // Final wrapper — only ONE return
    return Positioned(
      left: item.x ?? 100.0,
      top: item.y ?? 200.0,
      child: GestureDetector(
        onTap: () => widget.clipController.selectClip(item.id, item.type),
        onScaleUpdate: (details) {
          // Move
          item.x = (item.x ?? 100.0) + details.focalPointDelta.dx;
          item.y = (item.y ?? 200.0) + details.focalPointDelta.dy;

          // Scale
          if (details.scale != 1.0) {
            item.scale = (item.scale ?? 1.0) * details.scale;
          }

          // Rotate
          item.rotation =
              (item.rotation ?? 0.0) + (details.rotation * 180 / math.pi);

          widget.clipController.updateClip(item);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration:
              isSelected
                  ? BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF00D9FF),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  )
                  : null,
          child: content,
        ),
      ),
    );
  }

  Widget _buildBackgroundVisual() {
    final bg = widget.clipController.backgroundVisual!;
    if (bg.backgroundColor != null) {
      return Container(color: bg.backgroundColor);
    }
    if (bg.blurSigma != null && bg.blurSigma! > 0) {
      return BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: bg.blurSigma!,
          sigmaY: bg.blurSigma!,
        ),
        child: Container(
          color: Colors.black.withOpacity(0.3),

        ),
      );
    }
    if (bg.file != null) {
      if (bg.file!.path.endsWith('.mp4') || bg.file!.path.endsWith('.mov')) {
        final controller = widget.videoManager.backgroundVideoController;
        if (controller != null && controller.value.isInitialized) {
          return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          );
        }
      } else {
        return Image.file(bg.file!, fit: BoxFit.cover);
      }
    }
    return Container(color: Colors.black);
  }


  Widget _buildThumbnailFallback(TimelineItem clip) {
    if (clip.thumbnailBytes?.isNotEmpty != true) {
      return Container(color: Colors.black);
    }

    final localTime = (widget.playheadPosition - clip.startTime)
        .clamp(Duration.zero, clip.duration);

    // Map current playhead to source video time
    final sourceTimeMs = clip.trimStart.inMilliseconds +
        (localTime.inMilliseconds * clip.speed);

    final sourceProgress = sourceTimeMs / clip.originalDuration.inMilliseconds;
    final index = (sourceProgress * clip.thumbnailBytes!.length)
        .floor()
        .clamp(0, clip.thumbnailBytes!.length - 1);

    return Image.memory(
      clip.thumbnailBytes![index],
      fit: BoxFit.cover,
      gaplessPlayback: true,
    );
  }

}


// Custom clipper for normalized crop
class _CropClipper extends CustomClipper<Rect> {
  final Rect crop;
  _CropClipper(this.crop);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(
      crop.left * size.width,
      crop.top * size.height,
      crop.width * size.width,
      crop.height * size.height,
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => true;
}