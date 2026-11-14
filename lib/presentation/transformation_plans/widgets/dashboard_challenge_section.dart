import 'package:fitness_app/presentation/home/widgets/gradient_hero_card.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_slider_home_widget.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/transformation_daily_checklist.dart';
import 'package:fitness_app/utils/managers/card_size_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';

/// Dashboard Challenges Section.
/// Displays either the active transformation, a completed transformation summary,
/// or a featured challenge card when no plan is active, plus the preserved mini-challenge carousel.
class DashboardChallengeSection extends StatelessWidget {
  final TransformationPlanBlueprint? overrideRecommendedPlanForTesting;
  final bool suppressActiveTransformation;

  const DashboardChallengeSection({
    super.key,
    this.overrideRecommendedPlanForTesting,
    this.suppressActiveTransformation = true,
  });

  /// Selects the recommended programme using the user's actual onboarding information:
  /// - Fitness goal.
  /// - Fitness experience level.
  /// - Activity level, where relevant.
  static TransformationPlanBlueprint getRecommendedProgramme({
    Map<String, dynamic>? userData,
  }) {
    if (userData == null || userData.isEmpty) {
      // Sensible fallback when profile information is unavailable
      return TransformationPlansData.weightLoss60;
    }

    final experienceRaw = (userData['experience'] ??
            userData['experienceLevel'] ??
            userData['fitness_level'] ??
            userData['fitnessLevel'] ??
            userData['level'] ??
            '')
        .toString()
        .toLowerCase()
        .trim();

    final goalRaw = (userData['goal'] ?? '').toString().toUpperCase().trim();
    final activityRaw = (userData['activity'] ?? '').toString().toUpperCase().trim();

    final bool isBeginnerExperience = experienceRaw.contains('beginner') ||
        experienceRaw.contains('novice') ||
        experienceRaw.contains('starter');

    // Rule 1: Beginner experience always takes precedence -> Complete Beginner 30-Day
    // (e.g. beginner with a muscle-gain, weight-loss, or maintain goal).
    if (isBeginnerExperience) {
      return TransformationPlansData.beginnerFitness30;
    }

    // Rule 2: If experience is unspecified, check activity level
    final bool isSedentary = activityRaw.contains('SEDENTARY') || activityRaw == 'LOW';
    final bool isExplicitlyAdvancedOrIntermediate = experienceRaw.contains('intermediate') ||
        experienceRaw.contains('advanced') ||
        experienceRaw.contains('pro') ||
        experienceRaw.contains('athlete');

    if (isSedentary &&
        !isExplicitlyAdvancedOrIntermediate &&
        !goalRaw.contains('STRENGTH') &&
        !goalRaw.contains('GAIN')) {
      return TransformationPlansData.beginnerFitness30;
    }

    // Rule 3: Goal-based mapping for non-beginners
    if (goalRaw.contains('STRENGTH') || goalRaw.contains('POWER')) {
      return TransformationPlansData.strength12Week;
    } else if (goalRaw.contains('GAIN') ||
        goalRaw.contains('BUILD') ||
        goalRaw.contains('MUSCLE') ||
        goalRaw.contains('BULK')) {
      return TransformationPlansData.muscleBuilding90;
    } else if (goalRaw.contains('LOSE') ||
        goalRaw.contains('WEIGHT') ||
        goalRaw.contains('FAT') ||
        goalRaw.contains('CUT') ||
        goalRaw.contains('SHRED')) {
      return TransformationPlansData.weightLoss60;
    } else if (goalRaw.contains('MAINTAIN')) {
      // Do not treat Maintain as automatically meaning Beginner.
      return TransformationPlansData.weightLoss60;
    }

    // Sensible default fallback
    return TransformationPlansData.weightLoss60;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header with Title and "View All" CTA
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      color: ColorManager.primaryText,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Challenges',
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                key: const Key('view_all_challenges_button'),
                onTap: () => context.push(Routes.transformationPlansRoute),
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: ColorManager.primaryText,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: ColorManager.primaryText,
                        size: 11.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // 2. Challenges shelf: recommended programme first, then the Six-Pack,
        //    other programmes and the weekly technique (swipe to browse).
        Consumer<TransformationProvider?>(
          builder: (context, provider, _) {
            HomeProvider? homeProvider;
            try {
              homeProvider = Provider.of<HomeProvider?>(context);
            } catch (_) {
              homeProvider = null;
            }

            final featured = overrideRecommendedPlanForTesting ??
                getRecommendedProgramme(userData: homeProvider?.userData);
            final personalised = overrideRecommendedPlanForTesting == null &&
                (homeProvider?.userData.isNotEmpty ?? false);

            Widget featuredCard() => _buildProgrammeCard(
                  context,
                  featured,
                  badge: personalised
                      ? 'RECOMMENDED FOR YOU'
                      : 'FEATURED PROGRAMME',
                  cardKey: const Key('featured_challenge_card'),
                  ctaKey: const Key('explore_challenge_cta'),
                  ctaLabel: 'Explore Challenge',
                );

            // Other primary programmes, shown after the Six-Pack.
            List<Widget> otherProgrammes() => TransformationPlansData
                .primaryPlans
                .where((p) => p.id != featured.id)
                .take(2)
                .map((p) => _buildProgrammeCard(
                      context,
                      p,
                      badge: _categoryFor(p).$1.toUpperCase(),
                      cardKey: Key('shelf_programme_${p.id}'),
                      ctaLabel: 'Explore Programme',
                    ))
                .toList();

            // A finished / running programme is shown above the shelf.
            Widget? above;
            List<Widget> leading = const [];
            List<Widget> middle = const [];

            if (provider == null) {
              leading = [featuredCard()];
              middle = otherProgrammes();
            } else if (provider.isLoading) {
              leading = [_buildLoadingPlaceholder(context)];
            } else if (provider.hasActiveTransformation) {
              // Phase 3 Deduplication: the active transformation is already shown
              // in HomeAiRoutineCard (the primary workout hero).
              if (!suppressActiveTransformation) {
                above = _buildActiveChallengeCard(
                  context,
                  provider.activeTransformation!,
                );
              }
            } else {
              final hasCompleted = provider.history.isNotEmpty &&
                  provider.history.first.status == 'completed';
              if (hasCompleted) {
                above = _buildCompletedChallengeCard(
                  context,
                  provider.history.first,
                );
              }
              leading = [featuredCard()];
              middle = otherProgrammes();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (above != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 14.h),
                    child: above,
                  ),
                CarouselSliderHomeWidget(leading: leading, middle: middle),
              ],
            );
          },
        ),
      ],
    );
  }


  /// Goal label + icon shown on a programme card.
  (String, IconData) _categoryFor(TransformationPlanBlueprint plan) {
    if (plan.id == TransformationPlansData.beginnerFitness30.id) {
      return ('Foundation', Icons.spa_rounded);
    } else if (plan.id == TransformationPlansData.weightLoss60.id) {
      return ('Fat Loss', Icons.local_fire_department_rounded);
    } else if (plan.id == TransformationPlansData.muscleBuilding90.id) {
      return ('Muscle Mass', Icons.fitness_center_rounded);
    } else if (plan.id == TransformationPlansData.strength12Week.id) {
      return ('Strength', Icons.bolt_rounded);
    }
    return ('Conditioning', Icons.fitness_center_rounded);
  }

  /// A programme card for the Challenges shelf (recommended or "other").
  /// Calm by design: badge, title, two facts, one button. Description,
  /// difficulty and structure live on the programme detail screen.
  Widget _buildProgrammeCard(
    BuildContext context,
    TransformationPlanBlueprint plan, {
    required String badge,
    required Key cardKey,
    Key? ctaKey,
    required String ctaLabel,
  }) {
    final (categoryLabel, categoryIcon) = _categoryFor(plan);

    return GradientHeroCard(
      key: cardKey,
      tone: HeroImages.toneForPlan(plan.id),
      imageAsset: HeroImages.forKey(HeroImages.keyForPlan(plan.id)),
      photoAsset: HeroImages.photoForPlan(plan.id),
      imageSize: AppCardSize.heroImageSize,
      imageTop: AppCardSize.heroImageTop,
      height: CarouselHomeBox.heightOf(context),
      padding: EdgeInsets.all(AppCardSize.heroPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: HeroBadge(text: badge, icon: Icons.bolt_rounded),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 11.sp),
                    SizedBox(width: 3.w),
                    Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.only(right: GradientHeroCard.textInset),
            child: Text(
              plan.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: AppCardSize.heroTitleSize,
                height: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              HeroMetaChip(icon: categoryIcon, text: categoryLabel),
              HeroMetaChip(
                icon: Icons.calendar_today_rounded,
                text: '${plan.durationDays} Days',
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: ctaKey,
              onPressed: () {
                context.push(
                  '${Routes.transformationPlanDetailRoute}?planId=${plan.id}',
                  extra: plan,
                );
              },
              icon: Icon(Icons.arrow_forward_rounded,
                  size: 16.sp, color: ColorManager.inkOnLight),
              label: Text(
                ctaLabel,
                style: TextStyle(
                  color: ColorManager.inkOnLight,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                    vertical: AppCardSize.heroButtonPadding),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button.r),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// State B: Active Transformation Card
  Widget _buildActiveChallengeCard(
    BuildContext context,
    UserTransformationState state,
  ) {
    final pct = (state.completionPercentage * 100).toInt();

    // Determine next pending milestone
    final pendingMilestones = state.milestones.where((m) => !m.isAchieved).toList();
    final nextMilestone = pendingMilestones.isNotEmpty ? pendingMilestones.first : null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        key: const Key('active_challenge_card'),
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(AppRadius.card.r),
        ),
        padding: EdgeInsets.all(AppCardSize.heroPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active badge + Phase tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7.w,
                        height: 7.w,
                        decoration: const BoxDecoration(
                          color: ColorManager.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'ACTIVE CHALLENGE',
                        style: TextStyle(
                          color: ColorManager.primaryText,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Week ${state.currentWeekNumber}',
                  style: TextStyle(
                    color: ColorManager.primaryText,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Title
            Text(
              state.planTitle,
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),

            // Progress Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Day ${state.currentDay} of ${state.totalDays}',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$pct% Completed',
                  style: TextStyle(
                    color: ColorManager.primaryText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: LinearProgressIndicator(
                value: state.completionPercentage,
                minHeight: 8.h,
                backgroundColor: ColorManager.surfaceDark,
                valueColor: const AlwaysStoppedAnimation<Color>(ColorManager.primary),
              ),
            ),
            SizedBox(height: 12.h),

            // Next Milestone
            if (nextMilestone != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: ColorManager.surfaceDark,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.military_tech_rounded,
                      color: ColorManager.warningText,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Next Milestone: ${nextMilestone.title} (Day ${nextMilestone.triggerDay})',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
            ],

            // Compact Daily Accountability Checklist Summary
            const TransformationDailyChecklist(compact: true),
            SizedBox(height: 10.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    key: const Key('continue_challenge_cta'),
                    onPressed: () {
                      context.push(Routes.transformationRoadmapRoute);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button.r),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 18, color: ColorManager.onMint),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              color: ColorManager.onMint,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    key: const Key('view_progress_cta'),
                    onPressed: () {
                      context.push(Routes.transformationProgressRoute);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorManager.primaryText,
                      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                      side: BorderSide(color: ColorManager.primary.withValues(alpha: 0.6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button.r),
                      ),
                    ),
                    child: Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// State C: Completed Transformation Card
  Widget _buildCompletedChallengeCard(
    BuildContext context,
    UserTransformationState state,
  ) {
    final completedDateStr = state.completedAt != null
        ? DateFormat('MMMM d, yyyy').format(state.completedAt!)
        : 'Recently';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        key: const Key('completed_challenge_card'),
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(AppRadius.card.r),
        ),
        padding: EdgeInsets.all(AppCardSize.heroPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: ColorManager.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_rounded, color: ColorManager.successText, size: 13),
                      SizedBox(width: 5.w),
                      Text(
                        'PROGRAMME COMPLETED 🏆',
                        style: TextStyle(
                          color: ColorManager.successText,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    completedDateStr,
                    style: TextStyle(
                      color: ColorManager.textTertiary,
                      fontSize: 12.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            Text(
              state.planTitle,
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),

            Text(
              'Congratulations! You finished all ${state.totalDays} days of your transformation programme. Outstanding dedication to your health and discipline.',
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 12.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16.h),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    key: const Key('view_results_cta'),
                    onPressed: () => context.push(
                      Routes.transformationCompletionRoute,
                      extra: state,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.successDark,
                      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button.r),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.insights_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            'View Results',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('explore_another_challenge_cta'),
                    onPressed: () => context.push(Routes.transformationPlansRoute),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorManager.primaryText,
                      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                      side: BorderSide(color: ColorManager.primary.withValues(alpha: 0.6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button.r),
                      ),
                    ),
                    child: Text(
                      'Explore Plans',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Container(
      height: CarouselHomeBox.heightOf(context),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.hero.r),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}
