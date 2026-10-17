import 'dart:async';

import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';
import 'package:fitness_app/presentation/custom_workouts/workout_session_launcher_page.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class RecordedScheduledNotification {
  final int id;
  final String? title;
  final String? body;
  final tz.TZDateTime scheduledDate;
  final String? payload;
  final DateTimeComponents? matchDateTimeComponents;

  const RecordedScheduledNotification({
    required this.id,
    this.title,
    this.body,
    required this.scheduledDate,
    this.payload,
    this.matchDateTimeComponents,
  });
}

class FakeLocalNotificationsPlugin implements FlutterLocalNotificationsPlugin {
  NotificationAppLaunchDetails? launchDetails;
  DidReceiveNotificationResponseCallback? onSelectNotificationCallback;
  int initializeCallCount = 0;

  final List<int> canceledIds = [];
  final Map<int, RecordedScheduledNotification> activeScheduled = {};
  final List<RecordedScheduledNotification> scheduleHistory = [];

  FakeLocalNotificationsPlugin({this.launchDetails});

  void simulateWarmStartNotificationTap(String? payload) {
    onSelectNotificationCallback?.call(
      NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      ),
    );
  }

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCallCount++;
    onSelectNotificationCallback = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?>
      getNotificationAppLaunchDetails() async {
    return launchDetails;
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    canceledIds.add(id);
    activeScheduled.remove(id);
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final record = RecordedScheduledNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      matchDateTimeComponents: matchDateTimeComponents,
    );
    activeScheduled[id] = record;
    scheduleHistory.add(record);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestWorkoutProvider extends WorkoutProvider {
  final Completer<void>? fetchCompleter;
  final List<WorkoutModel> fetchedWorkoutsOnLoad;
  int fetchCount = 0;

  TestWorkoutProvider({
    this.fetchCompleter,
    this.fetchedWorkoutsOnLoad = const [],
  });

  @override
  Future fetchAndSetWorkouts() async {
    fetchCount++;
    if (fetchCompleter != null) {
      await fetchCompleter!.future;
    }
    if (fetchedWorkoutsOnLoad.isNotEmpty) {
      setAllWorkoutsForTesting(fetchedWorkoutsOnLoad);
    }
  }
}

