import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('workout-date refresh policy', () {
    final now = DateTime(2026, 11, 9, 18);

    test('a fresh provider must read history before calculating', () {
      expect(StatisticsProvider().shouldRefetchDates(now), isTrue);
    });

    test('recently read history is reused', () {
      final provider = StatisticsProvider()..markDatesFetchedForTesting(now);
      expect(provider.shouldRefetchDates(now), isFalse);
      expect(
        provider.shouldRefetchDates(
          now.add(StatisticsProvider.datesRefreshInterval),
        ),
        isFalse,
      );
    });

    test('stale history is read again', () {
      final provider = StatisticsProvider()..markDatesFetchedForTesting(now);
      expect(
        provider.shouldRefetchDates(
          now.add(StatisticsProvider.datesRefreshInterval +
              const Duration(minutes: 1)),
        ),
        isTrue,
      );
    });

    test('a failed read is never trusted', () {
      final provider = StatisticsProvider()
        ..markDatesFetchedForTesting(now)
        ..markDatesFetchedForTesting(null);
      expect(provider.shouldRefetchDates(now), isTrue);
    });
  });

  group('updateStreak still produces the same result', () {
    test('adds today to existing history and extends the streak', () async {
      final today = DateTime(2026, 11, 9, 18);
      final provider = StatisticsProvider()
        ..configureStreakStateForTesting(
          completedDates: [
            DateTime(2026, 11, 7, 18),
            DateTime(2026, 11, 8, 18),
          ],
          lastWorkoutDate: DateTime(2026, 11, 8, 18),
          storedStreak: 2,
          referenceNow: today,
        )
        ..markDatesFetchedForTesting(today);

      await provider.updateStreak();

      expect(provider.hasWorkoutOnDate(today), isTrue);
      expect(provider.currentStreak, 3);
      expect(provider.longestStreak, greaterThanOrEqualTo(3));
      expect(provider.completedWorkoutDates.length, 3);
    });

    test('finishing twice in one day does not double count', () async {
      final today = DateTime(2026, 11, 9, 18);
      final provider = StatisticsProvider()
        ..configureStreakStateForTesting(
          completedDates: [DateTime(2026, 11, 8, 18)],
          lastWorkoutDate: DateTime(2026, 11, 8, 18),
          storedStreak: 1,
          referenceNow: today,
        );

      await provider.updateStreak();
      await provider.updateStreak();

      expect(provider.currentStreak, 2);
      expect(provider.completedWorkoutDates.length, 2);
    });
  });
}
