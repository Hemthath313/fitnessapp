import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      // 0. Initialize local notifications first (needed for scheduled reminders)
      await initializeLocalNotifications();

      // 1. Request Permission (essential for iOS and Android 13+)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User granted notification permission: ${settings.authorizationStatus}');
      }

      // 2. Set up Background Message Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Save FCM token for the user if logged in
      await saveTokenToDatabase();

      // 4. Listen to token refreshes
      _messaging.onTokenRefresh.listen((token) async {
        await _saveToken(token);
      });

      // 5. Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
        }

        if (message.notification != null) {
          if (kDebugMode) {
            print('Message also contained a notification: ${message.notification?.title}');
          }
        }
      });

      // 6. Handle notification tap when app is in background but not terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('A new onMessageOpenedApp event was published!');
        }
        _handleNotificationRoute(message.data);
      });

      // 7. Check if app was opened from terminated state via a notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print('App opened from terminated state via notification: ${initialMessage.messageId}');
        }
        _handleNotificationRoute(initialMessage.data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e');
      }
    }
  }

  void _handleNotificationRoute(Map<String, dynamic> data) {
    try {
      final route = data['route'] as String?;
      if (route != null && route.isNotEmpty) {
        router.push(route);
      }
    } catch (e) {
      if (kDebugMode) print('Error routing notification: $e');
    }
  }

  Future<void> initializeLocalNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            router.push(payload);
          } catch (e) {
            if (kDebugMode) print('Error navigating from local notification payload: $e');
          }
        }
      },
    );

    // Request permissions for Android 13+
    _localNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  Future<void> scheduleStreakReminder() async {
    try {
      // Cancel existing streak reminders (ID: 1)
      await _localNotificationsPlugin.cancel(id: 1);

      // Schedule for 24 hours from now
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
              'streak_reminder', 'Streak Reminders',
              channelDescription: 'Reminds you to keep your streak alive',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true);
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotificationsPlugin.zonedSchedule(
          id: 1,
          title: '🚨 Streak Danger!',
          body: 'You are about to lose your streak. Log a glass of water or a quick workout to keep it alive!',
          scheduledDate: scheduledDate,
          notificationDetails: platformChannelSpecifics,
          payload: Routes.workoutLogRoute,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
              
      if (kDebugMode) print('Scheduled streak reminder for $scheduledDate');
    } catch (e) {
      if (kDebugMode) print('Failed to schedule streak reminder: $e');
    }
  }

  Future<void> scheduleWaterReminder() async {
    try {
      // Cancel existing water reminders (ID: 2)
      await _localNotificationsPlugin.cancel(id: 2);

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

      await _localNotificationsPlugin.zonedSchedule(
          id: 2,
          title: '💧 Drink Water',
          body: 'It is 6 PM! Have you reached your water goal for today?',
          scheduledDate: scheduledDate,
          notificationDetails: platformChannelSpecifics,
          payload: Routes.addWaterRoute,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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

      // 3 Days
      await _localNotificationsPlugin.zonedSchedule(
          id: 10,
          title: 'We miss you! 😢',
          body: 'It\'s been 3 days! Your muscles are missing you. Come back for a quick workout.',
          scheduledDate: now.add(const Duration(days: 3)),
          notificationDetails: platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);

      // 7 Days
      await _localNotificationsPlugin.zonedSchedule(
          id: 11,
          title: 'Don\'t lose your progress! 📉',
          body: 'It\'s been a week. Even a 5-minute stretch helps keep the momentum going!',
          scheduledDate: now.add(const Duration(days: 7)),
          notificationDetails: platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);

      // 14 Days
      await _localNotificationsPlugin.zonedSchedule(
          id: 12,
          title: 'Time to get back in the gym! 💪',
          body: 'We haven\'t seen you in two weeks. Start fresh today with a light workout!',
          scheduledDate: now.add(const Duration(days: 14)),
          notificationDetails: platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);

      if (kDebugMode) print('Scheduled re-engagement notifications for 3, 7, and 14 days.');
    } catch (e) {
      if (kDebugMode) print('Failed to schedule re-engagement notifications: $e');
    }
  }

  Future<void> scheduleDailyGymAlarm(TimeOfDay time) async {
    try {
      // Cancel any existing alarm first
      await cancelDailyGymAlarm();

      tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
              'gym_alarm', 'Gym Alarm',
              channelDescription: 'Daily alarm for your gym session',
              importance: Importance.max,
              priority: Priority.high,
              sound: null, // Uses default notification sound for now
              playSound: true,
              enableVibration: true,
              fullScreenIntent: true); // Wake up screen/show as high priority
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotificationsPlugin.zonedSchedule(
          id: 3, // ID for gym alarm
          title: '⏰ Gym Time!',
          body: 'It\'s time for your daily workout. Let\'s get it!',
          scheduledDate: scheduledDate,
          notificationDetails: platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time);

      if (kDebugMode) print('Scheduled daily gym alarm for $scheduledDate');
    } catch (e) {
      if (kDebugMode) print('Failed to schedule gym alarm: $e');
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
