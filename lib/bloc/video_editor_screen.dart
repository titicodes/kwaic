// // // video_editor_screen.dart
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// // import 'package:kwaic/bloc/video_editor_bloc.dart';
// // import 'package:kwaic/bloc/video_editor_event.dart';
// // import 'package:kwaic/bloc/video_editor_state.dart';
// // import 'package:path_provider/path_provider.dart';
// // import 'package:video_player/video_player.dart';
// // import 'package:file_picker/file_picker.dart';
// //
// // class VideoEditorScreen extends StatelessWidget {
// //   const VideoEditorScreen({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return BlocProvider(
// //       create: (context) => VideoEditorBloc(),
// //       child: const VideoEditorView(),
// //     );
// //   }
// // }
// //
// //
// //
// // class VideoEditorView extends StatelessWidget {
// //   const VideoEditorView({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.black,
// //       body: SafeArea(
// //         child: BlocListener<VideoEditorBloc, VideoEditorState>(
// //           listener: (context, state) {
// //             if (state is VideoEditorLoaded && state.errorMessage != null) {
// //               ScaffoldMessenger.of(context).showSnackBar(
// //                 SnackBar(
// //                   content: Text(state.errorMessage!),
// //                   backgroundColor: Colors.red,
// //                 ),
// //               );
// //             } else if (state is VideoEditorError) {
// //               ScaffoldMessenger.of(context).showSnackBar(
// //                 SnackBar(
// //                   content: Text(state.message),
// //                   backgroundColor: Colors.red,
// //                 ),
// //               );
// //             }
// //           },
// //           child: Column(
// //             children: const [
// //               _TopBar(),
// //               Expanded(child: _PreviewArea()),
// //               _TimelineArea(),
// //               _BottomToolbar(),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // ==================== TOP BAR ====================
// //
// // class _TopBar extends StatelessWidget {
// //   const _TopBar({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       height: 56,
// //       padding: const EdgeInsets.symmetric(horizontal: 8),
// //       decoration: const BoxDecoration(
// //         color: Color(0xFF1C1C1E),
// //         border: Border(bottom: BorderSide(color: Color(0xFF2C2C2E), width: 1)),
// //       ),
// //       child: Row(
// //         children: [
// //           IconButton(
// //             icon: const Icon(Icons.close, color: Colors.white),
// //             onPressed: () => Navigator.pop(context),
// //             tooltip: 'Close',
// //           ),
// //           // Undo button - disabled for now (can be implemented with history management)
// //           IconButton(
// //             icon: const Icon(Icons.undo, color: Colors.white),
// //             onPressed: null, // TODO: Implement undo/redo with history
// //             tooltip: 'Undo',
// //           ),
// //           // Redo button
// //           IconButton(
// //             icon: const Icon(Icons.redo, color: Colors.white),
// //             onPressed: null, // TODO: Implement undo/redo with history
// //             tooltip: 'Redo',
// //           ),
// //           const Spacer(),
// //           IconButton(
// //             icon: const Icon(Icons.settings, color: Colors.white),
// //             onPressed: () => _showProjectSettings(context),
// //             tooltip: 'Settings',
// //           ),
// //           const SizedBox(width: 8),
// //           BlocBuilder<VideoEditorBloc, VideoEditorState>(
// //             builder: (context, state) {
// //               if (state is VideoEditorLoaded && state.isExporting) {
// //                 return SizedBox(
// //                   width: 90,
// //                   height: 36,
// //                   child: Center(
// //                     child: Stack(
// //                       alignment: Alignment.center,
// //                       children: [
// //                         SizedBox(
// //                           width: 24,
// //                           height: 24,
// //                           child: CircularProgressIndicator(
// //                             value: state.exportProgress,
// //                             strokeWidth: 2,
// //                             color: Colors.white,
// //                           ),
// //                         ),
// //                         Text(
// //                           '${(state.exportProgress * 100).toInt()}%',
// //                           style: const TextStyle(
// //                             color: Colors.white,
// //                             fontSize: 8,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 );
// //               }
// //
// //               return ElevatedButton.icon(
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: const Color(0xFF0A84FF),
// //                   padding: const EdgeInsets.symmetric(
// //                     horizontal: 20,
// //                     vertical: 10,
// //                   ),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(8),
// //                   ),
// //                 ),
// //                 onPressed: () => _exportVideo(context),
// //                 icon: const Icon(Icons.file_download, size: 18),
// //                 label: const Text(
// //                   'Export',
// //                   style: TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 14,
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //               );
// //             },
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   void _showProjectSettings(BuildContext context) {
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: const Color(0xFF1C1C1E),
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (context) => Padding(
// //         padding: const EdgeInsets.all(20),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             const Text(
// //               'Project Settings',
// //               style: TextStyle(
// //                 color: Colors.white,
// //                 fontSize: 20,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             const SizedBox(height: 20),
// //             ListTile(
// //               leading: const Icon(Icons.aspect_ratio, color: Color(0xFF0A84FF)),
// //               title: const Text(
// //                 'Aspect Ratio',
// //                 style: TextStyle(color: Colors.white),
// //               ),
// //               subtitle: const Text(
// //                 '9:16 (Portrait)',
// //                 style: TextStyle(color: Colors.white60),
// //               ),
// //               trailing: const Icon(Icons.chevron_right, color: Colors.white60),
// //               onTap: () {},
// //             ),
// //             ListTile(
// //               leading: const Icon(Icons.high_quality, color: Color(0xFF0A84FF)),
// //               title: const Text(
// //                 'Export Quality',
// //                 style: TextStyle(color: Colors.white),
// //               ),
// //               subtitle: const Text(
// //                 '1080p HD',
// //                 style: TextStyle(color: Colors.white60),
// //               ),
// //               trailing: const Icon(Icons.chevron_right, color: Colors.white60),
// //               onTap: () {},
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Future<void> _exportVideo(BuildContext context) async {
// //     final directory = await getTemporaryDirectory();
// //     final outputPath =
// //         '${directory.path}/export_${DateTime.now().millisecondsSinceEpoch}.mp4';
// //
// //     context.read<VideoEditorBloc>().add(ExportVideoEvent(outputPath: outputPath));
// //   }
// // }
// //
// // // ==================== PREVIEW AREA ====================
// //
// // class _PreviewArea extends StatelessWidget {
// //   const _PreviewArea({Key? key}) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       color: Colors.black,
// //       child: Center(
// //         child: AspectRatio(
// //           aspectRatio: 9 / 16,
// //           child: BlocBuilder<VideoEditorBloc, VideoEditorState>(
// //             builder: (context, state) {
// //               if (state is! VideoEditorLoaded || state.clips.isEmpty) {
// //                 return _EmptyPreview();
// //               }
// //
// //               return Stack(
// //                 fit: StackFit.expand,
// //                 children: [
// //                   _VideoPlayer(),
// //                   _TextOverlaysLayer(),
// //                   _StickerOverlaysLayer(),
// //                 ],
// //               );
// //             },
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class _EmptyPreview extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       color: const Color(0xFF1C1C1E),
// //       child: Center(
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             const Icon(
// //               Icons.add_photo_alternate,
// //               size: 64,
// //               color: Colors.grey,
// //             ),
// //             const SizedBox(height: 16),
// //             ElevatedButton.icon(
// //               onPressed: () => _pickVideo(context),
// //               icon: const Icon(Icons.add),
// //               label: const Text('Add Video'),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: const Color(0xFF0A84FF),
// //                 foregroundColor: Colors.white,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Future<void> _pickVideo(BuildContext context) async {
// //     final result = await FilePicker.platform.pickFiles(
// //       type: FileType.video,
// //     );
// //
// //     if (result != null && result.files.single.path != null) {
// //       final file = File(result.files.single.path!);
// //       context.read<VideoEditorBloc>().add(LoadVideoEvent(file));
// //     }
// //   }
// // }
// //
// // class _VideoPlayer extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return BlocBuilder<VideoEditorBloc, VideoEditorState>(
// //       builder: (context, state) {
// //         if (state is! VideoEditorLoaded || state.videoController == null) {
// //           return const SizedBox();
// //         }
// //
// //         return ValueListenableBuilder<VideoPlayerValue>(
// //           valueListenable: state.videoController!,
// //           builder: (context, value, child) {
// //             if (!value.isInitialized) {
// //               return Container(
// //                 color: const Color(0xFF1C1C1E),
// //                 child: const Center(
// //                   child: CircularProgressIndicator(),
// //                 ),
// //               );
// //             }
// //
// //             return FittedBox(
// //               fit: BoxFit.contain,
// //               child: SizedBox(
// //                 width: value.size.width,
// //                 height: value.size.height,
// //                 child: VideoPlayer(state.videoController!),
// //               ),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }
// // }
// //
// // class _TextOverlaysLayer extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return BlocBuilder<VideoEditorBloc, VideoEditorState>(
// //       builder: (context, state) {
// //         if (state is! VideoEditorLoaded || state.selectedClip == null) {
// //           return const SizedBox();
// //         }
// //
// //         final clip = state.selectedClip!;
// //         final currentPos = state.currentPositionMs - clip.startMs;
// //
// //         return LayoutBuilder(
// //           builder: (context, constraints) {
// //             final width = constraints.maxWidth;
// //             final height = constraints.maxHeight;
// //
// //             return Stack(
// //               children: clip.textOverlays
// //                   .where((overlay) =>
// //               currentPos >= overlay.startMs &&
// //                   currentPos <= overlay.startMs + overlay.durationMs)
// //                   .map((overlay) => Positioned(
// //                 left: overlay.x * width - 100,
// //                 top: overlay.y * height - 50,
// //                 child: GestureDetector(
// //                   onPanUpdate: (details) {
// //                     final newX = (overlay.x + details.delta.dx / width)
// //                         .clamp(0.0, 1.0);
// //                     final newY = (overlay.y + details.delta.dy / height)
// //                         .clamp(0.0, 1.0);
// //
// //                     final overlayIndex = clip.textOverlays.indexOf(overlay);
// //                     context.read<VideoEditorBloc>().add(
// //                       UpdateTextOverlayEvent(
// //                         clipIndex: state.selectedClipIndex!,
// //                         overlayIndex: overlayIndex,
// //                         x: newX,
// //                         y: newY,
// //                       ),
// //                     );
// //                   },
// //                   child: Text(
// //                     overlay.text,
// //                     style: TextStyle(
// //                       color: Color(overlay.color),
// //                       fontSize: overlay.fontSize,
// //                       fontWeight: overlay.bold
// //                           ? FontWeight.bold
// //                           : FontWeight.normal,
// //                       fontStyle: overlay.italic
// //                           ? FontStyle.italic
// //                           : FontStyle.normal,
// //                       shadows: const [
// //                         Shadow(
// //                           blurRadius: 4,
// //                           color: Colors.black,
// //                           offset: Offset(2, 2),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               ))
// //                   .toList(),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }
// // }
// //
// // class _StickerOverlaysLayer extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return BlocBuilder<VideoEditorBloc, VideoEditorState>(
// //       builder: (context, state) {
// //         if (state is! VideoEditorLoaded || state.selectedClip == null) {
// //           return const SizedBox();
// //         }
// //
// //         final clip = state.selectedClip!;
// //         final currentPos = state.currentPositionMs - clip.startMs;
// //
// //         return LayoutBuilder(
// //           builder: (context, constraints) {
// //             final width = constraints.maxWidth;
// //             final height = constraints.maxHeight;
// //
// //             return Stack(
// //               children: clip.stickerOverlays
// //                   .where((sticker) =>
// //               currentPos >= sticker.startMs &&
// //                   currentPos <= sticker.startMs + sticker.durationMs)
// //                   .map((sticker) => Positioned(
// //                 left: sticker.x * width - 50 * sticker.scale,
// //                 top: sticker.y * height - 50 * sticker.scale,
// //                 child: Transform.rotate(
// //                   angle: sticker.rotation,
// //                   child: GestureDetector(
// //                     onScaleUpdate: (details) {
// //                       final stickerIndex =
// //                       clip.stickerOverlays.indexOf(sticker);
// //                       context.read<VideoEditorBloc>().add(
// //                         UpdateStickerOverlayEvent(
// //                           clipIndex: state.selectedClipIndex!,
// //                           overlayIndex: stickerIndex,
// //                           scale: (sticker.scale * details.scale)
// //                               .clamp(0.5, 3.0),
// //                           rotation: sticker.rotation + details.rotation,
// //                         ),
// //                       );
// //                     },
// //                     onPanUpdate: (details) {
// //                       final newX =
// //                       (sticker.x + details.delta.dx / width)
// //                           .clamp(0.0, 1.0);
// //                       final newY =
// //                       (sticker.y + details.delta.dy / height)
// //                           .clamp(0.0, 1.0);
// //
// //                       final stickerIndex =
// //                       clip.stickerOverlays.indexOf(sticker);
// //                       context.read<VideoEditorBloc>().add(
// //                         UpdateStickerOverlayEvent(
// //                           clipIndex: state.selectedClipIndex!,
// //                           overlayIndex: stickerIndex,
// //                           x: newX,
// //                           y: newY,
// //                         ),
// //                       );
// //                     },
// //                     child: Container(
// //                       width: 100 * sticker.scale,
// //                       height: 100 * sticker.scale,
// //                       decoration: BoxDecoration(
// //                         border: Border.all(color: Colors.white24),
// //                         image: DecorationImage(
// //                           image: AssetImage(sticker.assetPath),
// //                           fit: BoxFit.contain,
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ))
// //                   .toList(),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }
// // }
// //
// // // ==================== TIMELINE AREA ====================
// //
// // class _TimelineArea extends StatelessWidget {
// //   const _TimelineArea({Key? key}) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       height: 220,
// //       color: const Color(0xFF1C1C1E),
// //       child: Column(
// //         children: const [
// //           _PlaybackControls(),
// //           Divider(height: 1, thickness: 1, color: Color(0xFF2C2C2E)),
// //           Expanded(child: _Timeline()),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _PlaybackControls extends StatelessWidget {
// //   const _PlaybackControls({Key? key}) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       height: 60,
// //       padding: const EdgeInsets.symmetric(horizontal: 12),
// //       child: Row(
// //         children: [
// //           // Timecode
// //           SizedBox(
// //             width: 70,
// //             child: BlocBuilder<VideoEditorBloc, VideoEditorState>(
// //               builder: (context, state) {
// //                 final currentMs = state is VideoEditorLoaded
// //                     ? state.currentPositionMs
// //                     : 0.0;
// //                 return Text(
// //                   _formatTime(currentMs / 1000),
// //                   style: const TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 13,
// //                     fontFamily: 'monospace',
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //
// //           // Zoom controls
// //           IconButton(
// //             icon: const Icon(Icons.remove, color: Colors.white, size: 20),
// //             onPressed: () => context.read<VideoEditorBloc>().add(
// //               const ZoomTimelineEvent(zoomIn: false),
// //             ),
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.add, color: Colors.white, size: 20),
// //             onPressed: () => context.read<VideoEditorBloc>().add(
// //               const ZoomTimelineEvent(zoomIn: true),
// //             ),
// //           ),
// //
// //           // Playback slider
// //           Expanded(
// //             child: BlocBuilder<VideoEditorBloc, VideoEditorState>(
// //               builder: (context, state) {
// //                 if (state is! VideoEditorLoaded) {
// //                   return Slider(
// //                     value: 0,
// //                     max: 1,
// //                     onChanged: null,
// //                     activeColor: const Color(0xFF0A84FF),
// //                   );
// //                 }
// //
// //                 final totalDuration = state.totalDurationMs / 1000;
// //                 final currentTime =
// //                 (state.currentPositionMs / 1000).clamp(0.0, totalDuration);
// //
// //                 return SliderTheme(
// //                   data: const SliderThemeData(
// //                     trackHeight: 4,
// //                     thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
// //                   ),
// //                   child: Slider(
// //                     value: currentTime,
// //                     max: totalDuration > 0 ? totalDuration : 1,
// //                     activeColor: const Color(0xFF0A84FF),
// //                     inactiveColor: const Color(0xFF3A3A3C),
// //                     onChanged: (value) {
// //                       context.read<VideoEditorBloc>().add(
// //                         SeekToPositionEvent(value * 1000),
// //                       );
// //                     },
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //
// //           // Play/Pause button
// //           BlocBuilder<VideoEditorBloc, VideoEditorState>(
// //             builder: (context, state) {
// //               final isPlaying =
// //               state is VideoEditorLoaded ? state.isPlaying : false;
// //
// //               return Container(
// //                 decoration: BoxDecoration(
// //                   color: const Color(0xFF0A84FF),
// //                   borderRadius: BorderRadius.circular(20),
// //                 ),
// //                 child: IconButton(
// //                   icon: Icon(
// //                     isPlaying ? Icons.pause : Icons.play_arrow,
// //                     color: Colors.white,
// //                   ),
// //                   onPressed: () =>
// //                       context.read<VideoEditorBloc>().add(TogglePlayPauseEvent()),
// //                 ),
// //               );
// //             },
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   String _formatTime(double seconds) {
// //     final m = (seconds / 60).floor().toString().padLeft(2, '0');
// //     final s = (seconds % 60).floor().toString().padLeft(2, '0');
// //     final ms = ((seconds % 1) * 100).floor().toString().padLeft(2, '0');
// //     return '$m:$s.$ms';
// //   }
// // }
// //
// // // Import _Timeline and _BottomToolbar from timeline_toolbar.dart
// // // Or include them here - see the timeline_and_toolbar artifact
// //
// //
// // class _Timeline extends StatelessWidget {
// //   const _Timeline({Key? key}) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return BlocBuilder<VideoEditorBloc, VideoEditorState>(
// //       builder: (context, state) {
// //         if (state is! VideoEditorLoaded) {
// //           return _EmptyTimeline();
// //         }
// //
// //         if (state.clips.isEmpty) {
// //           return _EmptyTimeline();
// //         }
// //
// //         final totalDuration = state.totalDurationMs;
// //         final pixelsPerSecond = state.pixelsPerSecond;
// //
// //         return LayoutBuilder(
// //           builder: (context, constraints) {
// //             final playheadPos = (state.currentPositionMs / totalDuration)
// //                 .clamp(0.0, 1.0);
// //             final playheadLeft = playheadPos * constraints.maxWidth;
// //
// //             return Stack(
// //               children: [
// //                 SingleChildScrollView(
// //                   scrollDirection: Axis.horizontal,
// //                   child: SizedBox(
// //                     width: totalDuration * pixelsPerSecond / 1000,
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         _TimeRuler(
// //                           totalDuration: totalDuration,
// //                           pixelsPerSecond: pixelsPerSecond,
// //                         ),
// //                         const SizedBox(height: 4),
// //                         _VideoTrack(),
// //                         const SizedBox(height: 4),
// //                         _AudioTrack(),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //                 // Playhead
// //                 Positioned(
// //                   left: playheadLeft - 1,
// //                   top: 0,
// //                   bottom: 0,
// //                   child: Container(
// //                     width: 2,
// //                     color: const Color(0xFF0A84FF),
// //                     child: Column(
// //                       children: [
// //                         Container(
// //                           width: 12,
// //                           height: 12,
// //                           decoration: const BoxDecoration(
// //                             color: Color(0xFF0A84FF),
// //                             shape: BoxShape.circle,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }
// // }
// //
// // class _EmptyTimeline extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Center(
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           const Icon(Icons.video_library, color: Colors.grey, size: 48),
// //           const SizedBox(height: 12),
// //           ElevatedButton.icon(
// //             onPressed: () async {
// //               final result = await FilePicker.platform.pickFiles(
// //                 type: FileType.video,
// //               );
// //
// //               if (result != null && result.files.single.path != null) {
// //                 final file = File(result.files.single.path!);
// //                 context.read<VideoEditorBloc>().add(LoadVideoEvent(file));
// //               }
// //             },
// //             icon: const Icon(Icons.add),
// //             label: const Text('Add Video'),
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: const Color(0xFF0A84FF),
// //               foregroundColor: Colors.white,
// //               padding: const EdgeInsets.symmetric(
// //                 horizontal: 24,
// //                 vertical: 12,
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _TimeRuler extends StatelessWidget {
// //   final double totalDuration;
// //   final double pixelsPerSecond;
// //
// //   const _TimeRuler({
// //     Key? key,
// //     required this.totalDuration,
// //     required this.pixelsPerSecond,
// //   }) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final seconds = (totalDuration / 1000).ceil();
// //
// //     return Container(
// //       height: 24,
// //       color: const Color(0xFF2C2C2E),
// //       child: Row(
// //         children: List.generate(
// //           seconds + 1,
// //               (i) => Container(
// //             width: pixelsPerSecond,
// //             padding: const EdgeInsets.only(left: 4),
// //             child: Text(
// //               '${i}s',
// //               style: const TextStyle(color: Colors.white60, fontSize: 10),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class _VideoTrack extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return BlocBuilder<VideoEditorBloc, VideoEditorState>(
// //       builder: (context, state) {
// //         if (state is! VideoEditorLoaded) return const SizedBox();
// //
// //         double cumulativeStart = 0;
// //
// //         return Container(
// //           height: 70,
// //           decoration: BoxDecoration(
// //             color: const Color(0xFF2C2C2E),
// //             borderRadius: BorderRadius.circular(4),
// //           ),
// //           child: Stack(
// //             children: [
// //               ...state.clips.asMap().entries.map((entry) {
// //                 final index = entry.key;
// //                 final clip = entry.value;
// //                 final isSelected = state.selectedClipIndex == index;
// //                 final duration = clip.durationMs;
// //                 final width = duration * state.pixelsPerSecond / 1000;
// //
// //                 final left = cumulativeStart;
// //                 cumulativeStart += width;
// //
// //                 return Positioned(
// //                   left: left,
// //                   top: 4,
// //                   child: GestureDetector(
// //                     onTap: () {
// //                       context
// //                           .read<VideoEditorBloc>()
// //                           .add(SelectClipEvent(index));
// //                     },
// //                     onLongPress: () => _showClipOptions(context, index),
// //                     child: Container(
// //                       width: width.clamp(60.0, double.infinity),
// //                       height: 62,
// //                       margin: const EdgeInsets.only(right: 2),
// //                       decoration: BoxDecoration(
// //                         color: isSelected
// //                             ? const Color(0xFF0A84FF)
// //                             : const Color(0xFF3A3A3C),
// //                         borderRadius: BorderRadius.circular(6),
// //                         border: Border.all(
// //                           color: isSelected
// //                               ? const Color(0xFF0A84FF)
// //                               : const Color(0xFF48484A),
// //                           width: isSelected ? 3 : 1,
// //                         ),
// //                         boxShadow: isSelected
// //                             ? [
// //                           BoxShadow(
// //                             color: const Color(0xFF0A84FF)
// //                                 .withOpacity(0.5),
// //                             blurRadius: 8,
// //                             spreadRadius: 2,
// //                           ),
// //                         ]
// //                             : null,
// //                       ),
// //                       child: ClipRRect(
// //                         borderRadius: BorderRadius.circular(4),
// //                         child: clip.thumbnails.isNotEmpty
// //                             ? Row(
// //                           children: clip.thumbnails
// //                               .take(6)
// //                               .map((thumb) => Expanded(
// //                             child: Image.file(
// //                               File(thumb),
// //                               fit: BoxFit.cover,
// //                             ),
// //                           ))
// //                               .toList(),
// //                         )
// //                             : const Center(
// //                           child: Icon(
// //                             Icons.videocam,
// //                             color: Colors.white70,
// //                             size: 32,
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               }).toList(),
// //               // Add video button
// //               Positioned(
// //                 left: cumulativeStart + 8,
// //                 top: 4,
// //                 child: GestureDetector(
// //                   onTap: () async {
// //                     final result = await FilePicker.platform.pickFiles(
// //                       type: FileType.video,
// //                     );
// //
// //                     if (result != null && result.files.single.path != null) {
// //                       final file = File(result.files.single.path!);
// //                       context
// //                           .read<VideoEditorBloc>()
// //                           .add(AddVideoClipEvent(file));
// //                     }
// //                   },
// //                   child: Container(
// //                     width: 62,
// //                     height: 62,
// //                     decoration: BoxDecoration(
// //                       color: const Color(0xFF0A84FF),
// //                       borderRadius: BorderRadius.circular(6),
// //                     ),
// //                     child:
// //                     const Icon(Icons.add, color: Colors.white, size: 32),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// //
// //   void _showClipOptions(BuildContext context, int index) {
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: const Color(0xFF1C1C1E),
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (context) => Padding(
// //         padding: const EdgeInsets.all(20),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             ListTile(
// //               leading: const Icon(Icons.content_cut, color: Color(0xFF0A84FF)),
// //               title: const Text('Split', style: TextStyle(color: Colors.white)),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 final bloc = context.read<VideoEditorBloc>();
// //                 if (bloc.state is VideoEditorLoaded) {
// //                   bloc.add(SplitClipEvent(
// //                     index,
// //                     (bloc.state as VideoEditorLoaded).currentPositionMs,
// //                   ));
// //                 }
// //               },
// //             ),
// //             ListTile(
// //               leading:
// //               const Icon(Icons.content_copy, color: Color(0xFF0A84FF)),
// //               title: const Text('Duplicate',
// //                   style: TextStyle(color: Colors.white)),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 context.read<VideoEditorBloc>().add(DuplicateClipEvent(index));
// //               },
// //             ),
// //             ListTile(
// //               leading: const Icon(Icons.delete, color: Colors.red),
// //               title:
// //               const Text('Delete', style: TextStyle(color: Colors.red)),
// //               onTap: () {
// //                 Navigator.pop(context);
// //                 context.read<VideoEditorBloc>().add(RemoveClipEvent(index));
// //               },
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class _AudioTrack extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return BlocBuilder<VideoEditorBloc, VideoEditorState>(
// //       builder: (context, state) {
// //         if (state is! VideoEditorLoaded) return const SizedBox();
// //
// //         if (state.backgroundMusic == null && state.voiceOvers.isEmpty) {
// //           return Container(
// //             height: 40,
// //             decoration: BoxDecoration(
// //               color: const Color(0xFF2C2C2E),
// //               borderRadius: BorderRadius.circular(4),
// //             ),
// //             child: Center(
// //               child: TextButton.icon(
// //                 onPressed: () async {
// //                   final result = await FilePicker.platform.pickFiles(
// //                     type: FileType.audio,
// //                   );
// //
// //                   if (result != null && result.files.single.path != null) {
// //                     final file = File(result.files.single.path!);
// //                     context
// //                         .read<VideoEditorBloc>()
// //                         .add(AddBackgroundMusicEvent(file));
// //                   }
// //                 },
// //                 icon: const Icon(Icons.music_note, color: Colors.white60),
// //                 label: const Text(
// //                   'Add Audio',
// //                   style: TextStyle(color: Colors.white60, fontSize: 12),
// //                 ),
// //               ),
// //             ),
// //           );
// //         }
// //
// //         return Container(
// //           height: 40,
// //           decoration: BoxDecoration(
// //             color: const Color(0xFF2C2C2E),
// //             borderRadius: BorderRadius.circular(4),
// //           ),
// //           child: Stack(
// //             children: [
// //               if (state.backgroundMusic != null)
// //                 Positioned(
// //                   left: 4,
// //                   top: 4,
// //                   bottom: 4,
// //                   width: 100,
// //                   child: Container(
// //                     decoration: BoxDecoration(
// //                       color: const Color(0xFF30D158),
// //                       borderRadius: BorderRadius.circular(4),
// //                     ),
// //                     child: const Center(
// //                       child: Row(
// //                         mainAxisSize: MainAxisSize.min,
// //                         children: [
// //                           Icon(Icons.music_note,
// //                               color: Colors.white, size: 16),
// //                           SizedBox(width: 4),
// //                           Text(
// //                             'Music',
// //                             style: TextStyle(color: Colors.white, fontSize: 10),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// // }
// //
// // // ==================== BOTTOM TOOLBAR ====================
// //
// // class _BottomToolbar extends StatelessWidget {
// //   const _BottomToolbar({Key? key}) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final tabs = [
// //       {'icon': Icons.content_cut, 'label': 'Edit', 'index': 0},
// //       {'icon': Icons.music_note, 'label': 'Audio', 'index': 1},
// //       {'icon': Icons.text_fields, 'label': 'Text', 'index': 2},
// //       {'icon': Icons.emoji_emotions, 'label': 'Sticker', 'index': 3},
// //       {'icon': Icons.auto_awesome, 'label': 'Effect', 'index': 4},
// //       {'icon': Icons.picture_in_picture, 'label': 'PIP', 'index': 5},
// //     ];
// //
// //     return Container(
// //       height: 180,
// //       decoration: const BoxDecoration(
// //         color: Color(0xFF1C1C1E),
// //         border: Border(top: BorderSide(color: Color(0xFF2C2C2E), width: 1)),
// //       ),
// //       child: Column(
// //         children: [
// //           // Tab Bar
// //           Container(
// //             height: 60,
// //             padding: const EdgeInsets.symmetric(horizontal: 4),
// //             child: BlocBuilder<VideoEditorBloc, VideoEditorState>(
// //               builder: (context, state) {
// //                 final selectedTab = state is VideoEditorLoaded
// //                     ? state.selectedToolTab
// //                     : 0;
// //
// //                 return Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceAround,
// //                   children: tabs.map((tab) {
// //                     final isSelected = selectedTab == tab['index'] as int;
// //                     return Expanded(
// //                       child: GestureDetector(
// //                         onTap: () {
// //                           context.read<VideoEditorBloc>().add(
// //                             ChangeToolTabEvent(tab['index'] as int),
// //                           );
// //                         },
// //                         child: Container(
// //                           decoration: BoxDecoration(
// //                             border: Border(
// //                               bottom: BorderSide(
// //                                 color: isSelected
// //                                     ? const Color(0xFF0A84FF)
// //                                     : Colors.transparent,
// //                                 width: 2,
// //                               ),
// //                             ),
// //                           ),
// //                           child: Column(
// //                             mainAxisAlignment: MainAxisAlignment.center,
// //                             children: [
// //                               Icon(
// //                                 tab['icon'] as IconData,
// //                                 color: isSelected
// //                                     ? const Color(0xFF0A84FF)
// //                                     : Colors.white60,
// //                                 size: 24,
// //                               ),
// //                               const SizedBox(height: 4),
// //                               Text(
// //                                 tab['label'] as String,
// //                                 style: TextStyle(
// //                                   color: isSelected
// //                                       ? const Color(0xFF0A84FF)
// //                                       : Colors.white60,
// //                                   fontSize: 11,
// //                                   fontWeight: isSelected
// //                                       ? FontWeight.w600
// //                                       : FontWeight.normal,
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ),
// //                     );
// //                   }).toList(),
// //                 );
// //               },
// //             ),
// //           ),
// //           // Tab Content
// //           Expanded(
// //             child: BlocBuilder<VideoEditorBloc, VideoEditorState>(
// //               builder: (context, state) {
// //                 final selectedTab = state is VideoEditorLoaded
// //                     ? state.selectedToolTab
// //                     : 0;
// //
// //                 switch (selectedTab) {
// //                   case 0:
// //                     return _EditTab();
// //                   case 1:
// //                     return _AudioTab();
// //                   case 2:
// //                     return _TextTab();
// //                   case 3:
// //                     return _StickerTab();
// //                   case 4:
// //                     return _EffectTab();
// //                   case 5:
// //                     return _PIPTab();
// //                   default:
// //                     return _EditTab();
// //                 }
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // // ==================== EDIT TAB ====================
// //
// // class _EditTab extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     final tools = [
// //       {
// //         'icon': Icons.content_cut,
// //         'label': 'Split',
// //         'onTap': () {
// //           final bloc = context.read<VideoEditorBloc>();
// //           if (bloc.state is VideoEditorLoaded) {
// //             final state = bloc.state as VideoEditorLoaded;
// //             if (state.selectedClipIndex != null) {
// //               bloc.add(SplitClipEvent(
// //                 state.selectedClipIndex!,
// //                 state.currentPositionMs,
// //               ));
// //             }
// //           }
// //         }
// //       },
// //       {
// //         'icon': Icons.crop,
// //         'label': 'Trim',
// //         'onTap': () => _showTrimDialog(context)
// //       },
// //       {
// //         'icon': Icons.delete,
// //         'label': 'Delete',
// //         'onTap': () {
// //           final bloc = context.read<VideoEditorBloc>();
// //           if (bloc.state is VideoEditorLoaded) {
// //             final state = bloc.state as VideoEditorLoaded;
// //             if (state.selectedClipIndex != null) {
// //               bloc.add(RemoveClipEvent(state.selectedClipIndex!));
// //             }
// //           }
// //         }
// //       },
// //       {
// //         'icon': Icons.speed,
// //         'label': 'Speed',
// //         'onTap': () => _showSpeedDialog(context)
// //       },
// //       {
// //         'icon': Icons.volume_up,
// //         'label': 'Volume',
// //         'onTap': () => _showVolumeDialog(context)
// //       },
// //       {
// //         'icon': Icons.flip,
// //         'label': 'Flip',
// //         'onTap': () {
// //           final bloc = context.read<VideoEditorBloc>();
// //           if (bloc.state is VideoEditorLoaded) {
// //             final state = bloc.state as VideoEditorLoaded;
// //             if (state.selectedClipIndex != null) {
// //               bloc.add(FlipClipEvent(state.selectedClipIndex!));
// //             }
// //           }
// //         }
// //       },
// //       {
// //         'icon': Icons.content_copy,
// //         'label': 'Duplicate',
// //         'onTap': () {
// //           final bloc = context.read<VideoEditorBloc>();
// //           if (bloc.state is VideoEditorLoaded) {
// //             final state = bloc.state as VideoEditorLoaded;
// //             if (state.selectedClipIndex != null) {
// //               bloc.add(DuplicateClipEvent(state.selectedClipIndex!));
// //             }
// //           }
// //         }
// //       },
// //       {
// //         'icon': Icons.rotate_90_degrees_ccw,
// //         'label': 'Rotate',
// //         'onTap': () {
// //           final bloc = context.read<VideoEditorBloc>();
// //           if (bloc.state is VideoEditorLoaded) {
// //             final state = bloc.state as VideoEditorLoaded;
// //             if (state.selectedClipIndex != null) {
// //               bloc.add(RotateClipEvent(state.selectedClipIndex!, 90));
// //             }
// //           }
// //         }
// //       },
// //       {
// //         'icon': Icons.swap_horiz,
// //         'label': 'Transition',
// //         'onTap': () => _showTransitionDialog(context)
// //       },
// //     ];
// //
// //     return GridView.builder(
// //       padding: const EdgeInsets.all(12),
// //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //         crossAxisCount: 4,
// //         childAspectRatio: 1.2,
// //         crossAxisSpacing: 8,
// //         mainAxisSpacing: 8,
// //       ),
// //       itemCount: tools.length,
// //       itemBuilder: (context, index) {
// //         final tool = tools[index];
// //         return _ToolButton(
// //           icon: tool['icon'] as IconData,
// //           label: tool['label'] as String,
// //           onTap: tool['onTap'] as VoidCallback,
// //         );
// //       },
// //     );
// //   }
// //
// //   void _showTrimDialog(BuildContext context) {
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: const Color(0xFF1C1C1E),
// //       builder: (context) => Container(
// //         padding: const EdgeInsets.all(20),
// //         child: const Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Text(
// //               'Trim Video',
// //               style: TextStyle(
// //                 color: Colors.white,
// //                 fontSize: 18,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             SizedBox(height: 20),
// //             Text(
// //               'Use the timeline to adjust trim points',
// //               style: TextStyle(color: Colors.white60),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _showSpeedDialog(BuildContext context) {
// //     double speed = 1.0;
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: const Color(0xFF1C1C1E),
// //       builder: (context) => StatefulBuilder(
// //         builder: (context, setState) => Container(
// //           height: 250,
// //           padding: const EdgeInsets.all(20),
// //           child: Column(
// //             children: [
// //               const Text(
// //                 'Playback Speed',
// //                 style: TextStyle(
// //                   color: Colors.white,
// //                   fontSize: 18,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               const SizedBox(height: 20),
// //               Text(
// //                 '${speed.toStringAsFixed(2)}x',
// //                 style: const TextStyle(
// //                   color: Color(0xFF0A84FF),
// //                   fontSize: 32,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               const SizedBox(height: 20),
// //               Slider(
// //                 value: speed,
// //                 min: 0.25,
// //                 max: 4.0,
// //                 divisions: 15,
// //                 activeColor: const Color(0xFF0A84FF),
// //                 onChanged: (value) {
// //                   setState(() => speed = value);
// //                 },
// //                 onChangeEnd: (value) {
// //                   final bloc = context.read<VideoEditorBloc>();
// //                   if (bloc.state is VideoEditorLoaded) {
// //                     final state = bloc.state as VideoEditorLoaded;
// //                     if (state.selectedClipIndex != null) {
// //                       bloc.add(SetClipSpeedEvent(
// //                         state.selectedClipIndex!,
// //                         value,
// //                       ));
// //                     }
// //                   }
// //                 },
// //               ),
// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: const [
// //                   Text('0.25x', style: TextStyle(color: Colors.white60)),
// //                   Text('4.0x', style: TextStyle(color: Colors.white60)),
// //                 ],
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _showVolumeDialog(BuildContext context) {
// //     double volume = 1.0;
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: const Color(0xFF1C1C1E),
// //       builder: (context) => StatefulBuilder(
// //         builder: (context, setState) => Container(
// //           height: 250,
// //           padding: const EdgeInsets.all(20),
// //           child: Column(
// //             children: [
// //               const Text(
// //                 'Volume',
// //                 style: TextStyle(
// //                   color: Colors.white,
// //                   fontSize: 18,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               const SizedBox(height: 20),
// //               Text(
// //                 '${(volume * 100).toInt()}%',
// //                 style: const TextStyle(
// //                   color: Color(0xFF0A84FF),
// //                   fontSize: 32,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               const SizedBox(height: 20),
// //               Slider(
// //                 value: volume,
// //                 min: 0.0,
// //                 max: 2.0,
// //                 divisions: 20,
// //                 activeColor: const Color(0xFF0A84FF),
// //                 onChanged: (value) {
// //                   setState(() => volume = value);
// //                 },
// //                 onChangeEnd: (value) {
// //                   final bloc = context.read<VideoEditorBloc>();
// //                   if (bloc.state is VideoEditorLoaded) {
// //                     final state = bloc.state as VideoEditorLoaded;
// //                     if (state.selectedClipIndex != null) {
// //                       bloc.add(SetClipVolumeEvent(
// //                         state.selectedClipIndex!,
// //                         value,
// //                       ));
// //                     }
// //                   }
// //                 },
// //               ),
// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: const [
// //                   Text('0%', style: TextStyle(color: Colors.white60)),
// //                   Text('200%', style: TextStyle(color: Colors.white60)),
// //                 ],
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   void _showTransitionDialog(BuildContext context) {
// //     final transitions = [
// //       {'name': 'None', 'icon': Icons.close},
// //       {'name': 'Fade', 'icon': Icons.gradient},
// //       {'name': 'Slide', 'icon': Icons.swap_horiz},
// //       {'name': 'Zoom', 'icon': Icons.zoom_in},
// //       {'name': 'Wipe', 'icon': Icons.swipe},
// //       {'name': 'Dissolve', 'icon': Icons.blur_on},
// //     ];
// //
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: const Color(0xFF1C1C1E),
// //       builder: (context) => Container(
// //         padding: const EdgeInsets.all(20),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             const Text(
// //               'Transition',
// //               style: TextStyle(
// //                 color: Colors.white,
// //                 fontSize: 18,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             const SizedBox(height: 20),
// //             ...transitions.map((transition) => ListTile(
// //               leading: Icon(
// //                 transition['icon'] as IconData,
// //                 color: const Color(0xFF0A84FF),
// //               ),
// //               title: Text(
// //                 transition['name'] as String,
// //                 style: const TextStyle(color: Colors.white),
// //               ),
// //               onTap: () {
// //                 final bloc = context.read<VideoEditorBloc>();
// //                 if (bloc.state is VideoEditorLoaded) {
// //                   final state = bloc.state as VideoEditorLoaded;
// //                   if (state.selectedClipIndex != null) {
// //                     bloc.add(SetTransitionEvent(
// //                       state.selectedClipIndex!,
// //                       (transition['name'] as String).toLowerCase(),
// //                       0.5,
// //                     ));
// //                   }
// //                 }
// //                 Navigator.pop(context);
// //               },
// //             )),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class _ToolButton extends StatelessWidget {
// //   final IconData icon;
// //   final String label;
// //   final VoidCallback onTap;
// //
// //   const _ToolButton({
// //     Key? key,
// //     required this.icon,
// //     required this.label,
// //     required this.onTap,
// //   }) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         decoration: BoxDecoration(
// //           color: const Color(0xFF2C2C2E),
// //           borderRadius: BorderRadius.circular(8),
// //         ),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(icon, color: Colors.white, size: 28),
// //             const SizedBox(height: 6),
// //             Text(
// //               label,
// //               style: const TextStyle(color: Colors.white, fontSize: 11),
// //               textAlign: TextAlign.center,
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // ==================== AUDIO TAB ====================
// //
// // class _AudioTab extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return ListView(
// //       padding: const EdgeInsets.all(12),
// //       children: [
// //         _AudioOption(
// //           icon: Icons.music_note,
// //           title: 'Background Music',
// //           subtitle: 'Add music to your video',
// //           onTap: () async {
// //             final result = await FilePicker.platform.pickFiles(
// //               type: FileType.audio,
// //             );
// //
// //             if (result != null && result.files.single.path != null) {
// //               final file = File(result.files.single.path!);
// //               context
// //                   .read<VideoEditorBloc>()
// //                   .add(AddBackgroundMusicEvent(file));
// //             }
// //           },
// //         ),
// //         _AudioOption(
// //           icon: Icons.mic,
// //           title: 'Voice Over',
// //           subtitle: 'Record voice narration',
// //           onTap: () {
// //             context.read<VideoEditorBloc>().add(StartVoiceRecordingEvent());
// //
// //             showDialog(
// //               context: context,
// //               barrierDismissible: false,
// //               builder: (context) => AlertDialog(
// //                 backgroundColor: const Color(0xFF1C1C1E),
// //                 title: const Text(
// //                   'Recording...',
// //                   style: TextStyle(color: Colors.white),
// //                 ),
// //                 content: const Column(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     Icon(Icons.mic, color: Color(0xFF0A84FF), size: 64),
// //                     SizedBox(height: 16),
// //                     Text(
// //                       'Tap stop when finished',
// //                       style: TextStyle(color: Colors.white60),
// //                     ),
// //                   ],
// //                 ),
// //                 actions: [
// //                   TextButton(
// //                     onPressed: () {
// //                       context
// //                           .read<VideoEditorBloc>()
// //                           .add(StopVoiceRecordingEvent());
// //                       Navigator.pop(context);
// //                     },
// //                     child: const Text(
// //                       'Stop',
// //                       style: TextStyle(color: Color(0xFF0A84FF)),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             );
// //           },
// //         ),
// //         _AudioOption(
// //           icon: Icons.record_voice_over,
// //           title: 'Text to Speech',
// //           subtitle: 'Convert text to voice',
// //           onTap: () => _showTTSDialog(context),
// //         ),
// //         _AudioOption(
// //           icon: Icons.graphic_eq,
// //           title: 'Audio Effects',
// //           subtitle: 'Apply audio filters',
// //           onTap: () {
// //             ScaffoldMessenger.of(context).showSnackBar(
// //               const SnackBar(content: Text('Coming Soon: Audio Effects')),
// //             );
// //           },
// //         ),
// //       ],
// //     );
// //   }
// //
// //   void _showTTSDialog(BuildContext context) {
// //     final textController = TextEditingController();
// //
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         backgroundColor: const Color(0xFF1C1C1E),
// //         title: const Text(
// //           'Text to Speech',
// //           style: TextStyle(color: Colors.white),
// //         ),
// //         content: TextField(
// //           controller: textController,
// //           style: const TextStyle(color: Colors.white),
// //           maxLines: 4,
// //           decoration: InputDecoration(
// //             hintText: 'Enter text to convert to speech',
// //             hintStyle: const TextStyle(color: Colors.white60),
// //             filled: true,
// //             fillColor: const Color(0xFF2C2C2E),
// //             border: OutlineInputBorder(
// //               borderRadius: BorderRadius.circular(8),
// //               borderSide: BorderSide.none,
// //             ),
// //           ),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: const Text('Cancel'),
// //           ),
// //           ElevatedButton(
// //             onPressed: () {
// //               if (textController.text.isNotEmpty) {
// //                 context.read<VideoEditorBloc>().add(
// //                   GenerateTTSEvent(textController.text),
// //                 );
// //                 Navigator.pop(context);
// //               }
// //             },
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: const Color(0xFF0A84FF),
// //               foregroundColor: Colors.white,
// //             ),
// //             child: const Text('Generate'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _AudioOption extends StatelessWidget {
// //   final IconData icon;
// //   final String title;
// //   final String subtitle;
// //   final VoidCallback onTap;
// //
// //   const _AudioOption({
// //     Key? key,
// //     required this.icon,
// //     required this.title,
// //     required this.subtitle,
// //     required this.onTap,
// //   }) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Card(
// //       color: const Color(0xFF2C2C2E),
// //       margin: const EdgeInsets.only(bottom: 8),
// //       child: ListTile(
// //         leading: Container(
// //           padding: const EdgeInsets.all(8),
// //           decoration: BoxDecoration(
// //             color: const Color(0xFF0A84FF).withOpacity(0.2),
// //             borderRadius: BorderRadius.circular(8),
// //           ),
// //           child: Icon(icon, color: const Color(0xFF0A84FF)),
// //         ),
// //         title: Text(title, style: const TextStyle(color: Colors.white)),
// //         subtitle: Text(
// //           subtitle,
// //           style: const TextStyle(color: Colors.white60, fontSize: 12),
// //         ),
// //         trailing: const Icon(Icons.chevron_right, color: Colors.white60),
// //         onTap: onTap,
// //       ),
// //     );
// //   }
// // }
// //
// // // ==================== TEXT TAB ====================
// //
// // class _TextTab extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Column(
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.all(12),
// //           child: ElevatedButton.icon(
// //             onPressed: () => _showAddTextDialog(context),
// //             icon: const Icon(Icons.add),
// //             label: const Text('Add Text'),
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: const Color(0xFF0A84FF),
// //               foregroundColor: Colors.white,
// //               minimumSize: const Size(double.infinity, 44),
// //             ),
// //           ),
// //         ),
// //         Expanded(
// //           child: GridView.builder(
// //             padding: const EdgeInsets.symmetric(horizontal: 12),
// //             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //               crossAxisCount: 3,
// //               childAspectRatio: 1.2,
// //               crossAxisSpacing: 8,
// //               mainAxisSpacing: 8,
// //             ),
// //             itemCount: 9,
// //             itemBuilder: (context, index) {
// //               final styles = [
// //                 'Default',
// //                 'Bold',
// //                 'Italic',
// //                 'Outline',
// //                 'Shadow',
// //                 'Neon',
// //                 '3D',
// //                 'Typewriter',
// //                 'Glitch',
// //               ];
// //               return _ToolButton(
// //                 icon: Icons.text_fields,
// //                 label: styles[index],
// //                 onTap: () {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(content: Text('${styles[index]} style applied')),
// //                   );
// //                 },
// //               );
// //             },
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   void _showAddTextDialog(BuildContext context) {
// //     final textController = TextEditingController();
// //     double fontSize = 32;
// //     Color textColor = Colors.white;
// //
// //     showDialog(
// //       context: context,
// //       builder: (dialogContext) => StatefulBuilder(
// //         builder: (context, setState) => AlertDialog(
// //           backgroundColor: const Color(0xFF1C1C1E),
// //           title: const Text(
// //             'Add Text',
// //             style: TextStyle(color: Colors.white),
// //           ),
// //           content: SingleChildScrollView(
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 TextField(
// //                   controller: textController,
// //                   style: const TextStyle(color: Colors.white),
// //                   maxLines: 3,
// //                   decoration: InputDecoration(
// //                     hintText: 'Enter your text',
// //                     hintStyle: const TextStyle(color: Colors.white60),
// //                     filled: true,
// //                     fillColor: const Color(0xFF2C2C2E),
// //                     border: OutlineInputBorder(
// //                       borderRadius: BorderRadius.circular(8),
// //                       borderSide: BorderSide.none,
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 20),
// //                 Row(
// //                   children: [
// //                     const Text(
// //                       'Size: ',
// //                       style: TextStyle(color: Colors.white),
// //                     ),
// //                     Expanded(
// //                       child: Slider(
// //                         min: 16,
// //                         max: 72,
// //                         value: fontSize,
// //                         activeColor: const Color(0xFF0A84FF),
// //                         onChanged: (value) => setState(() => fontSize = value),
// //                       ),
// //                     ),
// //                     Text(
// //                       '${fontSize.toInt()}',
// //                       style: const TextStyle(color: Colors.white),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 12),
// //                 Row(
// //                   children: [
// //                     const Text(
// //                       'Color: ',
// //                       style: TextStyle(color: Colors.white),
// //                     ),
// //                     const SizedBox(width: 12),
// //                     GestureDetector(
// //                       onTap: () async {
// //                         final color = await showDialog<Color>(
// //                           context: dialogContext,
// //                           builder: (context) => AlertDialog(
// //                             backgroundColor: const Color(0xFF1C1C1E),
// //                             title: const Text(
// //                               'Pick Color',
// //                               style: TextStyle(color: Colors.white),
// //                             ),
// //                             content: SingleChildScrollView(
// //                               child: BlockPicker(
// //                                 pickerColor: textColor,
// //                                 onColorChanged: (c) =>
// //                                     Navigator.pop(context, c),
// //                               ),
// //                             ),
// //                           ),
// //                         );
// //                         if (color != null) {
// //                           setState(() => textColor = color);
// //                         }
// //                       },
// //                       child: Container(
// //                         width: 40,
// //                         height: 40,
// //                         decoration: BoxDecoration(
// //                           color: textColor,
// //                           borderRadius: BorderRadius.circular(8),
// //                           border: Border.all(color: Colors.white24),
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.pop(context),
// //               child: const Text('Cancel'),
// //             ),
// //             ElevatedButton(
// //               onPressed: () {
// //                 if (textController.text.isEmpty) {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     const SnackBar(content: Text('Please enter some text')),
// //                   );
// //                   return;
// //                 }
// //
// //                 final bloc = context.read<VideoEditorBloc>();
// //                 if (bloc.state is VideoEditorLoaded) {
// //                   final state = bloc.state as VideoEditorLoaded;
// //                   if (state.selectedClipIndex != null) {
// //                     bloc.add(AddTextOverlayEvent(
// //                       clipIndex: state.selectedClipIndex!,
// //                       text: textController.text,
// //                       startMs: state.currentPositionMs,
// //                       durationMs: 5000,
// //                       fontSize: fontSize,
// //                       color: textColor.value,
// //                     ));
// //                     Navigator.pop(context);
// //                   } else {
// //                     ScaffoldMessenger.of(context).showSnackBar(
// //                       const SnackBar(
// //                           content: Text('Please select a clip first')),
// //                     );
// //                   }
// //                 }
// //               },
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: const Color(0xFF0A84FF),
// //                 foregroundColor: Colors.white,
// //               ),
// //               child: const Text('Add'),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // ==================== STICKER TAB ====================
// //
// // class _StickerTab extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Column(
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.all(12),
// //           child: TextField(
// //             style: const TextStyle(color: Colors.white),
// //             decoration: InputDecoration(
// //               hintText: 'Search stickers',
// //               hintStyle: const TextStyle(color: Colors.white60),
// //               prefixIcon: const Icon(Icons.search, color: Colors.white60),
// //               filled: true,
// //               fillColor: const Color(0xFF2C2C2E),
// //               border: OutlineInputBorder(
// //                 borderRadius: BorderRadius.circular(8),
// //                 borderSide: BorderSide.none,
// //               ),
// //             ),
// //           ),
// //         ),
// //         Expanded(
// //           child: GridView.builder(
// //             padding: const EdgeInsets.symmetric(horizontal: 12),
// //             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //               crossAxisCount: 4,
// //               crossAxisSpacing: 8,
// //               mainAxisSpacing: 8,
// //             ),
// //             itemCount: 12,
// //             itemBuilder: (context, index) => GestureDetector(
// //               onTap: () {
// //                 final bloc = context.read<VideoEditorBloc>();
// //                 if (bloc.state is VideoEditorLoaded) {
// //                   final state = bloc.state as VideoEditorLoaded;
// //                   if (state.selectedClipIndex != null) {
// //                     bloc.add(AddStickerOverlayEvent(
// //                       clipIndex: state.selectedClipIndex!,
// //                       assetPath: 'assets/stickers/sticker_$index.png',
// //                       startMs: state.currentPositionMs,
// //                       durationMs: 5000,
// //                     ));
// //                   } else {
// //                     ScaffoldMessenger.of(context).showSnackBar(
// //                       const SnackBar(
// //                           content: Text('Please select a clip first')),
// //                     );
// //                   }
// //                 }
// //               },
// //               child: Container(
// //                 decoration: BoxDecoration(
// //                   color: const Color(0xFF2C2C2E),
// //                   borderRadius: BorderRadius.circular(8),
// //                   border: Border.all(color: const Color(0xFF3A3A3C)),
// //                 ),
// //                 child: Center(
// //                   child: Icon(
// //                     _getStickerIcon(index),
// //                     color: Colors.white60,
// //                     size: 32,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   IconData _getStickerIcon(int index) {
// //     final icons = [
// //       Icons.emoji_emotions,
// //       Icons.favorite,
// //       Icons.star,
// //       Icons.pets,
// //       Icons.eco,
// //       Icons.local_fire_department,
// //       Icons.wb_sunny,
// //       Icons.ac_unit,
// //       Icons.flash_on,
// //       Icons.celebration,
// //       Icons.cake,
// //       Icons.auto_awesome,
// //     ];
// //     return icons[index % icons.length];
// //   }
// // }
// //
// // // ==================== EFFECT TAB ====================
// //
// // class _EffectTab extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     final effects = [
// //       'None',
// //       'Black & White',
// //       'Sepia',
// //       'Vintage',
// //       'Blur',
// //       'Sharpen',
// //       'Brightness',
// //       'Contrast',
// //       'Saturation',
// //     ];
// //
// //     return GridView.builder(
// //       padding: const EdgeInsets.all(12),
// //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //         crossAxisCount: 3,
// //         childAspectRatio: 1.2,
// //         crossAxisSpacing: 8,
// //         mainAxisSpacing: 8,
// //       ),
// //       itemCount: effects.length,
// //       itemBuilder: (context, index) => _ToolButton(
// //         icon: Icons.filter,
// //         label: effects[index],
// //         onTap: () {
// //           final bloc = context.read<VideoEditorBloc>();
// //           if (bloc.state is VideoEditorLoaded) {
// //             final state = bloc.state as VideoEditorLoaded;
// //             if (state.selectedClipIndex != null) {
// //               bloc.add(ApplyFilterEvent(
// //                 state.selectedClipIndex!,
// //                 effects[index],
// //               ));
// //               ScaffoldMessenger.of(context).showSnackBar(
// //                 SnackBar(content: Text('${effects[index]} filter applied')),
// //               );
// //             } else {
// //               ScaffoldMessenger.of(context).showSnackBar(
// //                 const SnackBar(content: Text('Please select a clip first')),
// //               );
// //             }
// //           }
// //         },
// //       ),
// //     );
// //   }
// // }
// //
// // // ==================== PIP TAB ====================
// //
// // class _PIPTab extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Center(
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           const Icon(
// //             Icons.picture_in_picture_alt,
// //             color: Colors.white60,
// //             size: 64,
// //           ),
// //           const SizedBox(height: 16),
// //           const Text(
// //             'Picture-in-Picture',
// //             style: TextStyle(
// //               color: Colors.white,
// //               fontSize: 18,
// //               fontWeight: FontWeight.bold,
// //             ),
// //           ),
// //           const SizedBox(height: 8),
// //           const Text(
// //             'Coming soon',
// //             style: TextStyle(color: Colors.white60),
// //           ),
// //           const SizedBox(height: 24),
// //           ElevatedButton.icon(
// //             onPressed: () {
// //               ScaffoldMessenger.of(context).showSnackBar(
// //                 const SnackBar(
// //                   content: Text('PIP feature coming soon'),
// //                   backgroundColor: Color(0xFF0A84FF),
// //                 ),
// //               );
// //             },
// //             icon: const Icon(Icons.add),
// //             label: const Text('Add PIP Video'),
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: const Color(0xFF0A84FF),
// //               foregroundColor: Colors.white,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
// // video_editor_screen.dart
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// import 'package:kwaic/bloc/video_editor_bloc.dart';
// import 'package:kwaic/bloc/video_editor_event.dart';
// import 'package:kwaic/bloc/video_editor_state.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:video_player/video_player.dart';
// import 'package:file_picker/file_picker.dart';
//
// class VideoEditorScreen extends StatelessWidget {
//   const VideoEditorScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => VideoEditorBloc(),
//       child: const VideoEditorView(),
//     );
//   }
// }
//
// class VideoEditorView extends StatelessWidget {
//   const VideoEditorView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: BlocListener<VideoEditorBloc, VideoEditorState>(
//           listener: (context, state) {
//             if (state is VideoEditorLoaded && state.errorMessage != null) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(state.errorMessage!),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//             } else if (state is VideoEditorError) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(state.message),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//             }
//           },
//           child: Column(
//             children: const [
//               _TopBar(),
//               Expanded(child: _PreviewArea()),
//               _PlaybackControls(),
//               _TimelineArea(),
//               _BottomToolbar(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // ==================== TOP BAR ====================
//
// class _TopBar extends StatelessWidget {
//   const _TopBar({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 56,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       decoration: const BoxDecoration(color: Colors.black),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//           const Spacer(),
//           IconButton(
//             icon: const Icon(Icons.help_outline, color: Colors.white),
//             onPressed: () => _showProjectSettings(context),
//           ),
//           IconButton(
//             icon: const Icon(Icons.more_vert, color: Colors.white),
//             onPressed: () => _showProjectSettings(context),
//           ),
//           const SizedBox(width: 8),
//           BlocBuilder<VideoEditorBloc, VideoEditorState>(
//             builder: (context, state) {
//               if (state is VideoEditorLoaded && state.isExporting) {
//                 return Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 8,
//                   ),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF7C3AED),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(
//                           value: state.exportProgress,
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         '${(state.exportProgress * 100).toInt()}%',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }
//
//               return GestureDetector(
//                 onTap: () => _exportVideo(context),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 10,
//                   ),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF7C3AED),
//                     borderRadius: BorderRadius.circular(20),
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
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showProjectSettings(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1C1C1E),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (context) => Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Project Settings',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 ListTile(
//                   leading: const Icon(
//                     Icons.aspect_ratio,
//                     color: Color(0xFF7C3AED),
//                   ),
//                   title: const Text(
//                     'Aspect Ratio',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   subtitle: const Text(
//                     '9:16 (Portrait)',
//                     style: TextStyle(color: Colors.white60),
//                   ),
//                   trailing: const Icon(
//                     Icons.chevron_right,
//                     color: Colors.white60,
//                   ),
//                   onTap: () {},
//                 ),
//                 ListTile(
//                   leading: const Icon(
//                     Icons.high_quality,
//                     color: Color(0xFF7C3AED),
//                   ),
//                   title: const Text(
//                     'Export Quality',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   subtitle: const Text(
//                     '1080p HD',
//                     style: TextStyle(color: Colors.white60),
//                   ),
//                   trailing: const Icon(
//                     Icons.chevron_right,
//                     color: Colors.white60,
//                   ),
//                   onTap: () {},
//                 ),
//               ],
//             ),
//           ),
//     );
//   }
//
//   Future<void> _exportVideo(BuildContext context) async {
//     final directory = await getTemporaryDirectory();
//     final outputPath =
//         '${directory.path}/export_${DateTime.now().millisecondsSinceEpoch}.mp4';
//
//     context.read<VideoEditorBloc>().add(
//       ExportVideoEvent(outputPath: outputPath),
//     );
//   }
// }
//
// // ==================== PREVIEW AREA ====================
//
// class _PreviewArea extends StatelessWidget {
//   const _PreviewArea({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.black,
//       child: Center(
//         child: AspectRatio(
//           aspectRatio: 9 / 16,
//           child: BlocBuilder<VideoEditorBloc, VideoEditorState>(
//             builder: (context, state) {
//               if (state is! VideoEditorLoaded || state.clips.isEmpty) {
//                 return _EmptyPreview();
//               }
//
//               return Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   _VideoPlayer(),
//                   _TextOverlaysLayer(),
//                   _StickerOverlaysLayer(),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _EmptyPreview extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFF1C1C1E),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(
//               Icons.video_library_outlined,
//               size: 64,
//               color: Colors.grey,
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'No video selected',
//               style: TextStyle(color: Colors.white60, fontSize: 16),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () => _pickVideo(context),
//               icon: const Icon(Icons.add),
//               label: const Text('Add Video'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF7C3AED),
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(24),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _pickVideo(BuildContext context) async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.video);
//
//     if (result != null && result.files.single.path != null) {
//       final file = File(result.files.single.path!);
//       context.read<VideoEditorBloc>().add(LoadVideoEvent(file));
//     }
//   }
// }
//
// class _VideoPlayer extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<VideoEditorBloc, VideoEditorState>(
//       builder: (context, state) {
//         if (state is! VideoEditorLoaded || state.videoController == null) {
//           return const SizedBox();
//         }
//
//         return ValueListenableBuilder<VideoPlayerValue>(
//           valueListenable: state.videoController!,
//           builder: (context, value, child) {
//             if (!value.isInitialized) {
//               return Container(
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF1C1C1E),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Center(
//                   child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
//                 ),
//               );
//             }
//
//             return ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: FittedBox(
//                 fit: BoxFit.contain,
//                 child: SizedBox(
//                   width: value.size.width,
//                   height: value.size.height,
//                   child: VideoPlayer(state.videoController!),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }
//
// class _TextOverlaysLayer extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<VideoEditorBloc, VideoEditorState>(
//       builder: (context, state) {
//         if (state is! VideoEditorLoaded || state.selectedClip == null) {
//           return const SizedBox();
//         }
//
//         final clip = state.selectedClip!;
//         final currentPos = state.currentPositionMs - clip.startMs;
//
//         return LayoutBuilder(
//           builder: (context, constraints) {
//             final width = constraints.maxWidth;
//             final height = constraints.maxHeight;
//
//             return Stack(
//               children:
//                   clip.textOverlays
//                       .where(
//                         (overlay) =>
//                             currentPos >= overlay.startMs &&
//                             currentPos <= overlay.startMs + overlay.durationMs,
//                       )
//                       .map(
//                         (overlay) => Positioned(
//                           left: overlay.x * width - 100,
//                           top: overlay.y * height - 50,
//                           child: GestureDetector(
//                             onPanUpdate: (details) {
//                               final newX = (overlay.x +
//                                       details.delta.dx / width)
//                                   .clamp(0.0, 1.0);
//                               final newY = (overlay.y +
//                                       details.delta.dy / height)
//                                   .clamp(0.0, 1.0);
//
//                               final overlayIndex = clip.textOverlays.indexOf(
//                                 overlay,
//                               );
//                               context.read<VideoEditorBloc>().add(
//                                 UpdateTextOverlayEvent(
//                                   clipIndex: state.selectedClipIndex!,
//                                   overlayIndex: overlayIndex,
//                                   x: newX,
//                                   y: newY,
//                                 ),
//                               );
//                             },
//                             child: Text(
//                               overlay.text,
//                               style: TextStyle(
//                                 color: Color(overlay.color),
//                                 fontSize: overlay.fontSize,
//                                 fontWeight:
//                                     overlay.bold
//                                         ? FontWeight.bold
//                                         : FontWeight.normal,
//                                 fontStyle:
//                                     overlay.italic
//                                         ? FontStyle.italic
//                                         : FontStyle.normal,
//                                 shadows: const [
//                                   Shadow(
//                                     blurRadius: 4,
//                                     color: Colors.black,
//                                     offset: Offset(2, 2),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       )
//                       .toList(),
//             );
//           },
//         );
//       },
//     );
//   }
// }
//
// class _StickerOverlaysLayer extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<VideoEditorBloc, VideoEditorState>(
//       builder: (context, state) {
//         if (state is! VideoEditorLoaded || state.selectedClip == null) {
//           return const SizedBox();
//         }
//
//         final clip = state.selectedClip!;
//         final currentPos = state.currentPositionMs - clip.startMs;
//
//         return LayoutBuilder(
//           builder: (context, constraints) {
//             final width = constraints.maxWidth;
//             final height = constraints.maxHeight;
//
//             return Stack(
//               children:
//                   clip.stickerOverlays
//                       .where(
//                         (sticker) =>
//                             currentPos >= sticker.startMs &&
//                             currentPos <= sticker.startMs + sticker.durationMs,
//                       )
//                       .map(
//                         (sticker) => Positioned(
//                           left: sticker.x * width - 50 * sticker.scale,
//                           top: sticker.y * height - 50 * sticker.scale,
//                           child: Transform.rotate(
//                             angle: sticker.rotation,
//                             child: GestureDetector(
//                               onScaleUpdate: (details) {
//                                 final stickerIndex = clip.stickerOverlays
//                                     .indexOf(sticker);
//                                 context.read<VideoEditorBloc>().add(
//                                   UpdateStickerOverlayEvent(
//                                     clipIndex: state.selectedClipIndex!,
//                                     overlayIndex: stickerIndex,
//                                     scale: (sticker.scale * details.scale)
//                                         .clamp(0.5, 3.0),
//                                     rotation:
//                                         sticker.rotation + details.rotation,
//                                   ),
//                                 );
//                               },
//                               onPanUpdate: (details) {
//                                 final newX = (sticker.x +
//                                         details.delta.dx / width)
//                                     .clamp(0.0, 1.0);
//                                 final newY = (sticker.y +
//                                         details.delta.dy / height)
//                                     .clamp(0.0, 1.0);
//
//                                 final stickerIndex = clip.stickerOverlays
//                                     .indexOf(sticker);
//                                 context.read<VideoEditorBloc>().add(
//                                   UpdateStickerOverlayEvent(
//                                     clipIndex: state.selectedClipIndex!,
//                                     overlayIndex: stickerIndex,
//                                     x: newX,
//                                     y: newY,
//                                   ),
//                                 );
//                               },
//                               child: Container(
//                                 width: 100 * sticker.scale,
//                                 height: 100 * sticker.scale,
//                                 decoration: BoxDecoration(
//                                   border: Border.all(color: Colors.white24),
//                                   image: DecorationImage(
//                                     image: AssetImage(sticker.assetPath),
//                                     fit: BoxFit.contain,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       )
//                       .toList(),
//             );
//           },
//         );
//       },
//     );
//   }
// }
//
// // ==================== PLAYBACK CONTROLS ====================
//
// class _PlaybackControls extends StatelessWidget {
//   const _PlaybackControls({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 60,
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       color: Colors.black,
//       child: Row(
//         children: [
//           // Play/Pause button
//           BlocBuilder<VideoEditorBloc, VideoEditorState>(
//             builder: (context, state) {
//               final isPlaying =
//                   state is VideoEditorLoaded ? state.isPlaying : false;
//
//               return Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: IconButton(
//                   padding: EdgeInsets.zero,
//                   icon: Icon(
//                     isPlaying ? Icons.pause : Icons.play_arrow,
//                     color: Colors.white,
//                     size: 20,
//                   ),
//                   onPressed:
//                       () => context.read<VideoEditorBloc>().add(
//                         TogglePlayPauseEvent(),
//                       ),
//                 ),
//               );
//             },
//           ),
//
//           const SizedBox(width: 12),
//
//           // Timecode
//           SizedBox(
//             width: 80,
//             child: BlocBuilder<VideoEditorBloc, VideoEditorState>(
//               builder: (context, state) {
//                 final currentMs =
//                     state is VideoEditorLoaded ? state.currentPositionMs : 0.0;
//                 final totalMs =
//                     state is VideoEditorLoaded ? state.totalDurationMs : 0.0;
//                 return Text(
//                   '${_formatTime(currentMs / 1000)} / ${_formatTime(totalMs / 1000)}',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 11,
//                     fontFamily: 'monospace',
//                   ),
//                 );
//               },
//             ),
//           ),
//
//           const SizedBox(width: 16),
//
//           // Undo button
//           Container(
//             width: 36,
//             height: 36,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: IconButton(
//               padding: EdgeInsets.zero,
//               icon: const Icon(Icons.undo, color: Colors.white, size: 18),
//               onPressed: null, // TODO: Implement undo
//             ),
//           ),
//
//           const SizedBox(width: 8),
//
//           // Redo button
//           Container(
//             width: 36,
//             height: 36,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: IconButton(
//               padding: EdgeInsets.zero,
//               icon: const Icon(Icons.redo, color: Colors.white, size: 18),
//               onPressed: null, // TODO: Implement redo
//             ),
//           ),
//
//           const SizedBox(width: 8),
//
//           // Crop button
//           Container(
//             width: 36,
//             height: 36,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: IconButton(
//               padding: EdgeInsets.zero,
//               icon: const Icon(Icons.crop, color: Colors.white, size: 18),
//               onPressed: () {},
//             ),
//           ),
//
//           const SizedBox(width: 8),
//
//           // Flip button
//           Container(
//             width: 36,
//             height: 36,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: IconButton(
//               padding: EdgeInsets.zero,
//               icon: const Icon(Icons.flip, color: Colors.white, size: 18),
//               onPressed: () {
//                 final bloc = context.read<VideoEditorBloc>();
//                 if (bloc.state is VideoEditorLoaded) {
//                   final state = bloc.state as VideoEditorLoaded;
//                   if (state.selectedClipIndex != null) {
//                     bloc.add(FlipClipEvent(state.selectedClipIndex!));
//                   }
//                 }
//               },
//             ),
//           ),
//
//           const SizedBox(width: 8),
//
//           // Rotate button
//           Container(
//             width: 36,
//             height: 36,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: IconButton(
//               padding: EdgeInsets.zero,
//               icon: const Icon(
//                 Icons.rotate_90_degrees_ccw,
//                 color: Colors.white,
//                 size: 18,
//               ),
//               onPressed: () {
//                 final bloc = context.read<VideoEditorBloc>();
//                 if (bloc.state is VideoEditorLoaded) {
//                   final state = bloc.state as VideoEditorLoaded;
//                   if (state.selectedClipIndex != null) {
//                     bloc.add(RotateClipEvent(state.selectedClipIndex!, 90));
//                   }
//                 }
//               },
//             ),
//           ),
//
//           const Spacer(),
//
//           // Volume button
//           Container(
//             width: 36,
//             height: 36,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: IconButton(
//               padding: EdgeInsets.zero,
//               icon: const Icon(Icons.volume_up, color: Colors.white, size: 18),
//               onPressed: () => _showVolumeDialog(context),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatTime(double seconds) {
//     final m = (seconds / 60).floor().toString().padLeft(2, '0');
//     final s = (seconds % 60).floor().toString().padLeft(2, '0');
//     return '$m:$s';
//   }
//
//   void _showVolumeDialog(BuildContext context) {
//     double volume = 1.0;
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1C1C1E),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (context) => StatefulBuilder(
//             builder:
//                 (context, setState) => Container(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Text(
//                         'Volume',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Text(
//                         '${(volume * 100).toInt()}%',
//                         style: const TextStyle(
//                           color: Color(0xFF7C3AED),
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Slider(
//                         value: volume,
//                         min: 0.0,
//                         max: 2.0,
//                         divisions: 20,
//                         activeColor: const Color(0xFF7C3AED),
//                         onChanged: (value) {
//                           setState(() => volume = value);
//                         },
//                         onChangeEnd: (value) {
//                           final bloc = context.read<VideoEditorBloc>();
//                           if (bloc.state is VideoEditorLoaded) {
//                             final state = bloc.state as VideoEditorLoaded;
//                             if (state.selectedClipIndex != null) {
//                               bloc.add(
//                                 SetClipVolumeEvent(
//                                   state.selectedClipIndex!,
//                                   value,
//                                 ),
//                               );
//                             }
//                           }
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//           ),
//     );
//   }
// }
//
// // ==================== TIMELINE AREA ====================
//
// class _TimelineArea extends StatelessWidget {
//   const _TimelineArea({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 120,
//       color: Colors.black,
//       child: BlocBuilder<VideoEditorBloc, VideoEditorState>(
//         builder: (context, state) {
//           if (state is! VideoEditorLoaded || state.clips.isEmpty) {
//             return Center(
//               child: TextButton.icon(
//                 onPressed: () async {
//                   final result = await FilePicker.platform.pickFiles(
//                     type: FileType.video,
//                   );
//
//                   if (result != null && result.files.single.path != null) {
//                     final file = File(result.files.single.path!);
//                     context.read<VideoEditorBloc>().add(LoadVideoEvent(file));
//                   }
//                 },
//                 icon: const Icon(Icons.add, color: Colors.white60),
//                 label: const Text(
//                   'Add clips to timeline',
//                   style: TextStyle(color: Colors.white60),
//                 ),
//               ),
//             );
//           }
//
//           return _Timeline();
//         },
//       ),
//     );
//   }
// }
//
// class _Timeline extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<VideoEditorBloc, VideoEditorState>(
//       builder: (context, state) {
//         if (state is! VideoEditorLoaded) return const SizedBox();
//
//         final totalDuration = state.totalDurationMs;
//         final pixelsPerSecond = state.pixelsPerSecond;
//
//         return SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Stack(
//             children: [
//               SizedBox(
//                 width: totalDuration * pixelsPerSecond / 1000,
//                 height: 120,
//                 child: Column(
//                   children: [
//                     // Timeline track
//                     Expanded(child: _VideoTrack()),
//                   ],
//                 ),
//               ),
//               // Playhead
//               Positioned(
//                 left:
//                     (state.currentPositionMs / totalDuration) *
//                     (totalDuration * pixelsPerSecond / 1000),
//                 top: 0,
//                 bottom: 0,
//                 child: Container(
//                   width: 2,
//                   color: Colors.white,
//                   child: Container(
//                     width: 12,
//                     height: 12,
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
//
// class _VideoTrack extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<VideoEditorBloc, VideoEditorState>(
//       builder: (context, state) {
//         if (state is! VideoEditorLoaded) return const SizedBox();
//
//         double cumulativeStart = 0;
//
//         return Row(
//           children: [
//             ...state.clips.asMap().entries.map((entry) {
//               final index = entry.key;
//               final clip = entry.value;
//               final isSelected = state.selectedClipIndex == index;
//               final duration = clip.durationMs;
//               final width = duration * state.pixelsPerSecond / 1000;
//
//               return GestureDetector(
//                 onTap: () {
//                   context.read<VideoEditorBloc>().add(SelectClipEvent(index));
//                 },
//                 onLongPress: () => _showClipOptions(context, index),
//                 child: Container(
//                   width: width.clamp(80.0, double.infinity),
//                   height: 80,
//                   margin: const EdgeInsets.only(right: 4),
//                   decoration: BoxDecoration(
//                     color:
//                         isSelected
//                             ? const Color(0xFF7C3AED)
//                             : const Color(0xFF2C2C2E),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color:
//                           isSelected ? const Color(0xFF7C3AED) : Colors.white24,
//                       width: isSelected ? 3 : 1,
//                     ),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(6),
//                     child:
//                         clip.thumbnails.isNotEmpty
//                             ? Row(
//                               children:
//                                   clip.thumbnails
//                                       .take(6)
//                                       .map(
//                                         (thumb) => Expanded(
//                                           child: Image.file(
//                                             File(thumb),
//                                             fit: BoxFit.cover,
//                                           ),
//                                         ),
//                                       )
//                                       .toList(),
//                             )
//                             : const Center(
//                               child: Icon(
//                                 Icons.videocam,
//                                 color: Colors.white70,
//                                 size: 24,
//                               ),
//                             ),
//                   ),
//                 ),
//               );
//             }).toList(),
//             // Add video button
//             GestureDetector(
//               onTap: () async {
//                 final result = await FilePicker.platform.pickFiles(
//                   type: FileType.video,
//                 );
//
//                 if (result != null && result.files.single.path != null) {
//                   final file = File(result.files.single.path!);
//                   context.read<VideoEditorBloc>().add(AddVideoClipEvent(file));
//                 }
//               },
//               child: Container(
//                 width: 80,
//                 height: 80,
//                 margin: const EdgeInsets.only(left: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.white24),
//                 ),
//                 child: const Icon(Icons.add, color: Colors.white, size: 32),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _showClipOptions(BuildContext context, int index) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1C1C1E),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (context) => Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 ListTile(
//                   leading: const Icon(
//                     Icons.content_cut,
//                     color: Color(0xFF7C3AED),
//                   ),
//                   title: const Text(
//                     'Split',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   onTap: () {
//                     Navigator.pop(context);
//                     final bloc = context.read<VideoEditorBloc>();
//                     if (bloc.state is VideoEditorLoaded) {
//                       bloc.add(
//                         SplitClipEvent(
//                           index,
//                           (bloc.state as VideoEditorLoaded).currentPositionMs,
//                         ),
//                       );
//                     }
//                   },
//                 ),
//                 ListTile(
//                   leading: const Icon(
//                     Icons.content_copy,
//                     color: Color(0xFF7C3AED),
//                   ),
//                   title: const Text(
//                     'Duplicate',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   onTap: () {
//                     Navigator.pop(context);
//                     context.read<VideoEditorBloc>().add(
//                       DuplicateClipEvent(index),
//                     );
//                   },
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.delete, color: Colors.red),
//                   title: const Text(
//                     'Delete',
//                     style: TextStyle(color: Colors.red),
//                   ),
//                   onTap: () {
//                     Navigator.pop(context);
//                     context.read<VideoEditorBloc>().add(RemoveClipEvent(index));
//                   },
//                 ),
//               ],
//             ),
//           ),
//     );
//   }
// }
//
// // ==================== BOTTOM TOOLBAR ====================
//
// class _BottomToolbar extends StatelessWidget {
//   const _BottomToolbar({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 80,
//       decoration: BoxDecoration(
//         color: Colors.black,
//         border: Border(
//           top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
//         ),
//       ),
//       child: BlocBuilder<VideoEditorBloc, VideoEditorState>(
//         builder: (context, state) {
//           final selectedTab =
//               state is VideoEditorLoaded ? state.selectedToolTab : 0;
//
//           return Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _ToolbarButton(
//                 icon: Icons.content_cut,
//                 label: 'Edit',
//                 isSelected: selectedTab == 0,
//                 onTap: () {
//                   context.read<VideoEditorBloc>().add(
//                     const ChangeToolTabEvent(0),
//                   );
//                   _showEditOptions(context);
//                 },
//               ),
//               _ToolbarButton(
//                 icon: Icons.music_note,
//                 label: 'Audio',
//                 isSelected: selectedTab == 1,
//                 onTap: () {
//                   context.read<VideoEditorBloc>().add(
//                     const ChangeToolTabEvent(1),
//                   );
//                   _showAudioOptions(context);
//                 },
//               ),
//               _ToolbarButton(
//                 icon: Icons.text_fields,
//                 label: 'Text',
//                 isSelected: selectedTab == 2,
//                 onTap: () {
//                   context.read<VideoEditorBloc>().add(
//                     const ChangeToolTabEvent(2),
//                   );
//                   _showAddTextDialog(context);
//                 },
//               ),
//               _ToolbarButton(
//                 icon: Icons.filter_none,
//                 label: 'Stickers',
//                 isSelected: selectedTab == 3,
//                 onTap: () {
//                   context.read<VideoEditorBloc>().add(
//                     const ChangeToolTabEvent(3),
//                   );
//                   _showStickerPicker(context);
//                 },
//               ),
//               _ToolbarButton(
//                 icon: Icons.auto_awesome,
//                 label: 'Effects',
//                 isSelected: selectedTab == 4,
//                 onTap: () {
//                   context.read<VideoEditorBloc>().add(
//                     const ChangeToolTabEvent(4),
//                   );
//                   _showEffectOptions(context);
//                 },
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   void _showEditOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1C1C1E),
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (context) => DraggableScrollableSheet(
//             initialChildSize: 0.6,
//             maxChildSize: 0.9,
//             minChildSize: 0.4,
//             expand: false,
//             builder:
//                 (context, scrollController) => Container(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color: Colors.white24,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       const Text(
//                         'Edit Tools',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Expanded(
//                         child: GridView.count(
//                           controller: scrollController,
//                           crossAxisCount: 4,
//                           crossAxisSpacing: 12,
//                           mainAxisSpacing: 12,
//                           children: [
//                             _EditTool(
//                               icon: Icons.content_cut,
//                               label: 'Split',
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 final bloc = context.read<VideoEditorBloc>();
//                                 if (bloc.state is VideoEditorLoaded) {
//                                   final state = bloc.state as VideoEditorLoaded;
//                                   if (state.selectedClipIndex != null) {
//                                     bloc.add(
//                                       SplitClipEvent(
//                                         state.selectedClipIndex!,
//                                         state.currentPositionMs,
//                                       ),
//                                     );
//                                   }
//                                 }
//                               },
//                             ),
//                             _EditTool(
//                               icon: Icons.crop,
//                               label: 'Trim',
//                               onTap: () {
//                                 Navigator.pop(context);
//                               },
//                             ),
//                             _EditTool(
//                               icon: Icons.speed,
//                               label: 'Speed',
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 _showSpeedDialog(context);
//                               },
//                             ),
//                             _EditTool(
//                               icon: Icons.content_copy,
//                               label: 'Duplicate',
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 final bloc = context.read<VideoEditorBloc>();
//                                 if (bloc.state is VideoEditorLoaded) {
//                                   final state = bloc.state as VideoEditorLoaded;
//                                   if (state.selectedClipIndex != null) {
//                                     bloc.add(
//                                       DuplicateClipEvent(
//                                         state.selectedClipIndex!,
//                                       ),
//                                     );
//                                   }
//                                 }
//                               },
//                             ),
//                             _EditTool(
//                               icon: Icons.delete,
//                               label: 'Delete',
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 final bloc = context.read<VideoEditorBloc>();
//                                 if (bloc.state is VideoEditorLoaded) {
//                                   final state = bloc.state as VideoEditorLoaded;
//                                   if (state.selectedClipIndex != null) {
//                                     bloc.add(
//                                       RemoveClipEvent(state.selectedClipIndex!),
//                                     );
//                                   }
//                                 }
//                               },
//                             ),
//                             _EditTool(
//                               icon: Icons.swap_horiz,
//                               label: 'Transition',
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 _showTransitionDialog(context);
//                               },
//                             ),
//                             _EditTool(
//                               icon: Icons.animation,
//                               label: 'Animation',
//                               onTap: () {
//                                 Navigator.pop(context);
//                               },
//                             ),
//                             _EditTool(
//                               icon: Icons.video_settings,
//                               label: 'Chroma Key',
//                               onTap: () {
//                                 Navigator.pop(context);
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//           ),
//     );
//   }
//
//   void _showAudioOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1C1C1E),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (context) => Container(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'Audio Tools',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 ListTile(
//                   leading: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF7C3AED).withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Icon(
//                       Icons.music_note,
//                       color: Color(0xFF7C3AED),
//                     ),
//                   ),
//                   title: const Text(
//                     'Background Music',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   subtitle: const Text(
//                     'Add music to your video',
//                     style: TextStyle(color: Colors.white60),
//                   ),
//                   onTap: () async {
//                     Navigator.pop(context);
//                     final result = await FilePicker.platform.pickFiles(
//                       type: FileType.audio,
//                     );
//                     if (result != null && result.files.single.path != null) {
//                       final file = File(result.files.single.path!);
//                       context.read<VideoEditorBloc>().add(
//                         AddBackgroundMusicEvent(file),
//                       );
//                     }
//                   },
//                 ),
//                 ListTile(
//                   leading: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF7C3AED).withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Icon(Icons.mic, color: Color(0xFF7C3AED)),
//                   ),
//                   title: const Text(
//                     'Voice Over',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   subtitle: const Text(
//                     'Record narration',
//                     style: TextStyle(color: Colors.white60),
//                   ),
//                   onTap: () {
//                     Navigator.pop(context);
//                     context.read<VideoEditorBloc>().add(
//                       StartVoiceRecordingEvent(),
//                     );
//                   },
//                 ),
//                 ListTile(
//                   leading: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF7C3AED).withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Icon(
//                       Icons.graphic_eq,
//                       color: Color(0xFF7C3AED),
//                     ),
//                   ),
//                   title: const Text(
//                     'Sound Effects',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   subtitle: const Text(
//                     'Add audio effects',
//                     style: TextStyle(color: Colors.white60),
//                   ),
//                   onTap: () {
//                     Navigator.pop(context);
//                   },
//                 ),
//                 ListTile(
//                   leading: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF7C3AED).withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Icon(Icons.waves, color: Color(0xFF7C3AED)),
//                   ),
//                   title: const Text(
//                     'Noise Reduction',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   subtitle: const Text(
//                     'Remove background noise',
//                     style: TextStyle(color: Colors.white60),
//                   ),
//                   onTap: () {
//                     Navigator.pop(context);
//                   },
//                 ),
//                 ListTile(
//                   leading: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF7C3AED).withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Icon(
//                       Icons.record_voice_over,
//                       color: Color(0xFF7C3AED),
//                     ),
//                   ),
//                   title: const Text(
//                     'Text to Speech',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   subtitle: const Text(
//                     'Convert text to voice',
//                     style: TextStyle(color: Colors.white60),
//                   ),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _showTTSDialog(context);
//                   },
//                 ),
//               ],
//             ),
//           ),
//     );
//   }
//
//   void _showAddTextDialog(BuildContext context) {
//     final textController = TextEditingController();
//     double fontSize = 32;
//     Color textColor = Colors.white;
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1C1C1E),
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (dialogContext) => Padding(
//             padding: EdgeInsets.only(
//               bottom: MediaQuery.of(context).viewInsets.bottom,
//               left: 20,
//               right: 20,
//               top: 20,
//             ),
//             child: StatefulBuilder(
//               builder:
//                   (context, setState) => Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Text(
//                         'Add Text',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       TextField(
//                         controller: textController,
//                         style: const TextStyle(color: Colors.white),
//                         maxLines: 3,
//                         autofocus: true,
//                         decoration: InputDecoration(
//                           hintText: 'Enter your text',
//                           hintStyle: const TextStyle(color: Colors.white60),
//                           filled: true,
//                           fillColor: const Color(0xFF2C2C2E),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide.none,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Row(
//                         children: [
//                           const Text(
//                             'Size: ',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                           Expanded(
//                             child: Slider(
//                               min: 16,
//                               max: 72,
//                               value: fontSize,
//                               activeColor: const Color(0xFF7C3AED),
//                               onChanged:
//                                   (value) => setState(() => fontSize = value),
//                             ),
//                           ),
//                           Text(
//                             '${fontSize.toInt()}',
//                             style: const TextStyle(color: Colors.white),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           const Text(
//                             'Color: ',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                           const SizedBox(width: 12),
//                           GestureDetector(
//                             onTap: () async {
//                               final color = await showDialog<Color>(
//                                 context: dialogContext,
//                                 builder:
//                                     (context) => AlertDialog(
//                                       backgroundColor: const Color(0xFF1C1C1E),
//                                       title: const Text(
//                                         'Pick Color',
//                                         style: TextStyle(color: Colors.white),
//                                       ),
//                                       content: SingleChildScrollView(
//                                         child: BlockPicker(
//                                           pickerColor: textColor,
//                                           onColorChanged:
//                                               (c) => Navigator.pop(context, c),
//                                         ),
//                                       ),
//                                     ),
//                               );
//                               if (color != null) {
//                                 setState(() => textColor = color);
//                               }
//                             },
//                             child: Container(
//                               width: 40,
//                               height: 40,
//                               decoration: BoxDecoration(
//                                 color: textColor,
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(color: Colors.white24),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextButton(
//                               onPressed: () => Navigator.pop(context),
//                               child: const Text(
//                                 'Cancel',
//                                 style: TextStyle(color: Colors.white60),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: ElevatedButton(
//                               onPressed: () {
//                                 if (textController.text.isEmpty) return;
//
//                                 final bloc = context.read<VideoEditorBloc>();
//                                 if (bloc.state is VideoEditorLoaded) {
//                                   final state = bloc.state as VideoEditorLoaded;
//                                   if (state.selectedClipIndex != null) {
//                                     bloc.add(
//                                       AddTextOverlayEvent(
//                                         clipIndex: state.selectedClipIndex!,
//                                         text: textController.text,
//                                         startMs: state.currentPositionMs,
//                                         durationMs: 5000,
//                                         fontSize: fontSize,
//                                         color: textColor.value,
//                                       ),
//                                     );
//                                     Navigator.pop(context);
//                                   }
//                                 }
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFF7C3AED),
//                                 foregroundColor: Colors.white,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(24),
//                                 ),
//                               ),
//                               child: const Text('Add'),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                     ],
//                   ),
//             ),
//           ),
//     );
//   }
//
//   void _showStickerPicker(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1C1C1E),
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (context) => DraggableScrollableSheet(
//             initialChildSize: 0.7,
//             maxChildSize: 0.9,
//             minChildSize: 0.5,
//             expand: false,
//             builder:
//                 (context, scrollController) => Container(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color: Colors.white24,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Row(
//                         children: [
//                           const Text(
//                             'Stickers',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const Spacer(),
//                           IconButton(
//                             icon: const Icon(Icons.close, color: Colors.white),
//                             onPressed: () => Navigator.pop(context),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       TextField(
//                         style: const TextStyle(color: Colors.white),
//                         decoration: InputDecoration(
//                           hintText: 'Search shapes',
//                           hintStyle: const TextStyle(color: Colors.white60),
//                           prefixIcon: const Icon(
//                             Icons.search,
//                             color: Colors.white60,
//                           ),
//                           filled: true,
//                           fillColor: const Color(0xFF2C2C2E),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide.none,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       SingleChildScrollView(
//                         scrollDirection: Axis.horizontal,
//                         child: Row(
//                           children: [
//                             _StickerCategory(
//                               label: 'Recents',
//                               isSelected: true,
//                             ),
//                             _StickerCategory(
//                               label: 'Favorite',
//                               isSelected: false,
//                             ),
//                             _StickerCategory(label: 'GIF', isSelected: false),
//                             _StickerCategory(
//                               label: 'Trending',
//                               isSelected: false,
//                             ),
//                             _StickerCategory(
//                               label: 'Birthday',
//                               isSelected: false,
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Expanded(
//                         child: GridView.builder(
//                           controller: scrollController,
//                           gridDelegate:
//                               const SliverGridDelegateWithFixedCrossAxisCount(
//                                 crossAxisCount: 3,
//                                 crossAxisSpacing: 12,
//                                 mainAxisSpacing: 12,
//                               ),
//                           itemCount: 12,
//                           itemBuilder:
//                               (context, index) => GestureDetector(
//                                 onTap: () {
//                                   Navigator.pop(context);
//                                   final bloc = context.read<VideoEditorBloc>();
//                                   if (bloc.state is VideoEditorLoaded) {
//                                     final state =
//                                         bloc.state as VideoEditorLoaded;
//                                     if (state.selectedClipIndex != null) {
//                                       bloc.add(
//                                         AddStickerOverlayEvent(
//                                           clipIndex: state.selectedClipIndex!,
//                                           assetPath:
//                                               'assets/stickers/sticker_$index.png',
//                                           startMs: state.currentPositionMs,
//                                           durationMs: 5000,
//                                         ),
//                                       );
//                                     }
//                                   }
//                                 },
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFF2C2C2E),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Center(
//                                     child: Icon(
//                                       _getStickerIcon(index),
//                                       color: Colors.white70,
//                                       size: 40,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//           ),
//     );
//   }
//
//   void _showEffectOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1C1C1E),
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (context) => DraggableScrollableSheet(
//             initialChildSize: 0.6,
//             maxChildSize: 0.9,
//             minChildSize: 0.4,
//             expand: false,
//             builder:
//                 (context, scrollController) => Container(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color: Colors.white24,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       const Text(
//                         'Effects & Filters',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Expanded(
//                         child: GridView.count(
//                           controller: scrollController,
//                           crossAxisCount: 3,
//                           crossAxisSpacing: 12,
//                           mainAxisSpacing: 12,
//                           children: [
//                             _EffectTile(label: 'None', onTap: () {}),
//                             _EffectTile(
//                               label: 'Black & White',
//                               onTap: () {
//                                 _applyFilter(context, 'black & white');
//                               },
//                             ),
//                             _EffectTile(
//                               label: 'Sepia',
//                               onTap: () {
//                                 _applyFilter(context, 'sepia');
//                               },
//                             ),
//                             _EffectTile(
//                               label: 'Vintage',
//                               onTap: () {
//                                 _applyFilter(context, 'vintage');
//                               },
//                             ),
//                             _EffectTile(
//                               label: 'Blur',
//                               onTap: () {
//                                 _applyFilter(context, 'blur');
//                               },
//                             ),
//                             _EffectTile(
//                               label: 'Sharpen',
//                               onTap: () {
//                                 _applyFilter(context, 'sharpen');
//                               },
//                             ),
//                             _EffectTile(label: 'Cinematic', onTap: () {}),
//                             _EffectTile(label: 'Warm', onTap: () {}),
//                             _EffectTile(label: 'Cool', onTap: () {}),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//           ),
//     );
//   }
//
//   void _applyFilter(BuildContext context, String filterName) {
//     Navigator.pop(context);
//     final bloc = context.read<VideoEditorBloc>();
//     if (bloc.state is VideoEditorLoaded) {
//       final state = bloc.state as VideoEditorLoaded;
//       if (state.selectedClipIndex != null) {
//         bloc.add(ApplyFilterEvent(state.selectedClipIndex!, filterName));
//       }
//     }
//   }
//
//   void _showSpeedDialog(BuildContext context) {
//     double speed = 1.0;
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1C1C1E),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (context) => StatefulBuilder(
//             builder:
//                 (context, setState) => Container(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Text(
//                         'Playback Speed',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Text(
//                         '${speed.toStringAsFixed(2)}x',
//                         style: const TextStyle(
//                           color: Color(0xFF7C3AED),
//                           fontSize: 40,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Slider(
//                         value: speed,
//                         min: 0.25,
//                         max: 4.0,
//                         divisions: 15,
//                         activeColor: const Color(0xFF7C3AED),
//                         onChanged: (value) => setState(() => speed = value),
//                         onChangeEnd: (value) {
//                           final bloc = context.read<VideoEditorBloc>();
//                           if (bloc.state is VideoEditorLoaded) {
//                             final state = bloc.state as VideoEditorLoaded;
//                             if (state.selectedClipIndex != null) {
//                               bloc.add(
//                                 SetClipSpeedEvent(
//                                   state.selectedClipIndex!,
//                                   value,
//                                 ),
//                               );
//                             }
//                           }
//                         },
//                       ),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: const [
//                           Text(
//                             '0.25x',
//                             style: TextStyle(color: Colors.white60),
//                           ),
//                           Text('4.0x', style: TextStyle(color: Colors.white60)),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                     ],
//                   ),
//                 ),
//           ),
//     );
//   }
//
//   void _showTransitionDialog(BuildContext context) {
//     final transitions = ['None', 'Fade', 'Slide', 'Zoom', 'Wipe', 'Dissolve'];
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF1C1C1E),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (context) => Container(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'Transition',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 ...transitions.map(
//                   (transition) => ListTile(
//                     leading: const Icon(
//                       Icons.swap_horiz,
//                       color: Color(0xFF7C3AED),
//                     ),
//                     title: Text(
//                       transition,
//                       style: const TextStyle(color: Colors.white),
//                     ),
//                     onTap: () {
//                       Navigator.pop(context);
//                       final bloc = context.read<VideoEditorBloc>();
//                       if (bloc.state is VideoEditorLoaded) {
//                         final state = bloc.state as VideoEditorLoaded;
//                         if (state.selectedClipIndex != null) {
//                           bloc.add(
//                             SetTransitionEvent(
//                               state.selectedClipIndex!,
//                               transition.toLowerCase(),
//                               0.5,
//                             ),
//                           );
//                         }
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//     );
//   }
//
//   void _showTTSDialog(BuildContext context) {
//     final textController = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             backgroundColor: const Color(0xFF1C1C1E),
//             title: const Text(
//               'Text to Speech',
//               style: TextStyle(color: Colors.white),
//             ),
//             content: TextField(
//               controller: textController,
//               style: const TextStyle(color: Colors.white),
//               maxLines: 4,
//               decoration: InputDecoration(
//                 hintText: 'Enter text to convert to speech',
//                 hintStyle: const TextStyle(color: Colors.white60),
//                 filled: true,
//                 fillColor: const Color(0xFF2C2C2E),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text(
//                   'Cancel',
//                   style: TextStyle(color: Colors.white60),
//                 ),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   if (textController.text.isNotEmpty) {
//                     context.read<VideoEditorBloc>().add(
//                       GenerateTTSEvent(textController.text),
//                     );
//                     Navigator.pop(context);
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF7C3AED),
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('Generate'),
//               ),
//             ],
//           ),
//     );
//   }
//
//   IconData _getStickerIcon(int index) {
//     final icons = [
//       Icons.emoji_emotions,
//       Icons.favorite,
//       Icons.star,
//       Icons.pets,
//       Icons.eco,
//       Icons.local_fire_department,
//       Icons.wb_sunny,
//       Icons.ac_unit,
//       Icons.flash_on,
//       Icons.celebration,
//       Icons.cake,
//       Icons.auto_awesome,
//     ];
//     return icons[index % icons.length];
//   }
// }
//
// class _ToolbarButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool isSelected;
//   final VoidCallback onTap;
//
//   const _ToolbarButton({
//     Key? key,
//     required this.icon,
//     required this.label,
//     required this.isSelected,
//     required this.onTap,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color: isSelected ? const Color(0xFF7C3AED) : Colors.white60,
//               size: 24,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 color: isSelected ? const Color(0xFF7C3AED) : Colors.white60,
//                 fontSize: 11,
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _EditTool extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;
//
//   const _EditTool({
//     Key? key,
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: const Color(0xFF2C2C2E),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: Colors.white, size: 28),
//             const SizedBox(height: 6),
//             Text(
//               label,
//               style: const TextStyle(color: Colors.white, fontSize: 11),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _StickerCategory extends StatelessWidget {
//   final String label;
//   final bool isSelected;
//
//   const _StickerCategory({
//     Key? key,
//     required this.label,
//     required this.isSelected,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(right: 12),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF2C2C2E),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: isSelected ? Colors.white : Colors.white60,
//           fontSize: 13,
//           fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//         ),
//       ),
//     );
//   }
// }
//
// class _EffectTile extends StatelessWidget {
//   final String label;
//   final VoidCallback onTap;
//
//   const _EffectTile({Key? key, required this.label, required this.onTap})
//     : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: const Color(0xFF2C2C2E),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 50,
//               height: 50,
//               decoration: BoxDecoration(
//                 color: Colors.white12,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Icon(Icons.image, color: Colors.white60, size: 24),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               label,
//               style: const TextStyle(color: Colors.white, fontSize: 11),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// video_editor_screen.dart - CapCut/KwaiCut Style
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kwaic/bloc/video_editor_bloc.dart';
import 'package:kwaic/bloc/video_editor_event.dart';
import 'package:kwaic/bloc/video_editor_state.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';


class VideoEditorScree extends StatelessWidget {
  const VideoEditorScree({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VideoEditorBloc(),
      child: const VideoEditorView(),
    );
  }
}

class VideoEditorView extends StatelessWidget {
  const VideoEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BlocListener<VideoEditorBloc, VideoEditorState>(
          listener: (context, state) {
            if (state is VideoEditorLoaded && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Column(
            children: [
              _TopBar(),
              Expanded(child: _PreviewArea()),
              _PlaybackControls(),
              _TimelineArea(),
              _BottomToolbar(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== TOP BAR ====================

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          // Settings/Info button
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 24),
            onPressed: () => _showProjectSettings(context),
          ),
          // More options
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          // Export button
          BlocBuilder<VideoEditorBloc, VideoEditorState>(
            builder: (context, state) {
              if (state is VideoEditorLoaded && state.isExporting) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A5CFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          value: state.exportProgress,
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(state.exportProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A5CFF),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _exportVideo(context),
                child: const Text(
                  'Export',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showProjectSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Project Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _SettingsTile(
              icon: Icons.aspect_ratio,
              title: 'Aspect Ratio',
              value: '9:16',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.high_quality,
              title: 'Export Quality',
              value: '1080p',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.video_settings,
              title: 'Frame Rate',
              value: '30 fps',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportVideo(BuildContext context) async {
    final bloc = context.read<VideoEditorBloc>();
    if (bloc.state is! VideoEditorLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a video first')),
      );
      return;
    }

    final directory = await getTemporaryDirectory();
    final outputPath =
        '${directory.path}/export_${DateTime.now().millisecondsSinceEpoch}.mp4';

    bloc.add(ExportVideoEvent(outputPath: outputPath));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF8A5CFF)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.white60)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.white60),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ==================== PREVIEW AREA ====================

class _PreviewArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: BlocBuilder<VideoEditorBloc, VideoEditorState>(
            builder: (context, state) {
              if (state is! VideoEditorLoaded || state.clips.isEmpty) {
                return _EmptyPreview();
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  _VideoPlayer(),
                  _TextOverlaysLayer(),
                  _StickerOverlaysLayer(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.video_library,
                size: 40,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No video selected',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap below to add a video',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoEditorBloc, VideoEditorState>(
      builder: (context, state) {
        if (state is! VideoEditorLoaded || state.videoController == null) {
          return const SizedBox();
        }

        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: state.videoController!,
          builder: (context, value, child) {
            if (!value.isInitialized) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8A5CFF),
                  ),
                ),
              );
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: value.size.width,
                  height: value.size.height,
                  child: VideoPlayer(state.videoController!),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TextOverlaysLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoEditorBloc, VideoEditorState>(
      builder: (context, state) {
        if (state is! VideoEditorLoaded || state.selectedClip == null) {
          return const SizedBox();
        }

        final clip = state.selectedClip!;
        final currentPos = state.currentPositionMs - clip.startMs;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              children: clip.textOverlays
                  .where((overlay) =>
              currentPos >= overlay.startMs &&
                  currentPos <= overlay.startMs + overlay.durationMs)
                  .map((overlay) {
                final overlayIndex = clip.textOverlays.indexOf(overlay);
                return Positioned(
                  left: overlay.x * width - 100,
                  top: overlay.y * height - 50,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      final newX = (overlay.x + details.delta.dx / width)
                          .clamp(0.0, 1.0);
                      final newY = (overlay.y + details.delta.dy / height)
                          .clamp(0.0, 1.0);

                      context.read<VideoEditorBloc>().add(
                        UpdateTextOverlayEvent(
                          clipIndex: state.selectedClipIndex!,
                          overlayIndex: overlayIndex,
                          x: newX,
                          y: newY,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        overlay.text,
                        style: TextStyle(
                          color: Color(overlay.color),
                          fontSize: overlay.fontSize,
                          fontWeight: overlay.bold
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontStyle: overlay.italic
                              ? FontStyle.italic
                              : FontStyle.normal,
                          shadows: const [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _StickerOverlaysLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoEditorBloc, VideoEditorState>(
      builder: (context, state) {
        if (state is! VideoEditorLoaded || state.selectedClip == null) {
          return const SizedBox();
        }

        final clip = state.selectedClip!;
        final currentPos = state.currentPositionMs - clip.startMs;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              children: clip.stickerOverlays
                  .where((sticker) =>
              currentPos >= sticker.startMs &&
                  currentPos <= sticker.startMs + sticker.durationMs)
                  .map((sticker) {
                final stickerIndex = clip.stickerOverlays.indexOf(sticker);
                return Positioned(
                  left: sticker.x * width - 50 * sticker.scale,
                  top: sticker.y * height - 50 * sticker.scale,
                  child: Transform.rotate(
                    angle: sticker.rotation,
                    child: GestureDetector(
                      onScaleUpdate: (details) {
                        context.read<VideoEditorBloc>().add(
                          UpdateStickerOverlayEvent(
                            clipIndex: state.selectedClipIndex!,
                            overlayIndex: stickerIndex,
                            scale: (sticker.scale * details.scale)
                                .clamp(0.5, 3.0),
                            rotation: sticker.rotation + details.rotation,
                          ),
                        );
                      },
                      onPanUpdate: (details) {
                        final newX =
                        (sticker.x + details.delta.dx / width)
                            .clamp(0.0, 1.0);
                        final newY =
                        (sticker.y + details.delta.dy / height)
                            .clamp(0.0, 1.0);

                        context.read<VideoEditorBloc>().add(
                          UpdateStickerOverlayEvent(
                            clipIndex: state.selectedClipIndex!,
                            overlayIndex: stickerIndex,
                            x: newX,
                            y: newY,
                          ),
                        );
                      },
                      child: Container(
                        width: 100 * sticker.scale,
                        height: 100 * sticker.scale,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.emoji_emotions,
                          size: 50 * sticker.scale,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

// ==================== PLAYBACK CONTROLS (Below Video) ====================

class _PlaybackControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Play/Pause button
          BlocBuilder<VideoEditorBloc, VideoEditorState>(
            builder: (context, state) {
              final isPlaying =
              state is VideoEditorLoaded ? state.isPlaying : false;

              return IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () =>
                    context.read<VideoEditorBloc>().add(TogglePlayPauseEvent()),
              );
            },
          ),

          // Timecode
          SizedBox(
            width: 90,
            child: BlocBuilder<VideoEditorBloc, VideoEditorState>(
              builder: (context, state) {
                final currentMs = state is VideoEditorLoaded
                    ? state.currentPositionMs
                    : 0.0;
                final totalMs = state is VideoEditorLoaded
                    ? state.totalDurationMs
                    : 0.0;
                return Text(
                  '${_formatTime(currentMs / 1000)} / ${_formatTime(totalMs / 1000)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ),

          // Undo button
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white, size: 20),
            onPressed: null, // TODO: Implement undo
          ),

          // Redo button
          IconButton(
            icon: const Icon(Icons.redo, color: Colors.white, size: 20),
            onPressed: null, // TODO: Implement redo
          ),

          const Spacer(),

          // Timeline zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.white, size: 20),
            onPressed: () => context.read<VideoEditorBloc>().add(
              const ZoomTimelineEvent(zoomIn: false),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
            onPressed: () => context.read<VideoEditorBloc>().add(
              const ZoomTimelineEvent(zoomIn: true),
            ),
          ),

          // Crop/Fit toggle
          IconButton(
            icon: const Icon(Icons.crop, color: Colors.white, size: 20),
            onPressed: () {},
          ),

          // Volume control
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.white, size: 20),
            onPressed: () => _showVolumeControl(context),
          ),
        ],
      ),
    );
  }

  String _formatTime(double seconds) {
    final min = (seconds / 60).floor();
    final sec = (seconds % 60).floor();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _showVolumeControl(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Volume',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            BlocBuilder<VideoEditorBloc, VideoEditorState>(
              builder: (context, state) {
                double volume = 1.0;
                if (state is VideoEditorLoaded && state.selectedClip != null) {
                  volume = state.selectedClip!.volume;
                }

                return Column(
                  children: [
                    Text(
                      '${(volume * 100).toInt()}%',
                      style: const TextStyle(
                        color: Color(0xFF8A5CFF),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: volume,
                      min: 0.0,
                      max: 2.0,
                      activeColor: const Color(0xFF8A5CFF),
                      onChanged: (value) {
                        if (state is VideoEditorLoaded &&
                            state.selectedClipIndex != null) {
                          context.read<VideoEditorBloc>().add(
                            SetClipVolumeEvent(
                              state.selectedClipIndex!,
                              value,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== TIMELINE AREA ====================

class _TimelineArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: BlocBuilder<VideoEditorBloc, VideoEditorState>(
        builder: (context, state) {
          if (state is! VideoEditorLoaded || state.clips.isEmpty) {
            return Center(
              child: TextButton.icon(
                onPressed: () => _pickVideo(context),
                icon: const Icon(Icons.add, color: Color(0xFF8A5CFF)),
                label: const Text(
                  'Add Video',
                  style: TextStyle(color: Color(0xFF8A5CFF)),
                ),
              ),
            );
          }

          return Column(
            children: [
              // Playhead position indicator
              Container(
                height: 2,
                width: double.infinity,
                color: Colors.white.withOpacity(0.1),
                child: FractionallySizedBox(
                  widthFactor: state.currentPositionMs / state.totalDurationMs,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF8A5CFF),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF8A5CFF),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Timeline clips
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.clips.length + 1,
                  itemBuilder: (context, index) {
                    if (index == state.clips.length) {
                      return _AddClipButton();
                    }

                    final clip = state.clips[index];
                    final isSelected = state.selectedClipIndex == index;

                    return GestureDetector(
                      onTap: () {
                        context
                            .read<VideoEditorBloc>()
                            .add(SelectClipEvent(index));
                      },
                      onLongPress: () => _showClipOptions(context, index),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF8A5CFF).withOpacity(0.3)
                              : const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8A5CFF)
                                : Colors.white.withOpacity(0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: clip.thumbnails.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(clip.thumbnails.first),
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Center(
                          child: Icon(
                            Icons.videocam,
                            color: Colors.white38,
                            size: 32,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickVideo(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        context.read<VideoEditorBloc>().add(LoadVideoEvent(file));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick video: $e')),
      );
    }
  }

  void _showClipOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.content_cut, color: Color(0xFF8A5CFF)),
            title: const Text('Split', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              final bloc = context.read<VideoEditorBloc>();
              if (bloc.state is VideoEditorLoaded) {
                bloc.add(SplitClipEvent(
                  index,
                  (bloc.state as VideoEditorLoaded).currentPositionMs,
                ));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.content_copy, color: Color(0xFF8A5CFF)),
            title:
            const Text('Duplicate', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              context.read<VideoEditorBloc>().add(DuplicateClipEvent(index));
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              context.read<VideoEditorBloc>().add(RemoveClipEvent(index));
            },
          ),
        ],
      ),
    );
  }
}

class _AddClipButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.video,
        );
        if (result != null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          context.read<VideoEditorBloc>().add(AddVideoClipEvent(file));
        }
      },
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF8A5CFF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF8A5CFF).withOpacity(0.5),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            color: Color(0xFF8A5CFF),
            size: 32,
          ),
        ),
      ),
    );
  }
}

// ==================== BOTTOM TOOLBAR ====================

class _BottomToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tools = [
      {'icon': Icons.content_cut, 'label': 'Edit'},
      {'icon': Icons.headphones, 'label': 'Audio'},
      {'icon': Icons.text_fields, 'label': 'Text'},
      {'icon': Icons.emoji_emotions, 'label': 'Stickers'},
      {'icon': Icons.auto_awesome, 'label': 'Effects'},
      {'icon': Icons.layers, 'label': 'More'},
    ];

    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tools.map((tool) {
          return _BottomToolButton(
            icon: tool['icon'] as IconData,
            label: tool['label'] as String,
            onTap: () => _handleToolTap(context, tool['label'] as String),
          );
        }).toList(),
      ),
    );
  }

  void _handleToolTap(BuildContext context, String label) {
    final bloc = context.read<VideoEditorBloc>();
    final state = bloc.state;

    if (state is! VideoEditorLoaded || state.clips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a video first')),
      );
      return;
    }

    switch (label) {
      case 'Edit':
        _showEditTools(context);
        break;
      case 'Audio':
        _showAudioTools(context);
        break;
      case 'Text':
        _showTextDialog(context);
        break;
      case 'Stickers':
        _showStickersDialog(context);
        break;
      case 'Effects':
        _showEffectsDialog(context);
        break;
      case 'More':
        _showMoreOptions(context);
        break;
    }
  }

  void _showEditTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Edit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _EditToolItem(
                    icon: Icons.content_cut,
                    label: 'Split',
                    onTap: () {
                      Navigator.pop(context);
                      final bloc = context.read<VideoEditorBloc>();
                      if (bloc.state is VideoEditorLoaded) {
                        final state = bloc.state as VideoEditorLoaded;
                        if (state.selectedClipIndex != null) {
                          bloc.add(SplitClipEvent(
                            state.selectedClipIndex!,
                            state.currentPositionMs,
                          ));
                        }
                      }
                    },
                  ),
                  _EditToolItem(
                    icon: Icons.crop,
                    label: 'Trim',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Trim: Select start and end points')),
                      );
                    },
                  ),
                  _EditToolItem(
                    icon: Icons.speed,
                    label: 'Speed',
                    onTap: () {
                      Navigator.pop(context);
                      _showSpeedDialog(context);
                    },
                  ),
                  _EditToolItem(
                    icon: Icons.flip,
                    label: 'Flip',
                    onTap: () {
                      Navigator.pop(context);
                      final bloc = context.read<VideoEditorBloc>();
                      if (bloc.state is VideoEditorLoaded) {
                        final state = bloc.state as VideoEditorLoaded;
                        if (state.selectedClipIndex != null) {
                          bloc.add(FlipClipEvent(state.selectedClipIndex!));
                        }
                      }
                    },
                  ),
                  _EditToolItem(
                    icon: Icons.rotate_90_degrees_ccw,
                    label: 'Rotate',
                    onTap: () {
                      Navigator.pop(context);
                      final bloc = context.read<VideoEditorBloc>();
                      if (bloc.state is VideoEditorLoaded) {
                        final state = bloc.state as VideoEditorLoaded;
                        if (state.selectedClipIndex != null) {
                          bloc.add(RotateClipEvent(state.selectedClipIndex!, 90));
                        }
                      }
                    },
                  ),
                  _EditToolItem(
                    icon: Icons.content_copy,
                    label: 'Duplicate',
                    onTap: () {
                      Navigator.pop(context);
                      final bloc = context.read<VideoEditorBloc>();
                      if (bloc.state is VideoEditorLoaded) {
                        final state = bloc.state as VideoEditorLoaded;
                        if (state.selectedClipIndex != null) {
                          bloc.add(DuplicateClipEvent(state.selectedClipIndex!));
                        }
                      }
                    },
                  ),
                  _EditToolItem(
                    icon: Icons.delete,
                    label: 'Delete',
                    onTap: () {
                      Navigator.pop(context);
                      final bloc = context.read<VideoEditorBloc>();
                      if (bloc.state is VideoEditorLoaded) {
                        final state = bloc.state as VideoEditorLoaded;
                        if (state.selectedClipIndex != null) {
                          bloc.add(RemoveClipEvent(state.selectedClipIndex!));
                        }
                      }
                    },
                  ),
                  _EditToolItem(
                    icon: Icons.animation,
                    label: 'Animation',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Animation coming soon')),
                      );
                    },
                  ),
                  _EditToolItem(
                    icon: Icons.colorize,
                    label: 'Chroma Key',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chroma Key: Green screen removal')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAudioTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Audio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _AudioOptionTile(
                    icon: Icons.music_note,
                    title: 'Add Music',
                    subtitle: 'Background music library',
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.audio,
                      );
                      if (result != null && result.files.single.path != null) {
                        final file = File(result.files.single.path!);
                        context
                            .read<VideoEditorBloc>()
                            .add(AddBackgroundMusicEvent(file));
                      }
                    },
                  ),
                  _AudioOptionTile(
                    icon: Icons.mic,
                    title: 'Voice Over',
                    subtitle: 'Record narration',
                    onTap: () {
                      Navigator.pop(context);
                      context.read<VideoEditorBloc>().add(StartVoiceRecordingEvent());
                      _showRecordingDialog(context);
                    },
                  ),
                  _AudioOptionTile(
                    icon: Icons.volume_off,
                    title: 'Noise Reduction',
                    subtitle: 'Remove background noise',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Noise reduction applied')),
                      );
                    },
                  ),
                  _AudioOptionTile(
                    icon: Icons.graphic_eq,
                    title: 'Sound Effects',
                    subtitle: 'Add audio effects',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sound effects library')),
                      );
                    },
                  ),
                  _AudioOptionTile(
                    icon: Icons.voice_chat,
                    title: 'Voice Effects',
                    subtitle: 'Change voice style',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Voice effects: Robot, Deep, etc.')),
                      );
                    },
                  ),
                  _AudioOptionTile(
                    icon: Icons.audiotrack,
                    title: 'Extract Audio',
                    subtitle: 'Extract audio from video',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Audio extracted')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextDialog(BuildContext context) {
    final textController = TextEditingController();
    double fontSize = 32;
    Color textColor = Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Text',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF8A5CFF)),
                    onPressed: () {
                      if (textController.text.isEmpty) return;
                      final bloc = context.read<VideoEditorBloc>();
                      if (bloc.state is VideoEditorLoaded) {
                        final state = bloc.state as VideoEditorLoaded;
                        if (state.selectedClipIndex != null) {
                          bloc.add(
                            AddTextOverlayEvent(
                              clipIndex: state.selectedClipIndex!,
                              text: textController.text,
                              startMs: state.currentPositionMs,
                              durationMs: 5000,
                              fontSize: fontSize,
                              color: textColor.value,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter your text',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Text Styles',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _TextStyleOption('Default', Colors.white),
                    _TextStyleOption('Bold', Colors.white),
                    _TextStyleOption('Neon', const Color(0xFF00FFF0)),
                    _TextStyleOption('Shadow', Colors.white),
                    _TextStyleOption('Outline', Colors.white),
                    _TextStyleOption('3D', Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'Font Size',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    '${fontSize.toInt()}',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ),
              Slider(
                value: fontSize,
                min: 16,
                max: 72,
                activeColor: const Color(0xFF8A5CFF),
                onChanged: (value) => setState(() => fontSize = value),
              ),
              const SizedBox(height: 16),
              const Text(
                'Color',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Colors.white,
                  Colors.black,
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  const Color(0xFF8A5CFF),
                  Colors.pink,
                ].map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => textColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: textColor == color
                              ? const Color(0xFF8A5CFF)
                              : Colors.white24,
                          width: textColor == color ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStickersDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Stickers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Tabs
            Row(
              children: [
                _StickerTab('Recents', true),
                _StickerTab('Favorite', false),
                _StickerTab('GIF', false),
                _StickerTab('Trending', false),
                _StickerTab('Birthday', false),
              ],
            ),
            const SizedBox(height: 16),
            // Search bar
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search shapes',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Sticker grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      final bloc = context.read<VideoEditorBloc>();
                      if (bloc.state is VideoEditorLoaded) {
                        final state = bloc.state as VideoEditorLoaded;
                        if (state.selectedClipIndex != null) {
                          bloc.add(
                            AddStickerOverlayEvent(
                              clipIndex: state.selectedClipIndex!,
                              assetPath: 'sticker_$index',
                              startMs: state.currentPositionMs,
                              durationMs: 5000,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getStickerIcon(index),
                            color: Colors.white70,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Animation',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEffectsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Effects',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _EffectOption('None', Icons.block),
                  _EffectOption('B&W', Icons.filter_b_and_w),
                  _EffectOption('Sepia', Icons.filter_vintage),
                  _EffectOption('Vintage', Icons.filter),
                  _EffectOption('Blur', Icons.blur_on),
                  _EffectOption('Sharpen', Icons.auto_fix_high),
                  _EffectOption('Cinematic', Icons.movie_filter),
                  _EffectOption('Warm', Icons.wb_sunny),
                  _EffectOption('Cool', Icons.ac_unit),
                ].map((child) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      final bloc = context.read<VideoEditorBloc>();
                      if (bloc.state is VideoEditorLoaded) {
                        final state = bloc.state as VideoEditorLoaded;
                        if (state.selectedClipIndex != null) {
                          bloc.add(
                            ApplyFilterEvent(
                              state.selectedClipIndex!,
                              (child as _EffectOption).label,
                            ),
                          );
                        }
                      }
                    },
                    child: child,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.picture_in_picture, color: Color(0xFF8A5CFF)),
            title: const Text('PIP', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Picture in Picture', style: TextStyle(color: Colors.white60)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIP feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: Color(0xFF8A5CFF)),
            title: const Text('Transitions', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Add transition effects', style: TextStyle(color: Colors.white60)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transitions: Fade, Slide, Zoom')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.subtitles, color: Color(0xFF8A5CFF)),
            title: const Text('Subtitles', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Auto-generate captions', style: TextStyle(color: Colors.white60)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Auto-subtitles feature')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSpeedDialog(BuildContext context) {
    double speed = 1.0;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Speed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${speed.toStringAsFixed(2)}x',
                style: const TextStyle(
                  color: Color(0xFF8A5CFF),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Slider(
                value: speed,
                min: 0.25,
                max: 4.0,
                divisions: 15,
                activeColor: const Color(0xFF8A5CFF),
                onChanged: (value) => setState(() => speed = value),
                onChangeEnd: (value) {
                  final bloc = context.read<VideoEditorBloc>();
                  if (bloc.state is VideoEditorLoaded) {
                    final state = bloc.state as VideoEditorLoaded;
                    if (state.selectedClipIndex != null) {
                      bloc.add(SetClipSpeedEvent(state.selectedClipIndex!, value));
                    }
                  }
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('0.25x', style: TextStyle(color: Colors.white60)),
                  Text('4.0x', style: TextStyle(color: Colors.white60)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Recording...', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.mic, color: Color(0xFF8A5CFF), size: 64),
            SizedBox(height: 16),
            Text(
              'Tap stop when finished',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<VideoEditorBloc>().add(StopVoiceRecordingEvent());
              Navigator.pop(context);
            },
            child: const Text(
              'Stop',
              style: TextStyle(color: Color(0xFF8A5CFF)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStickerIcon(int index) {
    final icons = [
      Icons.emoji_emotions,
      Icons.favorite,
      Icons.star,
      Icons.pets,
      Icons.eco,
      Icons.local_fire_department,
      Icons.wb_sunny,
      Icons.ac_unit,
      Icons.flash_on,
      Icons.celebration,
      Icons.cake,
      Icons.auto_awesome,
    ];
    return icons[index % icons.length];
  }
}

class _BottomToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditToolItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EditToolItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AudioOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AudioOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF8A5CFF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF8A5CFF)),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: onTap,
    );
  }
}

class _TextStyleOption extends StatelessWidget {
  final String label;
  final Color color;

  const _TextStyleOption(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Aa',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerTab extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _StickerTab(this.label, this.isSelected);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF8A5CFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _EffectOption extends StatelessWidget {
  final String label;
  final IconData icon;

  const _EffectOption(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 36),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}