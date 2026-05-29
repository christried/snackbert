class MealAnalysisResult {
  MealAnalysisResult({
    required this.title,
    required this.appreciationMessage,
    required this.calories,
    required this.carbs,
    required this.fats,
    required this.proteins,
  });

  final String title;
  final String appreciationMessage;
  final int calories;
  final int carbs;
  final int fats;
  final int proteins;

  factory MealAnalysisResult.fromMap(Map<String, dynamic> map) {
    return MealAnalysisResult(
      title: _requireString(map, 'title'),
      appreciationMessage: _requireString(map, 'appreciationMessage'),
      calories: _requireInt(map, 'calories'),
      carbs: _requireInt(map, 'carbs'),
      fats: _requireInt(map, 'fats'),
      proteins: _requireInt(map, 'proteins'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'appreciationMessage': appreciationMessage,
      'calories': calories,
      'carbs': carbs,
      'fats': fats,
      'proteins': proteins,
    };
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

  static String _requireString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String) return value;
    if (value != null) return value.toString();

    throw FormatException('Ungültiger Wert für $key.');
  }
}
