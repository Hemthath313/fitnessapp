import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/services/review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReviewService Counter and Gated Milestone Tests', () {
    final reviewService = ReviewService();

    setUp(() {
      // Re-initialize mock preferences with empty values before each test
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

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
      
      await reviewService.incrementWorkoutsLogged();
      expect(prefs.getInt('review_workouts_logged_count'), 1);

      await reviewService.incrementWorkoutsLogged();
      expect(prefs.getInt('review_workouts_logged_count'), 2);
    });

    test('should return true for eligibility when both milestones are met', () async {
      final prefs = await SharedPreferences.getInstance();

      // Increment launches 5 times
      for (int i = 0; i < 5; i++) {
        await reviewService.incrementAppLaunches();
      }
      expect(prefs.getInt('review_app_launch_count'), 5);

      // Increment workouts 2 times -> should return false
      bool eligible = await reviewService.incrementWorkoutsLogged();
      expect(eligible, false);

      eligible = await reviewService.incrementWorkoutsLogged();
      expect(eligible, false);

      // 3rd workout logged -> should return true (milestones met!)
      eligible = await reviewService.incrementWorkoutsLogged();
      expect(eligible, true);
    });

    test('should not show prompt or increment if already marked as prompted', () async {
      final prefs = await SharedPreferences.getInstance();

      // Pre-set prompted state to true
      await reviewService.markAsPrompted();
      expect(prefs.getBool('review_has_prompted'), true);

      // Attempt to increment should stop/return false
      await reviewService.incrementAppLaunches();
      // Should remain null (early exits)
      expect(prefs.getInt('review_app_launch_count'), null);

      bool eligible = await reviewService.incrementWorkoutsLogged();
      expect(eligible, false);
      expect(prefs.getInt('review_workouts_logged_count'), null);
    });
  });
}
