import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class PremiumUpsellBannerCard extends StatelessWidget {
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;
  final String title;
  final String message;
  final String buttonText;

  const PremiumUpsellBannerCard({
    super.key,
    this.onUpgrade,
    this.onDismiss,
    this.title = 'Unlock Gym Buddy Pro',
    this.message =
        'Build unlimited custom workout splits, access strength analytics, and train completely ad-free.',
    this.buttonText = 'Upgrade to Pro',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(
          color: ColorManager.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorManager.primary.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: ColorManager.primaryText,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ColorManager.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 1.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: ColorManager.premium,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  key: const Key('premium_banner_dismiss_button'),
                  onTap: onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Icon(
                      Icons.close_rounded,
                      color: ColorManager.textTertiary,
                      size: 18.sp,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 12.sp,
              height: 1.35,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('premium_banner_cta_button'),
              onPressed: onUpgrade ?? () => context.push(Routes.premiumScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: ColorManager.onMint,
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button.r),
                ),
                elevation: 0,
              ),
              icon: Icon(
                Icons.flash_on_rounded,
                size: 15.sp,
                color: ColorManager.onMint,
              ),
              label: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.onMint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
