import 'package:flutter/material.dart';
import 'package:snackbert/models/meal.dart';

class ErrorMealCard extends StatelessWidget {
  const ErrorMealCard({super.key, required this.meal, required this.onRemove});

  final Meal meal;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          color: theme.colorScheme.errorContainer,
          child: Icon(Icons.error_outline, color: theme.colorScheme.error),
        ),
      ),
      title: Text(
        meal.inputText.isNotEmpty
            ? meal.inputText
            : "Analyse fehlgeschlagen 😕",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        "Bitte nochmal versuchen - vielleicht später dann?",
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
      trailing: GestureDetector(
        onTap: onRemove,
        child: const Icon(Icons.remove),
      ),
    );
  }
}
