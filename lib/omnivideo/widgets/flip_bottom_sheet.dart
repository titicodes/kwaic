import 'package:flutter/material.dart';

class FlipBottomSheet extends StatelessWidget {
  final Function() onClose;
  final Function() onApply;
  final Function(bool) onFlip;

  const FlipBottomSheet({
    super.key,
    required this.onClose,
    required this.onApply,
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
                  'Flip',
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
                _buildFlipOption(
                  Icons.flip,
                  'Horizontal',
                  true,
                      () => onFlip(true),
                ),
                const SizedBox(width: 20),
                _buildFlipOption(
                  Icons.flip,
                  'Vertical',
                  false,
                      () => onFlip(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipOption(
      IconData icon, String label, bool isHorizontal, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
            child: Transform.rotate(
              angle: isHorizontal ? 0 : 1.57,
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
