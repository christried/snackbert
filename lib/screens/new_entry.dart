import 'dart:io';

import 'package:flutter/material.dart';
import 'package:snackbert/widgets/info_bracket.dart';
import 'package:snackbert/widgets/inputs/meal_image_picker.dart';
import 'package:snackbert/widgets/inputs/meal_recorder.dart';

class NewEntryScreen extends StatefulWidget {
  const NewEntryScreen({super.key});

  @override
  State<NewEntryScreen> createState() {
    return _NewEntryScreenState();
  }
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  // passed to meal_image_picker to also get it here whenever an image is picked there
  File? _selectedImage;
  File? _recordedAudio;

  void _onSendMeal() {
    print(_selectedImage);
    print(_recordedAudio);
  }

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
              InfoBracket(
                icon: Icon(Icons.info_outline),
                text: "Eine Eingabe reicht schon aus.",
                horMargin: 0,
              ),

              MealImagePicker(onPickImage: (image) => _selectedImage = image),

              Text("Textinput hier dann"),

              MealRecorder(
                onPickAudio: (audioFile) => _recordedAudio = audioFile,
              ),

              ElevatedButton.icon(
                icon: Icon(Icons.send),
                onPressed: _onSendMeal,
                label: Text("Eintragen"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
