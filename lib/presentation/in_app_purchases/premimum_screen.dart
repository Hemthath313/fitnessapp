import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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
    // Trigger a one-time auto-restore attempt when opening the paywall.
    // This helps when the store already owns the subscription but user changed app login email.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sub = Provider.of<SubscriptionProvider>(context, listen: false);
      sub.autoRestoreIfNeeded();
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Go Premium', style: TextStyle(color: Colors.white)),
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
                        color: Colors.white,
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: SizeManager.s16.h),
                  if (subProvider.isPremium) ...[
                    Container(
                      padding: EdgeInsets.all(SizeManager.s20.w),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(SizeManager.s16.r),
                        border: Border.all(color: ColorManager.primary),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: ColorManager.primary),
                          SizedBox(width: SizeManager.s12.w),
                          const Text(
                            'You are already a Premium member!',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                        icon: const Icon(Icons.restore, color: ColorManager.textSecondary),
                        label: const Text(
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
                    ...subProvider.products.map((product) => _buildProductCard(product, subProvider)),
                  ],
                  SizedBox(height: SizeManager.s12.h),
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.security, color: ColorManager.primary, size: 14.sp),
                          SizedBox(width: 6.w),
                          Text(
                            'Secure checkout with App Store/Play Store',
                            style: TextStyle(fontSize: 10.sp, color: ColorManager.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: SizeManager.s24.h),
                  const Center(
                    child: Text(
                      'Cancel anytime. By subscribing, you agree to our\nTerms and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Colors.white38),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureSection() {
    return Column(
      children: [
        _buildFeatureItem(
          Icons.auto_awesome, 
          'AI Workout Generator', 
          'Build unlimited personalized weekly workout plans with AI.',
          Colors.purpleAccent,
        ),
        _buildFeatureItem(
          Icons.restaurant_menu, 
          'Advanced Diet & Macros', 
          'Track calories, macros, and access premium nutritional plans.',
          Colors.orangeAccent,
        ),
        _buildFeatureItem(
          Icons.fitness_center, 
          'Unlimited Custom Workouts', 
          'Create and save infinite custom routines.',
          Colors.blueAccent,
        ),
        _buildFeatureItem(
          Icons.analytics, 
          'Elite Analytics', 
          'Deep dive into your progress with interactive charts.',
          Colors.pinkAccent,
        ),
        _buildFeatureItem(
          Icons.ads_click, 
          'Ad-Free Experience', 
          'Remove all ads and focus entirely on your training.',
          Colors.greenAccent,
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
              color: iconColor.withOpacity(0.1),
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

  Widget _buildProductCard(ProductDetails product, SubscriptionProvider provider) {
    final isYearly = product.id.contains('yearly');
    return Container(
      margin: EdgeInsets.only(bottom: SizeManager.s16.h),
      padding: EdgeInsets.all(SizeManager.s16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(SizeManager.s16.r),
        border: Border.all(
          color: isYearly ? ColorManager.primary : ColorManager.surfaceLight,
          width: 2,
        ),
        boxShadow: [
          if (isYearly)
            BoxShadow(
              color: ColorManager.primary.withOpacity(0.2),
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
                if (isYearly)
                  Container(
                    margin: EdgeInsets.only(bottom: 4.h),
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: ColorManager.primary,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'BEST VALUE',
                      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                Text(
                  product.title.split('(')[0].trim(),
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  product.description,
                  style: TextStyle(fontSize: 12.sp, color: ColorManager.textSecondary),
                ),
                SizedBox(height: 4.h),
                Text(
                  product.price,
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: ColorManager.secondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => provider.buyProduct(product),
            style: ElevatedButton.styleFrom(
              backgroundColor: isYearly ? ColorManager.primary : ColorManager.surfaceLight,
              foregroundColor: isYearly ? Colors.black : ColorManager.textPrimary,
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
