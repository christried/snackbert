import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snackbert/models/meal.dart';
import 'package:snackbert/providers/meals_provider.dart';
import 'package:snackbert/utils/snackbar.dart';
import 'package:snackbert/widgets/inputs/nutrition_totals.dart';
import 'package:snackbert/widgets/inputs/overview_filters.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // STYLING
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final List<Meal> meals = ref.watch(mealsProvider);

    void onTapRemove(String id) async {
      final isOk = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Wirklich löschen?"),
          content: Text(
            "Snackbert kann sich danach nicht mehr an diese Mahlzeit erinnern.",
          ),
          elevation: 80,
          icon: Image.asset(
            'assets/snackbert_mascot_face_think.png',
            width: 64,
            height: 64,
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      if (isOk) {
        ref.read(mealsProvider.notifier).removeEntry(id);
        showAppSnackBar(context, "Mahlzeit entfernt!");
      }
    }

    void onTapMeal() {}

    return Column(
      children: [
        OverviewFilters(),
        Expanded(
          child: ListView.separated(
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: colors.tertiary,
              indent: 16,
              endIndent: 16,
            ),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final currentMeal = meals[index];
              final calories = currentMeal.calories.toString();
              final carbs = currentMeal.macros[Macro.carb];
              final protein = currentMeal.macros[Macro.protein];
              final fat = currentMeal.macros[Macro.fat];

              return InkWell(
                onTap: () {},
                child: ListTile(
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
                  trailing: GestureDetector(
                    onTap: () => onTapRemove(currentMeal.id),
                    child: Icon(Icons.remove),
                  ),
                ),
              );
            },
          ),
        ),
        NutritionTotals(),
      ],
    );
  }
}
