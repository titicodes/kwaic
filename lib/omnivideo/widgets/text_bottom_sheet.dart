import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/text_track.dart';
import '../provider/video_editor_provider.dart';
import 'package:uuid/uuid.dart';

class TextBottomSheet extends StatefulWidget {
  const TextBottomSheet({super.key});

  @override
  State<TextBottomSheet> createState() => _TextBottomSheetState();
}

class _TextBottomSheetState extends State<TextBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> tabs = ['Template', 'Fonts', 'Styles', 'Effects', 'Animation'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<VideoEditorProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    provider
                      ..showBottomSheet = false
                      ..showContextToolbar = true;
                  },
                ),
                const Spacer(),
                const Text('Add Text', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: () {
                    // Save current text (if editing)
                    provider
                      ..showBottomSheet = false
                      ..showContextToolbar = true;
                  },
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: const Color(0xFF8B5CF6),
            tabs: tabs.map((t) => Tab(text: t)).toList(),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTemplates(provider),
                _buildFonts(provider),
                _buildStyles(provider),
                _buildEffects(provider),
                _buildAnimations(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplates(VideoEditorProvider p) {
    final templates = ['Text Sample', 'Title', 'Subtitle', 'Quote', 'Lyrics'];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: templates.length + 1, // +1 for "Add Text"
      itemBuilder: (_, i) {
        if (i == 0) {
          return GestureDetector(
            onTap: () {
              final newText = TextTrack(
                id: const Uuid().v4(),
                startTime: p.currentPosition,
              );
              p.addTextTrack(newText);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 40),
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            final newText = TextTrack(
              id: const Uuid().v4(),
              text: templates[i - 1],
              startTime: p.currentPosition,
            );
            p.addTextTrack(newText);
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              templates[i - 1],
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  // Placeholder tabs — you'll expand these
  Widget _buildFonts(VideoEditorProvider p) => const Center(child: Text('Fonts', style: TextStyle(color: Colors.white)));
  Widget _buildStyles(VideoEditorProvider p) => const Center(child: Text('Styles', style: TextStyle(color: Colors.white)));
  Widget _buildEffects(VideoEditorProvider p) => const Center(child: Text('Effects', style: TextStyle(color: Colors.white)));
  Widget _buildAnimations(VideoEditorProvider p) => const Center(child: Text('Animation', style: TextStyle(color: Colors.white)));
}