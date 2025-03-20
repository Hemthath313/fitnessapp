import 'package:fitness_app/model/workout_split.dart';
import 'package:fitness_app/utils/router/router.dart';

final List<WorkoutSplit> workoutSplits = [
  WorkoutSplit(
    name: 'Bro Split',
    description: 'Focuses on one muscle group per day. Best for bodybuilders.',
    recommendedDays: 5,
    route: Routes.broSplit,
  ),
  WorkoutSplit(
    name: 'Push-Pull-Legs (PPL)',
    description:
        'Push (chest, shoulders, triceps), Pull (back, biceps), Legs. Great for growth!',
    recommendedDays: 6,
    route: Routes.pushPullLegsSplit,
  ),
  WorkoutSplit(
    name: 'Upper-Lower Split',
    description:
        'Alternates between upper and lower body. Ideal for 4-day training.',
    recommendedDays: 4,
    route: Routes.upperLowerSplit,
  ),
  WorkoutSplit(
    name: 'Full Body Split',
    description:
        'Targets all major muscle groups in a single session. Great for beginners.',
    recommendedDays: 3,
    route: Routes.fullBodySplit,
  ),
];
