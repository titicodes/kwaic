import 'package:flutter/material.dart';

class RotateBottomSheet extends StatelessWidget {
  final Function() onClose;
  final Function() onApply;
  final Function(double) onRotate;
  final Function() onFlip;

  const RotateBottomSheet({
    super.key,
    required this.onClose,
    required this.onApply,
    required this.onRotate,
    required this.onFlip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      color: Colors.black,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onClose,
                ),
                const Text(
                  'Rotate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: onApply,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRotateOption(
                  Icons.rotate_90_degrees_ccw,
                  'Rotate 90°',
                      () => onRotate(-90),
                ),
                const SizedBox(width: 20),
                _buildRotateOption(
                  Icons.rotate_90_degrees_cw,
                  'Rotate -90°',
                      () => onRotate(90),
                ),
                const SizedBox(width: 20),
                _buildRotateOption(
                  Icons.flip,
                  'Flip',
                  onFlip,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotateOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.black
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
