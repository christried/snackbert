import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:snackbert/models/meal.dart';
import 'package:snackbert/providers/meals_provider.dart';

class NutritionTotals extends ConsumerWidget {
  const NutritionTotals({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // STYLING
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final List<Meal> meals = ref.watch(mealsProvider);

    final int totalCalories = meals.fold(
      0,
      (prev, meal) => prev + meal.calories,
    );
    final int totalCarbs = meals.fold(
      0,
      (prev, meal) => prev + (meal.macros[Macro.carb] ?? 0),
    );
    final int totalProtein = meals.fold(
      0,
      (prev, meal) => prev + (meal.macros[Macro.protein] ?? 0),
    );

    final int totalFat = meals.fold(
      0,
      (prev, meal) => prev + (meal.macros[Macro.fat] ?? 0),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colors.onInverseSurface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Gesamt:', style: theme.textTheme.bodyLarge),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$totalCalories kcal', style: theme.textTheme.bodyLarge),
              Text(
                'Carbs: ${totalCarbs}g  Protein: ${totalProtein}g  Fett: ${totalFat}g',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
