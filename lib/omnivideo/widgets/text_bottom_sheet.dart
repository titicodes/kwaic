// widgets/text_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../model/text_track.dart';
import '../provider/video_editor_provider.dart';
import 'draggable_resizable_text.dart';

class TextBottomSheet extends StatefulWidget {
  const TextBottomSheet({super.key});

  @override
  State<TextBottomSheet> createState() => _TextBottomSheetState();
}

class _TextBottomSheetState extends State<TextBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> tabs = ['Template', 'Fonts', 'Style', 'Effect', 'Animation'];

  TextTrack? editingText;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    final provider = context.read<VideoEditorProvider>();
    editingText = provider.selectedTextTrack ??
        TextTrack(
          id: const Uuid().v4(),
          startTime: provider.currentPosition,
        );
    _textController.text = editingText!.text;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _applyAndClose() {
    final provider = context.read<VideoEditorProvider>();
    final updated = editingText!.copyWith(text: _textController.text);
    if (provider.selectedTextTrack == null) {
      provider.addTextTrack(updated);
    } else {
      provider.updateTextTrack(updated);
    }
    provider
      ..showBottomSheet = false
      ..showContextToolbar = true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoEditorProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
                  onPressed: _applyAndClose,
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
    final templates = [
      'Double tap to edit',
      'TITLE',
      'Subtitle',
      'Quote of the Day',
      'Lyrics',
      'Breaking News',
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2,
      ),
      itemCount: templates.length,
      itemBuilder: (_, i) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _textController.text = templates[i];
              editingText = editingText!.copyWith(text: templates[i]);
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              templates[i],
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFonts(VideoEditorProvider p) {
    final fonts = ['Roboto', 'Montserrat', 'Poppins', 'Oswald', 'Bebas Neue', 'Pacifico'];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fonts.length,
      itemBuilder: (_, i) {
        return ListTile(
          title: Text(fonts[i], style: TextStyle(color: Colors.white, fontFamily: fonts[i], fontSize: 20)),
          onTap: () {
            setState(() {
              editingText = editingText!.copyWith(fontFamily: fonts[i]);
            });
          },
        );
      },
    );
  }

  Widget _buildStyles(VideoEditorProvider p) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white, fontSize: 32),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'Enter text',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
            ),
            onChanged: (v) {
              editingText = editingText!.copyWith(text: v);
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _styleButton(Icons.format_bold, editingText!.fontWeight == FontWeight.bold, () {
                setState(() {
                  editingText = editingText!.copyWith(
                    fontWeight: editingText!.fontWeight == FontWeight.bold ? FontWeight.normal : FontWeight.bold,
                  );
                });
              }),
              _styleButton(Icons.format_italic, editingText!.fontStyle == FontStyle.italic, () {
                setState(() {
                  editingText = editingText!.copyWith(
                    fontStyle: editingText!.fontStyle == FontStyle.italic ? FontStyle.normal : FontStyle.italic,
                  );
                });
              }),
              _styleButton(Icons.format_align_center, editingText!.alignment == TextAlign.center, () {
                setState(() => editingText = editingText!.copyWith(alignment: TextAlign.center));
              }),
            ],
          ),
          const SizedBox(height: 20),
          Text('Font Size: ${editingText!.fontSize.round()}', style: const TextStyle(color: Colors.white)),
          Slider(
            value: editingText!.fontSize,
            min: 20,
            max: 100,
            onChanged: (v) => setState(() => editingText = editingText!.copyWith(fontSize: v)),
          ),
        ],
      ),
    );
  }

  Widget _styleButton(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF8B5CF6) : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildEffects(VideoEditorProvider p) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Text Shadow', style: TextStyle(color: Colors.white)),
            value: editingText!.hasShadow,
            onChanged: (v) => setState(() => editingText = editingText!.copyWith(hasShadow: v)),
          ),
          SwitchListTile(
            title: const Text('Text Stroke', style: TextStyle(color: Colors.white)),
            value: editingText!.hasStroke,
            onChanged: (v) => setState(() => editingText = editingText!.copyWith(hasStroke: v)),
          ),
          if (editingText!.hasStroke)
            Row(
              children: [
                const Text('Stroke Color', style: TextStyle(color: Colors.white)),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final color = await showColorPicker();
                    if (color != null) setState(() => editingText = editingText!.copyWith(strokeColor: color));
                  },
                  child: Container(width: 40, height: 40, color: editingText!.strokeColor),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAnimations(VideoEditorProvider p) {
    final anims = ['None', 'Fade In', 'Slide Up', 'Scale', 'Typewriter'];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: anims.length,
      itemBuilder: (_, i) {
        return ListTile(
          title: Text(anims[i], style: const TextStyle(color: Colors.white)),
          trailing: editingText!.animationIn == anims[i].toLowerCase().replaceAll(' ', '')
              ? const Icon(Icons.check, color: Color(0xFF00D9FF))
              : null,
          onTap: () {
            setState(() {
              editingText = editingText!.copyWith(
                animationIn: anims[i].toLowerCase().replaceAll(' ', ''),
                animationOut: anims[i].toLowerCase().replaceAll(' ', ''),
              );
            });
          },
        );
      },
    );
  }

  Future<Color?> showColorPicker() async {
    return showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Pick Color', style: TextStyle(color: Colors.white)),
        content: Wrap(
          children: Colors.primaries.map((c) {
            return GestureDetector(
              onTap: () => Navigator.pop(context, c),
              child: Container(margin: const EdgeInsets.all(4), width: 40, height: 40, color: c),
            );
          }).toList(),
        ),
      ),
    );
  }
}