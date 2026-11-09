import 'package:fitness_app/utils/managers/radius_manager.dart';
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

/// Optimized RecentPRsWidget with persistent stream subscription caching.
/// Avoids re-creating Firestore snapshot listeners on every Dashboard rebuild.
class RecentPRsWidget extends StatefulWidget {
  final Stream<List<WorkoutSession>>? sessionsStream;
  final Stream<List<WorkoutLog>>? logsStream;

  const RecentPRsWidget({
    super.key,
    this.sessionsStream,
    this.logsStream,
  });

  @override
  State<RecentPRsWidget> createState() => _RecentPRsWidgetState();
}

class _RecentPRsWidgetState extends State<RecentPRsWidget> {
  late Stream<List<WorkoutSession>> _sessionsStream;
  late Stream<List<WorkoutLog>> _logsStream;
  final WorkoutLogService _logService = WorkoutLogService();
  final StrengthService _strengthService = StrengthService();

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    _sessionsStream = widget.sessionsStream ?? _logService.getSessions();
    _logsStream = widget.logsStream ?? _logService.getLogs();
  }

  @override
  void didUpdateWidget(RecentPRsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sessionsStream != oldWidget.sessionsStream ||
        widget.logsStream != oldWidget.logsStream) {
      _initStreams();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WorkoutSession>>(
      stream: _sessionsStream,
      builder: (context, sessionSnapshot) {
        return StreamBuilder<List<WorkoutLog>>(
          stream: _logsStream,
          builder: (context, logSnapshot) {
            final bool hasError =
                sessionSnapshot.hasError || logSnapshot.hasError;
            final bool isLoading =
                (sessionSnapshot.connectionState == ConnectionState.waiting &&
                        !sessionSnapshot.hasData) ||
                    (logSnapshot.connectionState == ConnectionState.waiting &&
                        !logSnapshot.hasData);

            final sessions = sessionSnapshot.data ?? [];
            final logs = logSnapshot.data ?? [];

            final prMap = _strengthService.getAllTimePRs(
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
                  borderRadius: BorderRadius.circular(AppRadius.card.r),
                  border: Border.all(
                    color: ColorManager.divider.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
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
                                  color: Colors.amber.withValues(alpha: 0.15),
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
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              context.push(Routes.strengthAnalyticsRoute),
                          borderRadius: BorderRadius.circular(8.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 4.h),
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

                    // Content: Error, Loading, Real PR data, or clean empty state
                    if (hasError) ...[
                      // Error State
                      Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 14.h, horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: ColorManager.surfaceLight,
                          borderRadius: BorderRadius.circular(AppRadius.small.r),
                          border: Border.all(
                              color: ColorManager.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_off_rounded,
                                color: ColorManager.error, size: 20.sp),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Unable to load recent personal records. Tap PR Vault to view your strength history.',
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
                    ] else if (isLoading) ...[
                      // Subtle Loading State
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Center(
                          child: SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColorManager.primary,
                            ),
                          ),
                        ),
                      ),
                    ] else if (prList.isNotEmpty) ...[
                      // Display top 3 most recent PRs
                      ...prList.take(3).map((pr) {
                        final formattedWeight = pr.weight % 1 == 0
                            ? pr.weight.toInt().toString()
                            : pr.weight.toStringAsFixed(1);
                        final dateStr =
                            DateFormat('MMM d').format(pr.achievedAt);

                        return Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: ColorManager.surfaceLight,
                            borderRadius: BorderRadius.circular(AppRadius.small.r),
                            border: Border.all(
                              color: ColorManager.divider.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34.w,
                                height: 34.w,
                                decoration: BoxDecoration(
                                  color: ColorManager.primary.withValues(alpha: 0.12),
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: ColorManager.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color:
                                        ColorManager.primary.withValues(alpha: 0.3),
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
                        padding: EdgeInsets.symmetric(
                            vertical: 14.h, horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: ColorManager.surfaceLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: ColorManager.primary.withValues(alpha: 0.1),
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
