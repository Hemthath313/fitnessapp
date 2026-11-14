import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/utils/managers/card_size_manager.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/widgets/gradient_hero_card.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

  /// Empty State: No Plan Active -> Invite user to review and activate their personalized plan
class NoPlanCard extends StatelessWidget {
  const NoPlanCard({super.key});


  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider?>(context);
    final stats = Provider.of<StatisticsProvider?>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider?>(context);
    final isPremium = subscriptionProvider?.isPremium ?? false;
    final userGoal = homeProvider?.userData['goal']?.toString();
    final bool hasOnboardingGoal = userGoal != null && userGoal.isNotEmpty;
    final bool hasExistingSchedule = stats != null && stats.hasActiveSchedule;

    final String title = hasOnboardingGoal
        ? 'Activate 3-Day $userGoal Plan'
        : 'Build Your Workout Plan';
    final String subtitle = hasOnboardingGoal
        ? 'We prepared an adaptive starter split tailored to your goal ($userGoal). Review your schedule and tap to customize.'
        : 'Choose 3 to 6 days per week with smart exercises, rest timers, and video guides.';
    final String buttonLabel = hasOnboardingGoal
        ? 'Review & Customize Plan'
        : 'Build My Plan';
    const Color onLight = ColorManager.inkOnLight;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GradientHeroCard(
        key: const Key('no_plan_hero_card'),
        imageAsset: HeroImages.forGoal(userGoal),
        imageSize: AppCardSize.heroImageSize,
        padding: EdgeInsets.all(AppCardSize.heroPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            HeroBadge(
              text: hasOnboardingGoal
                  ? 'PERSONALIZED FOR YOU'
                  : 'WORKOUT ROUTINE',
              icon: Icons.auto_awesome,
            ),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.only(right: GradientHeroCard.textInset),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.only(right: GradientHeroCard.textInset),
              child: Text(
                subtitle,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12.sp,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                HeroMetaChip(
                  icon: Icons.calendar_today_rounded,
                  text: hasExistingSchedule
                      ? '${stats.scheduledDayNames.length}-Day Schedule'
                      : '3-6 days / week',
                ),
                const HeroMetaChip(icon: Icons.timer_outlined, text: '~45 min'),
                const HeroMetaChip(
                    icon: Icons.play_circle_outline_rounded,
                    text: 'Video guides'),
              ],
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(Routes.workoutGeneratorRoute),
                icon: const Icon(Icons.auto_awesome, size: 18, color: onLight),
                label: Text(
                  buttonLabel,
                  style: TextStyle(
                    color: onLight,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button.r)),
                  elevation: 0,
                ),
              ),
            ),
            if (!isPremium) ...[
              SizedBox(height: 6.h),
              Center(
                child: TextButton.icon(
                  onPressed: () => _activateFreeStarterPlan(context),
                  icon: const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 16),
                  label:  Text(
                    'Or tap to activate Free 3-Day Starter Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _activateFreeStarterPlan(BuildContext context) async {
    try {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      final statsProvider =
          Provider.of<StatisticsProvider>(context, listen: false);
      await workoutProvider.restoreDefaultThreeDaySplit();
      final now = workoutProvider.currentNow;
      await statsProvider.updateScheduledDays(
        const ['Monday', 'Wednesday', 'Friday'],
        effectiveDate: now,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '3-Day Starter Routine activated! Ready for your workout.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: ColorManager.successDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate starter plan: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: ColorManager.error,
          ),
        );
      }
    }
  }
}
