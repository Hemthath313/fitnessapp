import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/models/transformation_daily_log_model.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/configure_water_goal_dialog.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/recovery_checkin_dialog.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';

/// Reusable daily accountability checklist widget.
/// Seamlessly reflects workout completion, calories, protein, water and daily recovery.
class TransformationDailyChecklist extends StatelessWidget {
  final DateTime? date;
  final bool compact; // If true, renders a tighter view for dashboard cards

  const TransformationDailyChecklist({
    super.key,
    this.date,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final targetDate = date ?? DateTime.now();

    return Consumer2<TransformationProvider, ConsumptionProvider?>(
      builder: (context, transformationProvider, consumptionProvider, _) {
        final activeState = transformationProvider.activeTransformation;
        if (activeState == null) {
          return const SizedBox.shrink();
        }

        final log = transformationProvider.getDailyLogForDate(
          date: targetDate,
          consumptionProvider: consumptionProvider,
        );

        final blueprint = transformationProvider.activeBlueprint;
        final primaryColor = blueprint != null
            ? Color(int.parse(blueprint.gradientColorHex.replaceFirst('0x', ''), radix: 16))
            : ColorManager.primary;

        if (compact) {
          return _buildCompactDashboardSummary(
            context: context,
            log: log,
            provider: transformationProvider,
            consumptionProvider: consumptionProvider,
            primaryColor: primaryColor,
          );
        }

        return _buildFullChecklistView(
          context: context,
          log: log,
          provider: transformationProvider,
          consumptionProvider: consumptionProvider,
          primaryColor: primaryColor,
          targetDate: targetDate,
        );
      },
    );
  }

  /// Compact view designed for dashboard cards
  Widget _buildCompactDashboardSummary({
    required BuildContext context,
    required TransformationDailyLog log,
    required TransformationProvider provider,
    required ConsumptionProvider? consumptionProvider,
    required Color primaryColor,
  }) {
    return Container(
      key: const Key('dashboard_accountability_summary'),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Today\'s Accountability',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: log.hasEnoughData
                      ? primaryColor.withValues(alpha: 0.15)
                      : ColorManager.divider.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  log.hasEnoughData ? '${log.dailyAdherenceScore.round()}% Adherence' : 'In Progress',
                  style: TextStyle(
                    color: log.hasEnoughData ? primaryColor : ColorManager.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Compact metrics (2 rows of 2 for clean responsiveness)
          Row(
            children: [
              Expanded(
                child: _buildCompactItem(
                  label: 'Workout',
                  value: log.isRestDay
                      ? 'Rest Day'
                      : (log.workoutStatus == AccountabilityStatus.completed ? 'Done' : 'Pending'),
                  isComplete: log.isRestDay || log.workoutStatus == AccountabilityStatus.completed,
                  color: primaryColor,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildCompactItem(
                  label: 'Calories',
                  value: '${log.actualCalories.round()} / ${log.targetCalories.round()} kcal',
                  isComplete: log.calorieStatus == AccountabilityStatus.completed,
                  color: ColorManager.accent,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: _buildCompactItem(
                  label: 'Protein',
                  value: '${log.actualProtein.round()} / ${log.targetProtein.round()}g',
                  isComplete: log.proteinStatus == AccountabilityStatus.completed,
                  color: ColorManager.secondary,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildCompactItem(
                  label: 'Water',
                  value: '${(log.actualWaterMl / 1000).toStringAsFixed(1)} / ${(log.targetWaterMl / 1000).toStringAsFixed(1)}L',
                  isComplete: log.waterStatus == AccountabilityStatus.completed,
                  color: ColorManager.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactItem({
    required String label,
    required String value,
    required bool isComplete,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isComplete ? ColorManager.success.withValues(alpha: 0.4) : ColorManager.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isComplete ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 10.sp,
                color: isComplete ? ColorManager.successText : ColorManager.textTertiary,
              ),
              SizedBox(width: 3.w),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              color: isComplete ? ColorManager.textPrimary : ColorManager.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Full checklist view for Roadmap & Progress screens
  Widget _buildFullChecklistView({
    required BuildContext context,
    required TransformationDailyLog log,
    required TransformationProvider provider,
    required ConsumptionProvider? consumptionProvider,
    required Color primaryColor,
    required DateTime targetDate,
  }) {
    final isToday = log.dateString == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      key: const Key('transformation_daily_checklist_container'),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.checklist_rounded, color: primaryColor, size: 20.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Daily Accountability Checklist',
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
                    SizedBox(height: 2.h),
                    Text(
                      'Day ${log.dayNumber} • ${DateFormat('EEE, MMM d').format(targetDate)}',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              // Adherence Score Pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: log.hasEnoughData
                      ? primaryColor.withValues(alpha: 0.15)
                      : ColorManager.surfaceDark,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: log.hasEnoughData ? primaryColor.withValues(alpha: 0.4) : ColorManager.divider,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      log.hasEnoughData ? '${log.dailyAdherenceScore.round()}%' : '—',
                      style: TextStyle(
                        color: log.hasEnoughData ? primaryColor : ColorManager.textSecondary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Adherence',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Coverage text
          Text(
            log.coverageText,
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 14.h),

          // 1. WORKOUT ITEM
          _buildWorkoutTile(
            context: context,
            log: log,
            primaryColor: primaryColor,
          ),
          SizedBox(height: 10.h),

          // 2. CALORIE TARGET ITEM
          _buildCalorieTile(
            context: context,
            log: log,
            primaryColor: primaryColor,
          ),
          SizedBox(height: 10.h),

          // 3. PROTEIN TARGET ITEM
          _buildProteinTile(
            log: log,
            primaryColor: primaryColor,
          ),
          SizedBox(height: 10.h),

          // 4. WATER GOAL ITEM
          _buildWaterTile(
            context: context,
            log: log,
            provider: provider,
            consumptionProvider: consumptionProvider,
            primaryColor: primaryColor,
            isToday: isToday,
          ),
          SizedBox(height: 10.h),

          // 5. RECOVERY CHECK-IN ITEM
          _buildRecoveryTile(
            context: context,
            log: log,
            provider: provider,
            consumptionProvider: consumptionProvider,
            primaryColor: primaryColor,
            targetDate: targetDate,
          ),
        ],
      ),
    );
  }

  // --- ITEM TILES ---

  Widget _buildWorkoutTile({
    required BuildContext context,
    required TransformationDailyLog log,
    required Color primaryColor,
  }) {
    final isDone = log.workoutStatus == AccountabilityStatus.completed;
    final isRest = log.isRestDay;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.small.r),
        border: Border.all(
          color: isDone
              ? ColorManager.success.withValues(alpha: 0.5)
              : (isRest ? primaryColor.withValues(alpha: 0.3) : ColorManager.divider),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isRest
                  ? ColorManager.infoText.withValues(alpha: 0.15)
                  : (isDone
                      ? ColorManager.success.withValues(alpha: 0.15)
                      : primaryColor.withValues(alpha: 0.15)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRest
                  ? Icons.self_improvement_rounded
                  : (isDone ? Icons.check_circle_rounded : Icons.fitness_center_rounded),
              color: isRest
                  ? ColorManager.infoText
                  : (isDone ? ColorManager.success : primaryColor),
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRest ? 'Rest & Recovery Day' : 'Daily Workout Session',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isRest
                      ? 'No lifting scheduled. Active recovery & walking encouraged.'
                      : (isDone ? '✓ Session finished and verified' : 'Scheduled programme training'),
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: isRest
                  ? ColorManager.infoText.withValues(alpha: 0.15)
                  : (isDone
                      ? ColorManager.success.withValues(alpha: 0.15)
                      : ColorManager.surface),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              isRest ? 'Rest Day' : (isDone ? 'Completed' : 'Pending'),
              style: TextStyle(
                color: isRest
                    ? ColorManager.infoText
                    : (isDone ? ColorManager.success : ColorManager.textSecondary),
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieTile({
    required BuildContext context,
    required TransformationDailyLog log,
    required Color primaryColor,
  }) {
    final isDone = log.calorieStatus == AccountabilityStatus.completed;
    final isPartial = log.calorieStatus == AccountabilityStatus.partiallyCompleted;
    final ratio = log.targetCalories > 0 ? (log.actualCalories / log.targetCalories).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.small.r),
        border: Border.all(
          color: isDone ? ColorManager.success.withValues(alpha: 0.5) : ColorManager.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ColorManager.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_fire_department_rounded, color: ColorManager.accentText, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Calorie Target',
                            style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${log.actualCalories.round()} / ${log.targetCalories.round()} kcal',
                          style: TextStyle(
                            color: isDone ? ColorManager.successText : ColorManager.textPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 5.h,
                        backgroundColor: ColorManager.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDone ? ColorManager.success : ColorManager.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDone
                    ? '✓ On target (within ±10% tolerance)'
                    : (isPartial ? 'Close to target' : 'Tracking in progress'),
                style: TextStyle(
                  color: isDone ? ColorManager.successText : ColorManager.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              InkWell(
                key: const Key('checklist_view_meals_button'),
                onTap: () => context.push(Routes.transformationNutritionRoute),
                child: Text(
                  'View Meals 🥗',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProteinTile({
    required TransformationDailyLog log,
    required Color primaryColor,
  }) {
    final isDone = log.proteinStatus == AccountabilityStatus.completed;
    final isPartial = log.proteinStatus == AccountabilityStatus.partiallyCompleted;
    final ratio = log.targetProtein > 0 ? (log.actualProtein / log.targetProtein).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.small.r),
        border: Border.all(
          color: isDone ? ColorManager.success.withValues(alpha: 0.5) : ColorManager.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ColorManager.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.egg_alt_rounded, color: ColorManager.accentText, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Protein Target',
                            style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${log.actualProtein.round()} / ${log.targetProtein.round()} g',
                          style: TextStyle(
                            color: isDone ? ColorManager.successText : ColorManager.textPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 5.h,
                        backgroundColor: ColorManager.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDone ? ColorManager.success : ColorManager.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isDone
                  ? '✓ Muscle protection target achieved (≥90%)'
                  : (isPartial ? 'Partial intake (≥70%)' : 'Target: ${log.targetProtein.round()}g lean protein'),
              style: TextStyle(
                color: isDone ? ColorManager.successText : ColorManager.textSecondary,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTile({
    required BuildContext context,
    required TransformationDailyLog log,
    required TransformationProvider provider,
    required ConsumptionProvider? consumptionProvider,
    required Color primaryColor,
    required bool isToday,
  }) {
    final isDone = log.waterStatus == AccountabilityStatus.completed;
    final ratio = log.targetWaterMl > 0 ? (log.actualWaterMl / log.targetWaterMl).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.small.r),
        border: Border.all(
          color: isDone ? ColorManager.success.withValues(alpha: 0.5) : ColorManager.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ColorManager.info.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.water_drop_rounded, color: ColorManager.infoText, size: 18),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Water Hydration Goal',
                            style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${(log.actualWaterMl / 1000).toStringAsFixed(1)} / ${(log.targetWaterMl / 1000).toStringAsFixed(1)} L',
                          style: TextStyle(
                            color: isDone ? ColorManager.successText : ColorManager.textPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 5.h,
                        backgroundColor: ColorManager.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDone ? ColorManager.success : ColorManager.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                key: const Key('configure_water_goal_button'),
                onTap: () => ConfigureWaterGoalDialog.show(
                  context: context,
                  currentTargetMl: log.targetWaterMl,
                  provider: provider,
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: ColorManager.infoText, size: 12.sp),
                    SizedBox(width: 3.w),
                    Text(
                      'Goal: ${(log.targetWaterMl / 1000).toStringAsFixed(1)}L',
                      style: TextStyle(color: ColorManager.infoText, fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (isToday && consumptionProvider != null)
                InkWell(
                  key: const Key('quick_add_water_button'),
                  onTap: () async {
                    await consumptionProvider.addWater(
                      amount: 250.0,
                      dateTime: DateTime.now(),
                    );
                  },
                  borderRadius: BorderRadius.circular(6.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: ColorManager.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '+250 ml 💧',
                      style: TextStyle(
                        color: ColorManager.infoText,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryTile({
    required BuildContext context,
    required TransformationDailyLog log,
    required TransformationProvider provider,
    required ConsumptionProvider? consumptionProvider,
    required Color primaryColor,
    required DateTime targetDate,
  }) {
    final isRecorded = log.recoveryLevel != null && log.recoveryLevel!.isNotEmpty;
    final level = log.recoveryLevel?.toLowerCase();

    String levelTitle = 'Pending check-in';
    Color levelColor = ColorManager.textSecondary;
    String emoji = '🛏️';

    if (level == 'good') {
      levelTitle = 'Well Rested & Energetic';
      levelColor = ColorManager.success;
      emoji = '⚡️';
    } else if (level == 'moderate') {
      levelTitle = 'Normal / Moderate';
      levelColor = ColorManager.warning;
      emoji = '👍';
    } else if (level == 'poor') {
      levelTitle = 'High Fatigue / Need Rest';
      levelColor = ColorManager.error;
      emoji = '😴';
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.small.r),
        border: Border.all(
          color: isRecorded ? levelColor.withValues(alpha: 0.4) : ColorManager.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isRecorded ? levelColor.withValues(alpha: 0.15) : ColorManager.surface,
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: TextStyle(fontSize: 16.sp)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Recovery & Sleep',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isRecorded
                      ? '$levelTitle ${log.recoveryNote != null ? '• "${log.recoveryNote}"' : ''}'
                      : 'Log fatigue & sleep quality',
                  style: TextStyle(
                    color: isRecorded ? levelColor : ColorManager.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: isRecorded ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          InkWell(
            key: const Key('open_recovery_checkin_button'),
            onTap: () => RecoveryCheckInDialog.show(
              context: context,
              date: targetDate,
              provider: provider,
              consumptionProvider: consumptionProvider,
              initialLevel: log.recoveryLevel,
              initialNote: log.recoveryNote,
            ),
            borderRadius: BorderRadius.circular(6.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                isRecorded ? 'Update' : 'Check In',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
