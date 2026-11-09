import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MealDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> meal;
  final VoidCallback onSwapMeal;
  final Function(String) onAddFood;

  /// Shown only for custom meals the user added; null hides the button.
  final VoidCallback? onDelete;

  const MealDetailsSheet({
    super.key,
    required this.meal,
    required this.onSwapMeal,
    required this.onAddFood,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final foods = meal['foods'] ?? [];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.asset(
              meal['image'] ?? 'assets/images/milk.jpeg',
              height: 150.h,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            meal['name'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
              color: ColorManager.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          Divider(color: ColorManager.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Foods & Ingredients:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorManager.textPrimary,
                  fontSize: 16.sp,
                ),
              ),
              IconButton(
                tooltip: 'Add food',
                onPressed: () => _showAddFoodDialog(context),
                icon: Icon(Icons.add_circle, color: ColorManager.limerGreen2, size: 24.sp),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            constraints: BoxConstraints(maxHeight: 200.h),
            child: foods.isEmpty 
              ? Center(child: Text("No foods listed. Add some!", style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp)))
              : ListView.builder(
              shrinkWrap: true,
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final food = foods[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4.h),
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: ColorManager.surface,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.restaurant, color: ColorManager.textTertiary, size: 14.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '$food',
                          style: TextStyle(color: ColorManager.textPrimary, fontSize: 14.sp),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12.h),
          Divider(color: ColorManager.divider),
          Text(
            'Macros: ${meal['calories']} kcal | ${meal['protein']}g P | ${meal['carbs']}g C | ${meal['fats']}g F',
            style: TextStyle(color: ColorManager.textPrimary, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          _buildSubstitutionGuide(),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSwapMeal,
              icon: Icon(Icons.swap_horiz, size: 20.sp),
              label: Text(
                'Swap With Library Meal',
                style: TextStyle(color: ColorManager.background, fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.limerGreen2,
                foregroundColor: ColorManager.black,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button.r)),
              ),
            ),
          ),
          if (onDelete != null) ...[
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                key: const Key('meal_delete_button'),
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, size: 20.sp),
                label: Text(
                  'Remove This Meal',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: ColorManager.error,
                ),
              ),
            ),
          ],
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
  
  void _showAddFoodDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ColorManager.surface,
        title: Text("Add Food Item", style: TextStyle(color: ColorManager.textPrimary, fontSize: 18.sp)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: ColorManager.textPrimary),
          decoration: InputDecoration(
            hintText: "e.g., 1 Banana", 
            hintStyle: TextStyle(color: ColorManager.textTertiary)
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAddFood(controller.text);
                Navigator.pop(c);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: ColorManager.limerGreen2),
            child: const Text("Add", style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  Widget _buildSubstitutionGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: ColorManager.primaryText, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              'Substitutions:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ColorManager.primaryText,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        _subItem('Chicken', 'Turkey, Lean Beef, Tofu'),
        _subItem('Rice/Oats', 'Quinoa, Sweet Potato, Brown Rice'),
        _subItem('Milk/Shake', 'Greek Yogurt, Soy Milk, Casein'),
        _subItem('Vegetables', 'Spinach, Broccoli, Asparagus'),
      ],
    );
  }

  Widget _subItem(String original, String replacements) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12.sp, color: ColorManager.textSecondary),
          children: [
            TextSpan(
              text: '$original: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: replacements),
          ],
        ),
      ),
    );
  }
}
