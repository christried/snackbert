import 'package:flutter/material.dart';
import 'package:snackbert/widgets/info_bracket.dart';

// Screen to manage login/signup with google
// also contains "hero" that could transition into smaller size after logging in
// some cards with information about the app in same column between hero and login with google button

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    /// STYLING
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final headlineStyle = theme.textTheme.headlineLarge!.copyWith(
      color: colors.primary,
    );

    ///

    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Text("snackbert", style: headlineStyle),
            Image.asset(
              "assets/snackbert_mascot.png",
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),
            InfoBracket(
              icon: Icon(Icons.timer_outlined),
              text:
                  "Zeit sparen und einfach Snackbert die Rechenarbeit erledigen lassen!",
            ),
            InfoBracket(
              icon: Icon(Icons.chat_outlined),
              text:
                  "Einfach texten, abfotografieren oder eine kurze Sprachmemo schicken.",
            ),
            InfoBracket(
              icon: Icon(Icons.sentiment_very_satisfied_outlined),
              text: "Snackbert ist und bleibt lieb - hier judged dich niemand.",
            ),
          ],
        ),
      ),
    );
  }
}
