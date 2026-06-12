import 'dart:io';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:snackbert/data/placeholder_messages.dart';
import 'package:snackbert/providers/audio_recording_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:snackbert/data/snackbert_messages.dart';
import 'package:snackbert/providers/meal_submitting_provider.dart';
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
  late String _infoBoxMessage;
  late String _textInputHint;

  @override
  void initState() {
    super.initState();
    _textInputHint = PlaceholderMessages.randomNewEntryTextInputHint;
    _infoBoxMessage = PlaceholderMessages.randomNewEntryInfoBoxMessage;

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

    FocusScope.of(context).unfocus();

    String? storageImagePath;
    String? storageAudioPath;
    String mealId = uuid.v4();

    try {
      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('meal_images')
            .child('$mealId.png');
        await ref.putFile(_selectedImage!);
        storageImagePath = 'meal_images/$mealId.png';
      }

      if (_recordedAudio != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('meal_audios')
            .child('$mealId.m4a');
        await ref.putFile(_recordedAudio!);
        storageAudioPath = 'meal_audios/$mealId.m4a';
      }
      await FirebaseFirestore.instance.collection('meals').doc(mealId).set({
        'id': mealId,
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'date': DateTime.now().toIso8601String(),
        'status': 'pending',
        'inputText': trimmedText,
        'imagePath': storageImagePath,
        'imageMimeType': _selectedImage != null ? 'image/png' : null,
        'audioPath': storageAudioPath,
        'audioMimeType': _recordedAudio != null ? 'audio/m4a' : null,
      });

      if (mounted) {
        showAppSnackBar(
          context,
          SnackbertMessages.randomAnalyzingMessage,
          isAnalyzing: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          SnackbertMessages.randomErrorFallback,
          isError: true,
        );
      }
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
                        text: _infoBoxMessage,
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
                          hintText: _textInputHint,
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
