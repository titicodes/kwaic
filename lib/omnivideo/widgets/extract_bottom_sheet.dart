// widgets/extract_bottom_sheet.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:uuid/uuid.dart';
import '../provider/video_editor_provider.dart';
import '../model/audio_track.dart';

class ExtractBottomSheet extends StatefulWidget {
  const ExtractBottomSheet({super.key});

  @override
  State<ExtractBottomSheet> createState() => _ExtractBottomSheetState();
}

class _ExtractBottomSheetState extends State<ExtractBottomSheet> {
  List<AssetEntity> _videos = [];
  Set<String> _selected = {};
  bool _extracting = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (!permitted.isAuth) return;

    final albums = await PhotoManager.getAssetPathList(type: RequestType.video);
    if (albums.isNotEmpty) {
      final assets = await albums.first.getAssetListPaged(page: 0, size: 500);
      setState(() => _videos = assets);
    }
  }

  Future<void> _extractAndAdd() async {
    if (_selected.isEmpty) return;
    setState(() => _extracting = true);

    final provider = context.read<VideoEditorProvider>();
    final tempDir = await getTemporaryDirectory();

    for (final id in _selected) {
      final entity = _videos.firstWhere((e) => e.id == id);
      final file = await entity.file;
      if (file == null) continue;

      final outputPath = '${tempDir.path}/extracted_${const Uuid().v4()}.m4a';

      final command = '-i "${file.path}" -vn -c:a aac -b:a 192k "$outputPath"';
      final session = await FFmpegKit.execute(command);
      final rc = await session.getReturnCode();

      if (ReturnCode.isSuccess(rc)) {
        final audioFile = File(outputPath);
        final player = AudioPlayer();
        await player.setFilePath(outputPath);
        final duration = player.duration ?? const Duration(seconds: 5);
        final durationSec = duration.inMilliseconds / 1000.0;

        // Generate waveform
        final waveFile = File('${tempDir.path}/wave_${const Uuid().v4()}.wave');
        Waveform? waveform;
        try {
          final stream = JustWaveform.extract(audioInFile: audioFile, waveOutFile: waveFile);
          await for (final progress in stream) {
            if (progress.waveform != null) waveform = progress.waveform;
          }
        } catch (_) {}
        if (await waveFile.exists()) await waveFile.delete();

        final audioTrack = AudioTrack(
          id: const Uuid().v4(),
          path: outputPath,
          duration: durationSec,
          start: provider.currentPosition.inMilliseconds / 1000.0,
          waveform: waveform,
          player: player,
          originalDuration: durationSec,
        );

        provider.addAudioTrack(audioTrack);
      }
    }

    setState(() => _extracting = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('Extract Audio from Videos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_selected.length} selected', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _videos.length,
              itemBuilder: (_, i) {
                final video = _videos[i];
                final selected = _selected.contains(video.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selected.remove(video.id);
                      } else {
                        _selected.add(video.id);
                      }
                    });
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FutureBuilder<Uint8List?>(
                        future: video.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
                        builder: (_, snap) {
                          if (!snap.hasData) return Container(color: Colors.grey[900]);
                          return Image.memory(snap.data!, fit: BoxFit.cover);
                        },
                      ),
                      if (selected)
                        Container(
                          color: Colors.black54,
                          child: const Icon(Icons.check_circle, color: Color(0xFFB700FF), size: 40),
                        ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: Colors.black54,
                          child: Text(
                            '${video.videoDuration.inSeconds}s',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _extracting ? null : _extractAndAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB700FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: _extracting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Extract & Add Audio', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}