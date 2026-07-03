import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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

  Future<void> initialize() async {
    try {
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
          // In the future, we could trigger custom alerts or banners here.
        }
      });

      // 6. Handle notification tap when app is in background but not terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('A new onMessageOpenedApp event was published!');
        }
      });

      // 7. Check if app was opened from terminated state via a notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print('App opened from terminated state via notification: ${initialMessage.messageId}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e');
      }
    }
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
