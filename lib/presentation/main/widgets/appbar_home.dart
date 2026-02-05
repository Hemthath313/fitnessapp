import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness_app/utils/router/router.dart';

class HomePageAppBarWidget extends StatelessWidget {
  const HomePageAppBarWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final statisticsProvider = Provider.of<StatisticsProvider>(context);

    return FutureBuilder<Map<String, dynamic>>(
        future: homeProvider.fetchUserData(),
        builder: (context, snapshot) {
          return AppBar(
            actions: [
              // Streak indicator
              Padding(
                padding: const EdgeInsets.only(right: PaddingManager.p8),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: statisticsProvider.currentStreak > 0
                          ? Colors.orange
                          : Colors.grey,
                      size: SizeManager.s24,
                    ),
                    SizedBox(width: SizeManager.s4.w),
                    Text(
                      '${statisticsProvider.currentStreak}',
                      style: TextStyle(
                        color: ColorManager.white,
                        fontSize: SizeManager.s16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push(Routes.premiumScreen),
                icon: Icon(
                  Icons.workspace_premium,
                  color: Colors.amber, // Gold color for premium
                  size: SizeManager.s28,
                ),
              ),
              SizedBox(width: SizeManager.s12.w),
            ],
            centerTitle: false,
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: SizeManager.s50,
            automaticallyImplyLeading: false,
            elevation: SizeManager.s0,
            title: Padding(
              padding: const EdgeInsets.all(PaddingManager.p12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    StringsManager.welcomeBack,
                    textAlign: TextAlign.left,
                    style: StyleManager.homeTitleNameTextStyle,
                  ),
                  Text(
                    '${(homeProvider.userData['first name'] ?? 'Guest')} ${(homeProvider.userData['surname'] ?? '')}!',
                    style: StyleManager.homeTitleDataTextStyle,
                  )
                ],
              ),
            ),
          ).animate().fadeIn(
                duration: 500.ms,
              );
        });
  }
}
