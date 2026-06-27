import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/profile/providers/profile_provider.dart';
import 'package:fitness_app/presentation/profile/widgets/edit_text_button.dart';
import 'package:fitness_app/presentation/profile/widgets/weight_data_text_row.dart';
import 'package:fitness_app/presentation/profile/widgets/weight_line_chart.dart';
import 'package:fitness_app/presentation/theme/providers/theme_provider.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/profile/widgets/measurement_line_chart.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, _) => FutureBuilder<
              Map<String, dynamic>>(
          future: homeProvider.fetchUserData(),
          builder: (context, snapshot) {
            final String emailData = homeProvider.userData['email'];
            final double chestData = homeProvider.userData['chest'];
            final double shoulderData = homeProvider.userData['shoulders'];
            final double bicepsData = homeProvider.userData['biceps'];
            final double foreArmData = homeProvider.userData['foreArm'];
            final double waistData = homeProvider.userData['waist'];
            final double hipsData = homeProvider.userData['hips'];
            final double thighData = homeProvider.userData['thigh'];
            final double calfData = homeProvider.userData['calf'];
            profileProvider.fetchAndSetFlSpots();
            return SafeArea(
              bottom: true,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: PaddingManager.p12,
                              right: PaddingManager.p12,
                              top: PaddingManager.p4,
                            ),
                            child: Container(
                              width: deviceWidth,
                              height: SizeManager.s60.h,
                              decoration: BoxDecoration(
                                color: ColorManager.black87,
                                borderRadius: BorderRadius.circular(
                                  RadiusManager.r40.r,
                                ),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: PaddingManager.p28,
                                    right: PaddingManager.p28,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        StringsManager.loggedInAs,
                                        style: StyleManager
                                            .profieloggedinTextStyle,
                                      ),
                                      Text(
                                        emailData,
                                        style: StyleManager
                                            .profileLoginDataTextStyle,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          EditTextButton(
                              onTap: () =>
                                  context.push(Routes.changeMeasurementsRoute)),
                          SizedBox(height: 12.h),
                          EditTextButton(
                            text: "Monthly Comparison",
                            onTap: () => context.push(Routes.monthlyComparisonRoute),
                          ),
                          Stack(
                            children: [
                              SizedBox(
                                height: SizeManager.s600.h,
                                width: deviceWidth,
                                child: Image.asset(
                                  homeProvider.userData['gender'] == 'Male'
                                      ? ImageManager.man
                                      : ImageManager.woman,
                                ),
                              ),
                              Positioned(
                                top: SizeManager.s140.h,
                                left: SizeManager.s35.w,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          StringsManager.chest,
                                          style: StyleManager
                                              .profileBodyMeasurmentsNameTextSTyle,
                                        ),
                                        Text(
                                          '${chestData.toStringAsFixed(1)} cm',
                                          style: StyleManager
                                              .profileBodyMeasurementsDataTextStyle,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: SizeManager.s2.h,
                                      width: SizeManager.s150.w,
                                      color: ColorManager.black87,
                                    )
                                  ],
                                ),
                              ),
                              Positioned(
                                top: SizeManager.s100.h,
                                right: SizeManager.s35.w,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          StringsManager.shoulders,
                                          style: StyleManager
                                              .profileBodyMeasurmentsNameTextSTyle,
                                        ),
                                        Text(
                                          '${shoulderData.toStringAsFixed(1)} cm',
                                          style: StyleManager
                                              .profileBodyMeasurementsDataTextStyle,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: SizeManager.s2.h,
                                      width: SizeManager.s130.w,
                                      color: ColorManager.black87,
                                    )
                                  ],
                                ),
                              ),
                              Positioned(
                                top: SizeManager.s160.h,
                                right: SizeManager.s35.w,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          StringsManager.biceps,
                                          style: StyleManager
                                              .profileBodyMeasurmentsNameTextSTyle,
                                        ),
                                        Text(
                                          '${bicepsData.toStringAsFixed(1)} cm',
                                          style: StyleManager
                                              .profileBodyMeasurementsDataTextStyle,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: SizeManager.s2.h,
                                      width: SizeManager.s110.w,
                                      color: ColorManager.black87,
                                    )
                                  ],
                                ),
                              ),
                              Positioned(
                                top: SizeManager.s212.h,
                                left: SizeManager.s35.w,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          StringsManager.foreArm,
                                          style: StyleManager
                                              .profileBodyMeasurmentsNameTextSTyle,
                                        ),
                                        Text(
                                          '${foreArmData.toStringAsFixed(1)} cm',
                                          style: StyleManager
                                              .profileBodyMeasurementsDataTextStyle,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: SizeManager.s2.h,
                                      width: SizeManager.s100.w,
                                      color: ColorManager.black87,
                                    )
                                  ],
                                ),
                              ),
                              Positioned(
                                top: SizeManager.s230.h,
                                right: SizeManager.s35.w,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          StringsManager.waist,
                                          style: StyleManager
                                              .profileBodyMeasurmentsNameTextSTyle,
                                        ),
                                        Text(
                                          '${waistData.toStringAsFixed(1)} cm',
                                          style: StyleManager
                                              .profileBodyMeasurementsDataTextStyle,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: SizeManager.s2.h,
                                      width: SizeManager.s140.w,
                                      color: ColorManager.black87,
                                    )
                                  ],
                                ),
                              ),
                              Positioned(
                                top: SizeManager.s270.h,
                                left: SizeManager.s35.w,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          StringsManager.hips,
                                          style: StyleManager
                                              .profileBodyMeasurmentsNameTextSTyle,
                                        ),
                                        Text(
                                          '${hipsData.toStringAsFixed(1)} cm',
                                          style: StyleManager
                                              .profileBodyMeasurementsDataTextStyle,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: SizeManager.s2.h,
                                      width: SizeManager.s140.w,
                                      color: ColorManager.black87,
                                    )
                                  ],
                                ),
                              ),
                              Positioned(
                                top: SizeManager.s330.h,
                                left: SizeManager.s35.w,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          StringsManager.thigh,
                                          style: StyleManager
                                              .profileBodyMeasurmentsNameTextSTyle,
                                        ),
                                        Text(
                                          '${thighData.toStringAsFixed(1)} cm',
                                          style: StyleManager
                                              .profileBodyMeasurementsDataTextStyle,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: SizeManager.s2.h,
                                      width: SizeManager.s150.w,
                                      color: ColorManager.black87,
                                    )
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: SizeManager.s140.h,
                                right: SizeManager.s35.w,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          StringsManager.calf,
                                          style: StyleManager
                                              .profileBodyMeasurmentsNameTextSTyle,
                                        ),
                                        Text(
                                          '${calfData.toStringAsFixed(1)} cm',
                                          style: StyleManager
                                              .profileBodyMeasurementsDataTextStyle,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: SizeManager.s2.h,
                                      width: SizeManager.s140.w,
                                      color: ColorManager.black87,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Theme Toggle Card
                          SizedBox(height: 16.h),
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, child) {
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: PaddingManager.p12),
                                child: GestureDetector(
                                  onTap: () => themeProvider.toggleTheme(),
                                  child: Container(
                                    width: deviceWidth,
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          ColorManager.surface,
                                          ColorManager.surfaceLight,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: ColorManager.primary.withOpacity(0.3),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: ColorManager.primary.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12.w),
                                          decoration: BoxDecoration(
                                            color: ColorManager.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          child: Icon(
                                            themeProvider.isDarkMode
                                                ? Icons.dark_mode_rounded
                                                : Icons.light_mode_rounded,
                                            color: ColorManager.primary,
                                            size: 28.sp,
                                          ),
                                        ),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                                                style: TextStyle(
                                                  color: ColorManager.textPrimary,
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                'Tap to switch theme',
                                                style: TextStyle(
                                                  color: ColorManager.textSecondary,
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: themeProvider.isDarkMode,
                                          onChanged: (value) => themeProvider.toggleTheme(),
                                          activeColor: ColorManager.primary,
                                          activeTrackColor: ColorManager.primary.withOpacity(0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 16.h),
                          
                          EditTextButton(
                              onTap: () =>
                                  context.push(Routes.changeWeightRoute)),
                          const WeightDataTextRowWidget(),
                          const WeightLineChart(),
                          
                          // Pro Features Section
                          _buildProAnalyticsSection(context),
                          
                          SizedBox(height: 24.h),
                        ],
                      ).animate().fadeIn(
                            duration: 500.ms,
                          ),
                    ),
                  ),
                  PremiumAwareBannerAd(pageName: 'profile'),
                ],
              ),
            );
          }),
    );
  }

  Widget _buildProAnalyticsSection(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final isPremium = subProvider.isPremium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PaddingManager.p16, vertical: PaddingManager.p8),
          child: Row(
            children: [
              Text(
                'Advanced Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isPremium) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: ColorManager.secondary,
                    borderRadius: BorderRadius.circular(4.r),
                    boxShadow: [
                      BoxShadow(
                        color: ColorManager.secondary.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Stack(
          children: [
            Column(
              children: [
                const MeasurementLineChart(
                  title: 'Chest Progress',
                  measurementType: 'chest',
                ),
                const MeasurementLineChart(
                  title: 'Biceps Progress',
                  measurementType: 'biceps',
                ),
              ],
            ),
            if (!isPremium)
              Positioned.fill(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: PaddingManager.p12),
                  decoration: BoxDecoration(
                    color: ColorManager.background.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: ColorManager.primary, size: 44.sp),
                      SizedBox(height: 10.h),
                      Text(
                        'Unlock Advanced Metrics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Track every muscle group individually',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () => context.push(Routes.premiumScreen),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
                          elevation: 5,
                        ),
                        child: Text('Get Pro Access', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
