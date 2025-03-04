import 'package:fitness_app/presentation/diet_nutrition/diet_card.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DietMain extends StatelessWidget {
  const DietMain({super.key});

  @override
  Widget build(BuildContext context) {
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
            buildDietCard(
              context,
              'Bulking Diet',
              ImageManager.bulkingDiet,
              () {
                context.push(Routes.bulkingDietRoute);
              },
            ),
            const SizedBox(height: 16),
            buildDietCard(context, 'Cutting Diet', ImageManager.cuttingDiet,
                () {
              context.push(Routes.cardioRoute);
            }),
            const SizedBox(height: 16),
            buildDietCard(context, 'Maintain Diet', ImageManager.maintainDiet,
                () {
              context.push(Routes.bodypartsPage);
            }),
            const SizedBox(height: 16),
            buildDietCard(context, 'Vegan Diet', ImageManager.veganDiet, () {
              context.push(Routes.cardioRoute);
            }),
          ],
        ),
      ),
    );
  }
}
