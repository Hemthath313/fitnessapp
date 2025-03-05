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
            : ColorManager.black54,
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
            Text(
              '${meal['calories']} kcal | ${meal['protein']}g Protein',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Tap to view meal details',
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
}
