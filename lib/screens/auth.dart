import 'package:flutter/material.dart';

import 'package:snackbert/screens/tabs.dart';
import 'package:snackbert/services/auth_service.dart';
import 'package:snackbert/widgets/info_bracket.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  void initState() {
    super.initState();

    widget.authService.addListener(_onAuthStateChanged);
    widget.authService.initialize();
  }

  // Called every time [AuthService] calls notifyListeners()
  void _onAuthStateChanged() {
    if (!mounted) return;

    if (widget.authService.isSignedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TabsScreen(authService: widget.authService),
        ),
      );
      return;
    }

    setState(() {}); //?
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
        child: widget.authService.isInitializing
            ? const CircularProgressIndicator()
            : _buildContent(headlineStyle),
      ),
    );
  }

  Widget _buildContent(TextStyle headlineStyle) {
    return Column(
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
          onPressed: widget.authService.signIn,
          icon: const Icon(Icons.login_rounded),
          label: const Text('Login mit Google'),
        ),

        // TODO -1: Snackbert-Bar daraus machen
        if (widget.authService.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.authService.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
