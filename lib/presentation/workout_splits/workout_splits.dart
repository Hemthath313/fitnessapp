import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:fitness_app/model/workout_split.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart'; // For vibration
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WorkoutSplitListPage extends StatelessWidget {
  final List<WorkoutSplit> workoutSplits;

  const WorkoutSplitListPage({super.key, required this.workoutSplits});

  void _navigateToPage(BuildContext context, int index) {
    HapticFeedback.lightImpact(); // Vibration feedback
    switch (index) {
      case 0:
        context.push(Routes.broSplit);
        break;
      case 1:
        context.push(Routes.pushPullLegsSplit);
        break;
      case 2:
        context.push(Routes.upperLowerSplit);
        break;
      case 3:
        context.push(Routes.fullBodySplit);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Page not available')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
        title: Text(
          'Workout Splits',
          style: TextStyle(color: ColorManager.textPrimary),
        ),
        backgroundColor: ColorManager.background,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              '"Push yourself because no one else is going to do it for you."',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 16.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: workoutSplits.length,
              itemBuilder: (context, index) {
                final split = workoutSplits[index];
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: BorderSide(color: ColorManager.divider),
                  ),
                  color: ColorManager.surface,
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    leading: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.fitness_center_rounded, color: ColorManager.primary, size: 24.sp),
                    ),
                    title: Text(
                      split.name,
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        split.description,
                        style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${split.recommendedDays}',
                          style: TextStyle(
                            color: ColorManager.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                        Text(
                          'days/wk',
                          style: TextStyle(
                            color: ColorManager.textTertiary,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToPage(context, index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: ColorManager.background,
    );
  }
}
