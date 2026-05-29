// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snackbert/models/meal.dart';
import 'package:snackbert/models/meal_analysis.dart';

import 'package:snackbert/providers/meal_analysis_provider.dart';
import 'package:snackbert/providers/meals_provider.dart';
import 'package:snackbert/utils/snackbar.dart';
import 'package:snackbert/widgets/info_bracket.dart';
import 'package:snackbert/widgets/inputs/meal_image_picker.dart';
import 'package:snackbert/widgets/inputs/meal_recorder.dart';
import 'package:snackbert/widgets/loading_snackbert.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

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
      showAppSnackBar(
        context,
        'Bitte Text, Bild oder Audio angeben.',
        isError: true,
      );
      return;
    }

    // to get rid of keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isSending = true;
    });

    try {
      // TODO use this to create a new entry in overview

      final MealAnalysisResult mealAnalysisResult = await ref
          .read(mealAnalysisServiceProvider)
          .analyzeMeal(
            text: hasText ? trimmedText : null,
            image: _selectedImage,
            audio: _recordedAudio,
          );

      // add image to firebase
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('meal_images')
          .child("${Random().nextDouble() * 1000}.png");

      if (_selectedImage == null) {
        final byteData = await rootBundle.load(
          'assets/snackbert_mascot_face.png',
        );
        final imageBytes = byteData.buffer.asUint8List();

        await storageRef.putData(imageBytes);
      } else {
        await storageRef.putFile(_selectedImage!);
      }

      final imageUrl = await storageRef.getDownloadURL();

      // add audio to firebase in case it exists - otherwise dont.
      String audioUrl;
      if (_recordedAudio == null) {
        audioUrl = "";
      } else {
        // upload and set audioUrl
        final audioStorageRef = FirebaseStorage.instance
            .ref()
            .child('meal_audios')
            .child("${Random().nextDouble() * 1000}.m4a");

        await audioStorageRef.putFile(_recordedAudio!);

        audioUrl = await audioStorageRef.getDownloadURL();
      }

      final Meal meal = Meal(
        id: uuid.v4(),
        userId: FirebaseAuth.instance.currentUser!.uid,
        date: DateTime.now(),
        title: mealAnalysisResult.title,
        appreciationMessage: mealAnalysisResult.appreciationMessage,
        calories: mealAnalysisResult.calories,
        macros: {
          Macro.carb: mealAnalysisResult.carbs,
          Macro.protein: mealAnalysisResult.proteins,
          Macro.fat: mealAnalysisResult.fats,
        },
        imageUrl: imageUrl,
        audioUrl: audioUrl,
        inputText: _textInputController.text,
      );

      final mealPayload = meal.toMap();

      // add meal to database
      await FirebaseFirestore.instance
          .collection("meals")
          .doc("${Random().nextDouble() * 1000}")
          .set(mealPayload);

      if (!mounted) return;

      showAppSnackBar(
        context,
        // TODO Motivational Quote + Meal Title will also be received by the LLM
        "Das muss richtig lecker sein, ich liebe Erdnüsse!",
      );
    } on ArgumentError catch (e) {
      showAppSnackBar(
        context,
        e.message ?? 'Ungültige Eingabe.',
        isError: true,
      );
    } on Exception catch (e) {
      showAppSnackBar(
        context,
        'Fehler beim Senden der Mahlzeit: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }

      // add entry and navigate to overview
      ref.read(mealsProvider.notifier).addDummyEntry();

      _selectedImage = null;
      _recordedAudio = null;
      _textInputController.clear();
    }
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

    final oderText = Text("oder", style: TextStyle(color: Colors.black38));

    return Scaffold(
      body: Center(
        child: _isSending
            ? LoadingSnackbert()
            : Padding(
                padding: EdgeInsetsGeometry.symmetric(
                  vertical: 0,
                  horizontal: 25,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InfoBracket(
                        icon: Icon(Icons.info_outline),
                        text: "Eine Eingabe reicht total aus.",
                        horMargin: 0,
                      ),

                      SizedBox(height: 32),

                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: MealImagePicker(
                              onPickImage: (image) => _selectedImage = image,
                            ),
                          ),
                          oderText,
                          Expanded(
                            child: MealRecorder(
                              onPickAudio: (audioFile) =>
                                  _recordedAudio = audioFile,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      oderText,

                      SizedBox(height: 16),

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

                      SizedBox(height: 16),

                      ElevatedButton.icon(
                        icon: Icon(Icons.send),
                        onPressed: _onSendMeal,
                        label: Text("Eintragen"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
