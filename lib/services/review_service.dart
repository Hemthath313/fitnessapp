import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  static const String _keyLaunchCount = 'review_app_launch_count';
  static const String _keyWorkoutCount = 'review_workouts_logged_count';
  static const String _keyHasPrompted = 'review_has_prompted';

  final InAppReview _inAppReview = InAppReview.instance;

  // Configuration thresholds
  static const int _launchThreshold = 5;
  static const int _workoutThreshold = 3;

  /// Increments the app launch counter and checks eligibility
  Future<void> incrementAppLaunches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // If already prompted, no need to keep counting
      if (prefs.getBool(_keyHasPrompted) ?? false) return;

      int currentLaunches = prefs.getInt(_keyLaunchCount) ?? 0;
      currentLaunches++;
      await prefs.setInt(_keyLaunchCount, currentLaunches);

      if (kDebugMode) {
        print('ReviewService: App Launch Count incremented to $currentLaunches');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ReviewService: Error incrementing launches: $e');
      }
    }
  }

  /// Increments the workouts logged counter and triggers prompt check if eligible
  Future<bool> incrementWorkoutsLogged() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // If already prompted, stop
      if (prefs.getBool(_keyHasPrompted) ?? false) return false;

      int currentWorkouts = prefs.getInt(_keyWorkoutCount) ?? 0;
      currentWorkouts++;
      await prefs.setInt(_keyWorkoutCount, currentWorkouts);

      if (kDebugMode) {
        print('ReviewService: Workouts Logged Count incremented to $currentWorkouts');
      }

      return await _isEligibleForPrompt();
    } catch (e) {
      if (kDebugMode) {
        print('ReviewService: Error incrementing workouts: $e');
      }
      return false;
    }
  }

  /// Checks if counts meet thresholds and hasn't prompted yet
  Future<bool> _isEligibleForPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (prefs.getBool(_keyHasPrompted) ?? false) return false;

      final int launches = prefs.getInt(_keyLaunchCount) ?? 0;
      final int workouts = prefs.getInt(_keyWorkoutCount) ?? 0;

      return launches >= _launchThreshold && workouts >= _workoutThreshold;
    } catch (e) {
      return false;
    }
  }

  /// Marks the review as prompted in shared preferences
  Future<void> markAsPrompted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasPrompted, true);
      if (kDebugMode) {
        print('ReviewService: Gated review marked as prompted.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ReviewService: Error marking as prompted: $e');
      }
    }
  }

  /// Triggers the native in-app store review prompt
  Future<void> requestNativeReview() async {
    try {
      final bool isAvailable = await _inAppReview.isAvailable();
      if (isAvailable) {
        await _inAppReview.requestReview();
        if (kDebugMode) {
          print('ReviewService: Native In-App Review Prompt triggered successfully.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ReviewService: Error during native review request: $e');
      }
    }
  }

  /// Explicitly redirects user to the App Store or Google Play Store listing
  Future<void> openStoreListing() async {
    try {
      if (await _inAppReview.isAvailable()) {
        // AppStore ID is optional on Android, but required for iOS store redirect
        await _inAppReview.openStoreListing(
          appStoreId: 'com.gymbuddy.fitnessapp', // Will use fallback for Android, custom bundle for iOS
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('ReviewService: Error opening store listing: $e');
      }
    }
  }
}
