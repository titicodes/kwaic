// // CRITICAL FIXES ONLY - Add these changes to your existing video_editor_screen.dart:
//
// // 1. ADD these two new state variables at the top with your other state variables:
// bool _isInitializing = false;
// bool _isDisposed = false;
//
// // 2. REPLACE your entire initState() method with this:
// @override
// void initState() {
//   super.initState();
//   _isDisposed = false;
//
//   if (widget.initialVideos != null && widget.initialVideos!.isNotEmpty) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted || _isDisposed) return;
//
//       Future.delayed(const Duration(milliseconds: 200), () {
//         if (!mounted || _isDisposed) return;
//         _loadInitialVideosSequentially();
//       });
//     });
//   }
// }
//
// // 3. ADD this NEW method (place it after initState):
// Future<void> _loadInitialVideosSequentially() async {
//   if (_isInitializing || _isDisposed) return;
//
//   if (mounted) setState(() => _isInitializing = true);
//   _showLoading();
//
//   try {
//     Duration totalEnd = Duration.zero;
//
//     // Load videos ONE AT A TIME to avoid race conditions
//     for (int i = 0; i < widget.initialVideos!.length; i++) {
//       if (_isDisposed || !mounted) break;
//
//       final xfile = widget.initialVideos![i];
//       final file = File(xfile.path);
//
//       if (!await file.exists()) continue;
//
//       final controller = VideoPlayerController.file(file);
//
//       try {
//         await controller.initialize();
//
//         if (_isDisposed || !mounted) {
//           await controller.dispose();
//           break;
//         }
//
//         final duration = controller.value.duration;
//
//         final dir = await getTemporaryDirectory();
//         final thumbnailFutures = List.generate(5, (idx) async {
//           try {
//             final ms = (duration.inMilliseconds * idx / 4).round();
//             return await VideoThumbnail.thumbnailFile(
//               video: xfile.path,
//               thumbnailPath: dir.path,
//               imageFormat: ImageFormat.JPEG,
//               maxWidth: 120,
//               timeMs: ms,
//               quality: 75,
//             );
//           } catch (e) {
//             return null;
//           }
//         });
//
//         final thumbnailPaths = (await Future.wait(thumbnailFutures))
//             .whereType<String>()
//             .toList();
//
//         final item = TimelineItem(
//           id: '${DateTime.now().millisecondsSinceEpoch}_$i',
//           type: TimelineItemType.video,
//           file: file,
//           startTime: totalEnd,
//           duration: duration,
//           originalDuration: duration,
//           trimStart: Duration.zero,
//           trimEnd: duration,
//           thumbnailPaths: thumbnailPaths,
//           volume: 1.0,
//           speed: 1.0,
//         );
//
//         if (_isDisposed || !mounted) {
//           await controller.dispose();
//           break;
//         }
//
//         _controllers[item.id] = controller;
//         clips.add(item);
//         totalEnd += duration;
//
//         if (Platform.isAndroid) {
//           await _forceFirstFrameAndroid(controller);
//         }
//
//       } catch (e) {
//         debugPrint('Failed to initialize video $i: $e');
//         await controller.dispose();
//       }
//     }
//
//     if (!mounted || _isDisposed) return;
//
//     setState(() {
//       clips.sort((a, b) => a.startTime.compareTo(b.startTime));
//
//       if (clips.isNotEmpty) {
//         final first = clips.first;
//         selectedClip = int.tryParse(first.id);
//         _activeVideoController = _controllers[first.id];
//         _activeItem = first;
//         playheadPosition = Duration.zero;
//       }
//
//       _isInitializing = false;
//     });
//
//     await Future.delayed(const Duration(milliseconds: 100));
//     if (mounted && !_isDisposed) {
//       _updatePreview();
//       _hideLoading();
//       _showMessage('Loaded ${clips.length} video(s)');
//     }
//
//   } catch (e) {
//     if (mounted && !_isDisposed) {
//       setState(() => _isInitializing = false);
//       _hideLoading();
//       _showError('Failed to load videos: $e');
//     }
//   }
// }
//
// // 4. REPLACE the FIRST LINE of your dispose() method:
// @override
// void dispose() {
//   _isDisposed = true;  // ADD THIS LINE FIRST
//
//   // ... keep all your existing disposal code ...
// }
//
// // 5. UPDATE your _updatePreview() method - add this check at the very start:
// void _updatePreview() {
//   if (!mounted || _isDisposed) return;  // ADD THIS LINE
//
//   // ... keep all your existing preview code ...
// }
//
// // 6. UPDATE all your setState() calls that happen in async callbacks.
// //    Add this check BEFORE each setState:
// //    if (!mounted || _isDisposed) return;
//
// // Example for _addVideo:
// Future<void> _addVideo() async {
//   final XFile? file = await _picker.pickVideo(
//     source: ImageSource.gallery,
//     maxDuration: const Duration(minutes: 10),
//   );
//   if (file == null) return;
//
//   _showLoading();
//
//   try {
//     final result = await compute(_processVideoInBackground, file.path);
//
//     if (!mounted || _isDisposed) {  // ADD THIS CHECK
//       await result.controller.dispose();
//       return;
//     }
//
//     setState(() {
//       clips.add(result.item);
//       clips.sort((a, b) => a.startTime.compareTo(b.startTime));
//       selectedClip = int.parse(result.item.id);
//       _activeItem = result.item;
//       playheadPosition = result.item.startTime;
//       timelineOffset = result.item.startTime.inMilliseconds / 1000 * pixelsPerSecond;
//     });
//
//     _controllers[result.item.id] = result.controller;
//
//     if (Platform.isAndroid) {
//       unawaited(_forceFirstFrameAndroid(result.controller));
//     }
//
//     _updatePreview();
//     _hideLoading();
//     _showMessage('Video added successfully!');
//   } catch (e) {
//     _hideLoading();
//     _showError('Failed to add video: $e');
//   }
// }
//
// // 7. UPDATE _showError and _showMessage methods:
// void _showError(String msg) {
//   if (!mounted || _isDisposed) return;  // ADD THIS
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(content: Text(msg), backgroundColor: Colors.red),
//   );
// }
//
// void _showMessage(String msg) {
//   if (!mounted || _isDisposed) return;  // ADD THIS
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(content: Text(msg), backgroundColor: const Color(0xFF10B981)),
//   );
// }
//
// // 8. UPDATE _updateThumbnails method:
// Future<void> _updateThumbnails(TimelineItem item) async {
//   if (item.type != TimelineItemType.video || item.file == null) return;
//   final dir = await getTemporaryDirectory();
//   final thumbs = <String>[];
//   final effectiveDur = item.duration.inMilliseconds;
//   for (int i = 0; i < 5; i++) {
//     final ms = item.trimStart.inMilliseconds + (effectiveDur * i / 4).round();
//     final path = await VideoThumbnail.thumbnailFile(
//       video: item.file!.path,
//       thumbnailPath: dir.path,
//       imageFormat: ImageFormat.PNG,
//       maxWidth: 100,
//       timeMs: ms,
//     );
//     if (path != null) thumbs.add(path);
//   }
//   if (mounted && !_isDisposed) {  // ADD THIS CHECK
//     setState(() {
//       item.thumbnailPaths = thumbs;
//     });
//   }
// }
//
// // SUMMARY OF CHANGES:
// // ==================
// // 1. Added _isDisposed flag to track widget lifecycle
// // 2. Changed parallel video loading to SEQUENTIAL (one at a time)
// // 3. Added safety checks before all setState calls in async methods
// // 4. Increased initial delay to 200ms for slower devices
// // 5. Proper cleanup if widget is disposed during loading
//
// // KEEP EVERYTHING ELSE IN YOUR ORIGINAL FILE EXACTLY THE SAME!
// // This only fixes the initialization race condition issues.