import 'package:flutter/material.dart';

class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 16,
        ),
      ),
    );
  }
}
