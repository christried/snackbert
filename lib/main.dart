import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:snackbert/screens/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Pass the CLI configuration details here
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(Snackbert());
}

class Snackbert extends StatelessWidget {
  const Snackbert({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snackbert',
      theme: ThemeData(
        colorScheme: .fromSeed(
          seedColor: const Color.fromRGBO(128, 178, 114, 1),
        ),
        textTheme: GoogleFonts.fredokaTextTheme().copyWith(
          // HEADLINE AUTH SCREEN
          headlineLarge: GoogleFonts.fredoka(
            fontSize: 64,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
          // INFO BRACKETS AUTH SCREEN
          bodyMedium: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        // LOGIN BUTTON
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
            iconSize: 20,
            minimumSize: const Size(240, 64),
          ),
        ),
      ),
      home: AuthScreen(),
    );
  }
}
