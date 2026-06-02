import 'package:cloud_firestore/cloud_firestore.dart';
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
    return [];
  }

  final mealsStream = FirebaseFirestore.instance
      .collection("meals")
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
  }

  void removeEntry(String id) {
    state = state.where((meal) => meal.id != id).toList();
    FirebaseFirestore.instance.collection("meals").doc(id).delete();
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
