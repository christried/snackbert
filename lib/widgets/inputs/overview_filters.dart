import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snackbert/models/filters.dart';
import 'package:snackbert/providers/meals_provider.dart';

class OverviewFilters extends ConsumerStatefulWidget {
  const OverviewFilters({super.key});

  @override
  ConsumerState<OverviewFilters> createState() => _OverviewFiltersState();
}

class _OverviewFiltersState extends ConsumerState<OverviewFilters> {
  TimeFilters _selectedFilter = TimeFilters.today;

  String _chipLabelHelper(TimeFilters filter) {
    switch (filter) {
      case TimeFilters.today:
        return "Heute";
      case TimeFilters.lastSevenDays:
        return "Letzte 7 Tage";
      case TimeFilters.allTime:
        return "Alles";
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedFilter = ref.read(mealsProvider.notifier).currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      color: colors.onInverseSurface,
      child: Wrap(
        alignment: .center,
        spacing: 8,
        children: TimeFilters.values.map((filter) {
          final selected = _selectedFilter == filter;

          return ChoiceChip(
            label: Text(_chipLabelHelper(filter)),
            selected: selected,
            onSelected: (bool nowSelected) {
              setState(() {
                _selectedFilter = nowSelected ? filter : _selectedFilter;
              });

              ref.read(mealsProvider.notifier).updateTimeFilter(filter);
            },
            selectedColor: colors.primary.withAlpha(55),
            labelStyle: Theme.of(context).textTheme.bodyMedium,
          );
        }).toList(),
      ),
    );
  }
}
