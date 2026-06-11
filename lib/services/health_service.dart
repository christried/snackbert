// ignore_for_file: avoid_print

import 'package:health/health.dart';

class HealthService {
  HealthService._privateConstructor();
  static final HealthService instance = HealthService._privateConstructor();

  final Health _health = Health();
  bool _isInitialized = false;

  final List<HealthDataType> _types = [HealthDataType.NUTRITION];

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _health.configure();
      _isInitialized = true;
    } catch (e) {
      print("error while initializing health: $e");
    }
  }

  Future<bool> requestPermissions() async {
    if (!_isInitialized) await init();
    try {
      return await _health.requestAuthorization(
        _types,
        permissions: [HealthDataAccess.READ_WRITE],
      );
    } catch (e) {
      print("error while requesting permissions: $e");
      return false;
    }
  }

  MealType approximateMealType(DateTime time) {
    final hour = time.hour;
    if (hour >= 6 && hour < 11) return MealType.BREAKFAST;
    if (hour >= 11 && hour < 15) return MealType.LUNCH;
    if (hour >= 15 && hour < 22) return MealType.DINNER;
    return MealType.SNACK;
  }

  /// Writes a meal into health Connect incl. name, calories, mealType, macros and a timestamp
  Future<bool> logMeal({
    required String name,
    required double calories,
    required double carbs,
    required double protein,
    required double fat,
    required DateTime timestamp,
  }) async {
    if (!_isInitialized) await init();

    try {
      bool hasPermission = await requestPermissions();
      if (!hasPermission) return false;

      bool success = await _health.writeMeal(
        name: name,
        mealType: approximateMealType(timestamp),
        caloriesConsumed: calories,
        carbohydrates: carbs,
        protein: protein,
        fatTotal: fat,
        startTime: timestamp.subtract(const Duration(seconds: 1)),
        endTime: timestamp,
        recordingMethod: RecordingMethod.manual,
      );

      return success;
    } catch (e) {
      print("error writing the meal to Health Connect: $e");
      return false;
    }
  }
}
