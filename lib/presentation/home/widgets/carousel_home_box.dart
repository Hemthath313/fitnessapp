import 'package:flutter/material.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CarouselHomeBox extends StatelessWidget {
  const CarouselHomeBox({
    super.key,
    required this.deviceWidth,
    required this.image,
    required this.onTap,
    required this.title,
    this.badge = 'CHALLENGE',
    this.subtitle,
    this.progress,
    this.actionText,
  });

  final double deviceWidth;
  final String image;
  final VoidCallback onTap;
  final String title;
  final String badge;
  final String? subtitle;
  final double? progress;
  final String? actionText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: Container(
            width: double.infinity,
            height: 150.h,
            decoration: BoxDecoration(
              color: ColorManager.surface,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: ColorManager.divider.withOpacity(0.4),
                width: 1.2,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: ColorManager.surfaceLight),
                ),
                // Gradient overlay — dark styling with high contrast readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.15),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top row: category badge + optional action text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: ColorManager.primary.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              badge.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (actionText != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    actionText!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 11.sp),
                                ],
                              ),
                            ),
                        ],
                      ),
                      // Bottom row: Title + Subtitle + Optional Progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  blurRadius: 6,
                                  color: Colors.black.withOpacity(0.8),
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          if (subtitle != null) ...[
                            SizedBox(height: 3.h),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (progress != null) ...[
                            SizedBox(height: 8.h),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: LinearProgressIndicator(
                                value: progress!.clamp(0.0, 1.0),
                                minHeight: 4.h,
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
