import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CropEditor extends StatefulWidget {
  final VideoPlayerController videoController;
  final Function(double x, double y, double w, double h) onCrop;
  const CropEditor({required this.videoController, required this.onCrop});

  @override State<CropEditor> createState() => _CropEditorState();
}

class _CropEditorState extends State<CropEditor> {
  late TransformationController _transformController;
  double cropX = 0, cropY = 0, cropW = 1, cropH = 1;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Crop & Mask', style: TextStyle(color: Colors.white, fontSize: 20)),
        ),
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 1.0,
            maxScale: 5.0,
            child: AspectRatio(
              aspectRatio: widget.videoController.value.aspectRatio,
              child: VideoPlayer(widget.videoController),
            ),
            onInteractionEnd: (details) {
              final matrix = _transformController.value;
              // Convert matrix to crop values (simplified)
              final scale = matrix.getMaxScaleOnAxis();
              setState(() {
                cropW = 1 / scale;
                cropH = 1 / scale;
              });
              widget.onCrop(0.5 - cropW / 2, 0.5 - cropH / 2, cropW, cropH);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Free', '16:9', '9:16', '1:1', '4:3'].map((ratio) {
              return ElevatedButton(
                onPressed: () {
                  double w = 1.0, h = 1.0;
                  if (ratio == '16:9') { w = 16/9; h = 1; }
                  if (ratio == '9:16') { w = 9/16; h = 1; }
                  if (ratio == '1:1') { w = h = 1; }
                  if (ratio == '4:3') { w = 4/3; h = 1; }
                  widget.onCrop(0.5 - w/2, 0.5 - h/2, w, h);
                  Navigator.pop(context);
                },
                child: Text(ratio),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}