import 'package:flutter/material.dart';

import 'package:snackbert/screens/tabs.dart';
import 'package:snackbert/utils/snackbar.dart';
import 'package:snackbert/widgets/info_bracket.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  void _onTapAuth(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const TabsScreen()));
    showAppSnackBar(context, "Willkommen zurück!");
  }

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

            Image.asset(
              'assets/snackbert_mascot.png',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),

            InfoBracket(
              icon: const Icon(Icons.timer_outlined),
              text:
                  'Zeit sparen und einfach Snackbert die Rechenarbeit erledigen lassen!',
            ),
            InfoBracket(
              icon: const Icon(Icons.chat_outlined),
              text:
                  'Einfach texten, abfotografieren oder eine kurze Sprachmemo schicken.',
            ),
            InfoBracket(
              icon: const Icon(Icons.sentiment_very_satisfied_outlined),
              text: 'Snackbert ist und bleibt lieb - hier judged dich niemand.',
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => _onTapAuth(context),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
