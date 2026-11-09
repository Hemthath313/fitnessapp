import 'package:fitness_app/presentation/diet_nutrition/diet_plan_screen.dart';
import 'package:flutter/material.dart';

/// Bulking diet plan. All behaviour lives in [DietPlanScreen].
class BulkingDietScreen extends StatelessWidget {
  const BulkingDietScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const DietPlanScreen(plan: DietPlanConfig.bulking);
}
