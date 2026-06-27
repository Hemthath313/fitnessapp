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
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeManager.s12.w, vertical: SizeManager.s8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
                left: SizeManager.s8.w, bottom: SizeManager.s12.h),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                color: ColorManager.white,
                fontSize: SizeManager.s18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.water_drop,
                  label: 'Log Water',
                  color: Colors.blue,
                  onTap: () {
                    context.push(Routes.addWaterRoute);
                  },
                ),
              ),
              SizedBox(width: SizeManager.s12.w),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.edit_calendar,
                  label: 'Log Workout',
                  color: Colors.orange,
                  onTap: () {
                    context.push(Routes.workoutLogRoute);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: SizeManager.s12.h),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.fitness_center,
                  label: 'Exercises',
                  color: ColorManager.limerGreen2,
                  onTap: () async {
                    final sub = Provider.of<SubscriptionProvider>(context,
                        listen: false);
                    if (!sub.isPremium) {
                      await InterstitialAdService.showStrengthWorkoutAd();
                    }
                    context.push(Routes.bodypartsPage);
                  },
                ),
              ),
              SizedBox(width: SizeManager.s12.w),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.restaurant_menu,
                  label: 'Diet Plans',
                  color: Colors.orange,
                  onTap: () {
                    final sub = Provider.of<SubscriptionProvider>(context,
                        listen: false);
                    if (sub.isPremium) {
                      context.push(Routes.dietRoute);
                    } else {
                      context.push(Routes.premiumScreen);
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: SizeManager.s12.h),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.history,
                  label: 'Workout History',
                  color: Colors.teal,
                  onTap: () {
                    context.push(Routes.workoutHistoryRoute);
                  },
                ),
              ),
              // SizedBox(width: SizeManager.s12.w),
              // Expanded(
              //   child: _QuickActionCard(
              //     icon: Icons.photo_camera,
              //     label: 'Progress Photos',
              //     color: Colors.pink,
              //     onTap: () {
              //       context.push(Routes.progressPhotosRoute);
              //     },
              //   ),
              // ),
            ],
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
