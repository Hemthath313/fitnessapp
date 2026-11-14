import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/profile/profile_data.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness_app/utils/router/router.dart';

class HomePageAppBarWidget extends StatefulWidget {
  const HomePageAppBarWidget({super.key});

  @override
  State<HomePageAppBarWidget> createState() => _HomePageAppBarWidgetState();
}

class _HomePageAppBarWidgetState extends State<HomePageAppBarWidget> {
  Future<Map<String, dynamic>>? _userDataFuture;

  @override
  void initState() {
    super.initState();
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    if (homeProvider.userData.isEmpty) {
      _userDataFuture = homeProvider.fetchUserData();
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Selector2<HomeProvider, StatisticsProvider,
        ({String displayName, int streak, int freezes})>(
      selector: (_, homeProvider, statsProvider) {
        final firstName =
            (homeProvider.userData['first name'] ?? '').toString().trim();
        final displayName =
            firstName.isNotEmpty ? firstName : ProfileData.fallbackName;
        return (
          displayName: displayName,
          streak: statsProvider.currentStreak,
          freezes: statsProvider.freezesLeftThisMonth,
        );
      },
      builder: (context, data, _) {
        final displayName = data.displayName;
        final streak = data.streak;
        final freezes = data.freezes;

        final homeProvider = Provider.of<HomeProvider>(context, listen: false);
        if (homeProvider.userData.isNotEmpty || _userDataFuture == null) {
          return _buildAppBar(context, displayName, streak, freezes);
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            final fetchedName =
                (snapshot.data?['first name'] ?? displayName).toString().trim();
            final name = fetchedName.isNotEmpty ? fetchedName : displayName;
            return _buildAppBar(context, name, streak, freezes);
          },
        );
      },
    );
  }

  Widget _buildAppBar(
      BuildContext context, String displayName, int streak, int freezes) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      titleSpacing: 20.w,
      title: Row(
        children: [
          // Avatar -> Edit Profile. (It used to open the sign-up data screen.)
          GestureDetector(
            key: const Key('appbar_profile_button'),
            onTap: () => context.push(Routes.editProfileRoute),
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ColorManager.primaryDark, ColorManager.primary],
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: ColorManager.onMint,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()},',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayName,
                    maxLines: 1,
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Streak chip (static: no looping animation)
        RepaintBoundary(
          child: Semantics(
            button: true,
            excludeSemantics: true,
            label: streak > 0
                ? '$streak day streak, $freezes streak ${freezes == 1 ? 'freeze' : 'freezes'} left. Opens workout history'
                : 'No streak yet. Opens workout history',
            child: GestureDetector(
          onTap: () => context.push(Routes.workoutHistoryRoute),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 44.h,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                decoration: BoxDecoration(
                  // Streak uses the calorie/energy coral.
                  color: streak > 0
                      ? ColorManager.calorie.withValues(alpha: 0.14)
                      : ColorManager.chipBackground,
                  borderRadius: BorderRadius.circular(AppRadius.pill.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: streak > 0
                          ? ColorManager.calorieText
                          : ColorManager.textTertiary,
                      size: 18.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '$streak',
                      style: TextStyle(
                        color: streak > 0
                            ? ColorManager.textPrimary
                            : ColorManager.textTertiary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (streak > 0) ...[
                      SizedBox(width: 3.w),
                      Text(
                        'day${streak == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Streak freezes left this month (protect a missed day).
                      if (freezes > 0) ...[
                        SizedBox(width: 6.w),
                        Icon(Icons.ac_unit_rounded,
                            key: const Key('streak_freeze_indicator'),
                            size: 13.sp,
                            color: ColorManager.waterText),
                        Text(
                          '$freezes',
                          style: TextStyle(
                            color: ColorManager.waterText,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        )),
        ),
        SizedBox(width: 8.w),
        // Premium
        IconButton(tooltip: 'Go Premium', 
          onPressed: () => context.push(Routes.premiumScreen),
          style: IconButton.styleFrom(
            backgroundColor: ColorManager.premium.withValues(alpha: 0.16),
            minimumSize: Size(44.w, 44.w),
          ),
          icon: Icon(
            Icons.workspace_premium_rounded,
            color: ColorManager.warningText,
            size: 22.sp,
          ),
        ),
        SizedBox(width: 20.w),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }
}
