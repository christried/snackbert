import 'package:flutter/material.dart';
import 'package:snackbert/models/meal.dart';

class PendingMealCard extends StatelessWidget {
  const PendingMealCard({
    super.key,
    required this.meal,
    required this.onRemove,
  });

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
          color: theme.colorScheme.surfaceVariant,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      title: Text(
        // TODO: Generate more placeholders for pending meal card
        meal.inputText.isNotEmpty ? meal.inputText : "Wird analysiert…",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black45),
      ),
      subtitle: Text(
        // TODO: Generate more placeholders for pending meal card
        "Snackbert denkt nach… 🐿️",
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.black38),
      ),
      trailing: GestureDetector(
        onTap: onRemove,
        child: const Icon(Icons.remove),
      ),
    );
  }
}
