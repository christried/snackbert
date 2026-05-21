import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;

  final content = ListTile(
    leading: Image.asset(
      isError
          ? 'assets/snackbert_mascot_face_error.png'
          : 'assets/snackbert_mascot_face.png',
      width: 48,
      height: 48,
    ),
    title: Text(message, style: theme.textTheme.bodyMedium),
  );

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: content,
      backgroundColor: colors.primary,
      padding: const EdgeInsets.all(4),
      elevation: 80,
    ),
  );
}
