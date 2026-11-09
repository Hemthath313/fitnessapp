import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/presentation/body_parts/pages/body_part_exercises_page.dart';
import 'package:flutter/material.dart';

class BicepsExercisesPage extends StatelessWidget {
  const BicepsExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BodyPartExercisesPage(
      title: 'Biceps Workouts',
      tagline: 'Build Powerful Biceps',
      exercises: ExerciseData.biceps,
      category: 'Biceps',
    );
  }
}
