import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'dart:math' as math;
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/utils/tdee_calculator.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';

class CalorieGoalInfo {
  final double? targetCalories;
  final bool hasValidTarget;
  final String sourceDescription;

  const CalorieGoalInfo({
    this.targetCalories,
    required this.hasValidTarget,
    required this.sourceDescription,
  });
}

class FitnessDataWidget extends StatefulWidget {
  final bool compact;

  const FitnessDataWidget({
    super.key,
    this.compact = false,
  });

  /// Static helper to resolve calorie goal according to Phase 1 data accuracy rules.
  static CalorieGoalInfo resolveCalorieGoal({
    required BuildContext context,
    required Map<String, dynamic> userData,
  }) {
    // Priority 1: Active transformation personalized calorie target
    final transformationProvider =
        Provider.of<TransformationProvider?>(context, listen: false);
    if (transformationProvider != null &&
        transformationProvider.hasActiveTransformation &&
        transformationProvider.activeTransformation != null &&
        transformationProvider.activeTransformation!.targetCalories > 0) {
      return CalorieGoalInfo(
        targetCalories:
            transformationProvider.activeTransformation!.targetCalories,
        hasValidTarget: true,
        sourceDescription: 'Transformation Target',
      );
    }

    // Priority 2: Configured user calorie target
    final configuredTarget = (userData['targetCalories'] as num?)?.toDouble() ??
        (userData['target_calories'] as num?)?.toDouble() ??
        (userData['calorieGoal'] as num?)?.toDouble();
    if (configuredTarget != null && configuredTarget > 0) {
      return CalorieGoalInfo(
        targetCalories: configuredTarget,
        hasValidTarget: true,
        sourceDescription: 'Daily Goal',
      );
    }

    // Priority 3: Existing TDEE calculation and appropriate activity factor
    final tdeeVal = (userData['tdee'] as num?)?.toDouble();
    final goal = (userData['goal'] as String?) ?? '';
    final gender = (userData['gender'] as String?) ?? '';

    if (tdeeVal != null && tdeeVal > 0) {
      final target = TDEECalculator.calculateTargetCalories(
        tdee: tdeeVal,
        goal: goal,
        gender: gender.isNotEmpty ? gender : 'Male',
      );
      if (target > 0) {
        return CalorieGoalInfo(
          targetCalories: target,
          hasValidTarget: true,
          sourceDescription: 'TDEE Target',
        );
      }
    }

    // TDEE calculation from user biometric parameters
    final weight = (userData['weight'] as num?)?.toDouble() ?? 0.0;
    final height = (userData['height'] as num?)?.toDouble() ?? 0.0;
    final age = (userData['age'] as num?)?.toInt() ?? 0;
    final activity = (userData['activity'] as String?) ?? '';

    if (weight > 0 && height > 0 && age > 0 && gender.isNotEmpty) {
      final calculatedTdee = TDEECalculator.calculateTDEE(
        gender: gender,
        weightKg: weight,
        heightCm: height,
        age: age,
        activityLevel: activity.isNotEmpty ? activity : 'MODERATE',
      );
      final target = TDEECalculator.calculateTargetCalories(
        tdee: calculatedTdee,
        goal: goal,
        gender: gender,
      );
      if (target > 0) {
        return CalorieGoalInfo(
          targetCalories: target,
          hasValidTarget: true,
          sourceDescription: 'TDEE Target',
        );
      }
    }

    // Priority 4: Missing target state - honest unavailable/setup state
    return const CalorieGoalInfo(
      targetCalories: null,
      hasValidTarget: false,
      sourceDescription: 'Target Not Set',
    );
  }

  /// Static helper to resolve water goal according to Phase 1 dynamic water rules.
  static double resolveWaterGoal({
    required BuildContext context,
    required ConsumptionProvider consumptionProvider,
    required Map<String, dynamic> userData,
  }) {
    // 1. Active transformation daily water target (ml to L)
    final transformationProvider =
        Provider.of<TransformationProvider?>(context, listen: false);
    if (transformationProvider != null &&
        transformationProvider.hasActiveTransformation &&
        transformationProvider.activeTransformation != null &&
        transformationProvider.activeTransformation!.dailyWaterTargetMl > 0) {
      return transformationProvider
              .activeTransformation!.dailyWaterTargetMl /
          1000.0;
    }

    // 2. Custom water goal on ConsumptionProvider
    if (consumptionProvider.waterGoalLiters > 0 &&
        consumptionProvider.waterGoalLiters != 2.5) {
      return consumptionProvider.waterGoalLiters;
    }

    // 3. User profile configured water goal (userData)
    final userWaterGoal = (userData['waterGoal'] as num?)?.toDouble() ??
        (userData['dailyWaterTarget'] as num?)?.toDouble();
    if (userWaterGoal != null && userWaterGoal > 0) {
      return userWaterGoal > 100 ? (userWaterGoal / 1000.0) : userWaterGoal;
    }

    // 4. Default fallback: 2.5 L
    return 2.5;
  }

