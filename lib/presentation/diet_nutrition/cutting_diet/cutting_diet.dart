import 'package:fitness_app/presentation/diet_nutrition/diet_plan_screen.dart';
import 'package:flutter/material.dart';

/// Cutting diet plan. All behaviour lives in [DietPlanScreen].
class CuttingDietScreen extends StatelessWidget {
  const CuttingDietScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const DietPlanScreen(plan: DietPlanConfig.cutting);
}
