// import 'dart:async';
// import 'dart:io';
// import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_min_gpl/return_code.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:undo/undo.dart';
// import 'package:video_player/video_player.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:device_info_plus/device_info_plus.dart';
//
// class EditorController extends GetxController {
//   // ────────────────────────────────────── OBSERVABLES ──────────────────────────────────────
//   final RxList<ClipModel> clips = <ClipModel>[].obs;
//   final selectedIndex = (-1).obs;
//   final selectedToolTab = 0.obs;
//
//   VideoPlayerController? player;
//   final isPlaying = false.obs;
//   final currentMs = 0.0.obs;
//   final exporting = false.obs;
//
//   // Timeline zoom
//   final pixelsPerSecond = 50.0.obs;
//   final timelineScrollController = ScrollController();
//
//   String? bgMusicPath;
//   String? voiceoverPath;
//   String? ttsPath;
//
//   StreamSubscription? _posSub;
//   final ChangeStack _cs = ChangeStack();
//
//   // ────────────────────────────────────── UNDO / REDO ──────────────────────────────────────
//   void addChange(Change change) => _cs.add(change);
//   void undo() => _cs.undo();
//   void redo() => _cs.redo();
//   bool get canUndo => _cs.canUndo;
//   bool get canRedo => _cs.canRedo;
//
//   // ────────────────────────────────────── LIFECYCLE ──────────────────────────────────────
//   @override
//   void onClose() {
//     _stopPlayerListener();
//     player?.dispose();
//     timelineScrollController.dispose();
//     super.onClose();
//   }
//
//   // ────────────────────────────────────── TIMELINE ZOOM ──────────────────────────────────────
//   void zoomIn() {
//     pixelsPerSecond.value = (pixelsPerSecond.value + 10).clamp(30.0, 150.0);
//   }
//
//   void zoomOut() {
//     pixelsPerSecond.value = (pixelsPerSecond.value - 10).clamp(30.0, 150.0);
//   }
//
//   // ────────────────────────────────────── STORAGE PERMISSIONS (ROBUST) ──────────────────────────────────────
//   Future<bool> requestStoragePermission() async {
//     try {
//       if (Platform.isAndroid) {
//         final androidInfo = await DeviceInfoPlugin().androidInfo;
//
//         // Android 13+ (API 33+) uses granular permissions
//         if (androidInfo.version.sdkInt >= 33) {
//           final photos = await Permission.photos.request();
//           final videos = await Permission.videos.request();
//
//           if (photos.isGranted && videos.isGranted) {
//             return true;
//           }
//
//           // If denied, show settings
//           if (photos.isPermanentlyDenied || videos.isPermanentlyDenied) {
//             final openSettings = await Get.dialog<bool>(
//               AlertDialog(
//                 backgroundColor: const Color(0xFF1C1C1E),
//                 title: const Text(
//                   'Permission Required',
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 content: const Text(
//                   'This app needs access to your photos and videos. Please grant permission in settings.',
//                   style: TextStyle(color: Colors.white70),
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Get.back(result: false),
//                     child: const Text('Cancel'),
//                   ),
//                   ElevatedButton(
//                     onPressed: () => Get.back(result: true),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF0A84FF),
//                     ),
//                     child: const Text('Open Settings'),
//                   ),
//                 ],
//               ),
//             );
//
//             if (openSettings == true) {
//               await openAppSettings();
//             }
//             return false;
//           }
//
//           return false;
//         } else {
//           // Android 12 and below
//           final storage = await Permission.storage.request();
//
//           if (storage.isGranted) {
//             return true;
//           }
//
//           if (storage.isPermanentlyDenied) {
//             final openSettings = await Get.dialog<bool>(
//               AlertDialog(
//                 backgroundColor: const Color(0xFF1C1C1E),
//                 title: const Text(
//                   'Permission Required',
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 content: const Text(
//                   'Storage permission is required to access videos. Please grant permission in settings.',
//                   style: TextStyle(color: Colors.white70),
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Get.back(result: false),
//                     child: const Text('Cancel'),
//                   ),
//                   ElevatedButton(
//                     onPressed: () => Get.back(result: true),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF0A84FF),
//                     ),
//                     child: const Text('Open Settings'),
//                   ),
//                 ],
//               ),
//             );
//
//             if (openSettings == true) {
//               await openAppSettings();
//             }
//             return false;
//           }
//
//           return false;
//         }
//       } else if (Platform.isIOS) {
//         final photos = await Permission.photos.request();
//
//         if (photos.isGranted) {
//           return true;
//         }
//
//         if (photos.isPermanentlyDenied) {
//           final openSettings = await Get.dialog<bool>(
//             AlertDialog(
//               backgroundColor: const Color(0xFF1C1C1E),
//               title: const Text(
//                 'Permission Required',
//                 style: TextStyle(color: Colors.white),
//               ),
//               content: const Text(
//                 'Photo library access is required. Please grant permission in settings.',
//                 style: TextStyle(color: Colors.white70),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Get.back(result: false),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => Get.back(result: true),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF0A84FF),
//                   ),
//                   child: const Text('Open Settings'),
//                 ),
//               ],
//             ),
//           );
//
//           if (openSettings == true) {
//             await openAppSettings();
//           }
//           return false;
//         }
//
//         return false;
//       }
//
//       return true;
//     } catch (e) {
//       Get.snackbar(
//         'Permission Error',
//         'Failed to request permissions: $e',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       return false;
//     }
//   }

//   // ────────────────────────────────────── VIDEO PICK & THUMBNAILS ──────────────────────────────────────
//   Future<void> pickVideo() async {
//     try {
//       // Request permission first
//       final hasPermission = await requestStoragePermission();
//       if (!hasPermission) {
//         Get.snackbar(
//           'Permission Denied',
//           'Storage access is required to pick videos',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.orange,
//           colorText: Colors.white,
//         );
//         return;
//       }
//
//       final res = await FilePicker.platform.pickFiles(
//         type: FileType.video,
//         allowCompression: false,
//       );
//
//       if (res == null || res.files.isEmpty) return;
//
//       final path = res.files.single.path;
//       if (path == null) {
//         Get.snackbar('Error', 'Failed to get video path');
//         return;
//       }
//
//       // Validate file exists
//       final file = File(path);
//       if (!await file.exists()) {
//         Get.snackbar('Error', 'Video file not found');
//         return;
//       }
//
//       // Show loading
//       Get.dialog(
//         const AlertDialog(
//           backgroundColor: Color(0xFF1C1C1E),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircularProgressIndicator(color: Color(0xFF0A84FF)),
//               SizedBox(height: 16),
//               Text(
//                 'Loading video...',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ],
//           ),
//         ),
//         barrierDismissible: false,
//       );
//
//       final durationMs = await _getVideoDurationMs(path);
//       if (durationMs <= 0) {
//         Get.back();
//         Get.snackbar('Error', 'Invalid video duration');
//         return;
//       }
//
//       final newClip = ClipModel(
//         path: path,
//         startMs: 0,
//         endMs: durationMs.toDouble(),
//         originalDurationMs: durationMs.toDouble(),
//       );
//
//       clips.add(newClip);
//       selectedIndex.value = clips.length - 1;
//
//       // Generate thumbnails in background
//       unawaited(_generateThumbnailsForClip(newClip));
//
//       await loadSelectedToPlayer();
//
//       Get.back(); // Close loading dialog
//
//       Get.snackbar(
//         'Success',
//         'Video loaded successfully',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//       );
//     } catch (e) {
//       Get.back(); // Close loading dialog if open
//       Get.snackbar(
//         'Error',
//         'Failed to load video: $e',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }
//
//   Future<int> _getVideoDurationMs(String path) async {
//     VideoPlayerController? tmp;
//     try {
//       tmp = VideoPlayerController.file(File(path));
//       await tmp.initialize();
//       return tmp.value.duration.inMilliseconds;
//     } catch (e) {
//       print('Error getting duration: $e');
//       return 0;
//     } finally {
//       await tmp?.dispose();
//     }
//   }
//
//   Future<void> _generateThumbnailsForClip(
//       ClipModel clip, {
//         int count = 12,
//       }) async {
//     try {
//       final thumbs = <String>[];
//       final duration = clip.endMs - clip.startMs;
//
//       for (int i = 0; i < count; i++) {
//         try {
//           final timeMs = clip.startMs + ((i / (count - 1)) * duration);
//           final thumb = await VideoThumbnail.thumbnailFile(
//             video: clip.path,
//             imageFormat: ImageFormat.PNG,
//             timeMs: timeMs.toInt(),
//             quality: 75,
//           );
//           if (thumb != null) thumbs.add(thumb);
//         } catch (e) {
//           print('Thumbnail generation error at frame $i: $e');
//         }
//       }
//
//       if (thumbs.isNotEmpty) {
//         final updated = clip.copyWith(thumbs: thumbs);
//         final idx = clips.indexOf(clip);
//         if (idx != -1) {
//           clips[idx] = updated;
//           clips.refresh();
//         }
//       }
//     } catch (e) {
//       print('Thumbnail error: $e');
//     }
//   }
//
//   // ────────────────────────────────────── PLAYER & POSITION ──────────────────────────────────────
//   Future<void> loadSelectedToPlayer() async {
//     final idx = selectedIndex.value;
//     if (idx < 0 || idx >= clips.length) return;
//
//     final clip = clips[idx];
//
//     try {
//       await player?.dispose();
//       player = VideoPlayerController.file(File(clip.path));
//
//       await player!.initialize();
//       player!.setLooping(false);
//       player!.setPlaybackSpeed(clip.speed);
//       player!.setVolume(clip.volume);
//       await player!.seekTo(Duration(milliseconds: clip.startMs.toInt()));
//
//       _startPlayerListener();
//
//       if (isPlaying.value) {
//         await player!.play();
//       }
//     } catch (e) {
//       Get.snackbar(
//         'Error',
//         'Failed to load video: $e',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }
//
//   void _startPlayerListener() {
//     _stopPlayerListener();
//     _posSub = Stream.periodic(const Duration(milliseconds: 50)).listen((_) {
//       if (player == null || !player!.value.isInitialized) return;
//
//       final pos = player!.value.position.inMilliseconds.toDouble();
//       currentMs.value = pos;
//
//       final idx = selectedIndex.value;
//       if (idx < 0 || idx >= clips.length) return;
//
//       final clip = clips[idx];
//
//       // Auto-loop within trim range
//       if (pos >= clip.endMs) {
//         player!.seekTo(Duration(milliseconds: clip.startMs.toInt()));
//       }
//     });
//   }
//
//   void _stopPlayerListener() {
//     _posSub?.cancel();
//     _posSub = null;
//   }
//
//   void togglePlayPause() {
//     if (player == null || !player!.value.isInitialized) return;
//     if (player!.value.isPlaying) {
//       player!.pause();
//       isPlaying.value = false;
//     } else {
//       player!.play();
//       isPlaying.value = true;
//     }
//   }
//
//   Future<void> seekToMs(double ms) async {
//     if (player == null || !player!.value.isInitialized) return;
//     final dur = player!.value.duration.inMilliseconds.toDouble();
//     final target = ms.clamp(0.0, dur).toInt();
//     await player!.seekTo(Duration(milliseconds: target));
//     currentMs.value = target.toDouble();
//   }
//
//   // ────────────────────────────────────── UNDO-WRAPPED ACTIONS ──────────────────────────────────────
//   void _replaceClip(int idx, ClipModel clip) {
//     if (idx >= 0 && idx < clips.length) {
//       clips[idx] = clip;
//       clips.refresh();
//       loadSelectedToPlayer();
//     }
//   }
//
//   // ────────────────────────────────────── TRIM ──────────────────────────────────────
//   void setTrimStart(double ms) {
//     final idx = selectedIndex.value;
//     if (idx < 0 || idx >= clips.length) return;
//
//     final clip = clips[idx];
//     final before = clip.copy();
//
//     clip.startMs = ms.clamp(0.0, clip.endMs - 100);
//     clips.refresh();
//     seekToMs(clip.startMs);
//
//     final after = clip.copy();
//     addChange(
//       Change<ClipModel>(
//         before,
//             () => _replaceClip(idx, after),
//             (old) => _replaceClip(idx, old),
//       ),
//     );
//   }
//
//   void setTrimEnd(double ms) {
//     final idx = selectedIndex.value;
//     if (idx < 0 || idx >= clips.length) return;
//
//     final clip = clips[idx];
//     final before = clip.copy();
//     final max = clip.originalDurationMs;
//
//     clip.endMs = ms.clamp(clip.startMs + 100, max);
//     clips.refresh();
//
//     final after = clip.copy();
//     addChange(
//       Change<ClipModel>(
//         before,
//             () => _replaceClip(idx, after),
//             (old) => _replaceClip(idx, old),
//       ),
//     );
//   }
//
//   // ────────────────────────────────────── SPLIT ──────────────────────────────────────
//   Future<void> splitClip() async {
//     final idx = selectedIndex.value;
//     if (idx < 0 || idx >= clips.length) return;
//
//     final clip = clips[idx];
//     final splitPoint = currentMs.value - clip.startMs;
//
//     if (splitPoint <= 100 || splitPoint >= (clip.endMs - clip.startMs - 100)) {
//       Get.snackbar('Error', 'Cannot split at this position');
//       return;
//     }
//
//     Get.dialog(
//       const AlertDialog(
//         backgroundColor: Color(0xFF1C1C1E),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircularProgressIndicator(color: Color(0xFF0A84FF)),
//             SizedBox(height: 16),
//             Text('Splitting clip...', style: TextStyle(color: Colors.white)),
//           ],
//         ),
//       ),
//       barrierDismissible: false,
//     );
//
//     final firstEnd = clip.startMs + splitPoint;
//     final secondStart = firstEnd;
//
//     final firstClip = clip.copyWith(endMs: firstEnd);
//     final secondClip = clip.copyWith(startMs: secondStart, endMs: clip.endMs);
//
//     await _generateThumbnailsForClip(firstClip);
//     await _generateThumbnailsForClip(secondClip);
//
//     final beforeClips = clips.map((c) => c.copy()).toList();
//     final beforeIndex = selectedIndex.value;
//
//     clips.removeAt(idx);
//     clips.insert(idx, firstClip);
//     clips.insert(idx + 1, secondClip);
//     selectedIndex.value = idx + 1;
//
//     final afterClips = clips.map((c) => c.copy()).toList();
//     final afterIndex = selectedIndex.value;
//
//     addChange(
//       Change<List<ClipModel>>(
//         beforeClips,
//             () {
//           clips.clear();
//           clips.addAll(afterClips);
//           selectedIndex.value = afterIndex;
//           clips.refresh();
//           loadSelectedToPlayer();
//         },
//             (oldClips) {
//           clips.clear();
//           clips.addAll(oldClips);
//           selectedIndex.value = beforeIndex;
//           clips.refresh();
//           loadSelectedToPlayer();
//         },
//       ),
//     );
//
//     await loadSelectedToPlayer();
//     Get.back();
//     Get.snackbar('Success', 'Clip split successfully');
//   }
//
//   // ────────────────────────────────────── SPEED & VOLUME ──────────────────────────────────────
//   void setSpeed(double speed) {
//     final idx = selectedIndex.value;
//     if (idx < 0 || idx >= clips.length) return;
//
//     final clip = clips[idx];
//     final before = clip.copy();
//
//     clip.speed = speed.clamp(0.25, 4.0);
//     player?.setPlaybackSpeed(clip.speed);
//     clips.refresh();
//
//     final after = clip.copy();
//     addChange(
//       Change<ClipModel>(
//         before,
//             () => _replaceClip(idx, after),
//             (old) => _replaceClip(idx, old),
//       ),
//     );
//   }
//
//   void setVolume(double volume) {
//     final idx = selectedIndex.value;
//     if (idx < 0 || idx >= clips.length) return;
//
//     final clip = clips[idx];
//     final before = clip.copy();
//
//     clip.volume = volume.clamp(0.0, 2.0);
//     player?.setVolume(clip.volume);
//     clips.refresh();
//
//     final after = clip.copy();
//     addChange(
//       Change<ClipModel>(
//         before,
//             () => _replaceClip(idx, after),
//             (old) => _replaceClip(idx, old),
//       ),
//     );
//   }
//
//   // ────────────────────────────────────── FLIP & ROTATE ──────────────────────────────────────
//   void toggleFlipHorizontal() {
//     final idx = selectedIndex.value;
//     if (idx < 0 || idx >= clips.length) return;
//
//     final clip = clips[idx];
//     final before = clip.copy();
//
//     clip.flipHorizontal = !clip.flipHorizontal;
//     clips.refresh();
//
//     final after = clip.copy();
//     addChange(
//       Change<ClipModel>(
//         before,
//             () => _replaceClip(idx, after),
//             (old) => _replaceClip(idx, old),
//       ),
//     );
//   }
//
//   void rotateClip(int degrees) {
//     final idx = selectedIndex.value;
//     if (idx < 0 || idx >= clips.length) return;
//
//     final clip = clips[idx];
//     final before = clip.copy();
//
//     clip.rotation = (clip.rotation + degrees) % 360;
//     clips.refresh();
//
//     final after = clip.copy();
//     addChange(
//       Change<ClipModel>(
//         before,
//             () => _replaceClip(idx, after),
//             (old) => _replaceClip(idx, old),
//       ),
//     );
//   }
//
//   // ────────────────────────────────────── TRANSITION ──────────────────────────────────────
//   void setTransition(String type, double durationSec) {
//     final idx = selectedIndex.value;
//     if (idx >= clips.length - 1 || idx < 0) return;
//
//     final clip = clips[idx];
//     final before = clip.copy();
//
//     clip.transitionType = type;
//     clip.transitionDuration = durationSec;
//     clips.refresh();
//
//     final after = clip.copy();
//     addChange(
//       Change<ClipModel>(
//         before,
//             () => _replaceClip(idx, after),
//             (old) => _replaceClip(idx, old),
//       ),
//     );
//   }
//
//   // ────────────────────────────────────── FILTER ──────────────────────────────────────
//   void setFilter(String name) {
//     final idx = selectedIndex.value;
//     if (idx < 0 || idx >= clips.length) return;
//
//     final clip = clips[idx];
//     final before = clip.copy();
//
//     clip.filterName = name;
//     clip.filter = _getFilterId(name);
//     clips.refresh();
//
//     final after = clip.copy();
//     addChange(
//       Change<ClipModel>(
//         before,
//             () => _replaceClip(idx, after),
//             (old) => _replaceClip(idx, old),
//       ),
//     );
//   }
//
//   String _getFilterId(String name) {
//     const map = {
//       'Black & White': 'hue=s=0',
//       'Sepia': 'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131',
//       'Vintage': 'curves=vintage',
//       'Blur': 'boxblur=5:1',
//       'Sharpen': 'unsharp=5:5:1.0:5:5:0.0',
//     };
//     return map[name] ?? '';
//   }
//
//   // ────────────────────────────────────── OVERLAYS ──────────────────────────────────────
//   void addTextOverlay(TextOverlay overlay) {
//     final idx = selectedIndex.value;
//     if (idx < 0 || idx >= clips.length) return;
//
//     final before = clips[idx].copy();
//     final newOverlays = List<TextOverlay>.from(clips[idx].textOverlays)
//       ..add(overlay);
//     clips[idx] = clips[idx].copyWith(textOverlays: newOverlays);
//     clips.refresh();
//
//     final after = clips[idx].copy();
//     addChange(
//       Change<ClipModel>(
//         before,
//             () => _replaceClip(idx, after),
//             (old) => _replaceClip(idx, old),
//       ),
//     );
//   }
//
//   void addStickerOverlay(StickerOverlay overlay) {
//     final idx = selectedIndex.value;
//     if (idx < 0 || idx >= clips.length) return;
//
//     final before = clips[idx].copy();
//     final newOverlays = List<StickerOverlay>.from(clips[idx].stickerOverlays)
//       ..add(overlay);
//     clips[idx] = clips[idx].copyWith(stickerOverlays: newOverlays);
//     clips.refresh();
//
//     final after = clips[idx].copy();
//     addChange(
//       Change<ClipModel>(
//         before,
//             () => _replaceClip(idx, after),
//             (old) => _replaceClip(idx, old),
//       ),
//     );
//   }
//
//   // ────────────────────────────────────── AUDIO ──────────────────────────────────────
//   Future<void> pickBackgroundMusic() async {
//     try {
//       final res = await FilePicker.platform.pickFiles(type: FileType.audio);
//       if (res?.files.single.path != null) {
//         bgMusicPath = res!.files.single.path!;
//         Get.snackbar('Success', 'Background music selected');
//       }
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to pick music: $e');
//     }
//   }
//
//   Future<void> generateAndSaveTTS(String text) async {
//     try {
//       Get.dialog(
//         const AlertDialog(
//           backgroundColor: Color(0xFF1C1C1E),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircularProgressIndicator(color: Color(0xFF0A84FF)),
//               SizedBox(height: 16),
//               Text('Generating speech...', style: TextStyle(color: Colors.white)),
//             ],
//           ),
//         ),
//         barrierDismissible: false,
//       );
//
//       final dir = await getTemporaryDirectory();
//       final path = '${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
//
//       // TODO: Integrate actual TTS API (Google Cloud TTS, AWS Polly, etc.)
//       await Future.delayed(const Duration(seconds: 2));
//
//       ttsPath = path;
//       Get.back();
//       Get.snackbar('Success', 'Text-to-speech generated');
//     } catch (e) {
//       Get.back();
//       Get.snackbar('Error', 'TTS failed: $e');
//     }
//   }
//
//   // ────────────────────────────────────── EXPORT (ROBUST) ──────────────────────────────────────
//   Future<String?> exportProject() async {
//     if (clips.isEmpty) {
//       Get.snackbar('Export Error', 'No clips to export');
//       return null;
//     }
//
//     exporting.value = true;
//
//     try {
//       final tmpDir = await getTemporaryDirectory();
//       final processed = <String>[];
//
//       // Process each clip
//       for (int i = 0; i < clips.length; i++) {
//         final clip = clips[i];
//         final outPath = '${tmpDir.path}/clip_$i.mp4';
//
//         final cmd = await _buildClipCommand(clip, outPath);
//         final session = await FFmpegKit.execute(cmd);
//         final rc = await session.getReturnCode();
//
//         if (!ReturnCode.isSuccess(rc)) {
//           throw Exception('FFmpeg failed on clip $i');
//         }
//         processed.add(outPath);
//       }
//
//       // Concatenate clips
//       final concatFile = await _createConcatList(processed, tmpDir.path);
//       final finalOut = '${tmpDir.path}/final_export.mp4';
//
//       var concatCmd = '-f concat -safe 0 -i "$concatFile" -c copy -y "$finalOut"';
//       var session = await FFmpegKit.execute(concatCmd);
//       var rc = await session.getReturnCode();
//
//       if (!ReturnCode.isSuccess(rc)) {
//         // Fallback: re-encode
//         final inputs = processed.map((p) => '-i "$p"').join(' ');
//         final filter = List.generate(processed.length, (i) => '[$i:v][$i:a]').join();
//         concatCmd = '$inputs -filter_complex "$filter concat=n=${processed.length}:v=1:a=1[outv][outa]" '
//             '-map "[outv]" -map "[outa]" -c:v libx264 -preset fast -crf 23 -c:a aac -y "$finalOut"';
//         session = await FFmpegKit.execute(concatCmd);
//         rc = await session.getReturnCode();
//
//         if (!ReturnCode.isSuccess(rc)) {
//           throw Exception('Concatenation failed');
//         }
//       }
//
//       // Merge audio if needed
//       String outputPath = finalOut;
//       if (bgMusicPath != null || voiceoverPath != null || ttsPath != null) {
//         final merged = '${tmpDir.path}/final_with_audio.mp4';
//         final audioCmd = await _buildAudioMergeCommand(finalOut, merged);
//         final audioSession = await FFmpegKit.execute(audioCmd);
//         final audioRc = await audioSession.getReturnCode();
//
//         if (ReturnCode.isSuccess(audioRc)) {
//           outputPath = merged;
//         }
//       }
//
//       return outputPath;
//     } catch (e) {
//       Get.snackbar('Export Failed', e.toString());
//       return null;
//     } finally {
//       exporting.value = false;
//     }
//   }
//
//   Future<String> _buildClipCommand(ClipModel clip, String outPath) async {
//     final start = (clip.startMs / 1000).toStringAsFixed(3);
//     final duration = ((clip.endMs - clip.startMs) / 1000).toStringAsFixed(3);
//     final speed = clip.speed;
//
//     var vFilter = 'setpts=${(1 / speed).toStringAsFixed(6)}*PTS';
//     if (clip.flipHorizontal) vFilter += ',hflip';
//     if (clip.flipVertical) vFilter += ',vflip';
//     if (clip.rotation != 0) {
//       final rad = clip.rotation * 3.14159 / 180;
//       vFilter += ',rotate=$rad:ow=rotw($rad):oh=roth($rad)';
//     }
//     if (clip.filter.isNotEmpty) vFilter += ',${clip.filter}';
//
//     var aFilter = 'atempo=$speed,volume=${clip.volume}';
//
//     return '-ss $start -t $duration -i "${clip.path}" '
//         '-filter_complex "[0:v]$vFilter[v];[0:a]$aFilter[a]" '
//         '-map "[v]" -map "[a]" -c:v libx264 -preset fast -crf 23 -c:a aac -y "$outPath"';
//   }
//
//   Future<String> _createConcatList(List<String> files, String dir) async {
//     final path = '$dir/concat.txt';
//     final content = files.map((f) => "file '$f'").join('\n');
//     await File(path).writeAsString(content);
//     return path;
//   }
//
//   Future<String> _buildAudioMergeCommand(String videoPath, String outPath) async {
//     final inputs = ['-i "$videoPath"'];
//     if (bgMusicPath != null) inputs.add('-i "$bgMusicPath"');
//     if (voiceoverPath != null) inputs.add('-i "$voiceoverPath"');
//     if (ttsPath != null) inputs.add('-i "$ttsPath"');
//
//     final count = inputs.length;
//     final amix = List.generate(count, (i) => '[$i:a]').join();
//     final filter = '$amix amix=inputs=$count:duration=shortest[aout]';
//
//     return '${inputs.join(' ')} -filter_complex "$filter" '
//         '-map 0:v -map "[aout]" -c:v copy -c:a aac -shortest -y "$outPath"';
//   }
//
//   // ────────────────────────────────────── UTILITIES ──────────────────────────────────────
//   Future<void> denoiseClip() async {
//     Get.snackbar('Denoise', 'Audio denoising applied (placeholder)');
//   }
//
//   Future<void> autoCaption() async {
//     Get.snackbar('Auto Caption', 'Captions generated (placeholder)');
//   }
// }
//
// // ────────────────────────────────────── CLIP MODEL ──────────────────────────────────────
// // lib/models/clip_model.dart
//
//
// class ClipModel extends Equatable {
//   final String path;
//   final double startMs, endMs, originalDurationMs;
//   final double speed, volume;
//   final bool flipHorizontal, flipVertical;
//   final int rotation;
//   final String transitionType;
//   final double transitionDuration;
//   final String filterName;
//   final String filter;
//   final List<TextOverlay> textOverlays;
//   final List<StickerOverlay> stickerOverlays;
//   final List<String> thumbs;
//
//   const ClipModel({
//     required this.path,
//     this.startMs = 0,
//     required this.endMs,
//     required this.originalDurationMs,
//     this.speed = 1.0,
//     this.volume = 1.0,
//     this.flipHorizontal = false,
//     this.flipVertical = false,
//     this.rotation = 0,
//     this.transitionType = 'none',
//     this.transitionDuration = 0.5,
//     this.filterName = '',
//     this.filter = '',
//     this.textOverlays = const [],
//     this.stickerOverlays = const [],
//     this.thumbs = const [],
//   });
//
//   ClipModel copyWith({
//     String? path,
//     double? startMs,
//     double? endMs,
//     double? originalDurationMs,
//     double? speed,
//     double? volume,
//     bool? flipHorizontal,
//     bool? flipVertical,
//     int? rotation,
//     String? transitionType,
//     double? transitionDuration,
//     String? filterName,
//     String? filter,
//     List<TextOverlay>? textOverlays,
//     List<StickerOverlay>? stickerOverlays,
//     List<String>? thumbs,
//   }) {
//     return ClipModel(
//       path: path ?? this.path,
//       startMs: startMs ?? this.startMs,
//       endMs: endMs ?? this.endMs,
//       originalDurationMs: originalDurationMs ?? this.originalDurationMs,
//       speed: speed ?? this.speed,
//       volume: volume ?? this.volume,
//       flipHorizontal: flipHorizontal ?? this.flipHorizontal,
//       flipVertical: flipVertical ?? this.flipVertical,
//       rotation: rotation ?? this.rotation,
//       transitionType: transitionType ?? this.transitionType,
//       transitionDuration: transitionDuration ?? this.transitionDuration,
//       filterName: filterName ?? this.filterName,
//       filter: filter ?? this.filter,
//       textOverlays: textOverlays ?? this.textOverlays,
//       stickerOverlays: stickerOverlays ?? this.stickerOverlays,
//       thumbs: thumbs ?? this.thumbs,
//     );
//   }
//
//   @override
//   List<Object?> get props => [
//     path,
//     startMs,
//     endMs,
//     originalDurationMs,
//     speed,
//     volume,
//     flipHorizontal,
//     flipVertical,
//     rotation,
//     transitionType,
//     transitionDuration,
//     filterName,
//     filter,
//     textOverlays,
//     stickerOverlays,
//     thumbs,
//   ];
// }
//
// // ---------------------------------------------------------------------
// // TextOverlay / StickerOverlay (unchanged, just add Equatable)
// class TextOverlay extends Equatable {
//   final String text;
//   final double fontSize;
//   final int color;
//   final double startMs;
//   final double durationMs;
//   final double x, y; // 0-1 normalized
//
//   const TextOverlay({
//     required this.text,
//     this.fontSize = 32,
//     this.color = 0xFFFFFFFF,
//     this.startMs = 0,
//     this.durationMs = 5000,
//     this.x = 0.5,
//     this.y = 0.5,
//   });
//
//   TextOverlay copyWith({
//     String? text,
//     double? fontSize,
//     int? color,
//     double? startMs,
//     double? durationMs,
//     double? x,
//     double? y,
//   }) {
//     return TextOverlay(
//       text: text ?? this.text,
//       fontSize: fontSize ?? this.fontSize,
//       color: color ?? this.color,
//       startMs: startMs ?? this.startMs,
//       durationMs: durationMs ?? this.durationMs,
//       x: x ?? this.x,
//       y: y ?? this.y,
//     );
//   }
//
//   @override
//   List<Object?> get props => [text, fontSize, color, startMs, durationMs, x, y];
// }
//
// class StickerOverlay extends Equatable {
//   final String assetPath;
//   final double startMs;
//   final double durationMs;
//   final double x, y, scale, rotation;
//
//   const StickerOverlay({
//     required this.assetPath,
//     this.startMs = 0,
//     this.durationMs = 5000,
//     this.x = 0.5,
//     this.y = 0.5,
//     this.scale = 1.0,
//     this.rotation = 0,
//   });
//
//   StickerOverlay copyWith({
//     String? assetPath,
//     double? startMs,
//     double? durationMs,
//     double? x,
//     double? y,
//     double? scale,
//     double? rotation,
//   }) {
//     return StickerOverlay(
//       assetPath: assetPath ?? this.assetPath,
//       startMs: startMs ?? this.startMs,
//       durationMs: durationMs ?? this.durationMs,
//       x: x ?? this.x,
//       y: y ?? this.y,
//       scale: scale ?? this.scale,
//       rotation: rotation ?? this.rotation,
//     );
//   }
//
//   @override
//   List<Object?> get props => [assetPath, startMs, durationMs, x, y, scale, rotation];
// }
//
// // ────────────────────────────────────── TEXT OVERLAY ──────────────────────────────────────
// class TextOverlay {
//   final String text;
//   double x;
//   double y;
//   double fontSize;
//   int color;
//   double startMs;
//   double durationMs;
//
//   TextOverlay({
//     required this.text,
//     this.x = 0.5,
//     this.y = 0.5,
//     this.fontSize = 32,
//     this.color = 0xFFFFFFFF,
//     this.startMs = 0,
//     this.durationMs = 5000,
//   });
//
//   TextOverlay copy() {
//     return TextOverlay(
//       text: text,
//       x: x,
//       y: y,
//       fontSize: fontSize,
//       color: color,
//       startMs: startMs,
//       durationMs: durationMs,
//     );
//   }
// }
//
// // ────────────────────────────────────── STICKER OVERLAY ──────────────────────────────────────
// class StickerOverlay {
//   final String assetPath;
//   double x;
//   double y;
//   double scale;
//   double rotation;
//   double startMs;
//   double durationMs;
//
//   StickerOverlay({
//     required this.assetPath,
//     this.x = 0.5,
//     this.y = 0.5,
//     this.scale = 1.0,
//     this.rotation = 0.0,
//     this.startMs = 0,
//     this.durationMs = 5000,
//   });
//
//   StickerOverlay copy() {
//     return StickerOverlay(
//       assetPath: assetPath,
//       x: x,
//       y: y,
//       scale: scale,
//       rotation: rotation,
//       startMs: startMs,
//       durationMs: durationMs,
//     );
//   }
// }
//
// // ────────────────────────────────────── DRAGGABLE TIMELINE ──────────────────────────────────────
// class DraggableTimeline extends StatefulWidget {
//   final File videoFile;
//   final double durationMs;
//   final double startMs;
//   final double endMs;
//   final Function(double) onStartChanged;
//   final Function(double) onEndChanged;
//
//   const DraggableTimeline({
//     Key? key,
//     required this.videoFile,
//     required this.durationMs,
//     required this.startMs,
//     required this.endMs,
//     required this.onStartChanged,
//     required this.onEndChanged,
//   }) : super(key: key);
//
//   @override
//   State<DraggableTimeline> createState() => _DraggableTimelineState();
// }
//
// class _DraggableTimelineState extends State<DraggableTimeline> {
//   late double _localStart;
//   late double _localEnd;
//
//   @override
//   void initState() {
//     super.initState();
//     _localStart = widget.startMs;
//     _localEnd = widget.endMs;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 100,
//       decoration: BoxDecoration(
//         color: const Color(0xFF2C2C2E),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           final width = constraints.maxWidth;
//           final startPos = (_localStart / widget.durationMs) * width;
//           final endPos = (_localEnd / widget.durationMs) * width;
//
//           return Stack(
//             children: [
//               // Timeline background
//               Container(
//                 width: width,
//                 height: 80,
//                 margin: const EdgeInsets.symmetric(vertical: 10),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF3A3A3C),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Row(
//                   children: List.generate(
//                     10,
//                         (i) => Expanded(
//                       child: Container(
//                         margin: const EdgeInsets.all(2),
//                         color: Colors.white10,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//
//               // Selected region highlight
//               Positioned(
//                 left: startPos,
//                 top: 10,
//                 width: endPos - startPos,
//                 height: 80,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF0A84FF).withOpacity(0.3),
//                     border: Border.all(
//                       color: const Color(0xFF0A84FF),
//                       width: 2,
//                     ),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                 ),
//               ),
//
//               // Start handle
//               Positioned(
//                 left: startPos - 15,
//                 top: 5,
//                 child: GestureDetector(
//                   onHorizontalDragUpdate: (details) {
//                     setState(() {
//                       final newStart = (_localStart + (details.delta.dx / width) * widget.durationMs)
//                           .clamp(0.0, _localEnd - 100);
//                       _localStart = newStart;
//                       widget.onStartChanged(newStart);
//                     });
//                   },
//                   child: Container(
//                     width: 30,
//                     height: 90,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF0A84FF),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: const Center(
//                       child: Icon(
//                         Icons.drag_handle,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//
//               // End handle
//               Positioned(
//                 left: endPos - 15,
//                 top: 5,
//                 child: GestureDetector(
//                   onHorizontalDragUpdate: (details) {
//                     setState(() {
//                       final newEnd = (_localEnd + (details.delta.dx / width) * widget.durationMs)
//                           .clamp(_localStart + 100, widget.durationMs);
//                       _localEnd = newEnd;
//                       widget.onEndChanged(newEnd);
//                     });
//                   },
//                   child: Container(
//                     width: 30,
//                     height: 90,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF0A84FF),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: const Center(
//                       child: Icon(
//                         Icons.drag_handle,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }