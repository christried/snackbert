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
  File? _selectedImage;
  File? _recordedAudio;
  final _textInputController = TextEditingController();

  // TODO Get this method to a meals provider and then call it from here with this stuff
  void _onSendMeal() {
    print(_selectedImage);
    print(_recordedAudio);
    print(_textInputController.text);
  }

  @override
  void dispose() {
    _textInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // STYLING
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textFieldTextStyle = theme.textTheme.bodyMedium!.copyWith(
      color: colors.primary,
    );

    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 0, horizontal: 40),
          child: SingleChildScrollView(
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

                TextField(
                  controller: _textInputController,
                  maxLines: 3,
                  maxLength: 1000,
                  style: textFieldTextStyle,
                  decoration: InputDecoration(
                    hint: Text(
                      "z.B. 200g Sojageschnetzeltes, 1 Paprika, 2 EL Öl [...]",
                    ),
                  ),
                ),

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
      ),
    );
  }
}
