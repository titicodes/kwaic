// ========================================
// 1. ANIMATED STICKERS WITH GIFs & Lottie
// ========================================

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';

import '../model/timeline_item.dart';
import 'enhanced_color_picker.dart';

class AnimatedStickersManager {
  // Lottie animations for transitions
  static const List<Map<String, dynamic>> lottieTransitions = [
    {'name': 'Fade', 'path': 'assets/lottie/fade.json', 'icon': Icons.blur_on},
    {'name': 'Wipe', 'path': 'assets/lottie/wipe.json', 'icon': Icons.swipe},
    {'name': 'Zoom', 'path': 'assets/lottie/zoom.json', 'icon': Icons.zoom_out_map},
    {'name': 'Slide', 'path': 'assets/lottie/slide.json', 'icon': Icons.view_carousel},
    {'name': 'Spin', 'path': 'assets/lottie/spin.json', 'icon': Icons.rotate_right},
    {'name': 'Bounce', 'path': 'assets/lottie/bounce.json', 'icon': Icons.sports_basketball},
  ];

  // Animated GIF stickers
  static const List<Map<String, dynamic>> gifStickers = [
    {'name': 'Fire', 'path': 'assets/gifs/fire.gif', 'emoji': '🔥'},
    {'name': 'Heart', 'path': 'assets/gifs/heart.gif', 'emoji': '❤️'},
    {'name': 'Star', 'path': 'assets/gifs/star.gif', 'emoji': '⭐'},
    {'name': 'Sparkle', 'path': 'assets/gifs/sparkle.gif', 'emoji': '✨'},
    {'name': 'Confetti', 'path': 'assets/gifs/confetti.gif', 'emoji': '🎉'},
    {'name': 'Lightning', 'path': 'assets/gifs/lightning.gif', 'emoji': '⚡'},
    {'name': 'Music', 'path': 'assets/gifs/music.gif', 'emoji': '🎵'},
    {'name': 'Camera', 'path': 'assets/gifs/camera.gif', 'emoji': '📸'},
  ];
}

// Animated Sticker Widget
class AnimatedStickerWidget extends StatefulWidget {
  final String? gifPath;
  final String? lottiePath;
  final double size;
  final bool repeat;

  const AnimatedStickerWidget({
    Key? key,
    this.gifPath,
    this.lottiePath,
    this.size = 100,
    this.repeat = true,
  }) : super(key: key);

  @override
  State<AnimatedStickerWidget> createState() => _AnimatedStickerWidgetState();
}

class _AnimatedStickerWidgetState extends State<AnimatedStickerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lottiePath != null) {
      return Lottie.asset(
        widget.lottiePath!,
        width: widget.size,
        height: widget.size,
        repeat: widget.repeat,
        controller: _controller,
        onLoaded: (composition) {
          _controller.duration = composition.duration;
        },
      );
    } else if (widget.gifPath != null) {
      return Image.file(
        File(widget.gifPath!),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }
    return const SizedBox();
  }
}

// Enhanced Sticker Selector with Animations
class EnhancedStickerSelector extends StatelessWidget {
  final Function(String type, String path) onStickerSelected;

