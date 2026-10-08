import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/explore/explore_page.dart';
import 'package:fitness_app/presentation/home/pages/home_page.dart';
import 'package:fitness_app/presentation/main/widgets/appbar_consumption.dart';
import 'package:fitness_app/presentation/main/widgets/appbar_home.dart';
import 'package:fitness_app/presentation/main/widgets/appbar_custom_workouts.dart';
import 'package:fitness_app/presentation/main/widgets/appbar_more.dart';
import 'package:fitness_app/presentation/more/more_page.dart';
import 'package:fitness_app/presentation/custom_workouts/custom_workouts_page.dart';
import 'package:fitness_app/presentation/progress/progress_page.dart';
import 'package:fitness_app/presentation/workouts/pages/workout_tab_page.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/services/connectivity_service.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/services/update_service.dart';
import 'package:fitness_app/services/review_service.dart';
import 'package:fitness_app/presentation/widgets/update_dialog.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/presentation/workout_logs/workout_log_history_page.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/utils/widgets/error_boundary.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  var _currentIndex = 0;
  ontap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> pages = const [
    HomePage(),
    ExploreWidget(),
    WorkoutLogHistoryPage(),
    ProgressPage(),
    MorePage(),
  ];

  appBar() {
    if (isHomePage) {
      return const HomePageAppBarWidget();
    } else if (isExplorePage) {
      return const ConsumptionPageAppBarWidget();
    } else if (isMorePage) {
      return const MorePageAppBarWidget();
    }
    return null;
  }

  bool get isMorePage => _currentIndex == 4;
  bool get isProgressPage => _currentIndex == 3;
  bool get isHistoryPage => _currentIndex == 2;
  bool get isExplorePage => _currentIndex == 1;
  bool get isHomePage => _currentIndex == 0;

  @override
  void initState() {
    super.initState();
    _startPaywallTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check if user is authenticated before loading data
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        return; // Don't load data if user is not authenticated
      }

      NetworkService.initialize();
      Provider.of<SubscriptionProvider>(context, listen: false).refresh();

      // Initialize Push Notifications
      try {
        await NotificationService().initialize();
      } catch (e) {
        print('Error initializing NotificationService: $e');
      }

      // Check for App Updates
      try {
        final updateInfo = await UpdateService().checkForUpdates();
        if (updateInfo.hasUpdate && mounted) {
          showDialog(
            context: context,
            barrierDismissible: !updateInfo.isForceUpdate,
            builder: (BuildContext context) {
              return UpdateDialog(
                isForceUpdate: updateInfo.isForceUpdate,
                releaseNotes: updateInfo.releaseNotes,
                updateUrl: updateInfo.updateUrl,
              );
            },
          );
        }
      } catch (e) {
        print('Error checking for updates: $e');
      }

      // Increment app launch count for rating prompts
      try {
        await ReviewService().incrementAppLaunches();
      } catch (e) {
        print('Error incrementing app launches: $e');
      }

      final consumptionProvider =
          Provider.of<ConsumptionProvider>(context, listen: false);
      final workoutsProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      final statisticsProvider =
          Provider.of<StatisticsProvider>(context, listen: false);

      try {
        // Load statistics
        await statisticsProvider.loadStreakData();

        // FIRST: Check and clear water for new day BEFORE loading data
        await consumptionProvider.clearWaterIfNeeded();

        // THEN: Load fresh data after potential reset
        await consumptionProvider.fetchAndSetMeals();
        await consumptionProvider.fetchAndSetWater();
        await workoutsProvider.fetchAndSetWorkouts();
        await workoutsProvider.getProgressPercent();
      } catch (e) {
        // Handle errors gracefully - don't crash the app
        print('Error loading initial data: $e');
      }

      final workouts = workoutsProvider.workouts;
      final meals = consumptionProvider.meals;
      bool isNewDay(DateTime now, DateTime lastDate) {
        return now.year > lastDate.year ||
            now.month > lastDate.month ||
            now.day > lastDate.day;
      }

      if (meals.isNotEmpty) {
        final lastMealDateTime = meals.last.dateTime;
        if (isNewDay(DateTime.now(), lastMealDateTime)) {
          await consumptionProvider.clearMealsIfNeeded();
          await consumptionProvider.fetchAndSetMeals();
        }
      }

      if (workouts.isNotEmpty) {
        final lastWorkoutDateTime = workouts.last.dateTime;
        final now = DateTime.now();
        if (now.year > lastWorkoutDateTime.year ||
            now.month > lastWorkoutDateTime.month ||
            now.day > lastWorkoutDateTime.day) {
          await workoutsProvider.clearWorkoutsIfDayChanges(lastWorkoutDateTime);
          await workoutsProvider.fetchAndSetWorkouts();
        }
      }
    });
  }

  void _startPaywallTimer() {
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
        if (!subProvider.isPremium) {
          _showPaywallDialog();
        }
      }
    });
  }

  void _showPaywallDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: ColorManager.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 24.h),
                    decoration: BoxDecoration(
                      color: ColorManager.textTertiary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 32.sp),
                    SizedBox(width: 8.w),
                    Text('Unlock Premium', style: TextStyle(color: ColorManager.textPrimary, fontSize: 24.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 16.h),
                Text('Take your fitness to the next level with:', textAlign: TextAlign.center, style: TextStyle(color: ColorManager.textSecondary, fontSize: 16.sp)),
                SizedBox(height: 24.h),
                _buildDialogFeaturePoint(Icons.auto_awesome, 'Unlimited AI Workouts & Splits', Colors.tealAccent),
                _buildDialogFeaturePoint(Icons.fitness_center_rounded, 'Barbell Plate Math & Visualizer', Colors.amberAccent),
                _buildDialogFeaturePoint(Icons.file_download_outlined, 'Workout History & CSV Export', Colors.blueAccent),
                _buildDialogFeaturePoint(Icons.ads_click, 'Ad-Free Training Experience', Colors.greenAccent),
                SizedBox(height: 32.h),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(Routes.premiumScreen);
                  },
                  child: Text('View Premium Options', style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Maybe Later', style: TextStyle(color: ColorManager.textTertiary, fontSize: 14.sp)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogFeaturePoint(IconData icon, String text, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(child: Text(text, style: TextStyle(color: ColorManager.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: appBar() != null
          ? PreferredSize(
              preferredSize: Size(
                double.infinity,
                SizeManager.s60.h,
              ),
              child: appBar()!,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: ontap,
        backgroundColor: ColorManager.surface,
        indicatorColor: ColorManager.primary.withOpacity(0.15),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 400),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: ColorManager.textTertiary),
            selectedIcon: Icon(Icons.home_rounded, color: ColorManager.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined, color: ColorManager.textTertiary),
            selectedIcon: Icon(Icons.fitness_center_rounded, color: ColorManager.primary),
            label: 'Workouts',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined, color: ColorManager.textTertiary),
            selectedIcon: Icon(Icons.calendar_month_rounded, color: ColorManager.primary),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined, color: ColorManager.textTertiary),
            selectedIcon: Icon(Icons.insights_rounded, color: ColorManager.primary),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: ColorManager.textTertiary),
            selectedIcon: Icon(Icons.person_rounded, color: ColorManager.primary),
            label: 'Profile',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ErrorBoundary(
          child: pages[_currentIndex].animate().fadeIn(duration: 500.ms),
          fallbackMessage: 'Unable to load this page',
        ),
      ),
    );
  }
}
