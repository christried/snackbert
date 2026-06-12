import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snackbert/services/health_service.dart';

import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:snackbert/models/filters.dart';
import 'package:snackbert/models/meal.dart';

var uuid = Uuid();

final mealsProvider = NotifierProvider<MealsNotifier, List<Meal>>(
  MealsNotifier.new,
);

class MealsNotifier extends Notifier<List<Meal>> {
  @override
  List<Meal> build() {
    return [];
  }

  List<Meal> _allMeals = [];
  TimeFilters currentFilter = TimeFilters.today;

  final mealsStream = FirebaseFirestore.instance
      .collection("meals")
      .where("userId", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .orderBy("date", descending: false)
      .snapshots();

  void duplicateEntry(Meal meal) async {
    final duplicatedMeal = meal.copyWith(
      id: uuid.v4(),
      date: DateTime.now(),
      macros: Map.of(
        meal.macros,
      ), // necessary "deep" copy so mutations are not shared. But maybe that would be nice too since its the same meal?
    );

    final mealPayload = duplicatedMeal.toMap();

    // add meal to database
    await FirebaseFirestore.instance
        .collection("meals")
        .doc(mealPayload["id"])
        .set(mealPayload);

    // add same meal to health connect as well
    await HealthService.instance.logMeal(
      name: meal.title,
      // Health wants double rather than int
      calories: meal.calories.toDouble(),
      carbs: meal.macros[Macro.carb]!.toDouble(),
      protein: meal.macros[Macro.protein]!.toDouble(),
      fat: meal.macros[Macro.fat]!.toDouble(),
      timestamp: meal.date,
    );
  }

  void removeEntry(String id) {
    _allMeals = _allMeals.where((meal) => meal.id != id).toList();
    state = _applyFilter(_allMeals, currentFilter);
    FirebaseFirestore.instance.collection("meals").doc(id).delete();
  }

  void setMeals(List<Meal> meals) {
    _allMeals = meals;
    state = _applyFilter(_allMeals, currentFilter);
  }

  void updateTimeFilter(TimeFilters filter) {
    currentFilter = filter;
    state = _applyFilter(_allMeals, currentFilter);
  }

  List<Meal> mealsForToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    return _allMeals
        .where((meal) => DateUtils.dateOnly(meal.date) == today)
        .toList();
  }

  List<Meal> mealsForLastSevenDays() {
    final now = DateUtils.dateOnly(DateTime.now());
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    return _allMeals.where((meal) {
      final mealDay = DateUtils.dateOnly(meal.date);
      return !mealDay.isBefore(sevenDaysAgo) && !mealDay.isAfter(now);
    }).toList();
  }

  List<Meal> _applyFilter(List<Meal> meals, TimeFilters filter) {
    if (filter == TimeFilters.today) {
      return mealsForToday();
    }
    if (filter == TimeFilters.lastSevenDays) {
      return mealsForLastSevenDays();
    }
    return meals;
  }
}
