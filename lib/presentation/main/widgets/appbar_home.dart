import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness_app/utils/router/router.dart';

class HomePageAppBarWidget extends StatelessWidget {
  const HomePageAppBarWidget({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '💪';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final statisticsProvider = Provider.of<StatisticsProvider>(context);
    final streak = statisticsProvider.currentStreak;

    return FutureBuilder<Map<String, dynamic>>(
      future: homeProvider.fetchUserData(),
      builder: (context, snapshot) {
        final firstName =
            (homeProvider.userData['first name'] ?? 'Champ') as String;
        final displayName = firstName.isNotEmpty ? firstName : 'Champ';

        return AppBar(
          actions: [
            // Streak badge
            GestureDetector(
              onTap: () => context.push(Routes.workoutHistoryRoute),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: 8.w),
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: streak > 0
                      ? LinearGradient(
                          colors: streak >= 7
                              ? [const Color(0xFFFF6B35), const Color(0xFFFF8C42)]
                              : [Colors.orange.shade600, Colors.amber],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: streak == 0 ? ColorManager.surfaceLight : null,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: streak > 0
                      ? [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 0,
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: streak > 0 ? Colors.white : ColorManager.textTertiary,
                      size: 18.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '$streak',
                      style: TextStyle(
                        color: streak > 0 ? Colors.white : ColorManager.textTertiary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (streak > 0) ...[
                      SizedBox(width: 2.w),
                      Text(
                        'day${streak == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
                    duration: 2000.ms,
                    delay: 1000.ms,
                    color: Colors.white.withOpacity(0.2),
                  ),
            ),
            // Premium icon
            IconButton(
              onPressed: () => context.push(Routes.premiumScreen),
              icon: Icon(
                Icons.workspace_premium_rounded,
                color: Colors.amber,
                size: SizeManager.s26,
              ),
            ),
            SizedBox(width: 4.w),
          ],
          centerTitle: false,
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Padding(
            padding:
                EdgeInsets.only(left: 8.w, top: 4.h, bottom: 4.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, $displayName ${_getGreetingEmoji()}',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  streak > 0
                      ? '🔥 $streak-day streak — keep it going!'
                      : 'Start your streak today!',
                  style: TextStyle(
                    color: streak > 0
                        ? Colors.orange.shade600
                        : ColorManager.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 500.ms);
      },
    );
  }
}
