import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      margin: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: meal['isCompleted']
            ? Colors.green.withOpacity(0.2)
            : ColorManager.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(2, 2),
          )
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Icon(
          meal['isCompleted'] ? Icons.check_circle : Icons.fastfood,
          color: meal['isCompleted'] ? Colors.green : Colors.orangeAccent,
          size: 28.sp,
        ),
        title: Text(
          meal['name'],
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16.sp),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${meal['calories']} kcal | ${meal['protein']}g Protein',
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
                SizedBox(width: 8.w),
                _buildMacroBadge(),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tap to see details & foods',
                  style: TextStyle(fontSize: 10.sp, color: Colors.white54),
                ),
                Icon(Icons.chevron_right, color: Colors.white54, size: 16.sp)
              ],
            ),
          ],
        ),
        trailing: Transform.scale(
          scale: 0.8,
          child: Switch(
            value: meal['isCompleted'],
            onChanged: onToggleMeal,
            activeColor: Colors.green,
          ),
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
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 8.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}
