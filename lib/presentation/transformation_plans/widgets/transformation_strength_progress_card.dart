import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_strength_analytics.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';

/// Comprehensive Strength Progress Card embedded inside TransformationProgressScreen
class TransformationStrengthProgressCard extends StatefulWidget {
  final List<WorkoutSession>? overrideSessions;

  const TransformationStrengthProgressCard({
    super.key,
    this.overrideSessions,
  });

  @override
  State<TransformationStrengthProgressCard> createState() =>
      _TransformationStrengthProgressCardState();
}

class _TransformationStrengthProgressCardState
    extends State<TransformationStrengthProgressCard> {
  final WorkoutLogService _logService = WorkoutLogService();
  String? _selectedExerciseName;
  bool _show1RM = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WorkoutSession>>(
      stream: _logService.getSessions(),
      initialData: widget.overrideSessions,
      builder: (context, snapshot) {
        final sessions = widget.overrideSessions ?? snapshot.data ?? [];
        final provider = Provider.of<TransformationProvider>(context);
        final state = provider.activeTransformation;

        if (state == null) return const SizedBox.shrink();

        final summary = TransformationStrengthAnalytics.analyze(
          state: state,
          sessions: sessions,
        );

        return Container(
          key: const Key('transformation_strength_progress_card'),
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
                        Icon(Icons.fitness_center_rounded, color: ColorManager.primaryText, size: 20.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Strength Progress',
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
                  if (summary.hasData) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${summary.totalStrengthWorkouts} Workouts',
                        style: TextStyle(
                          color: ColorManager.primaryText,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 14.h),

              if (!summary.hasData) ...[
                _buildEmptyState(),
              ] else ...[
                // Stat Counter Chips
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricBadge(
                        label: 'Workouts',
                        value: '${summary.totalStrengthWorkouts}',
                        icon: Icons.check_circle_outline_rounded,
                        color: ColorManager.primary,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _buildMetricBadge(
                        label: 'PRs Set',
                        value: '${summary.prsAchieved.length}',
                        icon: Icons.emoji_events_rounded,
                        color: Colors.amber,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _buildMetricBadge(
                        label: 'Est 1RM Gain',
                        value: '+${summary.totalEstimated1RMGain.toStringAsFixed(1)} kg',
                        icon: Icons.trending_up_rounded,
                        color: ColorManager.success,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Exercise Selection & Chart
                if (summary.exerciseProgressions.isNotEmpty) ...[
                  _buildChartSection(summary),
                  SizedBox(height: 16.h),

                  // Exercise Level Progression Table
                  _buildExerciseProgressionList(summary),
                ],

                // PRs Achieved List
                if (summary.prsAchieved.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  _buildPRsSection(summary),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
      ),
      child: Column(
        children: [
          Icon(Icons.fitness_center_rounded, size: 36.sp, color: ColorManager.textTertiary),
          SizedBox(height: 10.h),
          Text(
            'No Strength Workouts Recorded Yet',
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Complete your scheduled resistance workouts to track working weights, estimated 1RM, and PR achievements!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 11.sp,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.small.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 11.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(TransformationStrengthSummary summary) {
    final progressions = summary.exerciseProgressions;
    _selectedExerciseName ??= progressions.first.exerciseName;

    final selected = progressions.firstWhere(
      (p) => p.exerciseName == _selectedExerciseName,
      orElse: () => progressions.first,
    );

    final points = selected.historyPoints;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector & Metric Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selected.exerciseName,
                    isDense: true,
                    dropdownColor: ColorManager.surface,
                    style: TextStyle(color: ColorManager.textPrimary, fontSize: 12.sp, fontWeight: FontWeight.bold),
                    items: progressions.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.exerciseName,
                        child: Text(p.exerciseName, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedExerciseName = val);
                    },
                  ),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _show1RM = !_show1RM),
                borderRadius: BorderRadius.circular(6.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _show1RM ? ColorManager.primary.withValues(alpha: 0.2) : ColorManager.surface,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: _show1RM ? ColorManager.primary : ColorManager.divider),
                  ),
                  child: Text(
                    _show1RM ? '1RM Trend' : 'Weight Trend',
                    style: TextStyle(
                      color: _show1RM ? ColorManager.primary : ColorManager.textSecondary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          if (points.length < 2) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: Text(
                  'Baseline: ${selected.startingWeight.toStringAsFixed(1)} kg • Log 1 more session to view chart curve',
                  style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 140.h,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points.asMap().entries.map((entry) {
                        final val = _show1RM ? entry.value.estimated1RM : entry.value.workingWeight;
                        return FlSpot(entry.key.toDouble(), val);
                      }).toList(),
                      isCurved: true,
                      color: _show1RM ? ColorManager.secondary : ColorManager.primary,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 3.5,
                          color: _show1RM ? ColorManager.secondary : ColorManager.primary,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: (_show1RM ? ColorManager.secondary : ColorManager.primary)
                            .withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d').format(points.first.date),
                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                ),
                Expanded(
                  child: Text(
                    _show1RM
                        ? '${selected.startingEstimated1RM.toStringAsFixed(1)} kg → ${selected.latestEstimated1RM.toStringAsFixed(1)} kg'
                        : '${selected.startingWeight.toStringAsFixed(1)} kg → ${selected.latestWeight.toStringAsFixed(1)} kg (${selected.weightDifference >= 0 ? '+' : ''}${selected.weightDifference.toStringAsFixed(1)} kg)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColorManager.textPrimary, fontSize: 11.sp, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(points.last.date),
                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseProgressionList(TransformationStrengthSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercise Strength Progression',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        ...summary.exerciseProgressions.take(4).map((p) {
          final isPositive = p.weightDifference > 0;
          return Container(
            margin: EdgeInsets.only(bottom: 6.h),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: ColorManager.surfaceDark,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.exerciseName,
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Start: ${p.startingWeight.toStringAsFixed(1)} kg • Latest: ${p.latestWeight.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 11.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? ColorManager.success.withValues(alpha: 0.15)
                          : ColorManager.divider.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${p.weightDifference.toStringAsFixed(1)} kg (${isPositive ? '+' : ''}${p.percentageImprovement.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: isPositive ? ColorManager.success : ColorManager.textSecondary,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPRsSection(TransformationStrengthSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 16.sp),
            SizedBox(width: 6.w),
            Text(
              'Personal Records Achieved (${summary.prsAchieved.length})',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ...summary.prsAchieved.take(3).map((pr) {
          return Container(
            margin: EdgeInsets.only(bottom: 6.h),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: ColorManager.surfaceDark,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pr.exerciseName,
                        style: TextStyle(color: ColorManager.textPrimary, fontSize: 12.sp, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(pr.achievedAt),
                        style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${pr.weight.toStringAsFixed(1)} kg × ${pr.reps} reps',
                  style: TextStyle(color: Colors.amber, fontSize: 11.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
