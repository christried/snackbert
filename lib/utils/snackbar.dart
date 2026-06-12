import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isAnalyzing = false,
}) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;

  final content = ListTile(
    leading: Image.asset(
      isError
          ? 'assets/snackbert_mascot_face_error.png'
          : isAnalyzing
          ? 'assets/snackbert_mascot_face_smart.png'
          : 'assets/snackbert_mascot_face.png',
      width: 56,
      height: 56,
    ),
    title: Text(
      message,
      style: theme.textTheme.bodyMedium!.copyWith(color: Colors.white),
    ),
  );

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: Duration(seconds: 6),
      content: content,
      backgroundColor: colors.primary,
      padding: const EdgeInsets.all(4),
      elevation: 80,
    ),
  );
}
