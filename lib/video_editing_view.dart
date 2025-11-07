// //
// //
// // // pubspec.yaml dependencies needed:
// // // video_player: ^2.8.0
// // // image_picker: ^1.0.0
// // // path_provider: ^2.1.0
// // // permission_handler: ^11.0.0
// // // audioplayers: ^5.0.0
// // // file_picker: ^6.0.0
// // // ffmpeg_kit_flutter_min_gpl: ^6.0.3
// //
// // // pubspec.yaml dependencies needed:
// // // video_player: ^2.8.0
// // // image_picker: ^1.0.0
// // // path_provider: ^2.1.0
// // // permission_handler: ^11.0.0
// // // audioplayers: ^5.0.0
// // // file_picker: ^6.0.0
// // // ffmpeg_kit_flutter_min_gpl: ^6.0.3
// //
// // import 'dart:async';
// // import 'dart:io';
// // import 'dart:math' as math;
// //
// // import 'package:audioplayers/audioplayers.dart';
// // import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
// // import 'package:ffmpeg_kit_min_gpl/return_code.dart';
// // import 'package:file_picker/file_picker.dart';
// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:path_provider/path_provider.dart';
// // import 'package:permission_handler/permission_handler.dart';
// // import 'package:video_player/video_player.dart';
// //
// // void main() {
// //   runApp(const KwaiCutCloneApp());
// // }
// //
// // class KwaiCutCloneApp extends StatelessWidget {
// //   const KwaiCutCloneApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'KwaiCut',
// //       theme: ThemeData.dark().copyWith(
// //         primaryColor: const Color(0xFF000000),
// //         scaffoldBackgroundColor: const Color(0xFF000000),
// //       ),
// //       home: const HomeScreen(),
// //       debugShowCheckedModeBanner: false,
// //     );
// //   }
// // }
// //
// // // ==================== DATA MODELS ====================
// // class VideoClip {
// //   String name;
// //   String filePath;
// //   double duration;
// //   double startTime;
// //   double speed;
// //   String? filterName;
// //   double volume;
// //   String? transitionType;
// //   double transitionDuration;
// //   VideoPlayerController? _controller;
// //   double sourceStart;
// //   double originalDuration;
// //
// //   VideoClip({
// //     required this.name,
// //     required this.filePath,
// //     required this.duration,
// //     required this.startTime,
// //     required this.originalDuration,
// //     this.filterName,
// //     this.speed = 1.0,
// //     this.volume = 1.0,
// //     this.transitionDuration = 0.5,
// //     this.sourceStart = 0.0,
// //   });
// //
// //   Future<void> initController() async {
// //     if (_controller == null) {
// //       _controller = VideoPlayerController.file(File(filePath));
// //       await _controller!.initialize();
// //       _controller!.setLooping(false);
// //       await applyVolume(); // ✅ apply clip’s stored volume
// //     }
// //   }
// //
// //   Future<void> applyVolume() async {
// //     if (_controller != null) {
// //       await _controller!.setVolume(volume);
// //     }
// //   }
// //
// //   Future<void> disposeController() async {
// //     await _controller?.dispose();
// //     _controller = null;
// //   }
// // }
// //
// // class TextOverlay {
// //   String text;
// //   double x;
// //   double y;
// //   double fontSize = 32;
// //   Color color = Colors.white;
// //   FontWeight fontWeight = FontWeight.bold;
// //   double startTime;
// //   double endTime;
// //   String? animationType;
// //   double scale = 1.0;
// //   double rotation = 0.0;
// //
// //   TextOverlay({
// //     required this.text,
// //     required this.x,
// //     required this.y,
// //     required this.startTime,
// //     required this.endTime,
// //   });
// // }
// //
// // class StickerOverlay {
// //   String assetPath;
// //   double x;
// //   double y;
// //   double scale = 1.0;
// //   double rotation = 0.0;
// //   double startTime;
// //   double endTime;
// //
// //   StickerOverlay({
// //     required this.assetPath,
// //     required this.x,
// //     required this.y,
// //     required this.startTime,
// //     required this.endTime,
// //   });
// // }
// //
// // class AudioTrack {
// //   String name;
// //   String filePath;
// //   double startTime;
// //   double duration;
// //   double volume = 1.0;
// //   AudioPlayer? player;
// //
// //   AudioTrack({
// //     required this.name,
// //     required this.filePath,
// //     required this.startTime,
// //     required this.duration,
// //   });
// //
// //   Future<void> initPlayer() async {
// //     if (player == null) {
// //       player = AudioPlayer();
// //       await player!.setSourceDeviceFile(filePath);
// //     }
// //   }
// //
// //   Future<void> disposePlayer() async {
// //     await player?.dispose();
// //     player = null;
// //   }
// // }
// //
// // // ==================== HOME SCREEN ====================
// // class HomeScreen extends StatefulWidget {
// //   const HomeScreen({super.key});
// //
// //   @override
// //   State<HomeScreen> createState() => _HomeScreenState();
// // }
// //
// // class _HomeScreenState extends State<HomeScreen> {
// //   int _selectedIndex = 0;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body:
// //           _selectedIndex == 0
// //               ? const ProjectsScreen()
// //               : const Center(child: Text('Coming Soon')),
// //       bottomNavigationBar: Container(
// //         decoration: BoxDecoration(
// //           color: Colors.black,
// //           border: Border(top: BorderSide(color: Colors.grey[900]!, width: 0.5)),
// //         ),
// //         child: SafeArea(
// //           child: SizedBox(
// //             height: 56,
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceAround,
// //               children: [
// //                 _buildNavItem(0, Icons.home, 'Home'),
// //                 _buildNavItem(1, Icons.explore_outlined, 'Discover'),
// //                 _buildNavItem(2, Icons.add_box_outlined, 'Create'),
// //                 _buildNavItem(3, Icons.person_outline, 'Me'),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildNavItem(int index, IconData icon, String label) {
// //     final isSelected = _selectedIndex == index;
// //     return GestureDetector(
// //       onTap: () => setState(() => _selectedIndex = index),
// //       child: Container(
// //         color: Colors.transparent,
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(
// //               icon,
// //               color: isSelected ? Colors.white : Colors.grey[600],
// //               size: 24,
// //             ),
// //             const SizedBox(height: 4),
// //             Text(
// //               label,
// //               style: TextStyle(
// //                 color: isSelected ? Colors.white : Colors.grey[600],
// //                 fontSize: 10,
// //                 fontWeight: FontWeight.w500,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // ==================== PROJECTS SCREEN ====================
// // class ProjectsScreen extends StatelessWidget {
// //   const ProjectsScreen({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.black,
// //       appBar: AppBar(
// //         backgroundColor: Colors.black,
// //         elevation: 0,
// //         title: const Text(
// //           'Projects',
// //           style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
// //         ),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.search, size: 24),
// //             onPressed: () {},
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.more_vert, size: 24),
// //             onPressed: () {},
// //           ),
// //         ],
// //       ),
// //       body: GridView.builder(
// //         padding: const EdgeInsets.all(12),
// //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //           crossAxisCount: 2,
// //           crossAxisSpacing: 10,
// //           mainAxisSpacing: 10,
// //           childAspectRatio: 9 / 16,
// //         ),
// //         itemCount: 8,
// //         itemBuilder: (context, index) {
// //           return GestureDetector(
// //             onTap: () {
// //               Navigator.push(
// //                 context,
// //                 MaterialPageRoute(builder: (_) => const VideoEditorScreen()),
// //               );
// //             },
// //             child: Container(
// //               decoration: BoxDecoration(
// //                 color: const Color(0xFF1A1A1A),
// //                 borderRadius: BorderRadius.circular(6),
// //               ),
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Container(
// //                     width: 56,
// //                     height: 56,
// //                     decoration: BoxDecoration(
// //                       color: const Color(0xFF2A2A2A),
// //                       shape: BoxShape.circle,
// //                     ),
// //                     child: Icon(
// //                       Icons.play_arrow,
// //                       size: 28,
// //                       color: Colors.grey[600],
// //                     ),
// //                   ),
// //                   const SizedBox(height: 12),
// //                   Text(
// //                     'Draft ${index + 1}',
// //                     style: const TextStyle(
// //                       color: Colors.white,
// //                       fontSize: 13,
// //                       fontWeight: FontWeight.w500,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 2),
// //                   Text(
// //                     'Edited ${index + 1}h ago',
// //                     style: TextStyle(color: Colors.grey[600], fontSize: 11),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //       floatingActionButton: Container(
// //         margin: const EdgeInsets.only(bottom: 12),
// //         child: FloatingActionButton.extended(
// //           onPressed: () {
// //             Navigator.push(
// //               context,
// //               MaterialPageRoute(builder: (_) => const VideoEditorScreen()),
// //             );
// //           },
// //           backgroundColor: const Color(0xFF8B5CF6),
// //           elevation: 4,
// //           label: const Row(
// //             children: [
// //               Icon(Icons.add, size: 20),
// //               SizedBox(width: 6),
// //               Text(
// //                 'New project',
// //                 style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
// //     );
// //   }
// // }
// //
// // // ==================== VIDEO EDITOR SCREEN ====================
// // class VideoEditorScreen extends StatefulWidget {
// //   const VideoEditorScreen({super.key});
// //
// //   @override
// //   State<VideoEditorScreen> createState() => _VideoEditorScreenState();
// // }
// //
// // class _VideoEditorScreenState extends State<VideoEditorScreen> {
// //   final List<VideoClip> _videoClips = [];
// //   final List<TextOverlay> _textOverlays = [];
// //   final List<AudioTrack> _audioTracks = [];
// //   final List<StickerOverlay> _stickers = [];
// //
// //   double _currentTime = 0.0;
// //   double _totalDuration = 0.0;
// //   bool _isPlaying = false;
// //   Timer? _playbackTimer;
// //
// //   int _selectedToolTab = 0;
// //   int? _selectedClipIndex;
// //   int? _selectedTextIndex;
// //   int? _selectedStickerIndex;
// //   double _canvasScale = 1.0;
// //
// //   VideoPlayerController? _previewController;
// //   VoidCallback? _previewListener;
// //
// //   final double pixelsPerSecond = 10.0;
// //
// //   final Map<String, ColorFilter> _previewFilters = {
// //     'B&W': const ColorFilter.mode(Colors.grey, BlendMode.saturation),
// //     'Sepia': ColorFilter.matrix(<double>[
// //       0.393,
// //       0.769,
// //       0.189,
// //       0,
// //       0,
// //       0.349,
// //       0.686,
// //       0.168,
// //       0,
// //       0,
// //       0.272,
// //       0.534,
// //       0.131,
// //       0,
// //       0,
// //       0,
// //       0,
// //       0,
// //       1,
// //       0,
// //     ]),
// //   };
// //
// //   Map<String, String> _ffmpegFilters = {
// //     'B&W': 'hue=s=0',
// //     'Sepia': 'colorchannelmixer=.393:.769:.189:.349:.686:.168:.272:.534:.131',
// //   };
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _initPreviewListener();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _playbackTimer?.cancel();
// //     _previewController?.removeListener(_previewListener!);
// //     _previewController?.dispose();
// //     for (var clip in _videoClips) {
// //       clip.disposeController();
// //     }
// //     for (var audio in _audioTracks) {
// //       audio.disposePlayer();
// //     }
// //     super.dispose();
// //   }
// //
// //   void _initPreviewListener() {
// //     _previewListener = () {
// //       if (_previewController == null ||
// //           !_previewController!.value.isInitialized)
// //         return;
// //
// //       final clip = activeClip;
// //       if (clip == null) return;
// //
// //       final position =
// //           _previewController!.value.position.inMilliseconds / 1000.0;
// //       if (mounted) {
// //         setState(() => _currentTime = clip.startTime + position);
// //       }
// //
// //       if (position >= clip.duration) {
// //         if (_selectedClipIndex == _videoClips.length - 1) {
// //           _pausePlayback();
// //         } else {
// //           _nextClip();
// //         }
// //       }
// //     };
// //   }
// //
// //   void _calculateTotalDuration() {
// //     if (_videoClips.isEmpty) {
// //       _totalDuration = 0.0;
// //       return;
// //     }
// //     double currentStart = 0.0;
// //     for (var clip in _videoClips) {
// //       clip.startTime = currentStart;
// //       currentStart += clip.duration;
// //     }
// //     _totalDuration = currentStart;
// //   }
// //
// //   VideoClip? get activeClip {
// //     for (var clip in _videoClips) {
// //       if (_currentTime >= clip.startTime &&
// //           _currentTime < clip.startTime + clip.duration) {
// //         return clip;
// //       }
// //     }
// //     return _videoClips.isNotEmpty ? _videoClips.first : null;
// //   }
// //
// //   Future<void> _updatePreviewController() async {
// //     final clip = activeClip;
// //     if (clip == null) return;
// //
// //     await clip.initController();
// //     if (_previewController != clip._controller) {
// //       _previewController?.pause();
// //       _previewController?.removeListener(_previewListener!);
// //       _previewController = clip._controller;
// //       if (_previewController != null) {
// //         _previewController!.addListener(_previewListener!);
// //         await _previewController!.setPlaybackSpeed(clip.speed);
// //         await _previewController!.setVolume(clip.volume);
// //       }
// //     }
// //
// //     final localTime = _currentTime - clip.startTime;
// //     if (_previewController != null) {
// //       await _previewController!.seekTo(
// //         Duration(milliseconds: (localTime * 1000).toInt()),
// //       );
// //     }
// //   }
// //
// //   void _nextClip() {
// //     final currentIndex = _selectedClipIndex ?? 0;
// //     if (currentIndex < _videoClips.length - 1) {
// //       setState(() {
// //         _selectedClipIndex = currentIndex + 1;
// //         _currentTime = _videoClips[currentIndex + 1].startTime;
// //       });
// //       _updatePreviewController();
// //       if (_isPlaying) {
// //         _previewController?.play();
// //       }
// //     } else {
// //       _pausePlayback();
// //     }
// //   }
// //
// //   void _pausePlayback() {
// //     setState(() => _isPlaying = false);
// //     _previewController?.pause();
// //     for (var audio in _audioTracks) {
// //       audio.player?.pause();
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.black,
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             _buildTopBar(),
// //             Expanded(child: _buildPreviewCanvas()),
// //             _buildTimelineSection(),
// //             _buildBottomToolbar(),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ==================== TOP BAR ====================
// //   Widget _buildTopBar() {
// //     return Container(
// //       height: 48,
// //       padding: const EdgeInsets.symmetric(horizontal: 4),
// //       decoration: BoxDecoration(
// //         color: Colors.black,
// //         border: Border(
// //           bottom: BorderSide(color: Colors.grey[900]!, width: 0.5),
// //         ),
// //       ),
// //       child: Row(
// //         children: [
// //           IconButton(
// //             icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
// //             onPressed: () => Navigator.pop(context),
// //             padding: EdgeInsets.zero,
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.help_outline, color: Colors.white, size: 22),
// //             onPressed: () {},
// //             padding: EdgeInsets.zero,
// //           ),
// //           const Spacer(),
// //           IconButton(
// //             icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
// //             onPressed: () {},
// //             padding: EdgeInsets.zero,
// //           ),
// //           Container(
// //             margin: const EdgeInsets.only(left: 4, right: 4),
// //             child: Material(
// //               color: const Color(0xFF8B5CF6),
// //               borderRadius: BorderRadius.circular(20),
// //               child: InkWell(
// //                 onTap: _videoClips.isNotEmpty ? _exportVideo : null,
// //                 borderRadius: BorderRadius.circular(20),
// //                 child: Container(
// //                   padding: const EdgeInsets.symmetric(
// //                     horizontal: 20,
// //                     vertical: 8,
// //                   ),
// //                   child: const Text(
// //                     'Export',
// //                     style: TextStyle(
// //                       color: Colors.white,
// //                       fontSize: 14,
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ==================== PREVIEW CANVAS ====================
// //   Widget _buildPreviewCanvas() {
// //     return Container(
// //       color: Colors.black,
// //       child: Center(
// //         child: AspectRatio(
// //           aspectRatio: 9 / 16,
// //           child: GestureDetector(
// //             onScaleUpdate: (details) {
// //               setState(() => _canvasScale = details.scale.clamp(0.5, 3.0));
// //             },
// //             child: Transform.scale(
// //               scale: _canvasScale,
// //               child: Container(
// //                 decoration: BoxDecoration(
// //                   color: const Color(0xFF0D0D0D),
// //                   border: Border.all(
// //                     color: const Color(0xFF2A2A2A),
// //                     width: 0.5,
// //                   ),
// //                 ),
// //                 child: Stack(
// //                   children: [
// //                     _buildVideoLayer(),
// //                     ..._buildTextOverlays(),
// //                     ..._buildStickers(),
// //                     if (_videoClips.isEmpty) _buildEmptyState(),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildVideoLayer() {
// //     final clip = activeClip;
// //     if (clip == null ||
// //         _previewController == null ||
// //         !_previewController!.value.isInitialized) {
// //       return Container(
// //         color: const Color(0xFF1A1A1A),
// //         child: const Center(
// //           child: Icon(Icons.play_circle_outline, size: 64, color: Colors.grey),
// //         ),
// //       );
// //     }
// //
// //     Widget player = VideoPlayer(_previewController!);
// //
// //     if (clip.filterName != null &&
// //         _previewFilters.containsKey(clip.filterName)) {
// //       player = ColorFiltered(
// //         colorFilter: _previewFilters[clip.filterName]!,
// //         child: player,
// //       );
// //     }
// //
// //     return player;
// //   }
// //
// //   List<Widget> _buildTextOverlays() {
// //     return _textOverlays
// //         .asMap()
// //         .entries
// //         .where((entry) {
// //           final overlay = entry.value;
// //           return _currentTime >= overlay.startTime &&
// //               _currentTime < overlay.endTime;
// //         })
// //         .map((entry) {
// //           final index = entry.key;
// //           final overlay = entry.value;
// //           return Positioned(
// //             left: overlay.x,
// //             top: overlay.y,
// //             child: GestureDetector(
// //               onTap: () => setState(() => _selectedTextIndex = index),
// //               onPanUpdate: (details) {
// //                 setState(() {
// //                   overlay.x += details.delta.dx / _canvasScale;
// //                   overlay.y += details.delta.dy / _canvasScale;
// //                 });
// //               },
// //               onScaleUpdate: (details) {
// //                 setState(() {
// //                   overlay.scale = (overlay.scale * details.scale).clamp(
// //                     0.5,
// //                     3.0,
// //                   );
// //                   overlay.rotation += details.rotation;
// //                 });
// //               },
// //               child: Transform.scale(
// //                 scale: overlay.scale,
// //                 child: Transform.rotate(
// //                   angle: overlay.rotation,
// //                   child: Container(
// //                     padding: const EdgeInsets.symmetric(
// //                       horizontal: 8,
// //                       vertical: 4,
// //                     ),
// //                     decoration: BoxDecoration(
// //                       border:
// //                           _selectedTextIndex == index
// //                               ? Border.all(color: Colors.white, width: 1.5)
// //                               : null,
// //                     ),
// //                     child: Text(
// //                       overlay.text,
// //                       style: TextStyle(
// //                         color: overlay.color,
// //                         fontSize: overlay.fontSize,
// //                         fontWeight: overlay.fontWeight,
// //                         shadows: const [
// //                           Shadow(
// //                             blurRadius: 8,
// //                             color: Colors.black54,
// //                             offset: Offset(0, 2),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           );
// //         })
// //         .toList();
// //   }
// //
// //   List<Widget> _buildStickers() {
// //     return _stickers
// //         .asMap()
// //         .entries
// //         .where((entry) {
// //           final sticker = entry.value;
// //           return _currentTime >= sticker.startTime &&
// //               _currentTime < sticker.endTime;
// //         })
// //         .map((entry) {
// //           final index = entry.key;
// //           final sticker = entry.value;
// //           return Positioned(
// //             left: sticker.x,
// //             top: sticker.y,
// //             child: GestureDetector(
// //               onTap: () => setState(() => _selectedStickerIndex = index),
// //               onPanUpdate: (details) {
// //                 setState(() {
// //                   sticker.x += details.delta.dx / _canvasScale;
// //                   sticker.y += details.delta.dy / _canvasScale;
// //                 });
// //               },
// //               onScaleUpdate: (details) {
// //                 setState(() {
// //                   sticker.scale = (sticker.scale * details.scale).clamp(
// //                     0.5,
// //                     3.0,
// //                   );
// //                   sticker.rotation += details.rotation;
// //                 });
// //               },
// //               child: Container(
// //                 decoration: BoxDecoration(
// //                   border:
// //                       _selectedStickerIndex == index
// //                           ? Border.all(color: Colors.white, width: 1.5)
// //                           : null,
// //                 ),
// //                 child: Transform.scale(
// //                   scale: sticker.scale,
// //                   child: Transform.rotate(
// //                     angle: sticker.rotation,
// //                     child: Icon(
// //                       Icons.emoji_emotions,
// //                       size: 48,
// //                       color: Colors.yellow,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           );
// //         })
// //         .toList();
// //   }
// //
// //   Widget _buildEmptyState() {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(Icons.video_library_outlined, size: 72, color: Colors.grey[800]),
// //           const SizedBox(height: 20),
// //           Material(
// //             color: Colors.white,
// //             borderRadius: BorderRadius.circular(6),
// //             child: InkWell(
// //               onTap: _addVideoClip,
// //               borderRadius: BorderRadius.circular(6),
// //               child: Container(
// //                 padding: const EdgeInsets.symmetric(
// //                   horizontal: 28,
// //                   vertical: 12,
// //                 ),
// //                 child: const Row(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     Icon(Icons.add, size: 18, color: Colors.black),
// //                     SizedBox(width: 6),
// //                     Text(
// //                       'Add video',
// //                       style: TextStyle(
// //                         color: Colors.black,
// //                         fontSize: 15,
// //                         fontWeight: FontWeight.w600,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ==================== TIMELINE SECTION ====================
// //   Widget _buildTimelineSection() {
// //     return Container(
// //       height: 140,
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF0A0A0A),
// //         border: Border(top: BorderSide(color: Colors.grey[900]!, width: 0.5)),
// //       ),
// //       child: Column(
// //         children: [
// //           _buildPlaybackControls(),
// //           const Divider(height: 1, thickness: 0.5, color: Color(0xFF2A2A2A)),
// //           Expanded(child: _buildTimeline()),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildPlaybackControls() {
// //     return Container(
// //       height: 52,
// //       padding: const EdgeInsets.symmetric(horizontal: 12),
// //       child: Row(
// //         children: [
// //           Container(
// //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
// //             decoration: BoxDecoration(
// //               color: const Color(0xFF1A1A1A),
// //               borderRadius: BorderRadius.circular(4),
// //             ),
// //             child: Text(
// //               _formatTime(_currentTime),
// //               style: const TextStyle(
// //                 color: Colors.white,
// //                 fontSize: 12,
// //                 fontWeight: FontWeight.w600,
// //                 fontFeatures: [FontFeature.tabularFigures()],
// //               ),
// //             ),
// //           ),
// //           Expanded(
// //             child: SliderTheme(
// //               data: SliderThemeData(
// //                 activeTrackColor: Colors.white,
// //                 inactiveTrackColor: const Color(0xFF2A2A2A),
// //                 thumbColor: Colors.white,
// //                 thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
// //                 overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
// //                 trackHeight: 2,
// //               ),
// //               child: Slider(
// //                 value: _currentTime.clamp(0.0, _totalDuration),
// //                 max: _totalDuration > 0 ? _totalDuration : 1.0,
// //                 onChanged: (value) {
// //                   setState(() => _currentTime = value);
// //                   _updatePreviewController();
// //                 },
// //               ),
// //             ),
// //           ),
// //           Container(
// //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
// //             decoration: BoxDecoration(
// //               color: const Color(0xFF1A1A1A),
// //               borderRadius: BorderRadius.circular(4),
// //             ),
// //             child: Text(
// //               _formatTime(_totalDuration),
// //               style: const TextStyle(
// //                 color: Colors.white,
// //                 fontSize: 12,
// //                 fontWeight: FontWeight.w600,
// //                 fontFeatures: [FontFeature.tabularFigures()],
// //               ),
// //             ),
// //           ),
// //           const SizedBox(width: 8),
// //           Container(
// //             width: 36,
// //             height: 36,
// //             decoration: const BoxDecoration(
// //               color: Color(0xFF1A1A1A),
// //               shape: BoxShape.circle,
// //             ),
// //             child: IconButton(
// //               icon: Icon(
// //                 _isPlaying ? Icons.pause : Icons.play_arrow,
// //                 color: Colors.white,
// //                 size: 20,
// //               ),
// //               onPressed: _togglePlayback,
// //               padding: EdgeInsets.zero,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildTimeline() {
// //     if (_videoClips.isEmpty) {
// //       return Center(
// //         child: Text(
// //           'Tap + to add clips',
// //           style: TextStyle(color: Colors.grey[700], fontSize: 12),
// //         ),
// //       );
// //     }
// //
// //     return SingleChildScrollView(
// //       scrollDirection: Axis.horizontal,
// //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
// //       child: Row(
// //         children:
// //             _videoClips.asMap().entries.map((entry) {
// //               final index = entry.key;
// //               final clip = entry.value;
// //               final isSelected = _selectedClipIndex == index;
// //               return GestureDetector(
// //                 key: ValueKey(clip.filePath),
// //                 onTap: () => setState(() => _selectedClipIndex = index),
// //                 child: Container(
// //                   width:
// //                       (math
// //                           .max(80, clip.duration * pixelsPerSecond)
// //                           .clamp(60.0, 300.0)).toDouble(),
// //                   height: 56,
// //                   margin: const EdgeInsets.only(right: 6),
// //                   decoration: BoxDecoration(
// //                     color: isSelected ? Colors.white : const Color(0xFF2A2A2A),
// //                     borderRadius: BorderRadius.circular(4),
// //                     border: Border.all(
// //                       color:
// //                           isSelected ? Colors.white : const Color(0xFF3A3A3A),
// //                       width: isSelected ? 2 : 0.5,
// //                     ),
// //                   ),
// //                   child: Center(
// //                     child: Column(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         Icon(
// //                           Icons.videocam,
// //                           color: isSelected ? Colors.black : Colors.white70,
// //                           size: 20,
// //                         ),
// //                         const SizedBox(height: 4),
// //                         Text(
// //                           '${clip.duration.toStringAsFixed(1)}s',
// //                           style: TextStyle(
// //                             color: isSelected ? Colors.black : Colors.white70,
// //                             fontSize: 10,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               );
// //             }).toList(),
// //       ),
// //     );
// //   }
// //
// //   // ==================== BOTTOM TOOLBAR ====================
// //   Widget _buildBottomToolbar() {
// //     return Container(
// //       height: 200,
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF0A0A0A),
// //         border: Border(top: BorderSide(color: Colors.grey[900]!, width: 0.5)),
// //       ),
// //       child: Column(
// //         children: [_buildToolTabs(), Expanded(child: _buildToolPanel())],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildToolTabs() {
// //     final tools = [
// //       {'icon': Icons.content_cut, 'label': 'Edit'},
// //       {'icon': Icons.music_note, 'label': 'Audio'},
// //       {'icon': Icons.closed_caption_outlined, 'label': 'Caption'},
// //       {'icon': Icons.text_fields, 'label': 'Text'},
// //       {'icon': Icons.emoji_emotions_outlined, 'label': 'Sticker'},
// //       {'icon': Icons.auto_awesome_outlined, 'label': 'Effect'},
// //     ];
// //
// //     return Container(
// //       height: 56,
// //       padding: const EdgeInsets.symmetric(horizontal: 8),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceAround,
// //         children:
// //             tools.asMap().entries.map((entry) {
// //               final index = entry.key;
// //               final tool = entry.value;
// //               final isSelected = _selectedToolTab == index;
// //
// //               return Expanded(
// //                 child: GestureDetector(
// //                   onTap: () => setState(() => _selectedToolTab = index),
// //                   child: Container(
// //                     color: Colors.transparent,
// //                     child: Column(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         Icon(
// //                           tool['icon'] as IconData,
// //                           color:
// //                               isSelected
// //                                   ? Colors.white
// //                                   : const Color(0xFF606060),
// //                           size: 24,
// //                         ),
// //                         const SizedBox(height: 4),
// //                         Text(
// //                           tool['label'] as String,
// //                           style: TextStyle(
// //                             color:
// //                                 isSelected
// //                                     ? Colors.white
// //                                     : const Color(0xFF606060),
// //                             fontSize: 10,
// //                             fontWeight:
// //                                 isSelected
// //                                     ? FontWeight.w600
// //                                     : FontWeight.normal,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               );
// //             }).toList(),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildToolPanel() {
// //     switch (_selectedToolTab) {
// //       case 0:
// //         return _buildEditTools();
// //       case 1:
// //         return _buildAudioTools();
// //       case 2:
// //         return _buildCaptionTools();
// //       case 3:
// //         return _buildTextTools();
// //       case 4:
// //         return _buildStickerTools();
// //       case 5:
// //         return _buildEffectTools();
// //       default:
// //         return Container();
// //     }
// //   }
// //
// //   // ==================== EDIT TOOLS ====================
// //   Widget _buildEditTools() {
// //     final tools = [
// //       {'icon': Icons.content_cut, 'label': 'Split', 'onTap': _splitClip},
// //       {'icon': Icons.crop_free, 'label': 'Trim', 'onTap': _trimClip},
// //       {'icon': Icons.delete_outline, 'label': 'Delete', 'onTap': _deleteClip},
// //       {'icon': Icons.speed, 'label': 'Speed', 'onTap': _changeSpeed},
// //       {'icon': Icons.volume_up, 'label': 'Volume', 'onTap': _changeVolume},
// //       {'icon': Icons.flip, 'label': 'Flip', 'onTap': _flipClip},
// //       {'icon': Icons.copy, 'label': 'Copy', 'onTap': _duplicateClip},
// //       {'icon': Icons.crop, 'label': 'Crop', 'onTap': _cropClip},
// //       {
// //         'icon': Icons.rotate_90_degrees_ccw,
// //         'label': 'Rotate',
// //         'onTap': _rotateClip,
// //       },
// //       {
// //         'icon': Icons.swap_horiz,
// //         'label': 'Transition',
// //         'onTap': _setTransition,
// //       },
// //     ];
// //
// //     return GridView.builder(
// //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //         crossAxisCount: 5,
// //         mainAxisSpacing: 8,
// //         crossAxisSpacing: 6,
// //         childAspectRatio: 1.0,
// //       ),
// //       itemCount: tools.length,
// //       itemBuilder: (context, index) {
// //         final tool = tools[index];
// //         return _buildToolItem(
// //           tool['icon'] as IconData,
// //           tool['label'] as String,
// //           tool['onTap'] as VoidCallback,
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildToolItem(IconData icon, String label, VoidCallback onTap) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           Container(
// //             width: 40,
// //             height: 40,
// //             decoration: BoxDecoration(
// //               color: const Color(0xFF1A1A1A),
// //               borderRadius: BorderRadius.circular(6),
// //             ),
// //             child: Icon(icon, color: Colors.white, size: 20),
// //           ),
// //           const SizedBox(height: 3),
// //           Text(
// //             label,
// //             style: const TextStyle(color: Colors.white, fontSize: 9),
// //             textAlign: TextAlign.center,
// //             maxLines: 1,
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ==================== AUDIO TOOLS ====================
// //   Widget _buildAudioTools() {
// //     return Column(
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.all(16),
// //           child: Row(
// //             children: [
// //               Expanded(
// //                 child: _buildAudioButton(
// //                   'Music',
// //                   const Color(0xFFEF4444),
// //                   Icons.music_note,
// //                   _addMusic,
// //                 ),
// //               ),
// //               const SizedBox(width: 10),
// //               Expanded(
// //                 child: _buildAudioButton(
// //                   'Effects',
// //                   const Color(0xFF3B82F6),
// //                   Icons.graphic_eq,
// //                   () => _showSnackBar('Audio effects coming soon'),
// //                 ),
// //               ),
// //               const SizedBox(width: 10),
// //               Expanded(
// //                 child: _buildAudioButton(
// //                   'Voiceover',
// //                   const Color(0xFF8B5CF6),
// //                   Icons.mic,
// //                   _addVoiceover,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //         Expanded(
// //           child:
// //               _audioTracks.isEmpty
// //                   ? Center(
// //                     child: Text(
// //                       'No audio added',
// //                       style: TextStyle(color: Colors.grey[600], fontSize: 13),
// //                     ),
// //                   )
// //                   : ListView.builder(
// //                     padding: const EdgeInsets.symmetric(horizontal: 16),
// //                     itemCount: _audioTracks.length,
// //                     itemBuilder: (context, index) {
// //                       return Container(
// //                         margin: const EdgeInsets.only(bottom: 8),
// //                         padding: const EdgeInsets.all(10),
// //                         decoration: BoxDecoration(
// //                           color: const Color(0xFF1A1A1A),
// //                           borderRadius: BorderRadius.circular(6),
// //                         ),
// //                         child: Row(
// //                           children: [
// //                             const Icon(
// //                               Icons.music_note,
// //                               color: Colors.white,
// //                               size: 18,
// //                             ),
// //                             const SizedBox(width: 10),
// //                             Expanded(
// //                               child: Column(
// //                                 crossAxisAlignment: CrossAxisAlignment.start,
// //                                 children: [
// //                                   Text(
// //                                     _audioTracks[index].name,
// //                                     style: const TextStyle(
// //                                       color: Colors.white,
// //                                       fontSize: 12,
// //                                     ),
// //                                   ),
// //                                   const SizedBox(height: 2),
// //                                   Text(
// //                                     '${_audioTracks[index].duration.toStringAsFixed(1)}s',
// //                                     style: TextStyle(
// //                                       color: Colors.grey[600],
// //                                       fontSize: 10,
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                             IconButton(
// //                               icon: const Icon(
// //                                 Icons.delete_outline,
// //                                 color: Colors.grey,
// //                                 size: 18,
// //                               ),
// //                               onPressed:
// //                                   () => setState(() {
// //                                     _audioTracks[index].disposePlayer();
// //                                     _audioTracks.removeAt(index);
// //                                   }),
// //                               padding: EdgeInsets.zero,
// //                             ),
// //                           ],
// //                         ),
// //                       );
// //                     },
// //                   ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildAudioButton(
// //     String label,
// //     Color color,
// //     IconData icon,
// //     VoidCallback onTap,
// //   ) {
// //     return Material(
// //       color: color.withOpacity(0.15),
// //       borderRadius: BorderRadius.circular(6),
// //       child: InkWell(
// //         onTap: onTap,
// //         borderRadius: BorderRadius.circular(6),
// //         child: Container(
// //           padding: const EdgeInsets.symmetric(vertical: 12),
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               Icon(icon, color: color, size: 22),
// //               const SizedBox(height: 4),
// //               Text(
// //                 label,
// //                 style: TextStyle(
// //                   color: color,
// //                   fontSize: 11,
// //                   fontWeight: FontWeight.w500,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ==================== CAPTION TOOLS ====================
// //   Widget _buildCaptionTools() {
// //     return Padding(
// //       padding: const EdgeInsets.all(12),
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           _buildCaptionButton('Add text', Icons.add, _addTextOverlay),
// //           const SizedBox(height: 8),
// //           _buildCaptionButton('Auto caption', Icons.subtitles_outlined, () {
// //             _showSnackBar('Auto caption coming soon');
// //           }),
// //           const SizedBox(height: 8),
// //           _buildCaptionButton(
// //             'Text to speech',
// //             Icons.record_voice_over_outlined,
// //             () {
// //               _showSnackBar('Text to speech coming soon');
// //             },
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildCaptionButton(String label, IconData icon, VoidCallback onTap) {
// //     return Material(
// //       color: const Color(0xFF1A1A1A),
// //       borderRadius: BorderRadius.circular(6),
// //       child: InkWell(
// //         onTap: onTap,
// //         borderRadius: BorderRadius.circular(6),
// //         child: Container(
// //           height: 44,
// //           padding: const EdgeInsets.symmetric(horizontal: 14),
// //           child: Row(
// //             children: [
// //               Icon(icon, color: Colors.white, size: 20),
// //               const SizedBox(width: 10),
// //               Text(
// //                 label,
// //                 style: const TextStyle(
// //                   color: Colors.white,
// //                   fontSize: 13,
// //                   fontWeight: FontWeight.w500,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ==================== TEXT TOOLS ====================
// //   Widget _buildTextTools() {
// //     return Column(
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.all(16),
// //           child: Material(
// //             color: Colors.white,
// //             borderRadius: BorderRadius.circular(6),
// //             child: InkWell(
// //               onTap: _addTextOverlay,
// //               borderRadius: BorderRadius.circular(6),
// //               child: Container(
// //                 height: 48,
// //                 child: const Center(
// //                   child: Text(
// //                     'Add text',
// //                     style: TextStyle(
// //                       color: Colors.black,
// //                       fontSize: 15,
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //         Expanded(
// //           child: GridView.count(
// //             crossAxisCount: 3,
// //             padding: const EdgeInsets.symmetric(horizontal: 16),
// //             mainAxisSpacing: 8,
// //             crossAxisSpacing: 8,
// //             childAspectRatio: 1.0,
// //             children: [
// //               _buildTextStyleCard('Default'),
// //               _buildTextStyleCard('Bold'),
// //               _buildTextStyleCard('Neon'),
// //               _buildTextStyleCard('Writer'),
// //               _buildTextStyleCard('Glitch'),
// //               _buildTextStyleCard('3D'),
// //             ],
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildTextStyleCard(String style) {
// //     return GestureDetector(
// //       onTap: () => _applyTextStyle(style),
// //       child: Container(
// //         decoration: BoxDecoration(
// //           color: const Color(0xFF1A1A1A),
// //           borderRadius: BorderRadius.circular(6),
// //         ),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             const Text(
// //               'Aa',
// //               style: TextStyle(
// //                 color: Colors.white,
// //                 fontSize: 28,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             const SizedBox(height: 4),
// //             Text(
// //               style,
// //               style: const TextStyle(color: Color(0xFF808080), fontSize: 10),
// //               maxLines: 1,
// //               overflow: TextOverflow.ellipsis,
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ==================== STICKER TOOLS ====================
// //   Widget _buildStickerTools() {
// //     return Column(
// //       children: [
// //         // Search bar
// //         Padding(
// //           padding: const EdgeInsets.all(12),
// //           child: Container(
// //             height: 40,
// //             decoration: BoxDecoration(
// //               color: const Color(0xFF1A1A1A),
// //               borderRadius: BorderRadius.circular(20),
// //             ),
// //             child: Row(
// //               children: [
// //                 const SizedBox(width: 16),
// //                 Icon(Icons.search, color: Colors.grey[600], size: 20),
// //                 const SizedBox(width: 8),
// //                 Expanded(
// //                   child: TextField(
// //                     style: const TextStyle(color: Colors.white, fontSize: 14),
// //                     decoration: InputDecoration(
// //                       hintText: 'Search stickers',
// //                       hintStyle: TextStyle(
// //                         color: Colors.grey[600],
// //                         fontSize: 14,
// //                       ),
// //                       border: InputBorder.none,
// //                       isDense: true,
// //                       contentPadding: EdgeInsets.zero,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //         // Category tabs
// //         SizedBox(
// //           height: 32,
// //           child: ListView(
// //             scrollDirection: Axis.horizontal,
// //             padding: const EdgeInsets.symmetric(horizontal: 12),
// //             children:
// //                 ['Recents', 'Favorite', 'GIF', 'Trending', 'Birthday'].map((
// //                   category,
// //                 ) {
// //                   return Container(
// //                     margin: const EdgeInsets.only(right: 8),
// //                     child: Chip(
// //                       label: Text(
// //                         category,
// //                         style: const TextStyle(
// //                           color: Color(0xFF808080),
// //                           fontSize: 11,
// //                         ),
// //                       ),
// //                       backgroundColor: const Color(0xFF1A1A1A),
// //                       side: BorderSide.none,
// //                       padding: const EdgeInsets.symmetric(horizontal: 8),
// //                       labelPadding: EdgeInsets.zero,
// //                     ),
// //                   );
// //                 }).toList(),
// //           ),
// //         ),
// //         const SizedBox(height: 8),
// //         // Sticker grid
// //         Expanded(
// //           child: GridView.count(
// //             crossAxisCount: 3,
// //             padding: const EdgeInsets.symmetric(horizontal: 12),
// //             mainAxisSpacing: 8,
// //             crossAxisSpacing: 8,
// //             children: List.generate(9, (index) {
// //               final icons = [
// //                 Icons.emoji_emotions,
// //                 Icons.favorite,
// //                 Icons.star,
// //                 Icons.celebration,
// //                 Icons.flash_on,
// //                 Icons.wb_sunny,
// //                 Icons.cloud,
// //                 Icons.pets,
// //                 Icons.local_florist,
// //               ];
// //               return GestureDetector(
// //                 onTap: () => _addSticker('sticker_$index'),
// //                 child: Container(
// //                   decoration: BoxDecoration(
// //                     color: const Color(0xFF1A1A1A),
// //                     borderRadius: BorderRadius.circular(6),
// //                   ),
// //                   child: Column(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     children: [
// //                       Container(
// //                         width: 56,
// //                         height: 56,
// //                         decoration: BoxDecoration(
// //                           color: const Color(0xFF2A2A2A),
// //                           borderRadius: BorderRadius.circular(4),
// //                         ),
// //                         child: Icon(
// //                           icons[index],
// //                           size: 28,
// //                           color: Colors.white,
// //                         ),
// //                       ),
// //                       const SizedBox(height: 6),
// //                       const Text(
// //                         'Animation',
// //                         style: TextStyle(color: Color(0xFF606060), fontSize: 9),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               );
// //             }),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   // ==================== EFFECT TOOLS ====================
// //   Widget _buildEffectTools() {
// //     final effects = ['None', 'B&W', 'Sepia', 'Vintage', 'Glitch', 'Blur'];
// //     return GridView.count(
// //       crossAxisCount: 3,
// //       padding: const EdgeInsets.all(16),
// //       mainAxisSpacing: 10,
// //       crossAxisSpacing: 10,
// //       childAspectRatio: 1.2,
// //       children:
// //           effects.map((effect) {
// //             final isApplied =
// //                 _selectedClipIndex != null &&
// //                 _videoClips[_selectedClipIndex!].filterName == effect;
// //             return GestureDetector(
// //               onTap: () => _applyEffect(effect),
// //               child: Container(
// //                 decoration: BoxDecoration(
// //                   color: const Color(0xFF1A1A1A),
// //                   borderRadius: BorderRadius.circular(6),
// //                   border:
// //                       isApplied
// //                           ? Border.all(color: Colors.white, width: 2)
// //                           : null,
// //                 ),
// //                 child: Column(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Container(
// //                       width: 48,
// //                       height: 48,
// //                       decoration: BoxDecoration(
// //                         color: const Color(0xFF2A2A2A),
// //                         borderRadius: BorderRadius.circular(4),
// //                       ),
// //                       child: Icon(
// //                         Icons.filter,
// //                         color: isApplied ? Colors.white : Colors.grey[600],
// //                         size: 24,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 8),
// //                     Text(
// //                       effect,
// //                       style: TextStyle(
// //                         color:
// //                             isApplied ? Colors.white : const Color(0xFF808080),
// //                         fontSize: 11,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             );
// //           }).toList(),
// //     );
// //   }
// //
// //   // ==================== ACTION METHODS ====================
// //
// //   void _togglePlayback() async {
// //     setState(() => _isPlaying = !_isPlaying);
// //     if (_isPlaying) {
// //       await _updatePreviewController();
// //       _previewController?.play();
// //       for (var audio in _audioTracks) {
// //         if (_currentTime >= audio.startTime &&
// //             _currentTime < audio.startTime + audio.duration) {
// //           await audio.initPlayer();
// //           audio.player!.seek(
// //             Duration(
// //               milliseconds: ((_currentTime - audio.startTime) * 1000).toInt(),
// //             ),
// //           );
// //           audio.player!.resume();
// //           audio.player!.setVolume(audio.volume);
// //         }
// //       }
// //     } else {
// //       _pausePlayback();
// //     }
// //   }
// //
// //   Future<String?> _processVideoWithFFmpeg(
// //     String inputPath,
// //     String commandPart,
// //   ) async {
// //     Directory tempDir = await getTemporaryDirectory();
// //     String outputPath =
// //         '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
// //     String command = '-i "$inputPath" $commandPart "$outputPath"';
// //     final session = await FFmpegKit.execute(command);
// //     final returnCode = await session.getReturnCode();
// //     if (ReturnCode.isSuccess(returnCode)) {
// //       return outputPath;
// //     } else {
// //       _showSnackBar('Processing failed');
// //       return null;
// //     }
// //   }
// //
// //   Future<void> _addVideoClip() async {
// //     if (await Permission.photos.request().isGranted ||
// //         await Permission.storage.request().isGranted) {
// //       final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
// //       if (picked == null) return;
// //
// //       String path = picked.path;
// //       final controller = VideoPlayerController.file(File(path));
// //       await controller.initialize();
// //       double dur = controller.value.duration.inMilliseconds / 1000.0;
// //       await controller.dispose();
// //
// //       setState(() {
// //         _videoClips.add(
// //           VideoClip(
// //             name: picked.name ?? 'Video ${_videoClips.length + 1}',
// //             filePath: path,
// //             duration: dur,
// //             startTime: _totalDuration,
// //             originalDuration: dur,
// //           ),
// //         );
// //         _calculateTotalDuration();
// //       });
// //       _showSnackBar('Video clip added');
// //     } else {
// //       _showSnackBar('Permission denied');
// //     }
// //   }
// //
// //   Future<void> _trimClip() async {
// //     if (_selectedClipIndex == null) {
// //       _showSnackBar('Select a clip first');
// //       return;
// //     }
// //     final clip = _videoClips[_selectedClipIndex!];
// //     double newStart = clip.sourceStart;
// //     double newEnd = clip.sourceStart + clip.duration;
// //     final originalDur = clip.originalDuration;
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: const Color(0xFF1A1A1A),
// //       builder:
// //           (context) => StatefulBuilder(
// //             builder: (context, setBottomState) {
// //               return Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   const Text(
// //                     'Trim Clip',
// //                     style: TextStyle(
// //                       color: Colors.white,
// //                       fontSize: 17,
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                   ),
// //                   RangeSlider(
// //                     values: RangeValues(newStart, newEnd),
// //                     min: 0.0,
// //                     max: originalDur,
// //                     onChanged: (values) {
// //                       setBottomState(() {
// //                         newStart = values.start;
// //                         newEnd = values.end;
// //                       });
// //                     },
// //                   ),
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                     children: [
// //                       TextButton(
// //                         onPressed: () {
// //                           Navigator.pop(context);
// //                         },
// //                         child: const Text('Cancel'),
// //                       ),
// //                       TextButton(
// //                         onPressed: () async {
// //                           Navigator.pop(context);
// //                           final trimDur = newEnd - newStart;
// //                           final newPath = await _processVideoWithFFmpeg(
// //                             clip.filePath,
// //                             '-ss $newStart -t $trimDur -c copy',
// //                           );
// //                           if (newPath != null) {
// //                             await clip.disposeController();
// //                             setState(() {
// //                               clip.filePath = newPath;
// //                               clip.duration = trimDur;
// //                               clip.sourceStart = 0.0;
// //                               clip.originalDuration = trimDur;
// //                               _calculateTotalDuration();
// //                             });
// //                             _showSnackBar('Clip trimmed');
// //                           }
// //                         },
// //                         child: const Text('Apply'),
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               );
// //             },
// //           ),
// //     );
// //   }
// //
// //   Future<void> _splitClip() async {
// //     if (_selectedClipIndex == null) {
// //       _showSnackBar('Select a clip first');
// //       return;
// //     }
// //     final clip = _videoClips[_selectedClipIndex!];
// //     final splitPoint = _currentTime - clip.startTime;
// //     if (splitPoint <= 0 || splitPoint >= clip.duration) {
// //       _showSnackBar('Invalid split point');
// //       return;
// //     }
// //
// //     final firstDur = splitPoint;
// //     final secondDur = clip.duration - splitPoint;
// //
// //     final firstPath = await _processVideoWithFFmpeg(
// //       clip.filePath,
// //       '-ss 0 -t $firstDur -c copy',
// //     );
// //     final secondPath = await _processVideoWithFFmpeg(
// //       clip.filePath,
// //       '-ss $splitPoint -t $secondDur -c copy',
// //     );
// //
// //     if (firstPath != null && secondPath != null) {
// //       await clip.disposeController();
// //       setState(() {
// //         clip.filePath = firstPath;
// //         clip.duration = firstDur;
// //         clip.originalDuration = firstDur;
// //         final newClip = VideoClip(
// //           name: '${clip.name} (2)',
// //           filePath: secondPath,
// //           duration: secondDur,
// //           startTime: 0, // Will be updated
// //           originalDuration: secondDur,
// //         );
// //         _videoClips.insert(_selectedClipIndex! + 1, newClip);
// //         _calculateTotalDuration();
// //       });
// //       _showSnackBar('Clip split');
// //     }
// //   }
// //
// //   void _deleteClip() {
// //     if (_selectedClipIndex == null) {
// //       _showSnackBar('Select a clip first');
// //       return;
// //     }
// //     setState(() {
// //       _videoClips[_selectedClipIndex!].disposeController();
// //       _videoClips.removeAt(_selectedClipIndex!);
// //       _selectedClipIndex = null;
// //       _calculateTotalDuration();
// //     });
// //     _showSnackBar('Clip deleted');
// //   }
// //
// //   Future<void> _duplicateClip() async {
// //     if (_selectedClipIndex == null) {
// //       _showSnackBar('Select a clip first');
// //       return;
// //     }
// //     final original = _videoClips[_selectedClipIndex!];
// //     final newPath = await _processVideoWithFFmpeg(original.filePath, '-c copy');
// //     if (newPath != null) {
// //       setState(() {
// //         _videoClips.add(
// //           VideoClip(
// //             name: '${original.name} (Copy)',
// //             filePath: newPath,
// //             duration: original.duration,
// //             startTime: 0, // Updated later
// //             originalDuration: original.originalDuration,
// //             speed: original.speed,
// //             filterName: original.filterName,
// //             volume: original.volume,
// //           ),
// //         );
// //         _calculateTotalDuration();
// //       });
// //       _showSnackBar('Clip duplicated');
// //     }
// //   }
// //
// //   Future<void> _changeSpeed() async {
// //     if (_selectedClipIndex == null) {
// //       _showSnackBar('Select a clip first');
// //       return;
// //     }
// //     final clip = _videoClips[_selectedClipIndex!];
// //     double newSpeed = clip.speed;
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: const Color(0xFF1A1A1A),
// //       builder:
// //           (context) => StatefulBuilder(
// //             builder: (context, setBottomState) {
// //               return Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   const Text(
// //                     'Speed',
// //                     style: TextStyle(
// //                       color: Colors.white,
// //                       fontSize: 17,
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                   ),
// //                   Slider(
// //                     value: newSpeed,
// //                     min: 0.5,
// //                     max: 2.0,
// //                     divisions: 15,
// //                     label: '${newSpeed.toStringAsFixed(1)}x',
// //                     onChanged:
// //                         (value) => setBottomState(() => newSpeed = value),
// //                   ),
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                     children: [
// //                       TextButton(
// //                         onPressed: () {
// //                           Navigator.pop(context);
// //                         },
// //                         child: const Text('Cancel'),
// //                       ),
// //                       TextButton(
// //                         onPressed: () async {
// //                           Navigator.pop(context);
// //                           final pts = 1 / newSpeed;
// //                           final atempo = newSpeed;
// //                           final newPath = await _processVideoWithFFmpeg(
// //                             clip.filePath,
// //                             '-filter:v "setpts=$pts*PTS" -filter:a "atempo=$atempo"',
// //                           );
// //                           if (newPath != null) {
// //                             await clip.disposeController();
// //                             setState(() {
// //                               clip.filePath = newPath;
// //                               clip.duration = clip.duration / newSpeed;
// //                               clip.speed = newSpeed;
// //                               clip.originalDuration = clip.duration;
// //                               _calculateTotalDuration();
// //                             });
// //                             _showSnackBar('Speed changed to ${newSpeed}x');
// //                           }
// //                         },
// //                         child: const Text('Apply'),
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               );
// //             },
// //           ),
// //     );
// //   }
// //
// //   Future<void> _changeVolume() async {
// //     if (_selectedClipIndex == null) {
// //       _showSnackBar('Select a clip first');
// //       return;
// //     }
// //     final clip = _videoClips[_selectedClipIndex!];
// //     double newVolume = clip.volume;
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: const Color(0xFF1A1A1A),
// //       builder:
// //           (context) => StatefulBuilder(
// //             builder: (context, setBottomState) {
// //               return Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   const Text(
// //                     'Volume',
// //                     style: TextStyle(
// //                       color: Colors.white,
// //                       fontSize: 17,
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                   ),
// //                   Slider(
// //                     value: newVolume,
// //                     min: 0.0,
// //                     max: 1.0,
// //                     label: '${(newVolume * 100).toInt()}%',
// //                     onChanged:
// //                         (value) => setBottomState(() => newVolume = value),
// //                   ),
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                     children: [
// //                       TextButton(
// //                         onPressed: () {
// //                           Navigator.pop(context);
// //                         },
// //                         child: const Text('Cancel'),
// //                       ),
// //                       TextButton(
// //                         onPressed: () {
// //                           Navigator.pop(context);
// //                           setState(() => clip.volume = newVolume);
// //                           _previewController?.setVolume(newVolume);
// //                           _showSnackBar(
// //                             'Volume set to ${(newVolume * 100).toInt()}%',
// //                           );
// //                         },
// //                         child: const Text('Apply'),
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               );
// //             },
// //           ),
// //     );
// //   }
// //
// //   Future<void> _flipClip() async {
// //     if (_selectedClipIndex == null) {
// //       _showSnackBar('Select a clip first');
// //       return;
// //     }
// //     final clip = _videoClips[_selectedClipIndex!];
// //     final newPath = await _processVideoWithFFmpeg(clip.filePath, '-vf hflip');
// //     if (newPath != null) {
// //       await clip.disposeController();
// //       setState(() => clip.filePath = newPath);
// //       _showSnackBar('Clip flipped');
// //     }
// //   }
// //
// //   Future<void> _rotateClip() async {
// //     if (_selectedClipIndex == null) {
// //       _showSnackBar('Select a clip first');
// //       return;
// //     }
// //     final clip = _videoClips[_selectedClipIndex!];
// //     final newPath = await _processVideoWithFFmpeg(
// //       clip.filePath,
// //       '-vf transpose=1',
// //     );
// //     if (newPath != null) {
// //       await clip.disposeController();
// //       setState(() => clip.filePath = newPath);
// //       _showSnackBar('Clip rotated');
// //     }
// //   }
// //
// //   Future<void> _cropClip() async {
// //     if (_selectedClipIndex == null) {
// //       _showSnackBar('Select a clip first');
// //       return;
// //     }
// //     final clip = _videoClips[_selectedClipIndex!];
// //     final newPath = await _processVideoWithFFmpeg(
// //       clip.filePath,
// //       '-vf crop=iw/2:ih/2:0:0',
// //     );
// //     if (newPath != null) {
// //       await clip.disposeController();
// //       setState(() => clip.filePath = newPath);
// //       _showSnackBar('Clip cropped');
// //     }
// //   }
// //
// //   void _setTransition() {
// //     if (_selectedClipIndex == null ||
// //         _selectedClipIndex == _videoClips.length - 1) {
// //       _showSnackBar('Select a clip with next clip');
// //       return;
// //     }
// //     setState(() {
// //       _videoClips[_selectedClipIndex!].transitionType = 'fade';
// //     });
// //     _showSnackBar('Fade transition set');
// //   }
// //
// //   Future<void> _addMusic() async {
// //     final result = await FilePicker.platform.pickFiles(type: FileType.audio);
// //     if (result == null) return;
// //     final path = result.files.first.path!;
// //     final player = AudioPlayer();
// //     await player.setSourceDeviceFile(path);
// //     final dur = (await player.getDuration())!.inMilliseconds / 1000.0;
// //     await player.dispose();
// //     setState(() {
// //       _audioTracks.add(
// //         AudioTrack(
// //           name: result.files.first.name,
// //           filePath: path,
// //           startTime: _currentTime,
// //           duration: dur,
// //         ),
// //       );
// //     });
// //     _showSnackBar('Music added');
// //   }
// //
// //   Future<void> _addVoiceover() async {
// //     _showSnackBar('Voiceover recording coming soon, picking file instead');
// //     await _addMusic();
// //   }
// //
// //   void _addTextOverlay() {
// //     String textInput = '';
// //     showDialog(
// //       context: context,
// //       builder: (context) {
// //         return AlertDialog(
// //           backgroundColor: const Color(0xFF1A1A1A),
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //           title: const Text(
// //             'Add Text',
// //             style: TextStyle(color: Colors.white, fontSize: 17),
// //           ),
// //           content: TextField(
// //             autofocus: true,
// //             style: const TextStyle(color: Colors.white, fontSize: 15),
// //             decoration: InputDecoration(
// //               hintText: 'Enter text',
// //               hintStyle: TextStyle(color: Colors.grey[600]),
// //               enabledBorder: UnderlineInputBorder(
// //                 borderSide: BorderSide(color: Colors.grey[700]!),
// //               ),
// //               focusedBorder: const UnderlineInputBorder(
// //                 borderSide: BorderSide(color: Colors.white, width: 2),
// //               ),
// //             ),
// //             onChanged: (value) => textInput = value,
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.pop(context),
// //               child: Text(
// //                 'Cancel',
// //                 style: TextStyle(color: Colors.grey[500], fontSize: 15),
// //               ),
// //             ),
// //             TextButton(
// //               onPressed: () {
// //                 if (textInput.isNotEmpty) {
// //                   setState(() {
// //                     _textOverlays.add(
// //                       TextOverlay(
// //                         text: textInput,
// //                         x: 100,
// //                         y: 200,
// //                         startTime: _currentTime,
// //                         endTime: _currentTime + 3.0,
// //                       ),
// //                     );
// //                   });
// //                   Navigator.pop(context);
// //                   _showSnackBar('Text added');
// //                 }
// //               },
// //               child: const Text(
// //                 'Add',
// //                 style: TextStyle(
// //                   color: Colors.white,
// //                   fontSize: 15,
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   void _applyTextStyle(String style) {
// //     if (_selectedTextIndex == null) {
// //       _showSnackBar('Select a text first');
// //       return;
// //     }
// //     setState(() {
// //       final overlay = _textOverlays[_selectedTextIndex!];
// //       switch (style) {
// //         case 'Bold':
// //           overlay.fontWeight = FontWeight.w900;
// //           break;
// //         case 'Neon':
// //           overlay.color = const Color(0xFF00FFFF);
// //           break;
// //         default:
// //           overlay.fontWeight = FontWeight.bold;
// //       }
// //     });
// //     _showSnackBar('$style applied');
// //   }
// //
// //   void _addSticker(String id) {
// //     setState(() {
// //       _stickers.add(
// //         StickerOverlay(
// //           assetPath: 'assets/stickers/$id.png',
// //           x: 150,
// //           y: 300,
// //           startTime: _currentTime,
// //           endTime: _currentTime + 3.0,
// //         ),
// //       );
// //     });
// //     _showSnackBar('Sticker added');
// //   }
// //
// //   Future<void> _applyEffect(String effectName) async {
// //     if (_selectedClipIndex == null) {
// //       _showSnackBar('Select a clip first');
// //       return;
// //     }
// //     final clip = _videoClips[_selectedClipIndex!];
// //     final filter = _ffmpegFilters[effectName];
// //     if (filter == null && effectName != 'None') return;
// //
// //     String commandPart = filter != null ? '-vf "$filter"' : '';
// //     final newPath = await _processVideoWithFFmpeg(clip.filePath, commandPart);
// //     if (newPath != null) {
// //       await clip.disposeController();
// //       setState(() {
// //         clip.filePath = newPath;
// //         clip.filterName = effectName == 'None' ? null : effectName;
// //       });
// //       _showSnackBar('$effectName applied');
// //     }
// //   }
// //
// //   Future<void> _exportVideo() async {
// //     if (_videoClips.isEmpty) return;
// //
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (context) => const Center(child: CircularProgressIndicator()),
// //     );
// //
// //     Directory tempDir = await getTemporaryDirectory();
// //     String outputPath = '${tempDir.path}/exported_video.mp4';
// //
// //     // Build FFmpeg command
// //     String inputArgs = '';
// //     String videoFilterComplex = '';
// //     String audioFilterComplex = '';
// //     String map = '-map "[v]" -map "[a]"';
// //
// //     // For videos: concat with transitions if any
// //     double currentTime = 0.0;
// //     String vInputs = _videoClips
// //         .asMap()
// //         .entries
// //         .map((e) => '-i "${e.value.filePath}"')
// //         .join(' ');
// //     String vChain = '';
// //     for (int i = 0; i < _videoClips.length; i++) {
// //       final clip = _videoClips[i];
// //       vChain += '[$i:v]settb=AV_TB[v$i]; ';
// //       if (i > 0) {
// //         final prevClip = _videoClips[i - 1];
// //         final transType = prevClip.transitionType ?? 'none';
// //         final transDur = prevClip.transitionDuration;
// //         final offset = currentTime - transDur;
// //         String trans = 'fade';
// //         if (transType == 'slide') trans = 'slideleft'; // Example
// //         vChain +=
// //             '[v${i - 1}][v$i]xfade=transition=$trans:duration=$transDur:offset=$offset [vv$i]; ';
// //         vChain += '[vv$i]';
// //       } else {
// //         vChain += '[v0]';
// //       }
// //       currentTime += clip.duration;
// //     }
// //     videoFilterComplex =
// //         vChain.substring(0, vChain.length - 1) + '[v]; '; // Remove last [
// //
// //     // For audios: similar for acrossfade
// //     String aChain = '';
// //     for (int i = 0; i < _videoClips.length; i++) {
// //       aChain += '[$i:a]asetrate=44100[a$i]; ';
// //       if (i > 0) {
// //         final prevClip = _videoClips[i - 1];
// //         final transDur = prevClip.transitionDuration;
// //         final offset = currentTime - _videoClips[i].duration - transDur;
// //         aChain += '[a${i - 1}][a$i]acrossfade=d=$transDur [aa$i]; ';
// //         aChain += '[aa$i]';
// //       } else {
// //         aChain += '[a0]';
// //       }
// //     }
// //     audioFilterComplex =
// //         aChain.substring(0, aChain.length - 1) +
// //         '[maina]; '; // Main video audio
// //
// //     // Add additional audio tracks
// //     int audioIndex = _videoClips.length;
// //     String additionalAudioInputs = '';
// //     String additionalAudioFilters = '';
// //     for (var audio in _audioTracks) {
// //       additionalAudioInputs += '-i "${audio.filePath}" ';
// //       final delay = audio.startTime * 1000;
// //       additionalAudioFilters +=
// //           '[$audioIndex:a]adelay=$delay|$delay,volume=${audio.volume}[add$audioIndex]; ';
// //       audioFilterComplex +=
// //           '[maina][add$audioIndex]amix=inputs=2:duration=longest [maina]; ';
// //       audioIndex++;
// //     }
// //
// //     // Add overlays: text and stickers
// //     String overlayChain = '[v]';
// //     int overlayIndex = audioIndex;
// //     for (var text in _textOverlays) {
// //       final globalStart = text.startTime;
// //       final globalEnd = text.endTime;
// //       final fs = text.fontSize;
// //       final col = 'white'; // Convert color
// //       overlayChain +=
// //           'drawtext=text=\'${text.text}\':x=${text.x}:y=${text.y}:fontsize=$fs:fontcolor=$col:enable=\'between(t,$globalStart,$globalEnd)\' [v$overlayIndex]; ';
// //       overlayIndex++;
// //     }
// //     for (var sticker in _stickers) {
// //       additionalAudioInputs += '-i "${sticker.assetPath}" '; // Sticker is image
// //       final globalStart = sticker.startTime;
// //       final globalEnd = sticker.endTime;
// //       overlayChain +=
// //           '[v${overlayIndex - 1}][$overlayIndex]overlay=${sticker.x}:${sticker.y}:enable=\'between(t,$globalStart,$globalEnd)\' [v$overlayIndex]; ';
// //       overlayIndex++;
// //     }
// //     videoFilterComplex +=
// //         additionalAudioFilters +
// //         overlayChain.substring(0, overlayChain.length - 1) +
// //         '[v]; ' +
// //         audioFilterComplex;
// //
// //     String command =
// //         '$vInputs $additionalAudioInputs -filter_complex "$videoFilterComplex" $map "$outputPath"';
// //
// //     final session = await FFmpegKit.execute(command);
// //     final returnCode = await session.getReturnCode();
// //     Navigator.pop(context);
// //     if (ReturnCode.isSuccess(returnCode)) {
// //       _showSnackBar('Exported to $outputPath');
// //     } else {
// //       _showSnackBar('Export failed');
// //     }
// //   }
// //
// //   void _showSnackBar(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(fontSize: 13)),
// //         duration: const Duration(seconds: 2),
// //         behavior: SnackBarBehavior.floating,
// //         backgroundColor: const Color(0xFF2A2A2A),
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
// //       ),
// //     );
// //   }
// //
// //   String _formatTime(double seconds) {
// //     final minutes = (seconds / 60).floor();
// //     final secs = (seconds % 60).floor();
// //     final millis = ((seconds % 1) * 10).floor();
// //     return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.$millis';
// //   }
// // }
//
// // pubspec.yaml dependencies needed:
// // video_player: ^2.8.0
// // image_picker: ^1.0.0
// // path_provider: ^2.1.0
// // permission_handler: ^11.0.0
// // audioplayers: ^5.0.0
// // file_picker: ^6.0.0
// // ffmpeg_kit_flutter_min_gpl: ^6.0.3
// // flutter/services.dart for assets
//
// import 'dart:async';
// import 'dart:io';
// import 'dart:math' as math;
// import 'dart:ui' as ui;
//
// import 'package:audioplayers/audioplayers.dart';
// import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_min_gpl/return_code.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:video_player/video_player.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
//
// void main() {
//   runApp(const KwaiCutCloneApp());
// }
//
// class KwaiCutCloneApp extends StatelessWidget {
//   const KwaiCutCloneApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'KwaiCut',
//       theme: ThemeData.dark().copyWith(
//         primaryColor: const Color(0xFF8B5CF6),
//         scaffoldBackgroundColor: const Color(0xFF000000),
//         colorScheme: const ColorScheme.dark(
//           primary: Color(0xFF8B5CF6),
//           secondary: Color(0xFF8B5CF6),
//         ),
//       ),
//       home: const HomeScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
//
// // ==================== DATA MODELS ====================
// class VideoClip {
//   String name;
//   String filePath;
//   String? thumbnailPath;
//   double duration;
//   double startTime;
//   double speed;
//   String? filterName;
//   double volume;
//   String? transitionType;
//   double transitionDuration;
//   VideoPlayerController? _controller;
//   double sourceStart;
//   double originalDuration;
//
//   VideoClip({
//     required this.name,
//     required this.filePath,
//     this.thumbnailPath,
//     required this.duration,
//     required this.startTime,
//     required this.originalDuration,
//     this.filterName,
//     this.speed = 1.0,
//     this.volume = 1.0,
//     this.transitionType,
//     this.transitionDuration = 0.5,
//     this.sourceStart = 0.0,
//   });
//
//   Future<void> initController() async {
//     if (_controller == null) {
//       _controller = VideoPlayerController.file(File(filePath));
//       await _controller!.initialize();
//       _controller!.setLooping(false);
//       await applyVolume();
//       await _controller!.setPlaybackSpeed(speed);
//     }
//   }
//
//   Future<void> applyVolume() async {
//     if (_controller != null) {
//       await _controller!.setVolume(volume);
//     }
//   }
//
//   Future<void> disposeController() async {
//     await _controller?.dispose();
//     _controller = null;
//   }
// }
//
// class TextOverlay {
//   String text;
//   double x;
//   double y;
//   double fontSize = 32;
//   Color color = Colors.white;
//   FontWeight fontWeight = FontWeight.bold;
//   double startTime;
//   double endTime;
//   String? animationType;
//   double scale = 1.0;
//   double rotation = 0.0;
//
//   TextOverlay({
//     required this.text,
//     required this.x,
//     required this.y,
//     required this.startTime,
//     required this.endTime,
//   });
// }
//
// class StickerOverlay {
//   String assetPath;
//   double x;
//   double y;
//   double scale = 1.0;
//   double rotation = 0.0;
//   double startTime;
//   double endTime;
//
//   StickerOverlay({
//     required this.assetPath,
//     required this.x,
//     required this.y,
//     required this.startTime,
//     required this.endTime,
//   });
// }
//
// class AudioTrack {
//   String name;
//   String filePath;
//   double startTime;
//   double duration;
//   double volume = 1.0;
//   AudioPlayer? player;
//
//   AudioTrack({
//     required this.name,
//     required this.filePath,
//     required this.startTime,
//     required this.duration,
//   });
//
//   Future<void> initPlayer() async {
//     if (player == null) {
//       player = AudioPlayer();
//       await player!.setSourceDeviceFile(filePath);
//     }
//   }
//
//   Future<void> disposePlayer() async {
//     await player?.dispose();
//     player = null;
//   }
// }
//
// // ==================== HOME SCREEN ====================
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _selectedIndex == 0
//           ? const ProjectsScreen()
//           : const Center(child: Text('Coming Soon')),
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.black,
//           border: Border(top: BorderSide(color: Colors.grey[900]!, width: 0.5)),
//         ),
//         child: SafeArea(
//           child: SizedBox(
//             height: 56,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildNavItem(0, Icons.home, 'Home'),
//                 _buildNavItem(1, Icons.explore_outlined, 'Discover'),
//                 _buildNavItem(2, Icons.add_box_outlined, 'Create'),
//                 _buildNavItem(3, Icons.person_outline, 'Me'),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNavItem(int index, IconData icon, String label) {
//     final isSelected = _selectedIndex == index;
//     return GestureDetector(
//       onTap: () => setState(() => _selectedIndex = index),
//       child: Container(
//         color: Colors.transparent,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
//               size: 24,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
//                 fontSize: 10,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ==================== PROJECTS SCREEN ====================
// class ProjectsScreen extends StatelessWidget {
//   const ProjectsScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         title: const Text(
//           'Projects',
//           style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search, size: 24),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.more_vert, size: 24),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: GridView.builder(
//         padding: const EdgeInsets.all(12),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           crossAxisSpacing: 10,
//           mainAxisSpacing: 10,
//           childAspectRatio: 9 / 16,
//         ),
//         itemCount: 8,
//         itemBuilder: (context, index) {
//           return GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const VideoEditorScreen()),
//               );
//             },
//             child: Container(
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1A1A),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: 56,
//                     height: 56,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF2A2A2A),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.play_arrow,
//                       size: 28,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     'Draft ${index + 1}',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     'Edited ${index + 1}h ago',
//                     style: TextStyle(color: Colors.grey[600], fontSize: 11),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         child: FloatingActionButton.extended(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const VideoEditorScreen()),
//             );
//           },
//           backgroundColor: Theme.of(context).primaryColor,
//           elevation: 4,
//           label: const Row(
//             children: [
//               Icon(Icons.add, size: 20),
//               SizedBox(width: 6),
//               Text(
//                 'New project',
//                 style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
//               ),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//     );
//   }
// }
//
// // ==================== VIDEO EDITOR SCREEN ====================
// class VideoEditorScreen extends StatefulWidget {
//   const VideoEditorScreen({super.key});
//
//   @override
//   State<VideoEditorScreen> createState() => _VideoEditorScreenState();
// }
//
// class _VideoEditorScreenState extends State<VideoEditorScreen> {
//   final List<VideoClip> _videoClips = [];
//   final List<TextOverlay> _textOverlays = [];
//   final List<AudioTrack> _audioTracks = [];
//   final List<StickerOverlay> _stickers = [];
//
//   double _currentTime = 0.0;
//   double _totalDuration = 0.0;
//   bool _isPlaying = false;
//   Timer? _playbackTimer;
//
//   int _selectedToolTab = 0;
//   int? _selectedClipIndex;
//   int? _selectedTextIndex;
//   int? _selectedStickerIndex;
//   double _canvasScale = 1.0;
//
//   VideoPlayerController? _previewController;
//   VoidCallback? _previewListener;
//
//   final double pixelsPerSecond = 10.0;
//
//   final Map<String, ColorFilter> _previewFilters = {
//     'B&W': const ColorFilter.mode(Colors.grey, BlendMode.saturation),
//     'Sepia': ColorFilter.matrix(<double>[
//       0.393,
//       0.769,
//       0.189,
//       0,
//       0,
//       0.349,
//       0.686,
//       0.168,
//       0,
//       0,
//       0.272,
//       0.534,
//       0.131,
//       0,
//       0,
//       0,
//       0,
//       0,
//       1,
//       0,
//     ]),
//     'Vintage': ColorFilter.matrix(<double>[
//       0.6279345635105574,
//       0.3202480219227092,
//       -0.03965408290255167,
//       0,
//       9.651965935734187,
//       0.02578397707665873,
//       0.6441185285476414,
//       0.03259129187565881,
//       0,
//       7.462829176470147,
//       0.04653277737452861,
//       0.0857188940096518,
//       0.8127045049852926,
//       0,
//       3.455209805512038,
//       0,
//       0,
//       0,
//       1,
//       0,
//     ]),
//     'Glitch': ColorFilter.matrix(<double>[
//       1,
//       0,
//       0,
//       0,
//       0,
//       0,
//       1,
//       0,
//       0,
//       0,
//       0,
//       0,
//       1,
//       0,
//       0,
//       0,
//       0,
//       0,
//       1,
//       0,
//     ]),
//     'Blur': const ColorFilter.mode(Colors.transparent, BlendMode.dst),
//   };
//
//   Map<String, String> _ffmpegFilters = {
//     'B&W': 'hue=s=0',
//     'Sepia': 'colorchannelmixer=.393:.769:.189:.349:.686:.168:.272:.534:.131',
//     'Vintage': 'curves=r="0/0.11 0.42/0.51 1/0.95":g="0/0.50 0.48/0.22 1/0.95":b="0/0.31 0.47/0.85 1/0.95"',
//     'Glitch': 'geq=r=abs(r(X,Y)-0.1*random(1)*255):g=abs(g(X,Y)-0.1*random(1)*255):b=abs(b(X,Y)-0.1*random(1)*255)',
//     'Blur': 'boxblur=2:1',
//   };
//
//   @override
//   void initState() {
//     super.initState();
//     _initPreviewListener();
//   }
//
//   @override
//   void dispose() {
//     _playbackTimer?.cancel();
//     _previewController?.removeListener(_previewListener!);
//     _previewController?.dispose();
//     for (var clip in _videoClips) {
//       clip.disposeController();
//     }
//     for (var audio in _audioTracks) {
//       audio.disposePlayer();
//     }
//     super.dispose();
//   }
//
//   void _initPreviewListener() {
//     _previewListener = () {
//       if (_previewController == null || !_previewController!.value.isInitialized) return;
//
//       final clip = activeClip;
//       if (clip == null) return;
//
//       final position = _previewController!.value.position.inMilliseconds / 1000.0;
//       if (mounted) {
//         setState(() => _currentTime = clip.startTime + position);
//       }
//
//       if (position >= clip.duration) {
//         if (_selectedClipIndex == _videoClips.length - 1) {
//           _pausePlayback();
//         } else {
//           _nextClip();
//         }
//       }
//     };
//   }
//
//   void _calculateTotalDuration() {
//     if (_videoClips.isEmpty) {
//       _totalDuration = 0.0;
//       return;
//     }
//     double currentStart = 0.0;
//     for (var clip in _videoClips) {
//       clip.startTime = currentStart;
//       currentStart += clip.duration;
//     }
//     _totalDuration = currentStart;
//   }
//
//   VideoClip? get activeClip {
//     for (var clip in _videoClips) {
//       if (_currentTime >= clip.startTime && _currentTime < clip.startTime + clip.duration) {
//         return clip;
//       }
//     }
//     return _videoClips.isNotEmpty ? _videoClips.first : null;
//   }
//
//   Future<void> _updatePreviewController() async {
//     final clip = activeClip;
//     if (clip == null) return;
//
//     await clip.initController();
//     if (_previewController != clip._controller) {
//       _previewController?.pause();
//       _previewController?.removeListener(_previewListener!);
//       _previewController = clip._controller;
//       if (_previewController != null) {
//         _previewController!.addListener(_previewListener!);
//         await _previewController!.setPlaybackSpeed(clip.speed);
//         await _previewController!.setVolume(clip.volume);
//       }
//     }
//
//     final localTime = _currentTime - clip.startTime;
//     if (_previewController != null) {
//       await _previewController!.seekTo(
//         Duration(milliseconds: (localTime * 1000).toInt()),
//       );
//     }
//   }
//
//   void _nextClip() {
//     final currentIndex = _videoClips.indexWhere((clip) => clip.startTime <= _currentTime && _currentTime < clip.startTime + clip.duration);
//     if (currentIndex < _videoClips.length - 1) {
//       setState(() {
//         _selectedClipIndex = currentIndex + 1;
//         _currentTime = _videoClips[currentIndex + 1].startTime;
//       });
//       _updatePreviewController();
//       if (_isPlaying) {
//         _previewController?.play();
//       }
//     } else {
//       _pausePlayback();
//     }
//   }
//
//   void _pausePlayback() {
//     setState(() => _isPlaying = false);
//     _previewController?.pause();
//     for (var audio in _audioTracks) {
//       audio.player?.pause();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildTopBar(),
//             Expanded(child: _buildPreviewCanvas()),
//             _buildTimelineSection(),
//             _buildBottomToolbar(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ==================== TOP BAR ====================
//   Widget _buildTopBar() {
//     return Container(
//       height: 48,
//       padding: const EdgeInsets.symmetric(horizontal: 4),
//       decoration: BoxDecoration(
//         color: Colors.black,
//         border: Border(
//           bottom: BorderSide(color: Colors.grey[900]!, width: 0.5),
//         ),
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
//             onPressed: () => Navigator.pop(context),
//             padding: EdgeInsets.zero,
//           ),
//           IconButton(
//             icon: const Icon(Icons.help_outline, color: Colors.white, size: 22),
//             onPressed: () {},
//             padding: EdgeInsets.zero,
//           ),
//           const Spacer(),
//           IconButton(
//             icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
//             onPressed: () {},
//             padding: EdgeInsets.zero,
//           ),
//           Container(
//             margin: const EdgeInsets.only(left: 4, right: 4),
//             child: Material(
//               color: Theme.of(context).primaryColor,
//               borderRadius: BorderRadius.circular(20),
//               child: InkWell(
//                 onTap: _videoClips.isNotEmpty ? _exportVideo : null,
//                 borderRadius: BorderRadius.circular(20),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 8,
//                   ),
//                   child: const Text(
//                     'Export',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==================== PREVIEW CANVAS ====================
//   Widget _buildPreviewCanvas() {
//     return Container(
//       color: Colors.black,
//       child: Center(
//         child: AspectRatio(
//           aspectRatio: 9 / 16,
//           child: GestureDetector(
//             onScaleUpdate: (details) {
//               setState(() => _canvasScale = details.scale.clamp(0.5, 3.0));
//             },
//             child: Transform.scale(
//               scale: _canvasScale,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF0D0D0D),
//                   border: Border.all(
//                     color: const Color(0xFF2A2A2A),
//                     width: 0.5,
//                   ),
//                 ),
//                 child: Stack(
//                   children: [
//                     _buildVideoLayer(),
//                     ..._buildTextOverlays(),
//                     ..._buildStickers(),
//                     if (_videoClips.isEmpty) _buildEmptyState(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildVideoLayer() {
//     final clip = activeClip;
//     if (clip == null || _previewController == null || !_previewController!.value.isInitialized) {
//       return Container(
//         color: const Color(0xFF1A1A1A),
//         child: const Center(
//           child: Icon(Icons.play_circle_outline, size: 64, color: Colors.grey),
//         ),
//       );
//     }
//
//     Widget player = VideoPlayer(_previewController!);
//
//     if (clip.filterName != null && _previewFilters.containsKey(clip.filterName)) {
//       player = ColorFiltered(
//         colorFilter: _previewFilters[clip.filterName]!,
//         child: player,
//       );
//     }
//
//     return player;
//   }
//
//   List<Widget> _buildTextOverlays() {
//     return _textOverlays.asMap().entries.where((entry) {
//       final overlay = entry.value;
//       return _currentTime >= overlay.startTime && _currentTime < overlay.endTime;
//     }).map((entry) {
//       final index = entry.key;
//       final overlay = entry.value;
//       return Positioned(
//         left: overlay.x,
//         top: overlay.y,
//         child: GestureDetector(
//           onTap: () => setState(() => _selectedTextIndex = index),
//           onPanUpdate: (details) {
//             setState(() {
//               overlay.x += details.delta.dx / _canvasScale;
//               overlay.y += details.delta.dy / _canvasScale;
//             });
//           },
//           onScaleUpdate: (details) {
//             setState(() {
//               overlay.scale = (overlay.scale * details.scale).clamp(0.5, 3.0);
//               overlay.rotation += details.rotation;
//             });
//           },
//           child: Transform.scale(
//             scale: overlay.scale,
//             child: Transform.rotate(
//               angle: overlay.rotation,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   border: _selectedTextIndex == index ? Border.all(color: Colors.white, width: 1.5) : null,
//                 ),
//                 child: Text(
//                   overlay.text,
//                   style: TextStyle(
//                     color: overlay.color,
//                     fontSize: overlay.fontSize,
//                     fontWeight: overlay.fontWeight,
//                     shadows: const [
//                       Shadow(
//                         blurRadius: 8,
//                         color: Colors.black54,
//                         offset: Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     }).toList();
//   }
//
//   List<Widget> _buildStickers() {
//     return _stickers.asMap().entries.where((entry) {
//       final sticker = entry.value;
//       return _currentTime >= sticker.startTime && _currentTime < sticker.endTime;
//     }).map((entry) {
//       final index = entry.key;
//       final sticker = entry.value;
//       return Positioned(
//         left: sticker.x,
//         top: sticker.y,
//         child: GestureDetector(
//           onTap: () => setState(() => _selectedStickerIndex = index),
//           onPanUpdate: (details) {
//             setState(() {
//               sticker.x += details.delta.dx / _canvasScale;
//               sticker.y += details.delta.dy / _canvasScale;
//             });
//           },
//           onScaleUpdate: (details) {
//             setState(() {
//               sticker.scale = (sticker.scale * details.scale).clamp(0.5, 3.0);
//               sticker.rotation += details.rotation;
//             });
//           },
//           child: Container(
//             decoration: BoxDecoration(
//               border: _selectedStickerIndex == index ? Border.all(color: Colors.white, width: 1.5) : null,
//             ),
//             child: Transform.scale(
//               scale: sticker.scale,
//               child: Transform.rotate(
//                 angle: sticker.rotation,
//                 child: Image.asset(sticker.assetPath, width: 48, height: 48),
//               ),
//             ),
//           ),
//         ),
//       );
//     }).toList();
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.video_library_outlined, size: 72, color: Colors.grey[800]),
//           const SizedBox(height: 20),
//           Material(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(6),
//             child: InkWell(
//               onTap: _addVideoClips,
//               borderRadius: BorderRadius.circular(6),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
//                 child: const Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.add, size: 18, color: Colors.black),
//                     SizedBox(width: 6),
//                     Text(
//                       'Add videos',
//                       style: TextStyle(
//                         color: Colors.black,
//                         fontSize: 15,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==================== TIMELINE SECTION ====================
//   Widget _buildTimelineSection() {
//     return Container(
//       height: 140,
//       decoration: BoxDecoration(
//         color: const Color(0xFF0A0A0A),
//         border: Border(top: BorderSide(color: Colors.grey[900]!, width: 0.5)),
//       ),
//       child: Column(
//         children: [
//           _buildPlaybackControls(),
//           const Divider(height: 1, thickness: 0.5, color: Color(0xFF2A2A2A)),
//           Expanded(child: _buildTimeline()),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPlaybackControls() {
//     return Container(
//       height: 52,
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//             decoration: BoxDecoration(
//               color: const Color(0xFF1A1A1A),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             child: Text(
//               _formatTime(_currentTime),
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 fontFeatures: [FontFeature.tabularFigures()],
//               ),
//             ),
//           ),
//           Expanded(
//             child: SliderTheme(
//               data: SliderThemeData(
//                 activeTrackColor: Theme.of(context).primaryColor,
//                 inactiveTrackColor: const Color(0xFF2A2A2A),
//                 thumbColor: Theme.of(context).primaryColor,
//                 thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
//                 overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
//                 trackHeight: 2,
//               ),
//               child: Slider(
//                 value: _currentTime.clamp(0.0, _totalDuration),
//                 max: _totalDuration > 0 ? _totalDuration : 1.0,
//                 onChanged: (value) {
//                   setState(() => _currentTime = value);
//                   _updatePreviewController();
//                 },
//               ),
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//             decoration: BoxDecoration(
//               color: const Color(0xFF1A1A1A),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             child: Text(
//               _formatTime(_totalDuration),
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 fontFeatures: [FontFeature.tabularFigures()],
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Container(
//             width: 36,
//             height: 36,
//             decoration: const BoxDecoration(
//               color: Color(0xFF1A1A1A),
//               shape: BoxShape.circle,
//             ),
//             child: IconButton(
//               icon: Icon(
//                 _isPlaying ? Icons.pause : Icons.play_arrow,
//                 color: Colors.white,
//                 size: 20,
//               ),
//               onPressed: _togglePlayback,
//               padding: EdgeInsets.zero,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTimeline() {
//     if (_videoClips.isEmpty) {
//       return Center(
//         child: Text(
//           'Tap + to add clips',
//           style: TextStyle(color: Colors.grey[700], fontSize: 12),
//         ),
//       );
//     }
//
//     return ReorderableListView.builder(
//       scrollDirection: Axis.horizontal,
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//       itemCount: _videoClips.length,
//       itemBuilder: (context, index) {
//         final clip = _videoClips[index];
//         final isSelected = _selectedClipIndex == index;
//         final width = (math.max(80, clip.duration * pixelsPerSecond)
//             .clamp(60.0, 300.0))
//             .toDouble();
//
//         return GestureDetector(
//           key: ValueKey(clip.filePath),
//           onTap: () => setState(() => _selectedClipIndex = index),
//           child: Container(
//             width: width,
//             height: 56,
//             margin: const EdgeInsets.only(right: 6),
//             decoration: BoxDecoration(
//               color: isSelected ? Theme.of(context).primaryColor : const Color(0xFF2A2A2A),
//               borderRadius: BorderRadius.circular(4),
//               border: Border.all(
//                 color: isSelected ? Theme.of(context).primaryColor : const Color(0xFF3A3A3A),
//                 width: isSelected ? 2 : 0.5,
//               ),
//             ),
//             child: clip.thumbnailPath != null
//                 ? ClipRRect(
//               borderRadius: BorderRadius.circular(4),
//               child: Image.file(File(clip.thumbnailPath!), fit: BoxFit.cover),
//             )
//                 : Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.videocam,
//                     color: isSelected ? Colors.black : Colors.white70,
//                     size: 20,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     '${clip.duration.toStringAsFixed(1)}s',
//                     style: TextStyle(
//                       color: isSelected ? Colors.black : Colors.white70,
//                       fontSize: 10,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//       onReorder: (oldIndex, newIndex) {
//         setState(() {
//           if (newIndex > oldIndex) {
//             newIndex -= 1;
//           }
//           final item = _videoClips.removeAt(oldIndex);
//           _videoClips.insert(newIndex, item);
//           _calculateTotalDuration();
//         });
//       },
//     );
//   }
//
//   // ==================== BOTTOM TOOLBAR ====================
//   Widget _buildBottomToolbar() {
//     return Container(
//       height: 200,
//       decoration: BoxDecoration(
//         color: const Color(0xFF0A0A0A),
//         border: Border(top: BorderSide(color: Colors.grey[900]!, width: 0.5)),
//       ),
//       child: Column(
//         children: [
//           _buildToolTabs(),
//           Expanded(child: _buildToolPanel()),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildToolTabs() {
//     final tools = [
//       {'icon': Icons.content_cut, 'label': 'Edit'},
//       {'icon': Icons.music_note, 'label': 'Audio'},
//       {'icon': Icons.closed_caption_outlined, 'label': 'Caption'},
//       {'icon': Icons.text_fields, 'label': 'Text'},
//       {'icon': Icons.emoji_emotions_outlined, 'label': 'Sticker'},
//       {'icon': Icons.auto_awesome_outlined, 'label': 'Effect'},
//     ];
//
//     return Container(
//       height: 56,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: tools.asMap().entries.map((entry) {
//           final index = entry.key;
//           final tool = entry.value;
//           final isSelected = _selectedToolTab == index;
//
//           return Expanded(
//             child: GestureDetector(
//               onTap: () => setState(() => _selectedToolTab = index),
//               child: Container(
//                 color: Colors.transparent,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       tool['icon'] as IconData,
//                       color: isSelected ? Theme.of(context).primaryColor : const Color(0xFF606060),
//                       size: 24,
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       tool['label'] as String,
//                       style: TextStyle(
//                         color: isSelected ? Theme.of(context).primaryColor : const Color(0xFF606060),
//                         fontSize: 10,
//                         fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
//
//   Widget _buildToolPanel() {
//     switch (_selectedToolTab) {
//       case 0:
//         return _buildEditTools();
//       case 1:
//         return _buildAudioTools();
//       case 2:
//         return _buildCaptionTools();
//       case 3:
//         return _buildTextTools();
//       case 4:
//         return _buildStickerTools();
//       case 5:
//         return _buildEffectTools();
//       default:
//         return Container();
//     }
//   }
//
//   // ==================== EDIT TOOLS ====================
//   Widget _buildEditTools() {
//     final tools = [
//       {'icon': Icons.content_cut, 'label': 'Split', 'onTap': _splitClip},
//       {'icon': Icons.crop_free, 'label': 'Trim', 'onTap': _trimClip},
//       {'icon': Icons.delete_outline, 'label': 'Delete', 'onTap': _deleteClip},
//       {'icon': Icons.speed, 'label': 'Speed', 'onTap': _changeSpeed},
//       {'icon': Icons.volume_up, 'label': 'Volume', 'onTap': _changeVolume},
//       {'icon': Icons.flip, 'label': 'Flip', 'onTap': _flipClip},
//       {'icon': Icons.copy, 'label': 'Copy', 'onTap': _duplicateClip},
//       {'icon': Icons.crop, 'label': 'Crop', 'onTap': _cropClip},
//       {'icon': Icons.rotate_90_degrees_ccw, 'label': 'Rotate', 'onTap': _rotateClip},
//       {'icon': Icons.swap_horiz, 'label': 'Transition', 'onTap': _setTransition},
//     ];
//
//     return GridView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 5,
//         mainAxisSpacing: 8,
//         crossAxisSpacing: 6,
//         childAspectRatio: 1.0,
//       ),
//       itemCount: tools.length,
//       itemBuilder: (context, index) {
//         final tool = tools[index];
//         return _buildToolItem(tool['icon'] as IconData, tool['label'] as String, tool['onTap'] as VoidCallback);
//       },
//     );
//   }
//
//   Widget _buildToolItem(IconData icon, String label, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: const Color(0xFF1A1A1A),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Icon(icon, color: Colors.white, size: 20),
//           ),
//           const SizedBox(height: 3),
//           Text(
//             label,
//             style: const TextStyle(color: Colors.white, fontSize: 9),
//             textAlign: TextAlign.center,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==================== AUDIO TOOLS ====================
//   Widget _buildAudioTools() {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Expanded(
//                 child: _buildAudioButton('Music', const Color(0xFFEF4444), Icons.music_note, _addMusic),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: _buildAudioButton('Effects', const Color(0xFF3B82F6), Icons.graphic_eq, () => _showSnackBar('Audio effects coming soon')),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: _buildAudioButton('Record', const Color(0xFF8B5CF6), Icons.mic, _addVoiceover),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: _buildAudioButton('Extract', const Color(0xFF10B981), Icons.audio_file, () => _showSnackBar('Extract audio coming soon')),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: _buildAudioButton('Volume', const Color(0xFFEAB308), Icons.volume_up, _changeVolume),
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: _audioTracks.isEmpty
//               ? Center(
//             child: Text(
//               'No audio added',
//               style: TextStyle(color: Colors.grey[600], fontSize: 13),
//             ),
//           )
//               : ListView.builder(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             itemCount: _audioTracks.length,
//             itemBuilder: (context, index) {
//               return Container(
//                 margin: const EdgeInsets.only(bottom: 8),
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF1A1A1A),
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.music_note, color: Colors.white, size: 18),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             _audioTracks[index].name,
//                             style: const TextStyle(color: Colors.white, fontSize: 12),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             '${_audioTracks[index].duration.toStringAsFixed(1)}s',
//                             style: TextStyle(color: Colors.grey[600], fontSize: 10),
//                           ),
//                         ],
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
//                       onPressed: () {
//                         setState(() {
//                           _audioTracks[index].disposePlayer();
//                           _audioTracks.removeAt(index);
//                         });
//                       },
//                       padding: EdgeInsets.zero,
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildAudioButton(String label, Color color, IconData icon, VoidCallback onTap) {
//     return Material(
//       color: color.withOpacity(0.15),
//       borderRadius: BorderRadius.circular(6),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(6),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(icon, color: color, size: 22),
//               const SizedBox(height: 4),
//               Text(
//                 label,
//                 style: TextStyle(
//                   color: color,
//                   fontSize: 11,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ==================== CAPTION TOOLS ====================
//   Widget _buildCaptionTools() {
//     return Padding(
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _buildCaptionButton('Add text', Icons.add, _addTextOverlay),
//           const SizedBox(height: 8),
//           _buildCaptionButton('Auto caption', Icons.subtitles_outlined, () {
//             _showSnackBar('Auto caption coming soon');
//           }),
//           const SizedBox(height: 8),
//           _buildCaptionButton('Text to speech', Icons.record_voice_over_outlined, () {
//             _showSnackBar('Text to speech coming soon');
//           }),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCaptionButton(String label, IconData icon, VoidCallback onTap) {
//     return Material(
//       color: const Color(0xFF1A1A1A),
//       borderRadius: BorderRadius.circular(6),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(6),
//         child: Container(
//           height: 44,
//           padding: const EdgeInsets.symmetric(horizontal: 14),
//           child: Row(
//             children: [
//               Icon(icon, color: Colors.white, size: 20),
//               const SizedBox(width: 10),
//               Text(
//                 label,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ==================== TEXT TOOLS ====================
//   Widget _buildTextTools() {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Material(
//             color: Theme.of(context).primaryColor,
//             borderRadius: BorderRadius.circular(6),
//             child: InkWell(
//               onTap: _addTextOverlay,
//               borderRadius: BorderRadius.circular(6),
//               child: Container(
//                 height: 48,
//                 child: const Center(
//                   child: Text(
//                     'Add text',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//         Expanded(
//           child: GridView.count(
//             crossAxisCount: 3,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             mainAxisSpacing: 8,
//             crossAxisSpacing: 8,
//             childAspectRatio: 1.0,
//             children: [
//               _buildTextStyleCard('Default'),
//               _buildTextStyleCard('Bold'),
//               _buildTextStyleCard('Neon'),
//               _buildTextStyleCard('Writer'),
//               _buildTextStyleCard('Glitch'),
//               _buildTextStyleCard('3D'),
//               _buildTextStyleCard('Subtitle'),
//               _buildTextStyleCard('Title'),
//               _buildTextStyleCard('Animation'),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTextStyleCard(String style) {
//     return GestureDetector(
//       onTap: () => _applyTextStyle(style),
//       child: Container(
//         decoration: BoxDecoration(
//           color: const Color(0xFF1A1A1A),
//           borderRadius: BorderRadius.circular(6),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'Aa',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               style,
//               style: const TextStyle(color: Color(0xFF808080), fontSize: 10),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ==================== STICKER TOOLS ====================
//   Widget _buildStickerTools() {
//     return Column(
//       children: [
//         // Search bar
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Container(
//             height: 40,
//             decoration: BoxDecoration(
//               color: const Color(0xFF1A1A1A),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Row(
//               children: [
//                 const SizedBox(width: 16),
//                 Icon(Icons.search, color: Colors.grey[600], size: 20),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: TextField(
//                     style: const TextStyle(color: Colors.white, fontSize: 14),
//                     decoration: InputDecoration(
//                       hintText: 'Search stickers',
//                       hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
//                       border: InputBorder.none,
//                       isDense: true,
//                       contentPadding: EdgeInsets.zero,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         // Category tabs
//         SizedBox(
//           height: 32,
//           child: ListView(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             children: ['Recents', 'Favorite', 'GIF', 'Trending', 'Birthday', 'Love', 'Funny'].map((category) {
//               return Container(
//                 margin: const EdgeInsets.only(right: 8),
//                 child: Chip(
//                   label: Text(
//                     category,
//                     style: const TextStyle(color: Color(0xFF808080), fontSize: 11),
//                   ),
//                   backgroundColor: const Color(0xFF1A1A1A),
//                   side: BorderSide.none,
//                   padding: const EdgeInsets.symmetric(horizontal: 8),
//                   labelPadding: EdgeInsets.zero,
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//         const SizedBox(height: 8),
//         // Sticker grid
//         Expanded(
//           child: GridView.count(
//             crossAxisCount: 3,
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             mainAxisSpacing: 8,
//             crossAxisSpacing: 8,
//             children: List.generate(12, (index) {
//               // Assume assets/stickers/sticker_0.png etc exist
//               return GestureDetector(
//                 onTap: () => _addSticker('assets/stickers/sticker_$index.png'),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF1A1A1A),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: 56,
//                         height: 56,
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF2A2A2A),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: Image.asset('assets/stickers/sticker_$index.png', fit: BoxFit.contain),
//                       ),
//                       const SizedBox(height: 6),
//                       const Text(
//                         'Sticker',
//                         style: TextStyle(color: Color(0xFF606060), fontSize: 9),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ==================== EFFECT TOOLS ====================
//   Widget _buildEffectTools() {
//     final effects = ['None', 'B&W', 'Sepia', 'Vintage', 'Glitch', 'Blur', 'Beautify', 'Background'];
//     return GridView.count(
//       crossAxisCount: 3,
//       padding: const EdgeInsets.all(16),
//       mainAxisSpacing: 10,
//       crossAxisSpacing: 10,
//       childAspectRatio: 1.2,
//       children: effects.map((effect) {
//         final isApplied = _selectedClipIndex != null && _videoClips[_selectedClipIndex!].filterName == effect;
//         return GestureDetector(
//           onTap: () => _applyEffect(effect),
//           child: Container(
//             decoration: BoxDecoration(
//               color: const Color(0xFF1A1A1A),
//               borderRadius: BorderRadius.circular(6),
//               border: isApplied ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null,
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF2A2A2A),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Icon(
//                     Icons.filter,
//                     color: isApplied ? Theme.of(context).primaryColor : Colors.grey[600],
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   effect,
//                   style: TextStyle(
//                     color: isApplied ? Theme.of(context).primaryColor : const Color(0xFF808080),
//                     fontSize: 11,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   // ==================== ACTION METHODS ====================
//
//   void _togglePlayback() async {
//     setState(() => _isPlaying = !_isPlaying);
//     if (_isPlaying) {
//       await _updatePreviewController();
//       _previewController?.play();
//       for (var audio in _audioTracks) {
//         if (_currentTime >= audio.startTime && _currentTime < audio.startTime + audio.duration) {
//           await audio.initPlayer();
//           audio.player!.seek(Duration(milliseconds: ((_currentTime - audio.startTime) * 1000).toInt()));
//           audio.player!.resume();
//           audio.player!.setVolume(audio.volume);
//         }
//       }
//     } else {
//       _pausePlayback();
//     }
//   }
//
//   Future<String?> _processVideoWithFFmpeg(String inputPath, String commandPart) async {
//     Directory tempDir = await getTemporaryDirectory();
//     String outputPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
//     String command = '-i "$inputPath" $commandPart "$outputPath"';
//     final session = await FFmpegKit.execute(command);
//     final returnCode = await session.getReturnCode();
//     if (ReturnCode.isSuccess(returnCode)) {
//       return outputPath;
//     } else {
//       _showSnackBar('Processing failed');
//       return null;
//     }
//   }
//
//   Future<String?> _generateThumbnail(String inputPath) async {
//     Directory tempDir = await getTemporaryDirectory();
//     String outputPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
//     String command = '-i "$inputPath" -ss 0 -vframes 1 "$outputPath"';
//     final session = await FFmpegKit.execute(command);
//     final returnCode = await session.getReturnCode();
//     if (ReturnCode.isSuccess(returnCode)) {
//       return outputPath;
//     } else {
//       return null;
//     }
//   }
//
//   Future<void> _addVideoClips() async {
//     if (!await Permission.photos.request().isGranted && !await Permission.storage.request().isGranted) {
//       _showSnackBar('Permission denied');
//       return;
//     }
//
//     final result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: true);
//     if (result == null || result.files.isEmpty) return;
//
//     for (var file in result.files) {
//       String? path = file.path;
//       if (path == null) continue;
//
//       final controller = VideoPlayerController.file(File(path));
//       await controller.initialize();
//       double dur = controller.value.duration.inMilliseconds / 1000.0;
//       await controller.dispose();
//
//       String? thumb = await _generateThumbnail(path);
//
//       setState(() {
//         _videoClips.add(
//           VideoClip(
//             name: file.name ?? 'Video ${_videoClips.length + 1}',
//             filePath: path,
//             thumbnailPath: thumb,
//             duration: dur,
//             startTime: _totalDuration,
//             originalDuration: dur,
//           ),
//         );
//         _calculateTotalDuration();
//       });
//     }
//     _showSnackBar('${result.files.length} video clips added');
//   }
//
//   Future<void> _trimClip() async {
//     if (_selectedClipIndex == null) {
//       _showSnackBar('Select a clip first');
//       return;
//     }
//     final clip = _videoClips[_selectedClipIndex!];
//     double newStart = clip.sourceStart;
//     double newEnd = clip.sourceStart + clip.duration;
//     final originalDur = clip.originalDuration;
//
//     VideoPlayerController trimController = VideoPlayerController.file(File(clip.filePath));
//     await trimController.initialize();
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1A1A1A),
//       isScrollControlled: true,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setBottomState) {
//           return Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 'Trim Clip',
//                 style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 16),
//               AspectRatio(
//                 aspectRatio: trimController.value.aspectRatio,
//                 child: VideoPlayer(trimController),
//               ),
//               RangeSlider(
//                 values: RangeValues(newStart, newEnd),
//                 min: 0.0,
//                 max: originalDur,
//                 onChanged: (values) {
//                   setBottomState(() {
//                     newStart = values.start;
//                     newEnd = values.end;
//                   });
//                   trimController.seekTo(Duration(seconds: newStart.toInt()));
//                 },
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   TextButton(
//                     onPressed: () {
//                       trimController.dispose();
//                       Navigator.pop(context);
//                     },
//                     child: const Text('Cancel'),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       trimController.dispose();
//                       Navigator.pop(context);
//                       final trimDur = newEnd - newStart;
//                       final newPath = await _processVideoWithFFmpeg(
//                         clip.filePath,
//                         '-ss $newStart -t $trimDur -c copy',
//                       );
//                       if (newPath != null) {
//                         final newThumb = await _generateThumbnail(newPath);
//                         await clip.disposeController();
//                         setState(() {
//                           clip.filePath = newPath;
//                           clip.thumbnailPath = newThumb;
//                           clip.duration = trimDur;
//                           clip.sourceStart = 0.0;
//                           clip.originalDuration = trimDur;
//                           _calculateTotalDuration();
//                         });
//                         _showSnackBar('Clip trimmed');
//                       }
//                     },
//                     child: const Text('Apply'),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Future<void> _splitClip() async {
//     if (_selectedClipIndex == null) {
//       _showSnackBar('Select a clip first');
//       return;
//     }
//     final clip = _videoClips[_selectedClipIndex!];
//     final splitPoint = _currentTime - clip.startTime;
//     if (splitPoint <= 0 || splitPoint >= clip.duration) {
//       _showSnackBar('Invalid split point');
//       return;
//     }
//
//     final firstDur = splitPoint;
//     final secondDur = clip.duration - splitPoint;
//
//     final firstPath = await _processVideoWithFFmpeg(clip.filePath, '-ss 0 -t $firstDur -c copy');
//     final secondPath = await _processVideoWithFFmpeg(clip.filePath, '-ss $splitPoint -t $secondDur -c copy');
//
//     if (firstPath != null && secondPath != null) {
//       final firstThumb = await _generateThumbnail(firstPath);
//       final secondThumb = await _generateThumbnail(secondPath);
//       await clip.disposeController();
//       setState(() {
//         clip.filePath = firstPath;
//         clip.thumbnailPath = firstThumb;
//         clip.duration = firstDur;
//         clip.originalDuration = firstDur;
//         final newClip = VideoClip(
//           name: '${clip.name} (2)',
//           filePath: secondPath,
//           thumbnailPath: secondThumb,
//           duration: secondDur,
//           startTime: 0, // Will be updated
//           originalDuration: secondDur,
//         );
//         _videoClips.insert(_selectedClipIndex! + 1, newClip);
//         _calculateTotalDuration();
//       });
//       _showSnackBar('Clip split');
//     }
//   }
//
//   void _deleteClip() {
//     if (_selectedClipIndex == null) {
//       _showSnackBar('Select a clip first');
//       return;
//     }
//     setState(() {
//       _videoClips[_selectedClipIndex!].disposeController();
//       _videoClips.removeAt(_selectedClipIndex!);
//       _selectedClipIndex = null;
//       _calculateTotalDuration();
//     });
//     _showSnackBar('Clip deleted');
//   }
//
//   Future<void> _duplicateClip() async {
//     if (_selectedClipIndex == null) {
//       _showSnackBar('Select a clip first');
//       return;
//     }
//     final original = _videoClips[_selectedClipIndex!];
//     final newPath = await _processVideoWithFFmpeg(original.filePath, '-c copy');
//     if (newPath != null) {
//       final newThumb = await _generateThumbnail(newPath);
//       setState(() {
//         _videoClips.insert(
//           _selectedClipIndex! + 1,
//           VideoClip(
//             name: '${original.name} (Copy)',
//             filePath: newPath,
//             thumbnailPath: newThumb,
//             duration: original.duration,
//             startTime: 0, // Updated later
//             originalDuration: original.originalDuration,
//             speed: original.speed,
//             filterName: original.filterName,
//             volume: original.volume,
//           ),
//         );
//         _calculateTotalDuration();
//       });
//       _showSnackBar('Clip duplicated');
//     }
//   }
//
//   Future<void> _changeSpeed() async {
//     if (_selectedClipIndex == null) {
//       _showSnackBar('Select a clip first');
//       return;
//     }
//     final clip = _videoClips[_selectedClipIndex!];
//     double newSpeed = clip.speed;
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1A1A1A),
//       builder: (context) => StatefulBuilder(
//         builder: (context, setBottomState) {
//           return Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 'Speed',
//                 style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
//               ),
//               Slider(
//                 value: newSpeed,
//                 min: 0.25,
//                 max: 4.0,
//                 divisions: 15,
//                 label: '${newSpeed.toStringAsFixed(2)}x',
//                 onChanged: (value) => setBottomState(() => newSpeed = value),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('Cancel'),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       Navigator.pop(context);
//                       final pts = 1 / newSpeed;
//                       final atempo = newSpeed.clamp(0.5, 2.0); // atempo limited
//                       String audioFilter = 'atempo=$atempo';
//                       if (newSpeed < 0.5 || newSpeed > 2.0) {
//                         audioFilter = 'atempo=0.5,atempo=0.5,atempo=${newSpeed * 2}'; // adjust for range
//                       }
//                       final newPath = await _processVideoWithFFmpeg(
//                         clip.filePath,
//                         '-filter:v "setpts=$pts*PTS" -filter:a "$audioFilter"',
//                       );
//                       if (newPath != null) {
//                         final newThumb = await _generateThumbnail(newPath);
//                         await clip.disposeController();
//                         setState(() {
//                           clip.filePath = newPath;
//                           clip.thumbnailPath = newThumb;
//                           clip.duration = clip.originalDuration / newSpeed;
//                           clip.speed = newSpeed;
//                           clip.originalDuration = clip.duration;
//                           _calculateTotalDuration();
//                         });
//                         _showSnackBar('Speed changed to ${newSpeed}x');
//                       }
//                     },
//                     child: const Text('Apply'),
//                   ),
//                 ],
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Future<void> _changeVolume() async {
//     if (_selectedClipIndex == null) {
//       _showSnackBar('Select a clip first');
//       return;
//     }
//     final clip = _videoClips[_selectedClipIndex!];
//     double newVolume = clip.volume;
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1A1A1A),
//       builder: (context) => StatefulBuilder(
//         builder: (context, setBottomState) {
//           return Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 'Volume',
//                 style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
//               ),
//               Slider(
//                 value: newVolume,
//                 min: 0.0,
//                 max: 2.0,
//                 label: '${(newVolume * 100).toInt()}%',
//                 onChanged: (value) => setBottomState(() => newVolume = value),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('Cancel'),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       Navigator.pop(context);
//                       final newPath = await _processVideoWithFFmpeg(
//                         clip.filePath,
//                         '-filter:a "volume=$newVolume"',
//                       );
//                       if (newPath != null) {
//                         await clip.disposeController();
//                         setState(() {
//                           clip.filePath = newPath;
//                           clip.volume = newVolume;
//                         });
//                         _showSnackBar('Volume set to ${(newVolume * 100).toInt()}%');
//                       }
//                     },
//                     child: const Text('Apply'),
//                   ),
//                 ],
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Future<void> _flipClip() async {
//     if (_selectedClipIndex == null) {
//       _showSnackBar('Select a clip first');
//       return;
//     }
//     final clip = _videoClips[_selectedClipIndex!];
//     final newPath = await _processVideoWithFFmpeg(clip.filePath, '-vf hflip -c:a copy');
//     if (newPath != null) {
//       final newThumb = await _generateThumbnail(newPath);
//       await clip.disposeController();
//       setState(() {
//         clip.filePath = newPath;
//         clip.thumbnailPath = newThumb;
//       });
//       _showSnackBar('Clip flipped');
//     }
//   }
//
//   Future<void> _rotateClip() async {
//     if (_selectedClipIndex == null) {
//       _showSnackBar('Select a clip first');
//       return;
//     }
//     final clip = _videoClips[_selectedClipIndex!];
//     final newPath = await _processVideoWithFFmpeg(clip.filePath, '-vf transpose=1 -c:a copy');
//     if (newPath != null) {
//       final newThumb = await _generateThumbnail(newPath);
//       await clip.disposeController();
//       setState(() {
//         clip.filePath = newPath;
//         clip.thumbnailPath = newThumb;
//       });
//       _showSnackBar('Clip rotated');
//     }
//   }
//
//   Future<void> _cropClip() async {
//     if (_selectedClipIndex == null) {
//       _showSnackBar('Select a clip first');
//       return;
//     }
//     final clip = _videoClips[_selectedClipIndex!];
//     // Example crop, in production add UI for crop params
//     final newPath = await _processVideoWithFFmpeg(clip.filePath, '-vf crop=iw/2:ih/2:0:0 -c:a copy');
//     if (newPath != null) {
//       final newThumb = await _generateThumbnail(newPath);
//       await clip.disposeController();
//       setState(() {
//         clip.filePath = newPath;
//         clip.thumbnailPath = newThumb;
//       });
//       _showSnackBar('Clip cropped');
//     }
//   }
//
//   void _setTransition() {
//     if (_selectedClipIndex == null || _selectedClipIndex == _videoClips.length - 1) {
//       _showSnackBar('Select a clip with next clip');
//       return;
//     }
//     // In production, show options for type
//     setState(() {
//       _videoClips[_selectedClipIndex!].transitionType = 'fade';
//     });
//     _showSnackBar('Fade transition set');
//   }
//
//   Future<void> _addMusic() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.audio);
//     if (result == null) return;
//     final path = result.files.first.path!;
//     final player = AudioPlayer();
//     await player.setSourceDeviceFile(path);
//     final dur = (await player.getDuration())!.inMilliseconds / 1000.0;
//     await player.dispose();
//     setState(() {
//       _audioTracks.add(
//         AudioTrack(
//           name: result.files.first.name,
//           filePath: path,
//           startTime: _currentTime,
//           duration: dur,
//         ),
//       );
//     });
//     _showSnackBar('Music added');
//   }
//
//   Future<void> _addVoiceover() async {
//     _showSnackBar('Voiceover recording coming soon, picking file instead');
//     await _addMusic();
//   }
//
//   void _addTextOverlay() {
//     String textInput = '';
//     double fontSize = 32.0;
//     Color color = Colors.white;
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               backgroundColor: const Color(0xFF1A1A1A),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               title: const Text(
//                 'Add Text',
//                 style: TextStyle(color: Colors.white, fontSize: 17),
//               ),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     autofocus: true,
//                     style: const TextStyle(color: Colors.white, fontSize: 15),
//                     decoration: InputDecoration(
//                       hintText: 'Enter text',
//                       hintStyle: TextStyle(color: Colors.grey[600]),
//                       enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
//                       focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2)),
//                     ),
//                     onChanged: (value) => textInput = value,
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       const Text('Size: ', style: TextStyle(color: Colors.white)),
//                       Slider(
//                         value: fontSize,
//                         min: 10,
//                         max: 60,
//                         onChanged: (val) => setDialogState(() => fontSize = val),
//                       ),
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       const Text('Color: ', style: TextStyle(color: Colors.white)),
//                       GestureDetector(
//                         onTap: () async {
//                           final newColor = await showColorPicker(context, color);
//                           if (newColor != null) setDialogState(() => color = newColor);
//                         },
//                         child: Container(
//                           width: 24,
//                           height: 24,
//                           color: color,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text('Cancel', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     if (textInput.isNotEmpty) {
//                       setState(() {
//                         final overlay = TextOverlay(
//                           text: textInput,
//                           x: 100,
//                           y: 200,
//                           startTime: _currentTime,
//                           endTime: _currentTime + 5.0,
//                         );
//                         overlay.fontSize = fontSize;
//                         overlay.color = color;
//                         _textOverlays.add(overlay);
//                       });
//                       Navigator.pop(context);
//                       _showSnackBar('Text added');
//                     }
//                   },
//                   child: const Text(
//                     'Add',
//                     style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Future<Color?> showColorPicker(BuildContext context, Color initialColor) async {
//     Color? selectedColor = initialColor;
//     await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Pick Color'),
//         content: SingleChildScrollView(
//           child: BlockPicker(
//             pickerColor: initialColor,
//             onColorChanged: (color) => selectedColor = color,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Select'),
//           ),
//         ],
//       ),
//     );
//     return selectedColor;
//   }
//
//   void _applyTextStyle(String style) {
//     if (_selectedTextIndex == null) {
//       _showSnackBar('Select a text first');
//       return;
//     }
//     setState(() {
//       final overlay = _textOverlays[_selectedTextIndex!];
//       switch (style) {
//         case 'Bold':
//           overlay.fontWeight = FontWeight.w900;
//           break;
//         case 'Neon':
//           overlay.color = const Color(0xFF00FFFF);
//           overlay.animationType = 'neon';
//           break;
//         case 'Glitch':
//           overlay.animationType = 'glitch';
//           break;
//         case '3D':
//           overlay.animationType = '3d';
//           break;
//       // Add more styles
//         default:
//           overlay.fontWeight = FontWeight.bold;
//       }
//     });
//     _showSnackBar('$style applied');
//   }
//
//   void _addSticker(String assetPath) {
//     setState(() {
//       _stickers.add(
//         StickerOverlay(
//           assetPath: assetPath,
//           x: 150,
//           y: 300,
//           startTime: _currentTime,
//           endTime: _currentTime + 5.0,
//         ),
//       );
//     });
//     _showSnackBar('Sticker added');
//   }
//
//   Future<void> _applyEffect(String effectName) async {
//     if (_selectedClipIndex == null) {
//       _showSnackBar('Select a clip first');
//       return;
//     }
//     final clip = _videoClips[_selectedClipIndex!];
//     final filter = _ffmpegFilters[effectName];
//     String commandPart = filter != null ? '-vf "$filter" -c:a copy' : '';
//     if (effectName == 'None') commandPart = '-c copy';
//     final newPath = await _processVideoWithFFmpeg(clip.filePath, commandPart);
//     if (newPath != null) {
//       final newThumb = await _generateThumbnail(newPath);
//       await clip.disposeController();
//       setState(() {
//         clip.filePath = newPath;
//         clip.thumbnailPath = newThumb;
//         clip.filterName = effectName == 'None' ? null : effectName;
//       });
//       _showSnackBar('$effectName applied');
//     }
//   }
//
//   Future<String> _copyAssetToTemp(String assetPath) async {
//     final byteData = await rootBundle.load(assetPath);
//     final tempDir = await getTemporaryDirectory();
//     final file = File('${tempDir.path}/${assetPath.split('/').last}');
//     await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
//     return file.path;
//   }
//
//   Future<void> _exportVideo() async {
//     if (_videoClips.isEmpty) return;
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(child: CircularProgressIndicator()),
//     );
//
//     Directory tempDir = await getTemporaryDirectory();
//     String outputPath = '${tempDir.path}/exported_video.mp4';
//
//     // Build FFmpeg command
//     String inputArgs = '';
//     String filterComplex = '';
//     int inputIndex = 0;
//
//     // Video inputs
//     List<String> videoInputs = [];
//     for (var clip in _videoClips) {
//       videoInputs.add('-i "${clip.filePath}"');
//       inputIndex++;
//     }
//
//     // Sticker inputs
//     List<String> stickerPaths = [];
//     for (var sticker in _stickers) {
//       final tempPath = await _copyAssetToTemp(sticker.assetPath);
//       stickerPaths.add(tempPath);
//       videoInputs.add('-i "$tempPath"');
//       inputIndex++;
//     }
//
//     // Audio inputs
//     List<String> additionalAudioInputs = [];
//     for (var audio in _audioTracks) {
//       additionalAudioInputs.add('-i "${audio.filePath}"');
//     }
//
//     inputArgs = [...videoInputs, ...additionalAudioInputs].join(' ');
//
//     // Video chain with transitions
//     String videoChain = '';
//     String prevV = '0:v';
//     videoChain += '[0:v]settb=AV_TB[v0]; ';
//     double currentOffset = 0.0;
//     for (int i = 1; i < _videoClips.length; i++) {
//       videoChain += '[$i:v]settb=AV_TB[v$i]; ';
//       final prevClip = _videoClips[i - 1];
//       if (prevClip.transitionType != null) {
//         String trans = prevClip.transitionType == 'fade' ? 'fade' : 'slideleft'; // add more types
//         double transDur = prevClip.transitionDuration;
//         double offset = currentOffset - transDur; // overlap
//         videoChain += '[v${i-1}][v$i]xfade=transition=$trans:duration=$transDur:offset=$offset[vv$i]; ';
//         prevV = 'vv$i';
//       } else {
//         videoChain += '[v${i-1}][v$i]concat[vv$i]; ';
//         prevV = 'vv$i';
//       }
//       currentOffset += _videoClips[i-1].duration;
//     }
//     String baseV = '[${prevV}]';
//
//     // Apply text overlays
//     String overlayV = baseV;
//     for (var text in _textOverlays) {
//       final fs = text.fontSize;
//       final col = '0x${text.color.value.toRadixString(16).padLeft(8, '0')}';
//       final enable = 'enable=\'between(t,${text.startTime},${text.endTime})\'';
//       videoChain += '$overlayV drawtext=text=\'${text.text}\':x=${text.x}:y=${text.y}:fontsize=$fs:fontcolor=$col:$enable [ov${_textOverlays.indexOf(text)}]; ';
//       overlayV = '[ov${_textOverlays.indexOf(text)}]';
//     }
//
//     // Apply stickers
//     int stickerInputStart = _videoClips.length;
//     for (var sticker in _stickers) {
//       int sIndex = stickerInputStart + _stickers.indexOf(sticker);
//       final enable = 'enable=\'between(t,${sticker.startTime},${sticker.endTime})\'';
//       videoChain += '$overlayV [$sIndex:v]overlay=${sticker.x}:${sticker.y}:$enable [os${_stickers.indexOf(sticker)}]; ';
//       overlayV = '[os${_stickers.indexOf(sticker)}]';
//     }
//
//     // Audio chain from videos
//     String audioChain = '';
//     String prevA = '0:a';
//     audioChain += '[0:a]asetrate=44100[a0]; ';
//     for (int i = 1; i < _videoClips.length; i++) {
//       audioChain += '[$i:a]asetrate=44100[a$i]; ';
//       final prevClip = _videoClips[i - 1];
//       if (prevClip.transitionType != null) {
//         double transDur = prevClip.transitionDuration;
//         audioChain += '[a${i-1}][a$i]acrossfade=d=$transDur [aa$i]; ';
//         prevA = 'aa$i';
//       } else {
//         audioChain += '[a${i-1}][a$i]concat=v=0:a=1 [aa$i]; ';
//         prevA = 'aa$i';
//       }
//     }
//     String mainA = '[${prevA}]';
//
//     // Add additional audios
//     int audioInputStart = _videoClips.length + _stickers.length;
//     for (var audio in _audioTracks) {
//       int aIndex = audioInputStart + _audioTracks.indexOf(audio);
//       final delay = (audio.startTime * 1000).toInt();
//       final vol = audio.volume;
//       audioChain += '[$aIndex:a]adelay=$delay|$delay,volume=$vol[add${_audioTracks.indexOf(audio)}]; ';
//       audioChain += '$mainA [add${_audioTracks.indexOf(audio)}]amix=inputs=2:duration=longest [ma${_audioTracks.indexOf(audio)}]; ';
//       mainA = '[ma${_audioTracks.indexOf(audio)}]';
//     }
//
//     filterComplex = videoChain + audioChain + '$overlayV [v]; $mainA [a]; ';
//
//     String command = '$inputArgs -filter_complex "$filterComplex" -map "[v]" -map "[a]" -c:v libx264 -c:a aac "$outputPath"';
//
//     final session = await FFmpegKit.execute(command);
//     final returnCode = await session.getReturnCode();
//     Navigator.pop(context);
//     if (ReturnCode.isSuccess(returnCode)) {
//       _showSnackBar('Exported to $outputPath');
//     } else {
//       final log = await session.getOutput();
//       print(log);
//       _showSnackBar('Export failed');
//     }
//   }
//
//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(fontSize: 13)),
//         duration: const Duration(seconds: 2),
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: const Color(0xFF2A2A2A),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }
//
//   String _formatTime(double seconds) {
//     final minutes = (seconds / 60).floor();
//     final secs = (seconds % 60).floor();
//     final millis = ((seconds % 1) * 10).floor();
//     return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.$millis';
//   }
// }