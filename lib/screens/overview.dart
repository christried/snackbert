import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:snackbert/data/placeholder_images.dart';

import 'package:snackbert/data/snackbert_messages.dart';
import 'package:snackbert/models/meal.dart';
import 'package:snackbert/providers/meals_provider.dart';
import 'package:snackbert/screens/meal_details.dart';
import 'package:snackbert/utils/snackbar.dart';
import 'package:snackbert/widgets/empty_list_placeholder.dart';
import 'package:snackbert/widgets/inputs/nutrition_totals.dart';
import 'package:snackbert/widgets/inputs/overview_filters.dart';
import 'package:snackbert/widgets/loading_snackbert.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // STYLING
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    void onTapRemove(String id) async {
      final isOk = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Wirklich löschen?"),
          content: Text(
            "Ich werd' mich danach nicht mehr an diese Mahlzeit erinnern können.",
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

      if (!context.mounted || isOk != true) return;

      ref.read(mealsProvider.notifier).removeEntry(id);
      showAppSnackBar(context, SnackbertMessages.randomDeleteMealMessage);
    }

    void onTapMeal(Meal meal, BuildContext context) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => MealDetailsScreen(meal: meal)),
      );
    }

    return StreamBuilder(
      stream: ref.read(mealsProvider.notifier).mealsStream,
      builder: (context, mealSnapshots) {
        if (mealSnapshots.connectionState == ConnectionState.waiting) {
          return Center(child: LoadingSnackbert(status: 'waiting'));
        }

        if (mealSnapshots.hasError) {
          showAppSnackBar(
            context,
            SnackbertMessages.randomErrorFallback,
            isError: true,
          );
          return const Center(child: Text("Error lol"));
        }

        final loadedMeals = mealSnapshots.data!.docs
            .map((doc) => Meal.fromMap({...doc.data()}))
            .toList();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ref.read(mealsProvider.notifier).setMeals(loadedMeals);
        });

        final filteredMeals = ref.watch(mealsProvider);

        return Column(
          children: [
            OverviewFilters(),

            Expanded(
              child: filteredMeals.isEmpty
                  ? Center(child: EmptyListPlaceholder())
                  : ListView.separated(
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: colors.tertiary,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemCount: filteredMeals.length,
                      itemBuilder: (context, index) {
                        final currentMeal = filteredMeals[index];
                        final calories = currentMeal.calories.toString();
                        final carbs = currentMeal.macros[Macro.carb];
                        final protein = currentMeal.macros[Macro.protein];
                        final fat = currentMeal.macros[Macro.fat];

                        return InkWell(
                          onTap: () {
                            onTapMeal(currentMeal, context);
                          },
                          child: ListTile(
                            // placeholder image
                            leading: Hero(
                              tag: currentMeal.id,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: currentMeal.imageUrl,
                                  progressIndicatorBuilder:
                                      (context, url, downloadProgress) =>
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(
                                              value: downloadProgress.progress,
                                            ),
                                          ),
                                  errorWidget: (context, url, error) => Image.asset(
                                    PlaceholderImages.getPlaceholderForSingleMeal(
                                      currentMeal.id,
                                    ),
                                  ),
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
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
      },
    );
  }
}
