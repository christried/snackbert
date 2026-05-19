import 'dart:io';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

class MealImagePicker extends StatefulWidget {
  const MealImagePicker({super.key, required this.onPickImage});

  final void Function(File image) onPickImage;

  @override
  State<MealImagePicker> createState() {
    return _MealImagePickerState();
  }
}

class _MealImagePickerState extends State<MealImagePicker> {
  File? _selectedImage;

  void _takePicture() async {
    final imagePicker = ImagePicker();

    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1000,
    );

    if (pickedImage == null) return;

    setState(() {
      _selectedImage = File(pickedImage.path);
    });

    widget.onPickImage(_selectedImage!);
  }

  @override
  Widget build(BuildContext context) {
    // STYLING
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bodyLarge = theme.textTheme.bodyLarge!.copyWith(
      color: colors.primary,
    );

    Widget content = GestureDetector(
      onTap: _takePicture,

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/snackbert_mascot_cam.png', width: 64, height: 64),

          Text("Bild machen", style: bodyLarge),
        ],
      ),
    );

    if (_selectedImage != null) {
      content = GestureDetector(
        onTap: _takePicture,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Image.file(
            _selectedImage!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withAlpha(155),
        border: Border.all(
          width: 2,
          color: colors.primary.withAlpha(155),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      height: 200,
      width: double.infinity,
      alignment: Alignment.center,
      child: content,
    );
  }
}
