import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

class MealDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> meal;
  final VoidCallback onSwapMeal;

  const MealDetailsSheet({
    super.key,
    required this.meal,
    required this.onSwapMeal,
  });

  @override
  Widget build(BuildContext context) {
    final foods = meal['foods'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            meal['image'] ?? 'assets/images/milk.jpeg',
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 8),
          Text(
            meal['name'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const Divider(color: Colors.white54),
          const Text(
            'Foods:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 200,
            child: ListView.builder(
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final food = foods[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorManager.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '- $food',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white54),
          Text(
            'Macros: ${meal['calories']} kcal | ${meal['protein']}g P | ${meal['carbs']}g C | ${meal['fats']}g F',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: onSwapMeal,
                icon: const Icon(Icons.swap_horiz),
                label: const Text(
                  'Swap Meal',
                  style: TextStyle(color: ColorManager.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.limerGreen2,
                  foregroundColor: ColorManager.limerGreen2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
