import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kwaic/nes_scr/widgets/wave_form_painter.dart';
import '../model/timeline_item.dart';
import '../servuices/clip_controller.dart';
import '../servuices/time_line_controller.dart';
import '../servuices/video_manager.dart';
import 'add_clip_tile.dart';

class TimelineView extends StatefulWidget {
  final TimelineController controller;
  final ClipController clipController;
  final VideoManager videoManager;
  final Duration playheadPosition;
  final bool isPlaying;
  final Function(Offset) onTimelineTap;
  final Function(String, TimelineItemType) onClipSelected;

  const TimelineView({
    super.key,
    required this.controller,
    required this.clipController,
    required this.videoManager,
    required this.playheadPosition,
    required this.isPlaying,
    required this.onTimelineTap,
    required this.onClipSelected,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  String? _trimmingClipId;
  bool _trimAtStart = false;
  Offset? _dragStartOffset;
  double _lastDx = 0;

  // 🔹 CapCut snap state
  static const double SNAP_PX = 8.0;
  static const Duration FRAME = Duration(milliseconds: 33);

  bool _isSnapping = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    try {
      widget.clipController.addListener(_onClipControllerChanged);
    } catch (_) {}
  }

  void _onControllerChanged() => setState(() {});
  void _onClipControllerChanged() => setState(() {});

  @override
  void didUpdateWidget(covariant TimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying) {
      // Force scroll every frame — no conditions
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.controller.scrollController.hasClients) return;

        widget.controller.scrollToTime(
          widget.playheadPosition,
          MediaQuery.of(context).size.width,
          animate: true,
        );
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    try {
      widget.clipController.removeListener(_onClipControllerChanged);
    } catch (_) {}
    super.dispose();
  }

  // =======================
// SNAP UTILITIES
// =======================

  Duration _snapTime(
      Duration raw,
      List<Duration> snapPoints,
      double pixelsPerSecond,
      ) {
    final snapPx = _lastDx > 12 ? 3.0 : SNAP_PX;

    for (final p in snapPoints) {
      final dx =
          (raw.inMilliseconds - p.inMilliseconds).abs() /
              1000 *
              pixelsPerSecond;

      if (dx <= snapPx) {
        _isSnapping = true;
        return p;
      }
    }

    _isSnapping = false;
    return raw;
  }

