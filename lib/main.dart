import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:snackbert/screens/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: Snackbert()));
}

class Snackbert extends StatelessWidget {
  const Snackbert({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snackbert',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
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
          // APP BODY BIG TEXTs
          bodyLarge: GoogleFonts.fredoka(
            fontSize: 20,
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
        // ICON BUTTONS
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            foregroundColor: const WidgetStatePropertyAll(Colors.black),
          ),
        ),

        // INPUT DECORATION
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFEAF4E2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF80B272), width: 2),
          ),
          hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.2)),
        ),

        // SNACKBAR
        snackBarTheme: SnackBarThemeData(
          elevation: 24,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // LIST TILES (OVERVIEW)
        listTileTheme: ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}
