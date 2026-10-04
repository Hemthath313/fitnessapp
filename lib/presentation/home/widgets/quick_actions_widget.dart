import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/interstitial_ads/interstitial_ad_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness_app/utils/router/router.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final isPremium = subProvider.isPremium;

    final List<Map<String, dynamic>> actions = [
      {
        'icon': Icons.water_drop_rounded,
        'label': 'Water',
        'color': Colors.blue,
        'onTap': () => context.push(Routes.addWaterRoute),
      },
      {
        'icon': Icons.fitness_center_rounded,
        'label': 'Log Lift',
        'color': Colors.orange,
        'onTap': () => context.push(Routes.workoutLogRoute),
      },
      {
        'icon': Icons.restaurant_menu_rounded,
        'label': 'Diet Plans',
        'color': Colors.green,
        'onTap': () {
          context.push(Routes.dietRoute);
        },
      },
      {
        'icon': Icons.history_rounded,
        'label': 'History',
        'color': Colors.teal,
        'onTap': () => context.push(Routes.workoutHistoryRoute),
      },
      {
        'icon': Icons.photo_camera_rounded,
        'label': 'Progress',
        'color': Colors.pink,
        'onTap': () => context.push(Routes.progressPhotosRoute),
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
            decoration: BoxDecoration(
              color: ColorManager.surfaceLight,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: ColorManager.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: actions.map((act) {
                final Color baseColor = act['color'] as Color;
                return GestureDetector(
                  onTap: act['onTap'] as VoidCallback,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular Icon wrapper
                      Container(
                        width: 52.w,
                        height: 52.w,
                        decoration: BoxDecoration(
                          color: baseColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: baseColor.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          act['icon'] as IconData,
                          color: baseColor,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        act['label'] as String,
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SizeManager.s16.r),
      child: Container(
        padding: EdgeInsets.all(SizeManager.s16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(SizeManager.s16.r),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: SizeManager.s28.sp,
            ),
            SizedBox(height: SizeManager.s8.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.white,
                fontSize: SizeManager.s14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
