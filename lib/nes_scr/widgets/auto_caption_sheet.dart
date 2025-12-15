import 'package:flutter/material.dart';

class AutoCaptionSheet extends StatelessWidget {
  const AutoCaptionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
              ),
              Text('Auto Caption'),
              SizedBox(width: 48),
            ],
          ),
          _fullButton('Generate from', 'Video'),
          _fullButton('Spoken Language', 'English'),
          _fullButton('Template', 'Classic'),
          _fullButton('Advanced', ''),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Generate captions using Whisper API or local model
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00D9FF),
              ),
              child: Text('Generate'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullButton(String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
          Text(subtitle, style: TextStyle(color: Colors.white54)),
          Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        ],
      ),
    );
  }
}
