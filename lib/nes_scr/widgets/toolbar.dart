import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Toolbar extends StatelessWidget {
  final Function(String) onToolSelected;

  const Toolbar({Key? key, required this.onToolSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[850],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: Icon(Icons.content_cut), onPressed: () => onToolSelected('split')),
          IconButton(icon: Icon(Icons.audiotrack), onPressed: () => onToolSelected('audio')),
          IconButton(icon: Icon(Icons.text_fields), onPressed: () => onToolSelected('text')),
          IconButton(icon: Icon(Icons.auto_awesome), onPressed: () => onToolSelected('effects')),
          IconButton(icon: Icon(Icons.layers), onPressed: () => onToolSelected('overlay')),
          IconButton(icon: Icon(Icons.share), onPressed: () => onToolSelected('export')),
        ],
      ),
    );
  }
}
