import 'dart:ui' show ImageFilter;

import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Shows a Pro feature blurred behind a small "Unlock with Pro" panel, so free
/// users can see what they would get instead of an empty locked box.
///
/// When [locked] is false the [child] is shown as-is.
class ProLockedPreview extends StatelessWidget {
  const ProLockedPreview({
    super.key,
    required this.child,
    required this.locked,
    required this.title,
    this.subtitle,
    this.borderRadius = 16,
  });

  final Widget child;
  final bool locked;
  final String title;
  final String? subtitle;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius.r),
      child: Stack(
        children: [
          // The real content, blurred and not interactive.
          IgnorePointer(child: ExcludeSemantics(child: child)),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: ColorManager.surface.withValues(alpha: 0.55),
                alignment: Alignment.center,
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: ColorManager.premium.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock_rounded,
                          color: ColorManager.warningText, size: 22.sp),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: ColorManager.textSecondary, fontSize: 12.sp),
                      ),
                    ],
                    SizedBox(height: 12.h),
                    ElevatedButton(
                      key: const Key('pro_locked_preview_unlock_button'),
                      onPressed: () => context.push(Routes.premiumScreen),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        foregroundColor: ColorManager.onMint,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r)),
                      ),
                      child: Text('Unlock with Pro',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
