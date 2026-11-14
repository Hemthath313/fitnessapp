import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';

/// Modal dialog celebrating an unlocked transformation milestone.
class MilestoneCelebrationDialog extends StatelessWidget {
  final TransformationMilestone milestone;
  final VoidCallback onDismiss;

  const MilestoneCelebrationDialog({
    super.key,
    required this.milestone,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required TransformationMilestone milestone,
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MilestoneCelebrationDialog(
        milestone: milestone,
        onDismiss: () {
          Navigator.of(ctx).pop();
          onDismiss();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = milestone.achievedAt != null
        ? DateFormat('MMMM d, yyyy').format(milestone.achievedAt!)
        : 'Today';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: ColorManager.warning.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorManager.warning.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 26.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Trophy / Milestone Icon
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                color: ColorManager.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: ColorManager.warning.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: ColorManager.warning,
                  size: 38.sp,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Badge Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: ColorManager.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                'MILESTONE UNLOCKED!',
                style: TextStyle(
                  color: ColorManager.warning,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Milestone Title
            Text(
              milestone.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),

            // Description
            Text(
              milestone.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 10.h),

            // Unlocked Date
            Text(
              'Unlocked on $dateStr',
              style: TextStyle(
                color: ColorManager.textTertiary,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 22.h),

            // Claim / Continue CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('milestone_claim_button'),
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.warning,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Claim & Continue',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
