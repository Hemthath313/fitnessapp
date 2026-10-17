import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/services/strength_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Delivers the 5-second answer:
/// 1. What did I do? (Weekly sessions & volume)
/// 2. Am I getting stronger? (Top PR & Est. 1RM milestone)
/// 3. What should I do next? (Direct navigation to PR Vault / Next session)
class AdaptiveStrengthSummaryCard extends StatelessWidget {
  const AdaptiveStrengthSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = Provider.of<StatisticsProvider>(context);
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

            // 1. What did I do? Weekly volume & adherence
            final weeklyMetrics = strengthService.calculateWeeklyMetrics(sessions);
            final workoutsThisWeek = weeklyMetrics.thisWeekSessions > 0
                ? weeklyMetrics.thisWeekSessions
                : stats.workoutsCompletedThisWeek;
            final weeklyTarget = stats.weeklyTarget;

            // 2. Am I getting stronger? Top PR
            final prs = strengthService.getAllTimePRs(sessions: sessions, legacyLogs: logs);
            final sortedPRs = prs.values.toList()
              ..sort((a, b) => b.estimated1RM.compareTo(a.estimated1RM));
            final topPR = sortedPRs.isNotEmpty ? sortedPRs.first : null;

            return Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ColorManager.surface,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: ColorManager.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: Colors.amber, size: 20.sp),
                          SizedBox(width: 6.w),
                          Text(
                            'Adaptive Strength Overview',
                            style: TextStyle(
                              color: ColorManager.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: ColorManager.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          'This Week',
                          style: TextStyle(
                            color: ColorManager.primary,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // 1. What did I do? (Workouts Done & Volume)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: ColorManager.surfaceDark,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adherence',
                                style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Text(
                                    '$workoutsThisWeek / $weeklyTarget',
                                    style: TextStyle(
                                      color: workoutsThisWeek >= weeklyTarget ? Colors.greenAccent : ColorManager.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'workouts',
                                    style: TextStyle(color: ColorManager.textSecondary, fontSize: 10.sp),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: ColorManager.surfaceDark,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Volume Lifted',
                                style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Text(
                                    '${weeklyMetrics.thisWeekVolume.toInt()} kg',
                                    style: TextStyle(
                                      color: ColorManager.primary,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (weeklyMetrics.volumeChangePct != 0) ...[
                                    SizedBox(width: 4.w),
                                    Text(
                                      '${weeklyMetrics.volumeChangePct > 0 ? '+' : ''}${weeklyMetrics.volumeChangePct.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: weeklyMetrics.volumeChangePct >= 0 ? Colors.green : Colors.orange,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // 2. Am I getting stronger? Top PR milestone
                  if (topPR != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: ColorManager.surfaceDark,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.amber.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20.sp),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  topPR.exerciseName,
                                  style: TextStyle(
                                    color: ColorManager.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Top Set: ${topPR.weight.toInt()} kg × ${topPR.reps}  •  Est. 1RM: ${topPR.estimated1RM.toStringAsFixed(1)} kg',
                                  style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: ColorManager.surfaceDark,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.fitness_center_rounded, color: ColorManager.textTertiary, size: 18.sp),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Complete your first routine to unlock your Strength PR Vault!',
                              style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 12.h),

                  // 3. What should I do next? Direct CTA
                  InkWell(
                    onTap: () => context.push(Routes.strengthAnalyticsRoute),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: ColorManager.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics_outlined, color: ColorManager.primary, size: 16.sp),
                          SizedBox(width: 6.w),
                          Text(
                            'Open Full Strength & PR Vault',
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(Icons.arrow_forward_ios_rounded, color: ColorManager.primary, size: 11.sp),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
