import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/presentation/widgets/update_dialog.dart';
import 'package:fitness_app/services/connectivity_service.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/services/update_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_update/in_app_update.dart' as play;
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Pure routing resolver based on authenticated user, onboarding status, and email verification.
  /// Guarantees that unauthenticated, unverified, or unknown-onboarding users are safely routed.
  static String determineInitialRoute({
    required User? user,
    required bool? hasAgeParameter,
  }) {
    final emailIsVerified = user?.emailVerified ?? false;
    if (user != null && hasAgeParameter == true && emailIsVerified) {
      return Routes.mainRoute;
    } else if (user != null &&
        hasAgeParameter == false &&
        emailIsVerified == true) {
      return Routes.addDataRoute;
    } else {
      return Routes.boardingRoute;
    }
  }

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isOfflineBlocked = false;
  bool _isRetrying = false;
  bool _hasRetryError = false;
  bool _isMandatoryUpdateBlocked = false;
  AppUpdateInfo? _mandatoryUpdateInfo;
  Timer? _navigationTimer;
  Timer? _offlineRetryTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Request notification permission immediately on app launch
    try {
      NotificationService().initialize();
    } catch (e) {
      debugPrint('Error initializing notifications on launch: $e');
    }

    // Animation controller (Runs only once)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    // Bounce scale effect for logo
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.6, end: 1.2)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 70),
      TweenSequenceItem(
          tween: Tween(begin: 1.2, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
    ]).animate(_controller);

    // Fade-in effect (Runs once)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Navigate to home screen after 3 seconds
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        navigate();
      }
    });
  }

  void _startObservingConnectivity() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        NetworkService.onConnectivityChanged.listen((results) async {
      final hasInterface = results.any(
        (r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet,
      );
      if (!hasInterface) return;

      // Validate actual uplink before triggering retry
      final hasInternet = await NetworkService.hasInternetAccess();
      if (!hasInternet) return;

      if (mounted && _isOfflineBlocked && !_isRetrying) {
        await _retryVerification();
      }
    });

    _offlineRetryTimer?.cancel();
    _offlineRetryTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted || !_isOfflineBlocked || _isRetrying) return;
      final hasInternet = await NetworkService.hasInternetAccess();
      if (hasInternet && mounted && _isOfflineBlocked && !_isRetrying) {
        await _retryVerification();
      }
    });
  }

  Future<void> _retryVerification() async {
    if (_isRetrying || !mounted) return;

    setState(() {
      _isRetrying = true;
      _hasRetryError = false;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null || !user.emailVerified) {
        _connectivitySubscription?.cancel();
        _offlineRetryTimer?.cancel();
        context.go(Routes.boardingRoute);
        return;
      }

      final activeUid = user.uid;

      // Call loadUserData to query Firestore with bounded timeout
      await authProvider.loadUserData();

      if (!mounted) return;

      // Prevent stale response if user switched during async gap
      if (authProvider.user?.uid != activeUid) {
        return;
      }

      final resolvedHasAge = authProvider.hasAgeParameter;
      if (resolvedHasAge != null) {
        _connectivitySubscription?.cancel();
        _offlineRetryTimer?.cancel();
        final destination = SplashScreen.determineInitialRoute(
          user: authProvider.user,
          hasAgeParameter: resolvedHasAge,
        );
        context.go(destination);
      } else {
        setState(() {
          _isRetrying = false;
          _hasRetryError = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRetrying = false;
          _hasRetryError = true;
        });
      }
    } finally {
      if (mounted && _isRetrying) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  Future<void> navigate() async {
    if (!mounted) return;
    debugPrint('SplashScreen: Starting navigation logic');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for initial auth state to load (with timeout)
    debugPrint('SplashScreen: Waiting for AuthProvider.isLoading (current: ${authProvider.isLoading})');
    int attempts = 0;
    while (authProvider.isLoading && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      attempts++;
    }
    debugPrint('SplashScreen: Out of wait loop. Attempts: $attempts, isLoading: ${authProvider.isLoading}');

    // Only load user data if not yet resolved (e.g. autoInitialize: false in unit test)
    if (authProvider.user != null && authProvider.hasAgeParameter == null) {
      debugPrint('SplashScreen: Calling authProvider.loadUserData()');
      await authProvider.loadUserData();
      debugPrint('SplashScreen: loadUserData() completed');
    }

    if (!mounted) return;

    // Wait a brief frame to ensure state is updated
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    // Check whether an update is required before proceeding
    try {
      final updateInfo = await UpdateService().checkForUpdates();
      if (!mounted) return;

      final bool isAndroid = UpdateService().isAndroidPlatform;

      if (updateInfo.isForceUpdate) {
        if (isAndroid) {
          // Android: Native Google Play immediate update (AppUpdateType.immediate)
          // No custom UpdateDialog on Android!
          if (updateInfo.canUsePlayStoreImmediateUpdate) {
            final result = await UpdateService().performNativeImmediateUpdate();
            if (result == play.AppUpdateResult.success) {
              return; // Update was applied
            }
          }
          // If immediate update was not allowed, failed, or canceled by user:
          // Fallback to update_url_android and keep mandatory restriction in place
          await UpdateService().openStore(customUrl: updateInfo.updateUrl);

          if (mounted) {
            setState(() {
              _isMandatoryUpdateBlocked = true;
              _mandatoryUpdateInfo = updateInfo;
            });
          }
          return; // Block navigation completely while mandatory update is pending
        } else {
          // iOS: Show existing custom UpdateDialog
          if (!UpdateService().isDialogOpen) {
            UpdateService().isDialogOpen = true;
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext dialogContext) {
                return UpdateDialog(
                  isForceUpdate: true,
                  releaseNotes: updateInfo.releaseNotes,
                  updateUrl: updateInfo.updateUrl,
                  canUsePlayStoreImmediateUpdate: false,
                  canUsePlayStoreFlexibleUpdate: false,
                );
              },
            );
            UpdateService().isDialogOpen = false;
          }
          return; // Block navigation completely while mandatory update is pending
        }
      } else if (updateInfo.hasUpdate) {
        if (isAndroid) {
          // Android: Native Google Play flexible update (AppUpdateType.flexible)
          // Do NOT show custom UpdateDialog on Android!
          // Optional updates must NOT block startup or Dashboard navigation!
          if (updateInfo.canUsePlayStoreFlexibleUpdate && UpdateService().shouldPromptOptionalUpdate) {
            UpdateService().markOptionalUpdateAttempted();
            unawaited(UpdateService().startNativeFlexibleUpdate(
              fallbackUrl: updateInfo.updateUrl,
            ));
          }
          // Proceed to normal navigation without blocking!
        } else {
          // iOS: Show existing custom UpdateDialog if not dismissed this session
          if (UpdateService().shouldPromptOptionalUpdate && !UpdateService().isDialogOpen) {
            UpdateService().markOptionalUpdateAttempted();
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
            UpdateService().isDialogOpen = false;
            UpdateService().markOptionalUpdateDismissed();
          }
          if (!mounted) return;
        }
      }
    } catch (e) {
      debugPrint('SplashScreen update check skipped: $e');
    }

    final user = authProvider.user;
    final hasAgeParameter = authProvider.hasAgeParameter;
    final emailIsVerified = user?.emailVerified ?? false;
    
    debugPrint('SplashScreen: Final state - user: ${user?.uid}, hasAge: $hasAgeParameter, verified: $emailIsVerified');

    if (!mounted) return;

    // Case 1: Unauthenticated user -> boarding
    if (user == null) {
      context.go(Routes.boardingRoute);
      return;
    }

    // Case 2: Unverified email -> boarding (safeguards preserved)
    if (!emailIsVerified) {
      context.go(Routes.boardingRoute);
      return;
    }

    // Case 3: User is authenticated and email verified:
    // If onboarding status is already known (either true -> mainRoute or false -> addDataRoute)
    if (hasAgeParameter != null) {
      final destination = SplashScreen.determineInitialRoute(
        user: user,
        hasAgeParameter: hasAgeParameter,
      );
      context.go(destination);
      return;
    }

    // Case 4: Authenticated & email-verified, but onboarding status cannot be verified offline
    final hasInternet = await NetworkService.hasInternetAccess();
    if (!mounted) return;
    if (!hasInternet) {
      setState(() {
        _isOfflineBlocked = true;
        _isRetrying = false;
        _hasRetryError = false;
      });
      _startObservingConnectivity();
      return;
    }

    // If device reports active internet, attempt verification
    await _retryVerification();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isMandatoryUpdateBlocked) {
      _checkMandatoryUpdateOnResume();
    }
  }

  Future<void> _checkMandatoryUpdateOnResume() async {
    try {
      final info = await UpdateService().checkForUpdates();
      if (!info.isForceUpdate) {
        if (mounted) {
          setState(() {
            _isMandatoryUpdateBlocked = false;
            _mandatoryUpdateInfo = null;
          });
          navigate();
        }
      } else {
        if (UpdateService().isAndroidPlatform && info.canUsePlayStoreImmediateUpdate) {
          await UpdateService().performNativeImmediateUpdate(fallbackUrl: info.updateUrl);
        }
      }
    } catch (e) {
      debugPrint('SplashScreen: Error rechecking update on resume: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navigationTimer?.cancel();
    _offlineRetryTimer?.cancel();
    _connectivitySubscription?.cancel();
    _controller.dispose(); // Clean up animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background, // Pure black background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with bounce & fade effect (happens only once)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value, // Bounce effect
                    child: Opacity(
                      opacity: _fadeAnimation.value, // Fade-in effect (one time)
                      child: Image.asset(
                        'assets/images/applogo.png', // Replace with your logo
                        width: 260, // Adjusted size for balance
                      ),
                    ),
                  );
                },
              ),

              if (_isOfflineBlocked) ...[
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: ColorManager.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _hasRetryError
                          ? Colors.red.withValues(alpha: 0.5)
                          : ColorManager.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_hasRetryError ? Colors.red : ColorManager.primary)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _hasRetryError
                              ? Icons.error_outline_rounded
                              : Icons.wifi_off_rounded,
                          color: _hasRetryError ? Colors.redAccent : ColorManager.primary,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No internet connection',
                        key: Key('splash_offline_title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We need an internet connection to verify your profile. Please reconnect to continue.',
                        key: const Key('splash_offline_message'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "We'll automatically retry when you're back online.",
                        key: const Key('splash_offline_supporting_text'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ColorManager.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_isRetrying) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ColorManager.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Verifying profile...',
                              key: const Key('splash_retrying_indicator'),
                              style: TextStyle(
                                color: ColorManager.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_hasRetryError && !_isRetrying) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Verification failed. Tap Retry to try again.',
                          key: Key('splash_retry_error_text'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          key: const Key('splash_offline_retry_button'),
                          onPressed: _retryVerification,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text(
                            'Retry Now',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (_isMandatoryUpdateBlocked) ...[
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: ColorManager.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ColorManager.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ColorManager.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: ColorManager.primary,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Update Required',
                        key: Key('splash_update_required_title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'A mandatory update is required to continue using Gym Buddy. Please update on Google Play.',
                        key: const Key('splash_update_required_message'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        key: const Key('splash_update_store_button'),
                        onPressed: () async {
                          final info = _mandatoryUpdateInfo;
                          if (info != null && info.canUsePlayStoreImmediateUpdate) {
                            final res = await UpdateService().performNativeImmediateUpdate();
                            if (res == play.AppUpdateResult.success) return;
                          }
                          await UpdateService().openStore(customUrl: _mandatoryUpdateInfo?.updateUrl);
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text(
                          'Update on Google Play',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