class StubSubscriptionProvider extends ChangeNotifier
    implements SubscriptionProvider {
  @override
  bool get isPremium => false;

  @override
  bool get isLifetime => false;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WorkoutLogService.clearLastLogCache();
    NotificationService().resetForTesting();
  });

  group('Phase 3A.1 — Local Notification Cold-Start & Warm-Start Handling', () {
    test(
        'Cold start routes valid local notification payload once and prevents duplicate navigation on re-initialization',
        () async {
      final navigatedRoutes = <String>[];
      final fakePlugin = FakeLocalNotificationsPlugin(
        launchDetails: const NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: '${Routes.dayWorkoutSessionRoute}?day=Monday',
          ),
        ),
      );

      final service = NotificationService.forTesting(
        localNotificationsPlugin: fakePlugin,
        routeNavigator: (route, {bool isGo = false}) {
          navigatedRoutes.add('${isGo ? "go" : "push"}:$route');
        },
      );

      await service.initializeLocalNotifications();
      expect(navigatedRoutes, ['push:/dayWorkoutSession?day=Monday']);

      // Re-initializing (e.g., when MainPage rebuilds) must NOT duplicate cold-start navigation
      await service.initializeLocalNotifications();
      await service.initializeLocalNotifications();
      expect(navigatedRoutes, ['push:/dayWorkoutSession?day=Monday']);
    });

    test(
        'Cold start defers navigation until router and required app state are ready, then flushes once on markAppReady',
        () async {
      final navigatedRoutes = <String>[];
      final fakePlugin = FakeLocalNotificationsPlugin(
        launchDetails: const NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: 'workout_day:Wednesday',
          ),
        ),
      );

      final service = NotificationService.forTesting(
        localNotificationsPlugin: fakePlugin,
        routeNavigator: (route, {bool isGo = false}) {
          navigatedRoutes.add('${isGo ? "go" : "push"}:$route');
        },
      );

      // Defer navigation while app/workout state is still loading
      service.deferNavigationUntilReady();
      await service.initializeLocalNotifications();
      expect(navigatedRoutes, isEmpty);

      // Calling initializeLocalNotifications again while still loading does not navigate prematurely
      await service.initializeLocalNotifications();
      expect(navigatedRoutes, isEmpty);

      // Marking app ready flushes the queued cold-start route once
      service.markAppReady();
      expect(navigatedRoutes, ['push:/dayWorkoutSession?day=Wednesday']);

      // Subsequent markAppReady calls are no-ops
      service.markAppReady();
      expect(navigatedRoutes, ['push:/dayWorkoutSession?day=Wednesday']);
    });

    test(
        'Warm-start notification taps route accurately before and after cold-start handling',
        () async {
      final navigatedRoutes = <String>[];
      final fakePlugin = FakeLocalNotificationsPlugin(
        launchDetails: const NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: '${Routes.dayWorkoutSessionRoute}?day=Monday',
          ),
        ),
      );

      final service = NotificationService.forTesting(
        localNotificationsPlugin: fakePlugin,
        routeNavigator: (route, {bool isGo = false}) {
          navigatedRoutes.add('${isGo ? "go" : "push"}:$route');
        },
      );

      await service.initializeLocalNotifications();
      expect(navigatedRoutes, ['push:/dayWorkoutSession?day=Monday']);

      // Simulate warm-start taps while app is in memory
      fakePlugin.simulateWarmStartNotificationTap(Routes.addWaterRoute);
      fakePlugin.simulateWarmStartNotificationTap('workout_split:Friday');
      fakePlugin.simulateWarmStartNotificationTap(Routes.mainRoute);

      expect(navigatedRoutes, [
        'push:/dayWorkoutSession?day=Monday',
        'push:/addWater',
        'push:/dayWorkoutSession?day=Friday',
        'go:/main',
      ]);
    });

    test(
        'Cold start with didNotificationLaunchApp=false or empty payload does not navigate',
        () async {
      final navigatedRoutes = <String>[];
      final fakePlugin = FakeLocalNotificationsPlugin(
        launchDetails: const NotificationAppLaunchDetails(false),
      );

      final service = NotificationService.forTesting(
        localNotificationsPlugin: fakePlugin,
        routeNavigator: (route, {bool isGo = false}) {
          navigatedRoutes.add(route);
        },
      );

      await service.initializeLocalNotifications();
      expect(navigatedRoutes, isEmpty);
    });
  });

  group('Phase 3A.2 — WorkoutSessionLauncherPage & GoRouter Navigation', () {
    Future<void> pumpLauncherTestApp(
      WidgetTester tester, {
      required WorkoutProvider workoutProvider,
      required GoRouter testRouter,
    }) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, __) => MultiProvider(
            providers: [
              ChangeNotifierProvider<WorkoutProvider>.value(
                value: workoutProvider,
              ),
              ChangeNotifierProvider<StatisticsProvider>(
                create: (_) => StatisticsProvider(),
              ),
              ChangeNotifierProvider<SubscriptionProvider>(
                create: (_) => StubSubscriptionProvider(),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: testRouter,
            ),
          ),
        ),
      );
    }

    testWidgets(
        'Shows loading state while fetching workouts, then renders DayWorkoutSessionPage inside declarative GoRoute',
        (tester) async {
      final fetchCompleter = Completer<void>();
      final now = DateTime(2026, 10, 12, 8, 0);
      final mondayWorkouts = [
        WorkoutModel(
          id: 'w1',
          name: '[Monday] Barbell Bench Press',
          repNumber: 8,
          setNumber: 3,
          dateTime: now,
        ),
      ];

      final workoutProvider = TestWorkoutProvider(
        fetchCompleter: fetchCompleter,
        fetchedWorkoutsOnLoad: mondayWorkouts,
      );

      final testRouter = GoRouter(
        initialLocation: '${Routes.dayWorkoutSessionRoute}?day=monday',
        routes: [
          GoRoute(
            path: Routes.mainRoute,
            builder: (_, __) => const Scaffold(body: Text('Home Screen Stub')),
          ),
          GoRoute(
            path: Routes.dayWorkoutSessionRoute,
            builder: (_, state) {
              final day = state.uri.queryParameters['day'] ?? 'today';
              return WorkoutSessionLauncherPage(dayName: day);
            },
          ),
        ],
      );

      await pumpLauncherTestApp(
        tester,
        workoutProvider: workoutProvider,
        testRouter: testRouter,
      );

      // Initially shows loading state
      expect(find.text("Loading today's workout..."), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete workout fetch
      fetchCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Renders DayWorkoutSessionPage directly within the route
      expect(find.byType(DayWorkoutSessionPage), findsOneWidget);
      expect(find.text('Monday Routine'), findsOneWidget);
      expect(find.text('1. Barbell Bench Press'), findsOneWidget);
    });

    testWidgets(
        'Missing workout routine renders fallback UI and Go to Home navigates to mainRoute',
        (tester) async {
      final workoutProvider = TestWorkoutProvider();
      workoutProvider.setAllWorkoutsForTesting([
        WorkoutModel(
          id: 'w1',
          name: '[Monday] Barbell Bench Press',
          repNumber: 8,
          setNumber: 3,
          dateTime: DateTime(2026, 10, 12),
        ),
      ]);

      final testRouter = GoRouter(
        initialLocation: '${Routes.dayWorkoutSessionRoute}?day=Friday',
        routes: [
          GoRoute(
            path: Routes.mainRoute,
            builder: (_, __) => const Scaffold(body: Text('Home Screen Stub')),
          ),
          GoRoute(
            path: Routes.dayWorkoutSessionRoute,
            builder: (_, state) {
              final day = state.uri.queryParameters['day'] ?? 'today';
              return WorkoutSessionLauncherPage(dayName: day);
            },
          ),
        ],
      );

      await pumpLauncherTestApp(
        tester,
        workoutProvider: workoutProvider,
        testRouter: testRouter,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No workout routine found for Friday.'),
        findsOneWidget,
      );
      expect(find.text('Go to Home'), findsOneWidget);

      await tester.tap(find.text('Go to Home'));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen Stub'), findsOneWidget);
    });

    testWidgets(
        'Resolves day=today to current weekday and safely handles String extra in GoRouter',
        (tester) async {
      final todayName = DateFormat('EEEE').format(DateTime.now());
      final workoutProvider = TestWorkoutProvider();
      workoutProvider.setAllWorkoutsForTesting([
        WorkoutModel(
          id: 'w_today',
          name: '[$todayName] Barbell Squat',
          repNumber: 5,
          setNumber: 3,
          dateTime: DateTime.now(),
        ),
      ]);

      final testRouter = GoRouter(
        initialLocation: '${Routes.dayWorkoutSessionRoute}?day=today',
        routes: [
          GoRoute(
            path: Routes.mainRoute,
            builder: (_, __) => const Scaffold(body: Text('Home Screen Stub')),
          ),
          GoRoute(
            path: Routes.dayWorkoutSessionRoute,
            builder: (_, state) {
              final extraMap = state.extra is Map
                  ? Map<String, dynamic>.from(state.extra as Map)
                  : null;
              final extraDay =
                  state.extra is String ? state.extra as String : null;
              final day = state.uri.queryParameters['day'] ??
                  extraMap?['dayName']?.toString() ??
                  extraDay ??
                  'today';
              final workouts = extraMap?['workouts'] as List<dynamic>?;
              return WorkoutSessionLauncherPage(
                dayName: day,
                initialWorkouts: workouts,
              );
            },
          ),
        ],
      );

      await pumpLauncherTestApp(
        tester,
        workoutProvider: workoutProvider,
        testRouter: testRouter,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DayWorkoutSessionPage), findsOneWidget);
      expect(find.text('$todayName Routine'), findsOneWidget);
      expect(find.text('1. Barbell Squat'), findsOneWidget);
    });
  });

  group('Phase 3A.3 — Workout Reminder Advancement & Rest-Day Protection', () {
    test(
        'Rest-day workout completion does NOT cancel or create a recurring workout reminder',
        () async {
      // Sunday, Oct 11, 2026 at 11:00 AM (Rest day for a Mon/Wed/Fri schedule)
      final sundayNow = DateTime(2026, 10, 11, 11, 0);
      SharedPreferences.setMockInitialValues({
        'notif_workout_reminders_enabled': true,
        'scheduled_workout_days': ['Monday', 'Wednesday', 'Friday'],
      });

      final fakePlugin = FakeLocalNotificationsPlugin();
      final service = NotificationService.forTesting(
        localNotificationsPlugin: fakePlugin,
        permissionChecker: () async => true,
        scheduleModeResolver: () async =>
            AndroidScheduleMode.exactAllowWhileIdle,
        nowProvider: () => sundayNow,
      );

      // Schedule initial Mon/Wed/Fri reminders
      await service.scheduleWorkoutDayReminders(
        scheduledDays: ['Monday', 'Wednesday', 'Friday'],
        time: const TimeOfDay(hour: 8, minute: 0),
      );
      expect(fakePlugin.activeScheduled.keys.toSet(), {20, 22, 24});
      fakePlugin.canceledIds.clear();
      fakePlugin.scheduleHistory.clear();

      // Complete an ad-hoc or catch-up workout on Sunday (Rest Day)
      await service.advanceTodayWorkoutReminderIfScheduled();

      // No reminder should be canceled or scheduled for Sunday (ID 26)
      expect(fakePlugin.canceledIds, isEmpty);
      expect(fakePlugin.scheduleHistory, isEmpty);
      expect(fakePlugin.activeScheduled.containsKey(26), isFalse);
      // Mon/Wed/Fri reminders remain intact
      expect(fakePlugin.activeScheduled.keys.toSet(), {20, 22, 24});
    });

    test(
        'Uses 8:00 AM default when custom hour is unset and advances to next week even when completed before 8:00 AM',
        () async {
      // Monday, Oct 12, 2026 at 6:45 AM (BEFORE the 8:00 AM default reminder!)
      final mondayEarlyMorning = DateTime(2026, 10, 12, 6, 45);
      SharedPreferences.setMockInitialValues({
        'notif_workout_reminders_enabled': true,
        // Notice: 'notif_workout_hour' and 'notif_workout_minute' are intentionally unset!
        'scheduled_workout_days': ['Monday', 'Wednesday', 'Friday'],
      });

      final fakePlugin = FakeLocalNotificationsPlugin();
      final service = NotificationService.forTesting(
        localNotificationsPlugin: fakePlugin,
        permissionChecker: () async => true,
        scheduleModeResolver: () async =>
            AndroidScheduleMode.exactAllowWhileIdle,
        nowProvider: () => mondayEarlyMorning,
      );

      await service.advanceTodayWorkoutReminderIfScheduled();

      // Monday is index 0 -> notifId 20
      expect(fakePlugin.canceledIds, [20]);
      expect(fakePlugin.activeScheduled.containsKey(20), isTrue);

      final rescheduledMonday = fakePlugin.activeScheduled[20]!;
      // Must be scheduled for next week (Monday, Oct 19, 2026) at 08:00 AM (NOT 18:00, and NOT Oct 12 at 08:00 AM)
      expect(rescheduledMonday.scheduledDate.year, 2026);
      expect(rescheduledMonday.scheduledDate.month, 10);
      expect(rescheduledMonday.scheduledDate.day, 19);
      expect(rescheduledMonday.scheduledDate.hour, 8);
      expect(rescheduledMonday.scheduledDate.minute, 0);
      expect(
        rescheduledMonday.payload,
        '${Routes.dayWorkoutSessionRoute}?day=Monday',
      );
    });

    test(
        'Advancing today workout reminder preserves all other scheduled weekday reminders untouched',
        () async {
      // Wednesday, Oct 14, 2026 at 5:30 PM
      final wednesdayAfternoon = DateTime(2026, 10, 14, 17, 30);
      SharedPreferences.setMockInitialValues({
        'notif_workout_reminders_enabled': true,
        'notif_workout_hour': 9,
        'notif_workout_minute': 30,
      });

      final fakePlugin = FakeLocalNotificationsPlugin();
      final service = NotificationService.forTesting(
        localNotificationsPlugin: fakePlugin,
        permissionChecker: () async => true,
        scheduleModeResolver: () async =>
            AndroidScheduleMode.exactAllowWhileIdle,
        nowProvider: () => wednesdayAfternoon,
      );

      await service.scheduleWorkoutDayReminders(
        scheduledDays: ['Monday', 'Wednesday', 'Friday'],
        time: const TimeOfDay(hour: 9, minute: 30),
      );

      // Verify initial scheduled reminders for Mon (20), Wed (22), Fri (24)
      expect(fakePlugin.activeScheduled.keys.toSet(), {20, 22, 24});
      final initialMonday = fakePlugin.activeScheduled[20]!;
      final initialFriday = fakePlugin.activeScheduled[24]!;

      fakePlugin.canceledIds.clear();
      fakePlugin.scheduleHistory.clear();

      // Advance Wednesday's reminder after completing Wednesday's workout
      await service.advanceTodayWorkoutReminderIfScheduled();

      // Only Wednesday (ID 22) was canceled and rescheduled
      expect(fakePlugin.canceledIds, [22]);
      expect(fakePlugin.scheduleHistory.length, 1);
      expect(fakePlugin.scheduleHistory.single.id, 22);

      // Monday (20) and Friday (24) are completely untouched
      expect(fakePlugin.activeScheduled[20], same(initialMonday));
      expect(fakePlugin.activeScheduled[24], same(initialFriday));

      // Wednesday (22) is advanced by 7 days to Oct 21, 2026 at 9:30 AM
      final updatedWednesday = fakePlugin.activeScheduled[22]!;
      expect(updatedWednesday.scheduledDate.year, 2026);
      expect(updatedWednesday.scheduledDate.month, 10);
      expect(updatedWednesday.scheduledDate.day, 21);
      expect(updatedWednesday.scheduledDate.hour, 9);
      expect(updatedWednesday.scheduledDate.minute, 30);
    });
  });
}
