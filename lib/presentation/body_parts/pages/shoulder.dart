import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/presentation/body_parts/pages/body_part_exercises_page.dart';
import 'package:flutter/material.dart';

class ShoulderExercisesPage extends StatelessWidget {
  const ShoulderExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BodyPartExercisesPage(
      title: 'Shoulder Workouts',
      tagline: 'Build Powerful Shoulders',
      exercises: ExerciseData.shoulders,
      category: 'Shoulder',
    );
  }
}
