import 'package:fitness_app/presentation/diet_nutrition/diet_plan_screen.dart';
import 'package:flutter/material.dart';

/// Maintenance diet plan. All behaviour lives in [DietPlanScreen].
class MaintainDietScreen extends StatelessWidget {
  const MaintainDietScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const DietPlanScreen(plan: DietPlanConfig.maintain);
}
