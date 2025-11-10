// // This is the complete continuation of the CapCut interface
// // Copy this entire file as your main.dart
//
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'dart:async';
// import 'dart:io';
// import 'dart:math' as math;
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
//
// void main() {
//   runApp(const CapCutApp());
// }
//
// class CapCutApp extends StatelessWidget {
//   const CapCutApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'CapCut Clone',
//       theme: ThemeData.dark().copyWith(
//         scaffoldBackgroundColor: Colors.black,
//         primaryColor: const Color(0xFF00D9FF),
//       ),
//       home: const VideoEditorScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
//
// enum TimelineItemType { video, audio, image, text }
//
// class TimelineItem {
//   String id;
//   TimelineItemType type;
//   File? file;
//   Duration startTime;
//   Duration duration;
//   Duration originalDuration;
//   Duration trimStart;
//   Duration trimEnd;
//   double speed;
//   double volume;
//   String? text;
//   Color? textColor;
//   double? fontSize;
//   double? x;
//   double? y;
//   double rotation;
//   double scale;
//   String? effect;
//   List<String> thumbnailPaths;
//   List<double>? waveformData;
//
//   TimelineItem({
//     required this.id,
//     required this.type,
//     this.file,
//     required this.startTime,
//     required this.duration,
//     required this.originalDuration,
//     Duration? trimStart,
//     Duration? trimEnd,
//     this.speed = 1.0,
//     this.volume = 1.0,
//     this.text,
//     this.textColor,
//     this.fontSize,
//     this.x,
//     this.y,
//     this.rotation = 0.0,
//     this.scale = 1.0,
//     this.effect,
//     List<String>? thumbnailPaths,
//     this.waveformData,
//   })  : trimStart = trimStart ?? Duration.zero,
//         trimEnd = trimEnd ?? originalDuration,
//         thumbnailPaths = thumbnailPaths ?? [];
//
//   TimelineItem copyWith({
//     String? id,
//     TimelineItemType? type,
//     File? file,
//     Duration? startTime,
//     Duration? duration,
//     Duration? originalDuration,
//     Duration? trimStart,
//     Duration? trimEnd,
//     double? speed,
//     double? volume,
//     String? text,
//     Color? textColor,
//     double? fontSize,
//     double? x,
//     double? y,
//     double? rotation,
//     double? scale,
//     String? effect,
//     List<String>? thumbnailPaths,
//     List<double>? waveformData,
//   }) {
//     return TimelineItem(
//       id: id ?? this.id,
//       type: type ?? this.type,
//       file: file ?? this.file,
//       startTime: startTime ?? this.startTime,
//       duration: duration ?? this.duration,
//       originalDuration: originalDuration ?? this.originalDuration,
//       trimStart: trimStart ?? this.trimStart,
//       trimEnd: trimEnd ?? this.trimEnd,
//       speed: speed ?? this.speed,
//       volume: volume ?? this.volume,
//       text: text ?? this.text,
//       textColor: textColor ?? this.textColor,
//       fontSize: fontSize ?? this.fontSize,
//       x: x ?? this.x,
//       y: y ?? this.y,
//       rotation: rotation ?? this.rotation,
//       scale: scale ?? this.scale,
//       effect: effect ?? this.effect,
//       thumbnailPaths: thumbnailPaths ?? List.from(this.thumbnailPaths),
//       waveformData: waveformData ?? this.waveformData,
//     );
//   }
// }
//
// class VideoEditorScreen extends StatefulWidget {
//   const VideoEditorScreen({Key? key}) : super(key: key);
//
//   @override
//   State<VideoEditorScreen> createState() => _VideoEditorScreenState();
// }
//
// class _VideoEditorScreenState extends State<VideoEditorScreen> with TickerProviderStateMixin {
//   bool isPlaying = false;
//   Duration playheadPosition = const Duration(seconds: 1);
//   int? selectedClip;
//   final double totalDuration = 12.0;
//   final double pixelsPerSecond = 80.0;
//   Timer? playbackTimer;
//   final ScrollController timelineScrollController = ScrollController();
//   final ImagePicker _picker = ImagePicker();
//
//   List<TimelineItem> clips = [];
//   List<TimelineItem> audioItems = [];
//   List<TimelineItem> textItems = [];
//   List<TimelineItem> overlayItems = [];
//
//   final Map<String, dynamic> _controllers = {};
//   final Map<String, dynamic> _audioControllers = {};
//   dynamic _activePreviewController;
//   TimelineItem? _activeItem;
//   late Ticker _playbackTicker;
//   int _lastFrameTime = 0;
//   double _initialRotation = 0.0;
//   double _initialScale = 1.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
//     _playbackTicker = createTicker(_playbackFrame)..start();
//     _initializeSampleClips();
//   }
//
//   void _initializeSampleClips() {
//     clips = [
//       TimelineItem(
//         id: '1',
//         type: TimelineItemType.video,
//         startTime: Duration.zero,
//         duration: const Duration(seconds: 3),
//         originalDuration: const Duration(seconds: 3),
//       ),
//       TimelineItem(
//         id: '2',
//         type: TimelineItemType.video,
//         startTime: const Duration(seconds: 3),
//         duration: const Duration(seconds: 2),
//         originalDuration: const Duration(seconds: 2),
//       ),
//       TimelineItem(
//         id: '3',
//         type: TimelineItemType.video,
//         startTime: const Duration(seconds: 5),
//         duration: const Duration(milliseconds: 2500),
//         originalDuration: const Duration(milliseconds: 2500),
//       ),
//       TimelineItem(
//         id: '4',
//         type: TimelineItemType.video,
//         startTime: const Duration(milliseconds: 7500),
//         duration: const Duration(milliseconds: 4500),
//         originalDuration: const Duration(milliseconds: 4500),
//       ),
//     ];
//   }
//
//   @override
//   void dispose() {
//     _playbackTicker.dispose();
//     timelineScrollController.dispose();
//     playbackTimer?.cancel();
//     for (final c in _controllers.values) {
//       if (c != null) c.dispose();
//     }
//     for (final c in _audioControllers.values) {
//       if (c != null) c.dispose();
//     }
//     super.dispose();
//   }
//
//   Future<bool> _requestPermissions() async {
//     return true;
//   }
//
//   void _playbackFrame(Duration elapsed) {
//     if (!mounted || !isPlaying) return;
//     final now = DateTime.now().millisecondsSinceEpoch;
//     final deltaMs = now - _lastFrameTime;
//     _lastFrameTime = now;
//     if (deltaMs <= 0 || deltaMs > 100) return;
//
//     setState(() {
//       playheadPosition += Duration(milliseconds: deltaMs);
//       if (playheadPosition.inMilliseconds >= totalDuration * 1000) {
//         playheadPosition = Duration(milliseconds: (totalDuration * 1000).toInt());
//         isPlaying = false;
//         _playbackTicker.stop();
//       }
//     });
//     _autoScrollTimeline();
//     _updatePreview();
//   }
//
//   void _autoScrollTimeline() {
//     if (!timelineScrollController.hasClients) return;
//     const double leftPadding = 136.0;
//     final double playheadPixelPosition = playheadPosition.inMilliseconds / 1000 * pixelsPerSecond;
//     final double targetScroll = leftPadding + playheadPixelPosition - MediaQuery.of(context).size.width / 2;
//     final double maxScroll = timelineScrollController.position.maxScrollExtent;
//     final double clampedScroll = targetScroll.clamp(0.0, maxScroll);
//
//     if ((clampedScroll - timelineScrollController.offset).abs() > 5) {
//       timelineScrollController.jumpTo(clampedScroll);
//     }
//   }
//
//   void _updatePreview() {
//     if (!mounted) return;
//     final activeVideo = _findActiveVideo();
//     setState(() => _activeItem = activeVideo);
//   }
//
//   TimelineItem? _findActiveVideo() {
//     for (final item in clips) {
//       final effectiveDur = Duration(milliseconds: (item.duration.inMilliseconds / item.speed).round());
//       if (playheadPosition >= item.startTime && playheadPosition < item.startTime + effectiveDur) {
//         return item;
//       }
//     }
//     return null;
//   }
//
//   void togglePlayPause() {
//     setState(() {
//       isPlaying = !isPlaying;
//       if (isPlaying && playheadPosition.inMilliseconds >= totalDuration * 1000) {
//         playheadPosition = Duration.zero;
//       }
//     });
//
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
//         playheadPosition = Duration(milliseconds: (clickPosition * 1000).clamp(0.0, totalDuration * 1000).toInt());
//         isPlaying = false;
//       });
//       playbackTimer?.cancel();
//     }
//   }
//
//   TimelineItem? getClipAtPlayhead() {
//     for (var clip in clips) {
//       if (playheadPosition >= clip.startTime && playheadPosition < clip.startTime + clip.duration) {
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
//
//       setState(() {
//         clips.removeWhere((c) => c.id == clipToSplit.id);
//         clips.add(clipToSplit.copyWith(duration: splitPoint));
//         clips.add(clipToSplit.copyWith(
//           id: DateTime.now().millisecondsSinceEpoch.toString(),
//           startTime: playheadPosition,
//           duration: clipToSplit.duration - splitPoint,
//         ));
//         clips.sort((a, b) => a.startTime.compareTo(b.startTime));
//       });
//       _showMessage('Clip split');
//     }
//   }
//
//   Future<void> _addVideo() async {
//     if (!await _requestPermissions()) {
//       _showError('Permission denied');
//       return;
//     }
//
//     try {
//       final XFile? file = await _picker.pickVideo(
//         source: ImageSource.gallery,
//         maxDuration: const Duration(minutes: 10),
//       );
//       if (file == null) return;
//
//       final startTime = clips.isEmpty
//           ? Duration.zero
//           : clips.map((i) => i.startTime + i.duration).reduce((a, b) => a > b ? a : b);
//
//       final item = TimelineItem(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         type: TimelineItemType.video,
//         file: File(file.path),
//         startTime: startTime,
//         duration: const Duration(seconds: 5),
//         originalDuration: const Duration(seconds: 5),
//       );
//
//       setState(() {
//         clips.add(item);
//         selectedClip = int.parse(item.id);
//       });
//
//       _showMessage('Video added: ${file.name}');
//     } catch (e) {
//       _showError('Failed to pick video: $e');
//     }
//   }
//
//   Future<void> _addAudio() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.audio,
//         allowMultiple: false,
//       );
//       if (result == null || result.files.isEmpty) return;
//       final filePath = result.files.first.path;
//       if (filePath == null) {
//         _showError('Invalid file path');
//         return;
//       }
//
//       final item = TimelineItem(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         type: TimelineItemType.audio,
//         file: File(filePath),
//         startTime: Duration.zero,
//         duration: const Duration(seconds: 10),
//         originalDuration: const Duration(seconds: 10),
//       );
//
//       setState(() {
//         audioItems.add(item);
//         selectedClip = int.parse(item.id);
//       });
//
//       _showMessage('Audio added: ${result.files.first.name}');
//     } catch (e) {
//       _showError('Failed to add audio: $e');
//     }
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
//   }
//
//   Future<void> _addOverlay() async {
//     if (!await _requestPermissions()) {
//       _showError('Permission denied');
//       return;
//     }
//
//     try {
//       final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
//       if (file == null) return;
//
//       final item = TimelineItem(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         type: TimelineItemType.image,
//         file: File(file.path),
//         startTime: playheadPosition,
//         duration: const Duration(seconds: 5),
//         originalDuration: const Duration(seconds: 5),
//         x: 50,
//         y: 100,
//       );
//
//       setState(() {
//         overlayItems.add(item);
//         selectedClip = int.parse(item.id);
//       });
//
//       _showMessage('Overlay added');
//     } catch (e) {
//       _showError('Failed to add overlay: $e');
//     }
//   }
//
//   String formatTime(double seconds) {
//     final mins = (seconds / 60).floor();
//     final secs = (seconds % 60).floor();
//     return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
//   }
//
//   void _showLoading() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00D9FF))),
//     );
//   }
//
//   void _hideLoading() {
//     if (Navigator.canPop(context)) Navigator.pop(context);
//   }
//
//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), backgroundColor: Colors.red),
//     );
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
//
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
//   Widget _buildTopBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: const BoxDecoration(
//         border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: const [
//               Icon(Icons.close, size: 24),
//               SizedBox(width: 16),
//               Icon(Icons.help_outline, size: 24),
//             ],
//           ),
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF2A2A2A),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: const [
//                     Icon(Icons.diamond, size: 14, color: Color(0xFF00D9FF)),
//                     SizedBox(width: 6),
//                     Text('free tr', style: TextStyle(fontSize: 13)),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF2A2A2A),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: const [
//                     Text('1080P', style: TextStyle(fontSize: 13)),
//                     SizedBox(width: 6),
//                     Icon(Icons.arrow_drop_down, size: 18),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF00D9FF),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'Export',
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildVideoPreview() {
//     return Container(
//       color: const Color(0xFF1A1A1A),
//       child: Center(
//         child: AspectRatio(
//           aspectRatio: 16 / 9,
//           child: Container(
//             margin: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
//               ),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Stack(
//               children: [
//                 Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: 128,
//                         height: 128,
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [Color(0xFFD97706), Color(0xFF92400E)],
//                           ),
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         clips.isEmpty ? 'Add a video to start' : 'Video Preview',
//                         style: const TextStyle(color: Colors.white54, fontSize: 12),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//                 ..._buildTextOverlays(),
//                 ..._buildImageOverlays(),
//                 Positioned(
//                   top: 16,
//                   left: 16,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.6),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: const Text('✂️ CapCut', style: TextStyle(fontSize: 12)),
//                   ),
//                 ),
//                 Positioned(
//                   top: 16,
//                   right: 16,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.6),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: const Text('PixVerse.ai', style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
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
//   List<Widget> _buildTextOverlays() {
//     final List<Widget> overlays = [];
//     for (final item in textItems) {
//       if (playheadPosition >= item.startTime && playheadPosition < item.startTime + item.duration) {
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
//                 shadows: [Shadow(offset: const Offset(1, 1), blurRadius: 3, color: Colors.black.withOpacity(0.5))],
//               ),
//             ),
//           ),
//         );
//
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
//               decoration: BoxDecoration(border: Border.all(color: const Color(0xFF00D9FF), width: 2)),
//               child: textWidget,
//             ),
//           );
//         }
//
//         overlays.add(Positioned(left: item.x ?? 100, top: item.y ?? 200, child: textWidget));
//       }
//     }
//     return overlays;
//   }
//
//   List<Widget> _buildImageOverlays() {
//     final List<Widget> overlays = [];
//     for (final item in overlayItems) {
//       if (playheadPosition >= item.startTime && playheadPosition < item.startTime + item.duration) {
//         if (item.file != null) {
//           Widget imageWidget = Transform.rotate(
//             angle: item.rotation * math.pi / 180,
//             child: Transform.scale(
//               scale: item.scale,
//               child: Image.file(item.file!, width: 200, height: 200, fit: BoxFit.contain),
//             ),
//           );
//
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
//                 decoration: BoxDecoration(border: Border.all(color: const Color(0xFF00D9FF), width: 2)),
//                 child: imageWidget,
//               ),
//             );
//           }
//
//           overlays.add(Positioned(left: item.x ?? 50, top: item.y ?? 100, child: imageWidget));
//         }
//       }
//     }
//     return overlays;
//   }
//
//   Widget _buildPlaybackControls() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF2A2A2A)))),
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
//                 decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(6)),
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
//           Text(formatTime(playheadPosition.inMilliseconds / 1000), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
//           const Text(' / ', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
//           Text(formatTime(totalDuration), style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTimelineSection(bool showSplitButton) {
//     return Container(
//       color: const Color(0xFF0A0A0A),
//       child: Column(
//         children: [
//           Container(
//             height: 24,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 for (int i = 0; i <= totalDuration.toInt(); i += 2) ...[
//                   Text(formatTime(i.toDouble()), style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
//                   if (i < totalDuration.toInt() - 1)
//                     const Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 32),
//                       child: Text('•', style: TextStyle(color: Color(0xFF444444))),
//                     ),
//                 ],
//               ],
//             ),
//           ),
//           SizedBox(
//             height: 240,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: GestureDetector(
//                 onTapDown: (details) => handleTimelineClick(details.localPosition.dx),
//                 child: SingleChildScrollView(
//                   controller: timelineScrollController,
//                   scrollDirection: Axis.horizontal,
//                   child: SizedBox(
//                     width: totalDuration * pixelsPerSecond + 136,
//                     child: Stack(
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             SizedBox(
//                               height: 80,
//                               child: Row(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   _buildMuteButton(),
//                                   _buildCoverButton(),
//                                   ...clips.map((clip) => _buildVideoClip(clip)),
//                                   _buildAddClipButton(),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             _buildAudioTrack(),
//                             const SizedBox(height: 8),
//                             _buildTextTrack(),
//                           ],
//                         ),
//                         Positioned(
//                           left: 136 + (playheadPosition.inMilliseconds / 1000) * pixelsPerSecond,
//                           top: 0,
//                           bottom: 0,
//                           child: Container(
//                             width: 2,
//                             color: Colors.white,
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Container(
//                                   width: 12,
//                                   height: 12,
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     shape: BoxShape.circle,
//                                     border: Border.all(color: Colors.black, width: 2),
//                                   ),
//                                 ),
//                                 Container(
//                                   width: 12,
//                                   height: 12,
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     shape: BoxShape.circle,
//                                     border: Border.all(color: Colors.black, width: 2),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         if (showSplitButton)
//                           Positioned(
//                             left: 136 + (playheadPosition.inMilliseconds / 1000) * pixelsPerSecond,
//                             top: 25,
//                             child: Transform.translate(
//                               offset: const Offset(-40, 0),
//                               child: GestureDetector(
//                                 onTap: splitClipAtPlayhead,
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFF00D9FF),
//                                     borderRadius: BorderRadius.circular(16),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: const Color(0xFF00D9FF).withOpacity(0.3),
//                                         blurRadius: 8,
//                                         spreadRadius: 2,
//                                       ),
//                                     ],
//                                   ),
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: const [
//                                       Icon(Icons.content_cut, size: 14, color: Colors.black),
//                                       SizedBox(width: 4),
//                                       Text('Split', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
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
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMuteButton() {
//     return Column(
//       children: [
//         Container(
//           width: 56,
//           height: 56,
//           margin: const EdgeInsets.only(right: 8),
//           decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8)),
//           child: const Icon(Icons.volume_off, size: 20),
//         ),
//         const SizedBox(height: 4),
//         const Text('Mute\nclip', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Color(0xFF999999))),
//       ],
//     );
//   }
//
//   Widget _buildCoverButton() {
//     return Column(
//       children: [
//         Container(
//           width: 56,
//           height: 56,
//           margin: const EdgeInsets.only(right: 16),
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(colors: [Color(0xFFB45309), Color(0xFF78350F)]),
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//         const SizedBox(height: 4),
//         const Text('Cover', style: TextStyle(fontSize: 10, color: Color(0xFF999999))),
//       ],
//     );
//   }
//
//   Widget _buildVideoClip(TimelineItem clip) {
//     final isSelected = selectedClip == int.tryParse(clip.id);
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           selectedClip = int.tryParse(clip.id);
//           playheadPosition = clip.startTime;
//         });
//       },
//       child: Container(
//         width: clip.duration.inMilliseconds / 1000 * pixelsPerSecond,
//         height: 64,
//         margin: const EdgeInsets.only(right: 2),
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(colors: [Color(0xFFB45309), Color(0xFF78350F)]),
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: isSelected ? const Color(0xFF00D9FF) : const Color(0xFF555555), width: 2),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(6),
//           child: clip.thumbnailPaths.isNotEmpty
//               ? Row(
//             children: clip.thumbnailPaths
//                 .map((p) => Expanded(child: Image.file(File(p), fit: BoxFit.cover)))
//                 .toList(),
//           )
//               : Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(colors: [Color(0xFFB45309), Color(0xFF78350F)]),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAddClipButton() {
//     return GestureDetector(
//       onTap: _addVideo,
//       child: Container(
//         width: 56,
//         height: 64,
//         margin: const EdgeInsets.only(left: 8),
//         decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8)),
//         child: const Center(child: Text('+', style: TextStyle(fontSize: 28))),
//       ),
//     );
//   }
//
//   Widget _buildAudioTrack() {
//     return Row(
//       children: [
//         const SizedBox(width: 136),
//         Expanded(
//           child: InkWell(
//             onTap: _addAudio,
//             child: Container(
//               height: 60,
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1A1A),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
//               ),
//               child: Row(
//                 children: const [
//                   SizedBox(width: 12),
//                   Icon(Icons.audiotrack, size: 20, color: Color(0xFF999999)),
//                   SizedBox(width: 12),
//                   Text('+ Add audio', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTextTrack() {
//     return Row(
//       children: [
//         const SizedBox(width: 136),
//         Expanded(
//           child: InkWell(
//             onTap: _addText,
//             child: Container(
//               height: 60,
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1A1A),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
//               ),
//               child: Row(
//                 children: const [
//                   SizedBox(width: 12),
//                   Icon(Icons.text_fields, size: 20, color: Color(0xFF999999)),
//                   SizedBox(width: 12),
//                   Text('+ Add text', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
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
//             _buildToolbarButton(Icons.audiotrack, 'Sounds', onTap: () => _showMessage('Sounds')),
//             _buildToolbarButton(Icons.content_cut, 'Split', onTap: showSplitButton ? splitClipAtPlayhead : null, enabled: showSplitButton),
//             _buildToolbarButton(Icons.volume_up, 'Volume', onTap: _showVolumeEditor),
//             _buildToolbarButton(Icons.auto_awesome, 'Fade', onTap: () => _showMessage('Fade')),
//             _buildToolbarButton(Icons.delete, 'Delete', color: Colors.red, onTap: _deleteSelected),
//             _buildToolbarButton(Icons.speed, 'Speed', onTap: _showSpeedEditor),
//             _buildToolbarButton(Icons.crop, 'Crop', onTap: () => _showMessage('Crop')),
//             _buildToolbarButton(Icons.more_horiz, 'More', onTap: () => _showMessage('More')),
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
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setModalState) => Container(
//           height: 250,
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               const Text('Volume', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 20),
//               Text('${(tempVolume * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 24)),
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
//                   _showMessage('Volume: ${(tempVolume * 100).toInt()}%');
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF00D9FF),
//                   foregroundColor: Colors.black,
//                   padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                 ),
//                 child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
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
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setModalState) => Container(
//           height: 300,
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               const Text('Speed', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 20),
//               Text('${tempSpeed.toStringAsFixed(2)}x', style: const TextStyle(color: Colors.white, fontSize: 24)),
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
//                 children: [0.25, 0.5, 1.0, 2.0, 4.0].map((speed) {
//                   return ElevatedButton(
//                     onPressed: () => setModalState(() => tempSpeed = speed),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: tempSpeed == speed ? const Color(0xFF00D9FF) : const Color(0xFF2A2A2A),
//                       foregroundColor: tempSpeed == speed ? Colors.black : Colors.white,
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
//                     item.duration = Duration(milliseconds: (oldDuration.inMilliseconds / tempSpeed).round());
//                   });
//                   Navigator.pop(ctx);
//                   _showMessage('Speed: ${tempSpeed.toStringAsFixed(2)}x');
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF00D9FF),
//                   foregroundColor: Colors.black,
//                   padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                 ),
//                 child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
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
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setModalState) => Padding(
//           padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
//           child: Container(
//             height: 450,
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 const Text('Edit Text', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: controller,
//                   style: const TextStyle(color: Colors.white),
//                   decoration: const InputDecoration(
//                     hintText: 'Enter text',
//                     hintStyle: TextStyle(color: Colors.white54),
//                     enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
//                     focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00D9FF))),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text('Color', style: TextStyle(color: Colors.white)),
//                 const SizedBox(height: 8),
//                 Wrap(
//                   spacing: 8,
//                   children: [Colors.white, Colors.red, Colors.yellow, Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.pink].map((c) {
//                     final isSelected = c == tempColor;
//                     return GestureDetector(
//                       onTap: () => setModalState(() => tempColor = c),
//                       child: Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: c,
//                           shape: BoxShape.circle,
//                           border: Border.all(color: isSelected ? const Color(0xFF00D9FF) : Colors.transparent, width: 3),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text('Font Size', style: TextStyle(color: Colors.white)),
//                 Slider(
//                   value: tempSize,
//                   min: 10,
//                   max: 100,
//                   activeColor: const Color(0xFF00D9FF),
//                   onChanged: (v) => setModalState(() => tempSize = v),
//                 ),
//                 Text('${tempSize.toInt()}', style: const TextStyle(color: Colors.white)),
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
//                     padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                   ),
//                   child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildToolbarButton(IconData icon, String label, {VoidCallback? onTap, bool enabled = true, Color? color}) {
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
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF2A2A2A)))),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildNavButton(Icons.content_cut, 'Edit'),
//           _buildNavButton(Icons.audiotrack, 'Audio', onTap: _addAudio),
//           _buildNavButton(Icons.text_fields, 'Text', onTap: () {
//             _addText();
//             Future.delayed(const Duration(milliseconds: 100), () {
//               if (textItems.isNotEmpty) _showTextEditor(textItems.last);
//             });
//           }),
//           _buildNavButton(Icons.auto_awesome, 'Effects', onTap: () => _showMessage('Effects')),
//           _buildNavButton(Icons.layers, 'Overlay', onTap: _addOverlay),
//           _buildNavButton(Icons.subtitles, 'Captions', onTap: () => _showMessage('Captions')),
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
//       decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF2A2A2A)))),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: const [
//           Icon(Icons.menu, size: 24),
//           Icon(Icons.circle_outlined, size: 24),
//           Icon(Icons.undo, size: 24),
//         ],
//       ),
//     );
//   }
// }