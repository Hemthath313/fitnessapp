import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/presentation/body_parts/pages/body_part_exercises_page.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

class ChestExercisesPage extends StatelessWidget {
  const ChestExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BodyPartExercisesPage(
      title: 'Chest Workouts',
      tagline: 'Build a Powerful Chest',
      exercises: ExerciseData.chest,
      category: 'Chest',
      headerColors: [ColorManager.surface, ColorManager.background, ColorManager.surface],
    );
  }
}
