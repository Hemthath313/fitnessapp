import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class WeeklyProgressCard extends StatelessWidget {
  final List<bool> completedDays; // 7 bools, index 0 = Mon, 6 = Sun (or based on locale)
  final int streakDays;

  const WeeklyProgressCard({
    super.key,
    required this.completedDays,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    // Get current weekday (1=Mon, 7=Sun)
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; 

    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "This Week's Consistency",
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange, size: 20.sp),
                  SizedBox(width: 4.w),
                  Text(
                    "$streakDays Day Streak",
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  )
                ],
              )
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isToday = index == todayIndex;
              final isCompleted = index < completedDays.length ? completedDays[index] : false;
              final dayLetter = _getDayLetter(index);

              return Column(
                children: [
                  Text(
                    dayLetter,
                    style: TextStyle(
                      color: isToday ? ColorManager.primary : Colors.white54,
                      fontSize: 12.sp,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted 
                          ? ColorManager.limerGreen2 
                          : (isToday ? ColorManager.primary.withValues(alpha: 0.2) : Colors.white10),
                      border: isToday 
                          ? Border.all(color: ColorManager.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(Icons.check, color: Colors.black, size: 20.sp)
                          : (isToday 
                              ? Text("${now.day}", style: TextStyle(color: ColorManager.primary, fontSize: 11.sp))
                              : null),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getDayLetter(int index) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[index];
  }
}
