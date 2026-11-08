import 'package:fitness_app/presentation/home/widgets/gradient_hero_card.dart';
import 'package:fitness_app/presentation/widgets/reminder_opt_in_card.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// What the "Your plan is ready" screen needs; passed through the router
/// `extra` right after the profile form is saved.
class PlanReadyArgs {
  const PlanReadyArgs({
    required this.name,
    required this.goal,
    required this.calories,
  });

  /// First name, may be empty.
  final String name;

  /// One of [StringsManager.lose], [StringsManager.maintain],
  /// [StringsManager.gain].
  final String goal;

  /// Daily calorie target already adjusted for the goal.
  final double calories;
}

/// First-run payoff: shows the personal calorie target and the next three
/// steps, and asks for reminders while motivation is highest.
class PlanReadyScreen extends StatelessWidget {
  const PlanReadyScreen({
    super.key,
    required this.args,
    required this.onBuildWorkout,
    required this.onSkip,
    this.reminderCard = const ReminderOptInCard(),
  });

  final PlanReadyArgs args;

  /// Primary action: go to the dashboard and open the AI workout builder.
  final VoidCallback onBuildWorkout;

  /// Secondary action: go straight to the dashboard.
  final VoidCallback onSkip;

  /// Replaceable so tests do not touch notification plugins.
  final Widget reminderCard;

  static const int weeklyWorkouts = 3;

  /// Human label and calorie explanation for each goal.
  static ({String label, String imageHint, String note}) copyFor(String goal) {
    if (goal == StringsManager.lose) {
      return (
        label: 'Lose weight',
        imageHint: 'Lose weight',
        note: '20% below your maintenance calories',
      );
    }
    if (goal == StringsManager.gain) {
      return (
        label: 'Build muscle',
        imageHint: 'Build muscle',
        note: '20% above your maintenance calories',
      );
    }
    return (
      label: 'Stay in shape',
      imageHint: 'Tone up',
      note: 'Matches your maintenance calories',
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = copyFor(args.goal);
    final kcal = NumberFormat.decimalPattern().format(args.calories.round());
    final name = args.name.trim();

    return Scaffold(
      backgroundColor: ColorManager.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                key: const Key('plan_ready_scroll'),
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      name.isEmpty ? 'Welcome!' : 'Welcome, $name',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Your plan is ready',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    GradientHeroCard(
                      key: const Key('plan_ready_hero'),
                      tone: HeroTone.teal,
                      imageAsset: HeroImages.forGoal(copy.imageHint),
                      imageSize: 130.w,
                      imageTop: 24.h,
                      padding: EdgeInsets.all(18.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HeroBadge(text: 'YOUR DAILY TARGET'),
                          SizedBox(height: 14.h),
                          Padding(
                            padding: EdgeInsets.only(
                                right: GradientHeroCard.textInset),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kcal,
                                  key: const Key('plan_ready_kcal'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  'kcal per day',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  copy.note,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Wrap(
                            spacing: 6.w,
                            runSpacing: 6.h,
                            children: [
                              HeroMetaChip(
                                icon: Icons.flag_rounded,
                                text: copy.label,
                              ),
                              const HeroMetaChip(
                                icon: Icons.calendar_today_rounded,
                                text: '$weeklyWorkouts workouts / week',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'What happens next',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _step(Icons.fitness_center_rounded,
                        'Build your first workout in about a minute with the AI planner.'),
                    _step(Icons.local_fire_department_rounded,
                        'Finish it to earn your first badge and start your streak.'),
                    _step(Icons.notifications_active_rounded,
                        'Pick a reminder time so day 2 does not slip.'),
                    SizedBox(height: 8.h),
                    reminderCard,
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 12.h),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key('plan_ready_build_workout'),
                      onPressed: onBuildWorkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'Build my first workout',
                        style: TextStyle(
                          color: ColorManager.onMint,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    key: const Key('plan_ready_skip'),
                    onPressed: onSkip,
                    child: Text(
                      'Skip to dashboard',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
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
  }

  Widget _step(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorManager.primary.withValues(alpha: 0.16),
            ),
            child: Icon(icon, color: ColorManager.primary, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                text,
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 13.sp,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
