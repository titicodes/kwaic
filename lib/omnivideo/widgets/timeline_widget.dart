import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VideoEditorProvider>();
      provider.timelineScrollController.addListener(_onScroll);
    });
  }

  Duration _lastSeek = Duration.zero;
  Duration? _dragStartTime;


  void _onScroll() {
    final provider = context.read<VideoEditorProvider>();
    final controller = provider.timelineScrollController;

    if (!controller.hasClients || provider.isPlaying) return;

    final seconds = controller.offset / pixelsPerSecond;
    final clampedSeconds = seconds.clamp(0, provider.totalTimelineSeconds);

    final newPos = Duration(milliseconds: (clampedSeconds * 1000).round());

    if ((newPos - _lastSeek).abs() >= const Duration(milliseconds: 80)) {
      _lastSeek = newPos;
      provider.seekTo(newPos);
    }
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
              // Scrollable content — now includes left section
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: provider.timelineScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: provider.isPlaying
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: _center - leftUiWidth), // Align left section properly
                      _LeftSection(), // Now scrolls with timeline!
                      SizedBox(width: 16), // Gap after left UI
                      SizedBox(
                        width: math.max(
                          provider.timelineWorldWidth + _center,
                          constraints.maxWidth * 2,
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            DurationRuler(),
                            SizedBox(height: 8),
                            VideoClipsRow(),
                            SizedBox(height: 8),
                            AudioTrackRow(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Fixed playhead (stays in center)
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

// ---------------------- Left Section ----------------------
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
        GestureDetector(
          onTap: provider.selectCover,
          child: _box(
            Column(
              children: [
                SizedBox(
                  height: 25,
                  child: Selector<VideoEditorProvider, Uint8List?>(
                    selector: (_, provider) {
                      // Find active track at current position
                      final pos = provider.currentPosition;
                      for (final track in provider.videoTracks) {
                        if (pos >= track.startTime && pos < track.endTime) {
                          return track.thumbnail;
                        }
                      }
                      return provider.videoTracks.isNotEmpty ? provider.videoTracks.first.thumbnail : null;
                    },
                    builder: (_, thumbnail, __) {
                      if (thumbnail != null) {
                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          child: Image.memory(
                            thumbnail,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        );
                      }
                      return const Icon(Icons.photo, color: Colors.white);
                    },
                  ),
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

// ---------------------- Video Clips Row ----------------------
class VideoClipsRow extends StatelessWidget {
  const VideoClipsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();
    Duration? _dragStartTime;


    return SizedBox(
      height: 60,
      child: Row(
        children: provider.videoTracks.map((track) {
          // Minimum width to avoid invisible clips
          final double width =
          math.max(track.duration.inMilliseconds / 1000 * pixelsPerSecond, 40);
          final bool isSelected = provider.selectedVideoTrackId == track.id;

          return GestureDetector(
            onLongPressStart: (_) {
              _dragStartTime = track.startTime;
            },

            onLongPressMoveUpdate: (details) {
              if (_dragStartTime == null) return;

              final deltaSeconds = details.offsetFromOrigin.dx / pixelsPerSecond;

              final newStart = _dragStartTime! +
                  Duration(milliseconds: (deltaSeconds * 1000).round());

              if (newStart < Duration.zero) return;

              provider.moveClip(track, newStart);
            },

            onLongPressEnd: (_) {
              _dragStartTime = null;
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
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------- Duration Ruler ----------------------
class DurationRuler extends StatelessWidget {
  const DurationRuler({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<VideoEditorProvider, double>(
      selector: (_, p) => p.totalTimelineSeconds,
      builder: (_, maxSeconds, __) {
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
      },
    );
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

// ---------------------- Centered Playhead ----------------------
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
              shape: BoxShape.rectangle,
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
