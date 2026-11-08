import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';

/// Screen displaying all available Transformation Programmes
/// categorized into Primary Programmes and Specialised Programmes,
/// with curriculum overviews, personalized beginner recommendations, and active enrolment tracking.
class TransformationHubScreen extends StatelessWidget {
  const TransformationHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryPlans = TransformationPlansData.primaryPlans;
    final specialisedPlans = TransformationPlansData.specialisedPlans;
    final homeProvider = Provider.of<HomeProvider?>(context);

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'Transformation Plans',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorManager.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorManager.textPrimary,
            size: 18.sp,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<TransformationProvider>(
        builder: (context, provider, _) {
          final activeState = provider.activeTransformation;

          final activity = (homeProvider?.userData['activity'] ?? '').toString();
          final isBeginner = activity.toUpperCase().contains('SEDENTARY') ||
              activity.toUpperCase().contains('LIGHT') ||
              (provider.history.isEmpty && !provider.hasActiveTransformation);

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            children: [
              // 1. Top Header Banner
              _buildIntroBanner(),
              SizedBox(height: 16.h),

              // 2. Active Enrolment Card (if enrolled)
              if (activeState != null && activeState.isActive) ...[
                _buildActiveEnrolmentBanner(context, activeState),
                SizedBox(height: 18.h),
              ],

              // 3. Personalized Beginner Recommendation Callout (if suitable & not enrolled)
              if (isBeginner && (activeState == null || !activeState.isActive)) ...[
                _buildBeginnerRecommendationBanner(context),
                SizedBox(height: 18.h),
              ],

              // 4. Primary Programmes Section Title
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: ColorManager.primary,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Primary Programmes (${primaryPlans.length})',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'Complete structured coaching curriculums for every experience level',
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(height: 12.h),

              // 5. Primary Programme Cards List
              ...primaryPlans.map((plan) {
                final isCurrentActive = activeState != null &&
                    activeState.isActive &&
                    activeState.planId == plan.id;
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: _buildProgrammeCard(
                    context,
                    plan,
                    isCurrentActive,
                    categoryBadge: _getBadge(plan),
                  ),
                );
              }),

              SizedBox(height: 10.h),

              // 6. Specialised Programmes Section Title
              Row(
                children: [
                  Icon(
                    Icons.military_tech_rounded,
                    color: const Color(0xFF9B51E0),
                    size: 18.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Specialised Programmes (${specialisedPlans.length})',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'Targeted advanced curriculums focusing on raw strength and powerlifting',
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(height: 12.h),

              // 7. Specialised Programme Cards List
              ...specialisedPlans.map((plan) {
                final isCurrentActive = activeState != null &&
                    activeState.isActive &&
                    activeState.planId == plan.id;
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: _buildProgrammeCard(
                    context,
                    plan,
                    isCurrentActive,
                    categoryBadge: 'Strength Specialisation',
                    badgeColor: const Color(0xFF9B51E0),
                  ),
                );
              }),

              SizedBox(height: 20.h),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: ColorManager.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_gymnastics_rounded,
              color: ColorManager.primary,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personalized Coaching Curriculums',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Multi-week periodized workouts, nutrition targets & milestones',
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
  }

  Widget _buildBeginnerRecommendationBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00B074).withValues(alpha: 0.16),
            ColorManager.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF00B074).withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: const Color(0xFF00B074).withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🌱', style: TextStyle(fontSize: 18)),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended for You: Complete Beginner',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Master movement fundamentals with manageable 25–35 min sessions and zero guesswork.',
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
  }