  List<Duration> _collectSnapPoints(TimelineItem clip) {
    final points = <Duration>[
      widget.controller.currentTime, // playhead
    ];

    for (final c in widget.clipController.videoClips) {
      if (c.id == clip.id) continue;
      points.add(c.startTime);
      points.add(c.startTime + c.duration);
    }

    return points;
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;
    final isTablet = screenWidth > 700;
    final timelineHeight = isTablet ? 300.0 : 260.0;

    return SizedBox(
      height: timelineHeight,
      child: Container(
        color: Colors.black,
        child: GestureDetector(
          onTapDown: (details) => widget.onTimelineTap(details.localPosition),
          onHorizontalDragUpdate:
              (details) => _handleHorizontalDrag(details.delta.dx),
          onScaleUpdate: (details) {
            if (details.scale != 1.0) _handleZoom(details.scale, screenWidth);
          },
          child: ClipRect(
            // ← This fixes overflow pixels
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: widget.controller.scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: screenWidth,
                      maxWidth: math.max(
                        (widget.controller.totalDuration.inMilliseconds /
                                1000.0) *
                            widget.controller.pixelsPerSecond,
                        screenWidth,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDurationRuler(screenWidth, centerX),
                          const SizedBox(height: 8),
                          if (_shouldShowVideoTrack())
                            _buildVideoTrack(centerX),
                          if (_shouldShowVideoTrack())
                            const SizedBox(height: 4),
                          if (_shouldShowAudioTrack())
                            _buildAudioTrack(centerX),
                          if (_shouldShowAudioTrack())
                            const SizedBox(height: 4),
                          if (_shouldShowTextTrack()) _buildTextTrack(centerX),
                          if (_shouldShowTextTrack()) const SizedBox(height: 4),
                          if (_shouldShowOverlayTrack())
                            _buildOverlayTrack(centerX),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildCenteredPlayhead(screenWidth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationRuler(double screenWidth, double centerX) {
    final totalDuration = widget.controller.totalDuration;
    final totalSeconds = totalDuration.inMilliseconds / 1000.0;
    final pixelsPerSecond = widget.controller.pixelsPerSecond;
    final timelineOffset = widget.controller.timelineOffset;

    if (totalSeconds <= 0) return const SizedBox(height: 40);

    final List<Widget> labels = [];

    // Show time label every 5 seconds (adjust based on zoom)
    double interval = 5.0;
    if (pixelsPerSecond < 50)
      interval = 10.0; // Zoomed out
    else if (pixelsPerSecond > 200)
      interval = 2.0; // Zoomed in
    else if (pixelsPerSecond > 400)
      interval = 1.0;

    // Generate labels
    for (double t = 0; t <= totalSeconds; t += interval) {
      final double x = centerX + t * pixelsPerSecond - timelineOffset;

      if (x < -100 || x > screenWidth + 100) continue;

      labels.add(
        Positioned(
          left: x - 40,
          top: 8,
          child: Text(
            _formatTime(Duration(milliseconds: (t * 1000).round())),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Final label at exact end (bold)
    final double endX =
        centerX + totalSeconds * pixelsPerSecond - timelineOffset;
    labels.add(
      Positioned(
        left: endX - 60,
        top: 8,
        child: Text(
          _formatTime(totalDuration),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    return SizedBox(height: 40, child: Stack(children: labels));
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final millis = (duration.inMilliseconds % 1000) ~/ 10; // Show centiseconds

    return '$minutes:${seconds.toString().padLeft(2, '0')}.'
        '${millis.toString().padLeft(2, '0')}';
  }

  void _handleHorizontalDrag(double deltaPx) {
    if (widget.isPlaying) {
      widget.videoManager.pause();
    }

    final sc = widget.controller.scrollController;
    if (sc.hasClients) {
      final newOffset = sc.offset - deltaPx;
      sc.jumpTo(newOffset.clamp(0.0, sc.position.maxScrollExtent));

      final screenWidth = MediaQuery.of(context).size.width;
      final newPlayheadSec =
          (newOffset + screenWidth / 2) / widget.controller.pixelsPerSecond;
      final newPlayhead = Duration(
        milliseconds: (newPlayheadSec * 1000).round(),
      );

      // CRITICAL: Force exact frame update on every drag movement
      widget.videoManager.beginScrub(); // Prevent feedback loop
      widget.videoManager.forceFrameAt(newPlayhead);
      widget.controller.currentTime = newPlayhead;
      widget.videoManager
          .endScrub(); // Optional: end after small delay if needed
    }
  }

  void _handleZoom(double scale, double screenWidth) {
    final oldPps = widget.controller.pixelsPerSecond;
    widget.controller.handleZoom(scale);
    if (widget.controller.scrollController.hasClients) {
      final centerSec =
          (widget.controller.timelineOffset + screenWidth / 2) / oldPps;
      final newOffset =
          centerSec * widget.controller.pixelsPerSecond - screenWidth / 2;
      final maxOffset =
          widget.controller.scrollController.position.maxScrollExtent;
      final targetOffset = newOffset.clamp(0.0, maxOffset);
      widget.controller.scrollController.jumpTo(targetOffset);
    }
  }

  bool _shouldShowVideoTrack() => widget.controller.shouldShowVideoTrack();
  bool _shouldShowAudioTrack() => widget.controller.shouldShowAudioTrack();
  bool _shouldShowTextTrack() => widget.controller.shouldShowTextTrack();
  bool _shouldShowOverlayTrack() => widget.controller.shouldShowOverlayTrack();

  Widget _buildVideoTrack(double centerX) {
    final clips = widget.clipController.videoClips;

    // Calculate the total width needed for all clips + add button space
    final Duration totalClipsDuration = clips.fold(Duration.zero, (prev, clip) => prev + clip.duration);
    final double clipsWidth = (totalClipsDuration.inMilliseconds / 1000.0) * widget.controller.pixelsPerSecond;

    return Container(
      height: 60,
      color: const Color(0xFF0A0A0A),
      child: Stack(
        children: [
          // Video clips
          ...clips.map((clip) => _buildVideoClipWithTrim(clip, centerX)).toList(),

          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => debugPrint('Add clip'),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00D9FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 32),
                ),
              ),
            ),
          ),
          // Optional: Left side buttons (Mute, Cover, etc.)
          if (clips.isNotEmpty)
            Positioned(
              left: centerX - widget.controller.timelineOffset - 140,
              top: 8,
              child: Row(
                children: [
                  _sideButton(Icons.volume_up, 'Sound\nOn', () {}),
                  const SizedBox(width: 8),
                  _buildCoverPreview(centerX),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoClipWithTrim(TimelineItem item, double centerX) {
    final isSelected = widget.clipController.selectedClipId == item.id;
    final isTrimming =
        _trimmingClipId == item.id ||
        (widget.controller.isTrimMode &&
            widget.controller.trimClipId == item.id);

    final startX =
        (item.startTime.inMilliseconds / 1000.0) *
            widget.controller.pixelsPerSecond -
        widget.controller.timelineOffset;

    final width = math.max(
      (item.duration.inMilliseconds / 1000.0) *
          widget.controller.pixelsPerSecond /
          item.speed,
      60.0,
    );

    return Positioned(
      left: startX + centerX - 12,
      child: SizedBox(
        width: width + 24,
        height: 60,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 12,
              child: Container(
                width: width,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isTrimming
                            ? Colors.orange
                            : (isSelected
                                ? const Color(0xFF00D9FF)
                                : Colors.transparent),
                    width: isTrimming ? 4 : (isSelected ? 3 : 0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildThumbnailStrip(item, width),
                ),
              ),
            ),

            if (isSelected || isTrimming)
              Positioned(
                left: 0,
                top: 6,
                bottom: 6,
                child: GestureDetector(
                  onHorizontalDragUpdate:
                      (d) => _handleTrimDrag(item, d.delta.dx, true),
                  onHorizontalDragEnd: (_) => _finishTrim(),
                  child: Container(
                    width: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(10),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 44,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),

            if (isSelected || isTrimming)
              Positioned(
                right: 0,
                top: 6,
                bottom: 6,
                child: GestureDetector(
                  onHorizontalDragUpdate:
                      (d) => _handleTrimDrag(item, d.delta.dx, false),
                  onHorizontalDragEnd: (_) => _finishTrim(),
                  child: Container(
                    width: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(10),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 44,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget.clipController.selectClip(item.id, item.type);
                widget.onClipSelected(item.id, item.type);

                widget.videoManager.forceFrameAt(widget.playheadPosition);
              },

              onDoubleTap: () {
                // Split on double-tap (CapCut style)
                final playheadSec = widget.playheadPosition.inMilliseconds / 1000.0;
                final clipStart = item.startTime.inMilliseconds / 1000.0;
                final clipEnd = clipStart + (item.duration.inMilliseconds / 1000.0 / item.speed);
                if (playheadSec > clipStart && playheadSec < clipEnd) {
                  widget.clipController.splitClip(item, widget.playheadPosition);
                }
              },
              onHorizontalDragStart: (_) {
                widget.videoManager.beginScrub();
              },
              onHorizontalDragUpdate: (d) {
                final deltaSec = d.delta.dx / widget.controller.pixelsPerSecond;
                final newStart =
                    item.startTime +
                    Duration(milliseconds: (deltaSec * 1000).round());

                if (newStart >= Duration.zero) {
                  item.startTime = newStart;
                  widget.clipController.updateClip(item);

                  // 🔑 Scrub preview only (NO seek)
                  final activeVideo = widget.clipController.getActiveVideoClip(
                    widget.controller.currentTime,
                  );

                  if (activeVideo != null) {
                    widget.videoManager.forceFrameAt(
                      widget.controller.currentTime,
                    );
                  }
                }
              },
              onHorizontalDragEnd: (_) {
                widget.videoManager.endScrub();
              },

              child: Container(
                width: width + 24,
                height: 60,
                color: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finishTrim() {
    _trimmingClipId = null;
    widget.controller.exitTrimMode();

    widget.videoManager.endScrub();
    widget.videoManager.forceFrameAt(widget.controller.currentTime);

    setState(() {});
  }

  void _handleTrimDrag(
      TimelineItem clip,
      double deltaPx,
      bool draggingStartHandle,
      ) {
    widget.videoManager.beginScrub();

    final pps = widget.controller.pixelsPerSecond;
    Duration delta =
    Duration(milliseconds: ((deltaPx / pps) * 1000).round());

    // 🔒 Frame lock
    delta = Duration(
      milliseconds:
      (delta.inMilliseconds ~/ FRAME.inMilliseconds) *
          FRAME.inMilliseconds,
    );

    final snapPoints = _collectSnapPoints(clip);

    setState(() {
      if (draggingStartHandle) {
        final rawTrim = clip.trimStart + delta;

        final snappedTrim =
        _snapTime(rawTrim, snapPoints, pps)
            .clamp(Duration.zero, clip.originalDuration);

        final diff = snappedTrim - clip.trimStart;

        clip.trimStart = snappedTrim;
        clip.startTime += diff;
        clip.duration -= diff;
      } else {
        final rawDuration = clip.duration + delta;

        final snapped =
            _snapTime(
              clip.startTime + rawDuration,
              snapPoints,
              pps,
            ) -
                clip.startTime;

        clip.duration = snapped.clamp(
          const Duration(milliseconds: 100),
          clip.originalDuration - clip.trimStart,
        );
      }

      widget.clipController.updateClip(clip);
    });

    widget.videoManager.forceFrameAt(widget.playheadPosition);
  }

  Widget _buildAudioClip(TimelineItem item, double centerX) {
    final startX =
        item.startTime.inMilliseconds /
            1000.0 *
            widget.controller.pixelsPerSecond -
        widget.controller.timelineOffset;
    final width = _clipWidth(item);

    if (item.waveformData == null) {
      return _buildSecondaryClip(
        item: item,
        centerX: centerX,
        color: const Color(0xFF10B981),
        child: const Text(
          'Loading waveform...',
          style: TextStyle(color: Colors.white70, fontSize: 8),
        ),
      );
    }

    return Positioned(
      left: startX + centerX,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // ← Critical for drag
        onTap: () {
          widget.clipController.selectClip(item.id, item.type);
          widget.onClipSelected(item.id, item.type);
        },
        onLongPress: () => _showClipOptions(item),
        onHorizontalDragUpdate: (d) {
          final deltaSec = d.delta.dx / widget.controller.pixelsPerSecond;
          final newStart =
              item.startTime +
              Duration(milliseconds: (deltaSec * 1000).round());
          if (newStart >= Duration.zero) {
            setState(() {
              item.startTime = newStart;
              widget.clipController.updateClip(item);
            });
          }
        },
        child: Container(
          width: width,
          height: 46,
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color:
                  widget.clipController.selectedClipId == item.id
                      ? const Color(0xFF00D9FF)
                      : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CustomPaint(
              painter: AudioWaveformPainter(
                waveform: item.waveformData!,
                color: const Color(0xFF10B981),
              ),
              size: Size(width, 46),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextClip(TimelineItem item, double centerX) {
    final startX =
        item.startTime.inMilliseconds /
            1000.0 *
            widget.controller.pixelsPerSecond -
        widget.controller.timelineOffset;
    final width = _clipWidth(item);

    return Positioned(
      left: startX + centerX,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.clipController.selectClip(item.id, item.type);
          widget.onClipSelected(item.id, item.type);
        },
        onHorizontalDragStart: (_) {
          widget.videoManager.beginScrub();
        },
        onHorizontalDragUpdate: (d) {
          final deltaSec = d.delta.dx / widget.controller.pixelsPerSecond;
          final newStart =
              item.startTime +
              Duration(milliseconds: (deltaSec * 1000).round());

          if (newStart >= Duration.zero) {
            item.startTime = newStart;
            widget.clipController.updateClip(item);

            final activeVideo = widget.clipController.getActiveVideoClip(
              widget.controller.currentTime,
            );

            if (activeVideo != null) {
              widget.videoManager.forceFrameAt(widget.controller.currentTime);
            }
          }
        },
        onHorizontalDragEnd: (_) {
          widget.videoManager.endScrub();
        },

        child: Container(
          width: width,
          height: 46,
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          decoration: BoxDecoration(
            color: Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color:
                  widget.clipController.selectedClipId == item.id
                      ? const Color(0xFF00D9FF)
                      : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              item.text ?? 'Text',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayClip(TimelineItem item, double centerX) {
    final startX =
        item.startTime.inMilliseconds /
            1000.0 *
            widget.controller.pixelsPerSecond -
        widget.controller.timelineOffset;
    final width = _clipWidth(item);

    return Positioned(
      left: startX + centerX,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.clipController.selectClip(item.id, item.type);
          widget.onClipSelected(item.id, item.type);
        },
        onHorizontalDragStart: (_) {
          widget.videoManager.beginScrub();
        },
        onHorizontalDragUpdate: (d) {
          final deltaSec = d.delta.dx / widget.controller.pixelsPerSecond;
          final newStart =
              item.startTime +
              Duration(milliseconds: (deltaSec * 1000).round());

          if (newStart >= Duration.zero) {
            item.startTime = newStart;
            widget.clipController.updateClip(item);

            final activeVideo = widget.clipController.getActiveVideoClip(
              widget.controller.currentTime,
            );

            if (activeVideo != null) {
              widget.videoManager.forceFrameAt(widget.controller.currentTime);
            }
          }
        },
        onHorizontalDragEnd: (_) {
          widget.videoManager.endScrub();
        },

        child: Container(
          width: width,
          height: 46,
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF9333EA),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color:
                  widget.clipController.selectedClipId == item.id
                      ? const Color(0xFF00D9FF)
                      : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child:
                item.file != null
                    ? Image.file(
                      item.file!,
                      fit: BoxFit.cover,
                      width: width,
                      height: 46,
                    )
                    : const Icon(Icons.image, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryClip({
    required TimelineItem item,
    required double centerX,
    required Color color,
    required Widget child,
  })
  {
    final isSelected = widget.clipController.selectedClipId == item.id;
    final startX =
        item.startTime.inMilliseconds /
            1000 *
            widget.controller.pixelsPerSecond -
        widget.controller.timelineOffset;
    final width = _clipWidth(item);

    return Positioned(
      left: startX + centerX,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // ← This fixes drag
        onTap: () {
          widget.clipController.selectClip(item.id, item.type);
          widget.onClipSelected(item.id, item.type);
        },
        onLongPress: () => _showClipOptions(item),
        onHorizontalDragStart: (_) {
          widget.videoManager.beginScrub();
        },
        onHorizontalDragUpdate: (d) {
          final deltaSec = d.delta.dx / widget.controller.pixelsPerSecond;
          final newStart =
              item.startTime +
              Duration(milliseconds: (deltaSec * 1000).round());

          if (newStart >= Duration.zero) {
            item.startTime = newStart;
            widget.clipController.updateClip(item);

            final activeVideo = widget.clipController.getActiveVideoClip(
              widget.controller.currentTime,
            );

            if (activeVideo != null) {
              widget.videoManager.forceFrameAt(widget.controller.currentTime);
            }
          }
        },
        onHorizontalDragEnd: (_) {
          widget.videoManager.endScrub();
        },

        child: Container(
          width: width,
          height: 46,
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? const Color(0xFF00D9FF) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  void _showClipOptions(TimelineItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder:
          (_) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Clip Options',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.content_cut,
                    color: Color(0xFF00D9FF),
                  ),
                  title: const Text(
                    'Split',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.clipController.splitClip(
                      item,
                      widget.playheadPosition,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.clipController.deleteClip(item.id, item.type);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _sideButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPreview(double centerX) {
    final activeClip = widget.clipController.getActiveVideoClip(
      widget.playheadPosition,
    );
    Uint8List? coverBytes;

    if (activeClip != null &&
        activeClip.thumbnailBytes != null &&
        activeClip.thumbnailBytes!.isNotEmpty) {
      final progress =
          (widget.playheadPosition - activeClip.startTime).inMilliseconds /
          activeClip.duration.inMilliseconds;
      final index = (progress * activeClip.thumbnailBytes!.length)
          .floor()
          .clamp(0, activeClip.thumbnailBytes!.length - 1);
      coverBytes = activeClip.thumbnailBytes![index];
    }

    return GestureDetector(
      onTap: () => debugPrint('Cover selector'),
      child: Container(
        width: 50,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (coverBytes != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Image.memory(
                  coverBytes,
                  width: 50,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 50,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: const Icon(Icons.photo, size: 18, color: Colors.white),
              ),
            const SizedBox(height: 2),
            const Text(
              'Cover',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  // In TimelineView.dart
  Widget _buildThumbnailStrip(TimelineItem item, double clipWidth) {
    final thumbs = item.thumbnailBytes;
    if (thumbs == null || thumbs.isEmpty) {
      return Container(color: const Color(0xFF2A2A2A));
    }

    const double thumbWidth = 90.0;

    final int count = thumbs.length;
    final double usedWidth = thumbWidth * (count - 1);
    final double lastThumbWidth =
    (clipWidth - usedWidth).clamp(thumbWidth * 0.5, thumbWidth * 2);

    return SizedBox(
      width: clipWidth,
      height: 60,
      child: Row(
        children: [
          for (int i = 0; i < count; i++)
            SizedBox(
              width: i == count - 1 ? lastThumbWidth : thumbWidth,
              height: 60,
              child: Image.memory(
                thumbs[i],
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioTrack(double centerX) => _buildSecondaryTrack(
    centerX,
    widget.clipController.audioClips,
    _buildAudioClip,
    Icons.audiotrack,
    () => debugPrint("Add Audio"),
    "Add Audio",
  );

  Widget _buildTextTrack(double centerX) => _buildSecondaryTrack(
    centerX,
    widget.clipController.textClips,
    _buildTextClip,
    Icons.text_fields,
    () => debugPrint("Add Text"),
    "Add Text",
  );

  Widget _buildOverlayTrack(double centerX) => _buildSecondaryTrack(
    centerX,
    widget.clipController.overlayClips,
    _buildOverlayClip,
    Icons.layers,
    () => debugPrint("Add Overlay"),
    "Add Overlay",
  );

  Widget _buildSecondaryTrack(
    double centerX,
    List<TimelineItem> clips,
    Widget Function(TimelineItem, double) buildClip,
    IconData icon,
    VoidCallback onAdd,
    String addLabel,
  ) {
    return Container(
      height: 40, // Slightly taller for better look
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: Stack(
        children: [
          // All audio clips
          ...clips.map((c) => buildClip(c, centerX)).toList(),

          // ALWAYS show the track icon on the left
          Positioned(
            left: centerX - widget.controller.timelineOffset - 60,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white70, size: 20),
            ),
          ),

          // Show "Add Audio" text only when track is empty
          if (clips.isEmpty)
            Positioned(
              left: centerX - widget.controller.timelineOffset + 10,
              top: 15,
              child: GestureDetector(
                onTap: onAdd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      addLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCenteredPlayhead(double screenWidth) {
    return Positioned(
      left: screenWidth / 2 - 1,
      top: 35,
      bottom: 4,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF00D9FF),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Container(
                width: 2,
                decoration: const BoxDecoration(
                  color: Color(0xFF00D9FF),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white30,
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _clipWidth(TimelineItem item) {
    final secs = item.duration.inMilliseconds / 1000.0 / item.speed;
    return (secs * widget.controller.pixelsPerSecond).clamp(
      60.0,
      double.infinity,
    );
  }


}



