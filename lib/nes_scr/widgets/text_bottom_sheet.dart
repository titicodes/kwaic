import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';

class TextBottomSheet extends StatefulWidget {
  final Function(String text, Map<String, dynamic> style) onApply;

  const TextBottomSheet({super.key, required this.onApply});

  @override
  State<TextBottomSheet> createState() => _TextBottomSheetState();
}

class _TextBottomSheetState extends State<TextBottomSheet>
    with TickerProviderStateMixin  {
  late TabController _mainTabController;
  late TabController _templateSubTabController;

  // Current style
  String _selectedFont = 'Roboto';
  String _selectedAnimation = 'None';
  Color _textColor = Colors.white;
  Color _shadowColor = Colors.black;
  double _shadowBlur = 4.0;
  double _strokeWidth = 2.0;
  Color _strokeColor = Colors.black;

  final List<String> _fonts = [
    'Roboto',
    'Montserrat',
    'Oswald',
    'Lobster',
    'Pacifico',
    'Dancing Script',
    'Bebas Neue',
    'Raleway',
    'Poppins',
    'Lato',
  ];

  final List<String> _animations = [
    'None',
    'Typewriter',
    'Fade',
    'Wave',
    'Scale',
    'Rotate',
    'Flicker',
    'Wavy',
  ];

  final List<Map<String, dynamic>> _mockTemplates = [
    // Trending
    {
      'text': 'GO VIRAL',
      'style': {'color': '#FF0066', 'font': 'Bebas Neue', 'animation': 'scale'},
    },
    {
      'text': 'TRENDING NOW',
      'style': {'color': '#00FFAA', 'font': 'Oswald', 'animation': 'fade'},
    },
    // Christmas
    {
      'text': 'MERRY CHRISTMAS',
      'style': {'color': '#FF0000', 'font': 'Pacifico', 'animation': 'wave'},
    },
    // New Year
    {
      'text': 'HAPPY 2026',
      'style': {'color': '#FFD700', 'font': 'Lobster', 'animation': 'flicker'},
    },
    // Classic
    {
      'text': 'CLASSIC',
      'style': {
        'color': '#FFFFFF',
        'font': 'Raleway',
        'animation': 'typewriter',
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 8, vsync: this);
    _templateSubTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _templateSubTabController.dispose();
    super.dispose();
  }

  void _applyStyle(String text, Map<String, dynamic> style) {
    final appliedStyle = {
      'font': style['font'] ?? _selectedFont,
      'color': style['color'] ?? '#FFFFFF',
      'animation': style['animation'] ?? _selectedAnimation,
      'shadowColor': _shadowColor.value.toRadixString(16),
      'shadowBlur': _shadowBlur,
      'strokeWidth': _strokeWidth,
      'strokeColor': _strokeColor.value.toRadixString(16),
    };
    widget.onApply(text, appliedStyle);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Search + Tick
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search templates, fonts...',
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.white70),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.check, color: Color(0xFF00D9FF)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Main Tabs
          TabBar(
            controller: _mainTabController,
            isScrollable: true,
            labelColor: Color(0xFF00D9FF),
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Template'),
              Tab(text: 'Fonts'),
              Tab(text: 'Style'),
              Tab(text: 'Effect'),
              Tab(text: 'Animation'),
              Tab(text: 'Bubbles'),
              Tab(text: 'Classic'),
              Tab(text: 'New'),
            ],
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                _buildTemplateTab(),
                _buildFontsTab(),
                _buildStyleTab(),
                _buildEffectsTab(),
                _buildAnimationTab(),
                Center(
                  child: Text(
                    'Bubbles coming soon',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                Center(
                  child: Text(
                    'Classic templates',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                Center(
                  child: Text(
                    'New templates',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateTab() {
    return Column(
      children: [
        TabBar(
          controller: _templateSubTabController,
          isScrollable: true,
          labelColor: Color(0xFF00D9FF),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Trending'),
            Tab(text: 'Christmas'),
            Tab(text: 'New Year'),
            Tab(text: 'Classic'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _templateSubTabController,
            children: [
              _buildTemplateGrid(0, 2),
              _buildTemplateGrid(2, 3),
              _buildTemplateGrid(3, 4),
              _buildTemplateGrid(4, 5),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateGrid(int start, int end) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.6,
      ),
      itemCount: end - start,
      itemBuilder: (_, i) {
        final template = _mockTemplates[start + i];
        return GestureDetector(
          onTap: () {
            _applyStyle(template['text'], template['style']);
            Navigator.pop(context);
          },
          child: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Center(
              child: Text(
                template['text'],
                style: GoogleFonts.getFont(
                  template['style']['font'],
                  color: Color(
                    int.parse(
                      template['style']['color'].replaceFirst('#', '0xFF'),
                    ),
                  ),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFontsTab() {
    return ListView.builder(
      itemCount: _fonts.length,
      itemBuilder: (_, i) {
        final font = _fonts[i];
        return ListTile(
          title: Text(
            'Aa',
            style: GoogleFonts.getFont(font, color: Colors.white, fontSize: 20),
          ),
          subtitle: Text(font, style: TextStyle(color: Colors.white70)),
          trailing:
              _selectedFont == font
                  ? Icon(Icons.check, color: Color(0xFF00D9FF))
                  : null,
          onTap: () {
            setState(() => _selectedFont = font);
            _applyStyle('Sample Text', {'font': font});
          },
        );
      },
    );
  }

  Widget _buildAnimationTab() {
    return ListView.builder(
      itemCount: _animations.length,
      itemBuilder: (_, i) {
        final anim = _animations[i];
        return ListTile(
          title: Text(anim, style: TextStyle(color: Colors.white)),
          trailing:
              _selectedAnimation == anim
                  ? Icon(Icons.check, color: Color(0xFF00D9FF))
                  : null,
          onTap: () {
            setState(() => _selectedAnimation = anim);
            _applyStyle('Animated', {'animation': anim.toLowerCase()});
          },
        );
      },
    );
  }

  Widget _buildEffectsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Text Color
          _effectRow(
            'Text Color',
            Container(width: 40, height: 40, color: _textColor),
            () async {
              final color = await _pickColor(_textColor);
              if (color != null) setState(() => _textColor = color);
            },
          ),
          // Shadow Color
          _effectRow(
            'Shadow Color',
            Container(width: 40, height: 40, color: _shadowColor),
            () async {
              final color = await _pickColor(_shadowColor);
              if (color != null) setState(() => _shadowColor = color);
            },
          ),
          _sliderRow(
            'Shadow Blur',
            _shadowBlur,
            0,
            20,
            (v) => setState(() => _shadowBlur = v),
          ),
          // Stroke
          _effectRow(
            'Stroke Color',
            Container(width: 40, height: 40, color: _strokeColor),
            () async {
              final color = await _pickColor(_strokeColor);
              if (color != null) setState(() => _strokeColor = color);
            },
          ),
          _sliderRow(
            'Stroke Width',
            _strokeWidth,
            0,
            10,
            (v) => setState(() => _strokeWidth = v),
          ),
        ],
      ),
    );
  }

  Widget _effectRow(String label, Widget preview, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.white)),
          Spacer(),
          GestureDetector(onTap: onTap, child: preview),
        ],
      ),
    );
  }

  Widget _sliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.white)),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              activeColor: Color(0xFF00D9FF),
            ),
          ),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Future<Color?> _pickColor(Color current) async {
    return showDialog<Color>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Color(0xFF1A1A1A),
            title: Text('Pick Color', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: BlockPicker(
                pickerColor: current,
                onColorChanged: (c) => Navigator.pop(context, c),
              ),
            ),
          ),
    );
  }

  Widget _buildStyleTab() {
    return Center(
      child: Text(
        'Style presets coming soon',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}
