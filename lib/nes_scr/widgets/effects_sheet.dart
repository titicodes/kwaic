import 'package:flutter/material.dart';

class EffectsSheet extends StatelessWidget {
  final Function(String? effect) onApply;

  const EffectsSheet({super.key, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Effects',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          ListTile(
            title: Text('None', style: TextStyle(color: Colors.white)),
            onTap: () => onApply(null),
          ),
          ListTile(
            title: Text('Shake', style: TextStyle(color: Colors.white)),
            onTap: () => onApply('shake'),
          ),
          ListTile(
            title: Text('Glitch', style: TextStyle(color: Colors.white)),
            onTap: () => onApply('glitch'),
          ),
        ],
      ),
    );
  }
}
