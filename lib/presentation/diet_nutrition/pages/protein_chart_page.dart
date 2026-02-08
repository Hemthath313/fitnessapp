import 'package:fitness_app/data/food_data.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

class ProteinChartPage extends StatelessWidget {
  const ProteinChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.black,
      appBar: AppBar(
        backgroundColor: ColorManager.black,
        title: const Text(
          'Food Library',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionTitle('High Protein Sources', Icons.fitness_center),
            _buildFoodList(FoodData.highProtein),
            const SizedBox(height: 24),

            _buildSectionTitle('Vegetarian / Vegan', Icons.eco),
            _buildFoodList(FoodData.vegetarian),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Healthy Fats', Icons.opacity),
            _buildFoodList(FoodData.healthyFats),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Carbs & Grains', Icons.grain),
            _buildFoodList(FoodData.carbs),
            const SizedBox(height: 24),

            _buildSectionTitle('Fruits', Icons.apple),
            _buildFoodList(FoodData.fruits),
            const SizedBox(height: 24),
            
             _buildSectionTitle('Vegetables', Icons.grass),
            _buildFoodList(FoodData.vegetables),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: ColorManager.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(List<FoodItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: items.map((item) => _buildFoodItem(item)).toList(),
      ),
    );
  }

  Widget _buildFoodItem(FoodItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${item.calories} cal ${item.quantity}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMacroBadge('P', item.protein, ColorManager.primary),
              const SizedBox(width: 8),
              _buildMacroBadge('C', item.carbs, Colors.blue),
              const SizedBox(width: 8),
              _buildMacroBadge('F', item.fat, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMacroBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
