import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/services/review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Setup SharedPreferences mock initial values
  Map<String, Object> values = <String, Object>{};
  SharedPreferences.setMockInitialValues(values);

  group('ReviewService Counter Tests', () {
    final reviewService = ReviewService();

    test('Initial states should be empty or zero', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('review_app_launch_count'), null);
      expect(prefs.getInt('review_workouts_logged_count'), null);
      expect(prefs.getBool('review_has_prompted'), null);
    });

    test('incrementAppLaunches should increment preferences launch count', () async {
      final prefs = await SharedPreferences.getInstance();
      
      await reviewService.incrementAppLaunches();
      expect(prefs.getInt('review_app_launch_count'), 1);

      await reviewService.incrementAppLaunches();
      expect(prefs.getInt('review_app_launch_count'), 2);
    });

    test('incrementWorkoutsLogged should increment logged workouts count', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Initially null/0
      await reviewService.incrementWorkoutsLogged();
      expect(prefs.getInt('review_workouts_logged_count'), 1);

      await reviewService.incrementWorkoutsLogged();
      expect(prefs.getInt('review_workouts_logged_count'), 2);
    });
  });
}
