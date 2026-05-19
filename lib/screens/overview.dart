import 'package:flutter/material.dart';
import 'package:snackbert/models/meal.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.meals});

  final List<Meal> meals;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("OverviewScreen hier"));
  }
}
