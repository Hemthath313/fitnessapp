import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/home_ai_routine_card.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestSubscriptionProvider extends SubscriptionProvider {
  _TestSubscriptionProvider({required bool isPremium})
      : _isPremiumOverride = isPremium;

  bool _isPremiumOverride;

  @override
  bool get isPremium => _isPremiumOverride;

  void setPremium(bool value) {
    _isPremiumOverride = value;
    notifyListeners();
  }
}

void _configureTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

List<WorkoutModel> _buildThreeDaySplit(DateTime date) {
  return [
    WorkoutModel(
      id: 'w_mon_1',
      name: '[Monday] Barbell Bench Press',
      repNumber: 10,
      setNumber: 4,
      dateTime: date,
    ),
    WorkoutModel(
      id: 'w_wed_1',
      name: '[Wednesday] Barbell Squat',
      repNumber: 8,
      setNumber: 4,
      dateTime: date,
    ),
    WorkoutModel(
      id: 'w_fri_1',
      name: '[Friday] Barbell Deadlift',
      repNumber: 6,
      setNumber: 3,
      dateTime: date,
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testDate = DateTime(2026, 10, 12, 10, 0); // Monday

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3B Batch 1: Offline Workout Routine Persistence', () {
    test('Scenario 1: Saved routine restored from cache when Firestore throws network exception', () async {
      const testUid = 'user_offline_1';
      final initialProvider = WorkoutProvider()..userIdOverrideForTesting = testUid;
      final split = _buildThreeDaySplit(testDate);

      // Save routine to cache as if previously generated and saved
      await initialProvider.addNewWorkouts(split);
      expect(initialProvider.hasActiveSplit, isTrue);

      // Simulate app restart with a fresh WorkoutProvider instance and empty memory
      final restartedProvider = WorkoutProvider()..userIdOverrideForTesting = testUid;
      expect(restartedProvider.hasActiveSplit, isFalse);

      // Simulate offline / network exception from Firestore
      restartedProvider.remoteWorkoutsFetcherForTesting = () async {
        throw Exception('Network error: Failed to connect to Firestore');
      };

      await restartedProvider.fetchAndSetWorkouts();

      // Verify routine is restored from local cache
      expect(restartedProvider.hasActiveSplit, isTrue);
      expect(restartedProvider.splitDaysCount, 3);
      expect(restartedProvider.groupedSplitWorkouts.containsKey('Monday'), isTrue);
      expect(restartedProvider.groupedSplitWorkouts.containsKey('Wednesday'), isTrue);
      expect(restartedProvider.groupedSplitWorkouts.containsKey('Friday'), isTrue);
      expect(restartedProvider.groupedSplitWorkouts['Monday']!.first.name, '[Monday] Barbell Bench Press');
    });

    testWidgets('Scenario 2: Home routine state remains available after offline startup', (tester) async {
      _configureTestViewport(tester);
      const testUid = 'user_offline_home';

      // Seed local SharedPreferences with cached active routine
      final seedProvider = WorkoutProvider()..userIdOverrideForTesting = testUid;
      final split = _buildThreeDaySplit(testDate);
      await seedProvider.saveWeeklyPlanToCache(split, testUid);

      // Fresh provider simulating offline app launch
      final workoutProvider = WorkoutProvider()
        ..userIdOverrideForTesting = testUid
        ..setNowProviderForTesting(() => testDate)
        ..remoteWorkoutsFetcherForTesting = () async {
          throw Exception('SocketException: Failed to connect (offline)');
        };

      // Perform initial fetch on startup
      await workoutProvider.fetchAndSetWorkouts();
      expect(workoutProvider.hasActiveSplit, isTrue);

      final statsProvider = StatisticsProvider();
      statsProvider.syncSplitSchedule(workoutProvider.groupedSplitWorkouts.keys);

      final homeProvider = HomeProvider();
      final subProvider = _TestSubscriptionProvider(isPremium: false);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(430, 932),
          minTextAdapt: true,
          builder: (context, child) => MultiProvider(
            providers: [
              ChangeNotifierProvider<WorkoutProvider>.value(value: workoutProvider),
              ChangeNotifierProvider<StatisticsProvider>.value(value: statsProvider),
              ChangeNotifierProvider<HomeProvider>.value(value: homeProvider),
              ChangeNotifierProvider<SubscriptionProvider>.value(value: subProvider),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: HomeAiRoutineCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that Home renders today's routine instead of "No Plan Active"
      expect(find.text('No plan yet'), findsNothing);
      expect(find.text('Barbell Bench Press'), findsWidgets);
    });

    test('Scenario 3: Transient remote failure does not overwrite valid cached routine with empty list', () async {
      const testUid = 'user_transient_failure';
      final provider = WorkoutProvider()..userIdOverrideForTesting = testUid;
      final split = _buildThreeDaySplit(testDate);

      // Save initial plan
      await provider.addNewWorkouts(split);
      expect(provider.hasActiveSplit, isTrue);

      final prefs = await SharedPreferences.getInstance();
      final cacheKey = WorkoutProvider.getCacheKey(testUid);
      expect(prefs.getString(cacheKey), isNotNull);

      // Now simulate a transient network error on background fetch
      provider.remoteWorkoutsFetcherForTesting = () async {
        throw Exception('503 Service Unavailable');
      };

      await provider.fetchAndSetWorkouts();

      // Provider in-memory state and cache MUST NOT be wiped
      expect(provider.hasActiveSplit, isTrue);
      expect(provider.splitDaysCount, 3);
      expect(prefs.getString(cacheKey), isNotNull);
    });

    test('Scenario 4: Explicit routine deletion clears local routine cache', () async {
      const testUid = 'user_delete_plan';
      final provider = WorkoutProvider()..userIdOverrideForTesting = testUid;
      final split = _buildThreeDaySplit(testDate);

      // Populate routine and cache
      await provider.addNewWorkouts(split);
      final cacheKey = WorkoutProvider.getCacheKey(testUid);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(cacheKey), isNotNull);

      // Explicitly delete weekly plan
      await provider.deleteWeeklyPlan();

      // Memory and cache must both be empty
      expect(provider.hasActiveSplit, isFalse);
      expect(prefs.getString(cacheKey), isNull);

      // Restart provider and attempt offline restore - must NOT resurrect deleted plan
      final freshProvider = WorkoutProvider()..userIdOverrideForTesting = testUid;
      final restored = await freshProvider.restoreWeeklyPlanFromCache(testUid);
      expect(restored, isFalse);
      expect(freshProvider.hasActiveSplit, isFalse);
    });

    test('Scenario 5: Genuinely successful remote empty result clears cache without resurrecting deleted plan', () async {
      const testUid = 'user_server_cleared';
      final provider = WorkoutProvider()..userIdOverrideForTesting = testUid;
      final split = _buildThreeDaySplit(testDate);

      // Pre-seed cache with an old split
      await provider.saveWeeklyPlanToCache(split, testUid);
      final cacheKey = WorkoutProvider.getCacheKey(testUid);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(cacheKey), isNotNull);

      // Server successfully returns an empty list (user removed plan on another device)
      provider.remoteWorkoutsFetcherForTesting = () async {
        return <WorkoutModel>[];
      };

      await provider.fetchAndSetWorkouts();

      // Memory and cache must now be empty
      expect(provider.hasActiveSplit, isFalse);
      expect(prefs.getString(cacheKey), isNull);
    });

    test('Scenario 6: Returning online synchronizes remote data without duplicating cached workouts', () async {
      const testUid = 'user_sync_no_dups';
      final split = _buildThreeDaySplit(testDate);

      // Seed local cache
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = WorkoutProvider.getCacheKey(testUid);
      final initialProvider = WorkoutProvider()..userIdOverrideForTesting = testUid;
      await initialProvider.saveWeeklyPlanToCache(split, testUid);

      // 1. Startup offline
      final activeProvider = WorkoutProvider()
        ..userIdOverrideForTesting = testUid
        ..remoteWorkoutsFetcherForTesting = () async {
          throw Exception('Network offline');
        };

      await activeProvider.fetchAndSetWorkouts();
      expect(activeProvider.allWorkouts.length, 3);
      expect(activeProvider.splitDaysCount, 3);

      // 2. Network restored, returning online
      activeProvider.remoteWorkoutsFetcherForTesting = () async {
        return _buildThreeDaySplit(testDate);
      };

      await activeProvider.fetchAndSetWorkouts();

      // Count of plan workouts in memory must strictly be 3 (no duplicate accumulation)
      final planWorkouts = activeProvider.allWorkouts.where((w) => w.name.startsWith('[')).toList();
      expect(planWorkouts.length, 3);
      expect(activeProvider.splitDaysCount, 3);
      expect(prefs.getString(cacheKey), isNotNull);
    });

    test('Scenario 7: Empty premium split does not erase free user independently saved schedule', () async {
      final statsProvider = StatisticsProvider();
      await statsProvider.updateScheduledDays(['Tuesday', 'Thursday']);
      expect(statsProvider.scheduledDayNames, containsAll(['Tuesday', 'Thursday']));

      // An empty split (e.g. from an offline start or free user with no AI split)
      final emptySplitDays = <String>[];
      statsProvider.syncSplitSchedule(emptySplitDays);

      // Schedule MUST be preserved
      expect(statsProvider.scheduledDayNames, containsAll(['Tuesday', 'Thursday']));
      expect(statsProvider.scheduledDayNames.length, 2);

      // Even after reloading streak data from prefs
      await statsProvider.loadStreakData();
      expect(statsProvider.scheduledDayNames, containsAll(['Tuesday', 'Thursday']));
    });
  });
}
