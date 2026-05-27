import 'dart:io';

enum Macro { carb, protein, fat }

class NewMeal {
  NewMeal({this.image, this.audio, this.text});

  File? image;
  File? audio;
  String? text;
}

class Meal {
  Meal({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.date,
    required this.calories,
    required this.macros,
  });

  String id;
  final String title;
  final String imageUrl;
  final DateTime date;
  final int calories;
  final Map<Macro, int> macros;
}

class MealAnalysisResult {
  MealAnalysisResult({
    required this.calories,
    required this.carbs,
    required this.fats,
    required this.proteins,
  });

  final int calories;
  final int carbs;
  final int fats;
  final int proteins;

  factory MealAnalysisResult.fromMap(Map<String, dynamic> map) {
    return MealAnalysisResult(
      calories: _requireInt(map, 'calories'),
      carbs: _requireInt(map, 'carbs'),
      fats: _requireInt(map, 'fats'),
      proteins: _requireInt(map, 'proteins'),
    );
  }

  static int _requireInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    throw FormatException('Ungültiger Wert für $key.');
  }
}
