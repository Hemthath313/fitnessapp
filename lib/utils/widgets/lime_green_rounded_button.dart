import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LimeGreenRoundedButtonWidget extends StatelessWidget {
  const LimeGreenRoundedButtonWidget({
    super.key,
    required this.onTap,
    required this.title,
    this.isLoading = false,
  });

  final VoidCallback onTap;
  final String title;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: SizedBox(
        height: 48.h,
        child: ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorManager.primary,
            foregroundColor: ColorManager.onMint,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button.r),
            ),
            disabledBackgroundColor: ColorManager.primary.withValues(alpha: 0.6),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          ),
          child: isLoading
              ? SizedBox(
                  height: 20.h,
                  width: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(ColorManager.onMint),
                  ),
                )
              : Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.onMint,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
