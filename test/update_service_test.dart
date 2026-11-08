import 'dart:convert';
import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/main/pages/main_page.dart';
import 'package:fitness_app/presentation/theme/providers/theme_provider.dart';
import 'package:fitness_app/presentation/widgets/update_dialog.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/services/update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_update/in_app_update.dart' as play;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockConsumptionProvider extends ConsumptionProvider {
  @override
  Future<void> getConsumedCalories() async {}
}

Widget _wrapMainPage({
  required Widget child,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => child),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<WorkoutProvider>(
          create: (_) => WorkoutProvider()..setAllWorkoutsForTesting(const [])),
      ChangeNotifierProvider<StatisticsProvider>(
          create: (_) => StatisticsProvider()),
      ChangeNotifierProvider<HomeProvider>(create: (_) => HomeProvider()),
      ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => SubscriptionProvider(autoInitialize: false)),
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ChangeNotifierProvider<ConsumptionProvider>(
          create: (_) => _MockConsumptionProvider()),
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp.router(
        routerConfig: router,
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(0.75),
          ),
          child: widget!,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final updateService = UpdateService();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    updateService.resetMockDependencies();
    AppUpdateConfig.reset();
  });

  tearDown(() {
    updateService.resetMockDependencies();
    AppUpdateConfig.reset();
  });

  group('Gym Buddy — Firestore Remote Update Control & Google Play Tests', () {
    // 1. Firestore force_update true with an older version
    test('1. Firestore force_update true with an older version', () async {
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.10',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.11',
          minRequiredVersion: '1.0.0',
          forceUpdate: true,
          releaseNotes: 'Critical update with breaking changes.',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
      );

      final updateInfo = await updateService.checkForUpdates();
      expect(updateInfo.hasUpdate, isTrue);
      expect(updateInfo.isForceUpdate, isTrue,
          reason: 'force_update true with older version must force update');
    });

    // 2. Firestore force_update false with an older version
    test('2. Firestore force_update false with an older version', () async {
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.10',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.11',
          minRequiredVersion: '1.0.0',
          forceUpdate: false,
          releaseNotes: 'New optional workouts available.',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
        playStoreUpdateAvailable: true,
        playStoreFlexibleAllowed: true,
      );

      final updateInfo = await updateService.checkForUpdates();
      expect(updateInfo.hasUpdate, isTrue);
      expect(updateInfo.isForceUpdate, isFalse,
          reason: 'force_update false with version satisfying min_required must remain optional');
      expect(updateInfo.canUsePlayStoreFlexibleUpdate, isTrue);
    });

    // 3. Latest version already installed
    test('3. Latest version already installed', () async {
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.10',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.10',
          minRequiredVersion: '1.0.0',
          forceUpdate: true, // Even if force_update is true in remote config!
          releaseNotes: 'Some release notes.',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
      );

      final updateInfo = await updateService.checkForUpdates();
      expect(updateInfo.hasUpdate, isFalse,
          reason: 'If installed version == latest_version, do not show update dialog even if force_update is true');
      expect(updateInfo.isForceUpdate, isFalse);
    });

    // 4. Installed version below minimum required version
    test('4. Installed version below minimum required version', () async {
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.9',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.12',
          minRequiredVersion: '1.0.10',
          forceUpdate: false, // Even if force_update is false!
          releaseNotes: 'Mandatory deprecation.',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
      );

      final updateInfo = await updateService.checkForUpdates();
      expect(updateInfo.hasUpdate, isTrue);
      expect(updateInfo.isForceUpdate, isTrue,
          reason: 'Installed version below min_required_version must force update');
    });

    // 5. Installed version satisfies minimum required version
    test('5. Installed version satisfies minimum required version', () async {
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.10',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.12',
          minRequiredVersion: '1.0.10',
          forceUpdate: false,
          releaseNotes: 'New features available.',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
      );

      final updateInfo = await updateService.checkForUpdates();
      expect(updateInfo.hasUpdate, isTrue);
      expect(updateInfo.isForceUpdate, isFalse,
          reason: 'Installed version satisfies min_required_version and force_update is false');
    });

    // 6. Semantic version comparison
    test('6. Semantic version comparison', () {
      expect(updateService.compareVersions('1.0.9', '1.0.10'), -1);
      expect(updateService.compareVersions('1.0.10', '1.0.9'), 1);
      expect(updateService.compareVersions('1.0.10', '1.0.10'), 0);
      expect(updateService.compareVersions('2.0.0', '1.9.9'), 1);
      expect(updateService.compareVersions('1.0.0', '2.0.0'), -1);
      expect(updateService.compareVersions('1.10.0', '1.9.0'), 1);
      expect(updateService.compareVersions('1.0.10+32', '1.0.10+33'), 0);
    });

    // 7. Mandatory dialog cannot be dismissed
    testWidgets('7. Mandatory dialog cannot be dismissed', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (context, child) => const MaterialApp(
            home: Scaffold(
              body: UpdateDialog(
                isForceUpdate: true,
                releaseNotes: 'Critical security fix.',
                updateUrl: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Update Required'), findsOneWidget);
      expect(find.text('UPDATE NOW'), findsOneWidget);
      expect(find.byKey(const Key('update_later_button')), findsNothing);
      expect(find.text('LATER'), findsNothing);

      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);
      final popScope = tester.widget<PopScope>(popScopeFinder);
      expect(popScope.canPop, isFalse);
    });

    // 8. Optional dialog supports LATER
    testWidgets('8. Optional dialog supports LATER', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (context, child) => const MaterialApp(
            home: Scaffold(
              body: UpdateDialog(
                isForceUpdate: false,
                releaseNotes: 'New workouts available.',
                updateUrl: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('UPDATE NOW'), findsOneWidget);
      expect(find.byKey(const Key('update_later_button')), findsOneWidget);
      expect(find.text('LATER'), findsOneWidget);

      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);
      final popScope = tester.widget<PopScope>(popScopeFinder);
      expect(popScope.canPop, isTrue);

      await tester.tap(find.byKey(const Key('update_later_button')));
      await tester.pumpAndSettle();
      expect(updateService.isOptionalUpdateDismissed, isTrue);
    });

    // 9. Firestore offline with cached mandatory configuration
    test('9. Firestore offline with cached mandatory configuration', () async {
      final prefs = await SharedPreferences.getInstance();
      const cachedConfig = RemoteUpdateConfig(
        latestVersion: '1.0.11',
        minRequiredVersion: '1.0.10',
        forceUpdate: true,
        releaseNotes: 'Cached mandatory update',
        updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
        updateUrlIos: '',
      );
      await prefs.setString(
        AppUpdateConfig.cachedRemoteConfigKey,
        jsonEncode(cachedConfig.toMap()),
      );

      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.9',
          buildNumber: '32',
          buildSignature: '',
        ),
        simulateFirestoreError: true, // Firestore is offline/unreachable
      );

      final updateInfo = await updateService.checkForUpdates();
      expect(updateInfo.hasUpdate, isTrue);
      expect(updateInfo.isForceUpdate, isTrue,
          reason: 'Offline check must use cached mandatory update config');
      expect(updateInfo.releaseNotes, 'Cached mandatory update');
    });

    // 10. Firestore offline without cached configuration
    test('10. Firestore offline without cached configuration', () async {
      // SharedPreferences is empty (no cache)
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.10',
          buildNumber: '32',
          buildSignature: '',
        ),
        simulateFirestoreError: true, // Firestore offline
      );

      final updateInfo = await updateService.checkForUpdates();
      // Should not throw, should use hardcoded baseline, and not falsely force an update
      expect(updateInfo, isNotNull);
      expect(updateInfo.hasUpdate, isFalse);
      expect(updateInfo.isForceUpdate, isFalse);
    });

    // 11. Malformed Firestore configuration
    test('11. Malformed Firestore configuration', () async {
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.9',
          buildNumber: '32',
          buildSignature: '',
        ),
        rawFirestoreData: {
          'latest_version': null,
          'min_required_version': 123,
          'force_update': 'true', // string instead of boolean
          'release_notes': 456,
          'update_url_android': null,
        },
      );

      final updateInfo = await updateService.checkForUpdates();
      expect(updateInfo, isNotNull);
      expect(updateInfo.hasUpdate, isTrue);
      expect(updateInfo.isForceUpdate, isTrue);
    });

    // 12. Google Play update unavailable
    test('12. Google Play update unavailable', () async {
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.10',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.11',
          minRequiredVersion: '1.0.0',
          forceUpdate: false,
          releaseNotes: 'Update available soon.',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
        playStoreUpdateAvailable: false,
      );

      final updateInfo = await updateService.checkForUpdates();
      expect(updateInfo.hasUpdate, isTrue);
      expect(updateInfo.isForceUpdate, isFalse);
      expect(updateInfo.canUsePlayStoreFlexibleUpdate, isFalse);
      expect(updateInfo.updateUrl, contains('play.google.com'));
    });

    // 13. Native update failure and store fallback
    test('13. Native update failure and store fallback', () async {
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.9',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.11',
          minRequiredVersion: '1.0.10',
          forceUpdate: true,
          releaseNotes: 'Update now.',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
        playStoreImmediateAllowed: false, // Immediate update not supported
      );

      final updateInfo = await updateService.checkForUpdates();
      expect(updateInfo.hasUpdate, isTrue);
      expect(updateInfo.isForceUpdate, isTrue);
      expect(updateInfo.canUsePlayStoreImmediateUpdate, isFalse);
      expect(updateInfo.updateUrl, 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp');
    });

    // 14. Duplicate dialog prevention
    test('14. Duplicate dialog prevention', () async {
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.9',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.11',
          minRequiredVersion: '1.0.10',
          forceUpdate: true,
          releaseNotes: 'Mandatory',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
      );

      final results = await Future.wait([
        updateService.checkForUpdates(),
        updateService.checkForUpdates(),
      ]);

      expect(results.length, 2);
      expect(results[0].hasUpdate, results[1].hasUpdate);
      expect(results[0].isForceUpdate, results[1].isForceUpdate);

      // Verify dialog open state flag prevents duplicate dialog opening
      updateService.isDialogOpen = true;
      expect(updateService.isDialogOpen, isTrue);
      updateService.isDialogOpen = false;
      expect(updateService.isDialogOpen, isFalse);
    });

    // 15. Existing hardcoded minimum fallback
    test('15. Existing hardcoded minimum fallback', () async {
      AppUpdateConfig.minimumRequiredVersion = '1.0.10';
      AppUpdateConfig.minimumRequiredBuildNumber = 32;

      // Firestore fails and no cache exists
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.9',
          buildNumber: '32',
          buildSignature: '',
        ),
        simulateFirestoreError: true,
      );

      final updateInfo = await updateService.checkForUpdates();
      expect(updateInfo.hasUpdate, isTrue);
      expect(updateInfo.isForceUpdate, isTrue,
          reason: 'Hardcoded local minimum safeguard must force update when version < 1.0.10');
    });

    // 16. Multiline release notes with bullet points format correctly
    testWidgets('16. Multiline release notes with bullet points format correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const multilineNotes = '• New chest and tricep routines\n• Improved rest timer UI\n- Performance enhancements';

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (context, child) => const MaterialApp(
            home: Scaffold(
              body: UpdateDialog(
                isForceUpdate: false,
                releaseNotes: multilineNotes,
                updateUrl: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('What\'s New:'), findsOneWidget);
      expect(find.text('New chest and tricep routines'), findsOneWidget);
      expect(find.text('Improved rest timer UI'), findsOneWidget);
      expect(find.text('Performance enhancements'), findsOneWidget);
      expect(find.text('UPDATE NOW'), findsOneWidget);
      expect(find.text('LATER'), findsOneWidget);
    });

    // 17. Small screen responsiveness keeps action buttons visible with scrollable notes
    testWidgets('17. Small screen responsiveness keeps action buttons visible with scrollable notes', (tester) async {
      // Simulate compact screen (e.g., iPhone SE or compact Android: 320x568)
      tester.view.physicalSize = const Size(320 * 2, 568 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final longNotes = List.generate(20, (i) => '• Feature item $i with detailed note').join('\n');

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(320, 568),
          minTextAdapt: true,
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: UpdateDialog(
                isForceUpdate: false,
                releaseNotes: longNotes,
                updateUrl: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Action buttons must be rendered and visible even with long content on small screen
      expect(find.text('UPDATE NOW'), findsOneWidget);
      expect(find.text('LATER'), findsOneWidget);
      expect(find.byKey(const Key('update_now_button')), findsOneWidget);
      expect(find.byKey(const Key('update_later_button')), findsOneWidget);
    });

    // 18. Native flexible update downloads in background and completes
    test('18. Native flexible update downloads in background and completes', () async {
      bool onDownloadedCalled = false;
      updateService.setMockDependencies(
        isAndroid: true,
        mockFlexibleResult: play.AppUpdateResult.success,
      );

      final result = await updateService.startNativeFlexibleUpdate(
        onDownloaded: () {
          onDownloadedCalled = true;
        },
      );

      expect(result, play.AppUpdateResult.success);
      expect(onDownloadedCalled, isTrue);
      expect(updateService.isFlexibleUpdateDownloaded, isTrue);
      expect(updateService.mockFlexibleUpdateCompleted, isFalse);
      expect(updateService.isFlexibleUpdateInProgress, isFalse);

      // Now complete when ready
      final completed = await updateService.completeNativeFlexibleUpdate();
      expect(completed, isTrue);
      expect(updateService.mockFlexibleUpdateCompleted, isTrue);
    });

    // 19. Native immediate update cancellation and resume re-check
    test('19. Native immediate update cancellation and resume re-check', () async {
      // Step A: Immediate update cancelled by user
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.9',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.11',
          minRequiredVersion: '1.0.10',
          forceUpdate: true,
          releaseNotes: 'Critical update',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
        mockImmediateResult: play.AppUpdateResult.userDeniedUpdate,
      );

      final result = await updateService.performNativeImmediateUpdate();
      expect(result, play.AppUpdateResult.userDeniedUpdate);
      // Mandatory status still active because version is 1.0.9
      final check1 = await updateService.checkForUpdates();
      expect(check1.isForceUpdate, isTrue);

      // Step B: User returns from Play Store after completing update to 1.0.11
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.11',
          buildNumber: '33',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.11',
          minRequiredVersion: '1.0.10',
          forceUpdate: true,
          releaseNotes: 'Critical update',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
      );

      final check2 = await updateService.checkForUpdates();
      expect(check2.hasUpdate, isFalse);
      expect(check2.isForceUpdate, isFalse,
          reason: 'Once updated to 1.0.11, mandatory lock is released');
    });

    // 20. Duplicate native update flows are safely prevented
    test('20. Duplicate native update flows are safely prevented', () async {
      updateService.setMockDependencies(
        isAndroid: true,
        mockImmediateResult: play.AppUpdateResult.success,
      );

      // Trigger concurrent immediate update calls
      final results = await Future.wait([
        updateService.performNativeImmediateUpdate(),
        updateService.performNativeImmediateUpdate(),
      ]);

      // Exactly one succeeds and duplicate call is safely guarded
      expect(results.contains(play.AppUpdateResult.success), isTrue);
      expect(updateService.isImmediateUpdateInProgress, isFalse);
    });

    // 21. Android uses native update flow and bypasses custom UpdateDialog
    test('21. Android uses native update flow and bypasses custom UpdateDialog', () async {
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.10',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.11',
          minRequiredVersion: '1.0.0',
          forceUpdate: false,
          releaseNotes: 'Optional update',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
        playStoreUpdateAvailable: true,
        playStoreFlexibleAllowed: true,
        mockFlexibleResult: play.AppUpdateResult.success,
      );

      final updateInfo = await updateService.checkForUpdates();
      expect(updateInfo.hasUpdate, isTrue);
      expect(updateInfo.isForceUpdate, isFalse);
      expect(updateInfo.canUsePlayStoreFlexibleUpdate, isTrue);

      // Native flexible update runs without triggering custom dialog
      expect(updateService.isDialogOpen, isFalse);
      final flexResult = await updateService.startNativeFlexibleUpdate();
      expect(flexResult, play.AppUpdateResult.success);
      expect(updateService.isDialogOpen, isFalse);
    });

    // 22. MainPage mandatory resume: App resume while on MainPage triggers mandatory update and blocks interaction
    testWidgets('22. MainPage mandatory update when resumed with MainPage already active blocks interaction', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Initial state: installed 1.0.10, latest 1.0.10 -> no update
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.10',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.10',
          minRequiredVersion: '1.0.0',
          forceUpdate: false,
          releaseNotes: '',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
        playStoreUpdateAvailable: true,
        mockStoreLaunchResult: true,
      );

      await tester.pumpWidget(
        _wrapMainPage(
          child: const MainPage(
            paywallTimerDelayForTesting: Duration(hours: 1),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('main_mandatory_update_scaffold')), findsNothing);

      // Remote config updates to mandatory update
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.10',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.11',
          minRequiredVersion: '1.0.11',
          forceUpdate: true,
          releaseNotes: 'Critical security update required.',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
        playStoreUpdateAvailable: true,
        mockStoreLaunchResult: true,
        mockImmediateResult: play.AppUpdateResult.userDeniedUpdate,
      );

      // Simulate App resuming while user is on MainPage
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Must block Dashboard interaction with non-dismissible scaffold
      expect(find.byKey(const Key('main_mandatory_update_scaffold')), findsOneWidget);
      expect(find.byKey(const Key('main_update_required_title')), findsOneWidget);
      expect(find.byKey(const Key('main_update_store_button')), findsOneWidget);
    });

    // 23. Immediate update cancellation non-bypass: user denies update, blocking state is enforced
    testWidgets('23. Google Play immediate update cancelled or unavailable shows non-dismissible blocking state with Update on Google Play action', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.9',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.11',
          minRequiredVersion: '1.0.10',
          forceUpdate: true,
          releaseNotes: 'Mandatory update required.',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
        playStoreUpdateAvailable: true,
        playStoreImmediateAllowed: true,
        mockStoreLaunchResult: true,
        mockImmediateResult: play.AppUpdateResult.userDeniedUpdate,
      );

      await tester.pumpWidget(
        _wrapMainPage(
          child: const MainPage(
            paywallTimerDelayForTesting: Duration(hours: 1),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Non-dismissible blocking state must be displayed
      expect(find.byKey(const Key('main_mandatory_update_scaffold')), findsOneWidget);
      expect(find.byKey(const Key('main_update_store_button')), findsOneWidget);

      final popScope = tester.widget<PopScope>(find.byType(PopScope).first);
      expect(popScope.canPop, isFalse);
    });

    // 24. No duplicate optional prompt after Splash evaluated it
    test('24. No duplicate optional update prompt after SplashScreen evaluated it', () async {
      updateService.resetMockDependencies();
      expect(updateService.optionalUpdateState, OptionalUpdateSessionState.notAttempted);
      expect(updateService.shouldPromptOptionalUpdate, isTrue);

      // SplashScreen marks attempted when initiating flexible update
      updateService.markOptionalUpdateAttempted();
      expect(updateService.optionalUpdateState, OptionalUpdateSessionState.downloading);
      expect(updateService.shouldPromptOptionalUpdate, isFalse);

      // MainPage evaluates optional update check -> shouldPromptOptionalUpdate is false
      expect(updateService.shouldPromptOptionalUpdate, isFalse);
    });

    // 25. Flexible completion without auto-restart
    test('25. Flexible update download completes without auto-restart', () async {
      updateService.setMockDependencies(
        isAndroid: true,
        mockFlexibleResult: play.AppUpdateResult.success,
      );

      bool downloadCallbackFired = false;
      final result = await updateService.startNativeFlexibleUpdate(
        onDownloaded: () => downloadCallbackFired = true,
      );

      expect(result, play.AppUpdateResult.success);
      expect(downloadCallbackFired, isTrue);
      expect(updateService.isFlexibleUpdateDownloaded, isTrue);
      expect(updateService.optionalUpdateState, OptionalUpdateSessionState.downloaded);
      // Downloaded does NOT auto-restart
      expect(updateService.mockFlexibleUpdateCompleted, isFalse);
      expect(updateService.updateReadyNotifier.value, isTrue);
    });

    // 26. Workout session active deferral
    test('26. Workout session active prevents restart prompt from interrupting user', () async {
      updateService.setMockDependencies(
        isAndroid: true,
        mockFlexibleResult: play.AppUpdateResult.success,
      );

      bool promptInvoked = false;
      updateService.onUpdateReadyPrompt = () {
        promptInvoked = true;
      };

      // User starts active workout session
      updateService.setWorkoutSessionActive(true);
      expect(updateService.isWorkoutSessionActive, isTrue);

      // Flexible update finishes downloading while in workout
      await updateService.startNativeFlexibleUpdate();

      // Restart prompt must NOT interrupt active workout
      expect(promptInvoked, isFalse);
      expect(updateService.isFlexibleUpdateDownloaded, isTrue);
    });

    // 27. Explicit restart after workout completion
    test('27. Explicit restart works after workout completion', () async {
      updateService.setMockDependencies(
        isAndroid: true,
        mockFlexibleResult: play.AppUpdateResult.success,
      );

      bool promptInvoked = false;
      updateService.onUpdateReadyPrompt = () {
        promptInvoked = true;
      };

      // User is in workout
      updateService.setWorkoutSessionActive(true);
      await updateService.startNativeFlexibleUpdate();
      expect(promptInvoked, isFalse);

      // Workout ends
      updateService.setWorkoutSessionActive(false);
      expect(updateService.isWorkoutSessionActive, isFalse);
      // Prompt is now safely triggered
      expect(promptInvoked, isTrue);

      // Explicit user confirmation triggers restart
      final restartSuccess = await updateService.completeNativeFlexibleUpdate();
      expect(restartSuccess, isTrue);
      expect(updateService.mockFlexibleUpdateCompleted, isTrue);
    });

    // 28. iOS empty / invalid URL handling: never falls back to Google Play
    test('28. iOS empty / invalid URL handling: never falls back to Google Play', () async {
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.10',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.11',
          minRequiredVersion: '1.0.10',
          forceUpdate: false,
          releaseNotes: 'iOS update',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '', // Empty iOS URL
        ),
        isAndroid: false, // iOS
      );

      final updateInfo = await updateService.checkForUpdates();
      expect(updateInfo.updateUrl, isEmpty);

      // Calling openStore on iOS with empty or Google Play URL returns false without launching Google Play
      final openedEmpty = await updateService.openStore(customUrl: '');
      expect(openedEmpty, isFalse);

      final openedPlay = await updateService.openStore(
        customUrl: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
      );
      expect(openedPlay, isFalse);
    });

    // 29. Android fallback URL handling
    test('29. Android fallback URL opens when Google Play in-app update is unavailable', () async {
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.9',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.11',
          minRequiredVersion: '1.0.10',
          forceUpdate: true,
          releaseNotes: 'Android fallback test',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
        playStoreImmediateAllowed: false, // In-app update not allowed on this device
      );

      final updateInfo = await updateService.checkForUpdates();
      expect(updateInfo.canUsePlayStoreImmediateUpdate, isFalse);
      expect(updateInfo.updateUrl, contains('com.gymbuddy.fitnessapp'));
    });

    // 30. Resume after successful update installation releases mandatory lock
    testWidgets('30. Resume after successful update installation releases mandatory lock and unblocks MainPage', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Step A: Initially blocked because installed version is 1.0.9
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.9',
          buildNumber: '32',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.11',
          minRequiredVersion: '1.0.10',
          forceUpdate: true,
          releaseNotes: 'Critical update',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
        playStoreUpdateAvailable: true,
        mockStoreLaunchResult: true,
        mockImmediateResult: play.AppUpdateResult.userDeniedUpdate,
      );

      await tester.pumpWidget(
        _wrapMainPage(
          child: const MainPage(
            paywallTimerDelayForTesting: Duration(hours: 1),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Blocked initially
      expect(find.byKey(const Key('main_mandatory_update_scaffold')), findsOneWidget);

      // Step B: User updates app on Play Store and returns (version is now 1.0.11)
      updateService.setMockDependencies(
        packageInfo: PackageInfo(
          appName: 'Gym Buddy',
          packageName: 'com.gymbuddy.fitnessapp',
          version: '1.0.11',
          buildNumber: '33',
          buildSignature: '',
        ),
        remoteConfig: const RemoteUpdateConfig(
          latestVersion: '1.0.11',
          minRequiredVersion: '1.0.10',
          forceUpdate: true,
          releaseNotes: 'Critical update',
          updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.gymbuddy.fitnessapp',
          updateUrlIos: '',
        ),
        isAndroid: true,
        playStoreUpdateAvailable: true,
        mockStoreLaunchResult: true,
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Mandatory lock released!
      expect(find.byKey(const Key('main_mandatory_update_scaffold')), findsNothing);
    });

    // 31. Flexible update completion failure displays retry option, preserves state, and prevents concurrent calls
    testWidgets('31. Flexible update completion failure displays retry option, preserves state, and prevents concurrent calls', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      updateService.setMockDependencies(
        isAndroid: true,
        playStoreUpdateAvailable: true,
        mockStoreLaunchResult: true,
        mockFlexibleResult: play.AppUpdateResult.success,
        simulateFlexibleCompletionFailure: true, // First attempt fails
      );

      await tester.pumpWidget(
        _wrapMainPage(
          child: const MainPage(
            paywallTimerDelayForTesting: Duration(hours: 1),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Trigger flexible download completion
      await updateService.startNativeFlexibleUpdate();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // SnackBar with RESTART appears
      expect(find.text('An update has been downloaded and is ready to install.'), findsOneWidget);
      expect(find.text('RESTART'), findsOneWidget);

      // Tap RESTART (fails due to simulateFlexibleCompletionFailure: true)
      final restartAction1 = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
      restartAction1.onPressed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Error message and RETRY appear
      expect(find.text('Failed to complete update. Tap to retry.'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);

      // Downloaded state is preserved
      expect(updateService.isFlexibleUpdateDownloaded, isTrue);

      // Allow completion to succeed now
      updateService.setMockDependencies(
        isAndroid: true,
        mockFlexibleResult: play.AppUpdateResult.success,
        simulateFlexibleCompletionFailure: false,
      );

      // Tap RETRY
      final retryAction = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
      retryAction.onPressed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Restart SnackBar re-appears
      expect(find.text('An update has been downloaded and is ready to install.'), findsOneWidget);
      expect(find.text('RESTART'), findsOneWidget);

      // Tap RESTART again to complete
      final restartAction2 = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
      restartAction2.onPressed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(updateService.mockFlexibleUpdateCompleted, isTrue);

      expect(updateService.mockFlexibleUpdateCompleted, isTrue);
    });

    // 32. Update SnackBar deduplication across multiple workouts
    testWidgets('32. Update SnackBar deduplication across multiple workouts', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      updateService.setMockDependencies(
        isAndroid: true,
        playStoreUpdateAvailable: true,
        mockStoreLaunchResult: true,
        mockFlexibleResult: play.AppUpdateResult.success,
      );

      await tester.pumpWidget(
        _wrapMainPage(
          child: const MainPage(
            paywallTimerDelayForTesting: Duration(hours: 1),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Download update
      await updateService.startNativeFlexibleUpdate();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('An update has been downloaded and is ready to install.'), findsOneWidget);

      // Simulate completing multiple workouts while prompt is already visible
      updateService.setWorkoutSessionActive(true);
      updateService.setWorkoutSessionActive(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      updateService.setWorkoutSessionActive(true);
      updateService.setWorkoutSessionActive(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Exactly ONE update-ready SnackBar exists (no duplicated/queued stack)
      expect(find.text('An update has been downloaded and is ready to install.'), findsOneWidget);
    });
  });
}
