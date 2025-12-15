import 'package:flutter/material.dart';

import '../model/timeline_item.dart';

class VolumeSheet extends StatefulWidget {
  final TimelineItem clip;
  const VolumeSheet({super.key, required this.clip});

  @override
  State<VolumeSheet> createState() => _VolumeSheetState();
}

class _VolumeSheetState extends State<VolumeSheet> {
  double volume = 1.0;

  @override
  void initState() {
    super.initState();
    volume = widget.clip.volume ?? 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: Color(0xFF1A1A1A),
      child: Column(
        children: [
          Padding(padding: EdgeInsets.all(16), child: Text('Volume')),
          Slider(
            value: volume,
            min: 0,
            max: 2,
            onChanged: (v) {
              setState(() => volume = v);
              widget.clip.volume = v;
              // Update audio manager
            },
          ),
          Text('${(volume * 100).round()}%'),
        ],
      ),
    );
  }
}
