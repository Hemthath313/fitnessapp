/// What a badge is measured in.
enum BadgeMetric { workouts, streakDays }

/// One badge goal: reach [target] in [metric].
typedef BadgeRule = ({BadgeMetric metric, int target});

/// How each badge in `allAchievements` is earned. This is the single source
/// of truth shared by the unlock check (`StatisticsProvider`) and the
/// "next badge" progress UI. Every key needs a matching `AchievementDef`.
const Map<String, BadgeRule> kBadgeRules = {
  'First Workout': (metric: BadgeMetric.workouts, target: 1),
  'Hat Trick': (metric: BadgeMetric.workouts, target: 3),
  '3 Day Streak': (metric: BadgeMetric.streakDays, target: 3),
  'Strong Start': (metric: BadgeMetric.workouts, target: 10),
  '7 Day Streak': (metric: BadgeMetric.streakDays, target: 7),
  '14 Day Streak': (metric: BadgeMetric.streakDays, target: 14),
  '21 Day Streak': (metric: BadgeMetric.streakDays, target: 21),
  '25 Workouts': (metric: BadgeMetric.workouts, target: 25),
  'Half Century': (metric: BadgeMetric.workouts, target: 50),
  'Monthly Warrior': (metric: BadgeMetric.streakDays, target: 30),
  '60 Day Streak': (metric: BadgeMetric.streakDays, target: 60),
  'Centurion': (metric: BadgeMetric.workouts, target: 100),
  '100 Day Streak': (metric: BadgeMetric.streakDays, target: 100),
  'Double Century': (metric: BadgeMetric.workouts, target: 200),
  'Iron Year': (metric: BadgeMetric.workouts, target: 365),
};

/// The user's current value for [metric].
int badgeValue(
  BadgeMetric metric, {
  required int totalWorkouts,
  required int currentStreak,
}) =>
    metric == BadgeMetric.workouts ? totalWorkouts : currentStreak;

/// Badge ids whose goal is now met but are not in [alreadyUnlocked], in
/// [kBadgeRules] order.
List<String> badgesToUnlock({
  required Iterable<String> alreadyUnlocked,
  required int totalWorkouts,
  required int currentStreak,
}) {
  final done = alreadyUnlocked.toSet();
  final result = <String>[];
  kBadgeRules.forEach((id, rule) {
    if (done.contains(id)) return;
    final value = badgeValue(rule.metric,
        totalWorkouts: totalWorkouts, currentStreak: currentStreak);
    if (value >= rule.target) result.add(id);
  });
  return result;
}
