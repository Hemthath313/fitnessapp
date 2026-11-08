import 'package:fitness_app/presentation/widgets/feedback_dialog.dart';
import 'package:fitness_app/services/review_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RatingPromptDialog extends StatefulWidget {
  const RatingPromptDialog({super.key});

  @override
  State<RatingPromptDialog> createState() => _RatingPromptDialogState();
}

class _RatingPromptDialogState extends State<RatingPromptDialog> {
  int _selectedRating = 0; // 0 means unselected

  void _handleSubmit() async {
    if (_selectedRating == 0) return;

    final reviewService = ReviewService();
    // Close the rating selection dialog first
    Navigator.of(context).pop();

    // Mark the milestone prompted in storage
    await reviewService.markAsPrompted();

    if (_selectedRating >= 4) {
      // 4 or 5 stars -> Show official Play Store native prompt
      await reviewService.requestNativeReview();
    } else {
      // 1, 2, or 3 stars -> Redirect to our private Firestore feedback dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => FeedbackDialog(initialRating: _selectedRating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusManager.r24),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(PaddingManager.p20.w),
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(RadiusManager.r24),
          border: Border.all(
            color: ColorManager.divider,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative Header/Branding Icon
            Container(
              padding: EdgeInsets.all(SizeManager.s16.w),
              decoration: BoxDecoration(
                color: ColorManager.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.thumb_up_alt_outlined,
                size: SizeManager.s40.sp,
                color: ColorManager.primary,
              ),
            ),
            SizedBox(height: SizeManager.s20.h),
            
            // Title
            Text(
              'Enjoying GymBuddy?',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeManager.s12.h),
            
            // Subtitle description
            Text(
              'How would you rate your workout experience with us?',
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 14.sp,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeManager.s24.h),
            
            // Star selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final isSelected = starValue <= _selectedRating;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = starValue;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: SizeManager.s4.w),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                      size: SizeManager.s48.sp,
                      color: isSelected ? Colors.amber : ColorManager.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: SizeManager.s28.h),
            
            // Actions
            Column(
              children: [
                // Submit Button
                ElevatedButton(
                  onPressed: _selectedRating == 0 ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    disabledBackgroundColor: ColorManager.divider,
                    foregroundColor: const Color(0xFF06201B),
                    disabledForegroundColor: ColorManager.textSecondary,
                    padding: EdgeInsets.symmetric(vertical: SizeManager.s14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusManager.r15),
                    ),
                  ),
                  child: Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: SizeManager.s10.h),
                
                // Maybe Later Dismiss button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // Closes without saving flagged state
                  child: Text(
                    'Maybe Later',
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
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
}
