import 'package:fitness_app/presentation/diet_nutrition/diet_card.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DietMain extends StatelessWidget {
  const DietMain({super.key});

  @override
  Widget build(BuildContext context) {
    final goal =
        Provider.of<HomeProvider>(context).userData['goal']?.toUpperCase();

    return Scaffold(
      backgroundColor: ColorManager.black,
      appBar: AppBar(
        backgroundColor: ColorManager.black,
        title: const Text(
          'Diet Plans',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (goal == 'GAIN')
              buildDietCard(
                context,
                'Bulking Diet',
                ImageManager.bulkingDiet,
                () {
                  context.push(Routes.bulkingDietRoute);
                },
              ),
            if (goal == 'LOSE')
              buildDietCard(
                context,
                'Cutting Diet',
                ImageManager.cuttingDiet,
                () {
                  context.push(Routes
                      .cuttingDietRoute); // Make sure this is correct route
                },
              ),
            if (goal == 'MAINTAIN')
              buildDietCard(
                context,
                'Maintain Diet',
                ImageManager.maintainDiet,
                () {
                  context.push(
                      Routes.maintainDietRoute); // Make sure this is correct route
                },
              ),
            if (goal == null || goal.isEmpty)
              const Text(
                'Please set your goal to view diet plans',
                style: TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
