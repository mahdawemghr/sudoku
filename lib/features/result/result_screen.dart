import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final bool won;
  final int duration;
  final String? difficulty;
  final bool isNewBest;

  const ResultScreen({
    super.key,
    required this.won,
    required this.duration,
    this.difficulty,
    required this.isNewBest,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Result Screen'),
      ),
    );
  }
}
