// fill_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../provider/video_editor_provider.dart';

class FillBottomSheet extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onApply;

  const FillBottomSheet({
    super.key,
    required this.onClose,
    required this.onApply,
  });

  @override
  State<FillBottomSheet> createState() => _FillBottomSheetState();
}

class _FillBottomSheetState extends State<FillBottomSheet> {
  late Rect _localCrop;
  late double _localZoom;

  @override
  void initState() {
    super.initState();
    final provider = context.read<VideoEditorProvider>();
    provider.resetCrop(); // Start fresh every time
    _localCrop = provider.previewCropRect;
    _localZoom = provider.previewCropZoom;
  }

  void _updateCrop(Rect crop, double zoom) {
    setState(() {
      _localCrop = crop;
      _localZoom = zoom;
    });
    final provider = context.read<VideoEditorProvider>();
    provider.previewCropRect = crop;
    provider.previewCropZoom = zoom;
  }

  int get cropPercentage => ((1.0 / _localZoom) * 100).round().clamp(100, 999);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                  ),
                  const Text(
                    'Fill',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        '$cropPercentage%',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.white),
                        onPressed: widget.onApply,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // PREVIEW (CONSTRAINED)
            SizedBox(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CropPreview(
                  controller: context.read<VideoEditorProvider>().videoController!,
                  crop: _localCrop,
                  zoom: _localZoom,
                  onChanged: _updateCrop,
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

}

// Keep the CropPreview and _CropOverlayPainter classes exactly as before
// (Copy them from my previous message if not already in the file)

class CropPreview extends StatefulWidget {
  final VideoPlayerController controller;
  final Rect crop;
  final double zoom;
  final Function(Rect, double) onChanged;

  const CropPreview({
    required this.controller,
    required this.crop,
    required this.zoom,
    required this.onChanged,
    super.key,
  });

  @override
  State<CropPreview> createState() => _CropPreviewState();
}

class _CropPreviewState extends State<CropPreview> {
  late Rect _crop;
  late double _zoom;
  Size? _videoSize;

  @override
  void initState() {
    super.initState();
    _crop = widget.crop;
    _zoom = widget.zoom;
    _videoSize = widget.controller.value.size;
  }

  @override
  void didUpdateWidget(covariant CropPreview old) {
    super.didUpdateWidget(old);
    _crop = widget.crop;
    _zoom = widget.zoom;
  }

  void _handleScale(ScaleUpdateDetails details) {
    if (_videoSize == null) return;

    setState(() {
      final newZoom = (_zoom * details.scale).clamp(1.0, 5.0);

      final delta = details.focalPointDelta;
      final newLeft = (_crop.left - delta.dx / _videoSize!.width).clamp(0.0, 1.0 - _crop.width / newZoom);
      final newTop = (_crop.top - delta.dy / _videoSize!.height).clamp(0.0, 1.0 - _crop.height / newZoom);

      _crop = Rect.fromLTWH(newLeft, newTop, _crop.width, _crop.height);
      _zoom = newZoom;

      widget.onChanged(_crop, _zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_videoSize == null) return const Center(child: CircularProgressIndicator(color: Colors.white));

    final cropPixels = Rect.fromLTWH(
      _crop.left * _videoSize!.width,
      _crop.top * _videoSize!.height,
      _crop.width * _videoSize!.width / _zoom,
      _crop.height * _videoSize!.height / _zoom,
    );

    return GestureDetector(
      onScaleUpdate: _handleScale,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio,
            child: VideoPlayer(widget.controller),
          ),
          IgnorePointer(
            child:CustomPaint(
              painter: _CropOverlayPainter(cropPixels),
            ),

          ),
        ],
      ),
    );
  }
}


class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;

  _CropOverlayPainter(this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withOpacity(0.6);
    final border = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, dim);
    canvas.drawRect(cropRect, border);
  }

  @override
  bool shouldRepaint(_) => true;
}
