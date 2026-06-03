import 'package:cloud_functions/cloud_functions.dart';
import 'package:snackbert/models/meal_analysis.dart';

class MealAnalysisService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<MealAnalysisResult> analyzeMeal({
    String? text,
    String? imagePath,
    String? imageMimeType,
    String? audioPath,
    String? audioMimeType,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'analyzeMealData',
      );

      final Map<String, dynamic> payload = {};

      if (text != null && text.isNotEmpty) payload['text'] = text;
      if (imagePath != null) payload['imagePath'] = imagePath;
      if (imageMimeType != null) payload['imageMimeType'] = imageMimeType;
      if (audioPath != null) payload['audioPath'] = audioPath;
      if (audioMimeType != null) payload['audioMimeType'] = audioMimeType;

      final response = await callable.call(payload);

      // Gemini API guarantees the defined responseSchema so
      // response.data is guaranteed to be a Map<String, dynamic> (I hope)
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data as Map,
      );

      return MealAnalysisResult.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Backend Error [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('Failed to process meal analysis: $e');
    }
  }
}
