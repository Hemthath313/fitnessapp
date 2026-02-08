import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fitness_app/app/app.dart';
import 'package:fitness_app/utils/ad_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // FIRST: Ensure Flutter framework is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // THEN: Load environment variables (with error handling)
  try {
    await dotenv.load(fileName: "lib/.env");
  } catch (e) {
    // Handle missing .env file gracefully
    if (kDebugMode) {
      debugPrint(
          'Warning: .env file not found. Some features may not work properly.');
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
    
    // Activate App Check
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue anyway, as some features might work and we don't want to hang the app
  }

  // Initialize Google Mobile Ads
  await MobileAds.instance.initialize();

  // Print ad configuration for debugging
  if (kDebugMode) {
    AdConfig.printAdConfig();
  }

  // Set up Crashlytics (only in production)
  if (!kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }

  // Pass all uncaught Flutter errors to Crashlytics
  FlutterError.onError = (errorDetails) {
    if (kDebugMode) {
      // Print to console in debug mode
      FlutterError.dumpErrorToConsole(errorDetails);
    } else {
      // Send to Crashlytics in production
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    }
  };

  // Run the app with error zone to catch all Dart errors
  runZonedGuarded(
    () => runApp(MyApp()),
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
        // Just print in debug mode
        debugPrint('Uncaught error: $error\n$stackTrace');
      }
    },
  );
}
