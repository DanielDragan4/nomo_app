import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// (Currently) useless garbage
class ImageInput extends StatefulWidget {
  const ImageInput({super.key, required this.onPickImage, this.previousImage});

  final void Function(File image) onPickImage;
  final String? previousImage;

  @override
  State<ImageInput> createState() {
    return _ImageInputState();
  }
}

class _ImageInputState extends State<ImageInput> {
  File? _selectedImage;

  void _takePicture() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 600,
    );

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _selectedImage = File(pickedImage.path);
    });
    widget.onPickImage(_selectedImage!);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.add, size: 50),
          onPressed: _takePicture,
        ),
        const Text('Add Image'),
      ],
    );

    if (_selectedImage != null) {
      content = GestureDetector(
        onTap: _takePicture,
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (widget.previousImage != null) {
      content = GestureDetector(
        onTap: _takePicture,
        child: Image.network(
          widget.previousImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 1,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      height: 250,
      width: double.infinity,
      alignment: Alignment.center,
      child: content,
    );
  }
}
