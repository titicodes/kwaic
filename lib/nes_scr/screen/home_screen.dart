// home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'video_editor_screen.dart';
import 'package:video_player/video_player.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // home_screen.dart
  Future<void> _startNewProject(BuildContext context) async {
    final picker = ImagePicker();

    try {
      final List<XFile>? pickedFiles = await picker.pickMultipleMedia();

      if (!context.mounted) return;

      if (pickedFiles == null || pickedFiles.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No files selected')));
        return;
      }

      // Filter only video files
      final videoFiles =
          pickedFiles.where((f) {
            final path = f.path.toLowerCase();
            return path.endsWith('.mp4') ||
                path.endsWith('.mov') ||
                path.endsWith('.avi') ||
                path.endsWith('.mkv') ||
                path.endsWith('.webm') ||
                path.endsWith('.m4v') ||
                path.endsWith('.3gp');
          }).toList();

      if (!context.mounted) return;

      if (videoFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No video files found. Please select videos.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            ),
      );

      // Initialize controllers
      final List<Map<String, dynamic>> videosData = [];
      for (final video in videoFiles) {
        try {
          final ctrl = VideoPlayerController.file(File(video.path));
          await ctrl.initialize();
          videosData.add({
            'file': video,
            'controller': ctrl,
            'duration': ctrl.value.duration,
          });
        } catch (e) {
          debugPrint('Error initializing video: $e');
        }
      }

      if (!context.mounted) return;
      Navigator.pop(context); // hide loading

      if (videosData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load videos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Go directly to editor with pre-loaded clips
      // Remove all the controller pre-initialization (let editor do it properly)
      Navigator.pop(context); // hide loading dialog

      // Pass only the raw XFile list — this is all we need!
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => VideoEditorScreen(
                initialVideos: videoFiles, // ← Just pass the XFile list!
              ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking videos: $e')));
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
              const Text(
                'Recent Projects',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (_, i) => _recentProjectCard(),
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

  Widget _recentProjectCard() {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Positioned(
                bottom: 6,
                right: 6,
                child: Text(
                  '0:07',
                  style: TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black87,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('20250318', style: TextStyle(fontWeight: FontWeight.w600)),
          Text(
            '2025/03/05 9:14 PM',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ],
      ),
    );
  }
}
