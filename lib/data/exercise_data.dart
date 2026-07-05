
// Centralized Exercise Data
class Exercise {
  final String name;
  final String videoPath;
  final String description;
  final String target;
  final String equipment;
  final List<String> instructions;
  final String difficulty;
  final String setsReps;

  const Exercise({
    required this.name,
    required this.videoPath,
    required this.description,
    required this.target,
    required this.equipment,
    required this.instructions,
    required this.difficulty,
    required this.setsReps,
  });
}

class ExerciseData {
  static const List<Exercise> chest = [
    Exercise(
      name: 'Barbell Bench Press',
      videoPath: 'assets/videos/chest/chest_barbell_bench_press.mp4',
      description: 'The king of chest exercises. Compound movement for overall mass.',
      target: 'Chest, Shoulders, Triceps',
      equipment: 'Barbell, Bench',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 8-12 reps',
      instructions: [
        'Lie flat on bench, feet planted.',
        'Grip slightly wider than shoulders.',
        'Lower to chest with control.',
        'Press up explosively.'
      ],
    ),
    Exercise(
      name: 'Barbell Decline Bench Press',
      videoPath: 'assets/videos/chest/chest_barbell_decline_bench_press.mp4',
      description: 'Targets lower pectorals for defined chest development.',
      target: 'Lower Chest, Triceps',
      equipment: 'Barbell, Decline Bench',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 8-10 reps',
      instructions: ['Secure legs, lower bar to lower chest, press up.'],
    ),
    Exercise(
      name: 'Chest Dips',
      videoPath: 'assets/videos/chest/chest_dips.mp4',
      description: 'Bodyweight exercise for lower chest and triceps.',
      target: 'Lower Chest, Triceps',
      equipment: 'Dip Bars',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 8-12 reps',
      instructions: ['Lean forward to target chest, lower until stretch, press up.'],
    ),
    Exercise(
      name: 'Dumbbell Hammer Press',
      videoPath: 'assets/videos/chest/chest_dumbell_lying_hamme_press.mp4',
      description: 'Neutral grip press, easier on shoulders.',
      target: 'Chest, Triceps',
      equipment: 'Dumbbells, Bench',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: ['Neutral grip, press up, lower with control.'],
    ),
    Exercise(
      name: 'Cable Standing Fly',
      videoPath: 'assets/videos/chest/chest_cable_standing_fly.mp4',
      description: 'Constant tension for inner chest development.',
      target: 'Chest, Core',
      equipment: 'Cable Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: ['Stand between cables, pull handles together in arc.'],
    ),
    Exercise(
      name: 'Deep Pushups',
      videoPath: 'assets/videos/chest/Chest_deep_pushups.mp4',
      description: 'Bodyweight pushups with an extended range of motion for chest stretching.',
      target: 'Chest, Shoulders, Triceps',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      setsReps: '3 sets × 10-15 reps',
      instructions: [
        'Place hands slightly wider than shoulders.',
        'Lower body until chest is close to the floor.',
        'Push back up to starting position.'
      ],
    ),
    Exercise(
      name: 'Resistance Band High Fly',
      videoPath: 'assets/videos/chest/chest_band_high_fly.mp4',
      description: 'Targets upper chest and inner chest using a high anchor resistance band.',
      target: 'Upper Chest, Inner Chest',
      equipment: 'Resistance Band',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Anchor band high behind you.',
        'Pull hands forward and down in an arc.',
        'Squeeze the chest at the bottom.'
      ],
    ),
    Exercise(
      name: 'Dumbbell Decline Fly (45 Degree)',
      videoPath: 'assets/videos/chest/chest_dumbell_decline_fly_(45degree).mp4',
      description: 'Focuses on the lower pectorals with an arc fly movement.',
      target: 'Lower Chest',
      equipment: 'Dumbbells, Decline Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Lie on decline bench, dumbbells up.',
        'Lower weights in wide arc to chest level.',
        'Bring them back together squeezing chest.'
      ],
    ),
    Exercise(
      name: 'Dumbbell Fly',
      videoPath: 'assets/videos/chest/chest_dumbell_fly.mp4',
      description: 'Isolation exercise targeting chest fibers without triceps activation.',
      target: 'Chest',
      equipment: 'Dumbbells, Bench',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12 reps',
      instructions: [
        'Lie on bench, dumbbells over chest.',
        'Open arms in wide arc, keeping elbows slightly bent.',
        'Squeeze chest to return weights to top.'
      ],
    ),
    Exercise(
      name: 'Incline Dumbbell Fly',
      videoPath: 'assets/videos/chest/chest_incline_dumbell_fly.mp4',
      description: 'Isolation movement targeting the upper pectorals.',
      target: 'Upper Chest',
      equipment: 'Dumbbells, Incline Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Set bench to 30-45 degree incline.',
        'Lower dumbbells in wide arc to sides.',
        'Squeeze upper chest to return to start.'
      ],
    ),
    Exercise(
      name: 'Incline Dumbbell Press',
      videoPath: 'assets/videos/chest/chest_incline_dumbell_press.mp4',
      description: 'Compound movement to build mass in upper chest and shoulders.',
      target: 'Upper Chest, Front Delts, Triceps',
      equipment: 'Dumbbells, Incline Bench',
      difficulty: 'Beginner',
      setsReps: '4 sets × 8-12 reps',
      instructions: [
        'Sit on incline bench, dumbbells at shoulders.',
        'Press weights straight up until arms extend.',
        'Lower slowly to upper chest.'
      ],
    ),
    Exercise(
      name: 'Lever Chest Press',
      videoPath: 'assets/videos/chest/chest_lever_chest_press.mp4',
      description: 'Machine press for safe and guided chest muscle isolation.',
      target: 'Chest, Triceps',
      equipment: 'Chest Press Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Adjust seat so handles are at chest level.',
        'Press handles forward to full extension.',
        'Return under control to starting point.'
      ],
    ),
    Exercise(
      name: 'Lever Pec Dec Fly',
      videoPath: 'assets/videos/chest/chest_lever_peck_dec_fly.mp4',
      description: 'Machine fly for targeted inner chest isolation.',
      target: 'Chest, Inner Chest',
      equipment: 'Pec Dec Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Sit with back flat on pad, grip handles.',
        'Pull arms together in front of chest.',
        'Slowly return to start, feeling stretch.'
      ],
    ),
  ];

  static const List<Exercise> legs = [
    Exercise(
      name: 'Classic Barbell Squat',
      videoPath: 'assets/videos/legs/legs_classic_barbell_squat.mp4',
      description: 'Essential compound movement for total leg development.',
      target: 'Quads, Glutes, Hamstrings',
      equipment: 'Barbell, Rack',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 6-10 reps',
      instructions: ['Bar on upper back, feet shoulder width, squat deep.'],
    ),
    Exercise(
      name: 'Barbell Lunge',
      videoPath: 'assets/videos/legs/legs_barbell_lunge.mp4',
      description: 'Unilateral exercise for balance and strength.',
      target: 'Quads, Glutes',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10 reps/leg',
      instructions: ['Step forward, lower back knee, push back to start.'],
    ),
     Exercise(
      name: 'Dumbbell Goblet Squat',
      videoPath: 'assets/videos/legs/legs_dumbbell_goblet_squat.mp4',
      description: 'Beginner friendly squat focusing on form.',
      target: 'Quads, Glutes',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      setsReps: '4 sets × 12 reps',
      instructions: ['Hold dumbbell at chest, squat down keeping chest up.'],
    ),
    Exercise(
      name: 'Leg Press',
      videoPath: 'assets/videos/legs/legs_close_feet_leg_press.mp4',
      description: 'Machine based heavy compound movement.',
      target: 'Quads',
      equipment: 'Leg Press Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 12 reps',
      instructions: ['Feet on platform, lower weight, press back up.'],
    ),
    Exercise(
      name: 'Leg Extension',
      videoPath: 'assets/videos/legs/legs_lever_leg_extension.mp4',
      description: 'Isolation for quadriceps definition.',
      target: 'Quads',
      equipment: 'Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 15 reps',
      instructions: ['Extend legs fully, squeeze quads, lower slowly.'],
    ),
    Exercise(
      name: 'Lying Leg Curl',
      videoPath: 'assets/videos/legs/legs_lever_lying_leg_curl.mp4',
      description: 'Isolation for hamstring development.',
      target: 'Hamstrings',
      equipment: 'Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12 reps',
      instructions: ['Curl heels to glutes, squeeze, lower.'],
    ),
  ];
  
  // TODO: Add Back, Shoulders, Arms in a similar fashion.
  // For now, I will add placeholder data for other groups to ensure the generator works correctly.
  
  static const List<Exercise> back = [
     Exercise(
      name: 'Wide Grip Pull Up',
      videoPath: 'assets/videos/back/back_pull_ups_wide_backgrip.mp4',
      description: 'The ultimate upper body developer. Targets lats, biceps, and core.',
      target: 'Lats, Biceps',
      equipment: 'Pull Up Bar',
      difficulty: 'Advanced',
      setsReps: '3 sets × Failure',
      instructions: ['Pull chin over bar, lower fully.', 'Keep core tight.'],
    ),
    Exercise(
      name: 'Barbell Bent Over Row',
      videoPath: 'assets/videos/back/back_barbell_unerhand_bent_over_row.mp4',
      description: 'Compound movement for back thickness and strength.',
      target: 'Middle Back, Lats',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 8-10 reps',
      instructions: ['Bend over at hips, pull bar to waist.', 'Keep back straight.'],
    ),
     Exercise(
      name: 'Lat Pulldown',
      videoPath: 'assets/videos/back/back_cable_pulldown.mp4',
      description: 'Vertical pull for back width and taper.',
      target: 'Lats',
      equipment: 'Cable Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12 reps',
      instructions: ['Pull bar to upper chest, squeeze lats.', 'Control the negative.'],
    ),
    Exercise(
      name: 'Seated Cable Row',
      videoPath: 'assets/videos/back/back_cable_seated_row.mp4',
      description: 'Horizontal pull targeting back thickness.',
      target: 'Lats, Rhomboids',
      equipment: 'Cable Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets x 12 reps',
      instructions: ['Pull handle to waist, squeeze back.', 'Keep torso upright.'],
    ),
  ];

   static const List<Exercise> shoulders = [
    Exercise(
      name: 'Standing Military Press',
      videoPath: 'assets/videos/shoulder/shoulder_military_press.mp4',
      description: 'Compound shoulder mass builder for overall size.',
      target: 'Shoulders, Triceps',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 8 reps',
      instructions: ['Press bar overhead from rack position.', 'Lock out at top.'],
    ),
    Exercise(
      name: 'Seated Barbell Press',
      videoPath: 'assets/videos/shoulder/shoulder_barbell_seated_behindhead_military_press.mp4',
      description: 'Strict press variation removing leg drive.',
      target: 'Shoulders',
      equipment: 'Barbell, Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets x 10 reps',
      instructions: ['Press straight up from behind neck.', 'Keep core locked.'],
    ),
    Exercise(
      name: 'Dumbbell Lateral Raise',
      videoPath: 'assets/videos/shoulder/shoulder_dumbbell_seated_lateral.mp4',
      description: 'Isolation for side delts to create width.',
      target: 'Side Delts',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      setsReps: '3 sets × 15 reps',
      instructions: ['Raise arms to side until parallel.', 'Control the descent.'],
    ),
     Exercise(
      name: 'Arnold Press',
      videoPath: 'assets/videos/shoulder/shoulder_dumbbell_arnold_press.mp4',
      description: 'Rotational press hitting all three delt heads.',
      target: 'Shoulders',
      equipment: 'Dumbbells',
      difficulty: 'Intermediate',
      setsReps: '3 sets x 10-12 reps',
      instructions: ['Start palms facing you, rotate as you press.', 'Palms face out at top.'],
    ),
  ];

  static const List<Exercise> arms = [
     Exercise(
      name: 'Barbell Curl',
      videoPath: 'assets/videos/biceps/biceps_barbell_curl.mp4',
      description: 'The standard for bicep mass building.',
      target: 'Biceps',
      equipment: 'Barbell',
      difficulty: 'Beginner',
      setsReps: '3 sets × 10 reps',
      instructions: ['Curl bar up keeping elbows fixed.', 'Squeeze at top.'],
    ),
    Exercise(
      name: 'Dumbbell Curl',
      videoPath: 'assets/videos/biceps/biceps_dumbell_biceps_curl.mp4',
      description: 'Unilateral curl for balanced development.',
      target: 'Biceps',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      setsReps: '3 sets x 12 reps',
      instructions: ['Curl dumbbells alternately or together.', 'Avoid swinging.'],
    ),
    Exercise(
      name: 'Tricep Pushdown',
      videoPath: 'assets/videos/triceps/triceps_cable_pushdown.mp4',
      description: 'Isolation for lateral and medial tricep heads.',
      target: 'Triceps',
      equipment: 'Cable Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12 reps',
      instructions: ['Push bar down, extend arms fully.', 'Keep elbows tucked.'],
    ),
    Exercise(
      name: 'Skull Crushers',
      videoPath: 'assets/videos/triceps/triceps_cable_lying_extension.mp4',
      description: 'Extension movement for the long head of the triceps.',
      target: 'Triceps',
      equipment: 'Cable/Barbell',
      difficulty: 'Intermediate',
      setsReps: '3 sets x 10-12 reps',
      instructions: ['Lower weight to forehead.', 'Extend elbows back up.'],
    ),
  ];
  static List<Exercise> get biceps => arms.where((e) => e.target.contains('Biceps')).toList();
  static List<Exercise> get triceps => arms.where((e) => e.target.contains('Triceps')).toList();
  static const List<Exercise> abs = []; 
  static const List<Exercise> cardio = [];
}
