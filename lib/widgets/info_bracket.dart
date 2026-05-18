// Widget that shows information in a card in AuthCreen, there will be multiple of these

import 'package:flutter/material.dart';

class InfoBracket extends StatelessWidget {
  const InfoBracket({
    super.key,
    required this.icon,
    required this.text,
    this.horMargin = 32,
  });

  final Icon icon;
  final String text;
  final double horMargin;

  @override
  Widget build(BuildContext context) {
    /// STYLING
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final infoBracketTextStyle = theme.textTheme.bodyMedium!.copyWith(
      // custom config not needed here
    );

    return Card.outlined(
      color: colors.inversePrimary,
      margin: EdgeInsets.symmetric(vertical: 0, horizontal: horMargin),
      child: ListTile(
        leading: icon,
        title: Text(
          text,
          style: infoBracketTextStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
