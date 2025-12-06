//
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../servuices/cloud_save_service.dart';
// import 'video_selection_screen.dart';
// import 'video_editor_screen.dart';
// import '../model/timeline_item.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   List<Map<String, dynamic>> _recentProjects = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadRecentProjects();
//   }
//
//   Future<void> _loadRecentProjects() async {
//     setState(() => _isLoading = true);
//
//     final projects = await CloudSaveService.getAllProjects();
//
//     // Sort by timestamp (newest first)
//     projects.sort((a, b) {
//       final timeA = DateTime.parse(a['timestamp']);
//       final timeB = DateTime.parse(b['timestamp']);
//       return timeB.compareTo(timeA);
//     });
//
//     if (mounted) {
//       setState(() {
//         _recentProjects =
//             projects.take(10).toList(); // Show only 10 most recent
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _startNewProject(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const VideoSelectionScreen()),
//     ).then((_) => _loadRecentProjects());
//   }
//
//   Future<void> _openProject(Map<String, dynamic> project) async {
//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder:
//             (_) => const Center(
//               child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
//             ),
//       );
//
//       final projectData = await CloudSaveService.loadProject(project['id']);
//
//       if (projectData == null) {
//         if (mounted) {
//           Navigator.pop(context);
//           _showError('Failed to load project');
//         }
//         return;
//       }
//
//       final clips =
//           (projectData['clips'] as List)
//               .map((json) => TimelineItem.fromJson(json))
//               .toList();
//
//       if (clips.isEmpty) {
//         if (mounted) {
//           Navigator.pop(context);
//           _showError('Project has no video clips');
//         }
//         return;
//       }
//
//       final List<XFile> videoFiles =
//           clips
//               .where((c) => c.file != null)
//               .map((c) => XFile(c.file!.path))
//               .toList();
//
//       if (mounted) {
//         Navigator.pop(context);
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder:
//                 (_) => VideoEditorScreen(
//                   initialVideos: videoFiles,
//                   projectId: projectData['id'],
//                   projectName: projectData['name'],
//                 ),
//           ),
//         ).then((_) => _loadRecentProjects());
//       }
//     } catch (e) {
//       debugPrint('Error opening project: $e');
//       if (mounted) {
//         Navigator.pop(context);
//         _showError('Failed to open project: $e');
//       }
//     }
//   }
//
//   Future<void> _deleteProject(String projectId) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             backgroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             title: const Text('Delete Project'),
//             content: const Text(
//               'Are you sure you want to delete this project? This action cannot be undone.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 child: const Text(
//                   'Delete',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//             ],
//           ),
//     );
//
//     if (confirm == true) {
//       final success = await CloudSaveService.deleteProject(projectId);
//       if (success) {
//         _showMessage('Project deleted');
//         _loadRecentProjects();
//       } else {
//         _showError('Failed to delete project');
//       }
//     }
//   }
//
//   Future<void> _renameProject(Map<String, dynamic> project) async {
//     final controller = TextEditingController(text: project['name']);
//
//     final newName = await showDialog<String>(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             backgroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             title: const Text('Rename Project'),
//             content: TextField(
//               controller: controller,
//               autofocus: true,
//               decoration: const InputDecoration(
//                 hintText: 'Enter project name',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context, controller.text),
//                 child: const Text('Save'),
//               ),
//             ],
//           ),
//     );
//
//     if (newName != null && newName.isNotEmpty && newName != project['name']) {
//       project['name'] = newName;
//
//       final clips =
//           (project['clips'] as List)
//               .map((json) => TimelineItem.fromJson(json))
//               .toList();
//       final audioItems =
//           (project['audio'] as List)
//               .map((json) => TimelineItem.fromJson(json))
//               .toList();
//       final textItems =
//           (project['text'] as List)
//               .map((json) => TimelineItem.fromJson(json))
//               .toList();
//       final overlayItems =
//           (project['overlays'] as List)
//               .map((json) => TimelineItem.fromJson(json))
//               .toList();
//
//       final success = await CloudSaveService.saveProject(
//         projectId: project['id'],
//         projectName: newName,
//         clips: clips,
//         audioItems: audioItems,
//         textItems: textItems,
//         overlayItems: overlayItems,
//       );
//
//       if (success) {
//         _showMessage('Project renamed');
//         _loadRecentProjects();
//       } else {
//         _showError('Failed to rename project');
//       }
//     }
//   }
//
//   void _showMessage(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: const Color(0xFF10B981),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   void _showError(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   String _getTimeAgo(DateTime time) {
//     final diff = DateTime.now().difference(time);
//     if (diff.inDays > 0) return '${diff.inDays}d ago';
//     if (diff.inHours > 0) return '${diff.inHours}h ago';
//     if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
//     return 'Just now';
//   }
//
//   String _getProjectDuration(Map<String, dynamic> project) {
//     try {
//       final clips = project['clips'] as List;
//       if (clips.isEmpty) return '0:00';
//
//       final totalMs = clips.fold<int>(
//         0,
//         (sum, clip) => sum + (clip['duration'] as int),
//       );
//
//       final duration = Duration(milliseconds: totalMs);
//       final minutes = duration.inMinutes;
//       final seconds = duration.inSeconds % 60;
//       return '$minutes:${seconds.toString().padLeft(2, '0')}';
//     } catch (e) {
//       return '0:00';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Use a consistent page padding that matches screenshot
//     const pagePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 16);
//
//     return Scaffold(
//       backgroundColor: const Color(
//         0xFFF5F5F7,
//       ), // subtle off-white as in screenshot
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: false,
//         toolbarHeight: 82,
//         leadingWidth: 72,
//         leading: Padding(
//           padding: const EdgeInsets.only(left: 12),
//           child: InkWell(
//             borderRadius: BorderRadius.circular(28),
//             onTap: () {},
//             child: Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(22),
//                 border: Border.all(color: const Color(0xFFF0EDF6)),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.03),
//                     blurRadius: 6,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: const Center(
//                 child: Icon(Icons.menu, color: Color(0xFF524F60)),
//               ),
//             ),
//           ),
//         ),
//         title: const Text(
//           'Omivideo',
//           style: TextStyle(
//             color: Color(0xFF2B2B2B),
//             fontWeight: FontWeight.w700,
//             fontSize: 20,
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 12),
//             child: Row(
//               children: [
//                 _smallRoundIconButton(icon: Icons.notifications_none),
//                 const SizedBox(width: 8),
//                 _smallRoundIconButton(icon: Icons.help_outline),
//                 const SizedBox(width: 8),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: RefreshIndicator(
//           onRefresh: _loadRecentProjects,
//           color: const Color(0xFF8B5CF6),
//           child: SingleChildScrollView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             child: Padding(
//               padding: pagePadding,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Quick tools area (two rows of circular tools)
//                   Container(
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.03),
//                           blurRadius: 8,
//                           offset: const Offset(0, 3),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 10,
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               // Empty left placeholder to match spacing in screenshot
//                               const SizedBox(width: 6),
//                               // small dotted line area to the right (as the screenshot shows)
//                               Row(
//                                 children: [
//                                   Container(
//                                     width: 10,
//                                     height: 10,
//                                     decoration: BoxDecoration(
//                                       color: Colors.white,
//                                       borderRadius: BorderRadius.circular(6),
//                                       border: Border.all(
//                                         color: const Color(0xFFEDE7FF),
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Container(
//                                     width: 34,
//                                     height: 34,
//                                     decoration: BoxDecoration(
//                                       color: Colors.white,
//                                       borderRadius: BorderRadius.circular(10),
//                                       border: Border.all(
//                                         color: const Color(0xFFEDE7FF),
//                                       ),
//                                     ),
//                                     child: const Icon(
//                                       Icons.more_horiz,
//                                       color: Color(0xFF7B7A86),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         const SizedBox(height: 6),
//
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 6,
//                           ),
//                           child: _toolsGrid(),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 18),
//
//                   // New Project CTA (purple pill)
//                   SizedBox(
//                     height: 56,
//                     child: ElevatedButton.icon(
//                       onPressed: () => _startNewProject(context),
//                       icon: const Icon(Icons.add, size: 22),
//                       label: const Text(
//                         'New Project',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF7C3AED),
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         padding: const EdgeInsets.symmetric(horizontal: 18),
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // Recent Projects header (See More at right)
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Recent Project',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF1E1E1E),
//                         ),
//                       ),
//                       if (_recentProjects.isNotEmpty)
//                         TextButton(
//                           onPressed: _showAllProjects,
//                           child: const Text(
//                             'More',
//                             style: TextStyle(
//                               color: Color(0xFF8B5CF6),
//                               fontSize: 13,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//
//                   // Recent Projects horizontal list
//                   if (_isLoading)
//                     const SizedBox(
//                       height: 140,
//                       child: Center(
//                         child: CircularProgressIndicator(
//                           color: Color(0xFF8B5CF6),
//                         ),
//                       ),
//                     )
//                   else if (_recentProjects.isEmpty)
//                     SizedBox(
//                       height: 140,
//                       child: Center(
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               Icons.video_library_outlined,
//                               size: 48,
//                               color: Colors.grey[300],
//                             ),
//                             const SizedBox(height: 10),
//                             Text(
//                               'No projects yet',
//                               style: TextStyle(color: Colors.grey[700]),
//                             ),
//                           ],
//                         ),
//                       ),
//                     )
//                   else
//                     SizedBox(
//                       height: 140,
//                       child: ListView.separated(
//                         physics: const BouncingScrollPhysics(),
//                         scrollDirection: Axis.horizontal,
//                         itemCount: _recentProjects.length,
//                         separatorBuilder: (_, __) => const SizedBox(width: 12),
//                         itemBuilder:
//                             (context, index) =>
//                                 _recentProjectCard(_recentProjects[index]),
//                       ),
//                     ),
//
//                   const SizedBox(height: 18),
//
//                   // AI banner (image asset)
//                   Container(
//                     width: double.infinity,
//                     height: 110,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.06),
//                           blurRadius: 12,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: Stack(
//                         fit: StackFit.expand,
//                         children: [
//                           // Use an asset image that matches the screenshot
//                           Image.asset(
//                             'assets/images/ai_banner.png',
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stack) {
//                               return Container(
//                                 color: const Color(0xFF2C1B63),
//                                 child: const Center(
//                                   child: Text(
//                                     'Explore AI Magic with Omivideo',
//                                     style: TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                           Positioned(
//                             left: 12,
//                             top: 12,
//                             child: ElevatedButton(
//                               onPressed: () {},
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.white,
//                                 foregroundColor: const Color(0xFF7C3AED),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(18),
//                                 ),
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 14,
//                                   vertical: 8,
//                                 ),
//                                 elevation: 0,
//                               ),
//                               child: const Text(
//                                 'Try Now',
//                                 style: TextStyle(fontWeight: FontWeight.w700),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 30),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//       bottomNavigationBar: _buildBottomNavBar(),
//     );
//   }
//
//   Widget _smallRoundIconButton({required IconData icon}) {
//     return Container(
//       width: 38,
//       height: 38,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFEEF0F6)),
//       ),
//       child: IconButton(
//         icon: Icon(icon, color: const Color(0xFF6B6B6B), size: 18),
//         onPressed: () {},
//       ),
//     );
//   }
//
//   Widget _toolsGrid() {
//     final tools = [
//       {'label': 'AutoCut', 'icon': Icons.content_cut},
//       {'label': 'Adjust', 'icon': Icons.tune},
//       {'label': 'AI Enhancer', 'icon': Icons.auto_fix_high},
//       {'label': 'Auto Captions', 'icon': Icons.closed_caption},
//       {'label': 'Photo Editor', 'icon': Icons.photo_library},
//       {'label': 'BG Remover', 'icon': Icons.person_remove},
//       {'label': 'Camera', 'icon': Icons.photo_camera},
//       {'label': 'All Tools', 'icon': Icons.more_horiz},
//     ];
//
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         for (int i = 0; i < tools.length; i++)
//           Expanded(
//             child: Column(
//               children: [
//                 InkWell(
//                   onTap: () {},
//                   borderRadius: BorderRadius.circular(28),
//                   child: Container(
//                     width: 56,
//                     height: 56,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF8F5FF),
//                       shape: BoxShape.circle,
//                       border: Border.all(color: const Color(0xFFEEE9FE)),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.02),
//                           blurRadius: 6,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Icon(
//                       tools[i]['icon'] as IconData,
//                       color: const Color(0xFF7C3AED),
//                       size: 24,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 SizedBox(
//                   height: 32,
//                   child: Text(
//                     tools[i]['label'] as String,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(fontSize: 11, height: 1.1),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }
//
//   Widget _recentProjectCard(Map<String, dynamic> project) {
//     final timestamp = DateTime.parse(project['timestamp']);
//     final dateStr =
//         '${timestamp.year.toString().padLeft(4, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.day.toString().padLeft(2, '0')} ${_formatTime(timestamp)}';
//     final duration = _getProjectDuration(project);
//
//     // Prefer a thumbnail path if provided in project map
//     final String? thumbPath = project['thumbnail'] as String?;
//     final bool hasThumb = thumbPath != null && thumbPath.isNotEmpty;
//
//     return GestureDetector(
//       onTap: () => _openProject(project),
//       onLongPress: () => _showProjectOptions(project),
//       child: Container(
//         width: 200,
//         padding: const EdgeInsets.all(8),
//         margin: const EdgeInsets.only(top: 4),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.03),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             // Thumbnail
//             ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: Stack(
//                 children: [
//                   Container(
//                     width: 110,
//                     height: 84,
//                     color: const Color(0xFFEBE7F9),
//                     child:
//                         hasThumb
//                             ? Image.network(
//                               thumbPath!,
//                               fit: BoxFit.cover,
//                               errorBuilder:
//                                   (_, __, ___) => _thumbnailPlaceholder(),
//                             )
//                             : _thumbnailPlaceholder(),
//                   ),
//                   // Duration badge - bottom-left
//                   Positioned(
//                     left: 6,
//                     bottom: 6,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 3,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.black87,
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         duration,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                   // small three dot icon top-right
//                   Positioned(
//                     top: 6,
//                     right: 6,
//                     child: GestureDetector(
//                       onTap: () => _showProjectOptions(project),
//                       child: Container(
//                         width: 28,
//                         height: 28,
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.85),
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: const Icon(Icons.more_vert, size: 16),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(width: 10),
//
//             // Title and date
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     project['name'],
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     dateStr,
//                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                   ),
//                   const Spacer(),
//                   Align(
//                     alignment: Alignment.bottomLeft,
//                     child: Text(
//                       'Edited • ${_getTimeAgo(timestamp)}',
//                       style: TextStyle(fontSize: 11, color: Colors.grey[500]),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _thumbnailPlaceholder() {
//     return Container(
//       color: const Color(0xFFEEEAFB),
//       child: const Center(
//         child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 36),
//       ),
//     );
//   }
//
//   String _formatTime(DateTime dt) {
//     final h = dt.hour.toString().padLeft(2, '0');
//     final m = dt.minute.toString().padLeft(2, '0');
//     return '$h:$m';
//   }
//
//   void _showProjectOptions(Map<String, dynamic> project) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (context) => SafeArea(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   margin: const EdgeInsets.only(top: 8),
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ListTile(
//                   leading: const Icon(
//                     Icons.play_arrow,
//                     color: Color(0xFF7C3AED),
//                   ),
//                   title: const Text('Open Project'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _openProject(project);
//                   },
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.edit, color: Color(0xFF7C3AED)),
//                   title: const Text('Rename'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _renameProject(project);
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
//                     _deleteProject(project['id']);
//                   },
//                 ),
//                 const SizedBox(height: 16),
//               ],
//             ),
//           ),
//     );
//   }
//
//   void _showAllProjects() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (_) => AllProjectsScreen(
//               projects: _recentProjects,
//               onProjectTap: _openProject,
//               onProjectDelete: _deleteProject,
//               onProjectRename: _renameProject,
//             ),
//       ),
//     ).then((_) => _loadRecentProjects());
//   }
//
//   Widget _buildBottomNavBar() {
//     return Container(
//       height: 78,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 12,
//             offset: const Offset(0, -4),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             _navItem(icon: Icons.home, label: 'Home', selected: true),
//             _navItem(icon: Icons.play_circle_outline, label: 'Project'),
//             _navItem(icon: Icons.grid_view, label: 'Template'),
//             _navItem(icon: Icons.auto_awesome_outlined, label: 'AI'),
//             _navItem(icon: Icons.person_outline, label: 'Profile'),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _navItem({
//     required IconData icon,
//     required String label,
//     bool selected = false,
//   }) {
//     final color = selected ? const Color(0xFF8B5CF6) : Colors.grey[600];
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, color: color, size: 22),
//         const SizedBox(height: 6),
//         Text(
//           label,
//           style: TextStyle(
//             color: color,
//             fontSize: 12,
//             fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// // All Projects Screen (kept similar; small style updates)
// class AllProjectsScreen extends StatelessWidget {
//   final List<Map<String, dynamic>> projects;
//   final Function(Map<String, dynamic>) onProjectTap;
//   final Function(String) onProjectDelete;
//   final Function(Map<String, dynamic>) onProjectRename;
//
//   const AllProjectsScreen({
//     Key? key,
//     required this.projects,
//     required this.onProjectTap,
//     required this.onProjectDelete,
//     required this.onProjectRename,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F7),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'All Projects',
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
//         ),
//       ),
//       body: GridView.builder(
//         padding: const EdgeInsets.all(16),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           childAspectRatio: 0.72,
//         ),
//         itemCount: projects.length,
//         itemBuilder: (context, index) {
//           final project = projects[index];
//           return _ProjectGridCard(
//             project: project,
//             onTap: () => onProjectTap(project),
//             onDelete: () => onProjectDelete(project['id']),
//             onRename: () => onProjectRename(project),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class _ProjectGridCard extends StatelessWidget {
//   final Map<String, dynamic> project;
//   final VoidCallback onTap;
//   final VoidCallback onDelete;
//   final VoidCallback onRename;
//
//   const _ProjectGridCard({
//     required this.project,
//     required this.onTap,
//     required this.onDelete,
//     required this.onRename,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final String? thumbPath = project['thumbnail'] as String?;
//     final bool hasThumb = thumbPath != null && thumbPath.isNotEmpty;
//     final timestamp = DateTime.parse(project['timestamp']);
//     final dateStr =
//         '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
//
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.03),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: ClipRRect(
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(12),
//                 ),
//                 child:
//                     hasThumb
//                         ? Image.network(
//                           thumbPath!,
//                           fit: BoxFit.cover,
//                           width: double.infinity,
//                         )
//                         : Container(
//                           color: const Color(0xFFEEEAFB),
//                           child: const Center(
//                             child: Icon(
//                               Icons.play_circle_fill,
//                               color: Colors.white70,
//                               size: 40,
//                             ),
//                           ),
//                         ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     project['name'],
//                     style: const TextStyle(fontWeight: FontWeight.w700),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     dateStr,
//                     style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../servuices/cloud_save_service.dart';
import 'video_selection_screen.dart';
import 'video_editor_screen.dart';
import '../model/timeline_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _recentProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentProjects();
  }

  Future<void> _loadRecentProjects() async {
    setState(() => _isLoading = true);
    final projects = await CloudSaveService.getAllProjects();
    projects.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

    if (mounted) {
      setState(() {
        _recentProjects = projects.take(10).toList();
        _isLoading = false;
      });
    }
  }

  void _startNewProject() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VideoSelectionScreen()),
    ).then((_) => _loadRecentProjects());
  }

  Future<void> _openProject(Map<String, dynamic> project) async {
    try {
      _showLoadingDialog();
      final projectData = await CloudSaveService.loadProject(project['id']);

      if (projectData == null || !mounted) {
        Navigator.pop(context);
        _showError('Failed to load project');
        return;
      }

      final clips = (projectData['clips'] as List)
          .map((json) => TimelineItem.fromJson(json))
          .toList();

      if (clips.isEmpty) {
        Navigator.pop(context);
        _showError('Project has no video clips');
        return;
      }

      final videoFiles = clips
          .where((c) => c.file != null)
          .map((c) => XFile(c.file!.path))
          .toList();

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoEditorScreen(
            initialVideos: videoFiles,
            projectId: projectData['id'],
            projectName: projectData['name'],
          ),
        ),
      ).then((_) => _loadRecentProjects());
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError('Failed to open project: $e');
      }
    }
  }

  Future<void> _deleteProject(String projectId) async {
    final confirm = await _showDeleteDialog();
    if (confirm != true) return;

    final success = await CloudSaveService.deleteProject(projectId);
    success ? _showMessage('Project deleted') : _showError('Failed to delete project');
    if (success) _loadRecentProjects();
  }

  Future<void> _renameProject(Map<String, dynamic> project) async {
    final newName = await _showRenameDialog(project['name']);
    if (newName == null || newName.isEmpty || newName == project['name']) return;

    final clips = (project['clips'] as List).map((j) => TimelineItem.fromJson(j)).toList();
    final audioItems = (project['audio'] as List).map((j) => TimelineItem.fromJson(j)).toList();
    final textItems = (project['text'] as List).map((j) => TimelineItem.fromJson(j)).toList();
    final overlayItems = (project['overlays'] as List).map((j) => TimelineItem.fromJson(j)).toList();

    final success = await CloudSaveService.saveProject(
      projectId: project['id'],
      projectName: newName,
      clips: clips,
      audioItems: audioItems,
      textItems: textItems,
      overlayItems: overlayItems,
    );

    success ? _showMessage('Project renamed') : _showError('Failed to rename project');
    if (success) _loadRecentProjects();
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))),
    );
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRenameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rename Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter project name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  void _showProjectOptions(Map<String, dynamic> project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(Icons.play_arrow, 'Open Project', () {
              Navigator.pop(context);
              _openProject(project);
            }),
            _buildOptionTile(Icons.edit, 'Rename', () {
              Navigator.pop(context);
              _renameProject(project);
            }),
            _buildOptionTile(Icons.delete, 'Delete', () {
              Navigator.pop(context);
              _deleteProject(project['id']);
            }, isDestructive: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFF7C3AED)),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : null)),
      onTap: onTap,
    );
  }

  void _showAllProjects() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllProjectsScreen(
          projects: _recentProjects,
          onProjectTap: _openProject,
          onProjectDelete: _deleteProject,
          onProjectRename: _renameProject,
        ),
      ),
    ).then((_) => _loadRecentProjects());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecentProjects,
          color: const Color(0xFF8B5CF6),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickToolsCard(),
                  const SizedBox(height: 18),
                  _buildNewProjectButton(),
                  const SizedBox(height: 20),
                  _buildRecentProjectsHeader(),
                  const SizedBox(height: 10),
                  _buildRecentProjectsList(),
                  const SizedBox(height: 18),
                  _buildAIBanner(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: 82,
      leadingWidth: 72,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _buildIconButton(Icons.menu, () {}),
      ),
      title: const Text('Omivideo', style: TextStyle(color: Color(0xFF2B2B2B), fontWeight: FontWeight.w700, fontSize: 20)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              _buildSmallIconButton(Icons.notifications_none),
              const SizedBox(width: 8),
              _buildSmallIconButton(Icons.help_outline),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF0EDF6)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Center(child: Icon(icon, color: const Color(0xFF524F60))),
      ),
    );
  }

  Widget _buildSmallIconButton(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F6)),
      ),
      child: IconButton(icon: Icon(icon, color: const Color(0xFF6B6B6B), size: 18), onPressed: () {}),
    );
  }

  Widget _buildQuickToolsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEDE7FF)),
                  ),
                  child: const Icon(Icons.more_horiz, color: Color(0xFF7B7A86)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: _buildToolsGrid()),
        ],
      ),
    );
  }

  Widget _buildToolsGrid() {
    final tools = [
      {'label': 'AutoCut', 'icon': Icons.content_cut},
      {'label': 'Adjust', 'icon': Icons.tune},
      {'label': 'AI Enhancer', 'icon': Icons.auto_fix_high},
      {'label': 'Auto Captions', 'icon': Icons.closed_caption},
      {'label': 'Photo Editor', 'icon': Icons.photo_library},
      {'label': 'BG Remover', 'icon': Icons.person_remove},
      {'label': 'Camera', 'icon': Icons.photo_camera},
      {'label': 'All Tools', 'icon': Icons.more_horiz},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: tools.map((tool) => _buildToolItem(tool['icon'] as IconData, tool['label'] as String)).toList(),
    );
  }

  Widget _buildToolItem(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEEE9FE)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Icon(icon, color: const Color(0xFF7C3AED), size: 24),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildNewProjectButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _startNewProject,
        icon: const Icon(Icons.add, size: 22),
        label: const Text('New Project', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildRecentProjectsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Recent Project', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E1E1E))),
        if (_recentProjects.isNotEmpty)
          TextButton(
            onPressed: _showAllProjects,
            child: const Text('More', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildRecentProjectsList() {
    if (_isLoading) {
      return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))));
    }

    if (_recentProjects.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_library_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 10),
              Text('No projects yet', style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: _recentProjects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _buildProjectCard(_recentProjects[index]),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final timestamp = DateTime.parse(project['timestamp']);
    final dateStr = '${timestamp.year}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    final duration = _getProjectDuration(project);
    final thumbPath = project['thumbnail'] as String?;

    return GestureDetector(
      onTap: () => _openProject(project),
      onLongPress: () => _showProjectOptions(project),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            _buildThumbnail(thumbPath, duration),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const Spacer(),
                  Text('Edited • ${_getTimeAgo(timestamp)}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? thumbPath, String duration) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 84,
            color: const Color(0xFFEBE7F9),
            child: thumbPath != null && thumbPath.isNotEmpty
                ? Image.network(thumbPath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder())
                : _buildPlaceholder(),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
              child: Text(duration, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _showProjectOptions(_recentProjects.firstWhere((p) => p['thumbnail'] == thumbPath, orElse: () => {})),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.more_vert, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFEEEAFB),
      child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 36)),
    );
  }

  Widget _buildAIBanner() {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/ai_banner.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF2C1B63),
                child: const Center(child: Text('Explore AI Magic with Omivideo', style: TextStyle(color: Colors.white))),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  elevation: 0,
                ),
                child: const Text('Try Now', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home, 'Home', true),
            _buildNavItem(Icons.play_circle_outline, 'Project', false),
            _buildNavItem(Icons.grid_view, 'Template', false),
            _buildNavItem(Icons.auto_awesome_outlined, 'AI', false),
            _buildNavItem(Icons.person_outline, 'Profile', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool selected) {
    final color = selected ? const Color(0xFF8B5CF6) : Colors.grey[600];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String _getProjectDuration(Map<String, dynamic> project) {
    try {
      final clips = project['clips'] as List;
      if (clips.isEmpty) return '0:00';
      final totalMs = clips.fold<int>(0, (sum, clip) => sum + (clip['duration'] as int));
      final duration = Duration(milliseconds: totalMs);
      return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    } catch (e) {
      return '0:00';
    }
  }
}

// All Projects Screen
class AllProjectsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> projects;
  final Function(Map<String, dynamic>) onProjectTap;
  final Function(String) onProjectDelete;
  final Function(Map<String, dynamic>) onProjectRename;

  const AllProjectsScreen({
    Key? key,
    required this.projects,
    required this.onProjectTap,
    required this.onProjectDelete,
    required this.onProjectRename,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('All Projects', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          final thumbPath = project['thumbnail'] as String?;
          final timestamp = DateTime.parse(project['timestamp']);
          final dateStr = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

          return GestureDetector(
            onTap: () => onProjectTap(project),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: thumbPath != null && thumbPath.isNotEmpty
                          ? Image.network(thumbPath, fit: BoxFit.cover, width: double.infinity)
                          : Container(
                        color: const Color(0xFFEEEAFB),
                        child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 40)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project['name'], style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Text(dateStr, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}