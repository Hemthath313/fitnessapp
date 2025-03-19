import 'package:flutter/material.dart';

class UpperLowerPage extends StatelessWidget {
  const UpperLowerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upper-Lower Split Workout')),
      body: const Center(
        child: Text(
          'Upper-Lower Split Exercises:\n\n'
          '⬆️ Upper Day: Chest, Back, Shoulders, Arms\n'
          '⬇️ Lower Day: Quads, Hamstrings, Glutes, Calves',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
