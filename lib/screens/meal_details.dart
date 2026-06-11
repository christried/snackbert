import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:snackbert/data/placeholder_images.dart';

import 'package:snackbert/data/snackbert_messages.dart';
import 'package:snackbert/models/meal.dart';
import 'package:snackbert/providers/meals_provider.dart';
import 'package:snackbert/utils/snackbar.dart';
import 'package:snackbert/widgets/info_bracket.dart';
import 'package:snackbert/widgets/speech_bubble.dart';

class MealDetailsScreen extends ConsumerWidget {
  const MealDetailsScreen({super.key, required this.meal});

  final Meal meal;

  void onEatAgain(BuildContext context, WidgetRef ref) async {
    final isOk = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Wirklich nochmal essen?"),
        content: Text(
          "Wenn du bestätigst, füge ich diese Leckerheit nochmal deiner Übersicht hinzu. Du kannst den Eintrag natürlich jederzeit wieder entfernen. Also von mir entfernen lassen, meine ich.",
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

    // add entry and navigate to overview
    ref.read(mealsProvider.notifier).duplicateEntry(meal);
    showAppSnackBar(context, SnackbertMessages.randomDuplicateMealMessage);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // STYLING
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(meal.title)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 16,
        children: [
          SizedBox(height: 32),
          SpeechBubble(text: meal.appreciationMessage),
          Hero(
            tag: meal.id,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: meal.imageUrl,
                progressIndicatorBuilder: (context, url, downloadProgress) =>
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        value: downloadProgress.progress,
                      ),
                    ),
                errorWidget: (context, url, error) => Image.asset(
                  PlaceholderImages.getPlaceholderForSingleMeal(meal.id),
                ),
                height: 300,
                width: 300,
                fit: BoxFit.cover,
              ),
            ),
          ),

          InfoBracket(
            icon: Icon(Icons.local_fire_department),
            text:
                '${meal.calories}kcal\nCarbs: ${meal.macros[Macro.carb] ?? 0}  Proteine: ${meal.macros[Macro.protein] ?? 0}  Fett: ${meal.macros[Macro.fat] ?? 0}',
            horMargin: 32,
          ),

          ElevatedButton(
            onPressed: () {
              onEatAgain(context, ref);
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text("Nochmal essen"),
          ),
        ],
      ),
    );
  }
}
