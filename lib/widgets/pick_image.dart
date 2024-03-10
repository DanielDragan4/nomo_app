import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/providers/saved_session_provider.dart';

class ImageInput extends ConsumerStatefulWidget {
  const ImageInput({super.key, required this.onPickImage});

  final void Function(File image) onPickImage;

  @override
  ConsumerState<ImageInput> createState() {
    return _ImageInputState();
  }
}

class _ImageInputState extends ConsumerState<ImageInput> {
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
    uploadImage(_selectedImage!);
    widget.onPickImage(_selectedImage!);
  }

  Future<void> uploadImage(File imageFile) async {
    final supabase = ref.watch(supabaseInstance);
    final userId = (await supabase).client.auth.currentUser!.id.toString();
    final response = await (await supabase)
        .client
        .storage
        .from('Images')
        .upload('${userId}/anotherimage', imageFile);

    // if (response.error == null) {
    //   print('Image uploaded successfully');
    // } else {
    //   print('Upload error: ${response.error!.message}');
    // }
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
