import 'package:fitness_app/presentation/home/widgets/achievements_widget.dart';
import 'package:fitness_app/presentation/home/widgets/next_badge_card.dart';
import 'package:fitness_app/services/badge_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextBadgeProgress', () {
    test('new user: First Flame is next and asks for one workout', () {
      final p = nextBadgeProgress(
          unlocked: const [], totalWorkouts: 0, currentStreak: 0)!;
      expect(p.def.id, 'First Workout');
      expect(p.message, 'Finish one workout to earn First Flame');
      expect(p.fraction, 0);
    });

    test('picks the badge with the highest completed share', () {
      final p = nextBadgeProgress(
        unlocked: const ['First Workout'],
        totalWorkouts: 7,
        currentStreak: 2,
      )!;
      expect(p.def.id, 'Strong Start'); // 7/10 beats 2/7
      expect(p.remaining, 3);
      expect(p.message, '3 more workouts to unlock Strong Start');
      expect(p.counter, '7 / 10');
    });

    test('streak badge uses days-in-a-row wording and singular', () {
      final p = nextBadgeProgress(
        unlocked: const ['First Workout', 'Strong Start'],
        totalWorkouts: 12,
        currentStreak: 6,
      )!;
      expect(p.def.id, '7 Day Streak');
      expect(p.message, '1 more day in a row to unlock 7-Day Warrior');
    });

    test('skips badges whose goal is met but not yet recorded', () {
      final p = nextBadgeProgress(
        unlocked: const [],
        totalWorkouts: 3,
        currentStreak: 7,
      )!;
      expect(p.def.id, isNot('First Workout'));
      expect(p.def.id, isNot('7 Day Streak'));
    });

    test('returns null when every badge is unlocked', () {
      final p = nextBadgeProgress(
        unlocked: kBadgeRules.keys,
        totalWorkouts: 400,
        currentStreak: 120,
      );
      expect(p, isNull);
    });
  });

  group('badge rules', () {
    test('every rule has a badge definition and vice versa', () {
      final defIds = allAchievements.map((a) => a.id).toSet();
      expect(defIds, kBadgeRules.keys.toSet());
      expect(allAchievements.length, 15);
    });

    test('badge ids and titles are unique', () {
      expect(allAchievements.map((a) => a.id).toSet().length,
          allAchievements.length);
      expect(allAchievements.map((a) => a.title).toSet().length,
          allAchievements.length);
    });

    test('first workout unlocks First Workout only', () {
      expect(
        badgesToUnlock(
            alreadyUnlocked: const [], totalWorkouts: 1, currentStreak: 1),
        ['First Workout'],
      );
    });

    test('three workouts over three days unlocks the three early badges', () {
      expect(
        badgesToUnlock(
            alreadyUnlocked: const ['First Workout'],
            totalWorkouts: 3,
            currentStreak: 3),
        ['Hat Trick', '3 Day Streak'],
      );
    });

    test('already unlocked badges are not returned again', () {
      expect(
        badgesToUnlock(
            alreadyUnlocked: kBadgeRules.keys,
            totalWorkouts: 999,
            currentStreak: 999),
        isEmpty,
      );
    });

    test('streak and workout metrics are independent', () {
      final ids = badgesToUnlock(
          alreadyUnlocked: const [], totalWorkouts: 0, currentStreak: 14);
      expect(ids, containsAll(['3 Day Streak', '7 Day Streak', '14 Day Streak']));
      expect(ids, isNot(contains('First Workout')));
      expect(ids, isNot(contains('21 Day Streak')));
    });

    test('targets rise within each metric when read in list order', () {
      for (final metric in BadgeMetric.values) {
        final targets = [
          for (final a in allAchievements)
            if (kBadgeRules[a.id]!.metric == metric) kBadgeRules[a.id]!.target
        ];
        final sorted = [...targets]..sort();
        expect(targets, sorted, reason: '$metric');
      }
    });
  });
}
