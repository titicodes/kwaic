// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:undo/undo.dart';
// import 'package:video_player/video_player.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:path_provider/path_provider.dart';
//
// import 'kawcut_controller.dart';
//
// class VideoEditorScreen extends StatelessWidget {
//   final ctrl = Get.put(EditorController());
//   final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
//
//   VideoEditorScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Column(
//           children: [
//             _topBar(),
//             Expanded(child: _previewWithOverlays()),
//             _multiTrackTimeline(),
//             _bottomToolbar(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ─────────────────────── TOP BAR ───────────────────────
//   Widget _topBar() {
//     return Container(
//       height: 56,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       decoration: const BoxDecoration(
//         color: Color(0xFF1C1C1E),
//         border: Border(bottom: BorderSide(color: Color(0xFF2C2C2E), width: 1)),
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.close, color: Colors.white),
//             onPressed: () => Get.back(),
//             tooltip: 'Close',
//           ),
//           IconButton(
//             icon: const Icon(Icons.undo, color: Colors.white),
//             onPressed: ctrl.canUndo ? ctrl.undo : null,
//             tooltip: 'Undo',
//           ),
//           IconButton(
//             icon: const Icon(Icons.redo, color: Colors.white),
//             onPressed: ctrl.canRedo ? ctrl.redo : null,
//             tooltip: 'Redo',
//           ),
//           const Spacer(),
//           IconButton(
//             icon: const Icon(Icons.settings, color: Colors.white),
//             onPressed: _showProjectSettings,
//             tooltip: 'Settings',
//           ),
//           const SizedBox(width: 8),
//           Obx(
//             () =>
//                 ctrl.exporting.value
//                     ? const SizedBox(
//                       width: 90,
//                       height: 36,
//                       child: Center(
//                         child: SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     )
//                     : ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF0A84FF),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 10,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       onPressed: () async {
//                         final out = await ctrl.exportProject();
//                         if (out != null) {
//                           Get.snackbar(
//                             'Success',
//                             'Video exported successfully!',
//                             snackPosition: SnackPosition.BOTTOM,
//                             backgroundColor: Colors.green,
//                             colorText: Colors.white,
//                           );
//                         }
//                       },
//                       icon: const Icon(Icons.file_download, size: 18),
//                       label: const Text(
//                         'Export',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ─────────────────────── PREVIEW WITH OVERLAYS ───────────────────────
//   Widget _previewWithOverlays() {
//     return Container(
//       color: Colors.black,
//       child: Center(
//         child: AspectRatio(
//           aspectRatio: 9 / 16,
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               final w = constraints.maxWidth;
//               final h = constraints.maxHeight;
//               return Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   // Video player
//                   if (ctrl.player != null)
//                     ValueListenableBuilder<VideoPlayerValue>(
//                       valueListenable: ctrl.player!,
//                       builder: (_, value, __) {
//                         if (!value.isInitialized) {
//                           return Container(
//                             color: const Color(0xFF1C1C1E),
//                             child: const Center(
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Icon(
//                                     Icons.video_library,
//                                     size: 64,
//                                     color: Colors.grey,
//                                   ),
//                                   SizedBox(height: 16),
//                                   Text(
//                                     'Loading video...',
//                                     style: TextStyle(color: Colors.grey),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         }
//                         return FittedBox(
//                           fit: BoxFit.contain,
//                           child: SizedBox(
//                             width: value.size.width,
//                             height: value.size.height,
//                             child: VideoPlayer(ctrl.player!),
//                           ),
//                         );
//                       },
//                     )
//                   else
//                     Container(
//                       color: const Color(0xFF1C1C1E),
//                       child: Center(
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const Icon(
//                               Icons.add_photo_alternate,
//                               size: 64,
//                               color: Colors.grey,
//                             ),
//                             const SizedBox(height: 16),
//                             ElevatedButton.icon(
//                               onPressed: ctrl.pickVideo,
//                               icon: const Icon(Icons.add),
//                               label: const Text('Add Video'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFF0A84FF),
//                                 foregroundColor: Colors.white,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//
//                   // Text overlays
//                   Obx(() {
//                     final idx = ctrl.selectedIndex.value;
//                     if (idx < 0 || idx >= ctrl.clips.length) {
//                       return const SizedBox();
//                     }
//                     final clip = ctrl.clips[idx];
//                     final pos = ctrl.currentMs.value - clip.startMs;
//                     return _buildTextOverlays(pos, clip, w, h);
//                   }),
//
//                   // Sticker overlays
//                   Obx(() {
//                     final idx = ctrl.selectedIndex.value;
//                     if (idx < 0 || idx >= ctrl.clips.length) {
//                       return const SizedBox();
//                     }
//                     final clip = ctrl.clips[idx];
//                     final pos = ctrl.currentMs.value - clip.startMs;
//                     return _buildStickerOverlays(pos, clip, w, h);
//                   }),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextOverlays(double pos, ClipModel clip, double w, double h) {
//     return Stack(
//       children:
//           clip.textOverlays
//               .where(
//                 (ov) => pos >= ov.startMs && pos <= ov.startMs + ov.durationMs,
//               )
//               .map(
//                 (ov) => Positioned(
//                   left: ov.x * w - 100,
//                   top: ov.y * h - 50,
//                   child: Text(
//                     ov.text,
//                     style: TextStyle(
//                       color: Color(ov.color),
//                       fontSize: ov.fontSize,
//                       fontWeight: FontWeight.bold,
//                       shadows: const [
//                         Shadow(
//                           blurRadius: 4,
//                           color: Colors.black,
//                           offset: Offset(2, 2),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               )
//               .toList(),
//     );
//   }
//
//   Widget _buildStickerOverlays(double pos, ClipModel clip, double w, double h) {
//     return Stack(
//       children:
//           clip.stickerOverlays
//               .where(
//                 (st) => pos >= st.startMs && pos <= st.startMs + st.durationMs,
//               )
//               .map(
//                 (st) => Positioned(
//                   left: st.x * w - 50 * st.scale,
//                   top: st.y * h - 50 * st.scale,
//                   child: Transform.rotate(
//                     angle: st.rotation,
//                     child: GestureDetector(
//                       onScaleUpdate: (d) {
//                         st.scale = (st.scale * d.scale).clamp(0.5, 3.0);
//                         st.rotation += d.rotation;
//                         ctrl.clips.refresh();
//                       },
//                       onPanUpdate: (d) {
//                         st.x += d.delta.dx / w;
//                         st.y += d.delta.dy / h;
//                         st.x = st.x.clamp(0.0, 1.0);
//                         st.y = st.y.clamp(0.0, 1.0);
//                         ctrl.clips.refresh();
//                       },
//                       child: Container(
//                         width: 100 * st.scale,
//                         height: 100 * st.scale,
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.white24),
//                           image: DecorationImage(
//                             image: AssetImage(st.assetPath),
//                             fit: BoxFit.contain,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               )
//               .toList(),
//     );
//   }
//
//   // ─────────────────────── MULTI-TRACK TIMELINE (KaiCut Style) ───────────────────────
//   Widget _multiTrackTimeline() {
//     return Container(
//       height: 220,
//       color: const Color(0xFF1C1C1E),
//       child: Column(
//         children: [
//           _playbackControls(),
//           const Divider(height: 1, thickness: 1, color: Color(0xFF2C2C2E)),
//           Expanded(child: _timelineWithTracks()),
//         ],
//       ),
//     );
//   }
//
//   // ───── PLAYBACK CONTROLS ─────
//   Widget _playbackControls() {
//     return Container(
//       height: 60,
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       child: Row(
//         children: [
//           // Time code
//           SizedBox(
//             width: 70,
//             child: Obx(
//               () => Text(
//                 _format(ctrl.currentMs.value / 1000),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 13,
//                   fontFamily: 'monospace',
//                 ),
//               ),
//             ),
//           ),
//
//           // Zoom controls
//           IconButton(
//             icon: const Icon(Icons.remove, color: Colors.white, size: 20),
//             onPressed: ctrl.zoomOut,
//             tooltip: 'Zoom Out',
//           ),
//           IconButton(
//             icon: const Icon(Icons.add, color: Colors.white, size: 20),
//             onPressed: ctrl.zoomIn,
//             tooltip: 'Zoom In',
//           ),
//
//           // Slider
//           Expanded(
//             child: Obx(() {
//               if (ctrl.clips.isEmpty) {
//                 return Slider(
//                   value: 0,
//                   max: 1,
//                   onChanged: null,
//                   activeColor: const Color(0xFF0A84FF),
//                 );
//               }
//
//               final total =
//                   ctrl.clips.fold<double>(
//                     0,
//                     (p, c) => p + (c.endMs - c.startMs),
//                   ) /
//                   1000;
//
//               final value =
//                   (ctrl.currentMs.value / 1000).clamp(0.0, total).toDouble();
//
//               return SliderTheme(
//                 data: SliderThemeData(
//                   trackHeight: 4,
//                   thumbShape: const RoundSliderThumbShape(
//                     enabledThumbRadius: 8,
//                   ),
//                   overlayShape: const RoundSliderOverlayShape(
//                     overlayRadius: 16,
//                   ),
//                 ),
//                 child: Slider(
//                   value: value,
//                   max: total,
//                   activeColor: const Color(0xFF0A84FF),
//                   inactiveColor: const Color(0xFF3A3A3C),
//                   onChanged: (v) => ctrl.seekToMs(v * 1000),
//                 ),
//               );
//             }),
//           ),
//
//           // Play/Pause
//           Obx(
//             () => Container(
//               decoration: BoxDecoration(
//                 color: const Color(0xFF0A84FF),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: IconButton(
//                 icon: Icon(
//                   ctrl.isPlaying.value ? Icons.pause : Icons.play_arrow,
//                   color: Colors.white,
//                 ),
//                 onPressed: ctrl.togglePlayPause,
//                 tooltip: ctrl.isPlaying.value ? 'Pause' : 'Play',
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ───── TIMELINE WITH TRACKS (Like KaiCut) ─────
//   Widget _timelineWithTracks() {
//     return Obx(() {
//       if (ctrl.clips.isEmpty) {
//         return Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.video_library, color: Colors.grey, size: 48),
//               const SizedBox(height: 12),
//               ElevatedButton.icon(
//                 onPressed: ctrl.pickVideo,
//                 icon: const Icon(Icons.add),
//                 label: const Text('Add Video'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF0A84FF),
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 24,
//                     vertical: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       }
//
//       final totalDuration = ctrl.clips.fold<double>(
//         0,
//         (p, c) => p + (c.endMs - c.startMs),
//       );
//
//       if (totalDuration == 0) return const SizedBox();
//
//       return LayoutBuilder(
//         builder: (context, constraints) {
//           final playheadPos = (ctrl.currentMs.value / totalDuration).clamp(
//             0.0,
//             1.0,
//           );
//           final playheadLeft = playheadPos * constraints.maxWidth;
//
//           return Stack(
//             children: [
//               // Scrollable timeline
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 controller: ctrl.timelineScrollController,
//                 child: SizedBox(
//                   width: totalDuration * ctrl.pixelsPerSecond.value / 1000,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Time ruler
//                       _buildTimeRuler(totalDuration),
//                       const SizedBox(height: 4),
//
//                       // Video track
//                       _buildVideoTrack(),
//
//                       const SizedBox(height: 4),
//
//                       // Audio track
//                       _buildAudioTrack(),
//                     ],
//                   ),
//                 ),
//               ),
//
//               // Playhead indicator
//               Positioned(
//                 left: playheadLeft - 1,
//                 top: 0,
//                 bottom: 0,
//                 child: Container(
//                   width: 2,
//                   color: const Color(0xFF0A84FF),
//                   child: Column(
//                     children: [
//                       Container(
//                         width: 12,
//                         height: 12,
//                         decoration: const BoxDecoration(
//                           color: Color(0xFF0A84FF),
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       );
//     });
//   }
//
//   Widget _buildTimeRuler(double totalDuration) {
//     final seconds = (totalDuration / 1000).ceil();
//     return Container(
//       height: 24,
//       color: const Color(0xFF2C2C2E),
//       child: Obx(() {
//         final pps = ctrl.pixelsPerSecond.value;
//         return Row(
//           children: List.generate(
//             seconds + 1,
//             (i) => Container(
//               width: pps,
//               padding: const EdgeInsets.only(left: 4),
//               child: Text(
//                 '${i}s',
//                 style: const TextStyle(color: Colors.white60, fontSize: 10),
//               ),
//             ),
//           ),
//         );
//       }),
//     );
//   }
//
//   Widget _buildVideoTrack() {
//     return Container(
//       height: 70,
//       decoration: BoxDecoration(
//         color: const Color(0xFF2C2C2E),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Obx(() {
//         double cumulativeStart = 0;
//         return Stack(
//           children: [
//             ...ctrl.clips.asMap().entries.map((entry) {
//               final i = entry.key;
//               final clip = entry.value;
//               final isSel = ctrl.selectedIndex.value == i;
//               final duration = clip.endMs - clip.startMs;
//               final width = duration * ctrl.pixelsPerSecond.value / 1000;
//
//               final left = cumulativeStart;
//               cumulativeStart += width;
//
//               return Positioned(
//                 left: left,
//                 top: 4,
//                 child: GestureDetector(
//                   onTap: () {
//                     ctrl.selectedIndex.value = i;
//                     ctrl.loadSelectedToPlayer();
//                   },
//                   onLongPress: () => _showClipOptions(i),
//                   child: Container(
//                     width: width.clamp(60.0, double.infinity),
//                     height: 62,
//                     margin: const EdgeInsets.only(right: 2),
//                     decoration: BoxDecoration(
//                       color:
//                           isSel
//                               ? const Color(0xFF0A84FF)
//                               : const Color(0xFF3A3A3C),
//                       borderRadius: BorderRadius.circular(6),
//                       border: Border.all(
//                         color:
//                             isSel
//                                 ? const Color(0xFF0A84FF)
//                                 : const Color(0xFF48484A),
//                         width: isSel ? 3 : 1,
//                       ),
//                       boxShadow:
//                           isSel
//                               ? [
//                                 BoxShadow(
//                                   color: const Color(
//                                     0xFF0A84FF,
//                                   ).withOpacity(0.5),
//                                   blurRadius: 8,
//                                   spreadRadius: 2,
//                                 ),
//                               ]
//                               : null,
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(4),
//                       child:
//                           clip.thumbs.isNotEmpty
//                               ? Row(
//                                 children:
//                                     clip.thumbs
//                                         .take(6)
//                                         .map(
//                                           (thumb) => Expanded(
//                                             child: Image.file(
//                                               File(thumb),
//                                               fit: BoxFit.cover,
//                                             ),
//                                           ),
//                                         )
//                                         .toList(),
//                               )
//                               : const Center(
//                                 child: Icon(
//                                   Icons.videocam,
//                                   color: Colors.white70,
//                                   size: 32,
//                                 ),
//                               ),
//                     ),
//                   ),
//                 ),
//               );
//             }).toList(),
//
//             // Add video button at the end
//             Positioned(
//               left: cumulativeStart + 8,
//               top: 4,
//               child: GestureDetector(
//                 onTap: ctrl.pickVideo,
//                 child: Container(
//                   width: 62,
//                   height: 62,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF0A84FF),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: const Icon(Icons.add, color: Colors.white, size: 32),
//                 ),
//               ),
//             ),
//           ],
//         );
//       }),
//     );
//   }
//
//   Widget _buildAudioTrack() {
//     return Container(
//       height: 40,
//       decoration: BoxDecoration(
//         color: const Color(0xFF2C2C2E),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Obx(() {
//         if (ctrl.bgMusicPath == null &&
//             ctrl.voiceoverPath == null &&
//             ctrl.ttsPath == null) {
//           return Center(
//             child: TextButton.icon(
//               onPressed: _showAudioOptions,
//               icon: const Icon(Icons.music_note, color: Colors.white60),
//               label: const Text(
//                 'Add Audio',
//                 style: TextStyle(color: Colors.white60, fontSize: 12),
//               ),
//             ),
//           );
//         }
//
//         return Stack(
//           children: [
//             if (ctrl.bgMusicPath != null)
//               Positioned(
//                 left: 4,
//                 top: 4,
//                 bottom: 4,
//                 width: 100,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF30D158),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: const Center(
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.music_note, color: Colors.white, size: 16),
//                         SizedBox(width: 4),
//                         Text(
//                           'Music',
//                           style: TextStyle(color: Colors.white, fontSize: 10),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         );
//       }),
//     );
//   }
//
//   // ─────────────────────── BOTTOM TOOLBAR ───────────────────────
//   Widget _bottomToolbar() {
//     final tabs = [
//       {'icon': Icons.content_cut, 'label': 'Trim', 'page': _editTab()},
//       {'icon': Icons.music_note, 'label': 'Audio', 'page': _audioTab()},
//       {'icon': Icons.text_fields, 'label': 'Text', 'page': _textTab()},
//       {'icon': Icons.emoji_emotions, 'label': 'Sticker', 'page': _stickerTab()},
//       {'icon': Icons.auto_awesome, 'label': 'Effect', 'page': _effectTab()},
//       {'icon': Icons.picture_in_picture, 'label': 'PIP', 'page': _pipTab()},
//     ];
//
//     return Container(
//       height: 180,
//       decoration: const BoxDecoration(
//         color: Color(0xFF1C1C1E),
//         border: Border(top: BorderSide(color: Color(0xFF2C2C2E), width: 1)),
//       ),
//       child: Column(
//         children: [
//           // Tab bar
//           Container(
//             height: 60,
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: Obx(
//               () => Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children:
//                     tabs.asMap().entries.map((e) {
//                       final i = e.key;
//                       final t = e.value;
//                       final sel = ctrl.selectedToolTab.value == i;
//                       return Expanded(
//                         child: GestureDetector(
//                           onTap: () => ctrl.selectedToolTab.value = i,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               border: Border(
//                                 bottom: BorderSide(
//                                   color:
//                                       sel
//                                           ? const Color(0xFF0A84FF)
//                                           : Colors.transparent,
//                                   width: 2,
//                                 ),
//                               ),
//                             ),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   t['icon'] as IconData,
//                                   color:
//                                       sel
//                                           ? const Color(0xFF0A84FF)
//                                           : Colors.white60,
//                                   size: 24,
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   t['label'] as String,
//                                   style: TextStyle(
//                                     color:
//                                         sel
//                                             ? const Color(0xFF0A84FF)
//                                             : Colors.white60,
//                                     fontSize: 11,
//                                     fontWeight:
//                                         sel
//                                             ? FontWeight.w600
//                                             : FontWeight.normal,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     }).toList(),
//               ),
//             ),
//           ),
//           // Tab content
//           Expanded(
//             child: Obx(
//               () => tabs[ctrl.selectedToolTab.value]['page'] as Widget,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ───── EDIT TAB ─────
//   Widget _editTab() {
//     final tools = [
//       {
//         'icon': Icons.content_cut,
//         'label': 'Split',
//         'onTap': _wrap(ctrl.splitClip),
//       },
//       {'icon': Icons.crop, 'label': 'Trim', 'onTap': _showTrimModal},
//       {'icon': Icons.delete, 'label': 'Delete', 'onTap': _wrap(_deleteClip)},
//       {'icon': Icons.speed, 'label': 'Speed', 'onTap': _showSpeedModal},
//       {'icon': Icons.volume_up, 'label': 'Volume', 'onTap': _showVolumeModal},
//       {
//         'icon': Icons.flip,
//         'label': 'Flip',
//         'onTap': _wrap(ctrl.toggleFlipHorizontal),
//       },
//       {
//         'icon': Icons.content_copy,
//         'label': 'Duplicate',
//         'onTap': _wrap(_duplicateClip),
//       },
//       {
//         'icon': Icons.rotate_90_degrees_ccw,
//         'label': 'Rotate',
//         'onTap': _wrap(() => ctrl.rotateClip(90)),
//       },
//       {
//         'icon': Icons.swap_horiz,
//         'label': 'Transition',
//         'onTap': _showTransitionModal,
//       },
//     ];
//
//     return GridView.builder(
//       padding: const EdgeInsets.all(12),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 4,
//         childAspectRatio: 1.2,
//         crossAxisSpacing: 8,
//         mainAxisSpacing: 8,
//       ),
//       itemCount: tools.length,
//       itemBuilder:
//           (_, i) => _toolButton(
//             icon: tools[i]['icon'] as IconData,
//             label: tools[i]['label'] as String,
//             onTap: tools[i]['onTap'] as VoidCallback,
//           ),
//     );
//   }
//
//   Widget _toolButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: const Color(0xFF2C2C2E),
//           borderRadius: BorderRadius.circular(8),
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
//
//   // ───── AUDIO TAB ─────
//   Widget _audioTab() {
//     return ListView(
//       padding: const EdgeInsets.all(12),
//       children: [
//         _audioOption(
//           icon: Icons.music_note,
//           title: 'Background Music',
//           subtitle: 'Add music to your video',
//           onTap: ctrl.pickBackgroundMusic,
//         ),
//         _audioOption(
//           icon: Icons.mic,
//           title: 'Voice Over',
//           subtitle: 'Record voice narration',
//           onTap: _startVoiceover,
//         ),
//         _audioOption(
//           icon: Icons.record_voice_over,
//           title: 'Text to Speech',
//           subtitle: 'Convert text to voice',
//           onTap: _showTTSDialog,
//         ),
//         _audioOption(
//           icon: Icons.graphic_eq,
//           title: 'Audio Effects',
//           subtitle: 'Apply audio filters',
//           onTap: () => Get.snackbar('Coming Soon', 'Audio effects'),
//         ),
//       ],
//     );
//   }
//
//   Widget _audioOption({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       color: const Color(0xFF2C2C2E),
//       margin: const EdgeInsets.only(bottom: 8),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: const Color(0xFF0A84FF).withOpacity(0.2),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: const Color(0xFF0A84FF)),
//         ),
//         title: Text(title, style: const TextStyle(color: Colors.white)),
//         subtitle: Text(
//           subtitle,
//           style: const TextStyle(color: Colors.white60, fontSize: 12),
//         ),
//         trailing: const Icon(Icons.chevron_right, color: Colors.white60),
//         onTap: onTap,
//       ),
//     );
//   }
//
//   // ───── TEXT TAB ─────
//   Widget _textTab() {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: ElevatedButton.icon(
//             onPressed: _showAddTextDialog,
//             icon: const Icon(Icons.add),
//             label: const Text('Add Text'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF0A84FF),
//               foregroundColor: Colors.white,
//               minimumSize: const Size(double.infinity, 44),
//             ),
//           ),
//         ),
//         Expanded(
//           child: GridView.builder(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               childAspectRatio: 1.2,
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//             ),
//             itemCount: 9,
//             itemBuilder: (_, i) {
//               final styles = [
//                 'Default',
//                 'Bold',
//                 'Italic',
//                 'Outline',
//                 'Shadow',
//                 'Neon',
//                 '3D',
//                 'Typewriter',
//                 'Glitch',
//               ];
//               return _toolButton(
//                 icon: Icons.text_fields,
//                 label: styles[i],
//                 onTap: () => _applyTextStyle(styles[i]),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ───── STICKER TAB ─────
//   Widget _stickerTab() {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: TextField(
//             style: const TextStyle(color: Colors.white),
//             decoration: InputDecoration(
//               hintText: 'Search stickers',
//               hintStyle: const TextStyle(color: Colors.white60),
//               prefixIcon: const Icon(Icons.search, color: Colors.white60),
//               filled: true,
//               fillColor: const Color(0xFF2C2C2E),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide.none,
//               ),
//             ),
//           ),
//         ),
//         Expanded(
//           child: GridView.builder(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 4,
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//             ),
//             itemCount: 12,
//             itemBuilder:
//                 (_, i) => GestureDetector(
//                   onTap: () => _addSticker(i),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF2C2C2E),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: const Color(0xFF3A3A3C)),
//                     ),
//                     child: const Center(
//                       child: Icon(
//                         Icons.emoji_emotions,
//                         color: Colors.white60,
//                         size: 32,
//                       ),
//                     ),
//                   ),
//                 ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ───── EFFECT TAB ─────
//   Widget _effectTab() {
//     final effects = [
//       'None',
//       'Black & White',
//       'Sepia',
//       'Vintage',
//       'Blur',
//       'Sharpen',
//       'Brightness',
//       'Contrast',
//       'Saturation',
//     ];
//     return GridView.builder(
//       padding: const EdgeInsets.all(12),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         childAspectRatio: 1.2,
//         crossAxisSpacing: 8,
//         mainAxisSpacing: 8,
//       ),
//       itemCount: effects.length,
//       itemBuilder:
//           (_, i) => _toolButton(
//             icon: Icons.filter,
//             label: effects[i],
//             onTap: () => ctrl.setFilter(effects[i]),
//           ),
//     );
//   }
//
//   // ───── PIP TAB ─────
//   Widget _pipTab() {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(
//             Icons.picture_in_picture_alt,
//             color: Colors.white60,
//             size: 64,
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Picture-in-Picture',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text('Coming soon', style: TextStyle(color: Colors.white60)),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             onPressed: () => Get.snackbar('Coming Soon', 'PIP feature'),
//             icon: const Icon(Icons.add),
//             label: const Text('Add PIP Video'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF0A84FF),
//               foregroundColor: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ─────────────────────── HELPER METHODS ───────────────────────
//
//   VoidCallback _wrap(VoidCallback fn) {
//     return () {
//       final idx = ctrl.selectedIndex.value;
//       if (idx < 0 || idx >= ctrl.clips.length) {
//         Get.snackbar('Error', 'Please select a video clip first');
//         return;
//       }
//       fn();
//     };
//   }
//
//   String _format(double secs) {
//     final m = (secs / 60).floor().toString().padLeft(2, '0');
//     final s = (secs % 60).floor().toString().padLeft(2, '0');
//     final ms = ((secs % 1) * 100).floor().toString().padLeft(2, '0');
//     return '$m:$s.$ms';
//   }
//
//   // ─────────────────────── MODALS & DIALOGS ───────────────────────
//
//   void _showProjectSettings() {
//     Get.bottomSheet(
//       Container(
//         padding: const EdgeInsets.all(20),
//         decoration: const BoxDecoration(
//           color: Color(0xFF1C1C1E),
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Project Settings',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             ListTile(
//               leading: const Icon(Icons.aspect_ratio, color: Color(0xFF0A84FF)),
//               title: const Text(
//                 'Aspect Ratio',
//                 style: TextStyle(color: Colors.white),
//               ),
//               subtitle: const Text(
//                 '9:16 (Portrait)',
//                 style: TextStyle(color: Colors.white60),
//               ),
//               trailing: const Icon(Icons.chevron_right, color: Colors.white60),
//               onTap: () {},
//             ),
//             ListTile(
//               leading: const Icon(Icons.high_quality, color: Color(0xFF0A84FF)),
//               title: const Text(
//                 'Export Quality',
//                 style: TextStyle(color: Colors.white),
//               ),
//               subtitle: const Text(
//                 '1080p HD',
//                 style: TextStyle(color: Colors.white60),
//               ),
//               trailing: const Icon(Icons.chevron_right, color: Colors.white60),
//               onTap: () {},
//             ),
//             ListTile(
//               leading: Icon(Icons.filter_frames, color: Color(0xFF0A84FF)),
//               title: const Text(
//                 'Frame Rate',
//                 style: TextStyle(color: Colors.white),
//               ),
//               subtitle: const Text(
//                 '30 fps',
//                 style: TextStyle(color: Colors.white60),
//               ),
//               trailing: const Icon(Icons.chevron_right, color: Colors.white60),
//               onTap: () {},
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showClipOptions(int index) {
//     Get.bottomSheet(
//       Container(
//         padding: const EdgeInsets.all(20),
//         decoration: const BoxDecoration(
//           color: Color(0xFF1C1C1E),
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.content_cut, color: Color(0xFF0A84FF)),
//               title: const Text('Split', style: TextStyle(color: Colors.white)),
//               onTap: () {
//                 Get.back();
//                 ctrl.selectedIndex.value = index;
//                 ctrl.splitClip();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.content_copy, color: Color(0xFF0A84FF)),
//               title: const Text(
//                 'Duplicate',
//                 style: TextStyle(color: Colors.white),
//               ),
//               onTap: () {
//                 Get.back();
//                 ctrl.selectedIndex.value = index;
//                 _duplicateClip();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.delete, color: Colors.red),
//               title: const Text('Delete', style: TextStyle(color: Colors.red)),
//               onTap: () {
//                 Get.back();
//                 ctrl.selectedIndex.value = index;
//                 _deleteClip();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _deleteClip() {
//     final idx = ctrl.selectedIndex.value;
//     if (idx < 0 || idx >= ctrl.clips.length) return;
//
//     Get.dialog(
//       AlertDialog(
//         backgroundColor: const Color(0xFF1C1C1E),
//         title: const Text(
//           'Delete Clip?',
//           style: TextStyle(color: Colors.white),
//         ),
//         content: const Text(
//           'This action cannot be undone.',
//           style: TextStyle(color: Colors.white60),
//         ),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () {
//               final removed = ctrl.clips.removeAt(idx);
//               ctrl.addChange(
//                 Change<ClipModel?>(
//                   null,
//                   () {
//                     ctrl.clips.removeAt(idx);
//                     ctrl.selectedIndex.value = -1;
//                   },
//                   (_) {
//                     ctrl.clips.insert(idx, removed);
//                     ctrl.selectedIndex.value = idx;
//                     ctrl.loadSelectedToPlayer();
//                   },
//                 ),
//               );
//               ctrl.selectedIndex.value = -1;
//               Get.back();
//               Get.snackbar('Success', 'Clip deleted');
//             },
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _duplicateClip() {
//     final idx = ctrl.selectedIndex.value;
//     if (idx < 0 || idx >= ctrl.clips.length) return;
//     final copy = ctrl.clips[idx].copy();
//     ctrl.clips.insert(idx + 1, copy);
//     ctrl.addChange(
//       Change<ClipModel?>(
//         null,
//         () => ctrl.clips.insert(idx + 1, copy),
//         (_) => ctrl.clips.removeAt(idx + 1),
//       ),
//     );
//     Get.snackbar('Success', 'Clip duplicated');
//   }
//
//   void _showTrimModal() {
//     final idx = ctrl.selectedIndex.value;
//     if (idx < 0 || idx >= ctrl.clips.length) {
//       Get.snackbar('Error', 'Please select a clip first');
//       return;
//     }
//     final clip = ctrl.clips[idx];
//
//     Get.bottomSheet(
//       Container(
//         height: 280,
//         padding: const EdgeInsets.all(20),
//         decoration: const BoxDecoration(
//           color: Color(0xFF1C1C1E),
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           children: [
//             const Text(
//               'Trim Video',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             DraggableTimeline(
//               videoFile: File(clip.path),
//               durationMs: clip.originalDurationMs,
//               startMs: clip.startMs,
//               endMs: clip.endMs,
//               onStartChanged: (v) => ctrl.setTrimStart(v),
//               onEndChanged: (v) => ctrl.setTrimEnd(v),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () => Get.back(),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.white,
//                       side: const BorderSide(color: Color(0xFF3A3A3C)),
//                     ),
//                     child: const Text('Cancel'),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Get.back();
//                       Get.snackbar('Success', 'Trim applied');
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF0A84FF),
//                       foregroundColor: Colors.white,
//                     ),
//                     child: const Text('Apply'),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showSpeedModal() {
//     final idx = ctrl.selectedIndex.value;
//     if (idx < 0 || idx >= ctrl.clips.length) {
//       Get.snackbar('Error', 'Please select a clip first');
//       return;
//     }
//     double speed = ctrl.clips[idx].speed;
//
//     Get.bottomSheet(
//       StatefulBuilder(
//         builder:
//             (context, setState) => Container(
//               height: 250,
//               padding: const EdgeInsets.all(20),
//               decoration: const BoxDecoration(
//                 color: Color(0xFF1C1C1E),
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//               ),
//               child: Column(
//                 children: [
//                   const Text(
//                     'Playback Speed',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     '${speed.toStringAsFixed(2)}x',
//                     style: const TextStyle(
//                       color: Color(0xFF0A84FF),
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   SliderTheme(
//                     data: SliderThemeData(
//                       trackHeight: 6,
//                       thumbShape: const RoundSliderThumbShape(
//                         enabledThumbRadius: 12,
//                       ),
//                     ),
//                     child: Slider(
//                       value: speed,
//                       min: 0.25,
//                       max: 4.0,
//                       divisions: 15,
//                       activeColor: const Color(0xFF0A84FF),
//                       inactiveColor: const Color(0xFF3A3A3C),
//                       onChanged: (v) {
//                         setState(() => speed = v);
//                         ctrl.setSpeed(v);
//                       },
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: const [
//                       Text(
//                         '0.25x',
//                         style: TextStyle(color: Colors.white60, fontSize: 12),
//                       ),
//                       Text(
//                         '4.0x',
//                         style: TextStyle(color: Colors.white60, fontSize: 12),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//       ),
//     );
//   }
//
//   void _showVolumeModal() {
//     final idx = ctrl.selectedIndex.value;
//     if (idx < 0 || idx >= ctrl.clips.length) {
//       Get.snackbar('Error', 'Please select a clip first');
//       return;
//     }
//     double vol = ctrl.clips[idx].volume;
//
//     Get.bottomSheet(
//       StatefulBuilder(
//         builder:
//             (context, setState) => Container(
//               height: 250,
//               padding: const EdgeInsets.all(20),
//               decoration: const BoxDecoration(
//                 color: Color(0xFF1C1C1E),
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//               ),
//               child: Column(
//                 children: [
//                   const Text(
//                     'Volume',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     '${(vol * 100).toInt()}%',
//                     style: const TextStyle(
//                       color: Color(0xFF0A84FF),
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   SliderTheme(
//                     data: SliderThemeData(
//                       trackHeight: 6,
//                       thumbShape: const RoundSliderThumbShape(
//                         enabledThumbRadius: 12,
//                       ),
//                     ),
//                     child: Slider(
//                       value: vol,
//                       min: 0.0,
//                       max: 2.0,
//                       divisions: 20,
//                       activeColor: const Color(0xFF0A84FF),
//                       inactiveColor: const Color(0xFF3A3A3C),
//                       onChanged: (v) {
//                         setState(() => vol = v);
//                         ctrl.setVolume(v);
//                       },
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: const [
//                       Text(
//                         '0%',
//                         style: TextStyle(color: Colors.white60, fontSize: 12),
//                       ),
//                       Text(
//                         '200%',
//                         style: TextStyle(color: Colors.white60, fontSize: 12),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//       ),
//     );
//   }
//
//   void _showTransitionModal() {
//     final transitions = [
//       {'name': 'None', 'icon': Icons.close},
//       {'name': 'Fade', 'icon': Icons.gradient},
//       {'name': 'Slide', 'icon': Icons.swap_horiz},
//       {'name': 'Zoom', 'icon': Icons.zoom_in},
//       {'name': 'Wipe', 'icon': Icons.swipe},
//       {'name': 'Dissolve', 'icon': Icons.blur_on},
//     ];
//
//     Get.bottomSheet(
//       Container(
//         height: 400,
//         padding: const EdgeInsets.all(20),
//         decoration: const BoxDecoration(
//           color: Color(0xFF1C1C1E),
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Transition',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: transitions.length,
//                 itemBuilder:
//                     (_, i) => ListTile(
//                       leading: Icon(
//                         transitions[i]['icon'] as IconData,
//                         color: const Color(0xFF0A84FF),
//                       ),
//                       title: Text(
//                         transitions[i]['name'] as String,
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                       trailing: const Icon(
//                         Icons.chevron_right,
//                         color: Colors.white60,
//                       ),
//                       onTap: () {
//                         ctrl.setTransition(
//                           (transitions[i]['name'] as String).toLowerCase(),
//                           0.5,
//                         );
//                         Get.back();
//                         Get.snackbar('Success', 'Transition applied');
//                       },
//                     ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showAudioOptions() {
//     Get.bottomSheet(
//       Container(
//         padding: const EdgeInsets.all(20),
//         decoration: const BoxDecoration(
//           color: Color(0xFF1C1C1E),
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.music_note, color: Color(0xFF0A84FF)),
//               title: const Text(
//                 'Add Music',
//                 style: TextStyle(color: Colors.white),
//               ),
//               onTap: () {
//                 Get.back();
//                 ctrl.pickBackgroundMusic();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.mic, color: Color(0xFF0A84FF)),
//               title: const Text(
//                 'Record Voice',
//                 style: TextStyle(color: Colors.white),
//               ),
//               onTap: () {
//                 Get.back();
//                 _startVoiceover();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _startVoiceover() async {
//     final status = await Permission.microphone.request();
//     if (!status.isGranted) {
//       Get.snackbar('Permission Denied', 'Microphone access is required');
//       return;
//     }
//
//     try {
//       final dir = await getTemporaryDirectory();
//       final path =
//           '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
//       await _recorder.openRecorder();
//       await _recorder.startRecorder(toFile: path);
//
//       Get.dialog(
//         AlertDialog(
//           backgroundColor: const Color(0xFF1C1C1E),
//           title: const Text(
//             'Recording...',
//             style: TextStyle(color: Colors.white),
//           ),
//           content: const Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(Icons.mic, color: Color(0xFF0A84FF), size: 64),
//               SizedBox(height: 16),
//               Text(
//                 'Tap stop when finished',
//                 style: TextStyle(color: Colors.white60),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: _stopVoiceover,
//               child: const Text(
//                 'Stop',
//                 style: TextStyle(color: Color(0xFF0A84FF)),
//               ),
//             ),
//           ],
//         ),
//         barrierDismissible: false,
//       );
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to start recording: $e');
//     }
//   }
//
//   Future<void> _stopVoiceover() async {
//     try {
//       final path = await _recorder.stopRecorder();
//       await _recorder.closeRecorder();
//       if (path != null) {
//         ctrl.voiceoverPath = path;
//         Get.back();
//         Get.snackbar('Success', 'Voice recording saved');
//       }
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to stop recording: $e');
//     }
//   }
//
//   void _showAddTextDialog() {
//     final txtCtrl = TextEditingController();
//     double fontSize = 32;
//     Color color = Colors.white;
//
//     showDialog(
//       context: Get.context!,
//       builder:
//           (dialogCtx) => AlertDialog(
//             backgroundColor: const Color(0xFF1C1C1E),
//             title: const Text(
//               'Add Text',
//               style: TextStyle(color: Colors.white),
//             ),
//             content: StatefulBuilder(
//               builder:
//                   (_, setState) => SingleChildScrollView(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         TextField(
//                           controller: txtCtrl,
//                           style: const TextStyle(color: Colors.white),
//                           maxLines: 3,
//                           decoration: InputDecoration(
//                             hintText: 'Enter your text',
//                             hintStyle: const TextStyle(color: Colors.white60),
//                             filled: true,
//                             fillColor: const Color(0xFF2C2C2E),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         Row(
//                           children: [
//                             const Text(
//                               'Size: ',
//                               style: TextStyle(color: Colors.white),
//                             ),
//                             Expanded(
//                               child: Slider(
//                                 min: 16,
//                                 max: 72,
//                                 value: fontSize,
//                                 activeColor: const Color(0xFF0A84FF),
//                                 onChanged: (v) => setState(() => fontSize = v),
//                               ),
//                             ),
//                             Text(
//                               '${fontSize.toInt()}',
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           children: [
//                             const Text(
//                               'Color: ',
//                               style: TextStyle(color: Colors.white),
//                             ),
//                             const SizedBox(width: 12),
//                             GestureDetector(
//                               onTap: () async {
//                                 final c = await showDialog<Color>(
//                                   context: dialogCtx,
//                                   builder:
//                                       (_) => AlertDialog(
//                                         backgroundColor: const Color(
//                                           0xFF1C1C1E,
//                                         ),
//                                         title: const Text(
//                                           'Pick Color',
//                                           style: TextStyle(color: Colors.white),
//                                         ),
//                                         content: SingleChildScrollView(
//                                           child: BlockPicker(
//                                             pickerColor: color,
//                                             onColorChanged:
//                                                 (c) =>
//                                                     Navigator.pop(dialogCtx, c),
//                                           ),
//                                         ),
//                                       ),
//                                 );
//                                 if (c != null) setState(() => color = c);
//                               },
//                               child: Container(
//                                 width: 40,
//                                 height: 40,
//                                 decoration: BoxDecoration(
//                                   color: color,
//                                   borderRadius: BorderRadius.circular(8),
//                                   border: Border.all(color: Colors.white24),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Get.back(),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   if (txtCtrl.text.isEmpty) {
//                     Get.snackbar('Error', 'Please enter some text');
//                     return;
//                   }
//                   final idx = ctrl.selectedIndex.value;
//                   if (idx < 0) {
//                     Get.snackbar('Error', 'Please select a clip first');
//                     return;
//                   }
//                   final ov =
//                       TextOverlay(text: txtCtrl.text)
//                         ..fontSize = fontSize
//                         ..color = color.value
//                         ..startMs = ctrl.currentMs.value
//                         ..durationMs = 5000;
//                   ctrl.addTextOverlay(ov);
//                   Get.back();
//                   Get.snackbar('Success', 'Text added');
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF0A84FF),
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('Add'),
//               ),
//             ],
//           ),
//     );
//   }
//
//   void _showTTSDialog() {
//     final txtCtrl = TextEditingController();
//     showDialog(
//       context: Get.context!,
//       builder:
//           (_) => AlertDialog(
//             backgroundColor: const Color(0xFF1C1C1E),
//             title: const Text(
//               'Text to Speech',
//               style: TextStyle(color: Colors.white),
//             ),
//             content: TextField(
//               controller: txtCtrl,
//               style: const TextStyle(color: Colors.white),
//               maxLines: 4,
//               decoration: InputDecoration(
//                 hintText: 'Enter text to convert to speech',
//                 hintStyle: const TextStyle(color: Colors.white60),
//                 filled: true,
//                 fillColor: const Color(0xFF2C2C2E),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Get.back(),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   if (txtCtrl.text.isEmpty) {
//                     Get.snackbar('Error', 'Please enter some text');
//                     return;
//                   }
//                   Get.back();
//                   await ctrl.generateAndSaveTTS(txtCtrl.text);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF0A84FF),
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('Generate'),
//               ),
//             ],
//           ),
//     );
//   }
//
//   void _applyTextStyle(String style) {
//     Get.snackbar('Text Style', '$style applied');
//   }
//
//   void _addSticker(int i) {
//     final idx = ctrl.selectedIndex.value;
//     if (idx < 0) {
//       Get.snackbar('Error', 'Please select a clip first');
//       return;
//     }
//     final st =
//         StickerOverlay(assetPath: 'assets/sticker$i.png')
//           ..startMs = ctrl.currentMs.value
//           ..durationMs = 5000
//           ..x = 0.5
//           ..y = 0.5;
//     ctrl.addStickerOverlay(st);
//     Get.snackbar('Success', 'Sticker added');
//   }
// }
