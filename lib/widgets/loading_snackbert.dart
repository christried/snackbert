import 'dart:async';
import 'package:flutter/material.dart';

class LoadingSnackbert extends StatefulWidget {
  const LoadingSnackbert({super.key, this.status = "eating"});

  final String status;
  @override
  State<LoadingSnackbert> createState() => _LoadingSnackbertState();
}

class _LoadingSnackbertState extends State<LoadingSnackbert> {
  // asset sets keyed by `widget.status` (eating | waiting)
  final Map<String, List<String>> _assetSets = const {
    'eating': [
      'assets/snackbert_mascot_eating1.png',
      'assets/snackbert_mascot_eating2.png',
    ],
    'waiting': [
      'assets/snackbert_mascot_waiting1.png',
      'assets/snackbert_mascot_waiting2.png',
    ],
  };

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
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
    final assets = _assetSets[widget.status] ?? _assetSets['eating']!;
    final image = assets[_index % assets.length];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Image.asset(image, width: 256, height: 256),
        ),
      ],
    );
  }
}
