import 'package:flutter/material.dart';
import 'package:snackbert/models/meal.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.meals});

  final List<Meal> meals;

  @override
  Widget build(BuildContext context) {
    // STYLING
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListView.separated(
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: colors.tertiary, indent: 16, endIndent: 16),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final currentMeal = meals[index];
        final calories = currentMeal.calories.toString();
        final carbs = currentMeal.macros[Macro.carb];
        final protein = currentMeal.macros[Macro.protein];
        final fat = currentMeal.macros[Macro.fat];

        return ListTile(
          // placeholder image
          leading: Image.asset('assets/snackbert_mascot_face.png'),
          title: Text(currentMeal.title),
          subtitle: Row(
            spacing: 8,
            children: [
              Text("${calories}kcal"),
              Text("C: $carbs"),
              Text("P: $protein"),
              Text("F: $fat"),
            ],
          ),
          trailing: Icon(Icons.remove),
        );
      },
    );
  }
}
