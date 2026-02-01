import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

class MealCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  final int index;
  final ValueChanged<bool> onToggleMeal;
  final VoidCallback onTap;

  const MealCard({
    super.key,
    required this.meal,
    required this.index,
    required this.onToggleMeal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: meal['isCompleted']
            ? Colors.green.withOpacity(0.2)
            : ColorManager.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(2, 2),
          )
        ],
      ),
      child: ListTile(
        leading: Icon(
          meal['isCompleted'] ? Icons.check_circle : Icons.fastfood,
          color: meal['isCompleted'] ? Colors.green : Colors.orangeAccent,
        ),
        title: Text(
          meal['name'],
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${meal['calories']} kcal | ${meal['protein']}g Protein',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 8),
                _buildMacroBadge(),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Tap to see details & foods',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
                Icon(Icons.chevron_right, color: Colors.white54, size: 18)
              ],
            ),
          ],
        ),
        trailing: Switch(
          value: meal['isCompleted'],
          onChanged: onToggleMeal,
          activeColor: Colors.green,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMacroBadge() {
    final protein = (meal['protein'] as num).toDouble();
    final calories = (meal['calories'] as num).toDouble();

    // Simple logic: if protein is high relative to others
    if (protein > 25) {
      return _badge('High Protein', Colors.orange);
    } else if (calories < 300) {
      return _badge('Low Cal', Colors.blue);
    }
    return const SizedBox.shrink();
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}
