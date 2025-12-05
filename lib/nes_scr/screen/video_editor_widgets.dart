// // PART 2: CapCut-Style Timeline with Resize Handles & Visual Feedback
// // =============================================================================
//
// // =============================================================================
// // 1. TIMELINE CLIP WITH RESIZE HANDLES (CapCut Style)
// // =============================================================================
//
// import 'dart:io';
// import 'dart:math' as math;
//
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
//
// import '../model/timeline_item.dart';
//
// class TimelineClipWidget extends StatefulWidget {
//   final TimelineItem item;
//   final double pixelsPerSecond;
//   final double timelineOffset;
//   final double centerX;
//   final bool isSelected;
//   final VoidCallback onTap;
//   final Function(Duration delta) onDrag;
//   final Function(Duration delta, bool isLeft) onResize;
//
//   const TimelineClipWidget({
//     super.key,
//     required this.item,
//     required this.pixelsPerSecond,
//     required this.timelineOffset,
//     required this.centerX,
//     required this.isSelected,
//     required this.onTap,
//     required this.onDrag,
//     required this.onResize,
//   });
//
//   @override
//   State<TimelineClipWidget> createState() => _TimelineClipWidgetState();
// }
//
// class _TimelineClipWidgetState extends State<TimelineClipWidget> {
//   bool _isResizingLeft = false;
//   bool _isResizingRight = false;
//   bool _isDragging = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final startX = widget.item.startTime.inSeconds * widget.pixelsPerSecond -
//         widget.timelineOffset;
//     final width = math.max(
//       widget.item.duration.inSeconds * widget.pixelsPerSecond,
//       60.0,
//     );
//
//     return Positioned(
//       left: startX + widget.centerX,
//       child: GestureDetector(
//         onTapDown: (_) => widget.onTap(),
//         onHorizontalDragStart: (details) {
//           final localX = details.localPosition.dx;
//           if (localX < 20) {
//             setState(() => _isResizingLeft = true);
//           } else if (localX > width - 20) {
//             setState(() => _isResizingRight = true);
//           } else {
//             setState(() => _isDragging = true);
//           }
//         },
//         onHorizontalDragUpdate: (details) {
//           final deltaSec = Duration(
//             milliseconds: ((details.delta.dx / widget.pixelsPerSecond) * 1000).round(),
//           );
//
//           if (_isResizingLeft || _isResizingRight) {
//             widget.onResize(deltaSec, _isResizingLeft);
//           } else if (_isDragging) {
//             widget.onDrag(deltaSec);
//           }
//         },
//         onHorizontalDragEnd: (_) {
//           setState(() {
//             _isResizingLeft = false;
//             _isResizingRight = false;
//             _isDragging = false;
//           });
//         },
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 150),
//           width: width,
//           height: 60,
//           decoration: BoxDecoration(
//             color: Colors.grey[850],
//             borderRadius: BorderRadius.circular(8),
//             border: widget.isSelected
//                 ? Border.all(color: const Color(0xFF00D9FF), width: 3)
//                 : Border.all(color: Colors.white24, width: 1),
//             boxShadow: widget.isSelected
//                 ? [
//               BoxShadow(
//                 color: const Color(0xFF00D9FF).withOpacity(0.5),
//                 blurRadius: 8,
//                 spreadRadius: 2,
//               ),
//             ]
//                 : null,
//           ),
//           child: Stack(
//             children: [
//               // Thumbnail strip
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: _buildThumbnailStrip(width),
//               ),
//
//               // LEFT RESIZE HANDLE (CapCut style)
//               if (width > 60)
//                 Positioned(
//                   left: 0,
//                   top: 0,
//                   bottom: 0,
//                   child: Container(
//                     width: 20,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.centerLeft,
//                         end: Alignment.centerRight,
//                         colors: [
//                           Colors.black.withOpacity(0.6),
//                           Colors.transparent,
//                         ],
//                       ),
//                     ),
//                     child: Center(
//                       child: Container(
//                         width: 4,
//                         height: 30,
//                         decoration: BoxDecoration(
//                           color: widget.isSelected
//                               ? const Color(0xFF00D9FF)
//                               : Colors.white,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//
//               // RIGHT RESIZE HANDLE
//               if (width > 60)
//                 Positioned(
//                   right: 0,
//                   top: 0,
//                   bottom: 0,
//                   child: Container(
//                     width: 20,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.centerRight,
//                         end: Alignment.centerLeft,
//                         colors: [
//                           Colors.black.withOpacity(0.6),
//                           Colors.transparent,
//                         ],
//                       ),
//                     ),
//                     child: Center(
//                       child: Container(
//                         width: 4,
//                         height: 30,
//                         decoration: BoxDecoration(
//                           color: widget.isSelected
//                               ? const Color(0xFF00D9FF)
//                               : Colors.white,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//
//               // Duration label
//               Positioned(
//                 bottom: 2,
//                 left: 0,
//                 right: 0,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(vertical: 2),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.7),
//                     borderRadius: const BorderRadius.vertical(
//                       bottom: Radius.circular(8),
//                     ),
//                   ),
//                   child: Text(
//                     _formatDuration(widget.item.duration),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 9,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//
//               // Selection indicator (top bar)
//               if (widget.isSelected)
//                 Positioned(
//                   top: 0,
//                   left: 0,
//                   right: 0,
//                   child: Container(
//                     height: 3,
//                     decoration: const BoxDecoration(
//                       color: Color(0xFF00D9FF),
//                       borderRadius: BorderRadius.vertical(
//                         top: Radius.circular(8),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildThumbnailStrip(double clipWidth) {
//     if (widget.item.thumbnailBytes == null ||
//         widget.item.thumbnailBytes!.isEmpty) {
//       return Container(
//         color: const Color(0xFF2A2A2A),
//         child: const Center(
//           child: Icon(Icons.videocam, color: Colors.white30, size: 20),
//         ),
//       );
//     }
//
//     final thumbs = widget.item.thumbnailBytes!;
//     final thumbWidth = clipWidth / thumbs.length;
//
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: List.generate(thumbs.length, (i) {
//         return SizedBox(
//           width: thumbWidth,
//           height: double.infinity,
//           child: Image.memory(
//             thumbs[i],
//             fit: BoxFit.cover,
//             gaplessPlayback: true,
//             errorBuilder: (_, __, ___) => Container(
//               color: const Color(0xFF2A2A2A),
//             ),
//           ),
//         );
//       }),
//     );
//   }
//
//   String _formatDuration(Duration d) {
//     final secs = d.inSeconds;
//     final mins = secs ~/ 60;
//     final remainingSecs = secs % 60;
//     return '${mins.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
//   }
// }
//
// // =============================================================================
// // 2. MUSIC SELECTOR WITH PREVIEW (CapCut Style)
// // =============================================================================
//
// class MusicSelectorDialog extends StatefulWidget {
//   final Function(File audioFile, Duration duration) onMusicSelected;
//
//   const MusicSelectorDialog({super.key, required this.onMusicSelected});
//
//   @override
//   State<MusicSelectorDialog> createState() => _MusicSelectorDialogState();
// }
//
// class _MusicSelectorDialogState extends State<MusicSelectorDialog> {
//   List<MusicItem> _musicFiles = [];
//   MusicItem? _playingMusic;
//   VideoPlayerController? _previewController;
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadMusicFiles();
//   }
//
//   Future<void> _loadMusicFiles() async {
//     setState(() => _isLoading = true);
//
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.audio,
//       allowMultiple: true,
//     );
//
//     if (result != null) {
//       final items = <MusicItem>[];
//       for (final file in result.files) {
//         if (file.path != null) {
//           final controller = VideoPlayerController.file(File(file.path!));
//           await controller.initialize();
//
//           items.add(MusicItem(
//             file: File(file.path!),
//             name: file.name,
//             duration: controller.value.duration,
//             controller: controller,
//           ));
//         }
//       }
//
//       setState(() {
//         _musicFiles = items;
//         _isLoading = false;
//       });
//     } else {
//       Navigator.pop(context);
//     }
//   }
//
//   Future<void> _playPreview(MusicItem music) async {
//     // Stop current
//     if (_previewController != null) {
//       await _previewController!.pause();
//       await _previewController!.seekTo(Duration.zero);
//     }
//
//     setState(() => _playingMusic = music);
//
//     _previewController = music.controller;
//     await _previewController!.setVolume(1.0);
//     await _previewController!.play();
//
//     // Auto-stop after 15 seconds
//     Future.delayed(const Duration(seconds: 15), () {
//       if (_previewController == music.controller) {
//         _stopPreview();
//       }
//     });
//   }
//
//   Future<void> _stopPreview() async {
//     await _previewController?.pause();
//     await _previewController?.seekTo(Duration.zero);
//     setState(() => _playingMusic = null);
//   }
//
//   @override
//   void dispose() {
//     _previewController?.pause();
//     for (final music in _musicFiles) {
//       music.controller.dispose();
//     }
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.75,
//       decoration: const BoxDecoration(
//         color: Color(0xFF1A1A1A),
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         children: [
//           // Header
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               border: Border(
//                 bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
//               ),
//             ),
//             child: Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.close, color: Colors.white),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//                 const Expanded(
//                   child: Text(
//                     'Add Music',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//                 const SizedBox(width: 48),
//               ],
//             ),
//           ),
//
//           // Music list
//           Expanded(
//             child: _isLoading
//                 ? const Center(
//               child: CircularProgressIndicator(
//                 color: Color(0xFF00D9FF),
//               ),
//             )
//                 : ListView.builder(
//               itemCount: _musicFiles.length,
//               padding: const EdgeInsets.all(16),
//               itemBuilder: (context, index) {
//                 final music = _musicFiles[index];
//                 final isPlaying = _playingMusic == music;
//
//                 return Container(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF2A2A2A),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: isPlaying
//                           ? const Color(0xFF00D9FF)
//                           : Colors.transparent,
//                       width: 2,
//                     ),
//                   ),
//                   child: ListTile(
//                     leading: Container(
//                       width: 48,
//                       height: 48,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF10B981),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Icon(
//                         Icons.music_note,
//                         color: Colors.white,
//                       ),
//                     ),
//                     title: Text(
//                       music.name,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     subtitle: Text(
//                       _formatDuration(music.duration),
//                       style: const TextStyle(color: Colors.white54),
//                     ),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Play/Pause preview
//                         IconButton(
//                           icon: Icon(
//                             isPlaying ? Icons.pause : Icons.play_arrow,
//                             color: const Color(0xFF00D9FF),
//                           ),
//                           onPressed: () {
//                             if (isPlaying) {
//                               _stopPreview();
//                             } else {
//                               _playPreview(music);
//                             }
//                           },
//                         ),
//                         // Add button
//                         IconButton(
//                           icon: const Icon(
//                             Icons.add_circle,
//                             color: Color(0xFF00D9FF),
//                           ),
//                           onPressed: () {
//                             widget.onMusicSelected(
//                               music.file,
//                               music.duration,
//                             );
//                             Navigator.pop(context);
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatDuration(Duration d) {
//     final mins = d.inMinutes;
//     final secs = d.inSeconds % 60;
//     return '$mins:${secs.toString().padLeft(2, '0')}';
//   }
// }
//
// class MusicItem {
//   final File file;
//   final String name;
//   final Duration duration;
//   final VideoPlayerController controller;
//
//   MusicItem({
//     required this.file,
//     required this.name,
//     required this.duration,
//     required this.controller,
//   });
// }
//
// // =============================================================================
// // 3. PREVIEW WITH VISUAL SELECTION FEEDBACK
// // =============================================================================
//
// Widget _buildPreviewWithSelection() {
//   return ValueListenableBuilder<PreviewState>(
//     valueListenable: _previewController,
//     builder: (context, state, child) {
//       Widget videoWidget;
//
//       if (state.controller != null && state.controller!.value.isInitialized) {
//         videoWidget = AspectRatio(
//           aspectRatio: state.controller!.value.aspectRatio,
//           child: VideoPlayer(state.controller!),
//         );
//       } else if (clips.isNotEmpty &&
//           clips.first.thumbnailBytes?.isNotEmpty == true) {
//         videoWidget = Image.memory(
//           clips.first.thumbnailBytes!.first,
//           fit: BoxFit.contain,
//         );
//       } else {
//         videoWidget = _buildPlaceholder();
//       }
//
//       // Apply filter
//       if (selectedFilter != null && selectedFilter != 'None') {
//         videoWidget = ColorFiltered(
//           colorFilter: _getFilter(selectedFilter!),
//           child: videoWidget,
//         );
//       }
//
//       // Visual feedback for selected clip
//       if (_selection.isEditMode && _selection.clipId != null) {
//         videoWidget = Stack(
//           fit: StackFit.expand,
//           children: [
//             videoWidget,
//             // Border overlay
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(
//                   color: const Color(0xFF00D9FF),
//                   width: 4,
//                 ),
//               ),
//             ),
//             // Selection indicator
//             Positioned(
//               top: 16,
//               left: 16,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF00D9FF),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: const [
//                     Icon(Icons.edit, color: Colors.black, size: 14),
//                     SizedBox(width: 4),
//                     Text(
//                       'EDITING',
//                       style: TextStyle(
//                         color: Colors.black,
//                         fontSize: 11,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         );
//       }
//
//       return Container(
//         color: Colors.black,
//         child: Center(child: videoWidget),
//       );
//     },
//   );
// }