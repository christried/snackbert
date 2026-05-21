import 'dart:io';

import 'package:uuid/uuid.dart';

import 'package:snackbert/models/meal.dart';

class MealAnalysisService {
  MealAnalysisService();

  Future<MealAnalysisResult> analyzeMeal({
    String? text,
    File? image,
    File? audio,
  }) async {
    final trimmedText = text?.trim();
    final hasText = trimmedText != null && trimmedText.isNotEmpty;

    if (!hasText && image == null && audio == null) {
      throw ArgumentError(
        'Irgendein Input muss schon da sein - Bild, Text oder Audio.',
      );
    }

    // To be used once stuff is uploaded again
    // ignore: unused_local_variable
    final uploadId = Uuid().v4();

    // For now, return stub data
    return MealAnalysisResult(calories: 0, carbs: 0, fats: 0, proteins: 0);
  }
}
