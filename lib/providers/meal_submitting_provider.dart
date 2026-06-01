import 'package:flutter_riverpod/flutter_riverpod.dart';

final mealSubmittingProvider = NotifierProvider<MealSubmittingNotifier, bool>(
  MealSubmittingNotifier.new,
);

class MealSubmittingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void toggleSubmission() {
    state = !state;
  }
}
