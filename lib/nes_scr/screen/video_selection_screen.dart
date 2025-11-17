// // video_selection_screen.dart
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'video_editor_screen.dart';
//
// class VideoSelectionScreen extends StatefulWidget {
//   final List<XFile> initialPickedVideos;
//
//   const VideoSelectionScreen({super.key, required this.initialPickedVideos});
//
//   @override
//   State<VideoSelectionScreen> createState() => _VideoSelectionScreenState();
// }
//
// class _VideoSelectionScreenState extends State<VideoSelectionScreen> {
//   late List<XFile> selectedVideos;
//
//   @override
//   void initState() {
//     super.initState();
//     selectedVideos = List.from(widget.initialPickedVideos);
//   }
//
//   Future<Uint8List?> _safeReadBytes(XFile file) async {
//     try {
//       return await file.readAsBytes().timeout(const Duration(seconds: 3));
//     } catch (_) {
//       return null; // Allowed here because our function returns Uint8List?
//     }
//   }
//
//   Future<void> _pickMoreVideos() async {
//     try {
//       final picker = ImagePicker();
//       final picked = await picker.pickMultipleMedia();
//
//       if (!mounted) return;
//
//       if (picked.isNotEmpty) {
//         setState(() {
//           selectedVideos.addAll(
//             picked.where((f) {
//               final path = f.path.toLowerCase();
//               return path.endsWith('.mp4') ||
//                   path.endsWith('.mov') ||
//                   path.endsWith('.avi') ||
//                   path.endsWith('.mkv') ||
//                   path.endsWith('.webm') ||
//                   path.endsWith('.3gp');
//             }),
//           );
//         });
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error picking videos: $e')));
//     }
//   }
//
//   void _removeVideo(int index) {
//     setState(() {
//       selectedVideos.removeAt(index);
//     });
//   }
//
//   void _goToEditor() async {
//     if (selectedVideos.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select at least one video')),
//       );
//       return;
//     }
//
//     // Critical: Check if still mounted before navigation
//     if (!mounted) return;
//
//     // Convert XFile → File safely
//     final List<File> videoFiles = [];
//     for (final xfile in selectedVideos) {
//       try {
//         final file = File(xfile.path);
//         if (await file.exists()) {
//           videoFiles.add(file);
//         }
//       } catch (e) {
//         debugPrint('Failed to access file: ${xfile.path}');
//         // Skip invalid files
//       }
//     }
//
//     if (videoFiles.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('No valid videos to edit')));
//       return;
//     }
//
//     // Final safety check
//     if (!mounted) return;
//
//     Navigator.push(
//       context,
//       PageRouteBuilder(
//         pageBuilder:
//             (c, a1, a2) => VideoEditorScreen(initialVideos: videoFiles),
//         transitionsBuilder:
//             (c, anim, a2, child) => FadeTransition(opacity: anim, child: child),
//         transitionDuration: const Duration(milliseconds: 400),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         title: Text('${selectedVideos.length} video(s) selected'),
//         titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           TextButton(
//             onPressed: selectedVideos.isEmpty ? null : _goToEditor,
//             child: const Text(
//               'Next',
//               style: TextStyle(color: Colors.white, fontSize: 17),
//             ),
//           ),
//         ],
//       ),
//       body:
//           selectedVideos.isEmpty
//               ? const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.video_library_outlined,
//                       size: 64,
//                       color: Colors.white30,
//                     ),
//                     SizedBox(height: 16),
//                     Text(
//                       'No videos selected',
//                       style: TextStyle(color: Colors.white70, fontSize: 18),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Tap + to add videos',
//                       style: TextStyle(color: Colors.white38, fontSize: 14),
//                     ),
//                   ],
//                 ),
//               )
//               : GridView.builder(
//                 padding: const EdgeInsets.all(12),
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 3,
//                   crossAxisSpacing: 12,
//                   mainAxisSpacing: 12,
//                   childAspectRatio: 0.75,
//                 ),
//                 itemCount: selectedVideos.length,
//                 itemBuilder: (context, index) {
//                   final video = selectedVideos[index];
//
//                   return GestureDetector(
//                     onTap:
//                         () => _removeVideo(
//                           index,
//                         ), // Tap whole card to remove (optional UX)
//                     child: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         // Thumbnail
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(12),
//                           child: FutureBuilder<Uint8List?>(
//                             future: _safeReadBytes(video),
//                             builder: (context, snapshot) {
//                               if (snapshot.hasData && snapshot.data != null) {
//                                 return Image.memory(
//                                   snapshot.data!,
//                                   fit: BoxFit.cover,
//                                   errorBuilder:
//                                       (_, __, ___) =>
//                                           Container(color: Colors.grey[800]),
//                                 );
//                               }
//                               return Container(
//                                 color: Colors.grey[800],
//                                 child: const Icon(
//                                   Icons.video_file,
//                                   color: Colors.white38,
//                                   size: 32,
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//
//                         // Remove button (top right)
//                         Positioned(
//                           top: 6,
//                           right: 6,
//                           child: GestureDetector(
//                             onTap: () => _removeVideo(index),
//                             child: Container(
//                               padding: const EdgeInsets.all(4),
//                               decoration: const BoxDecoration(
//                                 color: Colors.black87,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: const Icon(
//                                 Icons.close,
//                                 size: 18,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//
//                         // Play icon overlay
//                         const Align(
//                           alignment: Alignment.center,
//                           child: Icon(
//                             Icons.play_circle_fill,
//                             size: 48,
//                             color: Colors.white70,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: const Color(0xFFA855F7),
//         elevation: 8,
//         onPressed: _pickMoreVideos,
//         child: const Icon(Icons.add, color: Colors.white, size: 28),
//       ),
//     );
//   }
// }
