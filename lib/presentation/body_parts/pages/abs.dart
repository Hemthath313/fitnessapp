import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/presentation/body_parts/pages/body_part_exercises_page.dart';
import 'package:flutter/material.dart';

class AbsExercisesPage extends StatelessWidget {
  const AbsExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BodyPartExercisesPage(
      title: 'Abs Workouts',
      tagline: 'Build a Strong Core',
      exercises: ExerciseData.abs,
      category: 'Abs',
    );
  }
}
