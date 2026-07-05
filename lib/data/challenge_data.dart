class ChallengeExercise {
  final String name;
  final String target;
  final String equipment;
  final String videoPath;
  final String setsReps;

  const ChallengeExercise({
    required this.name,
    required this.target,
    required this.equipment,
    required this.videoPath,
    required this.setsReps,
  });
}

class ChallengeData {
  static final Map<int, List<ChallengeExercise>> sixPackCurriculum = _generateCurriculum();

  static Map<int, List<ChallengeExercise>> _generateCurriculum() {
    final Map<int, List<ChallengeExercise>> curriculum = {};
    
    const day1Exercises = [
      ChallengeExercise(
        name: 'Crunch',
        target: 'Upper Abs',
        equipment: 'None',
        videoPath: 'assets/videos/abs/abs_twisting_crunch.mp4',
        setsReps: '3 sets x 20 reps',
      ),
      ChallengeExercise(
        name: 'Leg Raise',
        target: 'Lower Abs',
        equipment: 'None',
        videoPath: 'assets/videos/abs/abs_vertical_leg_raise.mp4',
        setsReps: '3 sets x 15 reps',
      ),
      ChallengeExercise(
        name: 'Plank',
        target: 'Core',
        equipment: 'None',
        videoPath: 'assets/videos/abs/abs_plank.mp4', 
        setsReps: '3 sets x 45 seconds',
      ),
    ];

    const day2Exercises = [
      ChallengeExercise(
        name: 'V-Up',
        target: 'Upper & Lower Abs',
        equipment: 'None',
        videoPath: 'assets/videos/abs/abs_v-up.mp4',
        setsReps: '3 sets x 12 reps',
      ),
      ChallengeExercise(
        name: 'Bicycle Crunch',
        target: 'Obliques',
        equipment: 'None',
        videoPath: 'assets/videos/abs/abs_air_twist_crunch.mp4',
        setsReps: '3 sets x 20 reps',
      ),
      ChallengeExercise(
        name: 'Hanging Leg Raise',
        target: 'Lower Abs',
        equipment: 'Pull-up Bar',
        videoPath: 'assets/videos/abs/abs_vertical_leg_raise.mp4',
        setsReps: '3 sets x 10 reps',
      ),
    ];

    const day3Exercises = [
      ChallengeExercise(
        name: 'Russian Twist',
        target: 'Obliques',
        equipment: 'None',
        videoPath: 'assets/videos/abs/abs_air_twist_crunch.mp4',
        setsReps: '3 sets x 20 reps',
      ),
      ChallengeExercise(
        name: 'Twisting Crunch',
        target: 'Upper Abs & Obliques',
        equipment: 'None',
        videoPath: 'assets/videos/abs/abs_twisting_crunch.mp4',
        setsReps: '3 sets x 15 reps',
      ),
      ChallengeExercise(
        name: 'Flutter Kicks',
        target: 'Lower Abs',
        equipment: 'None',
        videoPath: 'assets/videos/abs/abs_vertical_leg_raise.mp4',
        setsReps: '3 sets x 30 seconds',
      ),
    ];

    for (int day = 1; day <= 30; day++) {
      final setsMultiplier = day > 20 ? 4 : 3;
      final repModifier = day > 20 ? 1.5 : (day > 10 ? 1.25 : 1.0);

      final List<ChallengeExercise> baseExercises;
      if (day % 3 == 1) {
        baseExercises = day1Exercises;
      } else if (day % 3 == 2) {
        baseExercises = day2Exercises;
      } else {
        baseExercises = day3Exercises;
      }

      curriculum[day] = baseExercises.map((e) {
        String setsRepsText = e.setsReps;
        if (e.setsReps.contains('reps')) {
          final parts = e.setsReps.split(' x ');
          final baseReps = int.tryParse(parts[1].split(' ')[0]) ?? 15;
          final adjustedReps = (baseReps * repModifier).round();
          setsRepsText = '$setsMultiplier sets x $adjustedReps reps';
        } else if (e.setsReps.contains('seconds')) {
          final parts = e.setsReps.split(' x ');
          final baseSeconds = int.tryParse(parts[1].split(' ')[0]) ?? 30;
          final adjustedSeconds = (baseSeconds * repModifier).round();
          setsRepsText = '$setsMultiplier sets x $adjustedSeconds seconds';
        }
        return ChallengeExercise(
          name: e.name,
          target: e.target,
          equipment: e.equipment,
          videoPath: e.videoPath,
          setsReps: setsRepsText,
        );
      }).toList();
    }

    return curriculum;
  }

  /// A pool of featured exercises that rotate automatically every week.
  /// Uses ISO week number so every Monday a new exercise appears.
  static final List<ChallengeExercise> _weeklyPool = [
    const ChallengeExercise(
      name: 'Cable Kneeling Crunch',
      target: 'Upper Abs',
      equipment: 'Cable Machine',
      videoPath: 'assets/videos/abs/abs_cable_kneeling_crunch.mp4',
      setsReps: '4 sets x 12-15 reps',
    ),
    const ChallengeExercise(
      name: 'V-Up',
      target: 'Upper & Lower Abs',
      equipment: 'None',
      videoPath: 'assets/videos/abs/abs_v-up.mp4',
      setsReps: '4 sets x 12 reps',
    ),
    const ChallengeExercise(
      name: 'Russian Twist',
      target: 'Obliques',
      equipment: 'None',
      videoPath: 'assets/videos/abs/abs_air_twist_crunch.mp4',
      setsReps: '3 sets x 20 reps each side',
    ),
    const ChallengeExercise(
      name: 'Hanging Leg Raise',
      target: 'Lower Abs',
      equipment: 'Pull-up Bar',
      videoPath: 'assets/videos/abs/abs_vertical_leg_raise.mp4',
      setsReps: '4 sets x 10 reps',
    ),
    const ChallengeExercise(
      name: 'Plank',
      target: 'Core Stability',
      equipment: 'None',
      videoPath: 'assets/videos/abs/abs_plank.mp4',
      setsReps: '4 sets x 60 seconds',
    ),
    const ChallengeExercise(
      name: 'Bicycle Crunch',
      target: 'Obliques & Abs',
      equipment: 'None',
      videoPath: 'assets/videos/abs/abs_air_twist_crunch.mp4',
      setsReps: '3 sets x 20 reps',
    ),
    const ChallengeExercise(
      name: 'Twisting Crunch',
      target: 'Upper Abs & Obliques',
      equipment: 'None',
      videoPath: 'assets/videos/abs/abs_twisting_crunch.mp4',
      setsReps: '4 sets x 15 reps',
    ),
    const ChallengeExercise(
      name: 'Leg Raise',
      target: 'Lower Abs',
      equipment: 'None',
      videoPath: 'assets/videos/abs/abs_vertical_leg_raise.mp4',
      setsReps: '4 sets x 15 reps',
    ),
  ];

  /// Returns the exercise for the current ISO week number.
  /// Rotates through the pool automatically every Monday.
  static ChallengeExercise get weeklyFeaturedExercise {
    final now = DateTime.now();
    // ISO week number: Jan 4 is always in week 1
    final dayOfYear = int.parse(
        '${now.difference(DateTime(now.year, 1, 1)).inDays + 1}');
    final weekNumber = ((dayOfYear - now.weekday + 10) ~/ 7);
    final index = weekNumber % _weeklyPool.length;
    return _weeklyPool[index];
  }
}
