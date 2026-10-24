import 'package:fitness_app/presentation/profile/widgets/gym_alarm_setting_widget.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class FakeLocalNotificationsPlugin implements FlutterLocalNotificationsPlugin {
  final List<int> canceledIds = [];
  final Map<int, NotificationDetails> scheduledDetails = {};
  final Map<int, tz.TZDateTime> scheduledDates = {};

  @override
  Future<void> cancel({required int id, String? tag}) async {
    canceledIds.add(id);
    scheduledDetails.remove(id);
    scheduledDates.remove(id);
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
    scheduledDates[id] = scheduledDate;
    scheduledDetails[id] = notificationDetails;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocalNotificationsPlugin fakePlugin;
  late NotificationService notificationService;

  setUpAll(() {
    tz.initializeTimeZones();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakePlugin = FakeLocalNotificationsPlugin();
    notificationService = NotificationService();
    notificationService.configureForTesting(
      localNotificationsPlugin: fakePlugin,
      permissionChecker: () async => true,
      scheduleModeResolver: () async => AndroidScheduleMode.exactAllowWhileIdle,
      nowProvider: () => DateTime(2026, 10, 19, 5, 0), // 5:00 AM local
    );
  });

  tearDown(() {
    notificationService.resetForTesting();
  });

  group('Gym Alarm Scheduling & Timezone Reliability', () {
    test('1. scheduleDailyGymAlarm schedules alarm for local time when time is later today', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('gym_alarm_enabled', true);

      // Now is 5:00 AM, schedule for 6:30 AM
      await notificationService.scheduleDailyGymAlarm(const TimeOfDay(hour: 6, minute: 30));

      expect(fakePlugin.scheduledDates.containsKey(3), isTrue);
      final scheduledDate = fakePlugin.scheduledDates[3]!;
      expect(scheduledDate.hour, 6);
      expect(scheduledDate.minute, 30);
      expect(scheduledDate.day, 19);

      // Verify alarm audio attributes & category
      final details = fakePlugin.scheduledDetails[3]!;
      final android = details.android!;
      expect(android.channelId, 'gym_alarm');
      expect(android.category, AndroidNotificationCategory.alarm);
      expect(android.audioAttributesUsage, AudioAttributesUsage.alarm);
      expect(android.importance, Importance.max);
      expect(android.priority, Priority.max);
      expect(android.fullScreenIntent, isTrue);
    });

    test('2. scheduleDailyGymAlarm advances to tomorrow when time has passed today', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('gym_alarm_enabled', true);

      // Now is 5:00 AM, schedule for 4:30 AM (already passed today)
      await notificationService.scheduleDailyGymAlarm(const TimeOfDay(hour: 4, minute: 30));

      expect(fakePlugin.scheduledDates.containsKey(3), isTrue);
      final scheduledDate = fakePlugin.scheduledDates[3]!;
      expect(scheduledDate.hour, 4);
      expect(scheduledDate.minute, 30);
      expect(scheduledDate.day, 20); // advanced to tomorrow
    });

    test('3. cancelDailyGymAlarm cancels notification ID 3', () async {
      await notificationService.cancelDailyGymAlarm();
      expect(fakePlugin.canceledIds.contains(3), isTrue);
    });

    test('4. rescheduleDailyGymAlarmIfNeeded restores alarm when enabled in preferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('gym_alarm_enabled', true);
      await prefs.setInt('gym_alarm_hour', 7);
      await prefs.setInt('gym_alarm_minute', 15);

      await notificationService.rescheduleDailyGymAlarmIfNeeded();

      expect(fakePlugin.scheduledDates.containsKey(3), isTrue);
      final scheduledDate = fakePlugin.scheduledDates[3]!;
      expect(scheduledDate.hour, 7);
      expect(scheduledDate.minute, 15);
    });

    test('5. rescheduleDailyGymAlarmIfNeeded does not schedule when alarm is disabled', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('gym_alarm_enabled', false);

      await notificationService.rescheduleDailyGymAlarmIfNeeded();

      expect(fakePlugin.scheduledDates.containsKey(3), isFalse);
    });

    testWidgets('6. GymAlarmSettingWidget toggles alarm on and off with feedback', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorkoutProvider>(create: (_) => WorkoutProvider()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(430, 932),
            builder: (_, __) => const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(child: GymAlarmSettingWidget()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Daily Gym Alarm tile
      expect(find.text('Daily Gym Alarm'), findsOneWidget);

      // Find switch for Daily Gym Alarm and toggle it on
      final switchFinder = find.byType(Switch).at(1);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Confirmation snackbar is shown
      expect(find.textContaining('Daily Gym Alarm set for'), findsOneWidget);

      // SharedPreferences updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('gym_alarm_enabled'), isTrue);
    });
  });
}
