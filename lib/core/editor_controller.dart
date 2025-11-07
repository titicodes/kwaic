// import 'dart:async';
// import 'dart:io';
// import 'package:get/get.dart';
// import 'package:video_player/video_player.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
// import 'package:flutter_tts/flutter_tts.dart';
//
// import 'clip_model.dart';
//
// class EditorController extends GetxController {
//   RxList<ClipModel> clips = <ClipModel>[].obs;
//   RxInt selectedClipIndex = (-1).obs;
//   VideoPlayerController? player;
//   RxBool isPlaying = false.obs;
//   RxBool exporting = false.obs;
//
//   final List<List<ClipModel>> _undoStack = [];
//   final List<List<ClipModel>> _redoStack = [];
//   final FlutterTts _tts = FlutterTts();
//
//   void _pushUndo() {
//     _undoStack.add(clips.map((c) => ClipModel(
//       path: c.path, startMs: c.startMs, endMs: c.endMs, speed: c.speed, overlays: List.from(c.overlays),
//     )).toList());
//     _redoStack.clear();
//   }
//
//   void undo() {
//     if (_undoStack.isEmpty) return;
//     _redoStack.add(clips.map((c) => ClipModel(
//       path: c.path, startMs: c.startMs, endMs: c.endMs, speed: c.speed, overlays: List.from(c.overlays),
//     )).toList());
//     final prev = _undoStack.removeLast();
//     clips.assignAll(prev);
//     selectedClipIndex.value = clips.isEmpty ? -1 : 0;
//     _reloadPlayer();
//   }
//
//   void redo() {
//     if (_redoStack.isEmpty) return;
//     _undoStack.add(clips.map((c) => ClipModel(
//       path: c.path, startMs: c.startMs, endMs: c.endMs, speed: c.speed, overlays: List.from(c.overlays),
//     )).toList());
//     final next = _redoStack.removeLast();
//     clips.assignAll(next);
//     selectedClipIndex.value = clips.isEmpty ? -1 : 0;
//     _reloadPlayer();
//   }
//
//   Future<void> pickVideo() async {
//     final status = await Permission.storage.request();
//     if (!status.isGranted) return;
//     final res = await FilePicker.platform.pickFiles(type: FileType.video);
//     if (res == null) return;
//     final path = res.files.single.path!;
//     final dur = await _getDurationMs(path);
//     _pushUndo();
//     clips.add(ClipModel(path: path, startMs: 0.0, endMs: dur.toDouble()));
//     selectedClipIndex.value = clips.length - 1;
//     await _loadSelectedToPlayer();
//   }
//
//   Future<int> _getDurationMs(String path) async {
//     final c = VideoPlayerController.file(File(path));
//     await c.initialize();
//     final d = c.value.duration.inMilliseconds;
//     await c.dispose();
//     return d;
//   }
//
//   Future<void> _loadSelectedToPlayer() async {
//     final idx = selectedClipIndex.value;
//     if (idx < 0 || idx >= clips.length) return;
//     player?.dispose();
//     player = VideoPlayerController.file(File(clips[idx].path));
//     await player!.initialize();
//     await player!.seekTo(Duration(milliseconds: clips[idx].startMs.toInt()));
//     player!.setLooping(true);
//     player!.setPlaybackSpeed(clips[idx].speed);
//     player!.play();
//     isPlaying.value = true;
//     update();
//   }
//
//   void _reloadPlayer() {
//     _loadSelectedToPlayer();
//   }
//
//   void togglePlayPause() {
//     if (player == null) return;
//     if (player!.value.isPlaying) {
//       player!.pause();
//       isPlaying.value = false;
//     } else {
//       player!.play();
//       isPlaying.value = true;
//     }
//   }
//
//   Future<void> seekBy(int milliseconds) async {
//     if (player == null || !player!.value.isInitialized) return;
//     final pos = player!.value.position.inMilliseconds + milliseconds;
//     final dur = player!.value.duration.inMilliseconds;
//     final newPos = pos.clamp(0, dur);
//     await player!.seekTo(Duration(milliseconds: newPos));
//   }
//
//   Future<void> stepForward([int ms = 500]) => seekBy(ms);
//   Future<void> stepBackward([int ms = 500]) => seekBy(-ms);
//
//   void setTrimStart(double ms) {
//     final idx = selectedClipIndex.value;
//     if (idx < 0) return;
//     _pushUndo();
//     clips[idx].startMs = ms;
//     _loadSelectedToPlayer();
//   }
//   void setTrimEnd(double ms) {
//     final idx = selectedClipIndex.value;
//     if (idx < 0) return;
//     _pushUndo();
//     clips[idx].endMs = ms;
//     _loadSelectedToPlayer();
//   }
//
//   void setSpeed(double speed) {
//     final idx = selectedClipIndex.value;
//     if (idx < 0) return;
//     _pushUndo();
//     clips[idx].speed = speed;
//     player?.setPlaybackSpeed(speed);
//     update();
//   }
//
//   void addTextOverlay(TextOverlay overlay) {
//     final idx = selectedClipIndex.value;
//     if (idx < 0) return;
//     _pushUndo();
//     clips[idx].overlays.add(overlay);
//     update();
//   }
//
//   void removeTextOverlay(int clipIndex, int overlayIndex) {
//     _pushUndo();
//     clips[clipIndex].overlays.removeAt(overlayIndex);
//     update();
//   }
//
//   Future<String?> generateThumb(String videoPath, int timeMs, {int width = 96}) async {
//     final thumb = await VideoThumbnail.thumbnailFile(
//       video: videoPath,
//       imageFormat: ImageFormat.PNG,
//       timeMs: timeMs,
//       quality: 75,
//       maxHeight: 120,
//       maxWidth: width,
//     );
//     return thumb;
//   }
//
//   Future<String?> generateTTS(String text) async {
//     final dir = await getTemporaryDirectory();
//     final out = '${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.wav';
//     return null;
//   }
//
//   Future<String?> exportProject({String? musicPath, String? ttsPath}) async {
//     if (clips.isEmpty) return null;
//     exporting.value = true;
//     final temp = await getTemporaryDirectory();
//     final processedPaths = <String>[];
//
//     for (int i = 0; i < clips.length; i++) {
//       final clip = clips[i];
//       final inPath = clip.path;
//       final outPath = '${temp.path}/proc_clip_${i}_${DateTime.now().millisecondsSinceEpoch}.mp4';
//       final start = (clip.startMs / 1000.0).toStringAsFixed(3);
//       final end = (clip.endMs / 1000.0).toStringAsFixed(3);
//       final speed = clip.speed;
//       String drawTextFilter = '';
//       if (clip.overlays.isNotEmpty) {
//         final texts = <String>[];
//         for (var ov in clip.overlays) {
//           final safeText = ov.text.replaceAll("'", "\\\\'");
//           final xExpr = "w*${ov.x.toStringAsFixed(3)} - text_w/2";
//           final yExpr = "h*${ov.y.toStringAsFixed(3)} - text_h/2";
//           final enable = "between(t,${(ov.startMs/1000.0).toStringAsFixed(3)},${((ov.startMs+ov.durationMs)/1000.0).toStringAsFixed(3)})";
//           texts.add("drawtext=text='$safeText':fontfile=/system/fonts/Roboto-Regular.ttf:fontsize=${ov.fontSize.toInt()}:fontcolor=white:x=$xExpr:y=$yExpr:enable='$enable'");
//         }
//         drawTextFilter = texts.join(',');
//       }
//
//       final vFilter = 'setpts=${(1/speed).toStringAsFixed(6)}*PTS';
//       final clampedSpeed = speed.clamp(0.5, 2.0);
//       final aFilter = 'atempo=${clampedSpeed.toStringAsFixed(6)}';
//
//       String filterComplex = '';
//       if (drawTextFilter.isEmpty) {
//         filterComplex = '[0:v]$vFilter[v];[0:a]$aFilter[a]';
//       } else {
//         filterComplex = '[0:v]$vFilter,$drawTextFilter[v];[0:a]$aFilter[a]';
//       }
//
//       final cmd =
//           '-ss $start -to $end -i "${inPath}" -filter_complex "$filterComplex" -map "[v]" -map "[a]" -c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 192k -y "$outPath"';
//
//       final sess = await FFmpegKit.execute(cmd);
//       final rc = await sess.getReturnCode();
//       if (ReturnCode.isSuccess(rc)) {
//         processedPaths.add(outPath);
//       } else {
//         exporting.value = false;
//         return null;
//       }
//     }
//
//     final concatList = '${temp.path}/concat_list.txt';
//     final f = File(concatList);
//     final sb = StringBuffer();
//     for (var p in processedPaths) {
//       sb.writeln("file '$p'");
//     }
//     await f.writeAsString(sb.toString());
//
//     final finalOut = '${temp.path}/final_${DateTime.now().millisecondsSinceEpoch}.mp4';
//     final concatCmd = '-f concat -safe 0 -i "${concatList}" -c copy -y "$finalOut"';
//     var concatSess = await FFmpegKit.execute(concatCmd);
//     var concatRc = await concatSess.getReturnCode();
//     if (!ReturnCode.isSuccess(concatRc)) {
//       final inputs = processedPaths.map((p) => '-i "$p" ').join();
//       final buf = StringBuffer();
//       for (int i = 0; i < processedPaths.length; i++) {
//         buf.write('[$i:v:0][$i:a:0]');
//       }
//       final filter = '${buf.toString()}concat=n=${processedPaths.length}:v=1:a=1[outv][outa]';
//       final cmd2 = '$inputs -filter_complex "$filter" -map "[outv]" -map "[outa]" -c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 192k -y "$finalOut"';
//       var s2 = await FFmpegKit.execute(cmd2);
//       var rc2 = await s2.getReturnCode();
//       if (!ReturnCode.isSuccess(rc2)) {
//         exporting.value = false;
//         return null;
//       }
//     }
//
//     if (musicPath != null || ttsPath != null) {
//       final mergedOut = '${temp.path}/final_with_audio_${DateTime.now().millisecondsSinceEpoch}.mp4';
//       final audioIn = musicPath ?? ttsPath!;
//       final mergeCmd =
//           '-i "$finalOut" -i "$audioIn" -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 -shortest -y "$mergedOut"';
//       final mergeSess = await FFmpegKit.execute(mergeCmd);
//       final mergeRc = await mergeSess.getReturnCode();
//       if (ReturnCode.isSuccess(mergeRc)) {
//         exporting.value = false;
//         return mergedOut;
//       } else {
//         exporting.value = false;
//         return null;
//       }
//     }
//
//     exporting.value = false;
//     return finalOut;
//   }
//
//   @override
//   void onClose() {
//     player?.dispose();
//     super.onClose();
//   }
// }
