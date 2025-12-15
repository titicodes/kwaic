import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerTile extends StatefulWidget {
  final Function(String path) onPick;

  const ImagePickerTile({
    super.key,
    required this.onPick,
  });

  @override
  State<ImagePickerTile> createState() => _ImagePickerTileState();
}

class _ImagePickerTileState extends State<ImagePickerTile> {
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(14),
          ),
          child: selectedImage == null
              ? const Icon(Icons.add_photo_alternate,
              color: Colors.white70, size: 60)
              : ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(selectedImage!, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? f = await _picker.pickImage(source: ImageSource.gallery);
    if (f != null) {
      setState(() => selectedImage = File(f.path));
      widget.onPick(f.path);
    }
  }
}
