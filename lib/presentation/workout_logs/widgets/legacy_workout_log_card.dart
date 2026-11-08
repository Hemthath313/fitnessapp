import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/services/strength_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Renders individual legacy logs clearly marked as "Legacy Log"
/// without fabricating duration, completion status, or session-level PRs.
class LegacyWorkoutLogCard extends StatelessWidget {
  final WorkoutLog log;

  const LegacyWorkoutLogCard({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    final cleanName = ExerciseIdentity.cleanDisplayName(log.exerciseName);

    return Card(
      color: ColorManager.surface,
      margin: EdgeInsets.only(bottom: 10.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(color: ColorManager.divider.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Clean Exercise Name, Legacy Badge, Progression Link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              cleanName,
                              style: TextStyle(
                                color: ColorManager.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'Legacy Log',
                              style: TextStyle(
                                color: Colors.blueGrey.shade200,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${DateFormat('MMM d, yyyy').format(log.date)} • ${log.category}',
                        style: TextStyle(
                          color: ColorManager.textTertiary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.analytics_outlined, color: ColorManager.primary, size: 20.sp),
                  tooltip: 'View Progression',
                  onPressed: () => context.push(
                    '${Routes.exerciseTracker}?exerciseName=${Uri.encodeComponent(cleanName)}',
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Sets preview
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: log.sets.asMap().entries.map((entry) {
                final s = entry.value;
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: ColorManager.surfaceDark,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${s.reps} reps @ ${s.weight.toStringAsFixed(s.weight % 1 == 0 ? 0 : 1)} kg',
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
