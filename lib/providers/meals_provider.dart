import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snackbert/models/filters.dart';
import 'package:snackbert/models/meal.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

final mealsProvider = NotifierProvider<MealsNotifier, List<Meal>>(
  MealsNotifier.new,
);

class MealsNotifier extends Notifier<List<Meal>> {
  @override
  List<Meal> build() {
    return dummyMeals;
  }

  void addDummyEntry() {
    state = [...state, dummyMeal];
  }

  void addEntry(Meal meal) {
    state = [...state, meal];
  }

  void duplicateEntry(Meal meal) {
    final duplicatedMeal = Meal(
      id: uuid.v4(),
      title: meal.title,
      imageUrl: meal.imageUrl,
      date: meal.date,
      calories: meal.calories,
      macros: Map.of(meal.macros),
    );
    state = [...state, duplicatedMeal];
  }

  void removeEntry(String id) {
    state = state.where((meal) => meal.id != id).toList();
  }

  void updateTimeFilter(TimeFilters filter) {
    state = filter == TimeFilters.today
        ? mealsForToday()
        : filter == TimeFilters.thisWeek
        ? mealsForThisWeek()
        : dummyMeals;
  }

  List<Meal> mealsForToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    return dummyMeals
        .where((meal) => DateUtils.dateOnly(meal.date) == today)
        .toList();
  }

  List<Meal> mealsForThisWeek() {
    final now = DateUtils.dateOnly(DateTime.now());
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfNextWeek = startOfWeek.add(const Duration(days: 7));

    return dummyMeals.where((meal) {
      final mealDay = DateUtils.dateOnly(meal.date);
      return !mealDay.isBefore(startOfWeek) &&
          mealDay.isBefore(startOfNextWeek);
    }).toList();
  }
}

final dummyMeal = Meal(
  id: "4",
  title: "Beispiel Mahlzeit ADDED",
  imageUrl: "",
  //always today
  date: DateTime.now(),
  calories: 555,
  macros: {Macro.carb: 20, Macro.protein: 30, Macro.fat: 20},
);

final dummyMeals = [
  Meal(
    id: "1",
    title: "Beispiel Mahlzeit Heute",
    imageUrl: "",
    //always today
    date: DateTime.now(),
    calories: 555,
    macros: {Macro.carb: 20, Macro.protein: 30, Macro.fat: 20},
  ),
  Meal(
    id: "2",
    title: "Beispiel Mahlzeit Gestern",
    imageUrl: "",
    // always a day ago
    date: DateTime.now().subtract(Duration(days: 1)),
    calories: 666,
    macros: {Macro.carb: 33, Macro.protein: 22, Macro.fat: 11},
  ),
  Meal(
    id: "3",
    title: "Beispiel Mahlzeit 8Tage",
    imageUrl: "",
    // always a day ago
    date: DateTime.now().subtract(Duration(days: 8)),
    calories: 666,
    macros: {Macro.carb: 33, Macro.protein: 22, Macro.fat: 11},
  ),
];
