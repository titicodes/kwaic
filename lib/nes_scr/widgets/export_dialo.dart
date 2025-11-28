import 'package:flutter/material.dart';

class ExportProgressDialog extends StatefulWidget {
  final Future<String?> exportFuture;

  const ExportProgressDialog({Key? key, required this.exportFuture})
    : super(key: key);

  @override
  State<ExportProgressDialog> createState() => _ExportProgressDialogState();
}

class _ExportProgressDialogState extends State<ExportProgressDialog> {
  double _progress = 0.0;
  String _status = 'Preparing export...';

  @override
  void initState() {
    super.initState();
    _startExport();
  }

  void _startExport() async {
    setState(() => _status = 'Exporting video...');

    final result = await widget.exportFuture;

    if (result != null && mounted) {
      setState(() {
        _progress = 1.0;
        _status = 'Export completed!';
      });

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context, result);
      }
    } else if (mounted) {
      setState(() => _status = 'Export failed');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_file, size: 64, color: Color(0xFF00D9FF)),
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: const Color(0xFF2A2A2A),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF00D9FF),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
