import 'package:fitness_app/utils/units.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/presentation/workout_tools/plate_calculator_sheet.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// 1-rep-max estimator dialog (Epley), opened from the Lifting Tools card.
void showOneRepMaxDialog(BuildContext context) {
  final weightController = TextEditingController(text: '80');
  final repsController = TextEditingController(text: '8');
  double estimatedMax = 80.0 * (1.0 + 8.0 / 30.0);

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        return AlertDialog(
          backgroundColor: ColorManager.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Row(
            children: [
              Icon(Icons.speed_rounded, color: ColorManager.primaryText, size: 24.sp),
              SizedBox(width: 8.w),
              Text('1-Rep Max Estimator', style: TextStyle(color: ColorManager.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculate your maximum single-rep strength using the Epley formula.',
                style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: ColorManager.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Weight (${Units.label})',
                        labelStyle: TextStyle(color: ColorManager.textTertiary),
                        filled: true,
                        fillColor: ColorManager.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) {
                        final w = double.tryParse(weightController.text) ?? 0;
                        final r = double.tryParse(repsController.text) ?? 1;
                        setModalState(() {
                          estimatedMax = w * (1.0 + r / 30.0);
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextField(
                      controller: repsController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: ColorManager.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Reps Completed',
                        labelStyle: TextStyle(color: ColorManager.textTertiary),
                        filled: true,
                        fillColor: ColorManager.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) {
                        final w = double.tryParse(weightController.text) ?? 0;
                        final r = double.tryParse(repsController.text) ?? 1;
                        setModalState(() {
                          estimatedMax = w * (1.0 + r / 30.0);
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text('ESTIMATED 1-REP MAX', style: TextStyle(color: ColorManager.primaryText, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                    SizedBox(height: 4.h),
                    Text('${estimatedMax.toStringAsFixed(1)} ${Units.label}', style: TextStyle(color: ColorManager.white, fontSize: 24.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Done', style: TextStyle(color: ColorManager.primaryText, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ),
  );
}

  /// Card 3: AI Split Customizer & Re-plan Card
class RoutineCustomizerCard extends StatelessWidget {
  const RoutineCustomizerCard({super.key, required this.activeDays});

  final List<String> activeDays;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorManager.surfaceDark,
            ColorManager.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: ColorManager.primaryText, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                'Routine Customizer',
                style: TextStyle(color: ColorManager.primaryText, fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            'Change frequency, target goal, or equipment in seconds.',
            style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
          ),
          Wrap(
            spacing: 6.w,
            children: [
              _FeatureBadge('${activeDays.length} Days Active'),
              _FeatureBadge('Full Equipment'),
              _FeatureBadge('Hypertrophy'),
            ],
          ),
          SizedBox(
            width: double.infinity,
            height: 36.h,
            child: ElevatedButton.icon(
              onPressed: () => context.push(Routes.workoutGeneratorRoute),
              icon: Icon(Icons.flash_on_rounded, size: 14.sp, color: ColorManager.onMint),
              label: Text('Re-generate Split', style: TextStyle(color: ColorManager.onMint, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button.r)),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

  /// Card 4: Pro Lifting Tools Card (Plate Calculator + 1RM Estimator)
class ProToolkitCard extends StatelessWidget {
  const ProToolkitCard({super.key});


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(color: ColorManager.premium.withValues(alpha: 0.4)),
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: ColorManager.warningText, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                'Lifting Tools & Calculators',
                style: TextStyle(color: ColorManager.warningText, fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            'Avoid gym math. Visual barbell loading and 1-rep max calculator.',
            style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => PlateCalculatorSheet.show(context),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: ColorManager.surfaceDark,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: ColorManager.divider),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.fitness_center_rounded, color: ColorManager.primaryText, size: 16.sp),
                        SizedBox(height: 3.h),
                        Text('Plate Math', style: TextStyle(color: ColorManager.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                        Text('Olympic Bar', style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: InkWell(
                  onTap: () => showOneRepMaxDialog(context),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: ColorManager.surfaceDark,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: ColorManager.divider),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.speed_rounded, color: ColorManager.warningText, size: 16.sp),
                        SizedBox(height: 3.h),
                        Text('1RM Calc', style: TextStyle(color: ColorManager.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                        Text('Max Strength', style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp)),
                      ],
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
}

  /// Card 5: Strength & PR Vault Partner
class StrengthPartnerCard extends StatelessWidget {
  const StrengthPartnerCard({super.key});


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(color: ColorManager.primary.withValues(alpha: 0.35)),
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: ColorManager.warningText, size: 18.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Strength Partner & PRs',
                    style: TextStyle(color: ColorManager.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: ColorManager.textTertiary, size: 12.sp),
            ],
          ),
          Text(
            'Track your Estimated 1RMs, progressive overload benchmarks, and PR vault.',
            style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
          ),
          InkWell(
            onTap: () => context.push(Routes.strengthAnalyticsRoute),
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: ColorManager.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, color: ColorManager.primaryText, size: 14.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Open PR Vault & Analytics',
                    style: TextStyle(color: ColorManager.primaryText, fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge(this.text);

  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Text(text, style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp)),
    );
  }
}
