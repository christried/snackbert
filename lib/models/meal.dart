import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

enum Macro { carb, protein, fat }

enum MealStatus { pending, done, error }

class NewMeal {
  NewMeal({this.image, this.audio, this.text});
  File? image;
  File? audio;
  String? text;
}

class Meal {
  Meal({
    required this.id,
    required this.userId,
    required this.date,
    required this.status,
    // LLM fields
    this.title,
    this.appreciationMessage,
    this.calories,
    this.macros,
    // User input
    required this.imageUrl,
    required this.audioUrl,
    required this.inputText,
    // Raw storage paths
    this.imagePath,
    this.imageMimeType,
    this.audioPath,
    this.audioMimeType,
    this.errorMessage,
  });

  final String id;
  final String userId;
  final DateTime date;
  final MealStatus status;
  final String? title;
  final String? appreciationMessage;
  final int? calories;
  final Map<Macro, int>? macros;
  final String imageUrl;
  final String audioUrl;
  final String inputText;
  final String? imagePath;
  final String? imageMimeType;
  final String? audioPath;
  final String? audioMimeType;
  final String? errorMessage;

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: _requireString(map, 'id'),
      userId: _requireString(map, 'userId'),
      date: _requireDateTime(map, 'date'),
      status: _parseStatus(map['status']),
      title: map['title'] as String?,
      appreciationMessage: map['appreciationMessage'] as String?,
      calories: map['calories'] == null
          ? null
          : _valueAsInt(map['calories'], 'calories'),
      macros: map['macros'] == null ? null : _requireMacroMap(map, 'macros'),
      imageUrl: (map['imageUrl'] as String?) ?? '',
      audioUrl: (map['audioUrl'] as String?) ?? '',
      inputText: (map['inputText'] as String?) ?? '',
      imagePath: map['imagePath'] as String?,
      imageMimeType: map['imageMimeType'] as String?,
      audioPath: map['audioPath'] as String?,
      audioMimeType: map['audioMimeType'] as String?,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'status': status.name,
      'title': title,
      'appreciationMessage': appreciationMessage,
      'calories': calories,
      'macros': macros != null ? _macrosToMap(macros!) : null,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'inputText': inputText,
      'imagePath': imagePath,
      'imageMimeType': imageMimeType,
      'audioPath': audioPath,
      'audioMimeType': audioMimeType,
      'errorMessage': errorMessage,
    };
  }

  Meal copyWith({
    String? id,
    String? userId,
    DateTime? date,
    MealStatus? status,
    String? title,
    String? appreciationMessage,
    int? calories,
    Map<Macro, int>? macros,
    String? imageUrl,
    String? audioUrl,
    String? inputText,
    String? imagePath,
    String? imageMimeType,
    String? audioPath,
    String? audioMimeType,
    String? errorMessage,
  }) {
    return Meal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      status: status ?? this.status,
      title: title ?? this.title,
      appreciationMessage: appreciationMessage ?? this.appreciationMessage,
      calories: calories ?? this.calories,
      macros: macros ?? this.macros,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      inputText: inputText ?? this.inputText,
      imagePath: imagePath ?? this.imagePath,
      imageMimeType: imageMimeType ?? this.imageMimeType,
      audioPath: audioPath ?? this.audioPath,
      audioMimeType: audioMimeType ?? this.audioMimeType,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static MealStatus _parseStatus(Object? value) {
    switch (value?.toString()) {
      case 'pending':
        return MealStatus.pending;
      case 'error':
        return MealStatus.error;
      default:
        return MealStatus.done;
    }
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
    switch (key?.toString()) {
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
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Ungültiger Wert für $key.');
  }

  static int _valueAsInt(Object? value, String key) {
    if (value is int) return value;
    if (value is num) return value.round();
    throw FormatException('Ungültiger Wert für $key.');
  }

  static String _requireString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String) return value;
    if (value != null) return value.toString();
    throw FormatException('Ungültiger Wert für $key.');
  }
}
