import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

enum Macro { carb, protein, fat }

class NewMeal {
  NewMeal({this.image, this.audio, this.text});

  File? image;
  File? audio;
  String? text;
}

class Meal {
  Meal({
    // set on Creation
    required this.id,
    required this.userId,
    required this.date,
    // get back from LLM
    required this.title,
    required this.appreciationMessage,
    required this.calories,
    required this.macros,
    // User Input, emptry strings are fine
    required this.imageUrl,
    required this.audioUrl,
    required this.inputText,
  });

  // set on Creation
  final String id;
  final String userId;
  final DateTime date;
  // get back from LLM
  final String title;
  final String appreciationMessage;
  final int calories;
  final Map<Macro, int> macros;
  // User Input, emptry strings are fine
  final String imageUrl;
  final String audioUrl;
  final String inputText;

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: _requireString(map, 'id'),
      userId: _requireString(map, 'userId'),
      date: _requireDateTime(map, 'date'),
      title: _requireString(map, 'title'),
      appreciationMessage: _requireString(map, 'appreciationMessage'),
      calories: _requireInt(map, 'calories'),
      macros: _requireMacroMap(map, 'macros'),
      imageUrl: _requireString(map, 'imageUrl'),
      audioUrl: _requireString(map, 'audioUrl'),
      inputText: _requireString(map, 'inputText'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'title': title,
      'appreciationMessage': appreciationMessage,
      'calories': calories,
      'macros': _macrosToMap(macros),
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'inputText': inputText,
    };
  }

  Meal copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? title,
    String? appreciationMessage,
    int? calories,
    Map<Macro, int>? macros,
    String? imageUrl,
    String? audioUrl,
    String? inputText,
  }) {
    return Meal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      title: title ?? this.title,
      appreciationMessage: appreciationMessage ?? this.appreciationMessage,
      calories: calories ?? this.calories,
      macros: macros ?? this.macros,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      inputText: inputText ?? this.inputText,
    );
  }

  static Map<String, int> _macrosToMap(Map<Macro, int> macros) {
    return {for (final entry in macros.entries) entry.key.name: entry.value};
  }

  static Map<Macro, int> _requireMacroMap(
    Map<String, dynamic> map,
    String key,
  ) {
    final value = map[key];
    if (value is Map) {
      final result = <Macro, int>{};
      for (final entry in value.entries) {
        final macro = _macroFromKey(entry.key);
        if (macro == null) {
          throw FormatException('Ungültiger Makro-Key: ${entry.key}.');
        }
        result[macro] = _valueAsInt(entry.value, 'macros.${macro.name}');
      }
      return result;
    }
    throw FormatException('Ungültiger Wert für $key.');
  }

  static Macro? _macroFromKey(Object? key) {
    final name = key?.toString();
    switch (name) {
      case 'carb':
        return Macro.carb;
      case 'protein':
        return Macro.protein;
      case 'fat':
        return Macro.fat;
      default:
        return null;
    }
  }

  static DateTime _requireDateTime(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is DateTime) {
      return value;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Ungültiger Wert für $key.');
  }

  static int _requireInt(Map<String, dynamic> map, String key) {
    return _valueAsInt(map[key], key);
  }

  static int _valueAsInt(Object? value, String key) {
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
