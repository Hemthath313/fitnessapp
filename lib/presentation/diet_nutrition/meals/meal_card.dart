import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
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

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('breakfast')) return Icons.free_breakfast_rounded;
    if (n.contains('lunch')) return Icons.lunch_dining_rounded;
    if (n.contains('dinner')) return Icons.dinner_dining_rounded;
    if (n.contains('snack')) return Icons.cookie_rounded;
    if (n.contains('shake') || n.contains('pre') || n.contains('post')) {
      return Icons.local_drink_rounded;
    }
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final bool done = meal['isCompleted'] == true;
    final String name = meal['name'].toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: done
            ? ColorManager.primary.withValues(alpha: 0.14)
            : ColorManager.surface,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
      ),
      // Transparent Material so the ink splash paints above the card colour.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card.r),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 8.w, 12.h),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: ColorManager.chipBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconFor(name),
                    color: ColorManager.primaryText,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ColorManager.textPrimary,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${meal['calories']} kcal | ${meal['protein']}g Protein',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ColorManager.textSecondary,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          _buildMacroBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
                // Round check toggle (44px tap target)
                Semantics(
                  button: true,
                  checked: done,
                  label: 'Mark $name as eaten',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onToggleMeal(!done),
                    child: SizedBox(
                      width: 48.w,
                      height: 48.w,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done ? ColorManager.primary : Colors.transparent,
                            border: Border.all(
                              color: done
                                  ? ColorManager.primary
                                  : ColorManager.textTertiary,
                              width: 2,
                            ),
                          ),
                          child: done
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 18.sp,
                                  color: ColorManager.onMint,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroBadge() {
    final protein = (meal['protein'] as num).toDouble();
    final calories = (meal['calories'] as num).toDouble();

    if (protein > 25) {
      return _badge('High Protein');
    } else if (calories < 300) {
      return _badge('Low Cal');
    }
    return const SizedBox.shrink();
  }

  Widget _badge(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: ColorManager.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ColorManager.primaryText,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
