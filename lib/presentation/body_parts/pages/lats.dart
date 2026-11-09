import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/presentation/body_parts/pages/body_part_exercises_page.dart';
import 'package:flutter/material.dart';

class LatExercisesPage extends StatelessWidget {
  const LatExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BodyPartExercisesPage(
      title: 'Back Workouts',
      tagline: 'Build a Powerful Back',
      exercises: ExerciseData.back,
      category: 'Lats',
    );
  }
}