  Widget _buildActiveEnrolmentBanner(
    BuildContext context,
    UserTransformationState activeState,
  ) {
    final pct = (activeState.completionPercentage * 100).toInt();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorManager.primary.withValues(alpha: 0.2),
            ColorManager.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorManager.primary, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(
                      color: ColorManager.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'CURRENTLY ENROLLED',
                    style: TextStyle(
                      color: ColorManager.success,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                'Day ${activeState.currentDay} of ${activeState.totalDays}',
                style: TextStyle(
                  color: ColorManager.primary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            activeState.planTitle,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: activeState.completionPercentage,
              minHeight: 6.h,
              backgroundColor: ColorManager.surfaceDark,
              valueColor: const AlwaysStoppedAnimation<Color>(ColorManager.primary),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$pct% Completed',
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 11.sp,
                ),
              ),
              InkWell(
                onTap: () {
                  context.push(
                    '${Routes.transformationPlanDetailRoute}?planId=${activeState.planId}',
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  child: Row(
                    children: [
                      Text(
                        'View Roadmap',
                        style: TextStyle(
                          color: ColorManager.primary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: ColorManager.primary,
                        size: 16.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgrammeCard(
    BuildContext context,
    TransformationPlanBlueprint plan,
    bool isCurrentActive, {
    String? categoryBadge,
    Color? badgeColor,
  }) {
    Color primaryColor;
    try {
      final hex = plan.gradientColorHex.replaceFirst('0x', '');
      primaryColor = Color(int.parse(hex, radix: 16));
    } catch (_) {
      primaryColor = ColorManager.primary;
    }

    final accentBadgeColor = badgeColor ?? primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isCurrentActive ? primaryColor : ColorManager.divider,
          width: isCurrentActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner with gradient
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.22),
                  primaryColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      plan.iconEmoji,
                      style: TextStyle(fontSize: 22.sp),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCurrentActive || categoryBadge != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (categoryBadge != null) ...[
                                    Flexible(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.w, vertical: 2.5.h),
                                        decoration: BoxDecoration(
                                          color: accentBadgeColor
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6.r),
                                          border: Border.all(
                                            color: accentBadgeColor
                                                .withValues(alpha: 0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          categoryBadge,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: accentBadgeColor,
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                  ],
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade700
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: Colors.amber.shade700
                                            .withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.workspace_premium_rounded,
                                            color: Colors.amber.shade700,
                                            size: 10.sp),
                                        SizedBox(width: 3.w),
                                        Text(
                                          'PRO',
                                          style: TextStyle(
                                            color: Colors.amber.shade700,
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrentActive)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 2.5.h),
                                decoration: BoxDecoration(
                                  color: ColorManager.success,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                      ],
                      Text(
                        plan.title,
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        plan.subtitle,
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 11.sp,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick info chips
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    _buildInfoChip('${plan.durationDays} Days', Icons.calendar_today_rounded),
                    _buildInfoChip(plan.difficulty, Icons.fitness_center_rounded),
                    _buildInfoChip(_getFrequency(plan), Icons.schedule_rounded),
                    _buildInfoChip(_getObjective(plan), Icons.trending_up_rounded),
                    _buildInfoChip('${plan.phases.length} Phases', Icons.layers_rounded),
                  ],
                ),
                SizedBox(height: 12.h),

                // Highlights bullets
                ...plan.highlights.take(3).map((h) => Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: primaryColor,
                            size: 14.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              h,
                              style: TextStyle(
                                color: ColorManager.textSecondary,
                                fontSize: 11.sp,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                SizedBox(height: 14.h),

                // Explore CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push(
                        '${Routes.transformationPlanDetailRoute}?planId=${plan.id}',
                        extra: plan,
                      );
                    },
                    icon: Icon(
                      isCurrentActive ? Icons.map_rounded : Icons.arrow_forward_rounded,
                      size: 15.sp,
                      color: Colors.white,
                    ),
                    label: Text(
                      isCurrentActive ? 'View Active Roadmap' : 'Explore Programme Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.sp, color: ColorManager.textSecondary),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getFrequency(TransformationPlanBlueprint plan) {
    switch (plan.id) {
      case 'beginner_fitness_30':
        return '3 Days/Wk';
      case 'weight_loss_60':
      case 'muscle_building_90':
        return '4-5 Days/Wk';
      case 'strength_12_week':
        return '4 Days/Wk';
      default:
        return '3-4 Days/Wk';
    }
  }

  String _getObjective(TransformationPlanBlueprint plan) {
    switch (plan.id) {
      case 'beginner_fitness_30':
        return 'Habits & Form';
      case 'weight_loss_60':
        return 'Fat Loss';
      case 'muscle_building_90':
        return 'Hypertrophy';
      case 'strength_12_week':
        return 'Strength & 1RM';
      default:
        return 'Fitness';
    }
  }

  String _getBadge(TransformationPlanBlueprint plan) {
    switch (plan.id) {
      case 'beginner_fitness_30':
        return 'Recommended for New Users';
      case 'weight_loss_60':
        return 'Popular Fat Loss';
      case 'muscle_building_90':
        return 'Flagship Hypertrophy';
      default:
        return 'Featured';
    }
  }
}
