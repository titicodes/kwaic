import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../provider/video_editor_provider.dart';
import '../timeline_constants.dart';
import 'audio_timeline_row.dart';
import 'clip_widget.dart';

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
  double _center = 0;

  @override
  void initState() {
    super.initState();
    final provider = context.read<VideoEditorProvider>();
    provider.timelineScrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final provider = context.read<VideoEditorProvider>();
    if (!provider.timelineScrollController.hasClients) return;

    final seconds = provider.timelineScrollController.offset / pixelsPerSecond;
    final newPos = Duration(milliseconds: (seconds * 1000).round());
    provider.seekTo(newPos);
  }

  @override
  void dispose() {
    final provider = context.read<VideoEditorProvider>();
    provider.timelineScrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        _center = constraints.maxWidth / 2;

        return SizedBox(
          height: 180,
          child: Stack(
            children: [
              // Fixed left UI (sound + cover)
              Positioned(
                left: _center - leftUiWidth,
                top: 30,
                child: AnimatedBuilder(
                  animation: provider.timelineScrollController,
                  builder: (_, __) {
                    final dx = provider.timelineScrollController.hasClients
                        ? -provider.timelineScrollController.offset
                        : 0.0;
                    final clampedDx = math.min(0, dx);
                    return Transform.translate(
                      offset: Offset(clampedDx.toDouble(), 0),
                      child: const _LeftSection(),
                    );
                  },
                ),
              ),

              // Scrollable timeline — ClampingScrollPhysics for smooth feel
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: provider.timelineScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(), // ← Smooth, no bounce fight
                  child:  Row(
                children: [
                SizedBox(width: _center),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DurationRuler(),
                    const SizedBox(height: 8),
                    const VideoClipsRow(),
                    AudioTrackRow(key: ValueKey(provider.audioTracks.length)),
                  ],
                ),
                SizedBox(width: _center + 400), // ← Extra space on right for scrolling left
                ],
              ),
                ),
              ),

              // Fixed playhead
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
        // Sound Toggle
        GestureDetector(
          onTap: provider.toggleSound,
          child: _box(
            Column(
              children: [
                Icon(
                  provider.isSoundOn ? Icons.volume_up : Icons.volume_off,
                  size: 16,
                  color: Colors.white,
                ),
                Text(
                  provider.isSoundOn ? 'Sound\nOn' : 'Sound\nOff',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Cover — Now shows current video frame
        GestureDetector(
          onTap: provider.selectCover, // keep existing function
          child: _box(
            Column(
              children: [
                SizedBox(
                  height: 25,
                  child: provider.videoController != null &&
                      provider.videoController!.value.isInitialized
                      ? VideoPlayer(provider.videoController!)
                      : provider.selectedCover != null
                      ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
                provider.showToolbar();
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
                      ? Border.all(color: const Color(0xFFB700FF), width: 3)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [const BoxShadow(color: Color(0xFFB700FF), blurRadius: 8)]
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

/// ⏱ TIME RULER - DYNAMIC
class DurationRuler extends StatelessWidget {
  const DurationRuler({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();
    final double maxSeconds = provider.totalTimelineSeconds;

    return SizedBox(
      height: 24,
      child: Row(
        children: List.generate(maxSeconds.toInt() + 1, (i) {
          return SizedBox(
            width: pixelsPerSecond,
            child: Center(
              child: Text(
                _fmt(i),
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
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
              color: Color(0xFFB700FF),
              shape: BoxShape.circle,
            ),
          ),
          const Expanded(
            child: ColoredBox(color: Color(0xFFB700FF), child: SizedBox(width: 2)),
          ),
        ],
      ),
    );
  }
}