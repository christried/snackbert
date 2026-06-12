import 'package:flutter/material.dart';
import 'package:snackbert/data/placeholder_messages.dart';
import 'package:snackbert/models/meal.dart';

class PendingMealCard extends StatefulWidget {
  const PendingMealCard({
    super.key,
    required this.meal,
    required this.onRemove,
  });

  final Meal meal;
  final VoidCallback onRemove;

  @override
  State<PendingMealCard> createState() => _PendingMealCardState();
}

class _PendingMealCardState extends State<PendingMealCard> {
  late final String _title;
  late final String _subtitle;

  @override
  void initState() {
    super.initState();
    _title = widget.meal.inputText.isNotEmpty
        ? widget.meal.inputText
        : PlaceholderMessages.randomNewPendingCardTitle;
    _subtitle = PlaceholderMessages.randomNewPendingCardSubtitle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      ),
      title: Text(
        _title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black45),
      ),
      subtitle: Text(
        _subtitle,
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.black38),
      ),
      trailing: GestureDetector(
        onTap: widget.onRemove,
        child: const Icon(Icons.remove),
      ),
    );
  }
}
