
import 'dart:io';

import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import '../../omnivideo/enum/enums.dart';
import '../../omnivideo/model/timeline_clip.dart';

class AAllAppController extends ChangeNotifier {
  // ================= TIMELINE
  final ScrollController scrollController = ScrollController();
  final double pixelsPerSecond = 90.0;
  double _timelineOffset = 0.0;


  Duration currentTime = Duration.zero;
  Duration totalDuration = Duration.zero;
  bool _internalSync = false;

  // ================= VIDEO
  VideoPlayerController? videoPlayerController;

  // Getters
  double get timelineOffset => _timelineOffset;

  // ================= CLIPS
  final List<TimelineClip> clips = [];

  AAllAppController() {
    scrollController.addListener(_onTimelineScroll);
  }

  // ================= TIMELINE → VIDEO
  void _onTimelineScroll() {
    if (_internalSync) return;

    final viewport = scrollController.position.viewportDimension;
    final playheadX = viewport / 2;

    final seconds =
        (scrollController.offset + playheadX) / pixelsPerSecond;

    currentTime =
        Duration(milliseconds: (seconds * 1000).round());

    notifyListeners();
  }

  Future<void> playFromTimeline({bool toggle = false}) async {
    if (clips.isEmpty) return;

    final clip = getClipAtCurrentTime()!;
    final relativePos = currentTime - clip.timelineStart + clip.trimStart;

    // If same clip and controller exists → just seek
    if (videoPlayerController != null &&
        videoPlayerController!.dataSource == clip.videoPath &&
        videoPlayerController!.value.isInitialized) {
      await videoPlayerController!.seekTo(relativePos);
      if (toggle || !videoPlayerController!.value.isPlaying) {
        videoPlayerController!.play();
      } else {
        videoPlayerController!.pause();
      }
      return;
    }

    // Otherwise dispose and create new
    await videoPlayerController?.dispose();
    videoPlayerController = VideoPlayerController.file(File(clip.videoPath));
    await videoPlayerController!.initialize();

    videoPlayerController!.addListener(() {
      if (videoPlayerController!.value.isPlaying) {
        syncVideoPosition(videoPlayerController!.value.position);
      }
    });

    await videoPlayerController!.seekTo(relativePos);
    videoPlayerController!.play();
    notifyListeners();
  }

  // ================= VIDEO → TIMELINE (auto-scroll)
  void syncVideoPosition(Duration position) {
    if (_internalSync) return;

    _internalSync = true;
    currentTime = position;

    final viewport = scrollController.position.viewportDimension;
    final playheadX = viewport / 2;

    final offset =
        position.inMilliseconds / 1000 * pixelsPerSecond - playheadX;

    scrollController.jumpTo(
      offset.clamp(
        0.0,
        scrollController.position.maxScrollExtent,
      ),
    );

    _internalSync = false;
    notifyListeners();
  }

  // ================= LOAD ASSETS → TIMELINE
  Future<void> addPickedAssetsToTimeline(
      List<PickedAsset> assets) async {
    Duration cursor = totalDuration;

    for (final asset in assets) {
      if (asset.source != AssetSource.localVideo &&
          asset.source != AssetSource.onlineVideo) continue;

      final videoPath = asset.source == AssetSource.onlineVideo
          ? await downloadOnlineVideo(asset.pathOrUrl)
          : asset.pathOrUrl;

      final tempController =
      VideoPlayerController.file(File(videoPath));
      await tempController.initialize();
      final duration = tempController.value.duration;
      await tempController.dispose();

      final frames = await generateFrameStrip(videoPath);
      final waveform = await generateWaveform(videoPath);

      clips.add(
        TimelineClip(
          id: asset.id,
          videoPath: videoPath,
          frameThumbnails: frames,
          waveformPath: waveform,
          timelineStart: cursor,
          duration: duration,
          trimStart: Duration.zero,
          trimEnd: duration,
        ),
      );

      cursor += duration;
    }

    totalDuration = cursor;
    notifyListeners();
  }

  // ================= PLAYBACK
  // ================= FFmpeg HELPERS

  Future<List<String>> generateFrameStrip(String videoPath) async {
    final dir = await getTemporaryDirectory();
    final List<String> frames = [];

    for (int i = 0; i < 5; i++) {
      final out =
          '${dir.path}/frame_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';

      await FFmpegKit.execute(
        '-i "$videoPath" -ss ${i * 0.5} -vframes 1 "$out"',
      );

      frames.add(out);
    }

    return frames;
  }

  Future<String> generateWaveform(String videoPath) async {
    final dir = await getTemporaryDirectory();
    final out =
        '${dir.path}/wave_${DateTime.now().millisecondsSinceEpoch}.png';

    await FFmpegKit.execute(
      '-i "$videoPath" -filter_complex showwavespic=s=600x80 "$out"',
    );

    return out;
  }

  Future<String> downloadOnlineVideo(String url) async {
    final res = await http.get(Uri.parse(url));
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${url.split('/').last}';
    final file = File(path);
    await file.writeAsBytes(res.bodyBytes);
    return path;
  }

  TimelineClip? getClipAtCurrentTime() {
    if (clips.isEmpty) return null; // handle empty list

    return clips.firstWhere(
          (clip) =>
      currentTime >= clip.timelineStart &&
          currentTime < clip.timelineStart + clip.duration,
      orElse: () => clips.last, // guaranteed non-null
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    videoPlayerController?.dispose();
    super.dispose();
  }

}
