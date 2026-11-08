import 'package:fitness_app/presentation/profile/providers/profile_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MeasurementLineChart extends StatelessWidget {
  final String title;
  final String measurementType;
  final String unit;

  const MeasurementLineChart({
    super.key,
    required this.title,
    required this.measurementType,
    this.unit = 'cm',
  });

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: PaddingManager.p12, vertical: PaddingManager.p8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8.w, bottom: 8.h),
              child: Text(
                title,
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FutureBuilder<List<FlSpot>>(
                future: profileProvider.fetchMeasurementSpots(measurementType),
                builder: (context, snapshot) {
                  final spots = snapshot.data ?? [];
                  
                  if (spots.isEmpty) {
                    return Container(
                      height: SizeManager.s150.h,
                      width: deviceWidth,
                      decoration: BoxDecoration(
                        color: ColorManager.surface,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: ColorManager.surfaceLight),
                      ),
                      child: Center(
                        child: Text(
                          'No history data yet.\nUpdate measurements in settings.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp),
                        ),
                      ),
                    );
                  }

                  return Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: ColorManager.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: ColorManager.surfaceLight),
                    ),
                    height: SizeManager.s200.h,
                    width: deviceWidth,
                    child: LineChart(
                      LineChartData(
                        minX: spots.first.x,
                        maxX: spots.last.x + 0.1,
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const months = [
                                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                ];
                                if (value < 1 || value > 12) return const Text('');
                                return Text(
                                  months[value.toInt() - 1],
                                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35.w,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(0),
                                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: ColorManager.divider,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            dotData: FlDotData(show: true),
                            color: ColorManager.primary,
                            barWidth: 2.w,
                            belowBarData: BarAreaData(
                              show: true,
                              color: ColorManager.primary.withValues(alpha: 0.1),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }
}
