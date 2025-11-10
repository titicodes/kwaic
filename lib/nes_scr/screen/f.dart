// import 'dart:async';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:video_player/video_player.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
// import 'dart:math' as math;
//
// import '../model/eitor_state.dart';
// import '../model/timeline_item.dart';
//
// class VideoEditorScreen extends StatefulWidget {
//   const VideoEditorScreen({super.key});
//
//   @override
//   State<VideoEditorScreen> createState() => _VideoEditorScreenState();
// }
//
// class _VideoEditorScreenState extends State<VideoEditorScreen>
//     with TickerProviderStateMixin {
//   bool isPlaying = false;
//   Duration playheadPosition = const Duration(seconds: 1);
//   int? selectedClip;
//   final double totalDuration = 12.0;
//   final double pixelsPerSecond = 80.0;
//   Timer? playbackTimer;
//   final ScrollController timelineScrollController = ScrollController();
//   final ImagePicker _picker = ImagePicker();
//   List<TimelineItem> clips = [];
//   List<TimelineItem> audioItems = [];
//   List<TimelineItem> textItems = [];
//   List<TimelineItem> overlayItems = [];
//   final Map<String, VideoPlayerController> _controllers = {};
//   final Map<String, dynamic> _audioControllers = {};
//   VideoPlayerController? _activePreviewController;
//   TimelineItem? _activeItem;
//   late Ticker _playbackTicker;
//   int _lastFrameTime = 0;
//   double _initialRotation = 0.0;
//   double _initialScale = 1.0;
//
//   List<EditorState> history = [];
//   int historyIndex = -1;
//
//   @override
//   void initState() {
//     super.initState();
//     _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
//     _playbackTicker = createTicker(_playbackFrame)..start();
//   }
//
//   @override
//   void dispose() {
//     _playbackTicker.dispose();
//     timelineScrollController.dispose();
//     playbackTimer?.cancel();
//     for (final c in _controllers.values) {
//       c.dispose();
//     }
//     for (final c in _audioControllers.values) {
//       if (c != null) c.dispose();
//     }
//     super.dispose();
//   }
//
//
//   // Update the _saveToHistory method:
//   void _saveToHistory() {
//     final currentState = EditorState(
//       clips: clips.map((c) => c.copyWith()).toList(),
//       audioItems: audioItems.map((a) => a.copyWith()).toList(),
//       textItems: textItems.map((t) => t.copyWith()).toList(),
//       overlayItems: overlayItems.map((o) => o.copyWith()).toList(),
//       selectedClip: selectedClip,
//       playheadPosition: playheadPosition,
//     );
//
//     if (historyIndex < history.length - 1) {
//       history = history.sublist(0, historyIndex + 1);
//     }
//     history.add(currentState);
//     historyIndex = history.length - 1;
//   }
//
// // Update the _undo method:
//   void _undo() {
//     if (historyIndex > 0) {
//       historyIndex--;
//       final state = history[historyIndex];
//       setState(() {
//         clips = state.clips.map((c) => c.copyWith()).toList();
//         audioItems = state.audioItems.map((a) => a.copyWith()).toList();
//         textItems = state.textItems.map((t) => t.copyWith()).toList();
//         overlayItems = state.overlayItems.map((o) => o.copyWith()).toList();
//         selectedClip = state.selectedClip;
//         playheadPosition = state.playheadPosition;
//       });
//     }
//   }
//
// // Update the _redo method:
//   void _redo() {
//     if (historyIndex < history.length - 1) {
//       historyIndex++;
//       final state = history[historyIndex];
//       setState(() {
//         clips = state.clips.map((c) => c.copyWith()).toList();
//         audioItems = state.audioItems.map((a) => a.copyWith()).toList();
//         textItems = state.textItems.map((t) => t.copyWith()).toList();
//         overlayItems = state.overlayItems.map((o) => o.copyWith()).toList();
//         selectedClip = state.selectedClip;
//         playheadPosition = state.playheadPosition;
//       });
//     }
//   }
//
//   void _playbackFrame(Duration elapsed) {
//     if (!mounted || !isPlaying) return;
//     final now = DateTime.now().millisecondsSinceEpoch;
//     final deltaMs = now - _lastFrameTime;
//     _lastFrameTime = now;
//     if (deltaMs <= 0 || deltaMs > 100) return;
//     setState(() {
//       playheadPosition += Duration(milliseconds: deltaMs);
//       if (playheadPosition.inMilliseconds >= totalDuration * 1000) {
//         playheadPosition = Duration(
//           milliseconds: (totalDuration * 1000).toInt(),
//         );
//         isPlaying = false;
//         _playbackTicker.stop();
//       }
//     });
//     _autoScrollTimeline();
//     _updatePreview();
//   }
//
//
//   Widget _buildTopBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: const BoxDecoration(
//         border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: const [
//               Icon(Icons.close, size: 22),
//               SizedBox(width: 12),
//               Icon(Icons.help_outline, size: 22),
//             ],
//           ),
//           Expanded(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF2A2A2A),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: const [
//                       Icon(Icons.diamond, size: 12, color: Color(0xFF00D9FF)),
//                       SizedBox(width: 4),
//                       Text('free', style: TextStyle(fontSize: 11)),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF2A2A2A),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: const [
//                       Text('1080P', style: TextStyle(fontSize: 11)),
//                       SizedBox(width: 4),
//                       Icon(Icons.arrow_drop_down, size: 16),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 GestureDetector(
//                   onTap: () => _showMessage('Exporting...'),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF00D9FF),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: const Text(
//                       'Export',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _autoScrollTimeline() {
//     if (!timelineScrollController.hasClients) return;
//     const double leftPadding = 136.0;
//     final double playheadPixelPosition =
//         playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
//     final double targetScroll =
//         leftPadding +
//             playheadPixelPosition -
//             MediaQuery.of(context).size.width / 2;
//     final double maxScroll = timelineScrollController.position.maxScrollExtent;
//     final double clampedScroll = targetScroll.clamp(0.0, maxScroll);
//     if ((clampedScroll - timelineScrollController.offset).abs() > 5) {
//       timelineScrollController.jumpTo(clampedScroll);
//     }
//   }
//
//   void _updatePreview() {
//     if (!mounted) return;
//     final activeVideo = _findActiveVideo();
//     setState(() => _activeItem = activeVideo);
//     if (activeVideo != null && _controllers.containsKey(activeVideo.id)) {
//       final ctrl = _controllers[activeVideo.id]!;
//       final localTime = playheadPosition - activeVideo.startTime;
//       final sourceTime =
//           activeVideo.trimStart +
//               Duration(
//                 milliseconds:
//                 (localTime.inMilliseconds * activeVideo.speed).round(),
//               );
//       if ((ctrl.value.position - sourceTime).inMilliseconds.abs() > 100) {
//         ctrl.seekTo(sourceTime);
//       }
//       ctrl.setPlaybackSpeed(activeVideo.speed);
//       ctrl.setVolume(activeVideo.volume);
//       if (isPlaying && !ctrl.value.isPlaying) {
//         ctrl.play();
//       }
//       if (!isPlaying && ctrl.value.isPlaying) {
//         ctrl.pause();
//       }
//       if (_activePreviewController != ctrl) {
//         _activePreviewController?.pause();
//         setState(() => _activePreviewController = ctrl);
//       }
//     } else {
//       _activePreviewController?.pause();
//       if (_activePreviewController != null) {
//         setState(() => _activePreviewController = null);
//       }
//     }
//   }
//
//   TimelineItem? _findActiveVideo() {
//     for (final item in clips) {
//       final effectiveDur = Duration(
//         milliseconds: (item.duration.inMilliseconds / item.speed).round(),
//       );
//       if (playheadPosition >= item.startTime &&
//           playheadPosition < item.startTime + effectiveDur) {
//         return item;
//       }
//     }
//     return null;
//   }
//
//   void togglePlayPause() {
//     setState(() {
//       isPlaying = !isPlaying;
//       if (isPlaying &&
//           playheadPosition.inMilliseconds >= totalDuration * 1000) {
//         playheadPosition = Duration.zero;
//       }
//     });
//     if (isPlaying) {
//       _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
//       _playbackTicker.start();
//     } else {
//       _playbackTicker.stop();
//     }
//   }
//
//   void handleTimelineClick(double localX) {
//     if (timelineScrollController.hasClients) {
//       final scrollOffset = timelineScrollController.offset;
//       final clickPosition = (localX + scrollOffset - 136) / pixelsPerSecond;
//       setState(() {
//         playheadPosition = Duration(
//           milliseconds:
//           (clickPosition * 1000).clamp(0.0, totalDuration * 1000).toInt(),
//         );
//         isPlaying = false;
//       });
//       playbackTimer?.cancel();
//     }
//   }
//
//   TimelineItem? getClipAtPlayhead() {
//     for (var clip in clips) {
//       if (playheadPosition >= clip.startTime &&
//           playheadPosition < clip.startTime + clip.duration) {
//         return clip;
//       }
//     }
//     return null;
//   }
//
//   void splitClipAtPlayhead() {
//     final clipToSplit = getClipAtPlayhead();
//     if (clipToSplit != null &&
//         playheadPosition > clipToSplit.startTime &&
//         playheadPosition < clipToSplit.startTime + clipToSplit.duration) {
//       final splitPoint = playheadPosition - clipToSplit.startTime;
//       setState(() {
//         clips.removeWhere((c) => c.id == clipToSplit.id);
//         clips.add(clipToSplit.copyWith(duration: splitPoint));
//         clips.add(
//           clipToSplit.copyWith(
//             id: DateTime.now().millisecondsSinceEpoch.toString(),
//             startTime: playheadPosition,
//             duration: clipToSplit.duration - splitPoint,
//           ),
//         );
//         clips.sort((a, b) => a.startTime.compareTo(b.startTime));
//       });
//       _showMessage('Clip split');
//     }
//   }
//
//   Future<void> _addVideo() async {
//     final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
//     if (file == null) return;
//
//     _showLoading();
//     try {
//       final tempCtrl = VideoPlayerController.file(File(file.path));
//       await tempCtrl.initialize();
//       final duration = tempCtrl.value.duration;
//
//       final dir = await getTemporaryDirectory();
//       final thumbs = <String>[];
//       for (int i = 0; i < 10; i++) {
//         final ms = (duration.inMilliseconds * i / 9).round();
//         final path = await VideoThumbnail.thumbnailFile(
//           video: file.path,
//           thumbnailPath: dir.path,
//           imageFormat: ImageFormat.PNG,
//           maxWidth: 100,
//           timeMs: ms,
//         );
//         if (path != null) thumbs.add(path);
//       }
//
//       final startTime =
//       clips.isEmpty
//           ? Duration.zero
//           : clips
//           .map((i) => i.startTime + i.duration)
//           .reduce((a, b) => a > b ? a : b);
//
//       final item = TimelineItem(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         type: TimelineItemType.video,
//         file: File(file.path),
//         startTime: startTime,
//         duration: duration,
//         originalDuration: duration,
//         thumbnailPaths: thumbs,
//       );
//
//       _controllers[item.id] = tempCtrl;
//       await tempCtrl.setLooping(false);
//
//       setState(() {
//         clips.add(item);
//         selectedClip = int.parse(item.id);
//         _activePreviewController = tempCtrl;
//       });
//       _hideLoading();
//       _showMessage('Video added: ${file.name}');
//     } catch (e) {
//       _hideLoading();
//       _showError('Failed to pick video: $e');
//     }
//   }
//
//   Future<void> _addAudio() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.audio,
//       allowMultiple: false,
//     );
//     if (result == null || result.files.isEmpty) return;
//
//     final filePath = result.files.first.path;
//     if (filePath == null) {
//       _showError('Invalid file path');
//       return;
//     }
//
//     final item = TimelineItem(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       type: TimelineItemType.audio,
//       file: File(filePath),
//       startTime: Duration.zero,
//       duration: const Duration(seconds: 10),
//       originalDuration: const Duration(seconds: 10),
//     );
//
//     setState(() {
//       audioItems.add(item);
//       selectedClip = int.parse(item.id);
//     });
//     _showMessage('Audio added: ${result.files.first.name}');
//   }
//
//   Future<void> _addImage() async {
//     final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
//     if (file == null) return;
//
//     final item = TimelineItem(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       type: TimelineItemType.image,
//       file: File(file.path),
//       startTime: playheadPosition,
//       duration: const Duration(seconds: 5),
//       originalDuration: const Duration(seconds: 5),
//       x: 50,
//       y: 100,
//     );
//
//     setState(() {
//       overlayItems.add(item);
//       selectedClip = int.parse(item.id);
//     });
//     _showMessage('Image added');
//   }
//
//   Future<void> _addText() async {
//     final item = TimelineItem(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       type: TimelineItemType.text,
//       text: "New Text",
//       startTime: playheadPosition,
//       duration: const Duration(seconds: 5),
//       originalDuration: const Duration(seconds: 5),
//       x: 100,
//       y: 200,
//       textColor: Colors.white,
//       fontSize: 32,
//     );
//
//     setState(() {
//       textItems.add(item);
//       selectedClip = int.parse(item.id);
//     });
//     _showMessage('Text added');
//
//     // Show text editor after adding text
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (textItems.isNotEmpty) _showTextEditor(textItems.last);
//     });
//   }
//
//   void _showTextEditor(TimelineItem item) {
//     final controller = TextEditingController(text: item.text);
//     Color tempColor = item.textColor ?? Colors.white;
//     double tempSize = item.fontSize ?? 32;
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: const Color(0xFF1A1A1A),
//       builder:
//           (ctx) => StatefulBuilder(
//         builder:
//             (context, setModalState) => Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//           ),
//           child: Container(
//             height: 450,
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 const Text(
//                   'Edit Text',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: controller,
//                   style: const TextStyle(color: Colors.white),
//                   decoration: const InputDecoration(
//                     hintText: 'Enter text',
//                     hintStyle: TextStyle(color: Colors.white54),
//                     enabledBorder: UnderlineInputBorder(
//                       borderSide: BorderSide(color: Colors.white54),
//                     ),
//                     focusedBorder: UnderlineInputBorder(
//                       borderSide: BorderSide(color: Color(0xFF00D9FF)),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   'Color',
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 const SizedBox(height: 8),
//                 Wrap(
//                   spacing: 8,
//                   children:
//                   [
//                     Colors.white,
//                     Colors.red,
//                     Colors.yellow,
//                     Colors.blue,
//                     Colors.green,
//                     Colors.purple,
//                     Colors.orange,
//                     Colors.pink,
//                   ].map((c) {
//                     final isSelected = c == tempColor;
//                     return GestureDetector(
//                       onTap:
//                           () => setModalState(() => tempColor = c),
//                       child: Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: c,
//                           shape: BoxShape.circle,
//                           border: Border.all(
//                             color:
//                             isSelected
//                                 ? const Color(0xFF00D9FF)
//                                 : Colors.transparent,
//                             width: 3,
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   'Font Size',
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 Slider(
//                   value: tempSize,
//                   min: 10,
//                   max: 100,
//                   activeColor: const Color(0xFF00D9FF),
//                   onChanged: (v) => setModalState(() => tempSize = v),
//                 ),
//                 Text(
//                   '${tempSize.toInt()}',
//                   style: const TextStyle(color: Colors.white),
//                 ),
//                 const Spacer(),
//                 ElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       item.text = controller.text;
//                       item.textColor = tempColor;
//                       item.fontSize = tempSize;
//                     });
//                     Navigator.pop(ctx);
//                     _showMessage('Text updated');
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF00D9FF),
//                     foregroundColor: Colors.black,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 32,
//                       vertical: 12,
//                     ),
//                   ),
//                   child: const Text(
//                     'Apply',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showLoading() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder:
//           (_) => const Center(
//         child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
//       ),
//     );
//   }
//
//   void _hideLoading() {
//     if (Navigator.canPop(context)) Navigator.pop(context);
//   }
//
//   void _showError(String msg) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
//   }
//
//   void _showMessage(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), backgroundColor: const Color(0xFF10B981)),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final clipAtPlayhead = getClipAtPlayhead();
//     final showSplitButton = clipAtPlayhead != null && !isPlaying;
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildTopBar(),
//             Expanded(child: _buildVideoPreview()),
//             _buildPlaybackControls(),
//             _buildTimeDisplay(),
//             _buildTimelineSection(showSplitButton),
//             if (selectedClip != null) _buildBottomToolbar(showSplitButton),
//             _buildBottomNavigation(),
//             _buildSystemNavigation(),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//
//   Widget _buildVideoPreview() {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.4, // Larger preview area
//       color: Colors.black,
//       child: Center(
//         child: AspectRatio(
//           aspectRatio: 9 / 16,
//           child: Container(
//             margin: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.black,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   if (_activePreviewController != null &&
//                       _activePreviewController!.value.isInitialized)
//                     VideoPlayer(_activePreviewController!)
//                   else
//                     Container(
//                       color: Colors.black,
//                       child: Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(
//                               Icons.video_library,
//                               size: 60,
//                               color: Colors.white24,
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               clips.isEmpty ? 'Add a video to start editing' : 'Video Preview',
//                               style: const TextStyle(color: Colors.white54, fontSize: 14),
//                               textAlign: TextAlign.center,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ..._buildTextOverlays(),
//                   ..._buildImageOverlays(),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   List<Widget> _buildTextOverlays() {
//     final List<Widget> overlays = [];
//     for (final item in textItems) {
//       if (playheadPosition >= item.startTime &&
//           playheadPosition < item.startTime + item.duration) {
//         Widget textWidget = Transform.rotate(
//           angle: item.rotation * math.pi / 180,
//           child: Transform.scale(
//             scale: item.scale,
//             child: Text(
//               item.text ?? '',
//               style: TextStyle(
//                 color: item.textColor ?? Colors.white,
//                 fontSize: item.fontSize ?? 32,
//                 fontWeight: FontWeight.bold,
//                 shadows: [
//                   Shadow(
//                     offset: const Offset(1, 1),
//                     blurRadius: 3,
//                     color: Colors.black.withOpacity(0.5),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//         if (selectedClip == int.tryParse(item.id)) {
//           textWidget = GestureDetector(
//             onPanUpdate: (d) {
//               setState(() {
//                 item.x = (item.x ?? 0) + d.delta.dx;
//                 item.y = (item.y ?? 0) + d.delta.dy;
//               });
//             },
//             onScaleStart: (d) {
//               _initialRotation = item.rotation;
//               _initialScale = item.scale;
//             },
//             onScaleUpdate: (d) {
//               setState(() {
//                 item.rotation = _initialRotation + d.rotation * 180 / math.pi;
//                 item.scale = (_initialScale * d.scale).clamp(0.5, 3.0);
//               });
//             },
//             child: Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: const Color(0xFF00D9FF), width: 2),
//               ),
//               child: textWidget,
//             ),
//           );
//         }
//         overlays.add(
//           Positioned(
//             left: item.x ?? 100,
//             top: item.y ?? 200,
//             child: textWidget,
//           ),
//         );
//       }
//     }
//     return overlays;
//   }
//
//   List<Widget> _buildImageOverlays() {
//     final List<Widget> overlays = [];
//     for (final item in overlayItems) {
//       if (playheadPosition >= item.startTime &&
//           playheadPosition < item.startTime + item.duration) {
//         if (item.file != null) {
//           Widget imageWidget = Transform.rotate(
//             angle: item.rotation * math.pi / 180,
//             child: Transform.scale(
//               scale: item.scale,
//               child: Image.file(
//                 item.file!,
//                 width: 200,
//                 height: 200,
//                 fit: BoxFit.contain,
//               ),
//             ),
//           );
//           if (selectedClip == int.tryParse(item.id)) {
//             imageWidget = GestureDetector(
//               onPanUpdate: (d) {
//                 setState(() {
//                   item.x = (item.x ?? 0) + d.delta.dx;
//                   item.y = (item.y ?? 0) + d.delta.dy;
//                 });
//               },
//               onScaleStart: (d) {
//                 _initialRotation = item.rotation;
//                 _initialScale = item.scale;
//               },
//               onScaleUpdate: (d) {
//                 setState(() {
//                   item.rotation = _initialRotation + d.rotation * 180 / math.pi;
//                   item.scale = (_initialScale * d.scale).clamp(0.3, 2.0);
//                 });
//               },
//               child: Container(
//                 decoration: BoxDecoration(
//                   border: Border.all(color: const Color(0xFF00D9FF), width: 2),
//                 ),
//                 child: imageWidget,
//               ),
//             );
//           }
//           overlays.add(
//             Positioned(
//               left: item.x ?? 50,
//               top: item.y ?? 100,
//               child: imageWidget,
//             ),
//           );
//         }
//       }
//     }
//     return overlays;
//   }
//
//   Widget _buildPlaybackControls() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: const BoxDecoration(
//         border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Icon(Icons.fullscreen, size: 20),
//           GestureDetector(
//             onTap: togglePlayPause,
//             child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 32),
//           ),
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF2A2A2A),
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: const Text('📱 ON', style: TextStyle(fontSize: 11)),
//               ),
//               const SizedBox(width: 16),
//               const Icon(Icons.rotate_left, size: 20),
//               const SizedBox(width: 16),
//               const Icon(Icons.rotate_right, size: 20),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTimeDisplay() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       color: const Color(0xFF0A0A0A),
//       child: Row(
//         children: [
//           Text(
//             formatTime(playheadPosition.inMilliseconds / 1000),
//             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//           ),
//           const Text(
//             ' / ',
//             style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
//           ),
//           Text(
//             formatTime(totalDuration),
//             style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String formatTime(double seconds) {
//     final mins = (seconds / 60).floor();
//     final secs = (seconds % 60).floor();
//     return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
//   }
//
//
//
//   Widget _buildTimelineSection(bool showSplitButton) {
//     return Container(
//       color: const Color(0xFF0A0A0A),
//       height: 140, // Adjusted height
//       child: Column(
//         children: [
//           // Time markers row
//           Container(
//             height: 30,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 Text(
//                   formatTime(playheadPosition.inMilliseconds / 1000),
//                   style: const TextStyle(fontSize: 12, color: Colors.white),
//                 ),
//                 const Text(' | ', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
//                 Text(
//                   formatTime(totalDuration),
//                   style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
//                 ),
//                 const Spacer(),
//                 const Icon(Icons.crop, size: 18, color: Colors.white),
//                 const SizedBox(width: 16),
//                 const Icon(Icons.zoom_out_map, size: 18, color: Colors.white),
//               ],
//             ),
//           ),
//
//           // Timeline content
//           Expanded(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Left controls section (fixed width)
//                 Container(
//                   width: 100,
//                   color: const Color(0xFF1A1A1A),
//                   child: Column(
//                     children: [
//                       _buildMuteButton(),
//                       const SizedBox(height: 8),
//                       _buildCoverButton(),
//                     ],
//                   ),
//                 ),
//
//                 // Timeline tracks (scrollable)
//                 Expanded(
//                   child: SingleChildScrollView(
//                     controller: timelineScrollController,
//                     scrollDirection: Axis.horizontal,
//                     child: Stack(
//                       children: [
//                         // Tracks container
//                         Container(
//                           padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
//                           child: Column(
//                             children: [
//                               // Video track
//                               SizedBox(
//                                 height: 60,
//                                 child: Row(
//                                   children: [
//                                     ...clips.map((clip) => _buildVideoClip(clip)).toList(),
//                                     _buildAddClipButton(),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//
//                               // Audio track
//                               _buildAudioTrack(),
//                             ],
//                           ),
//                         ),
//
//                         // Playhead
//                         Positioned(
//                           left: 136 + (playheadPosition.inMilliseconds / 1000) * pixelsPerSecond,
//                           top: 0,
//                           bottom: 0,
//                           child: Container(
//                             width: 2,
//                             color: const Color(0xFF8B5CF6), // Purple color
//                             child: Column(
//                               children: [
//                                 const SizedBox(height: 8),
//                                 Container(
//                                   width: 16,
//                                   height: 16,
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFF8B5CF6),
//                                     shape: BoxShape.circle,
//                                     border: Border.all(color: Colors.white, width: 2),
//                                   ),
//                                   child: const Icon(
//                                     Icons.lightbulb,
//                                     size: 10,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//
//                         // Split button
//                         if (showSplitButton)
//                           Positioned(
//                             left: 136 + (playheadPosition.inMilliseconds / 1000) * pixelsPerSecond,
//                             top: 20,
//                             child: Transform.translate(
//                               offset: const Offset(-40, 0),
//                               child: GestureDetector(
//                                 onTap: () {
//                                   _saveToHistory();
//                                   splitClipAtPlayhead();
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFF00D9FF),
//                                     borderRadius: BorderRadius.circular(14),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: const Color(0xFF00D9FF).withOpacity(0.3),
//                                         blurRadius: 6,
//                                         spreadRadius: 1,
//                                       ),
//                                     ],
//                                   ),
//                                   child: const Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Icon(Icons.content_cut, size: 12, color: Colors.black),
//                                       SizedBox(width: 3),
//                                       Text('Split', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMuteButton() {
//     return Container(
//       height: 50,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: Row(
//         children: [
//           const Icon(Icons.volume_up, size: 18, color: Colors.white),
//           const SizedBox(width: 6),
//           const Text('Sound ON', style: TextStyle(fontSize: 12, color: Colors.white)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCoverButton() {
//     return Container(
//       height: 50,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 30,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(4),
//               border: Border.all(color: Colors.white30),
//             ),
//             child: clips.isNotEmpty && clips[0].thumbnailPaths.isNotEmpty
//                 ? ClipRRect(
//               borderRadius: BorderRadius.circular(4),
//               child: Image.file(
//                 File(clips[0].thumbnailPaths[0]),
//                 fit: BoxFit.cover,
//               ),
//             )
//                 : const Center(
//               child: Icon(Icons.image, size: 16, color: Colors.white30),
//             ),
//           ),
//           const SizedBox(width: 6),
//           const Text('Cover', style: TextStyle(fontSize: 12, color: Colors.white)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildVideoClip(TimelineItem clip) {
//     final isSelected = selectedClip == int.tryParse(clip.id);
//     final clipWidth = (clip.duration.inMilliseconds / 1000 * pixelsPerSecond).clamp(60.0, double.infinity);
//
//     return Container(
//       width: clipWidth,
//       height: 56,
//       margin: const EdgeInsets.only(right: 4),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(4),
//         border: Border.all(
//           color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
//           width: 2,
//         ),
//       ),
//       child: clip.thumbnailPaths.isNotEmpty
//           ? ClipRRect(
//         borderRadius: BorderRadius.circular(4),
//         child: Image.file(
//           File(clip.thumbnailPaths.first),
//           fit: BoxFit.cover,
//         ),
//       )
//           : Container(
//         color: const Color(0xFF2A2A2A),
//         child: const Center(
//           child: Icon(Icons.videocam, color: Colors.white54, size: 18),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAddClipButton() {
//     return GestureDetector(
//       onTap: () {
//         _saveToHistory();
//         _addVideo();
//       },
//       child: Container(
//         width: 50,
//         height: 56,
//         margin: const EdgeInsets.only(left: 8),
//         decoration: BoxDecoration(
//           color: const Color(0xFF2A2A2A),
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(color: Colors.white12),
//         ),
//         child: const Center(
//           child: Icon(Icons.add, color: Colors.white, size: 24),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAudioTrack() {
//     return Container(
//       height: 30,
//       decoration: BoxDecoration(
//         color: const Color(0xFF1A1A1A),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: InkWell(
//         onTap: () {
//           _saveToHistory();
//           _addAudio();
//         },
//         child: const Padding(
//           padding: EdgeInsets.symmetric(horizontal: 12),
//           child: Row(
//             children: [
//               Icon(Icons.audiotrack, size: 16, color: Colors.white54),
//               SizedBox(width: 6),
//               Text('Add Audio', style: TextStyle(fontSize: 12, color: Colors.white54)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   Widget _buildBottomToolbar(bool showSplitButton) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: const BoxDecoration(
//         color: Color(0xFF1A1A1A),
//         border: Border(top: BorderSide(color: Color(0xFF444444))),
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: [
//             _buildToolbarButton(
//               Icons.audiotrack,
//               'Sounds',
//               onTap: () => _showMessage('Sounds'),
//             ),
//             _buildToolbarButton(
//               Icons.content_cut,
//               'Split',
//               onTap: showSplitButton ? splitClipAtPlayhead : null,
//               enabled: showSplitButton,
//             ),
//             _buildToolbarButton(
//               Icons.volume_up,
//               'Volume',
//               onTap: _showVolumeEditor,
//             ),
//             _buildToolbarButton(
//               Icons.auto_awesome,
//               'Fade',
//               onTap: () => _showMessage('Fade'),
//             ),
//             _buildToolbarButton(
//               Icons.delete,
//               'Delete',
//               color: Colors.red,
//               onTap: _deleteSelected,
//             ),
//             _buildToolbarButton(Icons.speed, 'Speed', onTap: _showSpeedEditor),
//             _buildToolbarButton(
//               Icons.crop,
//               'Crop',
//               onTap: () => _showMessage('Crop'),
//             ),
//             _buildToolbarButton(
//               Icons.more_horiz,
//               'More',
//               onTap: () => _showMessage('More'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _deleteSelected() {
//     if (selectedClip == null) return;
//     setState(() {
//       clips.removeWhere((c) => int.tryParse(c.id) == selectedClip);
//       audioItems.removeWhere((c) => int.tryParse(c.id) == selectedClip);
//       textItems.removeWhere((c) => int.tryParse(c.id) == selectedClip);
//       overlayItems.removeWhere((c) => int.tryParse(c.id) == selectedClip);
//       selectedClip = null;
//     });
//     _showMessage('Deleted');
//   }
//
//   void _showVolumeEditor() {
//     if (selectedClip == null) return;
//     TimelineItem? item;
//     for (var clip in [...clips, ...audioItems]) {
//       if (int.tryParse(clip.id) == selectedClip) {
//         item = clip;
//         break;
//       }
//     }
//     if (item == null) return;
//     double tempVolume = item.volume;
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1A1A1A),
//       builder:
//           (ctx) => StatefulBuilder(
//         builder:
//             (context, setModalState) => Container(
//           height: 250,
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               const Text(
//                 'Volume',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 '${(tempVolume * 100).toInt()}%',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                 ),
//               ),
//               Slider(
//                 value: tempVolume,
//                 min: 0.0,
//                 max: 2.0,
//                 divisions: 20,
//                 activeColor: const Color(0xFF00D9FF),
//                 onChanged: (v) => setModalState(() => tempVolume = v),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() => item!.volume = tempVolume);
//                   Navigator.pop(ctx);
//                   _showMessage(
//                     'Volume: ${(tempVolume * 100).toInt()}%',
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF00D9FF),
//                   foregroundColor: Colors.black,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 32,
//                     vertical: 12,
//                   ),
//                 ),
//                 child: const Text(
//                   'Apply',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showSpeedEditor() {
//     if (selectedClip == null) return;
//     TimelineItem? item;
//     for (var clip in [...clips, ...audioItems]) {
//       if (int.tryParse(clip.id) == selectedClip) {
//         item = clip;
//         break;
//       }
//     }
//     if (item == null) return;
//     double tempSpeed = item.speed;
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1A1A1A),
//       builder:
//           (ctx) => StatefulBuilder(
//         builder:
//             (context, setModalState) => Container(
//           height: 300,
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               const Text(
//                 'Speed',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 '${tempSpeed.toStringAsFixed(2)}x',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                 ),
//               ),
//               Slider(
//                 value: tempSpeed,
//                 min: 0.25,
//                 max: 4.0,
//                 divisions: 15,
//                 activeColor: const Color(0xFF00D9FF),
//                 onChanged: (v) => setModalState(() => tempSpeed = v),
//               ),
//               const SizedBox(height: 16),
//               Wrap(
//                 spacing: 8,
//                 children:
//                 [0.25, 0.5, 1.0, 2.0, 4.0].map((speed) {
//                   return ElevatedButton(
//                     onPressed:
//                         () =>
//                         setModalState(() => tempSpeed = speed),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor:
//                       tempSpeed == speed
//                           ? const Color(0xFF00D9FF)
//                           : const Color(0xFF2A2A2A),
//                       foregroundColor:
//                       tempSpeed == speed
//                           ? Colors.black
//                           : Colors.white,
//                     ),
//                     child: Text('${speed}x'),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     final oldDuration = item!.duration;
//                     item.speed = tempSpeed;
//                     item.duration = Duration(
//                       milliseconds:
//                       (oldDuration.inMilliseconds / tempSpeed)
//                           .round(),
//                     );
//                   });
//                   Navigator.pop(ctx);
//                   _showMessage(
//                     'Speed: ${tempSpeed.toStringAsFixed(2)}x',
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF00D9FF),
//                   foregroundColor: Colors.black,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 32,
//                     vertical: 12,
//                   ),
//                 ),
//                 child: const Text(
//                   'Apply',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildToolbarButton(
//       IconData icon,
//       String label, {
//         VoidCallback? onTap,
//         bool enabled = true,
//         Color? color,
//       }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       child: InkWell(
//         onTap: enabled ? onTap : null,
//         child: Opacity(
//           opacity: enabled ? 1.0 : 0.4,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(icon, size: 20, color: color),
//               const SizedBox(height: 4),
//               Text(label, style: TextStyle(fontSize: 11, color: color)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBottomNavigation() {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       decoration: const BoxDecoration(
//         border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildNavButton(Icons.content_cut, 'Edit', onTap: () => _showMessage('Edit tools')),
//           _buildNavButton(Icons.audiotrack, 'Audio', onTap: _addAudio),
//           _buildNavButton(Icons.text_fields, 'Text', onTap: () {
//             _saveToHistory();
//             _addText();
//           }),
//           _buildNavButton(Icons.auto_awesome, 'Effects', onTap: () => _showMessage('Effects')),
//           _buildNavButton(Icons.layers, 'Overlay', onTap: _addImage),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNavButton(IconData icon, String label, {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 20),
//           const SizedBox(height: 4),
//           Text(label, style: const TextStyle(fontSize: 11)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSystemNavigation() {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       decoration: const BoxDecoration(
//         border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           const Icon(Icons.menu, size: 24),
//           GestureDetector(
//             onTap: _undo,
//             child: const Icon(Icons.undo, size: 24),
//           ),
//           GestureDetector(
//             onTap: _redo,
//             child: const Icon(Icons.redo, size: 24),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//
// }

