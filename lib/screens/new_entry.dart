import 'dart:io';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:snackbert/data/placeholder_messages.dart';
import 'package:snackbert/providers/audio_recording_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:health/health.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:snackbert/data/snackbert_messages.dart';
import 'package:snackbert/models/meal.dart';
import 'package:snackbert/models/meal_analysis.dart';
import 'package:snackbert/providers/meal_analysis_provider.dart';
import 'package:snackbert/providers/meal_submitting_provider.dart';
import 'package:snackbert/services/health_service.dart';
import 'package:snackbert/utils/snackbar.dart';
import 'package:snackbert/widgets/info_bracket.dart';
import 'package:snackbert/widgets/inputs/meal_image_picker.dart';
import 'package:snackbert/widgets/inputs/meal_recorder.dart';
import 'package:snackbert/widgets/loading_snackbert.dart';

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

  @override
  void initState() {
    super.initState();

    _textInputController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

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

    MealType approximateMealType(DateTime time) {
      final hour = time.hour;
      if (hour >= 6 && hour < 11) return MealType.BREAKFAST;
      if (hour >= 11 && hour < 15) return MealType.LUNCH;
      if (hour >= 15 && hour < 22) return MealType.DINNER;
      return MealType.SNACK;
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
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('meal_images')
            .child("$mealId.png");

        await storageRef.putFile(_selectedImage!);

        storageImagePath = 'meal_images/$mealId.png';
        fullImageUrl = await storageRef.getDownloadURL();
      }

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

      // add same meal to health connect as well
      await HealthService.instance.logMeal(
        name: mealAnalysisResult.title,
        // Health wants double rather than int
        calories: mealAnalysisResult.calories.toDouble(),
        carbs: mealAnalysisResult.carbs.toDouble(),
        protein: mealAnalysisResult.proteins.toDouble(),
        fat: mealAnalysisResult.fats.toDouble(),
        timestamp: meal.date,
        mealType: approximateMealType(meal.date),
      );

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
    _textInputController.removeListener(_updateState);
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
    final isRecordingAudio = ref.watch(audioRecordingProvider);

    final hasInput =
        _textInputController.text.trim().isNotEmpty ||
        _selectedImage != null ||
        _recordedAudio != null;

    return Scaffold(
      body: Center(
        child: isSubmitting
            ? const LoadingSnackbert(status: "waiting")
            : Padding(
                padding: EdgeInsetsGeometry.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InfoBracket(
                        icon: Icon(Icons.info_outline),
                        text: PlaceholderMessages.randomNewEntryInfoBoxMessage,
                        horMargin: 0,
                      ),

                      SizedBox(height: 16),

                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: IgnorePointer(
                              ignoring: isRecordingAudio,
                              child: MealImagePicker(
                                onPickImage: (image) {
                                  setState(() {
                                    _selectedImage = image;
                                  });
                                },
                              ),
                            ),
                          ),
                          oderText,
                          Expanded(
                            child: MealRecorder(
                              onPickAudio: (audioFile) {
                                setState(() {
                                  _recordedAudio = audioFile;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      oderText,

                      SizedBox(height: 8),

                      TextField(
                        enabled: !isRecordingAudio,
                        controller: _textInputController,
                        maxLines: 3,
                        maxLength: 1000,
                        style: textFieldTextStyle,
                        textCapitalization: TextCapitalization.sentences,
                        autocorrect: true,
                        enableSuggestions: true,
                        decoration: InputDecoration(
                          hintText:
                              PlaceholderMessages.randomNewEntryTextInputHint,
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                      ),

                      SizedBox(height: 8),

                      ElevatedButton.icon(
                        icon: Icon(Icons.send),
                        onPressed: (hasInput && !isRecordingAudio)
                            ? _onSendMeal
                            : null,
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
