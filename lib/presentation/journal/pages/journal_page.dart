import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workout_logs/workout_history_screen.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/presentation/journal/widgets/weekly_schedule_widget.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(SizeManager.s16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My AI Hub',
              style: TextStyle(
                color: ColorManager.white,
                fontSize: SizeManager.s24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SizeManager.s4.h),
            Text(
              'Hyper-personalized fitness intelligence',
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: SizeManager.s14.sp,
              ),
            ),
            SizedBox(height: SizeManager.s24.h),

            if (!Provider.of<SubscriptionProvider>(context).isPremium)
              _buildPremiumUpgradeCard(),

            SizedBox(height: SizeManager.s20.h),
            _buildAICoachCard(),
            SizedBox(height: SizeManager.s20.h),
            const WeeklyScheduleWidget(),
            SizedBox(height: SizeManager.s20.h),

            // Navigation Cards
            Row(
              children: [
                Expanded(
                  child: _buildNavigationCard(
                    title: 'Meal Planner',
                    subtitle: 'Custom meal schedules',
                    icon: Icons.flatware_rounded,
                    color: Colors.orange,
                    isLocked: true,
                    onTap: null,
                  ),
                ),
                SizedBox(width: SizeManager.s12.w),
                Expanded(
                  child: _buildNavigationCard(
                    title: 'AI Scanner',
                    subtitle: 'Scan food to get proteins, carbs & fats per 100g',
                    icon: Icons.qr_code_scanner_rounded,
                    color: Colors.green,
                    isLocked: true,
                    onTap: null,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: SizeManager.s40.h),
            const PremiumAwareBannerAd(pageName: 'journal', bottomMargin: 60.0),
            SizedBox(height: SizeManager.s16.h),
          ],
        ),
      ),
    );
  }

  // ... (keep previous methods like _buildPremiumUpgradeCard, _buildAIInsightCard, _buildNutritionAnalysisCard)


  Widget _buildPremiumUpgradeCard() {
    return Container(
      margin: EdgeInsets.only(top: SizeManager.s12.h),
      padding: EdgeInsets.all(SizeManager.s16.w),
      decoration: BoxDecoration(
        color: ColorManager.primary,
        borderRadius: BorderRadius.circular(SizeManager.s20.r),
        boxShadow: [
          BoxShadow(
            color: ColorManager.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade to Pro!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: SizeManager.s18.sp,
                  ),
                ),
                SizedBox(height: SizeManager.s4.h),
                Text(
                  'Ads-free, AI Coach, Pro Tools & More.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: SizeManager.s12.sp,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push(Routes.premiumScreen),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ColorManager.primary,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: const Text(
              'Get Pro',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isLocked = false,
  }) {
    final cardContent = Stack(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(SizeManager.s16.w),
          height: SizeManager.s150.h,
          decoration: BoxDecoration(
            color: ColorManager.surface,
            borderRadius: BorderRadius.circular(SizeManager.s16.r),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(SizeManager.s10.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: SizeManager.s28.sp),
              ),
              SizedBox(height: SizeManager.s12.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorManager.white,
                  fontSize: SizeManager.s14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: SizeManager.s4.h),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorManager.white70,
                  fontSize: SizeManager.s11.sp,
                ),
              ),
            ],
          ),
        ),
        if (isLocked)
          Positioned(
            top: 12.h,
            right: 12.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'COMING SOON',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.lock_rounded,
                    color: Colors.amber,
                    size: 11.sp,
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    if (onTap == null) {
      return cardContent;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SizeManager.s16.r),
      child: cardContent,
    );
  }

  Widget _buildAICoachCard() {
    final sub = Provider.of<SubscriptionProvider>(context);
    final isPremium = sub.isPremium;

    return Container(
      padding: EdgeInsets.all(SizeManager.s20.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(SizeManager.s20.r),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: ColorManager.primary),
              SizedBox(width: SizeManager.s8.w),
              Text(
                'AI Personal Coach',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: SizeManager.s18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!isPremium)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'PREMIUM',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          SizedBox(height: SizeManager.s8.h),
          Text(
            isPremium
                ? 'Your coach is ready! Ask for meal ideas, exercise tips, and more.'
                : 'Unlock your AI Coach for 24/7 fitness and nutrition guidance.',
            style: TextStyle(
                color: ColorManager.white70, fontSize: SizeManager.s12.sp),
          ),
          SizedBox(height: SizeManager.s20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (isPremium) {
                  context.push(Routes.aiChatRoute);
                } else {
                  context.push(Routes.premiumScreen);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SizeManager.s12.r)),
              ),
              child: Text(
                isPremium ? 'Chat Now' : 'Unlock Now',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
