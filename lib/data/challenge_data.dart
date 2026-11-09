class ChallengeExercise {
  final String name;
  final String target;
  final String equipment;
  final String videoPath;
  final String setsReps;

  /// Form cues specific to this exercise (empty = show generic core cues).
  final List<String> tips;

  /// Common mistakes specific to this exercise.
  final List<String> mistakes;

  const ChallengeExercise({
    required this.name,
    required this.target,
    required this.equipment,
    required this.videoPath,
    required this.setsReps,
    this.tips = const [],
    this.mistakes = const [],
  });

  bool get hasVideo => videoPath.trim().isNotEmpty;
}

class ChallengeData {
  static final Map<int, List<ChallengeExercise>> sixPackCurriculum = _generateCurriculum();

  static List<ChallengeExercise> get weeklyPool => List.unmodifiable(_weeklyPool);

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
        videoPath: '',
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
      tips: [
        'Set the cable high and hold the rope beside your head; keep your hips still.',
        'Curl your ribcage toward your pelvis, not your elbows toward your knees.',
        'Breathe out hard at the bottom and pause for a second.',
      ],
      mistakes: [
        'Pulling with your arms instead of crunching your spine.',
        'Sitting back onto your heels as you crunch.',
        'Using so much weight that your hips move.',
      ],
    ),
    const ChallengeExercise(
      name: 'V-Up',
      target: 'Upper & Lower Abs',
      equipment: 'None',
      videoPath: 'assets/videos/abs/abs_v-up.mp4',
      setsReps: '4 sets x 12 reps',
      tips: [
        'Reach your arms and legs up to meet over your hips at the same time.',
        'Lower slowly and stop just above the floor to keep tension on your abs.',
        'Bend your knees slightly if your hamstrings are tight.',
      ],
      mistakes: [
        'Swinging your arms to build momentum.',
        'Letting your lower back arch off the floor on the way down.',
        'Rushing reps and dropping your legs.',
      ],
    ),
    const ChallengeExercise(
      name: 'Russian Twist',
      target: 'Obliques',
      equipment: 'None',
      videoPath: 'assets/videos/abs/abs_air_twist_crunch.mp4',
      setsReps: '3 sets x 20 reps each side',
      tips: [
        'Lean back slightly with a tall chest and a braced core.',
        'Rotate your ribcage, not just your arms.',
        'Keep your feet on the floor until you can stay steady, then lift them.',
      ],
      mistakes: [
        'Swinging your hands side to side without turning your torso.',
        'Rounding your back as you lean.',
        'Bouncing through the twist instead of controlling it.',
      ],
    ),
    const ChallengeExercise(
      name: 'Hanging Leg Raise',
      target: 'Lower Abs',
      equipment: 'Pull-up Bar',
      videoPath: 'assets/videos/abs/abs_vertical_leg_raise.mp4',
      setsReps: '4 sets x 10 reps',
      tips: [
        'Start from a dead hang with your shoulders pulled down, not shrugged.',
        'Tilt your pelvis up at the top so your abs, not your hip flexors, finish the rep.',
        'Lower under control and avoid swinging.',
      ],
      mistakes: [
        'Kipping or swinging to get your legs up.',
        'Letting your grip fail first; use straps if needed.',
        'Stopping at hip height without curling your pelvis.',
      ],
    ),
    const ChallengeExercise(
      name: 'Plank',
      target: 'Core Stability',
      equipment: 'None',
      videoPath: '',
      setsReps: '4 sets x 60 seconds',
      tips: [
        'Stack your elbows under your shoulders and make one line from head to heels.',
        'Squeeze your glutes and pull your ribs down toward your hips.',
        'Breathe steadily and end the set when your form breaks.',
      ],
      mistakes: [
        'Letting your hips sag or pike up.',
        'Holding your breath.',
        'Looking forward and straining your neck.',
      ],
    ),
    const ChallengeExercise(
      name: 'Bicycle Crunch',
      target: 'Obliques & Abs',
      equipment: 'None',
      videoPath: 'assets/videos/abs/abs_air_twist_crunch.mp4',
      setsReps: '3 sets x 20 reps',
      tips: [
        'Bring the opposite elbow toward your knee by rotating your ribcage.',
        'Fully extend the other leg without letting it touch the floor.',
        'Move slowly; a controlled rep beats a fast one.',
      ],
      mistakes: [
        'Pulling on your neck with your hands.',
        'Moving elbows and knees without actually twisting.',
        'Rushing so your legs never fully extend.',
      ],
    ),
    const ChallengeExercise(
      name: 'Twisting Crunch',
      target: 'Upper Abs & Obliques',
      equipment: 'None',
      videoPath: 'assets/videos/abs/abs_twisting_crunch.mp4',
      setsReps: '4 sets x 15 reps',
      tips: [
        'Lift your shoulder blades off the floor first, then rotate.',
        'Keep a fist of space between your chin and chest.',
        'Breathe out as you crunch and pause briefly at the top.',
      ],
      mistakes: [
        'Yanking your head forward with your hands.',
        'Using momentum to swing up.',
        'Lifting your lower back off the floor.',
      ],
    ),
    const ChallengeExercise(
      name: 'Leg Raise',
      target: 'Lower Abs',
      equipment: 'None',
      videoPath: 'assets/videos/abs/abs_vertical_leg_raise.mp4',
      setsReps: '4 sets x 15 reps',
      tips: [
        'Press your lower back into the floor before you lift.',
        'Keep your legs nearly straight and lower them for about 3 seconds.',
        'Stop lowering before your back starts to arch.',
      ],
      mistakes: [
        'Letting your lower back arch as your legs lower.',
        'Bending your knees to shorten the lever.',
        'Dropping your legs quickly on the way down.',
      ],
    ),
  ];

  /// A Monday in the past; weeks are counted from here so the rotation never
  /// jumps or repeats at a year boundary.
  static final DateTime _rotationEpoch = DateTime.utc(2024, 1, 1);

  /// Whole weeks (Monday to Sunday) between the epoch and [date].
  static int rotationWeek(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final monday = day.subtract(Duration(days: day.weekday - DateTime.monday));
    return monday.difference(_rotationEpoch).inDays ~/ 7;
  }

  /// The featured exercise for the week containing [date]. Changes every
  /// Monday and cycles through the whole pool.
  static ChallengeExercise weeklyFeaturedExerciseFor(DateTime date) {
    return _weeklyPool[rotationWeek(date) % _weeklyPool.length];
  }

  /// Days until the featured exercise changes (7 on a Monday, 1 on a Sunday).
  static int daysUntilNextFeatured(DateTime date) =>
      DateTime.sunday - date.weekday + 1;

  /// The exercise for the current week.
  static ChallengeExercise get weeklyFeaturedExercise =>
      weeklyFeaturedExerciseFor(DateTime.now());
}
