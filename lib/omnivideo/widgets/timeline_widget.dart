import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/video_editor_provider.dart';
import '../timeline_constants.dart';
import 'audio_timeline_row.dart';
import 'clip_widget.dart';

class TimelineWidget extends StatefulWidget {
  const TimelineWidget({super.key});

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  final ScrollController _scroll = ScrollController();
  double _center = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final provider = context.read<VideoEditorProvider>();
    final seconds = _scroll.offset / pixelsPerSecond;

    final newPos = Duration(milliseconds: (seconds * 1000).round());
    provider.seekTo(newPos); // This should update preview
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        _center = constraints.maxWidth / 2;

        return SizedBox(
          height: 180, // Increased height
          child: Stack(
            children: [
              /// 🔹 SOUND + COVER (scrolls but CLAMPED)
              Positioned(
                left: _center - leftUiWidth,
                top: 30,
                child: AnimatedBuilder(
                  animation: _scroll,
                  builder: (_, __) {
                    final dx = _scroll.hasClients ? -_scroll.offset : 0.0;
                    final clampedDx = math.min(0, dx);
                    return Transform.translate(
                      offset: Offset(clampedDx.toDouble(), 0),
                      child: const _LeftSection(),
                    );
                  },
                ),
              ),

              /// 🔹 SCROLLABLE TIMELINE
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      SizedBox(width: _center),
                      Column(
                        mainAxisSize: MainAxisSize.min, // Add this
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:  [
                          DurationRuler(),
                          SizedBox(height: 8),
                          VideoClipsRow(),
                          AudioTrackRow(key: ValueKey(provider.audioTracks.length), ),
                        ],
                      ),
                      SizedBox(width: _center),
                    ],
                  ),
                ),
              ),

              /// 🔹 PLAYHEAD (fixed forever)
              Positioned(
                left: _center - 1,
                top: 0,
                bottom: 0,
                child: const CenteredPlayhead(),
              ),
            ],
          ),
        );
      },
    );
  }

}

/// 🔒 FIXED LEFT UI
class _LeftSection extends StatelessWidget {
  const _LeftSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();

    return Row(
      children: [
        GestureDetector(
          onTap: provider.toggleSound,
          child: _box(
            Column(
              children: const [
                Icon(Icons.volume_up, size: 16, color: Colors.white),
               // SizedBox(height: 2),
                Text(
                  'Sound\nOn',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 8, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: provider.selectCover,
          child: _box(
            Column(
              children: [
                SizedBox(
                  height: 25,
                  child: provider.selectedCover != null
                      ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: Image.memory(
                      provider.selectedCover!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Icon(Icons.photo, color: Colors.white),
                ),
                const Text(
                  'Cover',
                  style: TextStyle(fontSize: 8, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _box(Widget child) {
    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

/// 🎬 VIDEO CLIPS
class VideoClipsRow extends StatelessWidget {
  const VideoClipsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();

    double cursor = 0;

    return SizedBox(
      height: 60,
      width: provider.timelineWorldWidth,
      child: Stack(
        children: provider.videoTracks.map((track) {
          final double width = track.duration.inMilliseconds / 1000 * pixelsPerSecond;
          final double left = cursor;
          cursor += width + clipGap;

          final bool isSelected = provider.selectedVideoTrackId == track.id;

          return Positioned(
            left: left,
            top: 0,
            child: GestureDetector(
              onTap: () {
                provider.selectVideoTrack(track.id);
                provider.showToolbar(); // Open edit toolbar
              },
              onHorizontalDragUpdate: (details) {
                final deltaSeconds = details.delta.dx / pixelsPerSecond;
                final newStartSeconds = (track.startTime.inMilliseconds / 1000) + deltaSeconds;
                if (newStartSeconds < 0) return;

                final updated = track.copyWith(
                  startTime: Duration(seconds: newStartSeconds.toInt()),
                  endTime: Duration(seconds: (newStartSeconds + track.duration.inSeconds).toInt()),
                );

                provider.replaceTrack(provider.videoTracks.indexOf(track), updated);
              },
              child: Container(
                width: width,
                height: 60,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(color: const Color(0xFF00D9FF), width: 3)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [const BoxShadow(color: Color(0xFF00D9FF), blurRadius: 8)]
                      : null,
                ),
                child: VideoClipWidget(track: track),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
/// ⏱ TIME RULER
class DurationRuler extends StatelessWidget {
  const DurationRuler({super.key});

  @override
  Widget build(BuildContext context) {
    final seconds =
        context.watch<VideoEditorProvider>().totalTimelineSeconds;

    return SizedBox(
      height: 24,
      child: Row(
        children: List.generate(seconds.toInt() + 1, (i) {
          return SizedBox(
            width: pixelsPerSecond,
            child: Center(
              child: Text(
                _fmt(i),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

/// ▶️ PLAYHEAD
class CenteredPlayhead extends StatelessWidget {
  const CenteredPlayhead({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF00D9FF),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              width: 2,
              color: const Color(0xFF00D9FF),
            ),
          ),
        ],
      ),
    );
  }
}
