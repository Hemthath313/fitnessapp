import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/pages/home_page.dart';
import 'package:fitness_app/presentation/main/widgets/appbar_home.dart';
import 'package:fitness_app/presentation/main/widgets/appbar_more.dart';
import 'package:fitness_app/presentation/more/more_page.dart';
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
import 'package:fitness_app/utils/widgets/error_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'package:fitness_app/presentation/widgets/premium_upsell_banner.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  final Duration? paywallTimerDelayForTesting;
  final bool? initialShowBannerForTesting;

  const MainPage({
    super.key,
    this.paywallTimerDelayForTesting,
    this.initialShowBannerForTesting,
  });

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
    WorkoutTabPage(),
    WorkoutLogHistoryPage(),
    ProgressPage(),
    MorePage(),
  ];

  appBar() {
    if (isHomePage) {
      return const HomePageAppBarWidget();
    } else if (isMorePage) {
      return const MorePageAppBarWidget();
    }
    return null;
  }

  bool get isMorePage => _currentIndex == 4;
  bool get isProgressPage => _currentIndex == 3;
  bool get isHistoryPage => _currentIndex == 2;
  bool get isWorkoutsPage => _currentIndex == 1;
  bool get isHomePage => _currentIndex == 0;

  Timer? _paywallTimer;
  bool _showPaywallBanner = false;
  bool _bannerDismissedByUser = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialShowBannerForTesting == true) {
      _showPaywallBanner = true;
    }
    _startPaywallTimer(delay: widget.paywallTimerDelayForTesting);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check if user is authenticated before loading data
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        return; // Don't load data if user is not authenticated
      }

      NetworkService.initialize();
      Provider.of<SubscriptionProvider>(context, listen: false).refresh();

      // Defer any cold-start notification deep-link navigation until required workout/streak state is loaded
      NotificationService().deferNavigationUntilReady();

      // Initialize Push & Local Notifications
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

        // Dynamically sync scheduled workout days with active workout split without erasing free-user schedules
        final splitDays = workoutsProvider.groupedSplitWorkouts.keys;
        statisticsProvider.syncSplitSchedule(splitDays);
      } catch (e) {
        // Handle errors gracefully - don't crash the app
        print('Error loading initial data: $e');
      } finally {
        if (mounted) {
          NotificationService().markAppReady();
        }
      }

      final workouts = workoutsProvider.workouts;
      final meals = consumptionProvider.meals;
      bool isNewDay(DateTime now, DateTime lastDate) {
        final today = DateTime(now.year, now.month, now.day);
        final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        return today.isAfter(lastDay);
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
        if (isNewDay(now, lastWorkoutDateTime)) {
          await workoutsProvider.clearWorkoutsIfDayChanges(lastWorkoutDateTime);
          await workoutsProvider.fetchAndSetWorkouts();
        }
      }
    });
  }

  @override
  void dispose() {
    _paywallTimer?.cancel();
    super.dispose();
  }

  void _startPaywallTimer({Duration? delay}) {
    _paywallTimer?.cancel();
    final effectiveDelay = delay ?? const Duration(minutes: 1);
    _paywallTimer = Timer(effectiveDelay, () {
      if (!mounted) return;
      final subProvider =
          Provider.of<SubscriptionProvider?>(context, listen: false);
      final isPremium = subProvider?.isPremium ?? false;
      if (!isPremium && !_bannerDismissedByUser) {
        setState(() {
          _showPaywallBanner = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider?>(context);
    final isPremium = subProvider?.isPremium ?? false;
    final bool shouldShowBanner =
        _showPaywallBanner && !isPremium && !_bannerDismissedByUser;

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
        indicatorColor: ColorManager.primary.withValues(alpha: 0.15),
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
        child: Column(
          children: [
            if (shouldShowBanner)
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                child: PremiumUpsellBannerCard(
                  onDismiss: () {
                    setState(() {
                      _bannerDismissedByUser = true;
                      _showPaywallBanner = false;
                    });
                  },
                ),
              ),
            Expanded(
              child: ErrorBoundary(
                fallbackMessage: 'Unable to load this page',
                child: pages[_currentIndex].animate().fadeIn(duration: 500.ms),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
