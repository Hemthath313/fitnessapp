import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';

class FitnessDataWidget extends StatelessWidget {
  const FitnessDataWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final deviceWidth = MediaQuery.of(context).size.width;

    return Consumer<ConsumptionProvider>(
      builder: (context, consumptionProvider, _) => FutureBuilder<
              Map<String, dynamic>>(
          future: homeProvider.fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SpinKitSpinningLines(color: ColorManager.limerGreen2);
            } else if (snapshot.hasError) {
              return Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.error_outline,
                        color: ColorManager.red, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Unable to load fitness data',
                      style: TextStyle(color: ColorManager.white, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please check your internet connection',
                      style: TextStyle(color: ColorManager.grey2, fontSize: 14),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info_outline,
                        color: ColorManager.limerGreen2, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'No fitness data available',
                      style: TextStyle(color: ColorManager.white, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please complete your profile setup',
                      style: TextStyle(color: ColorManager.grey2, fontSize: 14),
                    ),
                  ],
                ),
              );
            } else {
              // Safe null checks for user data
              final userData = snapshot.data!;
              final bmr = userData['bmr'] as double? ?? 0.0;
              final bmi = userData['bmi'] as double? ?? 0.0;
              Color getProgressColor(double bmi) {
                var isNormalBMI = bmi >= 18.5 && bmi <= 25;
                var isUnderOrOverWeight =
                    (bmi >= 17 && bmi < 18.5) || (bmi > 25 && bmi <= 30);
                if (isNormalBMI) {
                  return ColorManager.limerGreen2;
                } else if (isUnderOrOverWeight) {
                  return ColorManager.yellow;
                } else {
                  return ColorManager.red;
                }
              }

              String getMessage(double bmi) {
                var isNormalBMI = bmi >= 18.5 && bmi <= 25;
                var isUnderWeight = bmi >= 17 && bmi < 18.5;
                var isOverWeight = bmi > 25 && bmi <= 30;
                if (isNormalBMI) {
                  return StringsManager.normalBmi;
                } else if (isUnderWeight) {
                  return StringsManager.underWeightBmi;
                } else if (isOverWeight) {
                  return StringsManager.overWeightBmi;
                } else {
                  return StringsManager.dangerousBmi;
                }
              }

            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            final cardBg = isDarkMode ? ColorManager.surface : ColorManager.primary;
            final textColor = isDarkMode ? ColorManager.textPrimary : Colors.white;
            final secondaryTextColor = isDarkMode ? ColorManager.textSecondary : Colors.white.withOpacity(0.8);
            final iconColor = isDarkMode ? ColorManager.primary : Colors.white;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: PaddingManager.p12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 1. BMI Card (Left - Tall)
                  Container(
                    width: (deviceWidth / 3 - 16).w,
                    height: SizeManager.s200.h,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(RadiusManager.r15.r),
                      boxShadow: [
                        BoxShadow(
                          color: (isDarkMode ? Colors.black : ColorManager.primary).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularPercentIndicator(
                          circularStrokeCap: CircularStrokeCap.round,
                          radius: RadiusManager.r40.r,
                          lineWidth: SizeManager.s8.w,
                          percent: (bmi / 40).clamp(0.0, 1.0),
                          progressColor: iconColor,
                          backgroundColor: isDarkMode ? Colors.white10 : Colors.white24,
                          animateFromLastPercent: true,
                          animation: true,
                          center: Icon(Icons.favorite_rounded, color: iconColor, size: SizeManager.s28),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'BMI ${bmi.toStringAsFixed(1)}',
                          style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                          child: Text(
                            StringsManager.normalBmi,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: secondaryTextColor, fontSize: 11),
                          ),
                        )
                      ],
                    ),
                  ),
                  // 2. Right Column (Consumption + Row(Water, Calories))
                  Column(
                    children: [
                      // Calorie Consumption Card (Big)
                      Padding(
                        padding: EdgeInsets.only(left: PaddingManager.p12.w, bottom: PaddingManager.p12.h),
                        child: Container(
                          height: 90,
                          width: (deviceWidth * (2 / 3) - 10).w,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(RadiusManager.r15.r),
                            boxShadow: [
                              BoxShadow(
                                color: (isDarkMode ? Colors.black : ColorManager.primary).withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                StringsManager.kcalConsumption,
                                style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                bmr.toStringAsFixed(0),
                                style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                StringsManager.kcalPerDay,
                                style: TextStyle(color: secondaryTextColor, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Bottom Row: Water & Calories Spent
                      Row(
                        children: [
                          // Water Card
                          Padding(
                            padding: EdgeInsets.only(left: PaddingManager.p12.w, right: PaddingManager.p4.w),
                            child: Container(
                              width: (deviceWidth / 3 - 20).w,
                              height: SizeManager.s100.h,
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(RadiusManager.r15.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDarkMode ? Colors.black : ColorManager.primary).withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(StringsManager.water, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                                        Icon(Icons.local_drink_rounded, color: iconColor, size: 24.sp),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          consumptionProvider.waterADay.toStringAsFixed(1),
                                          style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(StringsManager.liters, style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          // Calories Spent Card
                          Container(
                            width: (deviceWidth / 3 - 20).w,
                            height: SizeManager.s100.h,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(RadiusManager.r15.r),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDarkMode ? Colors.black : ColorManager.primary).withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(StringsManager.calories, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                                      Icon(Icons.local_pizza_rounded, color: iconColor, size: 24.sp),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        consumptionProvider.consumedCalories.toStringAsFixed(0),
                                        style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(StringsManager.kcal, style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
            }
          }),
    );
  }
}
