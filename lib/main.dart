import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fitness_app/app/app.dart';
import 'package:fitness_app/services/ad_consent_service.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/utils/units.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_gemini/flutter_gemini.dart';
import 'firebase_options.dart';

void main() {
  // Run the app with error zone to catch all Dart errors
  runZonedGuarded(
    () async {
      // FIRST: Ensure Flutter framework is initialized INSIDE the zone
      WidgetsFlutterBinding.ensureInitialized();

      // THEN: Load environment variables (with error handling)
      try {
        await dotenv.load(fileName: "lib/.env", isOptional: true);
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
      } catch (e, st) {
        debugPrint('Firebase initialization error: $e\n$st');
      }

      // App Check is optional; a failure here must not break the app.
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider:
              kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
          appleProvider: kDebugMode
              ? AppleProvider.debug
              : AppleProvider.appAttestWithDeviceCheckFallback,
        );
      } catch (e) {
        debugPrint('Firebase App Check error: $e');
      }

      // Mobile Ads starts after the consent check (see AdConsentService),
      // not here, so EU users are asked before any ad request.

      // Set up Crashlytics: widget/build errors and platform errors, not
      // only the async errors runZonedGuarded catches.
      if (!kDebugMode) {
        try {
          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
          FlutterError.onError =
              FirebaseCrashlytics.instance.recordFlutterFatalError;
          PlatformDispatcher.instance.onError = (error, stack) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true;
          };
        } catch (e) {
          debugPrint('Crashlytics setup error: $e');
        }
      }
      
      // Initialize Local Notifications
      final notificationService = NotificationService();
      await notificationService.initializeLocalNotifications();

      // Lifting weight unit (kg / lb), used by every weight screen.
      await Units.load();

      runApp(const MyApp());

      // Consent form (EU/UK) and then the ads SDK, without blocking startup.
      unawaited(AdConsentService.initialize());
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
