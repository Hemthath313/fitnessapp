import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/presentation/body_parts/pages/body_part_exercises_page.dart';
import 'package:flutter/material.dart';

class LegExercisesPage extends StatelessWidget {
  const LegExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BodyPartExercisesPage(
      title: 'Leg Workouts',
      tagline: 'Build Powerful Legs',
      exercises: ExerciseData.legs,
      category: 'Legs',
    );
  }
}
