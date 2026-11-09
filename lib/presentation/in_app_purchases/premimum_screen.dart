import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  _PremiumScreenState createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sub = Provider.of<SubscriptionProvider>(context, listen: false);
      if (!sub.isPremium) {
        sub.restorePurchases();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
        title: Text('Go Premium', style: TextStyle(color: ColorManager.textPrimary)),
      ),
      body: subProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(SizeManager.s16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(
                      Icons.star_rounded,
                      size: 80.sp,
                      color: ColorManager.secondary,
                    ),
                  ),
                  SizedBox(height: SizeManager.s16.h),
                  Center(
                    child: Text(
                      'Unlock Your Potential',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: SizeManager.s8.h),
                  Center(
                    child: Text(
                      'Access exclusive analytics, pro workout routines, and advanced tracking.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, color: ColorManager.textSecondary),
                    ),
                  ),
                  SizedBox(height: SizeManager.s24.h),
                  
                  // Feature List
                  _buildFeatureSection(),
                  
                  SizedBox(height: SizeManager.s32.h),
                  
                  Center(
                    child: Text(
                      'Choose Your Plan',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: SizeManager.s16.h),
                  if (subProvider.isPremium) ...[
                    Container(
                      padding: EdgeInsets.all(SizeManager.s20.w),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(SizeManager.s16.r),
                        border: Border.all(color: ColorManager.primary),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: ColorManager.primary),
                          SizedBox(width: SizeManager.s12.w),
                          Text(
                            'You are already a Premium member!',
                            style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: subProvider.isLoading
                            ? null
                            : () => subProvider.restorePurchases(),
                        icon:  Icon(Icons.restore, color: ColorManager.textSecondary),
                        label:  Text(
                          'Restore',
                          style: TextStyle(color: ColorManager.textSecondary),
                        ),
                      ),
                    ),
                    if (subProvider.error != null) ...[
                      SizedBox(height: SizeManager.s8.h),
                      Text(
                        subProvider.error!,
                        style: TextStyle(
                          color: ColorManager.error,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: SizeManager.s12.h),
                    ],
                    ..._getSortedPlans(subProvider.plans).map((plan) => _buildProductCard(plan, subProvider)),
                  ],
                  SizedBox(height: SizeManager.s12.h),
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: ColorManager.surface,
                        boxShadow: ColorManager.cardShadow,
                        borderRadius: BorderRadius.circular(AppRadius.card.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.security, color: ColorManager.primary, size: 14.sp),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              'Secure checkout with App Store/Play Store',
                              style: TextStyle(fontSize: 11.sp, color: ColorManager.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: SizeManager.s24.h),
                   Center(
                    child: Text(
                      'Cancel anytime. By subscribing, you agree to our\nTerms and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.sp, color: Colors.white38),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<SubscriptionPlan> _getSortedPlans(List<SubscriptionPlan> plans) {
    final list = List<SubscriptionPlan>.from(plans);
    list.sort((a, b) {
      int getRank(SubscriptionPlan plan) {
        if (plan.isLifetime ||
            plan.id.toLowerCase().contains('lifetime') ||
            plan.title.toLowerCase().contains('lifetime')) {
          return 2;
        }
        if (plan.isYearly ||
            plan.id.toLowerCase().contains('yearly') ||
            plan.title.toLowerCase().contains('yearly') ||
            plan.title.toLowerCase().contains('annual')) {
          return 1;
        }
        return 0; // monthly
      }

      return getRank(a).compareTo(getRank(b));
    });
    return list;
  }

  Widget _buildFeatureSection() {
    return Column(
      children: [
        _buildFeatureItem(
          Icons.auto_awesome, 
          'Plan Builder', 
          'Build, customize & save unlimited personalized weekly workout splits.',
          Colors.tealAccent,
        ),
        _buildFeatureItem(
          Icons.file_download_outlined, 
          'Full History & CSV Export', 
          'Unlimited workout logs, calendar activity tracking, and Excel/CSV export.',
          Colors.blueAccent,
        ),
        _buildFeatureItem(
          Icons.restaurant_menu, 
          'Advanced Diet & Nutrition', 
          'Access structured bulking, cutting, and maintenance meal plans.',
          Colors.orangeAccent,
        ),
        _buildFeatureItem(
          Icons.ads_click, 
          'Ad-Free Experience', 
          'Remove all ads and focus entirely on your training.',
          Colors.greenAccent,
        ),
        _buildFeatureItem(
          Icons.view_carousel_rounded, 
          'Pro Splits & Workout Challenges', 
          'Unlock PPL, Upper/Lower, and all 30-day challenge training days.',
          Colors.amberAccent,
        ),
        _buildFeatureItem(
          Icons.star_purple500_sharp, 
          'Future Premium Features', 
          'Lock in access to all upcoming advanced training features and updates.',
          Colors.yellowAccent,
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, Color iconColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeManager.s12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(SizeManager.s10.w),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: iconColor, size: 22.sp),
          ),
          SizedBox(width: SizeManager.s16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: ColorManager.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: ColorManager.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(SubscriptionPlan plan, SubscriptionProvider provider) {
    final isYearly = plan.isYearly;
    final isLifetime = plan.isLifetime;
    final highlightColor = isLifetime 
        ? ColorManager.secondary 
        : (isYearly ? ColorManager.primary : ColorManager.surfaceLight);

    return Container(
      margin: EdgeInsets.only(bottom: SizeManager.s16.h),
      padding: EdgeInsets.all(SizeManager.s16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(
          color: highlightColor,
          width: 2,
        ),
        boxShadow: [
          if (isYearly || isLifetime)
            BoxShadow(
              color: highlightColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLifetime)
                  Container(
                    margin: EdgeInsets.only(bottom: 4.h),
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: ColorManager.secondary,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child:  Text(
                      'LIFETIME ACCESS',
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  )
                else if (isYearly)
                  Container(
                    margin: EdgeInsets.only(bottom: 4.h),
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: ColorManager.primary,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'BEST VALUE',
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: ColorManager.onMint),
                    ),
                  ),
                Text(
                  plan.title,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: ColorManager.textPrimary),
                ),
                Text(
                  plan.description,
                  style: TextStyle(fontSize: 12.sp, color: ColorManager.textSecondary),
                ),
                SizedBox(height: 4.h),
                Text(
                  plan.price,
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: ColorManager.secondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.buyPlan(plan);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not complete purchase: ${e.toString().replaceAll('Exception:', '').trim()}'),
                      backgroundColor: Colors.redAccent,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: (isYearly || isLifetime) ? highlightColor : ColorManager.surfaceLight,
              foregroundColor: (isYearly || isLifetime) 
                  ? (isLifetime ? ColorManager.onMint : ColorManager.textPrimary) 
                  : ColorManager.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              elevation: 0,
            ),
            child: Text('Select', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
