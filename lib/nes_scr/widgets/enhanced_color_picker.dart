// ========================================
// 3. ENHANCED COLOR PICKER WIDGET
// ========================================

import 'package:flutter/material.dart';
import 'dart:math' as math;

class EnhancedColorPicker extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorChanged;

  const EnhancedColorPicker({
    Key? key,
    required this.initialColor,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  State<EnhancedColorPicker> createState() => _EnhancedColorPickerState();
}

class _EnhancedColorPickerState extends State<EnhancedColorPicker> {
  late Color _selectedColor;
  late HSVColor _hsvColor;

  // Preset colors
  final List<Color> presetColors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _hsvColor = HSVColor.fromColor(_selectedColor);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF00D9FF),
            labelColor: Color(0xFF00D9FF),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Presets'),
              Tab(text: 'Custom'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPresetsTab(),
                _buildCustomTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: presetColors.length,
      itemBuilder: (context, index) {
        final color = presetColors[index];
        final isSelected = _selectedColor == color;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
              _hsvColor = HSVColor.fromColor(color);
            });
            widget.onColorChanged(color);
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF00D9FF) : Colors.white24,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: const Color(0xFF00D9FF).withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
                  : null,
            ),
            child: isSelected
                ? const Center(
              child: Icon(Icons.check, color: Colors.white, size: 20),
            )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildCustomTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Color preview
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
          ),
          const SizedBox(height: 24),

          // Hue slider
          _buildSliderSection(
            'Hue',
            _hsvColor.hue,
            0,
            360,
                (value) {
              setState(() {
                _hsvColor = _hsvColor.withHue(value);
                _selectedColor = _hsvColor.toColor();
              });
              widget.onColorChanged(_selectedColor);
            },
            gradient: LinearGradient(
              colors: [
                Colors.red,
                Colors.yellow,
                Colors.green,
                Colors.cyan,
                Colors.blue,
                Color(0xffFD3DB5),
                Colors.red,
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Saturation slider
          _buildSliderSection(
            'Saturation',
            _hsvColor.saturation,
            0,
            1,
                (value) {
              setState(() {
                _hsvColor = _hsvColor.withSaturation(value);
                _selectedColor = _hsvColor.toColor();
              });
              widget.onColorChanged(_selectedColor);
            },
            gradient: LinearGradient(
              colors: [
                Colors.grey,
                HSVColor.fromAHSV(1, _hsvColor.hue, 1, _hsvColor.value).toColor(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Value/Brightness slider
          _buildSliderSection(
            'Brightness',
            _hsvColor.value,
            0,
            1,
                (value) {
              setState(() {
                _hsvColor = _hsvColor.withValue(value);
                _selectedColor = _hsvColor.toColor();
              });
              widget.onColorChanged(_selectedColor);
            },
            gradient: LinearGradient(
              colors: [
                Colors.black,
                HSVColor.fromAHSV(1, _hsvColor.hue, _hsvColor.saturation, 1).toColor(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // RGB values
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorValue('R', _selectedColor.red),
              _buildColorValue('G', _selectedColor.green),
              _buildColorValue('B', _selectedColor.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection(
      String label,
      double value,
      double min,
      double max,
      Function(double) onChanged, {
        Gradient? gradient,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            Text(
              value.toStringAsFixed(0),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 30,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white24),
          ),
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 30,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorValue(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// Color Picker Palette Widget (Alternative design)
class ColorPickerPalette extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorChanged;

  const ColorPickerPalette({
    Key? key,
    required this.selectedColor,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ColorWheelPainter(selectedColor: selectedColor),
      child: GestureDetector(
        onPanUpdate: (details) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPosition = box.globalToLocal(details.globalPosition);
          final center = Offset(box.size.width / 2, box.size.height / 2);

          final dx = localPosition.dx - center.dx;
          final dy = localPosition.dy - center.dy;
          final distance = math.sqrt(dx * dx + dy * dy);
          final angle = math.atan2(dy, dx);

          if (distance <= box.size.width / 2) {
            final hue = (angle * 180 / math.pi + 360) % 360;
            final saturation = (distance / (box.size.width / 2)).clamp(0.0, 1.0);

            final color = HSVColor.fromAHSV(1, hue, saturation, 1).toColor();
            onColorChanged(color);
          }
        },
        child: Container(
          width: 250,
          height: 250,
          color: Colors.transparent,
        ),
      ),
    );
  }
}

class ColorWheelPainter extends CustomPainter {
  final Color selectedColor;

  ColorWheelPainter({required this.selectedColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw color wheel
    for (double i = 0; i < 360; i += 1) {
      final hue = i;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            HSVColor.fromAHSV(1, hue, 0, 1).toColor(),
            HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      final startAngle = (i - 0.5) * math.pi / 180;
      final sweepAngle = 1 * math.pi / 180;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
    }

    // Draw selected color indicator
    final hsvColor = HSVColor.fromColor(selectedColor);
    final selectedRadius = radius * hsvColor.saturation;
    final selectedAngle = hsvColor.hue * math.pi / 180;
    final selectedPos = Offset(
      center.dx + selectedRadius * math.cos(selectedAngle),
      center.dy + selectedRadius * math.sin(selectedAngle),
    );

    canvas.drawCircle(
      selectedPos,
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawCircle(
      selectedPos,
      8,
      Paint()..color = selectedColor,
    );
  }

  @override
  bool shouldRepaint(ColorWheelPainter oldDelegate) =>
      oldDelegate.selectedColor != selectedColor;
}

// Gradient Color Picker
class GradientColorPicker extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorChanged;

  const GradientColorPicker({
    Key? key,
    required this.initialColor,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  State<GradientColorPicker> createState() => _GradientColorPickerState();
}

class _GradientColorPickerState extends State<GradientColorPicker> {
  late Color _selectedColor;

  final List<List<Color>> gradientRows = [
    [Colors.red.shade900, Colors.red.shade700, Colors.red.shade500, Colors.red.shade300, Colors.red.shade100],
    [Colors.pink.shade900, Colors.pink.shade700, Colors.pink.shade500, Colors.pink.shade300, Colors.pink.shade100],
    [Colors.purple.shade900, Colors.purple.shade700, Colors.purple.shade500, Colors.purple.shade300, Colors.purple.shade100],
    [Colors.blue.shade900, Colors.blue.shade700, Colors.blue.shade500, Colors.blue.shade300, Colors.blue.shade100],
    [Colors.cyan.shade900, Colors.cyan.shade700, Colors.cyan.shade500, Colors.cyan.shade300, Colors.cyan.shade100],
    [Colors.green.shade900, Colors.green.shade700, Colors.green.shade500, Colors.green.shade300, Colors.green.shade100],
    [Colors.yellow.shade900, Colors.yellow.shade700, Colors.yellow.shade500, Colors.yellow.shade300, Colors.yellow.shade100],
    [Colors.orange.shade900, Colors.orange.shade700, Colors.orange.shade500, Colors.orange.shade300, Colors.orange.shade100],
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selected color preview
        Container(
          width: double.infinity,
          height: 60,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _selectedColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00D9FF), width: 2),
          ),
        ),

        // Gradient grid
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: gradientRows.length,
            itemBuilder: (context, rowIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: gradientRows[rowIndex].map((color) {
                    final isSelected = _selectedColor == color;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedColor = color);
                          widget.onColorChanged(color);
                        },
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00D9FF) : Colors.white24,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected
                              ? const Center(
                            child: Icon(Icons.check, color: Colors.white, size: 20),
                          )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}