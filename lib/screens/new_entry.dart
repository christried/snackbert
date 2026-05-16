import 'dart:io';

import 'package:flutter/material.dart';
import 'package:snackbert/widgets/inputs/meal_image_picker.dart';

class NewEntryScreen extends StatefulWidget {
  const NewEntryScreen({super.key});

  @override
  State<NewEntryScreen> createState() {
    return _NewEntryScreenState();
  }
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  File?
  _selectedImage; // passed to meal_image_picker to also get it here whenever an image is picked there

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 0, horizontal: 40),
          child: Column(
            spacing: 32,
            mainAxisSize: MainAxisSize.min,
            children: [
              MealImagePicker(onPickImage: (image) => _selectedImage = image),

              Text("Audio Aufnahme hier"),

              Text("Textinput hier dann"),

              ElevatedButton(onPressed: () {}, child: Text("Meal abschicken")),
            ],
          ),
        ),
      ),
    );
  }
}
