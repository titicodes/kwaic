
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kwaic/nes_scr/widgets/wave_form_painter.dart';
import '../model/timeline_item.dart';
import '../servuices/clip_controller.dart';
import '../servuices/time_line_controller.dart';

class TimelineView extends StatefulWidget {
  final TimelineController controller;
  final ClipController clipController;
  final Duration playheadPosition;
  final bool isPlaying; // NEW: Pass isPlaying from parent
  final Function(Offset) onTimelineTap;
  final Function(String, TimelineItemType) onClipSelected;

  const TimelineView({
    super.key,
    required this.controller,
    required this.clipController,
    required this.playheadPosition,
    required this.isPlaying,
    required this.onTimelineTap,
    required this.onClipSelected,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final ScrollController _scrollController = ScrollController();
  String? _trimmingClipId;
  bool _trimAtStart = false;
  Offset? _dragStartOffset;

  @override
  void initState() {
    super.initState();
    // Rebuild when timeline controller changes (zoom/offset)
    widget.controller.addListener(_onControllerChanged);
    // If clipController is a ChangeNotifier (expected), listen so selection/trims update UI
    try {
      widget.clipController.addListener(_onClipControllerChanged);
    } catch (_) {
      // If clipController is not a ChangeNotifier, ignore. But it's recommended it is.
    }
  }

  void _onControllerChanged() => setState(() {});

  void _onClipControllerChanged() => setState(() {});

  @override
  void didUpdateWidget(covariant TimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying &&
        widget.playheadPosition != oldWidget.playheadPosition) {
      final screenWidth = MediaQuery.of(context).size.width;

      if (widget.controller.scrollController.hasClients) {
        widget.controller.scrollToTime(
          widget.playheadPosition,
          screenWidth,
          animate: true, // ← Changed to true for smooth animation
        );
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    try {
      widget.clipController.removeListener(_onClipControllerChanged);
    } catch (_) {}
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;
    final bool isTablet = screenWidth > 700;
    final double timelineHeight = isTablet ? 300 : 260;

    return SizedBox(
      height: timelineHeight,
      child: Container(
        color: const Color(0xFF000000),
        child: GestureDetector(
          onTapDown: (details) => widget.onTimelineTap(details.localPosition),
          onHorizontalDragUpdate:
              (details) => _handleHorizontalDrag(details.delta.dx),
          onScaleUpdate: (details) {
            if (details.scale != 1.0) _handleZoom(details.scale, screenWidth);
          },
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
                          widget.controller.pixelsPerSecond +
                          screenWidth,
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
                        if (_shouldShowVideoTrack()) _buildVideoTrack(centerX),
                        if (_shouldShowVideoTrack()) const SizedBox(height: 4),
                        if (_shouldShowAudioTrack()) _buildAudioTrack(centerX),
                        if (_shouldShowAudioTrack()) const SizedBox(height: 4),
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
    );
  }

  void _handleHorizontalDrag(double deltaPx) {
    // Use TimelineController's scroll controller (keeps central state consistent)
    final sc = widget.controller.scrollController;
    if (sc.hasClients) {
      final newOffset = sc.offset - deltaPx;
      sc.jumpTo(newOffset.clamp(0.0, sc.position.maxScrollExtent));
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

  // === VIDEO TRACK WITH TRIM HANDLES & SPLIT ON TAP ===
  Widget _buildVideoTrack(double centerX) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: Stack(
        children: [
          ...widget.clipController.videoClips
              .map((clip) => _buildVideoClipWithTrim(clip, centerX))
              .toList(),
          // LEFT: Sound On + Cover
          if (widget.clipController.videoClips.isNotEmpty)
            Positioned(
              left: centerX - widget.controller.timelineOffset - 120,
              top: 8,
              child: Row(
                children: [
                  _sideButton(Icons.volume_up, 'Sound\nOn', () {}),
                  const SizedBox(width: 8),
                  _buildCoverPreview(centerX),
                ],
              ),
            ),
          // RIGHT: Add Video
          Positioned(
            right: 12,
            top: 16,
            child: GestureDetector(
              onTap: () => debugPrint('Add Video'),
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 18),
              ),
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
            widget.controller.isTrimMode && widget.controller.trimClipId == item.id;
    // Calculate left X relative to center of timeline
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
      left: startX + centerX,
      child: GestureDetector(
        onTap: () {
          final playheadSec = widget.playheadPosition.inMilliseconds / 1000.0;
          final clipStart = item.startTime.inMilliseconds / 1000.0;
          final clipEnd =
              clipStart + (item.duration.inMilliseconds / 1000.0 / item.speed);
          // If playhead is inside clip -> split (like your original logic)
          if (playheadSec > clipStart && playheadSec < clipEnd) {
            widget.clipController.splitClip(item, widget.playheadPosition);
            return;
          }
          // Otherwise select clip and notify parent (which should open editor/preview)
          widget.clipController.selectClip(item.id, item.type);
          // ensure controller stores selection
          widget.onClipSelected(item.id, item.type);
        },
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
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildThumbnailStrip(item, width),
              ),
              // Trim handles (visible when trimming or on long-press to enable manual trim)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) {
                    _trimAtStart = true;
                    _trimmingClipId = item.id;
                    widget.controller.enterTrimMode(item.id, atStart: true);
                    widget.onClipSelected(item.id, item.type);
                    setState(() {});
                  },
                  onHorizontalDragUpdate:
                      (d) => _handleTrimDrag(item, d.delta.dx, true),
                  onHorizontalDragEnd: (_) => _finishTrim(),
                  child: Container(
                    width: 12,
                    color: Colors.transparent,
                    child: const Center(
                      child: Icon(
                        Icons.drag_handle,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) {
                    _trimAtStart = false;
                    _trimmingClipId = item.id;
                    widget.controller.enterTrimMode(item.id, atStart: false);
                    widget.clipController.selectClip(item.id, item.type);
                    setState(() {});
                  },
                  onHorizontalDragUpdate:
                      (d) => _handleTrimDrag(item, d.delta.dx, false),
                  onHorizontalDragEnd: (_) => _finishTrim(),
                  child: Container(
                    width: 12,
                    color: Colors.transparent,
                    child: const Center(
                      child: Icon(
                        Icons.drag_handle,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
              // Left handle — white, prominent
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragStart: (_) {
                    widget.controller.enterTrimMode(item.id, atStart: true);
                    setState(() {});
                  },
                  onHorizontalDragUpdate: (d) => _handleTrimDrag(item, d.delta.dx, true),
                  child: Container(
                    width: 16,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.white
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _finishTrim() {
    // finish trims and exit trim mode
    _trimmingClipId = null;
    widget.controller.exitTrimMode();
    setState(() {});
  }

  /// deltaPx is positive when dragging to the right.
  void _handleTrimDrag(
      TimelineItem clip,
      double deltaPx,
      bool draggingStartHandle,
      ) {
    final deltaSec = deltaPx / widget.controller.pixelsPerSecond;
    final delta = Duration(milliseconds: (deltaSec * 1000).round());
    setState(() {
      // Non-destructive trim behaviour:
      // - Adjust clip.trimStart and clip.duration; do NOT edit clip.originalSource
      if (draggingStartHandle) {
        // Move trim start forward/back
        final newTrimStart = (clip.trimStart + delta).clamp(
          Duration.zero,
          clip.originalDuration - const Duration(milliseconds: 100),
        );
        // How much physical time on timeline should shift: if you change trimStart, the visible start
        // may need to move forward on timeline as well (we keep startTime updated so timeline shows anchored effect)
        final diff = newTrimStart - clip.trimStart;
        clip.trimStart = newTrimStart;
        // If trimming start, we effectively shift displayed start forward by diff
        clip.startTime = (clip.startTime + diff).clamp(
          Duration.zero,
          clip.startTime + clip.duration,
        );
        // reduce visible duration accordingly (can't be negative)
        clip.duration = (clip.duration - diff).clamp(
          Duration.zero,
          clip.originalDuration - clip.trimStart,
        );
      } else {
        // dragging end handle -> change visible duration only
        final newDuration = (clip.duration + delta).clamp(
          const Duration(milliseconds: 100),
          clip.originalDuration - clip.trimStart,
        );
        clip.duration = newDuration;
      }
      // If handle gets anchored to playhead (within threshold), enter trim mode anchored
      _maybeEnterTrimModeIfEdgeAtPlayhead(clip, draggingStartHandle);
      widget.clipController.updateClip(clip); // push change for preview/player
    });
  }

  void _maybeEnterTrimModeIfEdgeAtPlayhead(
      TimelineItem clip,
      bool draggingStartHandle,
      ) {
    // compute edge time (seconds)
    final edgeTime =
    (draggingStartHandle
        ? clip.startTime
        : (clip.startTime + clip.duration));
    final playheadTime = widget.playheadPosition;
    final diffMs = (edgeTime - playheadTime).inMilliseconds.abs();
    // threshold = 150ms (tweakable) -> if within threshold, anchor to playhead and set controller trim mode
    if (diffMs <= 150) {
      widget.controller.enterTrimMode(clip.id, atStart: draggingStartHandle);
      // Optionally snap clip edge to playhead in UI (non-destructive: we adjust start or duration for display only)
      if (draggingStartHandle) {
        // snap start to playhead
        final snapDiff = playheadTime - clip.startTime;
        clip.startTime = playheadTime;
        // adjust trimStart accordingly
        clip.trimStart = (clip.trimStart + snapDiff).clamp(
          Duration.zero,
          clip.originalDuration,
        );
        // reduce duration by snapDiff amount
        clip.duration = (clip.duration - snapDiff).clamp(
          Duration.zero,
          clip.originalDuration - clip.trimStart,
        );
      } else {
        // snap end to playhead -> set duration = playhead - start
        final newDuration = (playheadTime - clip.startTime).clamp(
          Duration.zero,
          clip.originalDuration - clip.trimStart,
        );
        clip.duration = newDuration;
      }
      _trimmingClipId = clip.id;
    }
  }

  // === AUDIO / TEXT / OVERLAY CLIPS (ROBUST + DRAG + LONG PRESS) ===
  Widget _buildAudioClip(TimelineItem item, double centerX) {
    // If waveform hasn't been generated yet
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

    // Waveform is ready
    return _buildSecondaryClip(
      item: item,
      centerX: centerX,
      color: const Color(0xFF10B981),
      child: SizedBox(
        height: 50, // Adjust as needed
        child: CustomPaint(
          painter: AudioWaveformPainter(
            waveform: item.waveformData!, // ✅ Waveform type
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTextClip(TimelineItem item, double centerX) =>
      _buildSecondaryClip(
        item: item,
        centerX: centerX,
        color: Color(0xFFF59E0B),
        child: Text(
          item.text ?? 'Text',
          style: TextStyle(color: Colors.white, fontSize: 11),
        ),
      );

  Widget _buildStickerClip(TimelineItem item, double centerX) =>
      _buildSecondaryClip(
        item: item,
        centerX: centerX,
        color: Color(0xFF9333EA),
        child:
        item.file != null
            ? Image.file(item.file!, width: 40, height: 40)
            : Icon(Icons.emoji_emotions_outlined),
      );

  Widget _buildOverlayClip(TimelineItem item, double centerX) =>
      _buildSecondaryClip(
        item: item,
        centerX: centerX,
        color: const Color(0xFF9333EA),
        child:
        item.file != null
            ? Image.file(item.file!, fit: BoxFit.cover)
            : const Icon(Icons.image, color: Colors.white, size: 20),
      );

  Widget _buildSecondaryClip({
    required TimelineItem item,
    required double centerX,
    required Color color,
    required Widget child,
  }) {
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
        onTap: () {
          widget.clipController.selectClip(item.id, item.type);
          widget.onClipSelected(item.id, item.type);
        },
        onLongPress: () => _showClipOptions(item),
        onHorizontalDragStart:
            (_) => _dragStartOffset = Offset(startX + centerX, 0),
        onHorizontalDragUpdate: (d) {
          if (_dragStartOffset == null) return;
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

  // === REST OF THE CODE (unchanged except using timeline controller state) ===
  Widget _buildDurationRuler(double screenWidth, double centerX) {
    final totalSec = widget.controller.totalDuration.inMilliseconds / 1000.0;
    final pixelsPerSecond = widget.controller.pixelsPerSecond;
    final timelineOffset = widget.controller.timelineOffset;

    final visibleSec = screenWidth / pixelsPerSecond;
    final centerSecond = timelineOffset / pixelsPerSecond;
    final halfScreenSec = visibleSec / 2;

    // Adaptive step: denser when zoomed in
    double step =
    pixelsPerSecond > 150
        ? 0.1
        : pixelsPerSecond > 80
        ? 0.5
        : 1.0;

    double start = (centerSecond - halfScreenSec).floorToDouble();
    double end = (centerSecond + halfScreenSec).ceilToDouble();

    final List<Widget> ticks = [];

    for (double s = start; s <= end; s += step) {
      if (s < 0 || s > totalSec + 2) continue;

      final isMajor = (s % 1 == 0); // Full seconds get labels
      final posX = centerX + (s * pixelsPerSecond) - timelineOffset;

      if (posX < -50 || posX > screenWidth + 50) continue; // Slight buffer

      ticks.add(
        Positioned(
          left: posX,
          top: 0,
          child: Column(
            children: [
              if (isMajor)
                Text(
                  _formatTime(Duration(milliseconds: (s * 1000).round())),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    height: 1.2,
                  ),
                ),
              if (isMajor) const SizedBox(height: 2),
              Container(
                width: 1,
                height: isMajor ? 10 : 5,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 34,
      child: Stack(
        children: [
          // REMOVED: The horizontal line (painted border)
          // This was the line you didn't want
          ...ticks,
        ],
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

  Widget _buildThumbnailStrip(TimelineItem item, double clipWidth) {
    if (item.thumbnailBytes == null || item.thumbnailBytes!.isEmpty) {
      return Container(
        color: const Color(0xFF2A2A2A),
        child: const Center(
          child: Icon(Icons.videocam, color: Colors.white30, size: 24),
        ),
      );
    }

    final thumbCount = item.thumbnailBytes!.length;
    final thumbWidth = 120.0;

    return SizedBox(
      width: clipWidth,
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: (clipWidth / thumbWidth).ceil() + 5,
        itemBuilder: (context, index) {
          final thumbIndex = index % thumbCount;
          final bytes = item.thumbnailBytes![thumbIndex];
          return SizedBox(
            width: thumbWidth,
            height: 60,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder:
                  (_, __, ___) => Container(
                color: const Color(0xFF2A2A2A),
                child: const Icon(Icons.error, color: Colors.white30),
              ),
            ),
          );
        },
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
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: Stack(
        children: [
          ...clips.map((c) => buildClip(c, centerX)).toList(),
          Positioned(
            left: centerX - widget.controller.timelineOffset - 60,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, color: Colors.white70, size: 16),
            ),
          ),
          Positioned(
            left: centerX - widget.controller.timelineOffset + 10,
            top: 3,
            child: GestureDetector(
              onTap: onAdd,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 14),
                  SizedBox(width: 3),
                  Text(
                    addLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
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
      top: 0,
      bottom: 0,
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

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final millis = (duration.inMilliseconds % 1000) ~/ 10; // Show centiseconds

    return '$minutes:${seconds.toString().padLeft(2, '0')}.'
        '${millis.toString().padLeft(2, '0')}';
  }

  // NEW method in _TimelineViewState
  void _handleWholeClipDrag(TimelineItem clip, double deltaPx) {
    final deltaSec = deltaPx / widget.controller.pixelsPerSecond;
    final delta = Duration(milliseconds: (deltaSec * 1000).round());

    // Calculate new start time, clamp to timeline bounds
    final newStart = (clip.startTime + delta).clamp(
      Duration.zero,
      widget.controller.totalDuration - clip.duration,
    );

    // Update startTime
    clip.startTime = newStart;
    widget.clipController.updateClip(clip); // Triggers rebuild + preview sync
  }
}