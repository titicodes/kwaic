// import 'dart:io' show File, Platform;
// import 'dart:math' as math;
// import 'dart:async'; // Added for Timer
//
// import 'package:collection/collection.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_min_gpl/ffprobe_kit.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:video_player/video_player.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
//
// void main() => runApp(const VideoEditorApp());
//
// class VideoEditorApp extends StatelessWidget {
//   const VideoEditorApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'CapCut Clone',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         brightness: Brightness.dark,
//         scaffoldBackgroundColor: Colors.black,
//         primaryColor: const Color(0xFF8B5CF6),
//         useMaterial3: true,
//       ),
//       home: const VideoEditorScreen(),
//     );
//   }
// }
//
// /* ------------------------------------------------------------------ */
// /* MODELS */
// /* ------------------------------------------------------------------ */
// class TimelineItem {
//   final String id;
//   final File file;
//   final bool isAudio;
//   Duration duration;
//   Duration trimStart;
//   Duration trimEnd;
//   double volume;
//   final List<String> thumbnailPaths = [];
//
//   TimelineItem({
//     required this.id,
//     required this.file,
//     required this.isAudio,
//     required this.duration,
//     Duration? trimStart,
//     Duration? trimEnd,
//     this.volume = 1.0,
//   })  : trimStart = trimStart ?? Duration.zero,
//         trimEnd = trimEnd ?? duration;
// }
//
// /* ------------------------------------------------------------------ */
// /* MAIN SCREEN */
// /* ------------------------------------------------------------------ */
// class VideoEditorScreen extends StatefulWidget {
//   const VideoEditorScreen({super.key});
//
//   @override
//   State<VideoEditorScreen> createState() => _VideoEditorScreenState();
// }
//
// class _VideoEditorScreenState extends State<VideoEditorScreen> {
//   List<TimelineItem> _videoClips = [];
//   List<TimelineItem> _audioClips = [];
//   int? _selectedVideoIndex;
//   int? _selectedAudioIndex;
//   Duration _playheadPosition = Duration.zero;
//   Duration _totalDuration = Duration.zero;
//   final Map<String, VideoPlayerController> _controllers = {};
//   VideoPlayerController? _activeController;
//   bool _playing = false;
//   final ImagePicker _picker = ImagePicker();
//   String _mode = 'Edit';
//   Timer? _playbackTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _startPlaybackLoop();
//   }
//
//   @override
//   void dispose() {
//     _playbackTimer?.cancel();
//     for (final c in _controllers.values) {
//       c.dispose();
//     }
//     super.dispose();
//   }
//
//   /* -------------------------------------------------------------- */
//   /* PERMISSIONS */
//   /* -------------------------------------------------------------- */
//   Future<bool> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       final androidInfo = await DeviceInfoPlugin().androidInfo;
//       if (androidInfo.version.sdkInt >= 33) {
//         final statuses = await [Permission.videos, Permission.audio].request();
//         return statuses.values.every((s) => s.isGranted);
//       } else {
//         return await Permission.storage.request().isGranted;
//       }
//     } else if (Platform.isIOS) {
//       final statuses = await [Permission.videos, Permission.photos].request();
//       return statuses.values.every((s) => s.isGranted);
//     }
//     return true;
//   }
//
//   /* -------------------------------------------------------------- */
//   /* PLAYBACK */
//   /* -------------------------------------------------------------- */
//   void _startPlaybackLoop() {
//     _playbackTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
//       if (!mounted) return;
//
//       if (_playing) {
//         setState(() {
//           _playheadPosition += const Duration(milliseconds: 16);
//           if (_playheadPosition >= _totalDuration) {
//             _playing = false;
//             _playheadPosition = Duration.zero;
//           }
//         });
//         _updatePreview();
//       }
//     });
//   }
//
//   void _updatePreview() {
//     if (_videoClips.isEmpty) return;
//
//     Duration accumulatedTime = Duration.zero;
//     TimelineItem? activeClip;
//
//     for (final clip in _videoClips) {
//       final clipEnd = accumulatedTime + clip.duration;
//       if (_playheadPosition >= accumulatedTime && _playheadPosition < clipEnd) {
//         activeClip = clip;
//         break;
//       }
//       accumulatedTime = clipEnd;
//     }
//
//     if (activeClip != null) {
//       final ctrl = _controllers[activeClip.id];
//       if (ctrl != null && ctrl.value.isInitialized) {
//         Duration accTime = Duration.zero;
//         for (final clip in _videoClips) {
//           if (clip == activeClip) break;
//           accTime += clip.duration;
//         }
//
//         final localTime = _playheadPosition - accTime;
//         final sourceTime = activeClip.trimStart + localTime;
//
//         if ((ctrl.value.position - sourceTime).abs() > const Duration(milliseconds: 100)) {
//           ctrl.seekTo(sourceTime);
//         }
//
//         if (_playing && !ctrl.value.isPlaying) {
//           ctrl.play();
//         } else if (!_playing && ctrl.value.isPlaying) {
//           ctrl.pause();
//         }
//
//         if (_activeController != ctrl) {
//           setState(() => _activeController = ctrl);
//         }
//       }
//     }
//
//     // Handle audio
//     for (final audio in _audioClips) {
//       final ctrl = _controllers[audio.id];
//       if (ctrl != null && ctrl.value.isInitialized) {
//         if (_playheadPosition >= Duration.zero && _playheadPosition < audio.duration) {
//           final sourceTime = audio.trimStart + _playheadPosition;
//           if ((ctrl.value.position - sourceTime).abs() > const Duration(milliseconds: 100)) {
//             ctrl.seekTo(sourceTime);
//           }
//           if (_playing && !ctrl.value.isPlaying) {
//             ctrl.play();
//           } else if (!_playing && ctrl.value.isPlaying) {
//             ctrl.pause();
//           }
//         } else if (_playheadPosition >= audio.duration && ctrl.value.isPlaying) {
//           ctrl.pause();
//         }
//       }
//     }
//   }
//
//   /* -------------------------------------------------------------- */
//   /* ADD VIDEO */
//   /* -------------------------------------------------------------- */
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
//       _showLoading();
//
//       final info = await FFprobeKit.getMediaInformation(file.path);
//       final media = info.getMediaInformation();
//       if (media == null) throw Exception('Invalid video');
//
//       final durSec = double.tryParse(media.getDuration() ?? '0') ?? 0.0;
//       final duration = Duration(milliseconds: (durSec * 1000).round());
//
//       // Generate thumbnails
//       final dir = await getTemporaryDirectory();
//       final List<String> thumbs = [];
//       for (int i = 0; i < 10; i++) {
//         final ms = (duration.inMilliseconds * i / 9).round();
//         final path = await VideoThumbnail.thumbnailFile(
//           video: file.path,
//           thumbnailPath: dir.path,
//           imageFormat: ImageFormat.PNG,
//           maxWidth: 60,
//           timeMs: ms,
//         );
//         if (path != null) thumbs.add(path);
//       }
//
//       final clip = TimelineItem(
//         id: 'video_${DateTime.now().millisecondsSinceEpoch}',
//         file: File(file.path),
//         isAudio: false,
//         duration: duration,
//         trimStart: Duration.zero,
//         trimEnd: duration,
//       );
//       clip.thumbnailPaths.addAll(thumbs);
//
//       final ctrl = VideoPlayerController.file(File(file.path));
//       await ctrl.initialize();
//
//       setState(() {
//         _videoClips.add(clip);
//         _selectedVideoIndex = _videoClips.length - 1;
//         _selectedAudioIndex = null;
//         _controllers[clip.id] = ctrl;
//         _updateTotalDuration();
//       });
//
//       _hideLoading();
//       _showMessage('Video added');
//     } catch (e) {
//       _hideLoading();
//       _showError('Failed: $e');
//     }
//   }
//
//   /* -------------------------------------------------------------- */
//   /* ADD AUDIO */
//   /* -------------------------------------------------------------- */
//   Future<void> _addAudio() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(type: FileType.audio);
//       if (result == null || result.files.isEmpty) return;
//
//       final filePath = result.files.first.path;
//       if (filePath == null) return;
//
//       _showLoading();
//
//       final info = await FFprobeKit.getMediaInformation(filePath);
//       final media = info.getMediaInformation();
//       final durSec = double.tryParse(media?.getDuration() ?? '0') ?? 0.0;
//       if (durSec <= 0) throw Exception('Invalid audio');
//
//       final duration = Duration(milliseconds: (durSec * 1000).round());
//
//       final clip = TimelineItem(
//         id: 'audio_${DateTime.now().millisecondsSinceEpoch}',
//         file: File(filePath),
//         isAudio: true,
//         duration: duration,
//         trimStart: Duration.zero,
//         trimEnd: duration,
//       );
//
//       final ctrl = VideoPlayerController.file(File(filePath));
//       await ctrl.initialize();
//
//       setState(() {
//         _audioClips.add(clip);
//         _selectedAudioIndex = _audioClips.length - 1;
//         _selectedVideoIndex = null;
//         _controllers[clip.id] = ctrl;
//       });
//
//       _hideLoading();
//       _showMessage('Audio added');
//     } catch (e) {
//       _hideLoading();
//       _showError('Failed: $e');
//     }
//   }
//
//   /* -------------------------------------------------------------- */
//   /* SPLIT */
//   /* -------------------------------------------------------------- */
//   Future<void> _split() async {
//     if (_selectedVideoIndex == null) {
//       _showError('Select a video clip');
//       return;
//     }
//
//     Duration accTime = Duration.zero;
//     final clip = _videoClips[_selectedVideoIndex!];
//
//     for (int i = 0; i < _selectedVideoIndex!; i++) {
//       accTime += _videoClips[i].duration;
//     }
//
//     if (_playheadPosition < accTime || _playheadPosition >= accTime + clip.duration) {
//       _showError('Move playhead inside clip');
//       return;
//     }
//
//     final splitPoint = _playheadPosition - accTime;
//
//     final first = TimelineItem(
//       id: clip.id,
//       file: clip.file,
//       isAudio: false,
//       duration: splitPoint,
//       trimStart: clip.trimStart,
//       trimEnd: clip.trimStart + splitPoint,
//     );
//     first.thumbnailPaths.addAll(clip.thumbnailPaths);
//
//     final second = TimelineItem(
//       id: 'video_${DateTime.now().millisecondsSinceEpoch}',
//       file: clip.file,
//       isAudio: false,
//       duration: clip.duration - splitPoint,
//       trimStart: clip.trimStart + splitPoint,
//       trimEnd: clip.trimEnd,
//     );
//     second.thumbnailPaths.addAll(clip.thumbnailPaths);
//
//     final newCtrl = VideoPlayerController.file(clip.file);
//     await newCtrl.initialize();
//     _controllers[second.id] = newCtrl;
//
//     setState(() {
//       _videoClips[_selectedVideoIndex!] = first;
//       _videoClips.insert(_selectedVideoIndex! + 1, second);
//       _updateTotalDuration();
//     });
//
//     _showMessage('Split');
//   }
//
//   /* -------------------------------------------------------------- */
//   /* DELETE */
//   /* -------------------------------------------------------------- */
//   void _delete() {
//     if (_selectedVideoIndex != null) {
//       final clip = _videoClips[_selectedVideoIndex!];
//       _controllers[clip.id]?.dispose();
//       _controllers.remove(clip.id);
//
//       setState(() {
//         _videoClips.removeAt(_selectedVideoIndex!);
//         _selectedVideoIndex = null;
//         _updateTotalDuration();
//       });
//       _showMessage('Deleted');
//     } else if (_selectedAudioIndex != null) {
//       final clip = _audioClips[_selectedAudioIndex!];
//       _controllers[clip.id]?.dispose();
//       _controllers.remove(clip.id);
//
//       setState(() {
//         _audioClips.removeAt(_selectedAudioIndex!);
//         _selectedAudioIndex = null;
//       });
//       _showMessage('Deleted');
//     }
//   }
//
//   /* -------------------------------------------------------------- */
//   /* HELPERS */
//   /* -------------------------------------------------------------- */
//   void _updateTotalDuration() {
//     _totalDuration = _videoClips.fold(
//       Duration.zero,
//           (sum, clip) => sum + clip.duration,
//     );
//   }
//
//   void _togglePlay() {
//     setState(() {
//       _playing = !_playing;
//       if (_playing && _playheadPosition >= _totalDuration) {
//         _playheadPosition = Duration.zero;
//       }
//     });
//     _updatePreview();
//   }
//
//   void _showLoading() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Center(
//         child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
//       ),
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
//   String _formatDuration(Duration d) {
//     final min = d.inMinutes.toString().padLeft(2, '0');
//     final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
//     return '$min:$sec';
//   }
//
//   /* -------------------------------------------------------------- */
//   /* BUILD UI */
//   /* -------------------------------------------------------------- */
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildTopBar(),
//             Expanded(child: _buildPreview()),
//             _buildTimeline(),
//             if (_selectedVideoIndex != null || _selectedAudioIndex != null)
//               _buildContextTools(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTopBar() => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//     color: Colors.black,
//     child: Row(
//       children: [
//         IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
//           onPressed: () {},
//         ),
//         const Spacer(),
//         IconButton(
//           icon: const Icon(Icons.help_outline, color: Colors.white, size: 24),
//           onPressed: () {},
//         ),
//         IconButton(
//           icon: const Icon(Icons.more_horiz, color: Colors.white, size: 24),
//           onPressed: () {},
//         ),
//         const SizedBox(width: 8),
//         ElevatedButton(
//           onPressed: () {},
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF8B5CF6),
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//           ),
//           child: const Text('Export', style: TextStyle(fontWeight: FontWeight.w600)),
//         ),
//       ],
//     ),
//   );
//
//   Widget _buildPreview() => Container(
//     color: Colors.black,
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//     child: Center(
//       child: AspectRatio(
//         aspectRatio: 9 / 16,
//         child: Container(
//           decoration: BoxDecoration(
//             color: const Color(0xFF1A1A1A),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: _activeController != null && _activeController!.value.isInitialized
//                 ? FittedBox(
//               fit: BoxFit.contain,
//               child: SizedBox(
//                 width: _activeController!.value.size.width,
//                 height: _activeController!.value.size.height,
//                 child: VideoPlayer(_activeController!),
//               ),
//             )
//                 : const Center(
//               child: Icon(Icons.video_library, size: 80, color: Colors.white24),
//             ),
//           ),
//         ),
//       ),
//     ),
//   );
//
//   /* -------------------------------------------------------------- */
//   /* TIMELINE – MATCHES THE SCREENSHOT EXACTLY                     */
//   /* -------------------------------------------------------------- */
//   /* -------------------------------------------------------------- */
// /* ✨ TIMELINE – EXACT MATCH TO YOUR SCREENSHOT                   */
// /* -------------------------------------------------------------- */
//
//   Widget _buildTimeline() {
//     const double videoTrackHeight = 100;
//     const double playheadWidth = 12;
//
//     return Container(
//       // Reduced height to match screenshot layout which includes the tool bar
//       height: 180,
//       color: Colors.black,
//       child: Column(
//         children: [
//           /* ───────── RULER + PURPLE PLAYHEAD ───────── */
//           SizedBox(
//             height: 30,
//             child: LayoutBuilder(
//               builder: (context, constraints) {
//                 final width = constraints.maxWidth - 32; // Account for horizontal padding
//                 final rulerInterval = Duration(seconds: 2); // Example interval
//                 final totalSeconds = _totalDuration.inSeconds;
//                 final numIntervals = (totalSeconds / rulerInterval.inSeconds).ceil() + 1;
//
//                 return Stack(
//                   children: [
//                     // Timeline Ticks and Timestamps (Simplified)
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: List.generate(
//                           // Create ticks for 0, 2, 4, 6... seconds up to total duration
//                           numIntervals,
//                               (i) {
//                             final time = Duration(seconds: i * rulerInterval.inSeconds);
//                             if (time.inSeconds > totalSeconds && i != 0) return Container();
//
//                             return Column(
//                               children: [
//                                 Text(
//                                   // Format as 00:00, 00:02, etc.
//                                   _formatDuration(time),
//                                   style: const TextStyle(color: Color(0xFFB3A4FF), fontSize: 10),
//                                 ),
//                                 const SizedBox(height: 2),
//                                 // Dot for the tick
//                                 Container(
//                                   width: 2,
//                                   height: 5,
//                                   color: const Color(0xFFB3A4FF),
//                                 ),
//                               ],
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//
//                     // Purple Playhead Line (Adjusted for better centering with the ruler)
//                     Positioned(
//                       left: (_totalDuration.inMilliseconds == 0)
//                           ? 16 // Start at the first clip padding
//                           : 16 + (_playheadPosition.inMilliseconds / _totalDuration.inMilliseconds) * (width),
//                       top: 0,
//                       child: GestureDetector(
//                         onHorizontalDragUpdate: (details) => _scrubPlayhead(details.delta.dx),
//                         child: Column(
//                           children: [
//                             CustomPaint(
//                               size: const Size(playheadWidth, 18),
//                               painter: _PlayheadPainter(),      // Hexagon painter
//                             ),
//                             // The line extends down through the tracks
//                             Container(
//                                 width: 2,
//                                 height: videoTrackHeight, // Extends through both tracks
//                                 color: const Color(0xFF9F7AEA)
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//
//           /* ───────── VIDEO AND AUDIO CLIPS TRACKS ───────── */
//           SizedBox(
//             height: videoTrackHeight, // Height for both video and audio tracks
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.only(left: 16, right: 16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // 1. VIDEO TRACK
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // SOUND ON (left icon) - Adjusted style to match screenshot
//                       _timelineButton(
//                         icon: Icons.volume_up,
//                         label: 'Sound ON',
//                         onTap: () {},
//                         width: 70, // Slightly smaller
//                         height: 50,
//                       ),
//
//                       const SizedBox(width: 8),
//
//                       // COVER (first clip) - Adjusted style to match screenshot
//                       if (_videoClips.isNotEmpty) _coverThumbnail(_videoClips[0]),
//
//                       const SizedBox(width: 8),
//
//                       // Video clip thumbnails
//                       Row(
//                         children: _videoClips.asMap().entries.map((entry) {
//                           final index = entry.key;
//                           final clip = entry.value;
//
//                           // ... inside _buildTimeline > Row > children: _videoClips ...
//                           return Row(
//                             children: [
//                               GestureDetector(
//                                 // ... onTap logic ...
//                                 child: Container(
//                                   width: 100,
//                                   height: 50,
//                                   margin: const EdgeInsets.only(right: 2),
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(8),
//                                     border: (_selectedVideoIndex == index)
//                                         ? Border.all(color: const Color(0xFF9F7AEA), width: 2)
//                                         : null,
//                                     // **FIX IS HERE: Only set 'image' if a thumbnail exists**
//                                     image: clip.thumbnailPaths.isNotEmpty
//                                         ? DecorationImage(
//                                       image: FileImage(File(clip.thumbnailPaths.first)),
//                                       fit: BoxFit.cover,
//                                     )
//                                         : null, // If null, the Container uses its default background
//                                   ),
//                                   child: clip.thumbnailPaths.isEmpty
//                                       ? const Center(child: Icon(Icons.videocam, color: Colors.white, size: 20))
//                                       : null,
//                                 ),
//                               ),
//                             ],
//                           );
// // ...
//                         }).toList(),
//                       ),
//
//                       const SizedBox(width: 8),
//
//                       // + ADD VIDEO (Replaced by the general bottom tool bar option, but keeping as visual placeholder)
//                       GestureDetector(
//                         onTap: _addVideo,
//                         child: Container(
//                           width: 50,
//                           height: 50,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: const Color(0xFF9F7AEA)),
//                           ),
//                           alignment: Alignment.center,
//                           child: const Icon(Icons.add, color: Colors.white, size: 24),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 10), // Separator
//
//                   // 2. AUDIO TRACK (Simplified for the screenshot's 'Add Audio' text bar)
//                   InkWell(
//                     onTap: _addAudio,
//                     child: Container(
//                       height: 30, // Shorter bar
//                       width: 150, // Fixed width for the button
//                       padding: const EdgeInsets.symmetric(horizontal: 10),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF2A2A2A),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.add, size: 18, color: Color(0xFF9F7AEA)),
//                           SizedBox(width: 6),
//                           Text("Add Audio", style: TextStyle(color: Colors.white, fontSize: 12)),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//   /* ───── Helper: Sound / Cover button ───── */
//   Widget _timelineButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//     double width = 80,
//     double height = 80
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: width,
//         height: height,
//         decoration: BoxDecoration(
//           color: const Color(0xFF2A2A2A),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: Colors.white, size: 24),
//             const SizedBox(height: 4),
//             Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
//           ],
//         ),
//       ),
//     );
//   }
//   /* ───── Helper: Cover thumbnail ───── */
//   Widget _coverThumbnail(TimelineItem clip) {
//     return GestureDetector(
//       onTap: () => setState(() {
//         _selectedVideoIndex = 0;
//         _selectedAudioIndex = null;
//       }),
//       child: Container(
//         width: 70, // Matches the Sound ON button width
//         height: 50, // Matches the video clip height
//         margin: const EdgeInsets.only(right: 8),
//         decoration: BoxDecoration(
//           color: const Color(0xFF2A2A2A),
//           borderRadius: BorderRadius.circular(8),
//           border: _selectedVideoIndex == 0 ? Border.all(color: const Color(0xFF9F7AEA), width: 2) : null,
//         ),
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             if (clip.thumbnailPaths.isNotEmpty)
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.file(File(clip.thumbnailPaths[0]), fit: BoxFit.cover),
//               ),
//             // Dark overlay and text/icon
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.black45,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               alignment: Alignment.center,
//               child: const Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.edit, color: Colors.white, size: 16),
//                   Text('Cover', style: TextStyle(color: Colors.white, fontSize: 10)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildToolOptionBar() {
//     return Container(
//       height: 70,
//       color: Colors.black,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _toolButton('Edit', Icons.content_cut, false, () {}),
//           _toolButton('Audio', Icons.volume_up, false, () {}),
//           _toolButton('Caption', Icons.closed_caption, false, () {}),
//           _toolButton('Text', Icons.text_fields, false, () {}),
//           _toolButton('Effect', Icons.auto_fix_high, false, () {}),
//           _toolButton('Adjust', Icons.tune, false, () {}),
//         ],
//       ),
//     );
//   }
//   /* ───── Scrub play-head with drag ───── */
//   void _scrubPlayhead(double deltaX) {
//     final width = MediaQuery.of(context).size.width - 32;
//     final ratio = (_playheadPosition.inMilliseconds / _totalDuration.inMilliseconds) + (deltaX / width);
//     final newPos = (ratio.clamp(0.0, 1.0) * _totalDuration.inMilliseconds).round();
//     setState(() => _playheadPosition = Duration(milliseconds: newPos));
//     _updatePreview();
//   }
//
//
// // Redefine the toolButton helper for the new fixed bar
//   Widget _toolButton(String label, IconData icon, bool isActive, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 4),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               color: isActive ? const Color(0xFF8B5CF6) : Colors.white,
//               size: 24,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 color: isActive ? const Color(0xFF8B5CF6) : Colors.white,
//                 fontSize: 10,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildContextTools() {
//     final isVideo = _selectedVideoIndex != null;
//
//     return Container(
//       height: 70,
//       color: Colors.black,
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           if (isVideo) ...[
//             _contextTool('Split', Icons.content_cut, _split),
//             _contextTool('Speed', Icons.speed, () {}),
//             _contextTool('Volume', Icons.volume_up, () {}),
//             _contextTool('Rotate', Icons.rotate_right, () {}),
//           ] else ...[
//             _contextTool('Volume', Icons.volume_up, () {}),
//             _contextTool('Fade', Icons.gradient, () {}),
//           ],
//           _contextTool('Delete', Icons.delete, _delete),
//         ],
//       ),
//     );
//   }
//
//   Widget _contextTool(String label, IconData icon, VoidCallback onTap) => GestureDetector(
//     onTap: onTap,
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: const Color(0xFF2A2A2A),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, size: 20, color: Colors.white),
//         ),
//         const SizedBox(height: 4),
//         Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
//       ],
//     ),
//   );
//
//   // Optional: Keep these if you plan to use them later
//   Widget _buildClipRow({
//     required TimelineItem clip,
//     required bool isSelected,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: 60,
//         margin: const EdgeInsets.only(bottom: 8),
//         decoration: BoxDecoration(
//           color: const Color(0xFF1A1A1A),
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: isSelected ? const Color(0xFF8B5CF6) : Colors.white12,
//             width: isSelected ? 2 : 1,
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 50,
//               alignment: Alignment.center,
//               child: Icon(
//                 clip.isAudio ? Icons.music_note : Icons.volume_up,
//                 color: Colors.white,
//                 size: 20,
//               ),
//             ),
//             Expanded(
//               child: clip.thumbnailPaths.isNotEmpty
//                   ? ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 physics: const BouncingScrollPhysics(),
//                 itemCount: clip.thumbnailPaths.length,
//                 itemBuilder: (context, index) {
//                   return Container(
//                     width: 40,
//                     margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 6),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(4),
//                       image: DecorationImage(
//                         image: FileImage(File(clip.thumbnailPaths[index])),
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   );
//                 },
//               )
//                   : Container(
//                 margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
//                 child: Row(
//                   children: List.generate(
//                     50,
//                         (i) => Container(
//                       width: 2,
//                       height: 10 + (i % 4) * 6,
//                       margin: const EdgeInsets.symmetric(horizontal: 1),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF10B981),
//                         borderRadius: BorderRadius.circular(1),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Text(
//                 _formatDuration(clip.duration),
//                 style: const TextStyle(color: Colors.white70, fontSize: 11),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAddClipButton() => GestureDetector(
//     onTap: _addVideo,
//     child: Container(
//       height: 60,
//       margin: const EdgeInsets.only(bottom: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(30),
//       ),
//       child: const Center(
//         child: Icon(Icons.add, color: Colors.black, size: 28),
//       ),
//     ),
//   );
//
//   Widget _buildAddAudioButton() => GestureDetector(
//     onTap: _addAudio,
//     child: Container(
//       height: 50,
//       decoration: BoxDecoration(
//         color: const Color(0xFF1A1A1A),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.white24),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: const [
//           Icon(Icons.add, color: Colors.white54, size: 20),
//           SizedBox(width: 8),
//           Text('Add Audio', style: TextStyle(color: Colors.white54, fontSize: 14)),
//         ],
//       ),
//     ),
//   );
// }
//
// /* ------------------------------------------------------------------ */
// /* PLAYHEAD PAINTER */
// /* ------------------------------------------------------------------ */
// class _PlayheadPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = const Color(0xFF9F7AEA); // Purple color
//     final path = Path();
//
//     // Hexagon shape
//     path.moveTo(size.width * 0.5, 0); // Top center
//     path.lineTo(size.width, size.height * 0.3);
//     path.lineTo(size.width, size.height);
//     path.lineTo(0, size.height);
//     path.lineTo(0, size.height * 0.3);
//     path.close();
//
//     canvas.drawPath(path, paint);
//
//     // Draw the purple line from the bottom of the hexagon
//     canvas.drawRect(Rect.fromLTWH(size.width / 2 - 1, size.height, 2, 12), paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
