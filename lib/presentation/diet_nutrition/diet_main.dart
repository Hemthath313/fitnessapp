import 'package:fitness_app/presentation/diet_nutrition/diet_card.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

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
            buildDietCard('Bulking Diet', ImageManager.bulkingDiet),
            const SizedBox(height: 16),
            buildDietCard('Cutting Diet', ImageManager.cuttingDiet),
            const SizedBox(height: 16),
            buildDietCard('Maintain Diet', ImageManager.maintainDiet),
            const SizedBox(height: 16),
            buildDietCard('Vegan Diet', ImageManager.veganDiet),
          ],
        ),
      ),
    );
  }
}
