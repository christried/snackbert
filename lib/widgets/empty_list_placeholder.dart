import 'package:flutter/material.dart';
import 'package:snackbert/data/snackbert_messages.dart';
import 'package:snackbert/widgets/info_bracket.dart';

class EmptyListPlaceholder extends StatefulWidget {
  const EmptyListPlaceholder({super.key});

  @override
  State<EmptyListPlaceholder> createState() => _EmptyListPlaceholderState();
}

class _EmptyListPlaceholderState extends State<EmptyListPlaceholder> {
  late final String emptyListMessage;

  @override
  void initState() {
    emptyListMessage = SnackbertMessages.randomEmptyListMessage;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/snackbert_mascot_shrug.png',
          width: 256,
          height: 256,
        ),
        InfoBracket(
          icon: Icon(Icons.fastfood_outlined),
          text: emptyListMessage,
          
        ),
      ],
    );
  }
}
