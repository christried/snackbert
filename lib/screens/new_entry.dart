import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snackbert/data/snackbert_messages.dart';
import 'package:snackbert/models/meal.dart';
import 'package:snackbert/models/meal_analysis.dart';

import 'package:snackbert/providers/meal_analysis_provider.dart';
import 'package:snackbert/providers/meal_submitting_provider.dart';
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

  Future<void> _onSendMeal() async {
    if (ref.read(mealSubmittingProvider)) return;
    ref.read(mealSubmittingProvider.notifier).toggleSubmission();

    final trimmedText = _textInputController.text.trim();
    final hasText = trimmedText.isNotEmpty;

    if (!hasText && _selectedImage == null && _recordedAudio == null) {
      showAppSnackBar(
        context,
        SnackbertMessages.randomMissingInputMessage,
        isError: true,
      );
      ref.read(mealSubmittingProvider.notifier).toggleSubmission();
      return;
    }

    // to get rid of keyboard
    FocusScope.of(context).unfocus();

    String? storageImagePath;
    String? storageAudioPath;
    String fullImageUrl = '';
    String fullAudioUrl = '';
    String mealId = uuid.v4();

    try {
      // add image to firebase
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('meal_images')
          .child("$mealId.png");

      if (_selectedImage == null) {
        final byteData = await rootBundle.load(
          'assets/snackbert_mascot_face_shush.png',
        );
        final imageBytes = byteData.buffer.asUint8List();

        await storageRef.putData(imageBytes);
      } else {
        await storageRef.putFile(_selectedImage!);
      }

      storageImagePath = 'meal_images/$mealId.png';
      fullImageUrl = await storageRef.getDownloadURL();

      // add audio to firebase in case it exists - otherwise dont.
      if (_recordedAudio != null) {
        // upload and set audioUrl
        final audioStorageRef = FirebaseStorage.instance
            .ref()
            .child('meal_audios')
            .child("$mealId.m4a");

        await audioStorageRef.putFile(_recordedAudio!);

        storageAudioPath = 'meal_audios/$mealId.m4a';
        fullAudioUrl = await audioStorageRef.getDownloadURL();
      }

      final MealAnalysisResult mealAnalysisResult = await ref
          .read(mealAnalysisServiceProvider)
          .analyzeMeal(
            text: hasText ? trimmedText : null,
            imagePath: storageImagePath,
            imageMimeType: 'image/png',
            audioPath: storageAudioPath,
            audioMimeType: _recordedAudio != null ? 'audio/m4a' : null,
          );

      final Meal meal = Meal(
        id: mealId,
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
        imageUrl: fullImageUrl,
        audioUrl: fullAudioUrl,
        inputText: _textInputController.text,
      );

      final mealPayload = meal.toMap();

      // add meal to database
      await FirebaseFirestore.instance
          .collection("meals")
          .doc(mealPayload["id"])
          .set(mealPayload);

      if (!mounted) return;

      showAppSnackBar(context, mealAnalysisResult.appreciationMessage);
    } on ArgumentError catch (e) {
      showAppSnackBar(
        context,
        e.message ?? SnackbertMessages.randomErrorFallback,
        isError: true,
      );
    } on Exception catch (e, stackTrace) {
      // ignore: avoid_print
      print("Error during meal submission: $e");
      // ignore: avoid_print
      print(stackTrace);
      showAppSnackBar(
        context,
        SnackbertMessages.randomErrorFallback,
        isError: true,
      );
    } finally {
      if (mounted) {
        ref.read(mealSubmittingProvider.notifier).toggleSubmission();
      }

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

    final isSubmitting = ref.watch(mealSubmittingProvider);

    return Scaffold(
      body: Center(
        child: isSubmitting
            ? const LoadingSnackbert(status: "waiting")
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
                        textCapitalization: TextCapitalization.sentences,
                        autocorrect: true,
                        enableSuggestions: true,
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
