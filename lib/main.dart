import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fitness_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: "lib/.env");

  // Ensure Flutter framework is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

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
