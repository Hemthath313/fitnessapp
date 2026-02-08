import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MealDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> meal;
  final VoidCallback onSwapMeal;
  final Function(String) onAddFood;

  const MealDetailsSheet({
    super.key,
    required this.meal,
    required this.onSwapMeal,
    required this.onAddFood,
  });

  @override
  Widget build(BuildContext context) {
    final foods = meal['foods'] ?? [];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.darkGrey,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
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
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const Divider(color: Colors.white54),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Foods & Ingredients:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
              IconButton(
                onPressed: () => _showAddFoodDialog(context),
                icon: Icon(Icons.add_circle, color: ColorManager.limerGreen2, size: 24.sp),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            constraints: BoxConstraints(maxHeight: 200.h),
            child: foods.isEmpty 
              ? Center(child: Text("No foods listed. Add some!", style: TextStyle(color: Colors.white54, fontSize: 12.sp)))
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
                      Icon(Icons.restaurant, color: Colors.white54, size: 14.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '$food',
                          style: TextStyle(color: Colors.white, fontSize: 14.sp),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12.h),
          const Divider(color: Colors.white54),
          Text(
            'Macros: ${meal['calories']} kcal | ${meal['protein']}g P | ${meal['carbs']}g C | ${meal['fats']}g F',
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
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
                style: TextStyle(color: ColorManager.black, fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.limerGreen2,
                foregroundColor: ColorManager.black,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
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
        title: Text("Add Food Item", style: TextStyle(color: Colors.white, fontSize: 18.sp)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "e.g., 1 Banana", 
            hintStyle: TextStyle(color: Colors.white54)
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
            Icon(Icons.lightbulb_outline, color: Colors.orangeAccent, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              'Substitutions:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
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
          style: TextStyle(fontSize: 12.sp, color: Colors.white70),
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
