import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
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
class AdaptiveStrengthSummaryCard extends StatefulWidget {
  const AdaptiveStrengthSummaryCard({super.key});

  @override
  State<AdaptiveStrengthSummaryCard> createState() =>
      _AdaptiveStrengthSummaryCardState();
}

class _AdaptiveStrengthSummaryCardState
    extends State<AdaptiveStrengthSummaryCard> {
  // Created once. Building these inside build() opened fresh Firestore
  // listeners (and flashed empty data) on every rebuild of the Progress tab.
  final WorkoutLogService _logService = WorkoutLogService();
  final StrengthService _strengthService = StrengthService();
  late final Stream<List<WorkoutSession>> _sessionsStream;
  late final Stream<List<WorkoutLog>> _logsStream;

  @override
  void initState() {
    super.initState();
    _sessionsStream = _logService.getSessions();
    _logsStream = _logService.getLogs();
  }

  @override
  Widget build(BuildContext context) {
    final stats = Provider.of<StatisticsProvider>(context);

    return StreamBuilder<List<WorkoutSession>>(
      stream: _sessionsStream,
      builder: (context, sessionSnapshot) {
        return StreamBuilder<List<WorkoutLog>>(
          stream: _logsStream,
          builder: (context, logSnapshot) {
            final sessions = sessionSnapshot.data ?? [];
            final logs = logSnapshot.data ?? [];

            // 1. What did I do? Weekly volume & adherence
            final weeklyMetrics = _strengthService.calculateWeeklyMetrics(sessions);
            final workoutsThisWeek = weeklyMetrics.thisWeekSessions > 0
                ? weeklyMetrics.thisWeekSessions
                : stats.workoutsCompletedThisWeek;
            final weeklyTarget = stats.weeklyTarget;

            // 2. Am I getting stronger? Top PR
            final prs = _strengthService.getAllTimePRs(sessions: sessions, legacyLogs: logs);
            final sortedPRs = prs.values.toList()
              ..sort((a, b) => b.estimated1RM.compareTo(a.estimated1RM));
            final topPR = sortedPRs.isNotEmpty ? sortedPRs.first : null;

            return Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ColorManager.surface,
                boxShadow: ColorManager.cardShadow,
                borderRadius: BorderRadius.circular(AppRadius.card.r),
                border: Border.all(color: ColorManager.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: Colors.amber, size: 20.sp),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                'Adaptive Strength Overview',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ColorManager.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: ColorManager.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          'This Week',
                          style: TextStyle(
                            color: ColorManager.primaryText,
                            fontSize: 11.sp,
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
                            borderRadius: BorderRadius.circular(AppRadius.small.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adherence',
                                style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                              ),
                              SizedBox(height: 4.h),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Text(
                                      '$workoutsThisWeek / $weeklyTarget',
                                      style: TextStyle(
                                        color: workoutsThisWeek >= weeklyTarget ? ColorManager.primaryText : ColorManager.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'workouts',
                                      style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
                                    ),
                                  ],
                                ),
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
                            borderRadius: BorderRadius.circular(AppRadius.small.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Volume Lifted',
                                style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                              ),
                              SizedBox(height: 4.h),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Text(
                                      '${weeklyMetrics.thisWeekVolume.toInt()} kg',
                                      style: TextStyle(
                                        color: ColorManager.primaryText,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (weeklyMetrics.volumeChangePct != 0) ...[
                                      SizedBox(width: 4.w),
                                      Text(
                                        '${weeklyMetrics.volumeChangePct > 0 ? '+' : ''}${weeklyMetrics.volumeChangePct.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          color: weeklyMetrics.volumeChangePct >= 0 ? ColorManager.primaryText : Colors.orange.shade800,
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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
                        borderRadius: BorderRadius.circular(AppRadius.small.r),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
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
                                  'All-time best',
                                  style: TextStyle(
                                    color: ColorManager.textTertiary,
                                    fontSize: AppText.caption,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2.h),
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
                        borderRadius: BorderRadius.circular(AppRadius.small.r),
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
                        color: ColorManager.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics_outlined, color: ColorManager.primaryText, size: 16.sp),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Open Full Strength & PR Vault',
                                style: TextStyle(
                                  color: ColorManager.primaryText,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(Icons.arrow_forward_ios_rounded, color: ColorManager.primaryText, size: 11.sp),
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
