// import 'package:flutter/material.dart';
//
// class RotateBottomSheet extends StatefulWidget {
//   final VoidCallback onClose;
//   final VoidCallback onApply;
//   final Function(double) onRotate;
//   final VoidCallback onFlip;
//
//   const RotateBottomSheet({
//     super.key,
//     required this.onClose,
//     required this.onApply,
//     required this.onRotate,
//     required this.onFlip,
//   });
//
//   @override
//   State<RotateBottomSheet> createState() => _RotateBottomSheetState();
// }
//
// class _RotateBottomSheetState extends State<RotateBottomSheet> {
//   double _currentRotation = 0.0;
//
//   void _rotate(double angle) {
//     setState(() {
//       _currentRotation += angle;
//     });
//     widget.onRotate(angle);
//   }
//
//   void _reset() {
//     setState(() {
//       _currentRotation = 0.0;
//     });
//     // You can also reset in provider if needed
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 180,
//       decoration: const BoxDecoration(
//         color: Color(0xFF1A1A1A),
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         children: [
//           // Header
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.close, color: Colors.white),
//                   onPressed: widget.onClose,
//                 ),
//                 const Text(
//                   'Rotate & Flip',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.check_circle, color: Color(0xFF00D9FF)),
//                   onPressed: widget.onApply,
//                 ),
//               ],
//             ),
//           ),
//
//           const Divider(height: 1, color: Colors.grey),
//
//           // Current rotation display
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 12),
//             child: Text(
//               'Current Rotation: ${_currentRotation.toStringAsFixed(0)}°',
//               style: const TextStyle(
//                 color: Colors.white70,
//                 fontSize: 16,
//               ),
//             ),
//           ),
//
//           // Controls
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildControlButton(
//                     icon: Icons.rotate_left,
//                     label: '-90°',
//                     onTap: () => _rotate(-90),
//                   ),
//                   _buildControlButton(
//                     icon: Icons.rotate_right,
//                     label: '+90°',
//                     onTap: () => _rotate(90),
//                   ),
//                   _buildControlButton(
//                     icon: Icons.flip,
//                     label: 'Flip',
//                     onTap: widget.onFlip,
//                   ),
//                   _buildControlButton(
//                     icon: Icons.refresh,
//                     label: 'Reset',
//                     onTap: _reset,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildControlButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 60,
//             height: 60,
//             decoration: BoxDecoration(
//               color: Colors.grey[800],
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Icon(icon, color: Colors.white, size: 32),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class RotateBottomSheet extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onApply;
  final Function(double) onRotate;
  final VoidCallback onFlipHorizontal;
  final VoidCallback onFlipVertical;

  const RotateBottomSheet({
    super.key,
    required this.onClose,
    required this.onApply,
    required this.onRotate,
    required this.onFlipHorizontal,
    required this.onFlipVertical,
  });

  @override
  State<RotateBottomSheet> createState() => _RotateBottomSheetState();
}

class _RotateBottomSheetState extends State<RotateBottomSheet> {
  double _currentRotation = 0.0;
  bool _flipHorizontal = false;
  bool _flipVertical = false;

  void _rotate(double angle) {
    setState(() {
      _currentRotation += angle;
    });
    widget.onRotate(angle);
  }

  void _toggleFlipHorizontal() {
    setState(() {
      _flipHorizontal = !_flipHorizontal;
    });
    widget.onFlipHorizontal();
  }

  void _toggleFlipVertical() {
    setState(() {
      _flipVertical = !_flipVertical;
    });
    widget.onFlipVertical();
  }

  void _reset() {
    setState(() {
      _currentRotation = 0.0;
      _flipHorizontal = false;
      _flipVertical = false;
    });
    // Reset in provider if needed
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
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
                  'Rotate & Flip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Color(0xFF00D9FF)),
                  onPressed: widget.onApply,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.grey),

          // Current state preview
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Rotation: ${_currentRotation.toStringAsFixed(0)}°  |  '
                  'Flip: ${_flipHorizontal ? 'H' : ''}${_flipVertical ? 'V' : ''}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),

          // Controls
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.rotate_left,
                    label: '-90°',
                    onTap: () => _rotate(-90),
                  ),
                  _buildControlButton(
                    icon: Icons.rotate_right,
                    label: '+90°',
                    onTap: () => _rotate(90),
                  ),
                  _buildControlButton(
                    icon: Icons.flip,
                    label: 'Horizontal',
                    onTap: _toggleFlipHorizontal,
                    active: _flipHorizontal,
                  ),
                  _buildControlButton(
                    icon: Icons.flip,
                    label: 'Vertical',
                    onTap: _toggleFlipVertical,
                    active: _flipVertical,
                  ),
                  _buildControlButton(
                    icon: Icons.refresh,
                    label: 'Reset',
                    onTap: _reset,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF00D9FF).withOpacity(0.3) : Colors.grey[800],
              borderRadius: BorderRadius.circular(16),
              border: active ? Border.all(color: const Color(0xFF00D9FF), width: 2) : null,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF00D9FF) : Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}