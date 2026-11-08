import 'dart:async';
import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/pages/home_page.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/main/widgets/appbar_home.dart';
import 'package:fitness_app/presentation/main/widgets/appbar_more.dart';
import 'package:fitness_app/presentation/more/more_page.dart';
import 'package:fitness_app/presentation/progress/progress_page.dart';
import 'package:fitness_app/presentation/widgets/premium_upsell_banner.dart';
import 'package:fitness_app/presentation/widgets/update_dialog.dart';
import 'package:fitness_app/presentation/workout_logs/workout_log_history_page.dart';
import 'package:fitness_app/presentation/workouts/pages/workout_tab_page.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/services/connectivity_service.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/services/review_service.dart';
import 'package:fitness_app/services/update_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/widgets/error_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_update/in_app_update.dart' as play;
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

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
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
  bool _isCheckingUpdate = false;
  bool _isUpdateDialogOpen = false;
  bool _isMandatoryUpdateBlocked = false;
  AppUpdateInfo? _mandatoryUpdateInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    UpdateService().onUpdateReadyPrompt = _showUpdateReadySnackBar;
    if (widget.initialShowBannerForTesting == true) {
      _showPaywallBanner = true;
    }
    _startPaywallTimer(delay: widget.paywallTimerDelayForTesting);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check for App Updates (Force Update / Optional Update)
      _checkForAppUpdates();

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
        debugPrint('Error initializing NotificationService: $e');
      }


      // Increment app launch count for rating prompts
      try {
        await ReviewService().incrementAppLaunches();
      } catch (e) {
        debugPrint('Error incrementing app launches: $e');
      }

      if (!mounted) return;

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
        debugPrint('Error loading initial data: $e');
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
    WidgetsBinding.instance.removeObserver(this);
    _paywallTimer?.cancel();
    if (UpdateService().onUpdateReadyPrompt == _showUpdateReadySnackBar) {
      UpdateService().onUpdateReadyPrompt = null;
    }
    super.dispose();
  }

  bool _isUpdateReadySnackBarVisible = false;

  void _showUpdateReadySnackBar() {
    if (!mounted) return;
    if (UpdateService().isWorkoutSessionActive) return;
    if (!UpdateService().isFlexibleUpdateDownloaded) return;
    if (_isUpdateReadySnackBarVisible) return;

    _isUpdateReadySnackBarVisible = true;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('An update has been downloaded and is ready to install.'),
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: 'RESTART',
          textColor: ColorManager.primary,
          onPressed: () async {
            _isUpdateReadySnackBarVisible = false;
            if (UpdateService().isFlexibleCompletionInProgress) return;
            final success = await UpdateService().completeNativeFlexibleUpdate();
            if (!success && mounted) {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Failed to complete update. Tap to retry.'),
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'RETRY',
                    textColor: ColorManager.primary,
                    onPressed: () {
                      _showUpdateReadySnackBar();
                    },
                  ),
                ),
              );
            }
          },
        ),
      ),
    ).closed.then((_) {
      if (mounted) {
        _isUpdateReadySnackBarVisible = false;
      }
    });
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
    if (_isMandatoryUpdateBlocked) {
      final isAndroid = UpdateService().isAndroidPlatform;
      return PopScope(
        canPop: false,
        child: Scaffold(
          key: const Key('main_mandatory_update_scaffold'),
          backgroundColor: ColorManager.background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: ColorManager.darkSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ColorManager.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ColorManager.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: ColorManager.primary,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Update Required',
                        key: Key('main_update_required_title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _mandatoryUpdateInfo?.releaseNotes.isNotEmpty == true
                            ? _mandatoryUpdateInfo!.releaseNotes
                            : 'A mandatory update is required to continue using Gym Buddy. Please update ${isAndroid ? 'on Google Play' : 'in the App Store'}.',
                        key: const Key('main_update_required_message'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          key: const Key('main_update_store_button'),
                          onPressed: () async {
                            final info = _mandatoryUpdateInfo;
                            if (isAndroid && info != null && info.canUsePlayStoreImmediateUpdate) {
                              final res = await UpdateService().performNativeImmediateUpdate();
                              if (res == play.AppUpdateResult.success) {
                                if (mounted) {
                                  setState(() {
                                    _isMandatoryUpdateBlocked = false;
                                  });
                                }
                                return;
                              }
                            }
                            await UpdateService().openStore(customUrl: _mandatoryUpdateInfo?.updateUrl);
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text(
                            isAndroid ? 'Update on Google Play' : 'Update App',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForAppUpdates(isAppResume: true);
    }
  }

  Future<void> _checkForAppUpdates({bool isAppResume = false}) async {
    if (_isCheckingUpdate || !mounted) return;
    _isCheckingUpdate = true;

    try {
      final updateInfo = await UpdateService().checkForUpdates();
      if (!mounted) return;

      final bool isAndroid = UpdateService().isAndroidPlatform;

      if (updateInfo.isForceUpdate) {
        if (isAndroid) {
          // Android: Native Google Play immediate update (No custom UpdateDialog on Android!)
          if (updateInfo.canUsePlayStoreImmediateUpdate) {
            final result = await UpdateService().performNativeImmediateUpdate();
            if (result == play.AppUpdateResult.success) {
              if (mounted) {
                setState(() {
                  _isMandatoryUpdateBlocked = false;
                });
              }
              return;
            }
          }
          // Immediate update cancelled, denied, or unavailable: fallback to store & block UI
          await UpdateService().openStore(customUrl: updateInfo.updateUrl);
          if (mounted) {
            setState(() {
              _isMandatoryUpdateBlocked = true;
              _mandatoryUpdateInfo = updateInfo;
            });
          }
          return;
        } else {
          // iOS: Show custom UpdateDialog and enforce blocking
          if (mounted) {
            setState(() {
              _isMandatoryUpdateBlocked = true;
              _mandatoryUpdateInfo = updateInfo;
            });
          }
          if (!_isUpdateDialogOpen && !UpdateService().isDialogOpen) {
            _isUpdateDialogOpen = true;
            UpdateService().isDialogOpen = true;
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext dialogContext) {
                return UpdateDialog(
                  isForceUpdate: true,
                  isRecommended: updateInfo.isRecommended,
                  releaseNotes: updateInfo.releaseNotes,
                  updateUrl: updateInfo.updateUrl,
                  canUsePlayStoreImmediateUpdate: false,
                  canUsePlayStoreFlexibleUpdate: false,
                );
              },
            );
            _isUpdateDialogOpen = false;
            UpdateService().isDialogOpen = false;
          }
        }
      } else {
        // Condition resolved or no mandatory update
        if (_isMandatoryUpdateBlocked && mounted) {
          setState(() {
            _isMandatoryUpdateBlocked = false;
            _mandatoryUpdateInfo = null;
          });
        }

        if (updateInfo.hasUpdate) {
          if (isAndroid) {
            // Android: Native Google Play flexible update
            if (updateInfo.canUsePlayStoreFlexibleUpdate &&
                UpdateService().shouldPromptOptionalUpdate) {
              UpdateService().markOptionalUpdateAttempted();
              unawaited(UpdateService().startNativeFlexibleUpdate(
                fallbackUrl: updateInfo.updateUrl,
              ));
            }
          } else {
            // iOS: Show custom UpdateDialog if not dismissed this session
            final bool shouldSkipOptional = !UpdateService().shouldPromptOptionalUpdate;

            if (!shouldSkipOptional && !_isUpdateDialogOpen && !UpdateService().isDialogOpen) {
              UpdateService().markOptionalUpdateAttempted();
              _isUpdateDialogOpen = true;
              UpdateService().isDialogOpen = true;
              await showDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext dialogContext) {
                  return UpdateDialog(
                    isForceUpdate: false,
                    isRecommended: updateInfo.isRecommended,
                    releaseNotes: updateInfo.releaseNotes,
                    updateUrl: updateInfo.updateUrl,
                    canUsePlayStoreImmediateUpdate: false,
                    canUsePlayStoreFlexibleUpdate: false,
                  );
                },
              );
              _isUpdateDialogOpen = false;
              UpdateService().isDialogOpen = false;
              UpdateService().markOptionalUpdateDismissed();
            }
          }
        } else {
          // If user updated and returned, dismiss any open dialog
          if ((_isUpdateDialogOpen || UpdateService().isDialogOpen) && mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _isUpdateDialogOpen = false;
            UpdateService().isDialogOpen = false;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates in MainPage: $e');
    } finally {
      _isCheckingUpdate = false;
    }
  }
}
