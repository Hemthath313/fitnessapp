import 'package:flutter/material.dart';

class PPLPage extends StatelessWidget {
  const PPLPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Push-Pull-Legs (PPL) Workout')),
      body: const Center(
        child: Text(
          'PPL Split Exercises:\n\n'
          '🟩 Push Day: Chest, Shoulders, Triceps\n'
          '🟦 Pull Day: Back, Biceps\n'
          '🟧 Leg Day: Quads, Hamstrings, Glutes',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
