import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/presentation/body_parts/pages/body_part_exercises_page.dart';
import 'package:flutter/material.dart';

class TricepsExercisesPage extends StatelessWidget {
  const TricepsExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BodyPartExercisesPage(
      title: 'Triceps Workouts',
      tagline: 'Build Powerful Triceps',
      exercises: ExerciseData.triceps,
      category: 'Triceps',
    );
  }
}
