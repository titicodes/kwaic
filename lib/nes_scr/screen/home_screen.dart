// import 'package:flutter/material.dart';
// import 'video_selection_screen.dart';
//
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//
//   void _startNewProject(BuildContext context) {
//     // Navigate to video selection screen
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const VideoSelectionScreen(),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: Colors.black),
//           onPressed: () {},
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_outlined, color: Colors.black),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.settings_outlined, color: Colors.black),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Quick Tools Grid
//               GridView.count(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 crossAxisCount: 4,
//                 mainAxisSpacing: 16,
//                 crossAxisSpacing: 16,
//                 childAspectRatio: 0.9,
//                 children: [
//                   _tool('AutoCut', Icons.cut_outlined),
//                   _tool('Adjust', Icons.tune),
//                   _tool('AI Enhance', Icons.auto_fix_high),
//                   _tool('Captions', Icons.closed_caption_outlined),
//                   _tool('Photos', Icons.photo_library_outlined),
//                   _tool('BG Remove', Icons.person_remove_outlined),
//                   _tool('Camera', Icons.camera_alt_outlined),
//                   _tool('More', Icons.more_horiz),
//                 ],
//               ),
//               const SizedBox(height: 32),
//
//               // New Project Button
//               GestureDetector(
//                 onTap: () => _startNewProject(context),
//                 child: Container(
//                   width: double.infinity,
//                   height: 56,
//                   decoration: BoxDecoration(
//                     gradient: const LinearGradient(
//                       colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
//                     ),
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: const Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.add, color: Colors.white, size: 26),
//                       SizedBox(width: 10),
//                       Text(
//                         'New Project',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 17,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 32),
//               const Text(
//                 'Recent Projects',
//                 style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 12),
//               SizedBox(
//                 height: 140,
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: 5,
//                   itemBuilder: (_, i) => _recentProjectCard(),
//                 ),
//               ),
//               const SizedBox(height: 32),
//
//               // AI Banner
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF1E1B4B), Color(0xFF4C1D95)],
//                   ),
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Text(
//                             'Explore AI Magic with',
//                             style: TextStyle(
//                               color: Colors.white70,
//                               fontSize: 13,
//                             ),
//                           ),
//                           const Text(
//                             'Omivideo',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           ElevatedButton(
//                             onPressed: () {},
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.white,
//                               foregroundColor: const Color(0xFF8B5CF6),
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                                 vertical: 10,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                             ),
//                             child: const Text(
//                               'Try Now',
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const Icon(
//                       Icons.auto_awesome,
//                       color: Colors.white,
//                       size: 56,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: const Color(0xFF8B5CF6),
//         unselectedItemColor: Colors.grey[600],
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.play_circle_outline),
//             label: 'Project',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.grid_view),
//             label: 'Template',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.auto_awesome_outlined),
//             label: 'AI',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person_outline),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _tool(String label, IconData icon) {
//     return Column(
//       children: [
//         Container(
//           width: 56,
//           height: 56,
//           decoration: BoxDecoration(
//             color: const Color(0xFFF3E5FF),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Icon(icon, color: const Color(0xFF8B5CF6), size: 28),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 11),
//           textAlign: TextAlign.center,
//           maxLines: 2,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ],
//     );
//   }
//
//   Widget _recentProjectCard() {
//     return Container(
//       width: 130,
//       margin: const EdgeInsets.only(right: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Stack(
//             children: [
//               Container(
//                 height: 90,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               const Positioned(
//                 bottom: 6,
//                 right: 6,
//                 child: Text(
//                   '0:07',
//                   style: TextStyle(
//                     color: Colors.white,
//                     backgroundColor: Colors.black87,
//                     fontSize: 10,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           const Text('20250318', style: TextStyle(fontWeight: FontWeight.w600)),
//           Text(
//             '2025/03/05 9:14 PM',
//             style: TextStyle(color: Colors.grey[600], fontSize: 11),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../servuices/cloud_save_service.dart';
import 'video_selection_screen.dart';
import '../model/timeline_item.dart';
import 'video_editor_screen.dart';
import 'package:image_picker/image_picker.dart';

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

    // Sort by timestamp (newest first)
    projects.sort((a, b) {
      final timeA = DateTime.parse(a['timestamp']);
      final timeB = DateTime.parse(b['timestamp']);
      return timeB.compareTo(timeA);
    });

    if (mounted) {
      setState(() {
        _recentProjects = projects.take(10).toList(); // Show only 10 most recent
        _isLoading = false;
      });
    }
  }

  void _startNewProject(BuildContext context) {
    // Navigate to video selection screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VideoSelectionScreen(),
      ),
    ).then((_) {
      // Refresh projects when returning
      _loadRecentProjects();
    });
  }

  Future<void> _openProject(Map<String, dynamic> project) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              SizedBox(height: 16),
              Text(
                'Loading project...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );

      // Load project data
      final projectData = await CloudSaveService.loadProject(project['id']);

      if (projectData == null) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          _showError('Failed to load project');
        }
        return;
      }

      // Convert JSON data back to XFiles for the editor
      final clips = (projectData['clips'] as List)
          .map((json) => TimelineItem.fromJson(json))
          .toList();

      if (clips.isEmpty) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          _showError('Project has no video clips');
        }
        return;
      }

      // Convert back to XFiles
      final List<XFile> videoFiles = clips
          .where((c) => c.file != null)
          .map((c) => XFile(c.file!.path))
          .toList();

      if (mounted) {
        Navigator.pop(context); // Close loading

        // Navigate to editor with project data
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
      }
    } catch (e) {
      debugPrint('Error opening project: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showError('Failed to open project: $e');
      }
    }
  }

  Future<void> _deleteProject(String projectId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await CloudSaveService.deleteProject(projectId);
      if (success) {
        _showMessage('Project deleted');
        _loadRecentProjects();
      } else {
        _showError('Failed to delete project');
      }
    }
  }

  Future<void> _renameProject(Map<String, dynamic> project) async {
    final controller = TextEditingController(text: project['name']);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rename Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter project name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != project['name']) {
      // Update project name
      project['name'] = newName;

      // Convert timeline items back
      final clips = (project['clips'] as List)
          .map((json) => TimelineItem.fromJson(json))
          .toList();
      final audioItems = (project['audio'] as List)
          .map((json) => TimelineItem.fromJson(json))
          .toList();
      final textItems = (project['text'] as List)
          .map((json) => TimelineItem.fromJson(json))
          .toList();
      final overlayItems = (project['overlays'] as List)
          .map((json) => TimelineItem.fromJson(json))
          .toList();

      final success = await CloudSaveService.saveProject(
        projectId: project['id'],
        projectName: newName,
        clips: clips,
        audioItems: audioItems,
        textItems: textItems,
        overlayItems: overlayItems,
      );

      if (success) {
        _showMessage('Project renamed');
        _loadRecentProjects();
      } else {
        _showError('Failed to rename project');
      }
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
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

      final totalMs = clips.fold<int>(
        0,
            (sum, clip) => sum + (clip['duration'] as int),
      );

      final duration = Duration(milliseconds: totalMs);
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } catch (e) {
      return '0:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          'Omivideo',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecentProjects,
          color: const Color(0xFF8B5CF6),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Tools Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    _tool('AutoCut', Icons.cut_outlined),
                    _tool('Adjust', Icons.tune),
                    _tool('AI Enhance', Icons.auto_fix_high),
                    _tool('Captions', Icons.closed_caption_outlined),
                    _tool('Photos', Icons.photo_library_outlined),
                    _tool('BG Remove', Icons.person_remove_outlined),
                    _tool('Camera', Icons.camera_alt_outlined),
                    _tool('More', Icons.more_horiz),
                  ],
                ),
                const SizedBox(height: 32),

                // New Project Button
                GestureDetector(
                  onTap: () => _startNewProject(context),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 26),
                        SizedBox(width: 10),
                        Text(
                          'New Project',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Recent Projects Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Projects',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_recentProjects.isNotEmpty)
                      TextButton(
                        onPressed: () => _showAllProjects(),
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Recent Projects List
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  )
                else if (_recentProjects.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No projects yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first project to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentProjects.length,
                      itemBuilder: (_, i) => _recentProjectCard(_recentProjects[i]),
                    ),
                  ),

                const SizedBox(height: 32),

                // AI Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1B4B), Color(0xFF4C1D95)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Explore AI Magic with',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const Text(
                              'Omivideo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF8B5CF6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Try Now',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 56,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8B5CF6),
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: 'Project',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Template',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _tool(String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF8B5CF6), size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _recentProjectCard(Map<String, dynamic> project) {
    final timestamp = DateTime.parse(project['timestamp']);
    final timeAgo = _getTimeAgo(timestamp);
    final duration = _getProjectDuration(project);

    return GestureDetector(
      onTap: () => _openProject(project),
      onLongPress: () => _showProjectOptions(project),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _showProjectOptions(project),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project['name'],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              timeAgo,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectOptions(Map<String, dynamic> project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Color(0xFF8B5CF6)),
              title: const Text('Open Project'),
              onTap: () {
                Navigator.pop(context);
                _openProject(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF8B5CF6)),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _renameProject(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteProject(project['id']);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Projects',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return _ProjectGridCard(
            project: project,
            onTap: () => onProjectTap(project),
            onDelete: () => onProjectDelete(project['id']),
            onRename: () => onProjectRename(project),
          );
        },
      ),
    );
  }
}

class _ProjectGridCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _ProjectGridCard({
    required this.project,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: Colors.white,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Rename'),
                          onTap: onRename,
                        ),
                        PopupMenuItem(
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateTime.parse(project['timestamp']).toString().split(' ')[0],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}