import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_strength_analytics.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';

/// Screen displayed when a transformation programme is completed, celebrating
/// all actual recorded progress, weight changes, measurements, and milestones.
class TransformationCompletionScreen extends StatelessWidget {
  final UserTransformationState? completedState;

  const TransformationCompletionScreen({
    super.key,
    this.completedState,
  });

  @override
  Widget build(BuildContext context) {
    final transformationProvider =
        Provider.of<TransformationProvider?>(context);
    final homeProvider = Provider.of<HomeProvider?>(context);

    // Resolve state: explicit argument, active (if completed), or newest in history
    final state = completedState ??
        (transformationProvider?.activeTransformation?.isCompleted == true
            ? transformationProvider?.activeTransformation
            : (transformationProvider?.history.isNotEmpty == true
                ? transformationProvider?.history.first
                : transformationProvider?.activeTransformation));

    if (state == null) {
      return Scaffold(
        backgroundColor: ColorManager.background,
        appBar: AppBar(title: const Text('Programme Completion')),
        body: const Center(child: Text('No transformation record found.')),
      );
    }

    final blueprint = TransformationPlansData.getById(state.planId) ??
        TransformationPlansData.weightLoss60;

    final completedDate = state.completedAt ?? DateTime.now();
    final dateStr = DateFormat('MMMM d, yyyy').format(completedDate);

    // Actual recorded weights
    final startingWeight = state.startingWeight;
    final finalWeight =
        (homeProvider?.userData['weight'] as num?)?.toDouble() ??
            (state.weeklyCheckIns.isNotEmpty
                ? state.weeklyCheckIns.last.weight
                : null);

    final weightChange = (startingWeight != null && finalWeight != null)
        ? finalWeight - startingWeight
        : null;

    final completedWorkouts = state.completedDayIndices.length;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: const Text('Programme Completed'),
        backgroundColor: ColorManager.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          children: [
            // 1. Trophy & Celebration Hero
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: ColorManager.surface,
                borderRadius: BorderRadius.circular(AppRadius.card.r),
                border: Border.all(
                  color: ColorManager.success.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.success.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: ColorManager.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${blueprint.iconEmoji} 🏆',
                        style: TextStyle(fontSize: 32.sp),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: ColorManager.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'ACHIEVEMENT UNLOCKED',
                      style: TextStyle(
                        color: ColorManager.successText,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    state.planTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Completed on $dateStr • ${state.totalDays} Days Journey',
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // 2. Summary Metrics Card (actual recorded data only)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: ColorManager.surface,
                boxShadow: ColorManager.cardShadow,
                borderRadius: BorderRadius.circular(AppRadius.card.r),
                border: Border.all(color: ColorManager.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transformation Summary',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Workouts',
                          value: '$completedWorkouts',
                          subtext: 'Completed',
                          icon: Icons.fitness_center_rounded,
                        ),
                      ),
                      if (startingWeight != null) ...[
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Start Weight',
                            value: '${startingWeight.toStringAsFixed(1)} kg',
                            subtext: 'Day 1',
                            icon: Icons.monitor_weight_outlined,
                          ),
                        ),
                      ],
                      if (finalWeight != null) ...[
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Final Weight',
                            value: '${finalWeight.toStringAsFixed(1)} kg',
                            subtext: 'Completed',
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ),
                      ],
                      if (weightChange != null) ...[
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Net Change',
                            value:
                                '${weightChange > 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg',
                            subtext: weightChange <= 0 ? 'Lost' : 'Gained',
                            icon: Icons.trending_down_rounded,
                            color: weightChange <= 0
                                ? ColorManager.success
                                : ColorManager.accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // 3. Body Measurements Comparison (if available)
            if (state.startingMeasurements.isNotEmpty) ...[
              _buildMeasurementsSummary(context, state, homeProvider),
              SizedBox(height: 20.h),
            ],

            // 4. Milestones Achieved Badges
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ColorManager.surface,
                boxShadow: ColorManager.cardShadow,
                borderRadius: BorderRadius.circular(AppRadius.tile.r),
                border: Border.all(color: ColorManager.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Milestones Earned (${state.milestones.length})',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: state.milestones.map((m) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: ColorManager.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: ColorManager.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.military_tech_rounded,
                              color: ColorManager.warningText,
                              size: 16,
                            ),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: Text(
                                m.title,
                                style: TextStyle(
                                  color: ColorManager.textPrimary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // 5a. Strength Achievements Section (Phase 9)
            _buildStrengthAchievementsCard(context, state),
            SizedBox(height: 20.h),

            // 5b. Graduation Pathway Recommendation (for 30-Day Complete Beginner)
            if (state.planId == 'beginner_fitness_30') ...[
              _buildBeginnerGraduationCard(context),
              SizedBox(height: 20.h),
            ],

            // 5c. Graduation Pathway Recommendation (for 60-Day Weight Loss)
            if (state.planId == 'weight_loss_60') ...[
              _buildWeightLossGraduationCard(context),
              SizedBox(height: 20.h),
            ],

            // 5d. Graduation Pathway Recommendation (for 90-Day Muscle Building)
            if (state.planId == 'muscle_building_90') ...[
              _buildMuscleBuildingGraduationCard(context),
              SizedBox(height: 20.h),
            ],

            // 5e. Graduation Pathway Recommendation (for 12-Week Strength Building)
            if (state.planId == 'strength_12_week') ...[
              _buildStrengthBuildingGraduationCard(context),
              SizedBox(height: 20.h),
            ],

            // 6. Action CTAs: Explore Another Challenge & Return to Dashboard
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('completion_explore_another_cta'),
                onPressed: () =>
                    context.pushReplacement(Routes.transformationPlansRoute),
                icon: const Icon(Icons.explore_rounded,
                    size: 18, color: ColorManager.onMint),
                label: Text(
                  'Explore Another Challenge',
                  style: TextStyle(
                    color: ColorManager.onMint,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const Key('completion_back_dashboard_cta'),
                onPressed: () => context.go(Routes.mainRoute),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorManager.textPrimary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: BorderSide(color: ColorManager.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button.r),
                  ),
                ),
                child: Text(
                  'Return to Dashboard',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? ColorManager.primaryText, size: 20.sp),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            color: color ?? ColorManager.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            color: ColorManager.textTertiary,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementsSummary(
    BuildContext context,
    UserTransformationState state,
    HomeProvider? homeProvider,
  ) {
    final userData = homeProvider?.userData ?? {};
    final starting = state.startingMeasurements;

    final parts = [
      {'name': 'Waist', 'key': 'waist'},
      {'name': 'Chest', 'key': 'chest'},
      {'name': 'Arms', 'key': 'biceps'},
      {'name': 'Hips', 'key': 'hips'},
      {'name': 'Thighs', 'key': 'thigh'},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body Measurement Evolution',
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                children: [
                  Text('Area',
                      style: TextStyle(
                          color: ColorManager.textTertiary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold)),
                  Text('Start',
                      style: TextStyle(
                          color: ColorManager.textTertiary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold)),
                  Text('Final',
                      style: TextStyle(
                          color: ColorManager.textTertiary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold)),
                  Text('Change',
                      style: TextStyle(
                          color: ColorManager.textTertiary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              ...parts.map((p) {
                final k = p['key']!;
                final startVal = starting[k];
                final currentVal = (userData[k] as num?)?.toDouble();
                final diff = (startVal != null && currentVal != null)
                    ? currentVal - startVal
                    : null;

                return TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(p['name']!,
                          style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontSize: 12.sp)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(startVal != null ? '$startVal cm' : '—',
                          style: TextStyle(
                              color: ColorManager.textSecondary,
                              fontSize: 12.sp)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(currentVal != null ? '$currentVal cm' : '—',
                          style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(
                        diff != null
                            ? '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}'
                            : '—',
                        style: TextStyle(
                          color: diff == null
                              ? ColorManager.textTertiary
                              : (diff <= 0
                                  ? ColorManager.success
                                  : ColorManager.warning),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBeginnerGraduationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(
          color: ColorManager.success.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorManager.success.withValues(alpha: 0.1),
            blurRadius: 16,
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
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ColorManager.success.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child:  Text('🎓', style: TextStyle(fontSize: 20.sp)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Graduate to Your Next Programme',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'You built consistency & form. Select your next path:',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Option 1: Muscle Building 90
          _buildGraduationOptionCard(
            context: context,
            title: '90-Day Muscle Building Challenge',
            subtitle: 'Pack on dense lean mass, increase size & progressive strength',
            tag: 'Goal: Build Muscle & Size',
            colorHex: '0xFF2F6BFF',
            planId: 'muscle_building_90',
            buttonKey: const Key('graduate_to_muscle_building_btn'),
          ),
          SizedBox(height: 12.h),

          // Option 2: Weight Loss 60
          _buildGraduationOptionCard(
            context: context,
            title: '60-Day Weight Loss Challenge',
            subtitle: 'Burn body fat, sculpt athletic definition & build conditioning',
            tag: 'Goal: Lose Body Fat',
            colorHex: '0xFFFF5E36',
            planId: 'weight_loss_60',
            buttonKey: const Key('graduate_to_weight_loss_btn'),
          ),
          SizedBox(height: 12.h),

          // Option 3: Strength Building 12-Week
          _buildGraduationOptionCard(
            context: context,
            title: '12-Week Strength Building Challenge',
            subtitle: 'Skyrocket your compound lifts and build dense tendon strength',
            tag: 'Goal: Raw Compound Strength',
            colorHex: '0xFF9B51E0',
            planId: 'strength_12_week',
            buttonKey: const Key('graduate_to_strength_btn'),
          ),
          SizedBox(height: 12.h),

          // Option 4: Continued General Fitness
          _buildGraduationOptionCard(
            context: context,
            title: 'Continued General Fitness',
            subtitle: 'Maintain your newly built habit with flexible custom splits & logging',
            tag: 'Goal: Active Lifestyle',
            colorHex: '0xFF00B074',
            planId: 'general_fitness',
            buttonKey: const Key('graduate_to_maintenance_btn'),
            actionLabel: 'Return to Dashboard',
            onActionPressed: () => context.go(Routes.mainRoute),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightLossGraduationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(
          color: ColorManager.accent.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorManager.accent.withValues(alpha: 0.1),
            blurRadius: 16,
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
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ColorManager.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child:  Text('🏆', style: TextStyle(fontSize: 20.sp)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Graduate to Your Next Chapter',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'You sculpted athletic definition! Select your next path:',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Option 1: Continue General Fitness & Maintenance
          _buildGraduationOptionCard(
            context: context,
            title: 'General Fitness & Lifestyle Maintenance',
            subtitle: 'Sustain your newly transformed physique with flexible splits and calorie balance',
            tag: 'Goal: Sustain Results',
            colorHex: '0xFF00B074',
            planId: 'general_fitness',
            buttonKey: const Key('graduate_wl_to_maintenance_btn'),
            actionLabel: 'Return to Dashboard',
            onActionPressed: () => context.go(Routes.mainRoute),
          ),
          SizedBox(height: 12.h),

          // Option 2: 90-Day Muscle Building Challenge
          _buildGraduationOptionCard(
            context: context,
            title: '90-Day Muscle Building Challenge',
            subtitle: 'Transition from fat loss to lean muscle hypertrophy with a slight caloric surplus',
            tag: 'Goal: Build Muscle & Size',
            colorHex: '0xFF2F6BFF',
            planId: 'muscle_building_90',
            buttonKey: const Key('graduate_wl_to_muscle_btn'),
          ),
          SizedBox(height: 12.h),

          // Option 3: 12-Week Strength Building Challenge
          _buildGraduationOptionCard(
            context: context,
            title: '12-Week Strength Building Challenge',
            subtitle: 'Skyrocket your compound lifts (Squat, Bench, Deadlift) and dense tendon power',
            tag: 'Goal: Raw Compound Strength',
            colorHex: '0xFF9B51E0',
            planId: 'strength_12_week',
            buttonKey: const Key('graduate_wl_to_strength_btn'),
          ),
          SizedBox(height: 12.h),

          // Option 4: Repeat 60-Day Weight Loss Cycle
          _buildGraduationOptionCard(
            context: context,
            title: 'Repeat 60-Day Weight Loss Challenge',
            subtitle: 'Take a 1–2 week maintenance break, then launch another focused fat loss wave',
            tag: 'Goal: Additional Fat Loss',
            colorHex: '0xFFFF5E36',
            planId: 'weight_loss_60',
            buttonKey: const Key('graduate_wl_to_repeat_btn'),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleBuildingGraduationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(
          color: ColorManager.info.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorManager.info.withValues(alpha: 0.1),
            blurRadius: 16,
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
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ColorManager.info.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child:  Text('⚡', style: TextStyle(fontSize: 20.sp)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Graduate to Your Next Chapter',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'You built impressive muscle mass and strength! Select your next path:',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Option 1: Continue Hypertrophy Progression (Repeat 90-Day Hypertrophy Cycle)
          _buildGraduationOptionCard(
            context: context,
            title: 'Repeat 90-Day Hypertrophy Cycle',
            subtitle: 'Take a 1-week deload, recalculate your maintenance calories, and target new muscle volume records',
            tag: 'Goal: Hypertrophy',
            colorHex: '0xFF2F6BFF',
            planId: 'muscle_building_90',
            buttonKey: const Key('graduate_mb_to_repeat_btn'),
          ),
          SizedBox(height: 12.h),

          // Option 2: 12-Week Strength Building Challenge
          _buildGraduationOptionCard(
            context: context,
            title: '12-Week Strength Building Challenge',
            subtitle: 'Convert your new muscle mass into maximal 1RM compound strength across Squat, Bench & Deadlift',
            tag: 'Goal: Raw Strength',
            colorHex: '0xFF9B51E0',
            planId: 'strength_12_week',
            buttonKey: const Key('graduate_mb_to_strength_btn'),
          ),
          SizedBox(height: 12.h),

          // Option 3: General Fitness & Muscle Maintenance
          _buildGraduationOptionCard(
            context: context,
            title: 'General Fitness & Muscle Maintenance',
            subtitle: 'Sustain your newly built muscle with flexible training splits at maintenance calories',
            tag: 'Goal: Retain & Maintain',
            colorHex: '0xFF00B074',
            planId: 'general_fitness',
            buttonKey: const Key('graduate_mb_to_maintenance_btn'),
            actionLabel: 'Return to Dashboard',
            onActionPressed: () => context.go(Routes.mainRoute),
          ),
          SizedBox(height: 12.h),

          // Option 4: 60-Day Fat Loss & Cutting Challenge
          _buildGraduationOptionCard(
            context: context,
            title: '60-Day Fat Loss & Cutting Challenge',
            subtitle: 'Strip body fat while preserving your new muscle mass to reveal peak vascular definition',
            tag: 'Goal: Cut & Definition',
            colorHex: '0xFFFF5E36',
            planId: 'weight_loss_60',
            buttonKey: const Key('graduate_mb_to_cut_btn'),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthBuildingGraduationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(
          color: ColorManager.violet.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorManager.violet.withValues(alpha: 0.1),
            blurRadius: 16,
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
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ColorManager.violet.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child:  Text('🏆', style: TextStyle(fontSize: 20.sp)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Graduate to Your Next Chapter',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'You forged remarkable tendon strength and compound power! Select your next path:',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Option 1: Repeat 12-Week Strength Challenge
          _buildGraduationOptionCard(
            context: context,
            title: 'Repeat 12-Week Strength Challenge',
            subtitle: 'Take a 1-week deload, recalculate your 1RM starting baselines, and initiate a new linear wave',
            tag: 'Goal: Compound Strength',
            colorHex: '0xFF9B51E0',
            planId: 'strength_12_week',
            buttonKey: const Key('graduate_sb_to_repeat_btn'),
          ),
          SizedBox(height: 12.h),

          // Option 2: 90-Day Muscle Building Challenge
          _buildGraduationOptionCard(
            context: context,
            title: '90-Day Muscle Building Challenge',
            subtitle: 'Leverage your new strength numbers to lift heavier volume in a dedicated hypertrophy split',
            tag: 'Goal: Hypertrophy & Size',
            colorHex: '0xFF2F6BFF',
            planId: 'muscle_building_90',
            buttonKey: const Key('graduate_sb_to_muscle_btn'),
          ),
          SizedBox(height: 12.h),

          // Option 3: General Fitness & Strength Maintenance
          _buildGraduationOptionCard(
            context: context,
            title: 'General Fitness & Strength Maintenance',
            subtitle: 'Maintain your baseline compound lifts with flexible training splits at maintenance energy',
            tag: 'Goal: Retain & Maintain',
            colorHex: '0xFF00B074',
            planId: 'general_fitness',
            buttonKey: const Key('graduate_sb_to_maintenance_btn'),
            actionLabel: 'Return to Dashboard',
            onActionPressed: () => context.go(Routes.mainRoute),
          ),
          SizedBox(height: 12.h),

          // Option 4: 60-Day Fat Loss & Cutting Challenge
          _buildGraduationOptionCard(
            context: context,
            title: '60-Day Fat Loss & Cutting Challenge',
            subtitle: 'Preserve your newly gained tendon power and dense muscle while shedding body fat',
            tag: 'Goal: Cut & Definition',
            colorHex: '0xFFFF5E36',
            planId: 'weight_loss_60',
            buttonKey: const Key('graduate_sb_to_cut_btn'),
          ),
        ],
      ),
    );
  }

  Widget _buildGraduationOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String tag,
    required String colorHex,
    required String planId,
    required Key buttonKey,
    String actionLabel = 'Explore Programme',
    VoidCallback? onActionPressed,
  }) {
    Color optionColor;
    try {
      optionColor = Color(int.parse(colorHex.replaceFirst('0x', ''), radix: 16));
    } catch (_) {
      optionColor = ColorManager.primary;
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: optionColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: optionColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: optionColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: buttonKey,
              onPressed: onActionPressed ??
                  () {
                    context.push('${Routes.transformationPlanDetailRoute}?planId=$planId');
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: optionColor,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button.r),
                ),
                elevation: 0,
              ),
              child: Text(
                actionLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthAchievementsCard(
    BuildContext context,
    UserTransformationState state,
  ) {
    return StreamBuilder<List<WorkoutSession>>(
      stream: WorkoutLogService().getSessions(),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];
        final summary = TransformationStrengthAnalytics.analyze(
          state: state,
          sessions: sessions,
        );

        if (!summary.hasData || summary.totalStrengthWorkouts == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          key: const Key('completion_strength_achievements_card'),
          width: double.infinity,
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: ColorManager.surface,
            boxShadow: ColorManager.cardShadow,
            borderRadius: BorderRadius.circular(AppRadius.card.r),
            border: Border.all(color: ColorManager.premium.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fitness_center_rounded, color: ColorManager.warningText, size: 22),
                  SizedBox(width: 8.w),
                  Text(
                    'Strength Achievements',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Workouts',
                      value: '${summary.totalStrengthWorkouts}',
                      subtext: 'Sessions',
                      icon: Icons.check_circle_rounded,
                      color: ColorManager.primary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'PRs Set',
                      value: '${summary.prsAchieved.length}',
                      subtext: 'Records',
                      icon: Icons.emoji_events_rounded,
                      color: ColorManager.premium,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildMetricTile(
                      label: '1RM Gain',
                      value: '+${summary.totalEstimated1RMGain.toStringAsFixed(1)} kg',
                      subtext: 'Estimated',
                      icon: Icons.trending_up_rounded,
                      color: ColorManager.success,
                    ),
                  ),
                ],
              ),

              if (summary.exerciseProgressions.isNotEmpty) ...[
                SizedBox(height: 14.h),
                Text(
                  'Most Improved Exercises',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                ...summary.exerciseProgressions.take(3).map((p) {
                  final isPositive = p.weightDifference > 0;
                  return Container(
                    margin: EdgeInsets.only(bottom: 6.h),
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: ColorManager.surfaceDark,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.exerciseName,
                                style: TextStyle(
                                  color: ColorManager.textPrimary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Baseline: ${p.startingWeight.toStringAsFixed(1)} kg → Final: ${p.latestWeight.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                  color: ColorManager.textSecondary,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: isPositive
                                ? ColorManager.success.withValues(alpha: 0.15)
                                : ColorManager.divider.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '${isPositive ? '+' : ''}${p.weightDifference.toStringAsFixed(1)} kg (${isPositive ? '+' : ''}${p.percentageImprovement.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              color: isPositive ? ColorManager.successText : ColorManager.textSecondary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}
