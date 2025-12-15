import 'package:flutter/material.dart';

import '../model/timeline_item.dart';
import '../servuices/clip_controller.dart';

class TextEditorSheet extends StatefulWidget {
  final ClipController clipController;
  final Duration insertPosition;
  final TimelineItem? editingItem; // null = new, else edit existing

  const TextEditorSheet({
    super.key,
    required this.clipController,
    required this.insertPosition,
    this.editingItem,
  });

  @override
  State<TextEditorSheet> createState() => _TextEditorSheetState();
}

class _TextEditorSheetState extends State<TextEditorSheet> {
  late TextEditingController _controller;
  Color _color = Colors.white;
  double _fontSize = 32;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.editingItem?.text ?? '');
  }

  Future<void> _addText() async {
    if (_controller.text.isEmpty) return;

    final item = (widget.editingItem ?? TimelineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TimelineItemType.text,
      startTime: widget.insertPosition,
      duration: const Duration(seconds: 5), // Default 5s
      originalDuration: const Duration(seconds: 5),
    )).copyWith(
      text: _controller.text,
      textColor: _color,
      fontSize: _fontSize,
      x: 100.0,
      y: 200.0,
      scale: 1.0,
      rotation: 0.0,
    );

    widget.clipController.addTextClip(item);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      builder: (_, controller) => Container(
        color: Color(0xFF1A1A1A),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                Text('Add Text', style: TextStyle(color: Colors.white, fontSize: 18)),
                IconButton(icon: Icon(Icons.check, color: Color(0xFF00D9FF)), onPressed: _addText),
              ],
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                style: TextStyle(color: _color, fontSize: _fontSize),
                decoration: InputDecoration(
                  hintText: 'Enter text',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(32),
                ),
              ),
            ),
            // Controls
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Color picker (simple for now)
                  GestureDetector(
                    onTap: () async {
                      final color = await showDialog<Color>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Pick a color'),
                          content: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: Colors.primaries.map((c) {
                              return GestureDetector(
                                onTap: () => Navigator.pop(context, c),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  color: c,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                      if (color != null) setState(() => _color = color);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      color: _color,
                      alignment: Alignment.center,
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                  ),

                  // Font size slider
                  Slider(
                    value: _fontSize,
                    min: 16,
                    max: 100,
                    onChanged: (v) => setState(() => _fontSize = v),
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