  const EnhancedStickerSelector({Key? key, required this.onStickerSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Stickers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            const TabBar(
              indicatorColor: Color(0xFF00D9FF),
              labelColor: Color(0xFF00D9FF),
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(text: 'Animated'),
                Tab(text: 'Static'),
                Tab(text: 'Custom'),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildAnimatedStickers(),
                  _buildStaticStickers(),
                  _buildCustomStickers(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStickers() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: AnimatedStickersManager.gifStickers.length,
      itemBuilder: (context, index) {
        final sticker = AnimatedStickersManager.gifStickers[index];
        return GestureDetector(
          onTap: () => onStickerSelected('gif', sticker['path'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sticker['emoji'] as String,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 4),
                Text(
                  sticker['name'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaticStickers() {
    final emojis = [
      '😀', '😎', '🥳', '😍', '🤩', '😂', '🤣', '😭',
      '👍', '👏', '🙌', '💪', '🔥', '💯', '⭐', '✨'
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onStickerSelected('emoji', emojis[index]),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emojis[index], style: const TextStyle(fontSize: 40)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomStickers() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.upload_file, size: 64, color: Colors.white30),
          const SizedBox(height: 16),
          const Text(
            'Upload your own stickers',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Upload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// 2. CUSTOM FONTS FOR TEXT TOOL
// ========================================

class CustomFontsManager {
  static const List<Map<String, String>> fonts = [
    {'name': 'Default', 'family': ''},
    {'name': 'Roboto', 'family': 'Roboto'},
    {'name': 'Montserrat', 'family': 'Montserrat'},
    {'name': 'Poppins', 'family': 'Poppins'},
    {'name': 'Bebas Neue', 'family': 'BebasNeue'},
    {'name': 'Pacifico', 'family': 'Pacifico'},
    {'name': 'Dancing Script', 'family': 'DancingScript'},
    {'name': 'Press Start', 'family': 'PressStart2P'},
    {'name': 'Oswald', 'family': 'Oswald'},
    {'name': 'Raleway', 'family': 'Raleway'},
  ];

  static TextStyle getTextStyle(String fontFamily, {
    double fontSize = 32,
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return TextStyle(
      fontFamily: fontFamily.isEmpty ? null : fontFamily,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      shadows: [
        Shadow(
          offset: const Offset(1, 1),
          blurRadius: 3,
          color: Colors.black.withOpacity(0.5),
        ),
      ],
    );
  }
}

// Enhanced Text Editor with Fonts
class EnhancedTextEditor extends StatefulWidget {
  final TimelineItem item;
  final Function(TimelineItem) onUpdate;

  const EnhancedTextEditor({
    Key? key,
    required this.item,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EnhancedTextEditor> createState() => _EnhancedTextEditorState();
}

class _EnhancedTextEditorState extends State<EnhancedTextEditor> {
  late TextEditingController _controller;
  Color _selectedColor = Colors.white;
  double _fontSize = 32;
  String _fontFamily = '';
  FontWeight _fontWeight = FontWeight.bold;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.text);
    _selectedColor = widget.item.textColor ?? Colors.white;
    _fontSize = widget.item.fontSize ?? 32;
    _fontFamily = widget.item.fontFamily ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Text',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: _applyChanges,
                  icon: const Icon(Icons.check, color: Color(0xFF00D9FF)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Text Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              style: CustomFontsManager.getTextStyle(
                _fontFamily,
                fontSize: 20,
                color: Colors.white,
              ),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter text',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00D9FF)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tabs
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: Color(0xFF00D9FF),
                    labelColor: Color(0xFF00D9FF),
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      Tab(text: 'Font'),
                      Tab(text: 'Color'),
                      Tab(text: 'Style'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildFontTab(),
                        _buildColorTab(),
                        _buildStyleTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: CustomFontsManager.fonts.length,
      itemBuilder: (context, index) {
        final font = CustomFontsManager.fonts[index];
        final isSelected = _fontFamily == font['family'];

        return GestureDetector(
          onTap: () => setState(() => _fontFamily = font['family']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00D9FF).withOpacity(0.2) : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF00D9FF) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Text(
              font['name']!,
              style: CustomFontsManager.getTextStyle(
                font['family']!,
                fontSize: 18,
                color: isSelected ? const Color(0xFF00D9FF) : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorTab() {
    return EnhancedColorPicker(
      initialColor: _selectedColor,
      onColorChanged: (color) => setState(() => _selectedColor = color),
    );
  }

  Widget _buildStyleTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Font Size', style: TextStyle(color: Colors.white, fontSize: 16)),
        Slider(
          value: _fontSize,
          min: 12,
          max: 100,
          divisions: 88,
          activeColor: const Color(0xFF00D9FF),
          label: _fontSize.toInt().toString(),
          onChanged: (v) => setState(() => _fontSize = v),
        ),
        const SizedBox(height: 20),
        const Text('Font Weight', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildWeightButton('Normal', FontWeight.normal),
            _buildWeightButton('Bold', FontWeight.bold),
            _buildWeightButton('Extra Bold', FontWeight.w900),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightButton(String label, FontWeight weight) {
    final isSelected = _fontWeight == weight;
    return GestureDetector(
      onTap: () => setState(() => _fontWeight = weight),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D9FF) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: weight,
          ),
        ),
      ),
    );
  }

  void _applyChanges() {
    final updatedItem = widget.item.copyWith(
      text: _controller.text,
      textColor: _selectedColor,
      fontSize: _fontSize,
      fontFamily: _fontFamily,
    );
    widget.onUpdate(updatedItem);
    Navigator.pop(context);
  }
}

// Continue in next artifact...