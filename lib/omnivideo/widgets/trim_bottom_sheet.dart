import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/video_track.dart';
import '../provider/video_editor_provider.dart';
import '../service/video_editor_service.dart';

class TrimBottomSheet extends StatefulWidget {
  const TrimBottomSheet({Key? key}) : super(key: key);

  @override
  State<TrimBottomSheet> createState() => _TrimBottomSheetState();
}

class _TrimBottomSheetState extends State<TrimBottomSheet> {
  late VideoTrack track;
  late Duration duration;

  bool isExporting = false;

  double startPercent = 0.0;
  double endPercent = 1.0;

  static const double thumbWidth = 60;
  static const double stripHeight = 80;



  @override
  void initState() {
    super.initState();

    final provider = context.read<VideoEditorProvider>();
    track = provider.videoTracks[provider.selectedTrackIndex];
    duration = track.duration;

    provider.setTrimRangeSilently(Duration.zero, duration);
  }

  /// ✅ Visible thumbnails based on trim window
  List<Uint8List> get visibleThumbs {
    final thumbs = track.timelineThumbnails;
    if (thumbs.isEmpty) return [];

    final start = (startPercent * thumbs.length).floor();
    final end = (endPercent * thumbs.length).ceil();

    return thumbs.sublist(
      start.clamp(0, thumbs.length),
      end.clamp(0, thumbs.length),
    );
  }

  double get stripWidth =>
      track.timelineThumbnails.length * thumbWidth;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();

    return Container(
      height: 220,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          /// 🔹 HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    provider
                      ..showBottomSheet = false
                      ..showContextToolbar = true;
                  },
                ),
                const Text(
                  'Trim',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: isExporting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.check, color: Colors.white),
                  onPressed: isExporting ? null : () => _applyTrim(provider),
                ),
              ],
            ),
          ),

          /// 🔹 TRIM STRIP
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: stripWidth,
                  height: stripHeight,
                  child: Stack(
                    children: [
                      /// THUMBNAILS
                      Row(
                        children: track.timelineThumbnails.map((bytes) {
                          return SizedBox(
                            width: thumbWidth,
                            height: stripHeight,
                            child: Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                            ),
                          );
                        }).toList(),
                      ),

                      /// LEFT HANDLE
                      _buildHandle(
                        left: startPercent * stripWidth - 15,
                        onDrag: (dx) {
                          final newX =
                              startPercent * stripWidth + dx;
                          final newPercent = (newX / stripWidth)
                              .clamp(0.0, endPercent - 0.02);

                          setState(() => startPercent = newPercent);

                          final ms =
                          (newPercent * duration.inMilliseconds).round();
                          provider.trimStart =
                              Duration(milliseconds: ms);
                          provider.seekTo(provider.trimStart);
                        },
                      ),

                      /// RIGHT HANDLE
                      _buildHandle(
                        left: endPercent * stripWidth - 15,
                        onDrag: (dx) {
                          final newX =
                              endPercent * stripWidth + dx;
                          final newPercent = (newX / stripWidth)
                              .clamp(startPercent + 0.02, 1.0);

                          setState(() => endPercent = newPercent);

                          final ms =
                          (newPercent * duration.inMilliseconds).round();
                          provider.trimEnd =
                              Duration(milliseconds: ms);
                        },
                      ),

                      /// SELECTION BORDER
                      IgnorePointer(
                        child: Container(
                          margin: EdgeInsets.only(
                            left: startPercent * stripWidth + 15,
                            right:
                            (1 - endPercent) * stripWidth + 15,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                        ),
                      ),

                      /// DARK OVERLAY
                      IgnorePointer(
                        child: Row(
                          children: [
                            Container(
                              width: startPercent * stripWidth,
                              color: Colors.black54,
                            ),
                            Container(
                              width:
                              (endPercent - startPercent) * stripWidth,
                              color: Colors.transparent,
                            ),
                            Expanded(
                              child: Container(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// 🔹 TIME LABELS
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(provider.trimStart),
                  style:
                  const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  _fmt(provider.trimEnd),
                  style:
                  const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle({
    required double left,
    required ValueChanged<double> onDrag,
  }) {
    return Positioned(
      left: left.clamp(-15.0, stripWidth),
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
        child: Container(
          width: 30,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Container(width: 5, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _applyTrim(VideoEditorProvider provider) async {
    final updatedTrack = track.copyWith(
      trimStart: provider.trimStart,
      trimEnd: provider.trimEnd,
    );

    provider.replaceTrack(provider.selectedTrackIndex, updatedTrack);

    provider
      ..showBottomSheet = false
      ..showContextToolbar = true;
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000 ~/ 100);
    return '$m:$s.$ms';
  }
}
