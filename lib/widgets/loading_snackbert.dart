import 'dart:async';
import 'package:flutter/material.dart';

class LoadingSnackbert extends StatefulWidget {
  const LoadingSnackbert({super.key});

  @override
  State<LoadingSnackbert> createState() => _LoadingSnackbertState();
}

class _LoadingSnackbertState extends State<LoadingSnackbert> {
  final List<String> _assets = const [
    'assets/snackbert_mascot_full1.png',
    'assets/snackbert_mascot_full2.png',
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      setState(() {
        _index = _index == 0 ? 1 : 0;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 96,
      children: [
        Image.asset(_assets[_index], width: 160, height: 160),
        CircularProgressIndicator(
          constraints: BoxConstraints(minHeight: 80, minWidth: 80),
        ),
      ],
    );
  }
}
