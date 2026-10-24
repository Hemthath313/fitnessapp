import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/services/strength_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RecentPRsWidget extends StatelessWidget {
  const RecentPRsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final logService = WorkoutLogService();
    final strengthService = StrengthService();

    return StreamBuilder<List<WorkoutSession>>(
      stream: logService.getSessions(),
      builder: (context, sessionSnapshot) {
        return StreamBuilder<List<WorkoutLog>>(
          stream: logService.getLogs(),
          builder: (context, logSnapshot) {
            final sessions = sessionSnapshot.data ?? [];
            final logs = logSnapshot.data ?? [];

            final prMap = strengthService.getAllTimePRs(
              sessions: sessions,
              legacyLogs: logs,
            );

            final prList = prMap.values.toList()
              ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: ColorManager.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: ColorManager.divider.withOpacity(0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.amber,
                                  size: 18.sp,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Flexible(
                                child: Text(
                                  'Personal Records',
                                  style: TextStyle(
                                    color: ColorManager.textPrimary,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => context.push(Routes.strengthAnalyticsRoute),
                          borderRadius: BorderRadius.circular(8.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                            child: Row(
                              children: [
                                Text(
                                  'PR Vault',
                                  style: TextStyle(
                                    color: ColorManager.primary,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: ColorManager.primary,
                                  size: 16.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Content: Real PR data or clean empty state
                    if (prList.isNotEmpty) ...[
                      // Display top 3 most recent PRs
                      ...prList.take(3).map((pr) {
                        final formattedWeight = pr.weight % 1 == 0
                            ? pr.weight.toInt().toString()
                            : pr.weight.toStringAsFixed(1);
                        final dateStr = DateFormat('MMM d').format(pr.achievedAt);

                        return Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: ColorManager.surfaceLight,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: ColorManager.divider.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34.w,
                                height: 34.w,
                                decoration: BoxDecoration(
                                  color: ColorManager.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.fitness_center_rounded,
                                  color: ColorManager.primary,
                                  size: 16.sp,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pr.exerciseName,
                                      style: TextStyle(
                                        color: ColorManager.textPrimary,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      '$formattedWeight kg × ${pr.reps} reps • $dateStr',
                                      style: TextStyle(
                                        color: ColorManager.textSecondary,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: ColorManager.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: ColorManager.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${pr.estimated1RM.toStringAsFixed(0)} kg 1RM',
                                  style: TextStyle(
                                    color: ColorManager.primary,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      // Clean Empty State
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: ColorManager.surfaceLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: ColorManager.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.trending_up_rounded,
                                color: ColorManager.primary,
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Log your sets during workouts to unlock automatic PR detection, estimated 1RMs, and strength curves.',
                                style: TextStyle(
                                  color: ColorManager.textSecondary,
                                  fontSize: 11.sp,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
