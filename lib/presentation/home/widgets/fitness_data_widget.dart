import 'dart:math' as math;
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';

class FitnessDataWidget extends StatefulWidget {
  const FitnessDataWidget({
    super.key,
  });

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

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsumptionProvider>(
      builder: (context, consumptionProvider, _) => FutureBuilder<
              Map<String, dynamic>>(
          future: _userDataFuture,
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
              final bmrVal = userData['bmr'] as double? ?? 0.0;
              final bmr = bmrVal == 0.0 ? 2000.0 : bmrVal;
              final bmi = userData['bmi'] as double? ?? 0.0;
              Color getProgressColor(double bmi) {
                var isNormalBMI = bmi >= 18.5 && bmi <= 25;
                var isUnderOrOverWeight =
                    (bmi >= 17 && bmi < 18.5) || (bmi > 25 && bmi <= 30);
                if (isNormalBMI) {
                  return const Color(0xFF10B981); // Emerald Green
                } else if (isUnderOrOverWeight) {
                  return const Color(0xFFF59E0B); // Amber / Yellow
                } else {
                  return const Color(0xFFEF4444); // Red
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
            final calorieCardDecoration = isDarkMode 
                ? BoxDecoration(
                    color: ColorManager.surface,
                    borderRadius: BorderRadius.circular(18.r),
                  )
                : BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1B55E2), // Rich Royal Blue
                        Color(0xFF3972F6), // Vibrant Medium Blue
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B55E2).withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  );

            // Other cards (Water, BMI)
            final cardBg = ColorManager.surface;
            final cardDecoration = BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            );

            final textColor = isDarkMode ? ColorManager.textPrimary : Colors.white;
            final calorieSecondaryText = isDarkMode ? ColorManager.textSecondary : const Color(0xFFDCE7FF);
            final calorieSmallLabelText = isDarkMode ? ColorManager.textSecondary : const Color(0xFFEAF1FF);
            
            final lightThemeTextColor = isDarkMode ? ColorManager.textPrimary : const Color(0xFF1E2140);
            final lightThemeSecondaryTextColor = isDarkMode ? ColorManager.textSecondary : const Color(0xFF6B7280);

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
                              percent: (bmr > 0 ? (consumptionProvider.consumedCalories / bmr) : 0.0).clamp(0.0, 1.0),
                              progressColor: isDarkMode ? ColorManager.primary : Colors.white,
                              backgroundColor: isDarkMode ? Colors.white10 : Colors.white24,
                              animateFromLastPercent: true,
                              animation: true,
                              center: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    consumptionProvider.consumedCalories.toString(),
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "/ ${bmr.toStringAsFixed(0)} kcal",
                                    style: TextStyle(
                                      color: calorieSmallLabelText,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Right Side: Metrics List
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCalorieMetric(
                                  label: "Consumed",
                                  value: "${consumptionProvider.consumedCalories} kcal",
                                  dotColor: isDarkMode ? const Color(0xFF93C5FD) : const Color(0xFFEAF1FF), 
                                  textColor: calorieSecondaryText,
                                  valueColor: textColor,
                                ),
                                SizedBox(height: 10.h),
                                _buildCalorieMetric(
                                  label: "Remaining",
                                  value: "${(bmr - consumptionProvider.consumedCalories).clamp(0.0, double.infinity).toStringAsFixed(0)} kcal",
                                  dotColor: isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFFDCE7FF),
                                  textColor: calorieSecondaryText,
                                  valueColor: textColor,
                                ),
                                SizedBox(height: 10.h),
                                _buildCalorieMetric(
                                  label: "Goal",
                                  value: "${bmr.toStringAsFixed(0)} kcal",
                                  dotColor: isDarkMode ? ColorManager.primary : Colors.white,
                                  textColor: calorieSecondaryText,
                                  valueColor: textColor,
                                ),
                              ],
                            ),
                          ],
                        ),
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
                                    Icon(Icons.water_drop_outlined, color: ColorManager.primary, size: 18.sp),
                                    SizedBox(width: 6.w),
                                    Text(
                                      StringsManager.water,
                                      style: TextStyle(
                                        color: lightThemeTextColor,
                                        fontSize: 15.sp,
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
                                          fillPercent: (consumptionProvider.waterADay / 2.5),
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 14.w),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              consumptionProvider.waterADay.toStringAsFixed(1),
                                              style: TextStyle(
                                                color: lightThemeTextColor,
                                                fontSize: 22.sp,
                                                fontWeight: FontWeight.bold,
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
                                        Text(
                                          "/ 2.5 L",
                                          style: TextStyle(
                                            color: lightThemeSecondaryTextColor,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                // Horizontal progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4.r),
                                  child: LinearProgressIndicator(
                                    value: (consumptionProvider.waterADay / 2.5).clamp(0.0, 1.0),
                                    backgroundColor: isDarkMode ? Colors.white10 : Colors.grey.withOpacity(0.1),
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
                                    Icon(Icons.accessibility_new_rounded, color: ColorManager.primary, size: 18.sp),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'BMI',
                                      style: TextStyle(
                                        color: lightThemeTextColor,
                                        fontSize: 15.sp,
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
                                  child: Text(
                                    getMessage(bmi),
                                    style: TextStyle(
                                      color: getProgressColor(bmi),
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
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
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        SizedBox(
          width: 85.w,
          child: Text(
            label,
            style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13.sp),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 13.sp, fontWeight: FontWeight.bold),
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
        ..color = const Color(0xFF2F6BFF) // Same vibrant blue
        ..style = PaintingStyle.fill;

      canvas.drawPath(waterPath, waterPaint);
    }

    // 2. Draw the glass frame outline
    final framePaint = Paint()
      ..color = isDarkMode ? Colors.white30 : const Color(0xFF93C5FD).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.w
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(glassPath, framePaint);

    // 3. Draw the rim at the top of the glass
    final rimPaint = Paint()
      ..color = isDarkMode ? Colors.white30 : const Color(0xFF93C5FD).withOpacity(0.5)
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
      ..color = isDarkMode ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.12)
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
          fontSize: 22.sp,
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