  @override
  State<FitnessDataWidget> createState() => _FitnessDataWidgetState();
}

class _FitnessDataWidgetState extends State<FitnessDataWidget> {
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    // Cache the future once so ConsumptionProvider rebuilds don't re-trigger Firestore fetches
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    _userDataFuture = homeProvider.fetchUserData();
  }

  CalorieGoalInfo _resolveCalorieGoal({
    required BuildContext context,
    required Map<String, dynamic> userData,
  }) =>
      FitnessDataWidget.resolveCalorieGoal(
        context: context,
        userData: userData,
      );

  double _resolveWaterGoal({
    required BuildContext context,
    required ConsumptionProvider consumptionProvider,
    required Map<String, dynamic> userData,
  }) =>
      FitnessDataWidget.resolveWaterGoal(
        context: context,
        consumptionProvider: consumptionProvider,
        userData: userData,
      );

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsumptionProvider>(
      builder: (context, consumptionProvider, _) => FutureBuilder<
              Map<String, dynamic>>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            final homeProvider =
                Provider.of<HomeProvider>(context, listen: false);
            final cachedData = homeProvider.userData;
            final effectiveData = (snapshot.hasData && snapshot.data!.isNotEmpty)
                ? snapshot.data!
                : (cachedData.isNotEmpty ? cachedData : null);

            if (snapshot.connectionState == ConnectionState.waiting &&
                effectiveData == null) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: CircularProgressIndicator(
                    color: ColorManager.primary,
                  ),
                ),
              );
            } else if (snapshot.hasError && effectiveData == null) {
              return Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.error_outline,
                        color: ColorManager.errorText, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Unable to load fitness data',
                      style: TextStyle(color: ColorManager.white, fontSize: 16.sp),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please check your internet connection',
                      style: TextStyle(color: ColorManager.grey2, fontSize: 14.sp),
                    ),
                  ],
                ),
              );
            } else if (effectiveData == null || effectiveData.isEmpty) {
              return Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info_outline,
                        color: ColorManager.primaryText, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'No fitness data available',
                      style: TextStyle(color: ColorManager.white, fontSize: 16.sp),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please complete your profile setup',
                      style: TextStyle(color: ColorManager.grey2, fontSize: 14.sp),
                    ),
                  ],
                ),
              );
            } else {
              // Safe null checks for user data
              final userData = effectiveData;
              final calorieInfo = _resolveCalorieGoal(context: context, userData: userData);
              final hasTarget = calorieInfo.hasValidTarget;
              final targetCalories = calorieInfo.targetCalories ?? 0.0;
              final consumedCalories = consumptionProvider.consumedCalories;
              final remainingCalories = hasTarget
                  ? (targetCalories - consumedCalories).clamp(0.0, double.infinity)
                  : 0.0;
              final caloriePercent = (hasTarget && targetCalories > 0
                      ? (consumedCalories / targetCalories)
                      : 0.0)
                  .clamp(0.0, 1.0);

              final waterGoal = _resolveWaterGoal(
                context: context,
                consumptionProvider: consumptionProvider,
                userData: userData,
              );
              final consumedWater = consumptionProvider.waterADay;
              final waterPercent = (waterGoal > 0 ? (consumedWater / waterGoal) : 0.0).clamp(0.0, 1.0);

              final bmi = userData['bmi'] as double? ?? 0.0;
              Color getProgressColor(double bmi) {
                var isNormalBMI = bmi >= 18.5 && bmi <= 25;
                var isUnderOrOverWeight =
                    (bmi >= 17 && bmi < 18.5) || (bmi > 25 && bmi <= 30);
                if (isNormalBMI) {
                  return ColorManager.success; // Emerald Green
                } else if (isUnderOrOverWeight) {
                  return ColorManager.warning; // Amber / Yellow
                } else {
                  return ColorManager.error; // Red
                }
              }

              String getMessage(double bmi) {
                var isNormalBMI = bmi >= 18.5 && bmi <= 25;
                var isUnderWeight = bmi < 18.5;
                var isOverWeight = bmi > 25 && bmi <= 30;
                if (isNormalBMI) {
                  return "Normal";
                } else if (isUnderWeight) {
                  return "Underweight";
                } else if (isOverWeight) {
                  return "Overweight";
                } else {
                  return "Obese";
                }
              }

            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            
            // Theme Decorations matching the user's recommended premium gradient:
            final calorieCardDecoration = BoxDecoration(
              color: ColorManager.surface,
              boxShadow: ColorManager.cardShadow,
              borderRadius: BorderRadius.circular(AppRadius.card.r),
            );

            // Other cards (Water, BMI)
            final cardBg = ColorManager.surface;
            final cardDecoration = BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppRadius.card.r),
              boxShadow: ColorManager.cardShadow,
            );

            final textColor = ColorManager.textPrimary;
            final calorieSecondaryText = ColorManager.textSecondary;
            final calorieSmallLabelText = ColorManager.textSecondary;
            
            final lightThemeTextColor = ColorManager.textPrimary;
            final lightThemeSecondaryTextColor = ColorManager.textSecondary;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: PaddingManager.p16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Daily Calorie Tracker Card (Full width at Top)
                  Container(
                    width: double.infinity,
                    decoration: calorieCardDecoration,
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Calorie Tracker',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left Side: Circular Gauge
                            CircularPercentIndicator(
                              circularStrokeCap: CircularStrokeCap.round,
                              radius: 50.r,
                              lineWidth: 9.w,
                              percent: caloriePercent,
                              progressColor: ColorManager.primary,
                              backgroundColor: ColorManager.primary.withValues(alpha: 0.15),
                              animateFromLastPercent: true,
                              animation: true,
                              center: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      consumedCalories.toString(),
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      hasTarget
                                          ? "/ ${targetCalories.toStringAsFixed(0)} kcal"
                                          : "/ -- kcal",
                                      style: TextStyle(
                                        color: calorieSmallLabelText,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Right Side: Metrics List
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCalorieMetric(
                                    label: "Consumed",
                                    value: "$consumedCalories kcal",
                                    dotColor: ColorManager.primaryLight, 
                                    textColor: calorieSecondaryText,
                                    valueColor: textColor,
                                  ),
                                  SizedBox(height: 10.h),
                                  _buildCalorieMetric(
                                    label: "Remaining",
                                    value: hasTarget
                                        ? "${remainingCalories.toStringAsFixed(0)} kcal"
                                        : "--",
                                    dotColor: ColorManager.accent,
                                    textColor: calorieSecondaryText,
                                    valueColor: textColor,
                                  ),
                                  SizedBox(height: 10.h),
                                  _buildCalorieMetric(
                                    label: "Goal",
                                    value: hasTarget
                                        ? "${targetCalories.toStringAsFixed(0)} kcal"
                                        : "Not Set",
                                    dotColor: ColorManager.primary,
                                    textColor: calorieSecondaryText,
                                    valueColor: textColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!hasTarget) ...[
                          SizedBox(height: 12.h),
                          GestureDetector(
                            onTap: () => context.push(Routes.changeWeightRoute),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: (isDarkMode ? Colors.white : Colors.black).withAlpha(15),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.tune_rounded,
                                      size: 13.sp,
                                      color: isDarkMode ? ColorManager.darkPrimaryText : Colors.white),
                                  SizedBox(width: 6.w),
                                  Flexible(
                                    child: Text(
                                      'Set daily calorie target in Profile',
                                      style: TextStyle(
                                        color: isDarkMode ? ColorManager.primaryText : Colors.white,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      size: 9.sp,
                                      color: isDarkMode ? ColorManager.darkPrimaryText : Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: SizeManager.s16.h),
                  // 2. Row of Water and BMI Cards (Side-by-Side)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left: Water Card — tappable to log water
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push(Routes.addWaterRoute),
                            child: Container(
                              decoration: cardDecoration,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.water_drop_outlined, color: ColorManager.primaryText, size: 18.sp),
                                    SizedBox(width: 6.w),
                                    Text(
                                      StringsManager.water,
                                      style: TextStyle(
                                        color: lightThemeTextColor,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    // Stylized custom glass of water using CustomPaint
                                    SizedBox(
                                      width: 36.w,
                                      height: 48.h,
                                      child: CustomPaint(
                                        painter: _WaterGlassPainter(
                                          fillPercent: waterPercent,
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    consumedWater.toStringAsFixed(1),
                                                    style: TextStyle(
                                                      color: lightThemeTextColor,
                                                      fontSize: 20.sp,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 2.w),
                                              Text(
                                                "L",
                                                style: TextStyle(
                                                  color: lightThemeTextColor,
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "/ ${waterGoal.toStringAsFixed(1)} L",
                                              style: TextStyle(
                                                color: lightThemeSecondaryTextColor,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                // Horizontal progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4.r),
                                  child: LinearProgressIndicator(
                                    value: waterPercent,
                                    backgroundColor: isDarkMode ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
                                    valueColor: const AlwaysStoppedAnimation<Color>(ColorManager.primary),
                                    minHeight: 6.h,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // Right: BMI Card
                        Expanded(
                          child: Container(
                            decoration: cardDecoration,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.accessibility_new_rounded, color: ColorManager.primaryText, size: 18.sp),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'BMI',
                                      style: TextStyle(
                                        color: lightThemeTextColor,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Center(
                                  child: SizedBox(
                                    width: 110.w,
                                    height: 70.h,
                                    child: CustomPaint(
                                      painter: _BmiGaugePainter(
                                        bmi: bmi,
                                        progressColor: getProgressColor(bmi),
                                        textColor: lightThemeTextColor,
                                        isDarkMode: isDarkMode,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      getMessage(bmi),
                                      style: TextStyle(
                                        color: getProgressColor(bmi),
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        }),
    );
  }

  Widget _buildCalorieMetric({
    required String label,
    required String value,
    required Color dotColor,
    required Color textColor,
    required Color valueColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7.w,
          height: 7.w,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6.w),
        SizedBox(
          width: 72.w,
          child: Text(
            label,
            style: TextStyle(color: textColor.withAlpha(200), fontSize: 12.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(color: valueColor, fontSize: 12.sp, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _WaterGlassPainter extends CustomPainter {
  final double fillPercent;
  final bool isDarkMode;

  _WaterGlassPainter({
    required this.fillPercent,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer glass path (tapered shape)
    final glassPath = Path()
      ..moveTo(4.w, 8.h)
      ..lineTo(w - 4.w, 8.h)
      ..lineTo(w - 9.w, h - 2.h)
      ..lineTo(9.w, h - 2.h)
      ..close();

    // 1. Draw the water inside if fillPercent > 0
    if (fillPercent > 0) {
      final waterPercent = fillPercent.clamp(0.0, 1.0);
      final waterHeight = (h - 11.h) * waterPercent;
      final waterTopY = h - 2.h - waterHeight;

      // Calculate width of the water surface using linear interpolation
      final waterLeftX = 4.w + (5.w * (1.0 - waterPercent));
      final waterRightX = w - waterLeftX;

      final waterPath = Path()
        ..moveTo(waterLeftX, waterTopY)
        ..quadraticBezierTo(w / 2, waterTopY - 2.h, waterRightX, waterTopY)
        ..lineTo(w - 9.w, h - 2.h)
        ..lineTo(9.w, h - 2.h)
        ..close();

      final waterPaint = Paint()
        ..color = ColorManager.primary
        ..style = PaintingStyle.fill;

      canvas.drawPath(waterPath, waterPaint);
    }

    // 2. Draw the glass frame outline
    final framePaint = Paint()
      ..color = isDarkMode ? Colors.white30 : const Color(0xFF93C5FD).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.w
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(glassPath, framePaint);

    // 3. Draw the rim at the top of the glass
    final rimPaint = Paint()
      ..color = isDarkMode ? Colors.white30 : const Color(0xFF93C5FD).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.w;

    canvas.drawOval(
      Rect.fromLTRB(2.w, 1.h, w - 2.w, 8.h),
      rimPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterGlassPainter oldDelegate) {
    return oldDelegate.fillPercent != fillPercent || oldDelegate.isDarkMode != isDarkMode;
  }
}

class _BmiGaugePainter extends CustomPainter {
  final double bmi;
  final Color progressColor;
  final Color textColor;
  final bool isDarkMode;

  _BmiGaugePainter({
    required this.bmi,
    required this.progressColor,
    required this.textColor,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = (size.width / 2) - 8;

    final startAngle = 3.1415926535 * 145 / 180; // 145 degrees
    final sweepAngle = 3.1415926535 * 250 / 180; // 250 degrees

    // 1. Draw background track
    final trackPaint = Paint()
      ..color = isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.w
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // 2. Draw progress arc
    final percent = ((bmi - 15) / (35 - 15)).clamp(0.0, 1.0);

    if (percent > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.w
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        percent * sweepAngle,
        false,
        progressPaint,
      );

      // 3. Draw pointer dot
      final pointerAngle = startAngle + percent * sweepAngle;
      final pointerCenter = Offset(
        center.dx + radius * math.cos(pointerAngle),
        center.dy + radius * math.sin(pointerAngle),
      );

      final pointerPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pointerCenter, 5.w, pointerPaint);

      final innerDotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pointerCenter, 1.5.w, innerDotPaint);
    }

    // 4. Draw centered score text mathematically
    final textPainter = TextPainter(
      text: TextSpan(
        text: bmi.toStringAsFixed(1),
        style: TextStyle(
          color: textColor,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2 - 8.h, // Position above the bottom line of the gauge
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant _BmiGaugePainter oldDelegate) {
    return oldDelegate.bmi != bmi ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
