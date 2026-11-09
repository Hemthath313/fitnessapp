import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
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
                                        ),
                                        SizedBox(width: 4.w),
                                        Flexible(
                                          child: Text(
                                            'Calories',
                                            style: TextStyle(
                                              color: ColorManager.textSecondary,
                                              fontSize: 11.sp,
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
                                      child: Text(
                                        '$consumedCalories kcal',
                                        style: TextStyle(
                                          color: ColorManager.textPrimary,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        hasTarget
                                            ? '/ ${targetCalories.toStringAsFixed(0)} kcal'
                                            : 'Not Set',
                                        style: TextStyle(
                                          color: ColorManager.textSecondary,
                                          fontSize: 11.sp,
                                        ),
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
                                          color: hasTarget
                                              ? (remainingCalories > 0
                                                  ? ColorManager.primaryText
                                                  : ColorManager.successText)
                                              : ColorManager.warningText,
                                              fontSize: 11.sp,
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
                                        ),
                                        SizedBox(width: 4.w),
                                        Flexible(
                                          child: Text(
                                            'Water',
                                            style: TextStyle(
                                              color: ColorManager.textSecondary,
                                              fontSize: 11.sp,
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
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 2.w),
                                          Text(
                                            'L',
                                            style: TextStyle(
                                              color: ColorManager.textPrimary,
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            '/ ${waterGoal.toStringAsFixed(1)} L',
                                            style: TextStyle(
                                              color: ColorManager.textSecondary,
                                              fontSize: 11.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${(waterPercent * 100).toInt()}% of goal',
                                        style: TextStyle(
                                          color: waterPercent >= 1.0
                                              ? ColorManager.successText
                                              : ColorManager.primaryText,
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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

/// Circular progress ring around an icon, as in the Daily Companion tiles:
/// dark circle, light icon, amber arc showing today's progress.
class _RingIcon extends StatelessWidget {
  final IconData icon;
  final double percent;

  const _RingIcon({required this.icon, required this.percent});

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
              color: ColorManager.ringAmber,
              backgroundColor: ColorManager.iconChip,
            ),
          ),
          Container(
            width: size - 10.w,
            height: size - 10.w,
            decoration: const BoxDecoration(
              color: ColorManager.iconChip,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15.sp, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
