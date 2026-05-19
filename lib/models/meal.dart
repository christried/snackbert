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

  final String id;
  final String title;
  final String imageUrl;
  final DateTime date;
  final int calories;
  final Map<Macro, int> macros;
}
