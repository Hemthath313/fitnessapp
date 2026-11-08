import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_equipment_adapter.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/milestone_celebration_dialog.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/transformation_daily_checklist.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/transformation_reschedule_dialog.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/transformation_weekly_schedule_card.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';

/// Screen displaying the complete personalized transformation roadmap,
/// daily workout schedule, rest/recovery assignments, nutrition targets, and milestone unlocks.
class TransformationRoadmapScreen extends StatefulWidget {
  const TransformationRoadmapScreen({super.key});

  @override
  State<TransformationRoadmapScreen> createState() =>
      _TransformationRoadmapScreenState();
}

class _TransformationRoadmapScreenState
    extends State<TransformationRoadmapScreen> {
  int _selectedPhaseIndex = 0;
  bool _isChecklistExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'Transformation Roadmap',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 18.sp,
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
        actions: [
          IconButton(
            key: const Key('roadmap_progress_action_button'),
            tooltip: 'Progress Dashboard',
            icon: Icon(
              Icons.query_stats_rounded,
              color: ColorManager.primary,
              size: 22.sp,
            ),
            onPressed: () => context.push(Routes.transformationProgressRoute),
          ),
          IconButton(
            tooltip: 'All Programmes',
            icon: Icon(
              Icons.dashboard_rounded,
              color: ColorManager.textPrimary,
              size: 20.sp,
            ),
            onPressed: () => context.push(Routes.transformationPlansRoute),
          ),
        ],
      ),
      body: Consumer<TransformationProvider>(
        builder: (context, provider, _) {
          final activeState = provider.activeTransformation;

          if (activeState == null || !activeState.isActive) {
            return _buildNoActivePlanState(context);
          }

          // Check for uncelebrated milestones
          final uncelebrated = provider.uncelebratedMilestones;
          if (uncelebrated.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final m = uncelebrated.first;
                MilestoneCelebrationDialog.show(
                  context,
                  milestone: m,
                  onDismiss: () => provider.markMilestoneCelebrated(m.id),
                );
              }
            });
          }

          final blueprint = provider.activeBlueprint ??
              TransformationPlansData.getById(activeState.planId) ??
              TransformationPlansData.weightLoss60;

          Color primaryColor;
          try {
            final hex = blueprint.gradientColorHex.replaceFirst('0x', '');
            primaryColor = Color(int.parse(hex, radix: 16));
          } catch (_) {
            primaryColor = ColorManager.primary;
          }

          final phases = blueprint.phases;
          if (_selectedPhaseIndex >= phases.length) {
            _selectedPhaseIndex = 0;
          }
          final currentPhase = phases[_selectedPhaseIndex];

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            children: [
              // 0. Programme Completed Banner (when 100% finished)
              if (activeState.completionPercentage >= 1.0) ...[
                _buildCompletionReadyBanner(context, provider, activeState, primaryColor),
                SizedBox(height: 14.h),
              ],

              // 1. Programme Header Card with Live Progress
              _buildProgressHeader(activeState, blueprint, primaryColor),
              SizedBox(height: 14.h),

              // Beginner Orientation Banner (if beginner programme)
              if (blueprint.id == 'beginner_fitness_30') ...[
                _buildBeginnerOrientationBanner(primaryColor),
                SizedBox(height: 14.h),
              ],

              // Weight Loss Orientation Banner (if weight loss programme)
              if (blueprint.id == 'weight_loss_60') ...[
                _buildWeightLossOrientationBanner(primaryColor),
                SizedBox(height: 14.h),
              ],

              // Muscle Gain Orientation Banner (if muscle building programme)
              if (blueprint.id == 'muscle_building_90') ...[
                _buildMuscleGainOrientationBanner(primaryColor),
                SizedBox(height: 14.h),
              ],

              // Strength Building Orientation Banner (if strength programme)
              if (blueprint.id == 'strength_12_week') ...[
                _buildStrengthOrientationBanner(primaryColor),
                SizedBox(height: 14.h),
              ],

              // Weekly Check-In Shortcut Banner
              _buildWeeklyCheckInBanner(context, activeState, primaryColor),
              SizedBox(height: 14.h),

              // 2. Calibrated Nutrition Targets Bar
              _buildNutritionTargetsBar(context, activeState, primaryColor),
              SizedBox(height: 16.h),

              // Six-Pack Educational Companion Card (for weight loss programme)
              if (blueprint.id == 'weight_loss_60') ...[
                _buildSixPackEducationCard(context, primaryColor),
                SizedBox(height: 16.h),
              ],

              // Progressive Overload Advisory Card (for muscle building programme)
              if (blueprint.id == 'muscle_building_90') ...[
                _buildProgressiveOverloadAdvisoryCard(context, primaryColor),
                SizedBox(height: 16.h),
              ],

              // Strength Intelligence Advisory Card (for strength programme)
              if (blueprint.id == 'strength_12_week') ...[
                _buildStrengthIntelligenceAdvisoryCard(context, primaryColor),
                SizedBox(height: 16.h),
              ],

              // 3. Milestones Checkpoint Card
              _buildMilestonesBar(activeState, primaryColor),
              SizedBox(height: 16.h),

              // 4. Phase Switcher Tabs
              _buildPhaseTabs(phases, primaryColor),
              SizedBox(height: 12.h),

              // 5. Phase Info Banner
              _buildPhaseInfoBanner(currentPhase, primaryColor),
              SizedBox(height: 14.h),

              // 6. Days Schedule for Current Phase
              ..._buildPhaseDaysList(
                context,
                provider,
                activeState,
                blueprint,
                currentPhase,
                primaryColor,
              ),
              SizedBox(height: 16.h),

              // Weekly Scheduling Breakdown & Advisory Insights
              const TransformationWeeklyScheduleCard(),
              SizedBox(height: 16.h),

              // Daily Accountability Checklist
              _buildChecklistSection(provider, primaryColor),

              SizedBox(height: 30.h),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoActivePlanState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 54.sp, color: ColorManager.textTertiary),
            SizedBox(height: 16.h),
            Text(
              'No Active Programme',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'You are not currently enrolled in a transformation challenge. Explore available programmes and begin your journey.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () => context.push(Routes.transformationPlansRoute),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: const Text('Explore Transformation Plans', style: TextStyle(color: ColorManager.onMint, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeginnerOrientationBanner(Color primaryColor) {
    return Container(
      key: const Key('beginner_roadmap_orientation_banner'),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.spa_rounded, color: primaryColor, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Beginner Rule: Form beats weight. Rest 60–90s between sets, drink 2.5L water, and stay consistent!',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 11.sp,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightLossOrientationBanner(Color primaryColor) {
    return Container(
      key: const Key('weight_loss_roadmap_orientation_banner'),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded, color: primaryColor, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Fat Loss Rule: Sustainable energy deficit (~15–20%) + 2.0g protein/kg preserves muscle while stripping fat. Rest 45–60s on circuits & hydrate!',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 11.sp,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSixPackEducationCard(BuildContext context, Color primaryColor) {
    return Container(
      key: const Key('weight_loss_six_pack_companion_card'),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
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
                child:  Text('⚡', style: TextStyle(fontSize: 14.sp)),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Core Training vs. Fat Loss Reality',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Abdominal exercises strengthen your core, but spot reduction is a myth. Visible abs are revealed through an overall caloric deficit and full-body conditioning.',
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 11.sp,
              height: 1.35,
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('roadmap_six_pack_challenge_btn'),
              onPressed: () => context.push(Routes.sixPackChallengeRoute),
              icon: Icon(Icons.flash_on_rounded, size: 16.sp, color: primaryColor),
              label: Text(
                'Explore 30-Day Six-Pack Challenge',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleGainOrientationBanner(Color primaryColor) {
    return Container(
      key: const Key('muscle_gain_roadmap_orientation_banner'),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: primaryColor, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Hypertrophy Rule: Progressive Overload + 10–15% Clean Surplus + ~2.0g protein/kg. Add reps within target bracket before adding weight!',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 11.sp,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressiveOverloadAdvisoryCard(BuildContext context, Color primaryColor) {
    return Container(
      key: const Key('muscle_gain_progressive_overload_card'),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
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
                child:  Text('⚡', style: TextStyle(fontSize: 14.sp)),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Hypertrophy Engine: Progressive Overload & 1RM',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Muscles only grow when progressively challenged over time. The app remembers your logged weights and reps. Strive to add 1–2 reps within your target rep bracket before increasing load by +1.25–2.5 kg. Deload on Weeks 4 and 8 to shed systemic fatigue.',
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 11.sp,
              height: 1.35,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('roadmap_strength_analytics_btn'),
                  onPressed: () => context.push(Routes.strengthAnalyticsRoute),
                  icon: Icon(Icons.analytics_rounded, size: 14.sp, color: primaryColor),
                  label: Text(
                    'Strength Analytics',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('roadmap_bulking_diet_btn'),
                  onPressed: () => context.push(Routes.bulkingDietRoute),
                  icon: Icon(Icons.restaurant_menu_rounded, size: 14.sp, color: primaryColor),
                  label: Text(
                    'Bulking Diet',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
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

  Widget _buildStrengthOrientationBanner(Color primaryColor) {
    return Container(
      key: const Key('strength_roadmap_orientation_banner'),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: primaryColor, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Strength Rule: Compound Mastery + 2–3 min Rest + Progressive Overload. Log every set accurately; Gym Buddy estimates your 1RM curves!',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 11.sp,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthIntelligenceAdvisoryCard(BuildContext context, Color primaryColor) {
    return Container(
      key: const Key('strength_intelligence_advisory_card'),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
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
                child:  Text('🏆', style: TextStyle(fontSize: 14.sp)),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Strength Engine: 1RM Analytics & PR Vault',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Track your compound lift progression across Squat, Bench, Deadlift, and Military Press. The app monitors your estimated 1RM, identifies all-time Personal Records (PRs), and remembers previous session weights.',
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 11.sp,
              height: 1.35,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('roadmap_pr_vault_btn'),
                  onPressed: () => context.push(Routes.strengthAnalyticsRoute),
                  icon: Icon(Icons.analytics_rounded, size: 14.sp, color: primaryColor),
                  label: Text(
                    'PR Vault & 1RM',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('roadmap_strength_history_btn'),
                  onPressed: () => context.push(Routes.workoutHistoryRoute),
                  icon: Icon(Icons.history_rounded, size: 14.sp, color: primaryColor),
                  label: Text(
                    'Workout History',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
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

  Widget _buildProgressHeader(
    UserTransformationState state,
    TransformationPlanBlueprint plan,
    Color primaryColor,
  ) {
    final pct = (state.completionPercentage * 100).toInt();

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(plan.iconEmoji, style: TextStyle(fontSize: 12.sp)),
                    SizedBox(width: 5.w),
                    Text(
                      'ACTIVE ROADMAP',
                      style: TextStyle(
                        color: primaryColor,
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
                  color: primaryColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          Text(
            state.planTitle,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day ${state.currentDay} of ${state.totalDays}',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  '$pct% Completed (${state.completedDayIndices.length} done)',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: state.completionPercentage,
              minHeight: 8.h,
              backgroundColor: ColorManager.surfaceDark,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionReadyBanner(
    BuildContext context,
    TransformationProvider provider,
    UserTransformationState state,
    Color primaryColor,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorManager.success),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: ColorManager.success, size: 24),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Programme Days Completed! 🏆',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Tap below to finalize your transformation and view your official results summary.',
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
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('finalize_and_view_results_button'),
              onPressed: () async {
                await provider.completePlan();
                if (context.mounted) {
                  context.push(
                    Routes.transformationCompletionRoute,
                    extra: state.copyWith(status: 'completed', completedAt: DateTime.now()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.success,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: const Text('Complete & View Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistSection(TransformationProvider provider, Color primaryColor) {
    return Column(
      children: [
        InkWell(
          key: const Key('toggle_roadmap_checklist_button'),
          onTap: () => setState(() => _isChecklistExpanded = !_isChecklistExpanded),
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: ColorManager.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.checklist_rounded, color: primaryColor, size: 18.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Daily Accountability Checklist',
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isChecklistExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: ColorManager.textSecondary,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
        if (_isChecklistExpanded) ...[
          SizedBox(height: 10.h),
          const TransformationDailyChecklist(),
        ],
      ],
    );
  }

  Widget _buildWeeklyCheckInBanner(
    BuildContext context,
    UserTransformationState state,
    Color primaryColor,
  ) {
    final currentWeek = state.currentWeekNumber;
    final hasCheckedIn = state.weeklyCheckIns.any((c) => c.weekNumber == currentWeek);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                hasCheckedIn ? Icons.task_alt_rounded : Icons.pending_actions_rounded,
                color: hasCheckedIn ? ColorManager.success : ColorManager.accent,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Week $currentWeek Check-In',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    hasCheckedIn ? 'Logged for this week' : 'Due this week',
                    style: TextStyle(
                      color: hasCheckedIn ? ColorManager.success : ColorManager.textTertiary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          TextButton(
            key: const Key('roadmap_weekly_check_in_button'),
            onPressed: () => context.push(
              Routes.transformationCheckInRoute,
              extra: currentWeek,
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            ),
            child: Text(
              hasCheckedIn ? 'Edit' : 'Log Now',
              style: TextStyle(
                color: primaryColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTargetsBar(
    BuildContext context,
    UserTransformationState state,
    Color primaryColor,
  ) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.restaurant_rounded, color: ColorManager.accent, size: 16.sp),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        'Daily Nutrition Target',
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => context.push(
                  state.planId == 'muscle_building_90'
                      ? Routes.bulkingDietRoute
                      : Routes.dietRoute,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Row(
                    children: [
                      Text(
                        state.planId == 'muscle_building_90'
                            ? 'Bulking Diet'
                            : (state.planId == 'strength_12_week' ? 'Strength Fuel' : 'Diet Plans'),
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: primaryColor, size: 14.sp),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNutritionStat(state.targetCalories.toStringAsFixed(0), 'Calories', ColorManager.textPrimary),
              _buildNutritionStat('${state.targetMacros['protein']?.toStringAsFixed(0)}g', 'Protein', ColorManager.accent),
              _buildNutritionStat('${state.targetMacros['carbs']?.toStringAsFixed(0)}g', 'Carbs', primaryColor),
              _buildNutritionStat('${state.targetMacros['fat']?.toStringAsFixed(0)}g', 'Fats', ColorManager.warning),
            ],
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('view_daily_meal_plan_button'),
              onPressed: () => context.push(
                Routes.transformationNutritionRoute,
                extra: state.currentDay,
              ),
              icon: const Icon(Icons.menu_book_rounded, size: 16, color: Colors.white),
              label: Text(
                'View Daily Meal Plan & Recipes 🥗',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                elevation: 0,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('nutrition_bar_log_meal_btn'),
                  onPressed: () => context.push(Routes.newMealRoute),
                  icon: Icon(Icons.add_circle_outline_rounded, size: 14.sp, color: primaryColor),
                  label: Text('Log Meal', style: TextStyle(fontSize: 11.sp, color: primaryColor, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('nutrition_bar_log_water_btn'),
                  onPressed: () => context.push(Routes.addWaterRoute),
                  icon: Icon(Icons.water_drop_outlined, size: 14.sp, color: ColorManager.secondary),
                  label: Text('Log Water', style: TextStyle(fontSize: 11.sp, color: ColorManager.secondary, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ColorManager.secondary.withValues(alpha: 0.4)),
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 13.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 2.h),
        Text(label, style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp)),
      ],
    );
  }

  Widget _buildMilestonesBar(UserTransformationState state, Color primaryColor) {
    final pending = state.milestones.where((m) => !m.isAchieved).toList();
    final achieved = state.milestones.where((m) => m.isAchieved).toList();
    final nextMilestone = pending.isNotEmpty ? pending.first : null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: ColorManager.warning, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextMilestone != null
                      ? 'Next: ${nextMilestone.title} (Day ${nextMilestone.triggerDay})'
                      : 'All ${achieved.length} Programme Milestones Unlocked! 🏆',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${achieved.length} of ${state.milestones.length} milestones achieved',
                  style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseTabs(List<TransformationPhase> phases, Color primaryColor) {
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: phases.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final phase = phases[index];
          final isSelected = index == _selectedPhaseIndex;
          return InkWell(
            onTap: () => setState(() => _selectedPhaseIndex = index),
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : ColorManager.surface,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: isSelected ? primaryColor : ColorManager.divider,
                ),
              ),
              child: Text(
                'Phase ${phase.phaseNumber}',
                style: TextStyle(
                  color: isSelected ? Colors.white : ColorManager.textPrimary,
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhaseInfoBanner(TransformationPhase phase, Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            phase.phaseName,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            phase.description,
            style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp, height: 1.3),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPhaseDaysList(
    BuildContext context,
    TransformationProvider provider,
    UserTransformationState state,
    TransformationPlanBlueprint plan,
    TransformationPhase phase,
    Color primaryColor,
  ) {
    final widgets = <Widget>[];

    // Compute base day offset for the current phase
    int baseDayOffset = 0;
    for (int i = 0; i < phase.phaseNumber - 1; i++) {
      if (i < plan.phases.length) {
        for (final w in plan.phases[i].weeks) {
          baseDayOffset += w.days.length;
        }
      }
    }

    int dayCounter = baseDayOffset;

    for (final week in phase.weeks) {
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Week ${week.weekNumber}: ${week.focus}',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

      for (final day in week.days) {
        dayCounter++;
        final dayNum = dayCounter;
        if (dayNum > plan.durationDays) continue;
        final isCompleted = state.completedDayIndices.contains(dayNum);
        final isToday = dayNum == state.currentDay;

        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _buildDayCard(
              context: context,
              provider: provider,
              day: day,
              dayNumber: dayNum,
              isCompleted: isCompleted,
              isToday: isToday,
              primaryColor: primaryColor,
              planTitle: plan.title,
              planId: plan.id,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildDayCard({
    required BuildContext context,
    required TransformationProvider provider,
    required TransformationDayBlueprint day,
    required int dayNumber,
    required bool isCompleted,
    required bool isToday,
    required Color primaryColor,
    required String planTitle,
    required String planId,
  }) {
    final state = provider.activeTransformation;
    final scheduledDate = state?.getScheduledDateForDay(dayNumber) ?? DateTime.now();
    final originalDate = state?.getOriginalDateForDay(dayNumber) ?? scheduledDate;
    final isRescheduled = state?.isDayRescheduled(dayNumber) ?? false;
    final isSkipped = state?.isDaySkipped(dayNumber) ?? false;

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final schedMidnight = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
    final effectiveIsToday = schedMidnight == todayMidnight;
    final isMissed = !isCompleted && !isSkipped && !day.isRestDay && schedMidnight.isBefore(todayMidnight);

    String statusLabel;
    Color statusColor;
    if (isCompleted) {
      statusLabel = 'Completed';
      statusColor = ColorManager.success;
    } else if (isSkipped) {
      statusLabel = 'Skipped';
      statusColor = ColorManager.accent;
    } else if (effectiveIsToday) {
      statusLabel = 'Today';
      statusColor = primaryColor;
    } else if (isRescheduled) {
      statusLabel = 'Rescheduled';
      statusColor = ColorManager.secondary;
    } else if (isMissed) {
      statusLabel = 'Missed';
      statusColor = Colors.orange;
    } else if (day.isRestDay) {
      statusLabel = 'Rest Day';
      statusColor = ColorManager.textSecondary;
    } else {
      statusLabel = 'Scheduled';
      statusColor = ColorManager.textTertiary;
    }

    Color cardBorder = effectiveIsToday
        ? primaryColor
        : (isCompleted ? ColorManager.success.withValues(alpha: 0.6) : ColorManager.divider);

    return Container(
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder, width: effectiveIsToday ? 1.5 : 1.0),
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: effectiveIsToday
                            ? primaryColor.withValues(alpha: 0.15)
                            : (isCompleted
                                ? ColorManager.success.withValues(alpha: 0.15)
                                : ColorManager.surfaceDark),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Day $dayNumber',
                        style: TextStyle(
                          color: effectiveIsToday
                              ? primaryColor
                              : (isCompleted ? ColorManager.success : ColorManager.textSecondary),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        day.isRestDay ? 'Rest & Recovery' : (day.muscleGroup ?? 'Workout'),
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reschedule action for eligible incomplete workout days
                  if (!isCompleted && !day.isRestDay && state != null) ...[
                    IconButton(
                      key: Key('reschedule_day_${dayNumber}_button'),
                      icon: Icon(
                        Icons.edit_calendar_rounded,
                        color: isRescheduled ? ColorManager.secondary : ColorManager.textSecondary,
                        size: 20.sp,
                      ),
                      tooltip: 'Reschedule Workout',
                      onPressed: () => TransformationRescheduleDialog.show(
                        context,
                        dayNumber: dayNumber,
                        dayName: day.muscleGroup ?? 'Workout',
                        provider: provider,
                        state: state,
                      ),
                    ),
                  ],
                  // Checkbox Toggle
                  IconButton(
                    key: Key('toggle_day_${dayNumber}_button'),
                    icon: Icon(
                      isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isCompleted ? ColorManager.success : ColorManager.textTertiary,
                      size: 22.sp,
                    ),
                    onPressed: () => provider.toggleDayCompletion(dayNumber),
                    tooltip: isCompleted ? 'Mark Incomplete' : 'Mark Completed',
                  ),
                ],
              ),
            ],
          ),

          // Date and Flexible Scheduling Status Subheader
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isRescheduled
                      ? 'Original: ${DateFormat('MMM d').format(originalDate)} • Scheduled: ${DateFormat('MMM d').format(scheduledDate)}'
                      : DateFormat('EEE, MMM d').format(scheduledDate),
                  style: TextStyle(
                    color: isRescheduled ? ColorManager.secondary : ColorManager.textSecondary,
                    fontSize: 11.sp,
                    fontWeight: isRescheduled ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          if (day.notes != null) ...[
            SizedBox(height: 4.h),
            Text(
              day.notes!,
              style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
            ),
          ],

          // Exercises List preview if workout day
          if (!day.isRestDay && day.exerciseNames.isNotEmpty) ...[
            Builder(
              builder: (context) {
                final activeState = provider.activeTransformation;
                final adaptedExercises = TransformationEquipmentAdapter.adaptExercisesForEnvironment(
                  exerciseNames: day.exerciseNames,
                  workoutLocation: activeState?.workoutLocation,
                  availableEquipment: activeState?.availableEquipment ?? const [],
                  injuries: activeState?.injuries,
                );
                final isAdapted = adaptedExercises.join(',') != day.exerciseNames.join(',');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: adaptedExercises.map((name) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: ColorManager.surfaceDark,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            '🔥 Warm-up (5-10m)',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: ColorManager.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            '🧘 Cooldown (5m)',
                            style: TextStyle(
                              color: ColorManager.secondary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isAdapted) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: ColorManager.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              '🏠 Home Adapted',
                              style: TextStyle(
                                color: ColorManager.success,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                );
              },
            ),
          ],

          SizedBox(height: 10.h),

          // Launch Workout CTA if workout day
          if (!day.isRestDay) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: Key('start_workout_day_$dayNumber'),
                onPressed: () => _launchDayWorkout(
                  context: context,
                  day: day,
                  dayNumber: dayNumber,
                  planTitle: planTitle,
                  planId: planId,
                  provider: provider,
                ),
                icon: Icon(
                  isCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded,
                  size: 16.sp,
                  color: Colors.white,
                ),
                label: Text(
                  isCompleted ? 'Repeat Workout' : 'Start Day $dayNumber Workout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? ColorManager.textTertiary : primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _launchDayWorkout({
    required BuildContext context,
    required TransformationDayBlueprint day,
    required int dayNumber,
    required String planTitle,
    required String planId,
    required TransformationProvider provider,
  }) {
    final activeState = provider.activeTransformation;
    final adaptedExerciseNames = TransformationEquipmentAdapter.adaptExercisesForEnvironment(
      exerciseNames: day.exerciseNames,
      workoutLocation: activeState?.workoutLocation,
      availableEquipment: activeState?.availableEquipment ?? const [],
      injuries: activeState?.injuries,
    );

    // Resolve exercises from ExerciseData catalog
    final resolvedExercises = <dynamic>[];

    for (final name in adaptedExerciseNames) {
      final catalogEx = ExerciseData.findByName(name);
      if (catalogEx != null) {
        resolvedExercises.add(catalogEx);
      } else {
        // Fallback map format compatible with DayWorkoutSessionPage
        resolvedExercises.add({
          'name': name,
          'setNumber': day.targetSets,
          'repNumber': 10,
        });
      }
    }

    // Launch canonical Gym Buddy workout session
    final isPremium =
        Provider.of<SubscriptionProvider?>(context, listen: false)?.isPremium ??
            false;
    if (!isPremium) {
      context.push(Routes.premiumScreen);
      return;
    }

    context.push(
      Routes.dayWorkoutSessionRoute,
      extra: {
        'dayName': '$planTitle • Day $dayNumber',
        'workouts': resolvedExercises,
        'planId': planId,
        'planDay': dayNumber,
      },
    );
  }
}
