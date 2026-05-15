import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snackbert/screens/auth.dart';

void main() {
  runApp(const Snackbert());
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
        textTheme: TextTheme(
          // HEADLINE AUTH SCREEN
          headlineLarge: GoogleFonts.fredoka(
            fontSize: 64,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
          // INFO BRACKET AUTH SCREEN
          bodyMedium: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      home: AuthScreen(),
    );
  }
}
