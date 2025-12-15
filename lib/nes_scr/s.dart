// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit_config.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:kwaic/nes_scr/widgets/play_back_controls.dart';
// import 'package:kwaic/nes_scr/widgets/preview_player.dart';
// import 'package:kwaic/nes_scr/widgets/timeline.dart';
// import 'package:video_player/video_player.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
//
// // Controllers
//
// // Models
// import '../model/timeline_item.dart';
// import '../servuices/audio_manager.dart';
// import '../servuices/clip_controller.dart';
// import '../servuices/playback_controller.dart';
// import '../servuices/time_line_controller.dart';
// import '../servuices/video_manager.dart';
// import '../widgets/play_back_controls.dart';
// import '../widgets/preview_player.dart';
// import '../widgets/timeline.dart';
// import '../widgets/toolbar.dart';
// import '../widgets/top_bar.dart';
// import 'model/timeline_item.dart';
//
// /// Main Video Editor Screen - Now simplified to ~300 lines!
// class VideoEditorScreen extends StatefulWidget {
//   final List<XFile>? initialVideos;
//   final String? projectId;
//   final String? projectName;
//
//   const VideoEditorScreen({
//     super.key,
//     this.initialVideos,
//     this.projectId,
//     this.projectName,
//   });
//
//   @override
//   State<VideoEditorScreen> createState() => _VideoEditorScreenState();
// }
//
// class _VideoEditorScreenState extends State<VideoEditorScreen> {
//   // Controllers
//   late VideoManager videoManager;
//   late AudioManager audioManager;
//   late PlaybackController playbackController;
//   late TimelineController timelineController;
//   late ClipController clipController;
//
//
//   // UI State
//   BottomNavMode _currentNavMode = BottomNavMode.normal;
//   bool _isInitializing = false;
//
//   // Project Info
//   late String projectId;
//   late String projectName;
//
//   @override
//   void initState() {
//     super.initState();
//
//     projectId =
//         widget.projectId ?? DateTime.now().millisecondsSinceEpoch.toString();
//     projectName = widget.projectName ?? 'Untitled Project';
//
//     _initializeControllers();
//
//     if (widget.initialVideos?.isNotEmpty == true) {
//       WidgetsBinding.instance.addPostFrameCallback(
//             (_) => _processInitialVideos(),
//       );
//     }
//   }
//
//   void _initializeControllers() {
//     videoManager = VideoManager();
//     audioManager = AudioManager();
//
//     playbackController = PlaybackController(
//       videoManager: videoManager,
//       audioManager: audioManager,
//     );
//
//     timelineController = TimelineController();
//
//     clipController = ClipController(
//       videoManager: videoManager,
//       audioManager: audioManager, timelineController: timelineController,
//     );
//
//     // Listen to controllers
//   }
//
//   Future<void> _processInitialVideos() async {
//     if (_isInitializing || widget.initialVideos == null) return;
//
//     setState(() => _isInitializing = true);
//
//     try {
//       Duration currentStart = Duration.zero;
//
//       for (var videoFile in widget.initialVideos!) {
//         final item = await _createVideoItemFromFile(
//           videoFile,
//           startTime: currentStart,
//         );
//
//         if (item != null) {
//           await clipController.addVideoClip(item);
//           currentStart += item.duration;
//         }
//       }
//
//       // Switch to first clip
//       if (clipController.videoClips.isNotEmpty) {
//         final firstClip = clipController.videoClips.first;
//         await videoManager.switchToClip(
//           firstClip,
//           playheadPosition: Duration.zero,
//           isPlaying: false,
//         );
//       }
//     } catch (e) {
//       debugPrint('❌ Error loading videos: $e');
//       _showError('Failed to load videos');
//     } finally {
//       if (mounted) setState(() => _isInitializing = false);
//     }
//   }
//
//   Future<TimelineItem?> _createVideoItemFromFile(
//       XFile file, {
//         Duration startTime = Duration.zero,
//       })
//   async {
//     try {
//       final path = file.path;
//       final fileObj = File(path);
//
//       // 1. Get real duration
//       final controller = VideoPlayerController.file(fileObj);
//       await controller.initialize();
//       final duration = controller.value.duration;
//       await controller.dispose(); // Clean!
//
//       // 2. Generate thumbnails with fallback
//       List<Uint8List> thumbs = [];
//       try {
//         thumbs = await clipController.generateRobustThumbnails(path, duration);
//       } catch (e) {
//         debugPrint('FFmpeg thumbnail failed: $e, using fallback...');
//         thumbs = await _generateFallbackThumbnails(path, duration);
//       }
//
//       return TimelineItem(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         type: TimelineItemType.video,
//         file: fileObj,
//         startTime: startTime,
//         duration: duration,
//         originalDuration: duration,
//         trimStart: Duration.zero,
//         trimEnd: duration,
//         thumbnailBytes: thumbs,
//       );
//     } catch (e, s) {
//       debugPrint('Error creating video item: $e\n$s');
//       return null;
//     }
//   }
//
//   Future<List<Uint8List>> _generateFallbackThumbnails(String videoPath, Duration duration) async {
//     final List<Uint8List> thumbs = [];
//     const int count = 12;
//     final int safeStartMs = 800; // Skip first 0.8s (avoids black frame)
//     final int safeEndMs = (duration.inMilliseconds - 1000).clamp(1000, duration.inMilliseconds);
//
//     if (duration.inMilliseconds < 2000) {
//       // Short video → grab middle frame
//       final thumb = await VideoThumbnail.thumbnailData(
//         video: videoPath,
//         imageFormat: ImageFormat.JPEG,
//         timeMs: (duration.inMilliseconds / 2).round(),
//         maxWidth: 160,
//         quality: 85,
//       );
//       if (thumb != null) return List.filled(count, thumb);
//       return [];
//     }
//
//     for (int i = 0; i < count; i++) {
//       final progress = i / (count - 1);
//       final targetMs = (safeStartMs + (safeEndMs - safeStartMs) * progress).round();
//
//       try {
//         final uint8list = await VideoThumbnail.thumbnailData(
//           video: videoPath,
//           imageFormat: ImageFormat.JPEG,
//           timeMs: targetMs,
//           maxWidth: 160,
//           quality: 85,
//         );
//
//         if (uint8list != null && uint8list.length > 1000) {
//           thumbs.add(uint8list);
//         } else {
//           // Fill gap: duplicate previous good frame
//           if (thumbs.isNotEmpty) thumbs.add(thumbs.last);
//         }
//       } catch (e) {
//         debugPrint('Thumbnail failed at ${targetMs}ms: $e');
//         if (thumbs.isNotEmpty) thumbs.add(thumbs.last);
//       }
//     }
//
//     return thumbs;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isInitializing) {
//       return const Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(
//           child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
//         ),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top Bar
//             TopBar(
//               projectName: projectName,
//               onBack: _handleBack,
//               onExport: _handleExport,
//               onHelp: () => _showMessage('Help coming soon'),
//             ),
//
//
//             Expanded(
//               child: AnimatedBuilder(
//                 animation: Listenable.merge([clipController, playbackController]),
//                 builder: (_, __) {
//                   return VideoPreview(
//                     videoManager: videoManager,
//                     clipController: clipController,
//                     playheadPosition: playbackController.playheadPosition,
//                   );
//                 },
//               ),
//             ),
//
//
//             AnimatedBuilder(
//               animation: playbackController,
//               builder: (_, __) {
//                 return PlaybackControls(
//                   isPlaying: playbackController.isPlaying,
//                   playheadPosition: playbackController.playheadPosition,
//                   totalDuration: _getTotalDuration(),
//                   onPlayPause: _handlePlayPause,
//                   onUndo: _handleUndo,
//                   onRedo: _handleRedo,
//                 );
//               },
//             ),
//
//
//             AnimatedBuilder(
//               animation: Listenable.merge([
//                 timelineController,
//                 clipController,
//                 playbackController,
//               ]),
//               builder: (_, __) {
//                 return TimelineView(
//                   controller: timelineController,
//                   clipController: clipController,
//                   playheadPosition: playbackController.playheadPosition,
//                   isPlaying: playbackController.isPlaying,  // ← ADD THIS LINE
//                   onTimelineTap: _handleTimelineTap,
//                   onClipSelected: _handleClipSelected,
//                 );
//               },
//             ),
//
//             // Context Tools (if in special mode)
//             if (_currentNavMode != BottomNavMode.normal) _buildContextTools(),
//
//             // Bottom Navigation
//             BottomNav(
//               currentMode: _currentNavMode,
//               onModeChanged: _handleNavModeChanged,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//   Future<void> _handlePlayPause() async {
//     await playbackController.togglePlayPause(
//       clips: clipController.videoClips,
//       audioItems: clipController.audioClips,
//     );
//   }
//
//   void _handleTimelineTap(Offset position) {
//     final newPosition = timelineController.handleTimelineTap(
//       position,
//       MediaQuery.of(context).size.width,
//     );
//
//     playbackController.seekTo(
//       newPosition,
//       clips: clipController.videoClips,
//       audioItems: clipController.audioClips,
//     );
//   }
//
//   void _handleClipSelected(String clipId, TimelineItemType type) {
//     clipController.selectClip(clipId, type);
//   }
//
//   void _handleNavModeChanged(BottomNavMode mode) {
//     setState(() {
//       _currentNavMode = mode;
//
//       // Update timeline display mode
//       switch (mode) {
//         case BottomNavMode.audio:
//           timelineController.setDisplayMode(TimelineDisplayMode.videoAudioOnly);
//           break;
//         case BottomNavMode.text:
//           timelineController.setDisplayMode(TimelineDisplayMode.videoTextOnly);
//           break;
//         case BottomNavMode.overlay:
//           timelineController.setDisplayMode(TimelineDisplayMode.videoOverlayOnly);
//           break;
//         case BottomNavMode.edit:
//           timelineController.setDisplayMode(TimelineDisplayMode.allTracks);
//
//           // === AUTO SELECT CURRENT VIDEO CLIP IN EDIT MODE ===
//           final currentClip = clipController.getActiveVideoClip(playbackController.playheadPosition);
//           if (currentClip != null) {
//             clipController.selectClip(currentClip.id, currentClip.type);
//             // Optional: Seek to start of clip for easy editing
//             playbackController.seekTo(
//               currentClip.startTime,
//               clips: clipController.videoClips,
//               audioItems: clipController.audioClips,
//             );
//           }
//           break;
//         default:
//           timelineController.setDisplayMode(TimelineDisplayMode.allTracks);
//       }
//     });
//   }
//
//   Future<void> _handleBack() async {
//     // Check for unsaved changes
//     final shouldPop = await _confirmUnsavedChanges();
//     if (shouldPop && mounted) {
//       Navigator.pop(context);
//     }
//   }
//
//   Future<void> _handleExport() async {
//     _showMessage('Export feature coming soon');
//     // This would use ExportService
//   }
//
//   void _handleUndo() {
//     _showMessage('Undo coming soon');
//
//     // This would use HistoryManager
//   }
//
//   void _handleRedo() {
//     _showMessage('Redo coming soon');
//     // This would use HistoryManager
//   }
//
//   Widget _buildContextTools() {
//     return Container(
//       height: 70,
//       color: const Color(0xFF1A1A1A),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: _getToolsForMode(_currentNavMode),
//         ),
//       ),
//     );
//   }
//
//   List<Widget> _getToolsForMode(BottomNavMode mode) {
//     switch (mode) {
//       case BottomNavMode.edit:
//         return [
//           _toolButton(Icons.content_cut, 'Split', _handleSplit),
//           _toolButton(Icons.speed, 'Speed', _handleSpeed),
//           _toolButton(Icons.crop, 'Crop', _handleCrop),
//           _toolButton(Icons.rotate_left, "Rotate", (){}),
//           _toolButton(Icons.delete, 'Delete', _handleDelete, color: Colors.red),
//         ];
//       case BottomNavMode.audio:
//         return [
//           _toolButton(Icons.audiotrack, 'Extract', _handleExtractAudio),
//           _toolButton(Icons.music_note, 'Sound', _handleOpenMusicLibrary),
//           _toolButton(Icons.graphic_eq, 'Sound FX', _handleOpenSoundFX),
//           _toolButton(Icons.mic, 'Record', _handleRecordVoiceover),
//           _toolButton(Icons.record_voice_over, 'Text to Audio', _handleTextToAudio),
//         ];
//       case BottomNavMode.text:
//         return [
//           _toolButton(Icons.add, 'Add', _handleAddText),
//           _toolButton(Icons.edit, 'Edit', _handleEditText),
//           _toolButton(Icons.delete, 'Delete', _handleDelete, color: Colors.red),
//         ];
//       default:
//         return [];
//     }
//   }
//
//   Widget _toolButton(
//       IconData icon,
//       String label,
//       VoidCallback onTap, {
//         Color? color,
//       }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 70,
//         padding: const EdgeInsets.all(10),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color: color ?? const Color(0xFF00D9FF),
//               size: 28,
//             ),
//             const SizedBox(height: 6),
//             Text(
//               label,
//               style: TextStyle(
//                 color: color ?? Colors.white,
//                 fontSize: 10,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//   // Tool Actions
//   // void _handleSplit() {
//   //   // Use the selected clip if available, otherwise find at playhead
//   //   TimelineItem? clip;
//   //   if (clipController.selectedClipType == TimelineItemType.video &&
//   //       clipController.selectedClipId != null) {
//   //     clip = clipController.videoClips.firstWhere(
//   //           (c) => c.id == clipController.selectedClipId,
//   //     );
//   //   } else {
//   //     clip = clipController.getActiveVideoClip(playbackController.playheadPosition);
//   //   }
//   //
//   //   if (clip != null &&
//   //       playbackController.playheadPosition > clip.startTime &&
//   //       playbackController.playheadPosition < clip.startTime + clip.duration) {
//   //     clipController.splitClip(clip, playbackController.playheadPosition);
//   //   }
//   // }
//
//   void _handleSplit() {
//     final clip = clipController.getActiveVideoClip(playbackController.playheadPosition);
//     if (clip != null) {
//       clipController.splitClip(clip, playbackController.playheadPosition);
//     }
//   }
//
//   void _handleDelete() {
//     if (clipController.selectedClipType == TimelineItemType.video &&
//         clipController.selectedClipId != null) {
//       clipController.deleteClip(clipController.selectedClipId!, clipController.selectedClipType!);
//     }
//   }
//   void _handleSpeed() => _showMessage('Speed editor coming soon');
//   void _handleCrop() => _showMessage('Crop editor coming soon');
//   void _handleExtractAudio() => _showMessage('Extract audio coming soon');
//   void _handleOpenMusicLibrary() => _showAudioLibrarySheet();
//   void _handleOpenSoundFX() => _showSoundFXSheet();
//   void _handleRecordVoiceover() => _showMessage('Record voiceover coming soon');
//   void _handleTextToAudio() => _showTextToAudioSheet();
//   void _handleAddText() => _showMessage('Add text coming soon');
//   void _handleEditText() => _showMessage('Edit text coming soon');
//
//
//   // Helpers
//   Duration _getTotalDuration() {
//     return Duration(
//       seconds:
//       playbackController.getTotalDuration([
//         clipController.videoClips,
//         clipController.audioClips,
//         clipController.textClips,
//         clipController.overlayClips,
//       ]).toInt(),
//     );
//   }
//
//   Future<bool> _confirmUnsavedChanges() async {
//     // Simplified - would check autosave manager
//     return true;
//   }
//
//   void _showMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: const Color(0xFF10B981),
//       ),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   void dispose() {
//     playbackController.dispose();
//     videoManager.dispose();
//     audioManager.dispose();
//     timelineController.dispose();
//     clipController.dispose();
//     super.dispose();
//   }
// }
//
// // Bottom Navigation Modes
