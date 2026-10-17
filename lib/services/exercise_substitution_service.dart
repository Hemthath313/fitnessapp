class ExerciseSubstitutionService {
  static const Map<String, List<String>> _substitutionMap = {
    'barbell bench press': [
      'Dumbbell Bench Press',
      'Machine Chest Press',
      'Smith Machine Bench Press',
      'Chest Dips',
    ],
    'barbell incline bench press': [
      'Incline Dumbbell Press',
      'Incline Machine Chest Press',
      'Smith Incline Press',
    ],
    'chest dips': [
      'Push-Ups',
      'Cable Chest Fly',
      'Pec Deck Fly',
      'Dumbbell Bench Press',
    ],
    'barbell squat': [
      'Leg Press',
      'Hack Squat',
      'Goblet Squat',
      'Bulgarian Split Squat',
    ],
    'barbell deadlift': [
      'Romanian Deadlift',
      'Trap Bar Deadlift',
      'Dumbbell Romanian Deadlift',
    ],
    'barbell lunge': [
      'Dumbbell Walking Lunge',
      'Bulgarian Split Squat',
      'Leg Press',
      'Goblet Squat',
    ],
    'seated cable row': [
      'Barbell Bent Over Row',
      'One-Arm Dumbbell Row',
      'Chest-Supported Row',
      'Lat Pulldown',
    ],
    'lat pulldown': [
      'Pull-Ups',
      'Neutral Grip Lat Pulldown',
      'Seated Cable Row',
      'Straight Arm Pulldown',
    ],
    'overhead press': [
      'Dumbbell Shoulder Press',
      'Seated Machine Shoulder Press',
      'Arnold Press',
      'Dumbbell Lateral Raise',
    ],
    'arnold press': [
      'Overhead Press',
      'Dumbbell Shoulder Press',
      'Seated Machine Shoulder Press',
    ],
    'dumbbell curl': [
      'Barbell Bicep Curl',
      'Hammer Curl',
      'Cable Bicep Curl',
      'Preacher Curl',
    ],
    'triceps pushdown': [
      'Skull Crushers',
      'Overhead Cable Tricep Extension',
      'Tricep Dips',
      'Close Grip Bench Press',
    ],
    'leg extension': [
      'Goblet Squat',
      'Bodyweight Squats',
      'Bulgarian Split Squat',
    ],
    'leg curl': [
      'Romanian Deadlift',
      'Dumbbell Romanian Deadlift',
      'Glute Bridge',
    ],
  };

  static List<String> getSubstitutions(String rawExerciseName) {
    final clean = rawExerciseName.replaceAll(RegExp(r'^\[\w+\]\s*'), '').trim().toLowerCase();
    
    // Check exact key match
    if (_substitutionMap.containsKey(clean)) {
      return _substitutionMap[clean]!;
    }

    // Check partial matches
    for (var entry in _substitutionMap.entries) {
      if (clean.contains(entry.key) || entry.key.contains(clean)) {
        return entry.value;
      }
    }

    // Generic fallback based on movement pattern
    if (clean.contains('press') || clean.contains('chest')) {
      return ['Dumbbell Bench Press', 'Machine Chest Press', 'Push-Ups'];
    }
    if (clean.contains('squat') || clean.contains('leg')) {
      return ['Leg Press', 'Goblet Squat', 'Bulgarian Split Squat'];
    }
    if (clean.contains('row') || clean.contains('back') || clean.contains('pull')) {
      return ['One-Arm Dumbbell Row', 'Lat Pulldown', 'Seated Cable Row'];
    }
    if (clean.contains('curl') || clean.contains('arm')) {
      return ['Hammer Curl', 'Cable Bicep Curl', 'Barbell Bicep Curl'];
    }

    return ['Dumbbell Bench Press', 'Goblet Squat', 'One-Arm Dumbbell Row'];
  }
}
