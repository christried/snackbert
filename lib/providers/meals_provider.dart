import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snackbert/models/meal.dart';

final dummyMeal = Meal(
  id: "3",
  title: "Beispiel Mahlzeit X",
  imageUrl: "",
  date: DateTime.now(),
  calories: 555,
  macros: {Macro.carb: 20, Macro.protein: 30, Macro.fat: 20},
);

List<Meal> dummyMeals = [
  Meal(
    id: "1",
    title: "Beispiel Mahlzeit 1",
    imageUrl: "",
    date: DateTime.now(),
    calories: 555,
    macros: {Macro.carb: 20, Macro.protein: 30, Macro.fat: 20},
  ),
  Meal(
    id: "2",
    title: "Beispiel Mahlzeit2",
    imageUrl: "",
    date: DateTime.now(),
    calories: 666,
    macros: {Macro.carb: 33, Macro.protein: 22, Macro.fat: 11},
  ),
];

final mealsProvider = Provider((ref) {
  return dummyMeals;
});
