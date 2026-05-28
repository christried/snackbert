import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:snackbert/screens/tabs.dart';
import 'package:snackbert/utils/snackbar.dart';
import 'package:snackbert/widgets/info_bracket.dart';
import 'package:snackbert/widgets/loading_snackbert.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isAuthenticating = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isAuthenticating = true;
    });

    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential userCredentials = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(userCredentials);

      //  Navigate to the next screen if successful
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const TabsScreen()));
      showAppSnackBar(context, "Omg Hi, da bist du ja!");
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      showAppSnackBar(
        context,
        e.message ?? "Anmeldung fehlgeschlagen.",
        isError: true,
      );
      setState(() {
        _isAuthenticating = false;
      });
    } catch (e) {
      if (!mounted) return;

      showAppSnackBar(
        context,
        "Ein unerwarteter Fehler ist aufgetreten.",
        isError: true,
      );
      setState(() {
        _isAuthenticating = false;
      });
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

            if (_isAuthenticating) LoadingSnackbert(status: "waiting"),
            if (!_isAuthenticating)
              ElevatedButton.icon(
                onPressed: () => _signInWithGoogle(),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Login mit Google'),
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
