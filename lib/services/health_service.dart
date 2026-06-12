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

      await requestPermissions();
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
  Future<String?> logMeal({
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
      if (!hasPermission) return null;

      final startTime = timestamp.subtract(const Duration(seconds: 1));
      final endTime = timestamp;

      bool success = await _health.writeMeal(
        name: name,
        mealType: approximateMealType(timestamp),
        caloriesConsumed: calories,
        carbohydrates: carbs,
        protein: protein,
        fatTotal: fat,
        startTime: startTime,
        endTime: endTime,
        recordingMethod: RecordingMethod.manual,
      );

      if (!success) return null;

      // Get the UUID of the new record to edit/delete it later
      final results = await _health.getHealthDataFromTypes(
        types: [HealthDataType.NUTRITION],
        startTime: startTime,
        endTime: endTime,
      );

      final match = results.firstWhere(
        (p) =>
            p.value is NutritionHealthValue &&
            (p.value as NutritionHealthValue).name == name,
        orElse: () => results.first,
      );

      return match.uuid.isNotEmpty ? match.uuid : null;
    } catch (e) {
      print("error writing the meal to Health Connect: $e");
      return null;
    }
  }

  Future<void> removeFromHealth({required String healthUuid}) async {
    if (!_isInitialized) await init();
    try {
      await _health.deleteByUUID(
        type: HealthDataType.NUTRITION,
        uuid: healthUuid,
      );
    } catch (e) {
      print("error removing meal from Health Connect: $e");
    }
  }
}
