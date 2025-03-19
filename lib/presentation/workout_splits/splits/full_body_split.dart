import 'package:flutter/material.dart';

class FullBodyPage extends StatelessWidget {
  const FullBodyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Full Body Split Workout')),
      body: const Center(
        child: Text(
          'Full Body Split Exercises:\n\n'
          '💪 Squats\n'
          '🏋️ Bench Press\n'
          '🏃 Deadlifts\n'
          '🪜 Rows\n'
          '🚶 Overhead Press',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
