import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/profile/providers/profile_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_recommendations.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/transformation_strength_progress_card.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/transformation_weekly_adherence_summary.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';

/// Dedicated Transformation Progress Dashboard Screen.
/// Displays actual recorded metrics (weight, measurements, workouts, strength progress, milestones, and intelligent insights).
class TransformationProgressScreen extends StatelessWidget {
  const TransformationProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'Transformation Progress',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: AppText.appBarTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorManager.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<TransformationProvider?>(
        builder: (context, provider, _) {
          final state = provider?.activeTransformation ??
              (provider?.history.isNotEmpty == true ? provider?.history.first : null);

          if (state == null) {
            return _buildEmptyState(context);
          }

          final homeProvider = Provider.of<HomeProvider?>(context);
          final profileProvider = Provider.of<ProfileProvider?>(context);

          final blueprint = TransformationPlansData.getById(state.planId) ??
              TransformationPlansData.weightLoss60;

          // Resolve current weight from HomeProvider, check-ins, or fallback
          final currentWeight =
              (homeProvider?.userData['weight'] as num?)?.toDouble() ??
                  (state.weeklyCheckIns.isNotEmpty
                      ? state.weeklyCheckIns.last.weight
                      : state.startingWeight);

          final insights = TransformationRecommendations.generateInsights(
            state: state,
            currentWeight: currentWeight,
          );

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Overall Progress Header Card
                _buildProgressHeaderCard(context, state, blueprint),
                SizedBox(height: 18.h),

                // Weekly Habit Consistency & Adherence Summary
                const TransformationWeeklyAdherenceSummary(),
                SizedBox(height: 18.h),

                // Strength Progress Section (Phase 9)
                const TransformationStrengthProgressCard(),
                SizedBox(height: 18.h),

                // 2. Weight Journey Card
                _buildWeightJourneyCard(
                  context,
                  state,
                  currentWeight,
                  profileProvider,
                ),
                SizedBox(height: 18.h),

                // 3. Body Measurements Card
                _buildMeasurementsCard(context, state, homeProvider),
                SizedBox(height: 18.h),

                // 4. Weekly Check-Ins Card
                _buildWeeklyCheckInsCard(context, state),
                SizedBox(height: 18.h),

                // 4b. Nutrition & Hydration Adherence Card
                _buildNutritionAndHydrationCard(context, state),
                SizedBox(height: 18.h),

                // 5. Intelligent Coach Insights
                _buildCoachInsightsCard(context, insights),
                SizedBox(height: 18.h),

                // 6. Milestones Achieved Card
                _buildMilestonesCard(context, state),
                SizedBox(height: 30.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats_rounded, size: 54.sp, color: ColorManager.textTertiary),
            SizedBox(height: 16.h),
            Text(
              'No Progress Data',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Enroll in a transformation programme to unlock dedicated progress tracking, weight charts, and milestone analysis.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () => context.push(Routes.transformationPlansRoute),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button.r)),
              ),
              child: const Text('Explore Programmes', style: TextStyle(color: ColorManager.onMint, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Overall Progress Header Card
  Widget _buildProgressHeaderCard(
    BuildContext context,
    UserTransformationState state,
    TransformationPlanBlueprint blueprint,
  ) {
    final pct = (state.completionPercentage * 100).toInt();
    final completedWorkouts = state.completedDayIndices.length;
    final totalDays = state.totalDays;

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  state.planTitle,
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: state.isCompleted
                      ? ColorManager.success.withValues(alpha: 0.15)
                      : ColorManager.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  state.isCompleted ? 'COMPLETED' : 'WEEK ${state.currentWeekNumber}',
                  style: TextStyle(
                    color: state.isCompleted ? ColorManager.success : ColorManager.primary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Completion Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Day ${state.currentDay} of $totalDays',
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 12.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct% Completed',
                style: TextStyle(
                  color: ColorManager.primaryText,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: state.completionPercentage,
              minHeight: 8.h,
              backgroundColor: ColorManager.surfaceDark,
              valueColor: const AlwaysStoppedAnimation<Color>(ColorManager.primary),
            ),
          ),
          SizedBox(height: 14.h),

          // Quick stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildStatMetric('Workouts', '$completedWorkouts Done', Icons.fitness_center_rounded)),
              Expanded(child: _buildStatMetric('Days', '$totalDays Total', Icons.calendar_today_rounded)),
              Expanded(child: _buildStatMetric('Milestones', '${state.milestones.where((m) => m.isAchieved).length}/${state.milestones.length}', Icons.emoji_events_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: ColorManager.textTertiary, size: 16.sp),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            color: ColorManager.textTertiary,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  /// 2. Weight Journey Card
  Widget _buildWeightJourneyCard(
    BuildContext context,
    UserTransformationState state,
    double? currentWeight,
    ProfileProvider? profileProvider,
  ) {
    final startingWeight = state.startingWeight;
    final targetWeight = state.targetWeight;
    final delta = (currentWeight != null && startingWeight != null)
        ? currentWeight - startingWeight
        : null;

    final weightSpots = <FlSpot>[];
    if (startingWeight != null) {
      weightSpots.add(FlSpot(0, startingWeight));
    }
    for (int i = 0; i < state.weeklyCheckIns.length; i++) {
      final c = state.weeklyCheckIns[i];
      if (c.weight != null) {
        weightSpots.add(FlSpot((i + 1).toDouble(), c.weight!));
      }
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.monitor_weight_outlined, color: ColorManager.accent, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Weight Journey',
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
                key: const Key('log_weight_shortcut_button'),
                onTap: () => context.push(Routes.changeWeightRoute),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  child: Row(
                    children: [
                      Text(
                        'Update Weight',
                        style: TextStyle(
                          color: ColorManager.primaryText,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: ColorManager.primaryText, size: 14.sp),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // 4-Metric Row: Starting, Latest, Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildWeightBox(
                  label: 'Starting',
                  value: startingWeight != null ? '${startingWeight.toStringAsFixed(1)} kg' : '—',
                  color: ColorManager.textPrimary,
                ),
              ),
              Expanded(
                child: _buildWeightBox(
                  label: 'Current',
                  value: currentWeight != null ? '${currentWeight.toStringAsFixed(1)} kg' : '—',
                  color: ColorManager.primary,
                ),
              ),
              Expanded(
                child: _buildWeightBox(
                  label: 'Target',
                  value: targetWeight != null ? '${targetWeight.toStringAsFixed(1)} kg' : '—',
                  color: ColorManager.accent,
                ),
              ),
              if (delta != null) ...[
                Expanded(
                  child: _buildWeightBox(
                    label: 'Net Change',
                    value: '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
                    color: delta <= 0 ? ColorManager.success : ColorManager.warning,
                  ),
                ),
              ],
            ],
          ),

          // Mini Trend Chart (rendered when at least 2 points exist)
          if (weightSpots.length >= 2) ...[
            SizedBox(height: 16.h),
            SizedBox(
              height: 110.h,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weightSpots,
                      isCurved: true,
                      color: ColorManager.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: ColorManager.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: 10.h),
            Text(
              'Weekly check-in weights will map your transformation trend chart here.',
              style: TextStyle(
                color: ColorManager.textTertiary,
                fontSize: 11.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: ColorManager.textTertiary,
            fontSize: 11.sp,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 3. Body Measurements Card
  Widget _buildMeasurementsCard(
    BuildContext context,
    UserTransformationState state,
    HomeProvider? homeProvider,
  ) {
    final userData = homeProvider?.userData ?? {};
    final starting = state.startingMeasurements;

    final parts = [
      {'name': 'Waist', 'key': 'waist'},
      {'name': 'Chest', 'key': 'chest'},
      {'name': 'Arms', 'key': 'biceps'},
      {'name': 'Hips', 'key': 'hips'},
      {'name': 'Thighs', 'key': 'thigh'},
    ];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.straighten_rounded, color: ColorManager.primaryText, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Body Measurements',
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
                key: const Key('update_measurements_shortcut_button'),
                onTap: () => context.push(Routes.changeMeasurementsRoute),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  child: Row(
                    children: [
                      Text(
                        'Record',
                        style: TextStyle(
                          color: ColorManager.primaryText,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: ColorManager.primaryText, size: 14.sp),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Measurements Comparison Table
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                children: [
                  Text('Area', style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                  Text('Start', style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                  Text('Current', style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                  Text('Change', style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                ],
              ),
              ...parts.map((p) {
                final k = p['key']!;
                final startVal = starting[k];
                final currentVal = (userData[k] as num?)?.toDouble();
                final diff = (startVal != null && currentVal != null) ? currentVal - startVal : null;

                return TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(p['name']!, style: TextStyle(color: ColorManager.textPrimary, fontSize: 12.sp)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(startVal != null ? '$startVal cm' : '—', style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(currentVal != null ? '$currentVal cm' : '—', style: TextStyle(color: ColorManager.textPrimary, fontSize: 12.sp, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(
                        diff != null ? '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}' : '—',
                        style: TextStyle(
                          color: diff == null ? ColorManager.textTertiary : (diff <= 0 ? ColorManager.success : ColorManager.warning),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// 4. Weekly Check-Ins Card
  Widget _buildWeeklyCheckInsCard(
    BuildContext context,
    UserTransformationState state,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.event_repeat_rounded, color: ColorManager.primaryText, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Weekly Check-Ins',
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
                key: const Key('record_check_in_cta_button'),
                onTap: () => context.push(Routes.transformationCheckInRoute),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  child: Row(
                    children: [
                      Text(
                        'Check In',
                        style: TextStyle(
                          color: ColorManager.primaryText,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.add_rounded, color: ColorManager.primaryText, size: 14.sp),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          if (state.weeklyCheckIns.isEmpty) ...[
            Text(
              'No weekly check-ins recorded yet. Tap "Check In" at the end of each week to log your weight, recovery, and notes.',
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 12.sp,
                height: 1.4,
              ),
            ),
          ] else ...[
            Column(
              children: state.weeklyCheckIns.map((c) {
                final dateStr = DateFormat('MMM d').format(c.checkInDate);
                final adherencePct = (c.adherencePercentage * 100).toInt();

                return Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: ColorManager.surfaceDark,
                    borderRadius: BorderRadius.circular(AppRadius.small.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Week ${c.weekNumber} ($dateStr)',
                              style: TextStyle(
                                color: ColorManager.textPrimary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${c.weight != null ? '${c.weight!.toStringAsFixed(1)} kg • ' : ''}$adherencePct% Adherence • ${c.fatigueLevel ?? 'Normal'}',
                              style: TextStyle(
                                color: ColorManager.textSecondary,
                                fontSize: 11.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (c.notes != null && c.notes!.isNotEmpty) ...[
                        Icon(Icons.notes_rounded, color: ColorManager.textTertiary, size: 16.sp),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 5. Intelligent Coach Insights
  Widget _buildCoachInsightsCard(
    BuildContext context,
    List<TransformationInsight> insights,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: ColorManager.warning, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Coach Insights & Progression',
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
          SizedBox(height: 10.h),

          Column(
            children: insights.map((insight) {
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: ColorManager.surfaceDark,
                  borderRadius: BorderRadius.circular(AppRadius.small.r),
                  border: Border.all(
                    color: insight.type == 'recovery'
                        ? ColorManager.accent.withValues(alpha: 0.3)
                        : (insight.type == 'nutrition' ? ColorManager.warning.withValues(alpha: 0.3) : ColorManager.primary.withValues(alpha: 0.3)),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(insight.iconEmoji, style: TextStyle(fontSize: 18.sp)),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.title,
                            style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            insight.message,
                            style: TextStyle(
                              color: ColorManager.textSecondary,
                              fontSize: 12.sp,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 6. Milestones Achieved Card
  Widget _buildMilestonesCard(
    BuildContext context,
    UserTransformationState state,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: ColorManager.warning, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Milestones',
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
          SizedBox(height: 12.h),

          Column(
            children: state.milestones.map((m) {
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: m.isAchieved ? ColorManager.warning.withValues(alpha: 0.08) : ColorManager.surfaceDark,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: m.isAchieved ? ColorManager.warning.withValues(alpha: 0.3) : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      m.isAchieved ? Icons.military_tech_rounded : Icons.lock_outline_rounded,
                      color: m.isAchieved ? ColorManager.warning : ColorManager.textTertiary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.title,
                            style: TextStyle(
                              color: m.isAchieved ? ColorManager.textPrimary : ColorManager.textSecondary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            m.description,
                            style: TextStyle(
                              color: ColorManager.textTertiary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (m.isAchieved) ...[
                      Text(
                        'Day ${m.triggerDay}',
                        style: TextStyle(
                          color: ColorManager.warning,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionAndHydrationCard(
    BuildContext context,
    UserTransformationState state,
  ) {
    return Container(
      key: const Key('transformation_nutrition_hydration_card'),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.restaurant_rounded, color: ColorManager.accent, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Nutrition & Hydration Targets',
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: ColorManager.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Daily Target',
                  style: TextStyle(
                    color: ColorManager.accent,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Calibrated Targets Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: ColorManager.surfaceDark,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${state.targetCalories.toStringAsFixed(0)} kcal',
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Energy Target',
                        style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: ColorManager.surfaceDark,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${state.targetMacros['protein']?.toStringAsFixed(0)}g',
                        style: TextStyle(
                          color: ColorManager.accent,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Protein Goal',
                        style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: ColorManager.surfaceDark,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${(state.dailyWaterTargetMl / 1000).toStringAsFixed(1)}L',
                        style: TextStyle(
                          color: ColorManager.secondary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Water Goal',
                        style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            state.planId == 'muscle_building_90'
                ? 'Personalized targets to support lean muscle hypertrophy with a 10–15% clean surplus and optimal protein synthesis. Log daily entries via the tools below:'
                : (state.planId == 'strength_12_week'
                    ? 'Personalized nutrition targets to fuel maximal neural output, tendon strength, and optimal central nervous system recovery. Log daily entries via the tools below:'
                    : 'Personalized targets to support sustainable fat loss while preserving lean muscle. Log daily entries via the tools below:'),
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 11.sp,
              height: 1.35,
            ),
          ),
          SizedBox(height: 12.h),

          // Action Buttons: Calorie Tracker, Water Tracker, Meal Plan
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('progress_log_meal_btn'),
                  onPressed: () => context.push(Routes.newMealRoute),
                  icon: Icon(Icons.add_circle_outline_rounded, size: 14.sp, color: ColorManager.primary),
                  label: Text('Log Meal', style: TextStyle(fontSize: 11.sp, color: ColorManager.primary, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ColorManager.primary.withValues(alpha: 0.4)),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('progress_log_water_btn'),
                  onPressed: () => context.push(Routes.addWaterRoute),
                  icon: Icon(Icons.water_drop_outlined, size: 14.sp, color: ColorManager.secondary),
                  label: Text('Log Water', style: TextStyle(fontSize: 11.sp, color: ColorManager.secondary, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ColorManager.secondary.withValues(alpha: 0.4)),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('progress_view_meal_plan_btn'),
              onPressed: () => context.push(
                Routes.transformationNutritionRoute,
                extra: state.currentDay,
              ),
              icon: const Icon(Icons.menu_book_rounded, size: 15, color: ColorManager.onMint),
              label: Text(
                'View Daily Meal Plan & Recipes 🥗',
                style: TextStyle(color: ColorManager.onMint, fontSize: 11.sp, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                elevation: 0,
              ),
            ),
          ),

          // If Weight Loss programme, show Six-Pack educational bridge
          if (state.planId == 'weight_loss_60') ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: ColorManager.surfaceDark,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: ColorManager.divider),
              ),
              child: Row(
                children: [
                   Text('⚡', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Six-Pack Challenge Companion',
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Abs are strengthened in workouts and revealed by your energy deficit.',
                          style: TextStyle(
                            color: ColorManager.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: const Key('progress_six_pack_challenge_btn'),
                    onPressed: () => context.push(Routes.sixPackChallengeRoute),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    ),
                    child: Text(
                      'Explore',
                      style: TextStyle(
                        color: ColorManager.primary,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // If Muscle Building programme, show Bulking Diet guide bridge
          if (state.planId == 'muscle_building_90') ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: ColorManager.surfaceDark,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: ColorManager.divider),
              ),
              child: Row(
                children: [
                   Text('🥩', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulking Diet Plan & Clean Surplus',
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Target 1.8–2.2g protein/kg and clean unrefined carbs.',
                          style: TextStyle(
                            color: ColorManager.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: const Key('progress_bulking_diet_btn'),
                    onPressed: () => context.push(Routes.bulkingDietRoute),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      foregroundColor: ColorManager.accent,
                    ),
                    child: const Text('View Diet', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],

          // If Strength Building programme, show Strength & Power Diet bridge
          if (state.planId == 'strength_12_week') ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: ColorManager.surfaceDark,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: ColorManager.divider),
              ),
              child: Row(
                children: [
                   Text('⚡', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Strength & Power Fueling Guide',
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Target 1.8–2.0g protein/kg and complex carbs for ATP replenishment.',
                          style: TextStyle(
                            color: ColorManager.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: const Key('progress_strength_nutrition_btn'),
                    onPressed: () => context.push(Routes.dietRoute),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      foregroundColor: ColorManager.primary,
                    ),
                    child: const Text('View Plans', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
