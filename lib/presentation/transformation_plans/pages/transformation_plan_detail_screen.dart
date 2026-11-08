import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';

/// Screen detailing a specific transformation programme curriculum,
/// phases, weekly breakdown, milestones, and enrolment action.
class TransformationPlanDetailScreen extends StatelessWidget {
  final TransformationPlanBlueprint? plan;
  final String? planId;

  const TransformationPlanDetailScreen({
    super.key,
    this.plan,
    this.planId,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve blueprint from passed object or ID
    final resolvedPlan = plan ??
        (planId != null ? TransformationPlansData.getById(planId!) : null) ??
        TransformationPlansData.weightLoss60;

    final subscriptionProvider = Provider.of<SubscriptionProvider?>(context);
    final bool isPremium = subscriptionProvider?.isPremium ?? false;

    Color primaryColor;
    try {
      final hex = resolvedPlan.gradientColorHex.replaceFirst('0x', '');
      primaryColor = Color(int.parse(hex, radix: 16));
    } catch (_) {
      primaryColor = ColorManager.primary;
    }

    return Scaffold(
      backgroundColor: ColorManager.background,
      body: Consumer<TransformationProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            slivers: [
              // 1. Sliver AppBar with Hero Banner
              SliverAppBar(
                expandedHeight: 250.h,
                pinned: true,
                backgroundColor: ColorManager.surface,
                leading: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          ColorManager.surfaceDark,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 16.h),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 4.h,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    resolvedPlan.iconEmoji,
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    '${resolvedPlan.durationDays} DAYS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                resolvedPlan.difficulty,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          resolvedPlan.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          resolvedPlan.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ),

              // 2. Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick stats row
                      _buildMetricsRow(resolvedPlan, primaryColor),
                      SizedBox(height: 20.h),

                      // Programme Overview Card
                      _buildSectionTitle('Programme Overview', Icons.info_outline_rounded),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: ColorManager.surface,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: ColorManager.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resolvedPlan.description,
                              style: TextStyle(
                                color: ColorManager.textSecondary,
                                fontSize: 13.sp,
                                height: 1.45,
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              'Key Highlights',
                              style: TextStyle(
                                color: ColorManager.textPrimary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            ...resolvedPlan.highlights.map(
                              (h) => Padding(
                                padding: EdgeInsets.only(bottom: 6.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: primaryColor,
                                      size: 15.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        h,
                                        style: TextStyle(
                                          color: ColorManager.textSecondary,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Beginner Onboarding Guide (when viewing beginner programme)
                      if (resolvedPlan.id == 'beginner_fitness_30') ...[
                        _buildSectionTitle('Beginner Guide: What to Expect', Icons.school_rounded),
                        SizedBox(height: 8.h),
                        _buildBeginnerGuideCard(resolvedPlan, primaryColor),
                        SizedBox(height: 20.h),
                      ],

                      // Weight Loss Programme Guide (when viewing weight loss programme)
                      if (resolvedPlan.id == 'weight_loss_60') ...[
                        _buildSectionTitle('Weight Loss Guide: What to Expect', Icons.local_fire_department_rounded),
                        SizedBox(height: 8.h),
                        _buildWeightLossGuideCard(context, resolvedPlan, primaryColor),
                        SizedBox(height: 20.h),
                      ],

                      // Muscle Gain Programme Guide (when viewing muscle building programme)
                      if (resolvedPlan.id == 'muscle_building_90') ...[
                        _buildSectionTitle('Muscle Gain Guide: What to Expect', Icons.fitness_center_rounded),
                        SizedBox(height: 8.h),
                        _buildMuscleGainGuideCard(context, resolvedPlan, primaryColor),
                        SizedBox(height: 20.h),
                      ],

                      // Strength Building Programme Guide (when viewing strength programme)
                      if (resolvedPlan.id == 'strength_12_week') ...[
                        _buildSectionTitle('Strength Guide: What to Expect', Icons.emoji_events_rounded),
                        SizedBox(height: 8.h),
                        _buildStrengthGuideCard(context, resolvedPlan, primaryColor),
                        SizedBox(height: 20.h),
                      ],

                      // Curriculum Phases & Weeks Breakdown
                      _buildSectionTitle('Curriculum Roadmap', Icons.timeline_rounded),
                      SizedBox(height: 8.h),
                      ...resolvedPlan.phases.map(
                        (phase) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildPhaseCard(phase, primaryColor),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Milestones Roadmap
                      _buildSectionTitle('Milestone Checkpoints', Icons.flag_rounded),
                      SizedBox(height: 8.h),
                      _buildMilestonesCard(resolvedPlan, primaryColor),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<TransformationProvider>(
        builder: (context, provider, _) {
          final activeState = provider.activeTransformation;
          final isCurrentPlanActive = activeState != null &&
              activeState.isActive &&
              activeState.planId == resolvedPlan.id;

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: ColorManager.surface,
              border: Border(
                top: BorderSide(color: ColorManager.divider, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('plan_detail_bottom_cta'),
                  onPressed: () => _handlePlanAction(
                    context,
                    provider,
                    resolvedPlan,
                    isCurrentPlanActive,
                  ),
                  icon: Icon(
                    isCurrentPlanActive
                        ? Icons.play_arrow_rounded
                        : (isPremium
                            ? Icons.fitness_center_rounded
                            : Icons.lock_outline_rounded),
                    color: Colors.white,
                    size: 18.sp,
                  ),
                  label: Text(
                    isCurrentPlanActive
                        ? 'Continue Day ${activeState.currentDay}'
                        : 'Start ${resolvedPlan.title}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handlePlanAction(
    BuildContext context,
    TransformationProvider provider,
    TransformationPlanBlueprint plan,
    bool isCurrentActive,
  ) {
    final isPremium =
        Provider.of<SubscriptionProvider?>(context, listen: false)?.isPremium ??
            false;

    if (!isPremium) {
      context.push(Routes.premiumScreen);
      return;
    }

    if (isCurrentActive) {
      context.push(Routes.transformationRoadmapRoute);
      return;
    }

    context.push(
      '${Routes.transformationOnboardingRoute}?planId=${plan.id}',
      extra: plan,
    );
  }

  Widget _buildBeginnerGuideCard(TransformationPlanBlueprint plan, Color primaryColor) {
    final guideItems = [
      {
        'title': '3 Workouts per Week',
        'desc': 'Manageable 25–35 min sessions designed to build consistency without burnout.',
        'icon': Icons.calendar_today_rounded,
      },
      {
        'title': '4 Recovery & Rest Days',
        'desc': 'Scheduled 20-min walks, mobility stretches, and 2.5L daily hydration protect your joints.',
        'icon': Icons.self_improvement_rounded,
      },
      {
        'title': 'Home or Gym Flexibility',
        'desc': 'Zero mandatory gym gear. Perform movements with bodyweight at home or light dumbbells at the gym.',
        'icon': Icons.home_repair_service_rounded,
      },
      {
        'title': 'Guided Workout Tracking',
        'desc': 'HD video demonstrations, built-in rest timers, and simple set and rep recording.',
        'icon': Icons.play_circle_fill_rounded,
      },
      {
        'title': 'Lifelong Habit & Graduation',
        'desc': 'After 30 days, movement feels natural and you graduate directly into Muscle Building, Fat Loss, or Strength.',
        'icon': Icons.emoji_events_rounded,
      },
    ];

    return Container(
      key: const Key('beginner_onboarding_guide_card'),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lightbulb_rounded, color: primaryColor, size: 16.sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Everything You Need to Know Before Starting',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...guideItems.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 2.h),
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: ColorManager.surfaceDark,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: primaryColor,
                      size: 14.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          item['desc'] as String,
                          style: TextStyle(
                            color: ColorManager.textSecondary,
                            fontSize: 11.sp,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeightLossGuideCard(
    BuildContext context,
    TransformationPlanBlueprint plan,
    Color primaryColor,
  ) {
    final guideItems = [
      {
        'title': '4 Training Days per Week',
        'desc': 'Structured split pairing compound resistance training with high-density conditioning (40–45 min).',
        'icon': Icons.fitness_center_rounded,
      },
      {
        'title': '3 Dedicated Recovery Days',
        'desc': '1 Active Recovery day (8,000–10,000 steps) plus 2 full rest days to preserve joints and recharge CNS.',
        'icon': Icons.directions_walk_rounded,
      },
      {
        'title': 'Sustainable Energy Deficit',
        'desc': 'Target a moderate ~15–20% caloric deficit with 2.0g protein/kg. No extreme starvation; preserve your muscle mass.',
        'icon': Icons.restaurant_rounded,
      },
      {
        'title': 'Daily Hydration Focus',
        'desc': 'Aim for 2.5L–3.0L water daily to support metabolic function, recovery, and natural appetite regulation.',
        'icon': Icons.water_drop_rounded,
      },
      {
        'title': 'Holistic Progress Tracking',
        'desc': 'Measured via weekly weigh-in check-ins, body circumference cm, progress photos, and gym strength retention.',
        'icon': Icons.analytics_rounded,
      },
      {
        'title': 'Core vs. Fat Loss Reality',
        'desc': 'Ab exercises build core strength, but overall caloric deficit reveals definition. Spot reduction is a myth.',
        'icon': Icons.lightbulb_rounded,
      },
    ];

    return Container(
      key: const Key('weight_loss_onboarding_guide_card'),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_fire_department_rounded, color: primaryColor, size: 16.sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '60-Day Fat Loss: Science & Guidelines',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...guideItems.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 2.h),
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: ColorManager.surfaceDark,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: primaryColor,
                      size: 14.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          item['desc'] as String,
                          style: TextStyle(
                            color: ColorManager.textSecondary,
                            fontSize: 11.sp,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 6.h),

          // Six-Pack Challenge Companion Action
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: ColorManager.surfaceDark,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: ColorManager.divider),
            ),
            child: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Want Focused Core Training?',
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pair with the 30-Day Six-Pack Challenge.',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const Key('explore_six_pack_from_detail_btn'),
                  onPressed: () => context.push(Routes.sixPackChallengeRoute),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    foregroundColor: primaryColor,
                  ),
                  child: const Text('View Abs', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleGainGuideCard(
    BuildContext context,
    TransformationPlanBlueprint plan,
    Color primaryColor,
  ) {
    final guideItems = [
      {
        'title': '4–5 Training Days per Week',
        'desc': 'Structured Upper/Lower and Push-Pull-Legs periodization (40–50 min) engineered for maximum mechanical tension.',
        'icon': Icons.fitness_center_rounded,
      },
      {
        'title': 'Progressive Overload Principle',
        'desc': 'Add 1–2 reps within your target bracket (6–12 reps) before increasing load (+1.25–2.5 kg). The app logs your previous weights.',
        'icon': Icons.trending_up_rounded,
      },
      {
        'title': 'Scheduled Deload Weeks',
        'desc': 'Weeks 4 and 8 reduce volume to 2 sets at RPE 6–7 to dissipate fatigue, protect joints, and resensitize muscle fibers.',
        'icon': Icons.healing_rounded,
      },
      {
        'title': 'Clean Caloric Surplus (10–15%)',
        'desc': 'Fuel hypertrophy with 250–400 kcal above maintenance and ~2.0g protein/kg bodyweight. Quality nutrition drives lean tissue.',
        'icon': Icons.restaurant_rounded,
      },
      {
        'title': 'Gym & Home Equipment Flexibility',
        'desc': 'Designed for barbell, dumbbell, cable, and machine equipment with automatic dumbbell alternatives for home lifters.',
        'icon': Icons.home_repair_service_rounded,
      },
      {
        'title': 'Deep Recovery & Muscle Synthesis',
        'desc': 'Target 7–8 hours of quality sleep. Muscle protein synthesis occurs during deep rest, not while lifting.',
        'icon': Icons.nightlight_round,
      },
    ];

    return Container(
      key: const Key('muscle_gain_onboarding_guide_card'),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bolt_rounded, color: primaryColor, size: 16.sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '90-Day Hypertrophy: Science & Overload Guidelines',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...guideItems.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 2.h),
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: ColorManager.surfaceDark,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: primaryColor,
                      size: 14.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          item['desc'] as String,
                          style: TextStyle(
                            color: ColorManager.textSecondary,
                            fontSize: 11.sp,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 6.h),

          // Bulking Diet Companion Action
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: ColorManager.surfaceDark,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: ColorManager.divider),
            ),
            child: Row(
              children: [
                const Text('🥩', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need Bulking Nutrition Guidance?',
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Target 1.8–2.2g protein/kg and clean surplus with Bulking Diet.',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const Key('explore_bulking_diet_from_detail_btn'),
                  onPressed: () => context.push(Routes.bulkingDietRoute),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    foregroundColor: primaryColor,
                  ),
                  child: const Text('Bulking Diet', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // Strength Analytics Companion Action
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: ColorManager.surfaceDark,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: ColorManager.divider),
            ),
            child: Row(
              children: [
                const Text('📈', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track 1RM & Overload Progress',
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Monitor personal records and strength curves.',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const Key('explore_strength_from_detail_btn'),
                  onPressed: () => context.push(Routes.strengthAnalyticsRoute),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    foregroundColor: primaryColor,
                  ),
                  child: const Text('View 1RM', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthGuideCard(
    BuildContext context,
    TransformationPlanBlueprint plan,
    Color primaryColor,
  ) {
    final guideItems = [
      {
        'title': 'Strength vs. Hypertrophy',
        'desc': 'Strength training develops neural recruitment, tendon stiffness, and rate of force production (3–5 reps), whereas hypertrophy prioritizes volume and metabolic fatigue.',
        'icon': Icons.offline_bolt_rounded,
      },
      {
        'title': 'Core Compound Lifts',
        'desc': 'Focused on the "Big 3" lifts + Overhead Press (Barbell Squat, Bench Press, Deadlift, Military Press) supplemented with functional power accessories.',
        'icon': Icons.fitness_center_rounded,
      },
      {
        'title': '2–3 Minutes Rest Between Sets',
        'desc': 'Heavy compound sets tax the phosphagen (ATP-CP) system. Rest 2–3 full minutes between working sets to maintain bar speed and technical precision.',
        'icon': Icons.timer_rounded,
      },
      {
        'title': 'Technique Before Load Overload',
        'desc': 'Add 1.25–2.5 kg only when you complete all target reps with crisp bar velocity and zero breakdown in form. Never sacrifice posture for bar weight.',
        'icon': Icons.trending_up_rounded,
      },
      {
        'title': 'Scheduled CNS Deloads (Weeks 4, 8 & 11)',
        'desc': 'Programmed 3-set deload weeks dissipate accumulated central nervous system fatigue and allow joints and connective tissue to supercompensate.',
        'icon': Icons.healing_rounded,
      },
      {
        'title': 'Estimated 1RM & PR Vault Integration',
        'desc': 'Gym Buddy safely tracks your estimated 1RM using the validated Epley formula from your submaximal sets. Frequent true 1RM failure attempts are discouraged.',
        'icon': Icons.analytics_rounded,
      },
    ];

    return Container(
      key: const Key('strength_onboarding_guide_card'),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emoji_events_rounded, color: primaryColor, size: 16.sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '12-Week Strength: Science & Progressive Overload Guidelines',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...guideItems.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 2.h),
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: ColorManager.surfaceDark,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: primaryColor,
                      size: 14.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          item['desc'] as String,
                          style: TextStyle(
                            color: ColorManager.textSecondary,
                            fontSize: 11.sp,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 6.h),

          // Strength Analytics & PR Vault Companion Action
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: ColorManager.surfaceDark,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: ColorManager.divider),
            ),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PR Vault & 1RM Progression',
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Track all-time compound records and 1RM curves.',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const Key('explore_strength_analytics_from_detail_btn'),
                  onPressed: () => context.push(Routes.strengthAnalyticsRoute),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    foregroundColor: primaryColor,
                  ),
                  child: const Text('PR Vault', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // Workout History Companion Action
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: ColorManager.surfaceDark,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: ColorManager.divider),
            ),
            child: Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inspect Previous Performance',
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Review past session logs, tonnage, and exercise history.',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const Key('explore_workout_history_from_detail_btn'),
                  onPressed: () => context.push(Routes.workoutHistoryRoute),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    foregroundColor: primaryColor,
                  ),
                  child: const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: ColorManager.primary),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(TransformationPlanBlueprint plan, Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            'Duration',
            '${plan.durationDays} Days',
            Icons.date_range_rounded,
            primaryColor,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildMetricTile(
            'Phases',
            '${plan.phases.length} Phases',
            Icons.layers_rounded,
            primaryColor,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildMetricTile(
            'Difficulty',
            plan.difficulty.split(' ').first,
            Icons.fitness_center_rounded,
            primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              color: ColorManager.textTertiary,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(TransformationPhase phase, Color primaryColor) {
    return Material(
      color: ColorManager.surface,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: ColorManager.divider),
        ),
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
          initiallyExpanded: phase.phaseNumber == 1,
          iconColor: primaryColor,
          collapsedIconColor: ColorManager.textSecondary,
          title: Text(
            phase.phaseName,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Text(
              phase.description,
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 11.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  SizedBox(height: 4.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.restaurant_rounded, size: 13.sp, color: ColorManager.accent),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'Nutrition: ${phase.nutritionFocus}',
                          style: TextStyle(
                            color: ColorManager.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Weeks in this phase (${phase.weeks.length}):',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  ...phase.weeks.map((w) => Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: ColorManager.surfaceDark,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Week ${w.weekNumber}:',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  w.focus,
                                  style: TextStyle(
                                    color: ColorManager.textSecondary,
                                    fontSize: 11.sp,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildMilestonesCard(TransformationPlanBlueprint plan, Color primaryColor) {
    final milestones = TransformationPlansData.createDefaultMilestones(plan);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        children: milestones.map((m) {
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Day ${m.triggerDay}',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title,
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        m.description,
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 11.sp,
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
    );
  }
}
