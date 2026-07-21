import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fitness_app/app/app.dart';
import 'package:fitness_app/utils/ad_config.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';

void main() {
  // Run the app with error zone to catch all Dart errors
  runZonedGuarded(
    () async {
      // FIRST: Ensure Flutter framework is initialized INSIDE the zone
      WidgetsFlutterBinding.ensureInitialized();

      // THEN: Load environment variables (with error handling)
      try {
        await dotenv.load(fileName: "lib/.env");
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Warning: .env file not found.');
        }
      }

      // Initialize Gemini
      if (dotenv.env['GEMINI_API_KEY'] != null) {
        Gemini.init(apiKey: dotenv.env['GEMINI_API_KEY']!);
      }

      // Initialize Firebase
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
        
        await FirebaseAppCheck.instance.activate(
          androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        );
      } catch (e) {
        debugPrint('Firebase initialization error: $e');
      }

      // Initialize Google Mobile Ads
      await MobileAds.instance.initialize();

      // Set up Crashlytics
      if (!kDebugMode) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      }
      
      // Initialize Local Notifications
      final notificationService = NotificationService();
      await notificationService.initializeLocalNotifications();

      runApp(const MyApp());
    },
    (error, stackTrace) {
      // Send all Dart errors to Crashlytics
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: 'Uncaught Dart exception',
          printDetails: true,
        );
      } else {
        debugPrint('Uncaught error: $error\n$stackTrace');
      }
    },
  );
}
