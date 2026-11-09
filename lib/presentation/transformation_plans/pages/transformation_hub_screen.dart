import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
import 'package:fitness_app/presentation/home/widgets/gradient_hero_card.dart';
import 'package:fitness_app/presentation/home/widgets/mini_challenge_cards.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/utils/managers/card_size_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';

/// All available Transformation Programmes: image cards with a title, two
/// facts and one button. Detail (description, structure, highlights) lives on
/// the programme detail screen.
class TransformationHubScreen extends StatelessWidget {
  const TransformationHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryPlans = TransformationPlansData.primaryPlans;
    final specialisedPlans = TransformationPlansData.specialisedPlans;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'Transformation Plans',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: AppText.appBarTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorManager.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(tooltip: 'Back', 
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

          bool isActivePlan(TransformationPlanBlueprint plan) =>
              activeState != null &&
              activeState.isActive &&
              activeState.planId == plan.id;

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            children: [
              // Active enrolment summary (only when enrolled)
              if (activeState != null && activeState.isActive) ...[
                _buildActiveEnrolmentBanner(context, activeState),
                SizedBox(height: 18.h),
              ],

              _buildSectionTitle('Primary Programmes (${primaryPlans.length})'),
              SizedBox(height: 12.h),
              ...primaryPlans.map((plan) => Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: _buildProgrammeCard(
                      context,
                      plan,
                      isActivePlan(plan),
                      categoryBadge: _getBadge(plan),
                    ),
                  )),

              SizedBox(height: 8.h),
              _buildSectionTitle(
                  'Specialised Programmes (${specialisedPlans.length})'),
              SizedBox(height: 12.h),
              ...specialisedPlans.map((plan) => Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: _buildProgrammeCard(
                      context,
                      plan,
                      isActivePlan(plan),
                      categoryBadge: 'Strength Specialisation',
                      tone: HeroTone.purple,
                    ),
                  )),

              SizedBox(height: 8.h),
              _buildSectionTitle('Mini Challenges (2)'),
              SizedBox(height: 12.h),
              // Same cards as the dashboard shelf, so View All really lists
              // every challenge.
              SizedBox(
                height: CarouselHomeBox.heightOf(context),
                child: const SixPackChallengeCard(),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                height: CarouselHomeBox.heightOf(context),
                child: const ExerciseOfWeekCard(),
              ),

              SizedBox(height: 20.h),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        color: ColorManager.textPrimary,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
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
                      fontSize: 11.sp,
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

  HeroTone _toneFor(TransformationPlanBlueprint plan) {
    switch (plan.id) {
      case 'beginner_fitness_30':
        return HeroTone.green;
      case 'weight_loss_60':
        return HeroTone.coral;
      case 'muscle_building_90':
        return HeroTone.teal;
      default:
        return HeroTone.purple;
    }
  }

  Widget _buildProgrammeCard(
    BuildContext context,
    TransformationPlanBlueprint plan,
    bool isCurrentActive, {
    String? categoryBadge,
    HeroTone? tone,
  }) {
    final key = HeroImages.keyForPlan(plan.id);

    return GradientHeroCard(
      key: Key('programme_card_${plan.id}'),
      tone: tone ?? _toneFor(plan),
      imageAsset: HeroImages.forKey(key),
      photoAsset: HeroImages.photoForPlan(plan.id),
      imageSize: AppCardSize.heroImageSize,
      imageTop: AppCardSize.heroImageTop,
      padding: EdgeInsets.all(AppCardSize.heroPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (categoryBadge != null)
                Flexible(
                  child: HeroBadge(
                    text: categoryBadge.toUpperCase(),
                    icon: Icons.bolt_rounded,
                  ),
                ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
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
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrentActive) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: ColorManager.success,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: ColorManager.onMint,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.only(right: GradientHeroCard.textInset),
            child: Text(
              plan.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                height: 1.2,
                fontWeight: FontWeight.bold,
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
                text: '${plan.durationDays} Days',
              ),
              HeroMetaChip(
                icon: Icons.trending_up_rounded,
                text: _getObjective(plan),
              ),
            ],
          ),
          SizedBox(height: 16.h),
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
                isCurrentActive
                    ? Icons.map_rounded
                    : Icons.arrow_forward_rounded,
                size: 16.sp,
                color: ColorManager.onMint,
              ),
              label: Text(
                isCurrentActive ? 'View Active Roadmap' : 'Explore Programme',
                style: TextStyle(
                  color: ColorManager.onMint,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 13.h),
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
