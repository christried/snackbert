import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snackbert/services/meal_analysis_service.dart';

final mealAnalysisServiceProvider = Provider((ref) {
  return MealAnalysisService();
});
