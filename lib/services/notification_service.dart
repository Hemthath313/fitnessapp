import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messaging actions if necessary
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  @visibleForTesting
  NotificationService.forTesting({
    FlutterLocalNotificationsPlugin? localNotificationsPlugin,
    Future<bool> Function()? permissionChecker,
    Future<AndroidScheduleMode> Function()? scheduleModeResolver,
    DateTime Function()? nowProvider,
    void Function(String route, {bool isGo})? routeNavigator,
    bool Function()? isNavigationReady,
  })  : _customLocalNotificationsPlugin = localNotificationsPlugin,
        _permissionChecker = permissionChecker,
        _scheduleModeResolver = scheduleModeResolver,
        _nowProvider = nowProvider,
        _routeNavigator = routeNavigator,
        _isNavigationReady = isNavigationReady;

  static const int defaultWorkoutReminderHour = 8;
  static const int defaultWorkoutReminderMinute = 0;
  static const String scheduledReminderDaysPrefKey =
      'notif_scheduled_workout_days';
  static const String scheduledWorkoutDaysPrefKey = 'scheduled_workout_days';

  static const List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  FlutterLocalNotificationsPlugin? _defaultLocalNotificationsPlugin;
  FlutterLocalNotificationsPlugin? _customLocalNotificationsPlugin;
  FlutterLocalNotificationsPlugin get _localNotificationsPlugin =>
      _customLocalNotificationsPlugin ??
      (_defaultLocalNotificationsPlugin ??= FlutterLocalNotificationsPlugin());

  Future<bool> Function()? _permissionChecker;
  Future<AndroidScheduleMode> Function()? _scheduleModeResolver;
  DateTime Function()? _nowProvider;
  void Function(String route, {bool isGo})? _routeNavigator;
  bool Function()? _isNavigationReady;

  bool _hasHandledColdStartNotification = false;
  String? _handledInitialFcmMessageId;
  bool _isFcmListenersInitialized = false;
  bool _isAppReady = true;
  String? _pendingLaunchPayload;

  @visibleForTesting
  void configureForTesting({
    FlutterLocalNotificationsPlugin? localNotificationsPlugin,
    Future<bool> Function()? permissionChecker,
    Future<AndroidScheduleMode> Function()? scheduleModeResolver,
    DateTime Function()? nowProvider,
    void Function(String route, {bool isGo})? routeNavigator,
    bool Function()? isNavigationReady,
  }) {
    _customLocalNotificationsPlugin = localNotificationsPlugin;
    _permissionChecker = permissionChecker;
    _scheduleModeResolver = scheduleModeResolver;
    _nowProvider = nowProvider;
    _routeNavigator = routeNavigator;
    _isNavigationReady = isNavigationReady;
  }

  @visibleForTesting
  void resetForTesting() {
    _customLocalNotificationsPlugin = null;
    _permissionChecker = null;
    _scheduleModeResolver = null;
    _nowProvider = null;
    _routeNavigator = null;
    _isNavigationReady = null;
    _hasHandledColdStartNotification = false;
    _handledInitialFcmMessageId = null;
    _isFcmListenersInitialized = false;
    _isAppReady = true;
    _pendingLaunchPayload = null;
  }

  /// Defers cold-start notification navigation until [markAppReady] is called.
  void deferNavigationUntilReady() {
    _isAppReady = false;
  }

  /// Marks the router and required application state as ready and flushes any
  /// pending cold-start notification route.
  void markAppReady() {
    _isAppReady = true;
    flushPendingLaunchNavigation();
  }

  /// Flushes any queued cold-start notification payload if navigation is ready.
  void flushPendingLaunchNavigation() {
    if (_pendingLaunchPayload != null && _canNavigateNow()) {
      final pending = _pendingLaunchPayload!;
      _pendingLaunchPayload = null;
      _handleNotificationRoute({'route': pending});
    }
  }

  bool _canNavigateNow() {
    if (_isNavigationReady != null) {
      return _isNavigationReady!();
    }
    return _isAppReady;
  }

  void _routeOrQueueLaunchPayload(String payload) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) return;
    if (_canNavigateNow()) {
      _pendingLaunchPayload = null;
      _handleNotificationRoute({'route': trimmed});
    } else {
      _pendingLaunchPayload = trimmed;
    }
  }

  tz.TZDateTime _currentTzNow() {
    if (_nowProvider != null) {
      return tz.TZDateTime.from(_nowProvider!(), tz.local);
    }
    return tz.TZDateTime.now(tz.local);
  }

  static String? _normalizeWeekdayName(String raw) {
    final lower = raw.trim().toLowerCase();
    for (final day in _weekDays) {
      if (day.toLowerCase() == lower) {
        return day;
      }
    }
    return null;
  }

  Future<void> initialize() async {
    try {
      // 0. Initialize local notifications first (without intrusive premature prompts)
      await initializeLocalNotifications();

      if (!_isFcmListenersInitialized) {
        _isFcmListenersInitialized = true;

        // 1. Set up Background Message Handler
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);

        // 3. Listen to token refreshes
        _messaging.onTokenRefresh.listen((token) async {
          await _saveToken(token);
        });

        // 4. Handle foreground notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (kDebugMode) {
            print('Got a message whilst in the foreground!');
            print('Message data: ${message.data}');
          }

          if (message.notification != null) {
            if (kDebugMode) {
              print(
                  'Message also contained a notification: ${message.notification?.title}');
            }
          }
        });

        // 5. Handle notification tap when app is in background but not terminated
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          if (kDebugMode) {
            print('A new onMessageOpenedApp event was published!');
          }
          _handleNotificationRoute(message.data);
        });
      }

      // 2. Save FCM token for the user if logged in and permitted
      await saveTokenToDatabase();

      // 6. Check if app was opened from terminated state via an FCM notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        final messageId = initialMessage.messageId ??
            '${initialMessage.sentTime?.millisecondsSinceEpoch ?? ''}_${initialMessage.data}';
        if (_handledInitialFcmMessageId != messageId) {
          _handledInitialFcmMessageId = messageId;
          if (kDebugMode) {
            print(
                'App opened from terminated state via notification: ${initialMessage.messageId}');
          }
          final route = (initialMessage.data['route'] as String? ??
                  initialMessage.data['payload'] as String?)
              ?.trim();
          if (route != null && route.isNotEmpty) {
            _routeOrQueueLaunchPayload(route);
          }
        }
      }

      // 7. Re-verify and restore daily gym alarm if enabled
      await rescheduleDailyGymAlarmIfNeeded();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e');
      }
    }
  }

  /// Request permissions contextually when the user enables notifications or configures their routine
  Future<bool> requestNotificationPermissions() async {
    try {
      bool granted = false;

      // iOS Darwin permissions
      final iosResult = await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      if (iosResult == true) granted = true;

      // Android 13+ runtime permissions
      final androidResult = await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      if (androidResult == true) granted = true;

      // Firebase Cloud Messaging permission
      final fcmSettings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (fcmSettings.authorizationStatus == AuthorizationStatus.authorized ||
          fcmSettings.authorizationStatus == AuthorizationStatus.provisional) {
        granted = true;
      }

      await saveTokenToDatabase();
      return granted;
    } catch (e) {
      if (kDebugMode) print('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Check current notification permission status
  Future<bool> hasNotificationPermission() async {
    if (_permissionChecker != null) {
      return _permissionChecker!();
    }
    try {
      if (Platform.isAndroid) {
        final androidImplementation = _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final bool? areEnabled =
              await androidImplementation.areNotificationsEnabled();
          return areEnabled ?? false;
        }
        return true;
      } else if (Platform.isIOS) {
        final settings = await _messaging.getNotificationSettings();
        return settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether exact alarm scheduling special access is available on Android,
  /// safely falling back to inexactAllowWhileIdle if access is revoked or denied
  /// to avoid SecurityException crashes on Android 12+ (API 31+).
  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    if (_scheduleModeResolver != null) {
      return _scheduleModeResolver!();
    }
    if (Platform.isAndroid) {
      try {
        final androidImplementation = _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final canExact =
              await androidImplementation.canScheduleExactNotifications();
          if (canExact == true) {
            return AndroidScheduleMode.exactAllowWhileIdle;
          }
        }
      } catch (_) {}
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
    return AndroidScheduleMode.exactAllowWhileIdle;
  }

  void _navigateToRoute(String targetRoute, {bool isGo = false}) {
    if (_routeNavigator != null) {
      _routeNavigator!(targetRoute, isGo: isGo);
      return;
    }
    if (isGo) {
      router.go(targetRoute);
    } else {
      router.push(targetRoute);
    }
  }

  void _handleNotificationRoute(Map<String, dynamic> data) {
    try {
      final String? rawRoute =
          data['route'] as String? ?? data['payload'] as String?;
      final String? route = rawRoute?.trim();
      if (route != null && route.isNotEmpty) {
        // Direct workout notification taps straight to the canonical adaptive session
        if (route == Routes.workoutLogRoute || route == 'workout_session') {
          _navigateToRoute('${Routes.dayWorkoutSessionRoute}?day=today');
        } else if (route.startsWith('workout_day:') ||
            route.startsWith('workout_split:')) {
          final day = route.split(':').last.trim();
          final resolvedDay = day.isEmpty ? 'today' : day;
          _navigateToRoute('${Routes.dayWorkoutSessionRoute}?day=$resolvedDay');
        } else if (route == Routes.mainRoute) {
          _navigateToRoute(Routes.mainRoute, isGo: true);
        } else {
          _navigateToRoute(route);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error routing notification: $e');
    }
  }

  void _configureLocalTimeZone() {
    try {
      tz.initializeTimeZones();
      final String timeZoneName = DateTime.now().timeZoneName;
      if (tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        return;
      }
      final localOffset = DateTime.now().timeZoneOffset;
      for (final location in tz.timeZoneDatabase.locations.values) {
        if (location.currentTimeZone.offset == localOffset) {
          tz.setLocalLocation(location);
          return;
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error configuring local timezone: $e');
    }
  }

  Future<void> initializeLocalNotifications() async {
    _configureLocalTimeZone();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // Defer permission requests so user isn't prompted prematurely on splash
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload?.trim();
        if (payload != null && payload.isNotEmpty) {
          _handleNotificationRoute({'route': payload});
        }
      },
    );

    // Handle cold-start launch from a local notification exactly once
    if (!_hasHandledColdStartNotification) {
      try {
        final launchDetails =
            await _localNotificationsPlugin.getNotificationAppLaunchDetails();
        if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
          _hasHandledColdStartNotification = true;
          final payload = launchDetails.notificationResponse?.payload?.trim();
          if (payload != null && payload.isNotEmpty) {
            _routeOrQueueLaunchPayload(payload);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error checking local notification launch details: $e');
        }
      }
    } else {
      flushPendingLaunchNavigation();
    }
  }

  /// Rest-day-aware streak reminder: Scheduled for 48 hours out (allowing 1-2 rest days without guilt warnings)
  Future<void> scheduleStreakReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool enabled =
          prefs.getBool('notif_streak_reminders_enabled') ?? true;
      if (!enabled) {
        await _localNotificationsPlugin.cancel(id: 1);
        return;
      }

      final hasPerm = await hasNotificationPermission();
      if (!hasPerm) return;

      // Cancel existing streak reminders (ID: 1)
      await _localNotificationsPlugin.cancel(id: 1);

      // Schedule for 48 hours from now (aligned with rest-day allowance)
      final tz.TZDateTime scheduledDate =
          _currentTzNow().add(const Duration(hours: 48));

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
              'streak_reminder', 'Streak Reminders',
              channelDescription: 'Reminds you to keep your streak alive',
              importance: Importance.high,
              priority: Priority.high,
              showWhen: true);
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      final scheduleMode = await _resolveScheduleMode();
      await _localNotificationsPlugin.zonedSchedule(
          id: 1,
          title: 'Keep Your Momentum Going! 🔥',
          body:
              'Great consistency so far! Step into the gym or log today\'s session to extend your streak.',
          scheduledDate: scheduledDate,
          notificationDetails: platformChannelSpecifics,
          payload: '${Routes.dayWorkoutSessionRoute}?day=today',
          androidScheduleMode: scheduleMode);

      if (kDebugMode) {
        print('Scheduled rest-day aware streak reminder for $scheduledDate');
      }
    } catch (e) {
      if (kDebugMode) print('Failed to schedule streak reminder: $e');
    }
  }

  Future<void> cancelStreakReminder() async {
    await _localNotificationsPlugin.cancel(id: 1);
  }

  /// Smart Workout Day Reminders: Schedules recurring weekly reminders for each split day at user's preferred time
  Future<void> scheduleWorkoutDayReminders({
    required List<String> scheduledDays,
    required TimeOfDay time,
    List<String> completedDays = const [],
  }) async {
    try {
      // Cancel previous workout reminders (IDs 20 to 26)
      for (int i = 0; i < 7; i++) {
        await _localNotificationsPlugin.cancel(id: 20 + i);
      }

      final prefs = await SharedPreferences.getInstance();
      final normalizedDays = <String>[];
      for (final rawDay in scheduledDays) {
        final canonical = _normalizeWeekdayName(rawDay);
        if (canonical != null && !normalizedDays.contains(canonical)) {
          normalizedDays.add(canonical);
        }
      }
      await prefs.setStringList(scheduledReminderDaysPrefKey, normalizedDays);

      final bool enabled =
          prefs.getBool('notif_workout_reminders_enabled') ?? false;
      if (!enabled) return;

      final hasPerm = await hasNotificationPermission();
      if (!hasPerm) return;

      final tz.TZDateTime now = _currentTzNow();

      for (var day in normalizedDays) {
        final dayIndex = _weekDays.indexOf(day);
        if (dayIndex == -1) continue;

        int targetWeekday = dayIndex + 1;
        int daysUntil = (targetWeekday - now.weekday) % 7;
        if (daysUntil < 0) daysUntil += 7;

        final targetDate = DateTime(now.year, now.month, now.day + daysUntil);
        tz.TZDateTime scheduledDate = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          time.hour,
          time.minute,
        );

        // If time already passed today, or if this day's workout is already completed today, advance to next week
        final isAlreadyCompletedToday =
            completedDays.any((d) => d.trim().toLowerCase() == day.toLowerCase());
        if (!scheduledDate.isAfter(now) ||
            (daysUntil == 0 && isAlreadyCompletedToday)) {
          final nextWeekDate =
              DateTime(targetDate.year, targetDate.month, targetDate.day + 7);
          scheduledDate = tz.TZDateTime(
            tz.local,
            nextWeekDate.year,
            nextWeekDate.month,
            nextWeekDate.day,
            time.hour,
            time.minute,
          );
        }

        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
                'workout_reminders', 'Workout Reminders',
                channelDescription: 'Reminds you when it is time to work out',
                importance: Importance.max,
                priority: Priority.high,
                showWhen: true);
        const NotificationDetails details =
            NotificationDetails(android: androidDetails);

        final scheduleMode = await _resolveScheduleMode();
        await _localNotificationsPlugin.zonedSchedule(
            id: 20 + dayIndex,
            title: '$day Workout Time! 💪',
            body:
                'Today is your scheduled workout session. Open Gym Buddy to track your lifts!',
            scheduledDate: scheduledDate,
            notificationDetails: details,
            payload: '${Routes.dayWorkoutSessionRoute}?day=$day',
            androidScheduleMode: scheduleMode,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);
      }

      if (kDebugMode) {
        print(
            'Scheduled weekly workout reminders for $normalizedDays at $time');
      }
    } catch (e) {
      if (kDebugMode) print('Failed to schedule workout day reminders: $e');
    }
  }

  Future<void> cancelWorkoutDayReminders() async {
    for (int i = 0; i < 7; i++) {
      await _localNotificationsPlugin.cancel(id: 20 + i);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(scheduledReminderDaysPrefKey);
    } catch (_) {}
  }

  /// When today's workout is completed, advances today's recurring reminder by 7 days
  /// ONLY if today is genuinely a scheduled workout day, without canceling or affecting
  /// any other scheduled training day reminder IDs or creating reminders on rest days.
  Future<void> advanceTodayWorkoutReminderIfScheduled({
    Iterable<String>? scheduledDays,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool enabled =
          prefs.getBool('notif_workout_reminders_enabled') ?? false;
      if (!enabled) return;

      final hasPerm = await hasNotificationPermission();
      if (!hasPerm) return;

      final tz.TZDateTime now = _currentTzNow();
      final int todayIndex = now.weekday - 1; // 0 for Monday .. 6 for Sunday
      final String todayName = _weekDays[todayIndex];

      // Determine the user's scheduled workout days
      Iterable<String>? rawScheduledDays = scheduledDays;
      if (rawScheduledDays == null) {
        final storedReminderDays =
            prefs.getStringList(scheduledReminderDaysPrefKey);
        if (storedReminderDays != null && storedReminderDays.isNotEmpty) {
          rawScheduledDays = storedReminderDays;
        } else {
          rawScheduledDays = prefs.getStringList(scheduledWorkoutDaysPrefKey);
        }
      }

      if (rawScheduledDays == null) return;

      final bool isTodayScheduled = rawScheduledDays.any(
        (day) => _normalizeWeekdayName(day) == todayName,
      );
      if (!isTodayScheduled) {
        return;
      }

      final int notifId = 20 + todayIndex;

      // Cancel only today's notification ID to prevent duplicates
      await _localNotificationsPlugin.cancel(id: notifId);

      final int hour =
          prefs.getInt('notif_workout_hour') ?? defaultWorkoutReminderHour;
      final int minute =
          prefs.getInt('notif_workout_minute') ?? defaultWorkoutReminderMinute;

      // Advance by 7 calendar days to next week's same weekday (even if completed before today's reminder time)
      final nextWeekDate = DateTime(now.year, now.month, now.day + 7);
      final tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        nextWeekDate.year,
        nextWeekDate.month,
        nextWeekDate.day,
        hour,
        minute,
      );

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
              'workout_reminders', 'Workout Reminders',
              channelDescription: 'Reminds you when it is time to work out',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true);
      const NotificationDetails details =
          NotificationDetails(android: androidDetails);

      final scheduleMode = await _resolveScheduleMode();
      await _localNotificationsPlugin.zonedSchedule(
          id: notifId,
          title: '$todayName Workout Time! 💪',
          body:
              'Today is your scheduled workout session. Open Gym Buddy to track your lifts!',
          scheduledDate: scheduledDate,
          notificationDetails: details,
          payload: '${Routes.dayWorkoutSessionRoute}?day=$todayName',
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);

      if (kDebugMode) {
        print(
            'Advanced today\'s ($todayName) workout reminder to $scheduledDate without altering other days.');
      }
    } catch (e) {
      if (kDebugMode) print('Failed to advance today\'s workout reminder: $e');
    }
  }

  /// Rest Day Recovery Notification: Friendly morning tip on planned recovery days
  Future<void> scheduleRestDayReminders({
    required List<String> restDays,
  }) async {
    try {
      // Cancel previous rest reminders (IDs 30 to 36)
      for (int i = 0; i < 7; i++) {
        await _localNotificationsPlugin.cancel(id: 30 + i);
      }

      final prefs = await SharedPreferences.getInstance();
      final bool enabled =
          prefs.getBool('notif_recovery_reminders_enabled') ?? false;
      if (!enabled) return;

      final hasPerm = await hasNotificationPermission();
      if (!hasPerm) return;

      const weekDays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      for (var day in restDays) {
        final dayIndex = weekDays.indexOf(day);
        if (dayIndex == -1) continue;

        tz.TZDateTime now = tz.TZDateTime.now(tz.local);
        int targetWeekday = dayIndex + 1;
        int daysUntil = (targetWeekday - now.weekday) % 7;
        if (daysUntil < 0) daysUntil += 7;

        // Morning recovery reminder at 9:00 AM
        tz.TZDateTime scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + daysUntil,
          9,
          0,
        );

        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 7));
        }

        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
                'recovery_reminders', 'Recovery Reminders',
                channelDescription: 'Recovery tips on planned rest days',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                showWhen: true);
        const NotificationDetails details =
            NotificationDetails(android: androidDetails);

        final scheduleMode = await _resolveScheduleMode();
        await _localNotificationsPlugin.zonedSchedule(
            id: 30 + dayIndex,
            title: 'Recovery & Rest Day 🧘',
            body: 'Planned rest day today! Muscles grow when you rest. Stay hydrated and eat well.',
            scheduledDate: scheduledDate,
            notificationDetails: details,
            payload: Routes.mainRoute,
            androidScheduleMode: scheduleMode,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);
      }
    } catch (e) {
      if (kDebugMode) print('Failed to schedule rest day reminders: $e');
    }
  }

  Future<void> cancelRestDayReminders() async {
    for (int i = 0; i < 7; i++) {
      await _localNotificationsPlugin.cancel(id: 30 + i);
    }
  }

  Future<void> scheduleWaterReminder() async {
    try {
      // Cancel existing water reminders (ID: 2)
      await _localNotificationsPlugin.cancel(id: 2);

      final prefs = await SharedPreferences.getInstance();
      final bool enabled =
          prefs.getBool('notif_water_reminders_enabled') ?? false;
      if (!enabled) return;

      final hasPerm = await hasNotificationPermission();
      if (!hasPerm) return;

      // Schedule for 6 PM today (or tomorrow if it's already past 6 PM)
      tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 18);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
              'water_reminder', 'Water Reminders',
              channelDescription: 'Reminds you to drink water',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority);
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      final scheduleMode = await _resolveScheduleMode();
      await _localNotificationsPlugin.zonedSchedule(
          id: 2,
          title: '💧 Drink Water',
          body: 'It is 6 PM! Have you reached your water goal for today?',
          scheduledDate: scheduledDate,
          notificationDetails: platformChannelSpecifics,
          payload: Routes.addWaterRoute,
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: DateTimeComponents.time);
              
      if (kDebugMode) print('Scheduled daily water reminder for $scheduledDate');
    } catch (e) {
      if (kDebugMode) print('Failed to schedule water reminder: $e');
    }
  }

  Future<void> cancelWaterReminder() async {
    await _localNotificationsPlugin.cancel(id: 2);
    if (kDebugMode) print('Cancelled water reminder');
  }

  Future<void> scheduleReEngagementNotifications() async {
    try {
      // Cancel existing ones
      await _localNotificationsPlugin.cancel(id: 10);
      await _localNotificationsPlugin.cancel(id: 11);
      await _localNotificationsPlugin.cancel(id: 12);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
              're_engagement', 'Re-engagement',
              channelDescription: 'Reminds you to come back to the app',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority);
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      final now = tz.TZDateTime.now(tz.local);
      final scheduleMode = await _resolveScheduleMode();

      // 3 Days
      await _localNotificationsPlugin.zonedSchedule(
          id: 10,
          title: 'We miss you! 😢',
          body: 'It\'s been 3 days! Your muscles are missing you. Come back for a quick workout.',
          scheduledDate: now.add(const Duration(days: 3)),
          notificationDetails: platformChannelSpecifics,
          androidScheduleMode: scheduleMode);

      // 7 Days
      await _localNotificationsPlugin.zonedSchedule(
          id: 11,
          title: 'Don\'t lose your progress! 📉',
          body: 'It\'s been a week. Even a 5-minute stretch helps keep the momentum going!',
          scheduledDate: now.add(const Duration(days: 7)),
          notificationDetails: platformChannelSpecifics,
          androidScheduleMode: scheduleMode);

      // 14 Days
      await _localNotificationsPlugin.zonedSchedule(
          id: 12,
          title: 'Time to get back in the gym! 💪',
          body: 'We haven\'t seen you in two weeks. Start fresh today with a light workout!',
          scheduledDate: now.add(const Duration(days: 14)),
          notificationDetails: platformChannelSpecifics,
          androidScheduleMode: scheduleMode);

      if (kDebugMode) print('Scheduled re-engagement notifications for 3, 7, and 14 days.');
    } catch (e) {
      if (kDebugMode) print('Failed to schedule re-engagement notifications: $e');
    }
  }

  Future<void> scheduleDailyGymAlarm(TimeOfDay time) async {
    try {
      // Cancel any existing alarm first
      await cancelDailyGymAlarm();

      final prefs = await SharedPreferences.getInstance();
      final bool enabled = prefs.getBool('gym_alarm_enabled') ?? false;
      if (!enabled) return;

      final hasPerm = await hasNotificationPermission();
      if (!hasPerm) return;

      _configureLocalTimeZone();
      tz.TZDateTime now = _currentTzNow();
      tz.TZDateTime scheduledDate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Ensure high-priority alarm notification channel is registered on Android
      try {
        final androidImpl = _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
            'gym_alarm',
            'Gym Alarm',
            description: 'Daily alarm for your gym session',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          );
          await androidImpl.createNotificationChannel(alarmChannel);
        }
      } catch (e) {
        if (kDebugMode) print('Error creating alarm channel: $e');
      }

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
              'gym_alarm', 'Gym Alarm',
              channelDescription: 'Daily alarm for your gym session',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              enableVibration: true,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              audioAttributesUsage: AudioAttributesUsage.alarm);
      
      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      final scheduleMode = await _resolveScheduleMode();
      await _localNotificationsPlugin.zonedSchedule(
          id: 3, // ID for gym alarm
          title: '⏰ Gym Time!',
          body: 'It\'s time for your daily workout. Let\'s get it!',
          scheduledDate: scheduledDate,
          notificationDetails: platformChannelSpecifics,
          payload: '${Routes.dayWorkoutSessionRoute}?day=today',
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: DateTimeComponents.time);

      if (kDebugMode) print('Scheduled daily gym alarm for $scheduledDate');
    } catch (e) {
      if (kDebugMode) print('Failed to schedule gym alarm: $e');
    }
  }

  Future<void> rescheduleDailyGymAlarmIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool enabled = prefs.getBool('gym_alarm_enabled') ?? false;
      if (enabled) {
        final hour = prefs.getInt('gym_alarm_hour') ?? 6;
        final minute = prefs.getInt('gym_alarm_minute') ?? 0;
        await scheduleDailyGymAlarm(TimeOfDay(hour: hour, minute: minute));
      }
    } catch (e) {
      if (kDebugMode) print('Failed to reschedule daily gym alarm: $e');
    }
  }

  Future<void> cancelDailyGymAlarm() async {
    await _localNotificationsPlugin.cancel(id: 3);
    if (kDebugMode) print('Cancelled daily gym alarm');
  }

  Future<void> saveTokenToDatabase() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  Future<void> _saveToken(String token) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'fcm_tokens': FieldValue.arrayUnion([token]),
          'last_token_update': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        if (kDebugMode) {
          print('FCM Token successfully saved/updated in Firestore: $token');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error saving FCM token to Firestore: $e');
        }
      }
    }
  }
}
