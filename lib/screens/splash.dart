import 'package:flutter/material.dart';
import 'package:snackbert/widgets/loading_snackbert.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // STYLING
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final headlineStyle = theme.textTheme.headlineLarge!.copyWith(
      color: colors.primary,
    );

    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Text('snackbert', style: headlineStyle),

            LoadingSnackbert(status: "waiting"),
          ],
        ),
      ),
    );
  }
}
