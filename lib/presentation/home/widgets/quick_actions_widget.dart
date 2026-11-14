import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness_app/utils/router/router.dart';

import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Water logging lives on the Today's Snapshot water card, so it is not
    // repeated here.
    return Selector<StatisticsProvider, bool>(
      selector: (_, stats) => stats.hasWorkoutToday,
      builder: (context, workoutDoneToday, _) {
        final List<Map<String, dynamic>> actions = [
          {
            'icon': Icons.play_arrow_rounded,
            'label': 'Start workout',
            'isCompleted': false,
            // Live, from scratch: rest timer, tick sets, add exercises.
            'onTap': () => DayWorkoutSessionPage.startQuickWorkout(context),
          },
          {
            'icon': Icons.restaurant_menu_rounded,
            'label': 'Log Meal',
            'alias': 'Diet Plans',
            'isCompleted': false,
            'onTap': () {
              final transformationProvider =
                  Provider.of<TransformationProvider?>(context, listen: false);
              if (transformationProvider != null &&
                  transformationProvider.hasActiveTransformation) {
                context.push(Routes.transformationNutritionRoute);
              } else {
                context.push(Routes.dietRoute);
              }
            },
          },
          {
            'icon': Icons.fitness_center_rounded,
            'label': 'Log past workout',
            'isCompleted': workoutDoneToday,
            // The form: today or an earlier date, several exercises.
            'onTap': () => context.push(Routes.workoutLogRoute),
          },
          {
            'icon': Icons.auto_awesome_rounded,
            'label': 'Plan Builder',
            'alias': 'Routine Builder',
            'isCompleted': false,
            'onTap': () {
              context.push(Routes.workoutGeneratorRoute);
            },
          },
        ];

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) SizedBox(width: 8.w),
                    Expanded(child: _buildActionTile(actions[i])),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// One quick-action tile: its own surface card with a ringed icon chip.
  Widget _buildActionTile(Map<String, dynamic> act) {
    final bool isCompleted = act['isCompleted'] as bool? ?? false;
    final String? alias = act['alias'] as String?;
    final String label = act['label'] as String;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: act['onTap'] as VoidCallback,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: BoxConstraints(minHeight: 96.h),
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: ColorManager.surface,
            borderRadius: BorderRadius.circular(AppRadius.card.r),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          color: ColorManager.chipBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted
                                ? ColorManager.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          act['icon'] as IconData,
                          color: ColorManager.primaryText,
                          size: 22.sp,
                        ),
                      ),
                      if (isCompleted)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: ColorManager.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: ColorManager.onMint,
                              size: 10.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 12.sp,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (alias != null)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.0,
                    child: Center(
                      child: Text(
                        alias,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
