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

    final error = widget.authService.errorMessage;
    final snackBarColor = Theme.of(context).colorScheme.primary;
    final snackBarTextStyle = Theme.of(context).textTheme.bodyMedium;

    if (error != null) {
      final snackBarContent = ListTile(
        leading: Image.asset(
          'assets/snackbert_mascot_face_error.png',
          width: 48,
          height: 48,
        ),
        title: Text(error, style: snackBarTextStyle),
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: snackBarContent,
          backgroundColor: snackBarColor,
          padding: EdgeInsets.all(4),
        ),
      );
    }

    if (widget.authService.isSignedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TabsScreen(authService: widget.authService),
        ),
      );
      return;
    }
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
          label: const Text('Login'),
          // style: ElevatedButton.styleFrom(
          //   backgroundColor: Theme.of(context).colorScheme.primary,
          //   foregroundColor: Colors.white,
          // ),
        ),
      ],
    );
  }
}
