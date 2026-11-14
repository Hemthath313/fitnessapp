import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/utils/app_feedback.dart';
import 'package:fitness_app/utils/haptics.dart';
import 'package:fitness_app/presentation/home/widgets/fitness_data_widget.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Compact Today's Health Snapshot for Option A (Focused Daily Companion).
///
/// Combines:
/// 1. Calories consumed vs valid calorie target (never BMR).
/// 2. Water consumed vs user's configured dynamic water goal.
class TodayHealthSnapshotWidget extends StatefulWidget {
  const TodayHealthSnapshotWidget({super.key});

  @override
  State<TodayHealthSnapshotWidget> createState() =>
      _TodayHealthSnapshotWidgetState();
}

class _TodayHealthSnapshotWidgetState extends State<TodayHealthSnapshotWidget> {
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    // Only hit Firestore when nothing is cached yet (the app bar does the
    // same); every edit screen refreshes the shared user data itself.
    _userDataFuture = homeProvider.userData.isNotEmpty
        ? Future<Map<String, dynamic>>.value(homeProvider.userData)
        : homeProvider.fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ConsumptionProvider>(
      builder: (context, consumptionProvider, _) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            final homeProvider =
                Provider.of<HomeProvider>(context, listen: false);
            final cachedData = homeProvider.userData;
            final effectiveData =
                (snapshot.hasData && snapshot.data!.isNotEmpty)
                    ? snapshot.data!
                    : (cachedData.isNotEmpty ? cachedData : <String, dynamic>{});

            final calorieInfo = FitnessDataWidget.resolveCalorieGoal(
              context: context,
              userData: effectiveData,
            );
            final hasTarget = calorieInfo.hasValidTarget;
            final targetCalories = calorieInfo.targetCalories ?? 0.0;
            final consumedCalories = consumptionProvider.consumedCalories;
            final remainingCalories = hasTarget
                ? (targetCalories - consumedCalories).clamp(0.0, double.infinity)
                : 0.0;
            final caloriePercent = (hasTarget && targetCalories > 0
                    ? (consumedCalories / targetCalories)
                    : 0.0)
                .clamp(0.0, 1.0);

            final waterGoal = FitnessDataWidget.resolveWaterGoal(
              context: context,
              consumptionProvider: consumptionProvider,
              userData: effectiveData,
            );
            final consumedWater = consumptionProvider.waterADay;
            final waterPercent = (waterGoal > 0 ? (consumedWater / waterGoal) : 0.0)
                .clamp(0.0, 1.0);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Section title
                    Row(
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          color: ColorManager.primaryText,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Today's Snapshot",
                              style: TextStyle(
                                color: ColorManager.textPrimary,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),

                    // Today's goals: one small row to "complete" every day.
                    _TodayGoalsRow(
                      waterDone: waterGoal > 0 && consumedWater >= waterGoal,
                      caloriesDone: hasTarget &&
                          targetCalories > 0 &&
                          consumedCalories >= targetCalories * 0.9,
                    ),
                    SizedBox(height: 12.h),

                    // Metrics: Side-by-Side Calories & Water compact cards
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left: Calorie Tracker Card
                          Expanded(
                            child: GestureDetector(
                              key: const Key('snapshot_calorie_card'),
                              // Always opens the Diet page: it shows the plan, macros
                              // and the "set your goal" prompt when no target exists.
                              onTap: () => context.push(Routes.dietRoute),
                              child: Container(
                                padding: EdgeInsets.all(14.w),
                                decoration: BoxDecoration(
                                  color: ColorManager.surface,
                                  boxShadow: ColorManager.cardShadow,
                                  borderRadius: BorderRadius.circular(AppRadius.card.r),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _RingIcon(
                                          icon: Icons.local_fire_department_rounded,
                                          percent: caloriePercent,
                                          tint: ColorManager.calorie,
                                          accent: ColorManager.calorieText,
                                        ),
                                        SizedBox(width: 4.w),
                                        Flexible(
                                          child: Text(
                                            'Calories',
                                            style: TextStyle(
                                              color: ColorManager.textSecondary,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: ColorManager.textSecondary
                                              .withValues(alpha: 0.4),
                                          size: 14.sp,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    // Big number, target beside it in grey.
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            '$consumedCalories kcal',
                                            style: TextStyle(
                                              color: ColorManager.textPrimary,
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            hasTarget
                                                ? '/ ${targetCalories.toStringAsFixed(0)} kcal'
                                                : 'Not Set',
                                            style: TextStyle(
                                              color: ColorManager.textSecondary,
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        hasTarget
                                            ? '${remainingCalories.toStringAsFixed(0)} left'
                                            : 'Set a goal',
                                        style: TextStyle(
                                          // Plain grey status; green once the
                                          // target is reached, amber if no goal.
                                          color: hasTarget
                                              ? (remainingCalories > 0
                                                  ? ColorManager.textSecondary
                                                  : ColorManager.successText)
                                              : ColorManager.warningText,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),

                          // Right: Water Tracker Card
                          Expanded(
                            child: GestureDetector(
                              key: const Key('snapshot_water_card'),
                              onTap: () => context.push(Routes.addWaterRoute),
                              child: Container(
                                padding: EdgeInsets.all(14.w),
                                decoration: BoxDecoration(
                                  color: ColorManager.surface,
                                  boxShadow: ColorManager.cardShadow,
                                  borderRadius: BorderRadius.circular(AppRadius.card.r),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _RingIcon(
                                          icon: Icons.water_drop_rounded,
                                          percent: waterPercent,
                                          tint: ColorManager.water,
                                          accent: ColorManager.waterText,
                                        ),
                                        SizedBox(width: 4.w),
                                        Flexible(
                                          child: Text(
                                            'Water',
                                            style: TextStyle(
                                              color: ColorManager.textSecondary,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: ColorManager.textSecondary
                                              .withValues(alpha: 0.4),
                                          size: 14.sp,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            consumedWater.toStringAsFixed(1),
                                            style: TextStyle(
                                              color: ColorManager.textPrimary,
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 2.w),
                                          Text(
                                            'L',
                                            style: TextStyle(
                                              color: ColorManager.textPrimary,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            '/ ${waterGoal.toStringAsFixed(1)} L',
                                            style: TextStyle(
                                              color: ColorManager.textSecondary,
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${(waterPercent * 100).toInt()}% of goal',
                                        style: TextStyle(
                                          color: waterPercent >= 1.0
                                              ? ColorManager.successText
                                              : ColorManager.textSecondary,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                        ),
                                        _QuickWaterButton(
                                          waterGoal: waterGoal,
                                          provider: consumptionProvider,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

/// Circular progress ring around an icon. Each metric has its own colour:
/// a soft [tint] circle, and the icon plus progress arc in [accent].
/// The faint track keeps the ring visible at 0%.
class _RingIcon extends StatelessWidget {
  final IconData icon;
  final double percent;
  final Color tint;
  final Color accent;

  const _RingIcon({
    required this.icon,
    required this.percent,
    required this.tint,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final double size = 38.w;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              strokeWidth: 2.6,
              strokeCap: StrokeCap.round,
              color: accent,
              backgroundColor: tint.withValues(alpha: 0.22),
            ),
          ),
          Container(
            width: size - 10.w,
            height: size - 10.w,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15.sp, color: accent),
          ),
        ],
      ),
    );
  }
}

/// One-tap "+0.25 L" on the water card, with an Undo in the confirmation.
class _QuickWaterButton extends StatefulWidget {
  const _QuickWaterButton({required this.waterGoal, required this.provider});

  final double waterGoal;
  final ConsumptionProvider provider;

  @override
  State<_QuickWaterButton> createState() => _QuickWaterButtonState();
}

class _QuickWaterButtonState extends State<_QuickWaterButton> {
  static const double _amount = 0.25; // liters
  bool _busy = false;

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    Haptics.light();
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await widget.provider.addWater(
        amount: _amount,
        dateTime: DateTime.now(),
        goalLiters: widget.waterGoal,
      );
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Added 0.25 L of water',
              style: TextStyle(color: ColorManager.textPrimary)),
          backgroundColor: ColorManager.surfaceLight,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Undo',
            textColor: ColorManager.primaryText,
            onPressed: () =>
                widget.provider.undoLastWater(goalLiters: widget.waterGoal),
          ),
        ));
    } catch (_) {
      if (mounted) AppFeedback.error(context, "Couldn't add water. Try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add 0.25 liters of water',
      child: InkWell(
        key: const Key('snapshot_quick_water_button'),
        onTap: _add,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: ColorManager.water.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: _busy
              ? SizedBox(
                  width: 14.w,
                  height: 14.w,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: ColorManager.waterText),
                )
              : Text(
                  '+0.25 L',
                  style: TextStyle(
                    color: ColorManager.waterText,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

/// "Today: 1 of 3 done" with a chip per goal. Calories is a Pro goal
/// (meal logging is Pro-only); free users see it locked and can tap to learn
/// more.
class _TodayGoalsRow extends StatelessWidget {
  const _TodayGoalsRow({required this.waterDone, required this.caloriesDone});

  final bool waterDone;
  final bool caloriesDone;

  @override
  Widget build(BuildContext context) {
    final stats = Provider.of<StatisticsProvider?>(context);
    final sub = Provider.of<SubscriptionProvider?>(context);
    final isPremium = sub?.isPremium ?? false;
    final now = DateTime.now();
    bool workoutDone = false;
    try {
      workoutDone = stats?.hasWorkoutOnDate(
              StatisticsProvider.normalizeLocalDate(now)) ??
          false;
    } catch (_) {}

    final goals = <(String, IconData, bool, bool)>[
      ('Workout', Icons.fitness_center_rounded, workoutDone, false),
      ('Water', Icons.water_drop_rounded, waterDone, false),
      ('Calories', Icons.local_fire_department_rounded, caloriesDone, !isPremium),
    ];
    final counted = goals.where((g) => !g.$4).toList();
    final done = counted.where((g) => g.$3).length;
    final allDone = done == counted.length;

    return Container(
      key: const Key('today_goals_row'),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(
          color: allDone
              ? ColorManager.successText.withValues(alpha: 0.5)
              : ColorManager.divider,
        ),
      ),
      child: Row(
        children: [
          Text(
            allDone ? 'All done today' : 'Today: $done of ${counted.length}',
            style: TextStyle(
              color: allDone ? ColorManager.successText : ColorManager.textPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          for (final g in goals) ...[
            SizedBox(width: 6.w),
            _GoalChip(label: g.$1, icon: g.$2, done: g.$3, locked: g.$4),
          ],
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.label,
    required this.icon,
    required this.done,
    required this.locked,
  });

  final String label;
  final IconData icon;
  final bool done;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final Color fg = locked
        ? ColorManager.textTertiary
        : (done ? ColorManager.successText : ColorManager.textSecondary);
    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: done && !locked
            ? ColorManager.success.withValues(alpha: 0.14)
            : ColorManager.chipBackground,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            locked
                ? Icons.lock_rounded
                : (done ? Icons.check_circle_rounded : icon),
            size: 14.sp,
            color: fg,
          ),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(color: fg, fontSize: 12.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
    if (!locked) return chip;
    return Tooltip(
      message: 'Calorie tracking is a Pro feature',
      child: InkWell(
        key: Key('today_goal_${label.toLowerCase()}_locked'),
        borderRadius: BorderRadius.circular(20.r),
        onTap: () => context.push(Routes.premiumScreen),
        child: chip,
      ),
    );
  }
}
