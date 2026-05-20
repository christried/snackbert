// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snackbert/providers/meal_analysis_provider.dart';

import 'package:snackbert/widgets/info_bracket.dart';
import 'package:snackbert/widgets/inputs/meal_image_picker.dart';
import 'package:snackbert/widgets/inputs/meal_recorder.dart';

class NewEntryScreen extends ConsumerStatefulWidget {
  const NewEntryScreen({super.key});

  @override
  ConsumerState<NewEntryScreen> createState() {
    return _NewEntryScreenState();
  }
}

class _NewEntryScreenState extends ConsumerState<NewEntryScreen> {
  File? _selectedImage;
  File? _recordedAudio;
  final _textInputController = TextEditingController();

  bool _isSending = false;

  Future<void> _onSendMeal() async {
    if (_isSending) return;

    final trimmedText = _textInputController.text.trim();
    final hasText = trimmedText.isNotEmpty;

    if (!hasText && _selectedImage == null && _recordedAudio == null) {
      _showSnackBar('Bitte Text, Bild oder Audio angeben.', isError: true);
      return;
    }

    // to get rid of keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isSending = true;
    });

    try {
      final result = await ref
          .read(mealAnalysisServiceProvider)
          .analyzeMeal(
            text: hasText ? trimmedText : null,
            image: _selectedImage,
            audio: _recordedAudio,
          );

      if (!mounted) return;

      _showSnackBar(
        'Kalorien: ${result.calories} kcal · '
        'Kohlenhydrate: ${result.carbs} g · '
        'Fette: ${result.fats} g · '
        'Proteine: ${result.proteins} g',
      );
    } on ArgumentError catch (e) {
      _showSnackBar(e.message ?? 'Ungültige Eingabe.', isError: true);
    } on Exception catch (e) {
      _showSnackBar('Fehler beim Senden der Mahlzeit: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool? isError = false}) {
    if (!mounted) return;
    final snackBarColor = Theme.of(context).colorScheme.primary;
    final snackBarTextStyle = Theme.of(context).textTheme.bodyMedium;

    final snackBarContent = ListTile(
      leading: Image.asset(
        isError!
            ? 'assets/snackbert_mascot_face_error.png'
            : 'assets/snackbert_mascot_face.png',
        width: 48,
        height: 48,
      ),
      title: Text(message, style: snackBarTextStyle),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: snackBarContent,
        backgroundColor: snackBarColor,
        padding: EdgeInsets.all(4),
      ),
    );
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
                  text: "Eine Eingabe reicht total aus.",
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
                  // TODO 1: Screen verbergen während _isSending läuft und dafür Snackbert Animation rein + circularprogressDingel
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
