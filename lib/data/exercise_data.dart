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
        'Press up explosively.',
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
        'Push back up to starting position.',
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
        'Squeeze the chest at the bottom.',
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
        'Bring them back together squeezing chest.',
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
        'Squeeze chest to return weights to top.',
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
        'Squeeze upper chest to return to start.',
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
        'Lower slowly to upper chest.',
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
        'Return under control to starting point.',
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
        'Slowly return to start, feeling stretch.',
      ],
    ),
  ];

  static const List<Exercise> back = [
    Exercise(
      name: 'Barbell Underhand Bent Over Row',
      videoPath: 'assets/videos/back/back_barbell_unerhand_bent_over_row.mp4',
      description:
          'Classic back builder with underhand grip that targets the lats, rhomboids, and biceps. The underhand grip allows for a greater range of motion and biceps involvement.',
      target: 'Lats, Rhomboids, Biceps',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 8-12 reps',
      instructions: [
        'Stand with feet shoulder-width apart, holding barbell with underhand grip',
        'Hinge at hips, keeping back straight and core engaged',
        'Pull the barbell to your lower chest/upper abdomen',
        'Squeeze your back muscles at the top',
        'Lower the bar slowly with control',
        'Keep your elbows close to your body throughout',
      ],
    ),
    Exercise(
      name: 'Cable One Arm Lateral Pull Down',
      videoPath: 'assets/videos/back/back_cable_one_arm_lateral_pull_down.mp4',
      description:
          'Unilateral exercise that allows you to focus on each side independently. Helps identify and correct strength imbalances while building lat width.',
      target: 'Lats, Biceps',
      equipment: 'Cable Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps per arm',
      instructions: [
        'Stand or kneel facing the cable machine',
        'Grab the handle with one hand using an overhand grip',
        'Pull the handle down to your side, keeping elbow close',
        'Squeeze your lat at the bottom of the movement',
        'Return slowly to starting position',
        'Repeat with the other arm',
      ],
    ),
    Exercise(
      name: 'Cable Pulldown',
      videoPath: 'assets/videos/back/back_cable_pulldown.mp4',
      description:
          'The most popular lat exercise. Targets the latissimus dorsi effectively, building width and creating that V-taper physique. Perfect for beginners and advanced lifters.',
      target: 'Lats, Biceps, Rhomboids',
      equipment: 'Cable Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-15 reps',
      instructions: [
        'Sit at the cable machine with thighs secured under pads',
        'Grab the bar with wide overhand grip',
        'Pull the bar down to your upper chest',
        'Squeeze your lats at the bottom',
        'Control the weight back up slowly',
        'Keep your torso upright and core engaged',
      ],
    ),
    Exercise(
      name: 'Cable Seated High Row (V-Bar)',
      videoPath: 'assets/videos/back/back_cable_seated_high_row(v_bar).mp4',
      description:
          'Seated rowing exercise with V-bar attachment that targets the middle traps and rhomboids. The V-bar grip provides a unique angle for back development.',
      target: 'Middle Traps, Rhomboids, Rear Delts',
      equipment: 'Cable Machine, V-Bar',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Sit at the cable machine with feet on platform',
        'Grab the V-bar with both hands',
        'Pull the bar to your upper chest/neck area',
        'Squeeze your back muscles at the peak',
        'Return slowly to starting position',
        'Keep your core engaged and back straight',
      ],
    ),
    Exercise(
      name: 'Cable Seated Row (Normal Grip)',
      videoPath: 'assets/videos/back/back_cable_seated_row(normal_grip).mp4',
      description:
          'Classic rowing exercise that builds thickness in the middle back. The normal grip targets the rhomboids and middle traps effectively.',
      target: 'Rhomboids, Middle Traps, Lats',
      equipment: 'Cable Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Sit at the cable machine with feet on platform',
        'Grab the handle with overhand grip',
        'Pull the handle to your lower chest/upper abdomen',
        'Squeeze your back muscles at the peak',
        'Return slowly, feeling the stretch',
        'Keep your back straight and core engaged',
      ],
    ),
    Exercise(
      name: 'Cable Seated Row (Parallel Grip)',
      videoPath: 'assets/videos/back/back_cable_seated_row(paralled_grip).mp4',
      description:
          'Rowing variation with parallel grip that reduces stress on the wrists and shoulders. Targets the lats and rhomboids with a comfortable grip position.',
      target: 'Lats, Rhomboids, Biceps',
      equipment: 'Cable Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Sit at the cable machine with feet on platform',
        'Grab the parallel grip handle',
        'Pull the handle to your lower chest',
        'Squeeze your back muscles at the peak',
        'Return slowly with control',
        'Maintain proper posture throughout',
      ],
    ),
    Exercise(
      name: 'Cable Seated Row',
      videoPath: 'assets/videos/back/back_cable_seated_row.mp4',
      description:
          'Fundamental rowing exercise that builds back thickness and strength. The seated position provides stability and allows for heavy loading.',
      target: 'Lats, Rhomboids, Middle Traps',
      equipment: 'Cable Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Sit at the cable machine with feet secured',
        'Grab the handle with both hands',
        'Pull the handle to your torso',
        'Squeeze your back muscles hard at the peak',
        'Return slowly, feeling the stretch',
        'Keep your back straight and core tight',
      ],
    ),
    Exercise(
      name: 'Dumbbell Incline Row',
      videoPath: 'assets/videos/back/back_dumbell_incline_row.mp4',
      description:
          'Performed on an incline bench, this variation provides excellent back isolation. The angle allows for a great stretch and contraction of the lats.',
      target: 'Lats, Rhomboids, Rear Delts',
      equipment: 'Dumbbells, Incline Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Set bench to 30-45 degree incline',
        'Lie face down on the bench holding dumbbells',
        'Pull the dumbbells up to your sides',
        'Squeeze your back muscles at the top',
        'Lower slowly with control',
        'Keep your core engaged throughout',
      ],
    ),
    Exercise(
      name: 'Lever T-Bar Row',
      videoPath: 'assets/videos/back/back_lever_tbar_row.mp4',
      description:
          'Machine-based rowing exercise that provides stability and safety. The T-bar position allows for heavy loading while maintaining proper form.',
      target: 'Lats, Rhomboids, Middle Traps',
      equipment: 'T-Bar Row Machine',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 8-12 reps',
      instructions: [
        'Straddle the T-bar with feet on platform',
        'Grab the handles with both hands',
        'Pull the weight to your chest',
        'Squeeze your back muscles at the peak',
        'Lower slowly with control',
        'Keep your back straight and core engaged',
      ],
    ),
    Exercise(
      name: 'Pull-ups Wide Back Grip',
      videoPath: 'assets/videos/back/back_pull_ups_wide_backgrip.mp4',
      description:
          'The ultimate bodyweight back exercise. Wide grip emphasizes lat width and creates that V-taper. Challenging but highly effective for building upper body strength.',
      target: 'Lats, Biceps, Rear Delts',
      equipment: 'Pull-up Bar',
      difficulty: 'Advanced',
      setsReps: '3-5 sets × 5-15 reps',
      instructions: [
        'Hang from pull-up bar with wide overhand grip',
        'Pull your body up until chin clears the bar',
        'Squeeze your lats at the top',
        'Lower slowly with control',
        'Keep your core engaged and avoid swinging',
        'Full range of motion is key',
      ],
    ),
    Exercise(
      name: 'Smith Deadlift',
      videoPath: 'assets/videos/back/back_smith_deadlift.mp4',
      description:
          'Machine-based deadlift that provides safety and stability. Great for beginners learning the movement pattern or when you want to focus on form.',
      target: 'Back, Glutes, Hamstrings',
      equipment: 'Smith Machine',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 6-10 reps',
      instructions: [
        'Stand with feet hip-width apart in Smith machine',
        'Grab the bar with overhand or mixed grip',
        'Keep your back straight and core engaged',
        'Lift the bar by extending hips and knees',
        'Stand tall at the top, squeezing glutes',
        'Lower with control, maintaining form',
      ],
    ),
    Exercise(
      name: 'Barbell Straight Leg Deadlift',
      videoPath: 'assets/videos/back/barbell_straight_leg_deadlift.mp4',
      description:
          'Hamstring and glute focused deadlift variation. The straight leg position emphasizes the posterior chain while also targeting the lower back.',
      target: 'Hamstrings, Glutes, Lower Back',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 8-12 reps',
      instructions: [
        'Stand holding barbell with overhand grip',
        'Keep legs straight (slight bend is okay)',
        'Hinge at hips, lowering bar along your legs',
        'Feel the stretch in your hamstrings',
        'Return to standing by extending hips',
        'Keep your back straight throughout',
      ],
    ),
    Exercise(
      name: 'Cable One Arm Twisting Seated Row',
      videoPath: 'assets/videos/back/back_cable_one_arm_twisting_seated_row.mp4',
      description:
          'A unilateral seated row variation using cables. Adding a twist to the wrist rotation engages the lats from multiple angles and increases muscle contraction.',
      target: 'Lats, Rhomboids, Obliques',
      equipment: 'Cable Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps per arm',
      instructions: [
        'Sit upright facing the cable, grab handle with one hand and arm fully extended.',
        'Pull the cable handle to your hip while twisting your wrist to an underhand grip.',
        'Squeeze the lat and slowly return with rotation.',
      ],
    ),
    Exercise(
      name: 'Cable Straight Back Seated High Row (Reverse Grip)',
      videoPath: 'assets/videos/back/back_cable_straight_back_seated_high_row_reverse_grip.mp4',
      description:
          'High cable row performed sitting upright with a reverse (underhand) grip. Excellent for focusing on the lower lats and biceps.',
      target: 'Lower Lats, Rhomboids, Biceps',
      equipment: 'Cable Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Sit tall in front of the high cable with an underhand grip.',
        'Pull the handle down and back towards your upper chest.',
        'Squeeze the lats and lower traps, then return slowly.',
      ],
    ),
    Exercise(
      name: 'Cable Straight Arm Pulldown',
      videoPath: 'assets/videos/back/back_cable_striaight_arm_pulldown.mp4',
      description:
          'Isolation exercise targeting the lats by sweeping the arms down with elbows locked, removing biceps involvement.',
      target: 'Lats, Triceps (Long Head)',
      equipment: 'Cable Machine, Straight Bar',
      difficulty: 'Beginner',
      setsReps: '4 sets × 12-15 reps',
      instructions: [
        'Stand facing cable, grip bar overhand with arms straight overhead.',
        'Keep elbows slightly bent but fixed, pull bar down to thighs.',
        'Return slowly, feeling the stretch in the lats.',
      ],
    ),
    Exercise(
      name: 'Cambered Bar Lying Row',
      videoPath: 'assets/videos/back/back_cambered_bar_lying_row.mp4',
      description:
          'Lying face down on an elevated bench and rowing a cambered barbell. The curved bar allows for a greater range of motion and deeper contraction.',
      target: 'Upper Back, Rhomboids, Lats',
      equipment: 'Cambered Barbell, Elevated Bench',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 8-12 reps',
      instructions: [
        'Lie face down on elevated bench holding cambered bar below.',
        'Pull bar up towards bench, allowing cambered section to pass bench height.',
        'Squeeze shoulder blades together, lower under control.',
      ],
    ),
    Exercise(
      name: 'Commando Pull-up',
      videoPath: 'assets/videos/back/back_commando_pullup.mp4',
      description:
          'A pull-up variation performed standing sideways to the bar with a close staggered grip. Heavily recruits lats, obliques, and brachialis.',
      target: 'Lats, Arms, Core',
      equipment: 'Pull-up Bar',
      difficulty: 'Advanced',
      setsReps: '3 sets × max reps',
      instructions: [
        'Stand sideways to pull-up bar, grab bar with staggered hands.',
        'Pull body up, shifting head to one side of the bar.',
        'Lower slowly and repeat, alternating sides.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Bent Over Row',
      videoPath: 'assets/videos/back/back_dumbell_bent_row.mp4',
      description:
          'Classic compound dumbbell row targeting the entire back, allowing for independent movement of each arm.',
      target: 'Lats, Rhomboids, Upper Back',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Bend at hips with flat back holding dumbbells.',
        'Pull dumbbells to your sides, keeping elbows tucked close.',
        'Lower under control to full extension.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Reverse Grip Row',
      videoPath: 'assets/videos/back/back_dumbell_reverse_grip_row.mp4',
      description:
          'A bent-over dumbbell row holding weights with palms facing forward to recruit more lower lat fibers and biceps.',
      target: 'Lower Lats, Biceps',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Hinge at hips, hold dumbbells with underhand grip.',
        'Pull weights towards lower waist, keeping elbows tight to torso.',
        'Lower slowly.',
      ],
    ),
    Exercise(
      name: 'Lever High Row',
      videoPath: 'assets/videos/back/back_lever_high_row.mp4',
      description:
          'Machine-based high row pulling at a downward angle to isolate the lats and lower trapezius with guided safety.',
      target: 'Lats, Lower Traps',
      equipment: 'High Row Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Adjust seat, grab handles overhead.',
        'Pull handles down and back towards chest, chest pressed to pad.',
        'Squeeze back and return slowly.',
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
    Exercise(
      name: 'Resistance Band Bent Over Hip Extension',
      videoPath: 'assets/videos/legs/legs_band_bent_over_hip_extension.mp4',
      description:
          'Target the glutes and hamstrings using a resistance band from a bent-over position. Excellent for isolation and glute activation.',
      target: 'Glutes, Hamstrings',
      equipment: 'Resistance Band',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps per leg',
      instructions: [
        'Secure band around ankles or foot, bend forward.',
        'Extend one leg backward against band resistance.',
        'Squeeze glute at top and return with control.',
      ],
    ),
    Exercise(
      name: 'Barbell Front Chest Squat',
      videoPath: 'assets/videos/legs/legs_barbell_front_chest_squat.mp4',
      description:
          'The front squat places the barbell across the front of the shoulders, shifting the emphasis onto the quadriceps and core strength.',
      target: 'Quads, Core, Upper Back',
      equipment: 'Barbell, Rack',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 8-10 reps',
      instructions: [
        'Rack bar on front of shoulders, cross arms.',
        'Keep torso upright, squat down until thighs are parallel to floor.',
        'Drive back up through heels.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Sumo Squat',
      videoPath: 'assets/videos/legs/legs_dumbbell_bar_grip_sumo_squat.mp4',
      description:
          'Wide stance squat variation targeting the inner thighs (adductors) and glutes using a dumbbell.',
      target: 'Inner Thighs, Glutes, Quads',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Stand with feet wider than shoulders, toes pointed out.',
        'Hold dumbbell vertically at chest or hanging down.',
        'Squat deep, keeping knees aligned with toes.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Lunge',
      videoPath: 'assets/videos/legs/legs_dumbbell_lunge.mp4',
      description:
          'A unilateral movement to build lower body strength and stability. Dumbbells allow easy balance control.',
      target: 'Quads, Glutes, Hamstrings',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      setsReps: '3 sets × 10 reps per leg',
      instructions: [
        'Hold dumbbells at sides, stand upright.',
        'Step forward with one leg, lower hips until back knee is near floor.',
        'Push back to starting position.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Lying Femoral Curl',
      videoPath: 'assets/videos/legs/legs_dumbell_lying_femoral.mp4',
      description:
          'Lie flat on a bench and curl a dumbbell held between your feet. Excellent for hamstring isolation without machines.',
      target: 'Hamstrings',
      equipment: 'Dumbbell, Flat Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Lie face down on bench, secure dumbbell between arches of feet.',
        'Curl dumbbell up towards glutes by bending knees.',
        'Lower slowly to full extension.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Single Leg Squat',
      videoPath: 'assets/videos/legs/legs_dumbell_single_leg_squat.mp4',
      description:
          'A challenging single-leg squat (Bulgarian split squat) targeting the quads and glutes while improving balance.',
      target: 'Quads, Glutes',
      equipment: 'Dumbbells, Bench',
      difficulty: 'Advanced',
      setsReps: '3 sets × 8-10 reps per leg',
      instructions: [
        'Place one foot behind you on a bench, hold dumbbells.',
        'Lower hips until front thigh is parallel to floor.',
        'Drive back up through front heel.',
      ],
    ),
    Exercise(
      name: 'Lever Kneeling Leg Curl',
      videoPath: 'assets/videos/legs/legs_lever_kneeling_leg_curl.mp4',
      description:
          'A kneeling machine variation to isolate each hamstring independently for balanced development.',
      target: 'Hamstrings',
      equipment: 'Leg Curl Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12 reps per leg',
      instructions: [
        'Kneel on machine pad, place back of ankle under roller.',
        'Curl leg upwards towards glutes.',
        'Lower under control to start.',
      ],
    ),
    Exercise(
      name: 'Lever Seated Hip Abduction',
      videoPath: 'assets/videos/legs/legs_lever_seated_hip_abduction.mp4',
      description:
          'Targets the outer glutes (gluteus medius/minimus) using a seated machine, essential for hip stability.',
      target: 'Outer Glutes, Hips',
      equipment: 'Hip Abduction Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 15 reps',
      instructions: [
        'Sit in machine with pads on outer knees.',
        'Press legs outward against pad resistance.',
        'Slowly return to start.',
      ],
    ),
    Exercise(
      name: 'Lever Seated Leg Curl',
      videoPath: 'assets/videos/legs/legs_lever_seated_leg_curl.mp4',
      description:
          'Seated machine exercise to isolate the hamstrings from a seated position, offering high safety and control.',
      target: 'Hamstrings',
      equipment: 'Seated Leg Curl Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Sit with back flat on pad, secure thighs.',
        'Curl legs down and back as far as possible.',
        'Return slowly under control.',
      ],
    ),
    Exercise(
      name: 'Sled 45 Degree Wide Leg Press',
      videoPath: 'assets/videos/legs/legs_sled_45_degree_leg_wide_press.mp4',
      description:
          'A wide stance leg press targeting the glutes, hamstrings, and adductors on a 45-degree sled.',
      target: 'Glutes, Inner Thighs, Quads',
      equipment: 'Leg Press Sled',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Place feet high and wide on platform.',
        'Lower sled towards chest, keeping knees out.',
        'Press platform up without locking knees.',
      ],
    ),
    Exercise(
      name: 'Sled Hack Squat',
      videoPath: 'assets/videos/legs/legs_sled_hack_squat.mp4',
      description:
          'Machine-guided hack squat targeting the quadriceps while supporting the back.',
      target: 'Quads, Glutes',
      equipment: 'Hack Squat Machine',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 8-12 reps',
      instructions: [
        'Place shoulders under pads, feet flat on platform.',
        'Lower body until knees are at 90 degrees.',
        'Drive up through platform.',
      ],
    ),
    Exercise(
      name: 'Smith Machine Chair Squat',
      videoPath: 'assets/videos/legs/legs_smith_chair_squat.mp4',
      description:
          'Positioning feet forward on the Smith machine to sit back like a chair. Shifts maximum load to the quadriceps.',
      target: 'Quads, Glutes',
      equipment: 'Smith Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Place feet forward under bar, bar on shoulders.',
        'Lower hips as if sitting back into a chair.',
        'Drive straight up.',
      ],
    ),
    Exercise(
      name: 'Donkey Calf Raise',
      videoPath: 'assets/videos/legs/legs_donkey_calf_raise.mp4',
      description:
          'Calf exercise where you hinge forward at the hips, keeping the lower body loaded to target the gastrocnemius with maximum stretch.',
      target: 'Calves (Gastrocnemius)',
      equipment: 'Machine or Bench',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 15-20 reps',
      instructions: [
        'Bend forward at hips, place feet on elevated block.',
        'Lower heels as far as possible to stretch calves.',
        'Raise up onto toes, squeezing calves at top.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Seated Calf Raise',
      videoPath: 'assets/videos/legs/legs_dumbell_seated_calf_raise.mp4',
      description:
          'Seated calf raise variation using dumbbells placed on the knees to isolate the soleus muscle.',
      target: 'Calves (Soleus)',
      equipment: 'Dumbbells, Bench, Block',
      difficulty: 'Beginner',
      setsReps: '4 sets × 12-15 reps',
      instructions: [
        'Sit on bench, place balls of feet on block, hold dumbbells on thighs.',
        'Lower heels to full stretch.',
        'Push up through toes, contracting calves.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Standing Calf Raise',
      videoPath: 'assets/videos/legs/legs_dumbell_standing_calf_raise.mp4',
      description:
          'Standing calf raise holding dumbbells at your sides, targeting the gastrocnemius for overall calf size.',
      target: 'Calves (Gastrocnemius)',
      equipment: 'Dumbbells, Block',
      difficulty: 'Beginner',
      setsReps: '4 sets × 15 reps',
      instructions: [
        'Stand with feet on elevated block holding dumbbells.',
        'Extend heels down for full stretch, keeping knees straight.',
        'Push up high onto toes, squeeze calves.',
      ],
    ),
    Exercise(
      name: 'Lever Seated Calf Raise',
      videoPath: 'assets/videos/legs/legs_lever_seated_calf_raise.mp4',
      description:
          'Seated machine calf raise targeting the soleus muscle, which is heavily engaged when the knees are bent.',
      target: 'Calves (Soleus)',
      equipment: 'Seated Calf Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 15-20 reps',
      instructions: [
        'Sit in machine, place thighs under pads and balls of feet on block.',
        'Release safety bar, lower heels.',
        'Press up through toes, contracting calves.',
      ],
    ),
    Exercise(
      name: 'Lever Standing Calf Raise',
      videoPath: 'assets/videos/legs/legs_lever_standing_calf_raise.mp4',
      description:
          'Standing machine calf raise to build the upper calf muscles (gastrocnemius) with guided stability.',
      target: 'Calves (Gastrocnemius)',
      equipment: 'Standing Calf Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 15-20 reps',
      instructions: [
        'Place shoulders under pads, balls of feet on platform.',
        'Lower heels slowly to feel the stretch.',
        'Explode up onto toes, squeezing at peak.',
      ],
    ),
    Exercise(
      name: 'Smith Machine Standing Calf Raise',
      videoPath: 'assets/videos/legs/legs_smith_calf_raise.mp4',
      description:
          'Standing calf raise performed in a Smith machine, allowing for safe heavy loading of the calf muscles.',
      target: 'Calves',
      equipment: 'Smith Machine, Block',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 12-15 reps',
      instructions: [
        'Place block under Smith machine bar, stand on block with bar on shoulders.',
        'Lower heels below block height.',
        'Push up high onto toes, contract calves.',
      ],
    ),
  ];

  static const List<Exercise> shoulders = [
    Exercise(
      name: 'Military Press',
      videoPath: 'assets/videos/shoulder/shoulder_military_press.mp4',
      description:
          'Classic overhead pressing movement that builds shoulder strength and size. Standing position engages your core and stabilizers, making it a functional exercise.',
      target: 'Shoulders, Triceps, Core',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 6-10 reps',
      instructions: [
        'Stand with feet shoulder-width apart, holding barbell at shoulder level',
        'Press the barbell overhead until arms are fully extended',
        'Keep your core tight and avoid arching your back excessively',
        'Lower the bar slowly back to shoulder level',
        'Keep your elbows slightly forward, not flared out',
        'Breathe out on the way up, breathe in on the way down',
      ],
    ),
    Exercise(
      name: 'Barbell Seated Behind Head Military Press',
      videoPath: 'assets/videos/shoulder/shoulder_barbell_seated_behindhead_military_press.mp4',
      description:
          'Seated variation that provides back support and stability. The behind-the-head position targets the rear delts and provides a different angle of resistance.',
      target: 'Shoulders (Rear Delts), Triceps',
      equipment: 'Barbell, Bench',
      difficulty: 'Advanced',
      setsReps: '3 sets × 8-12 reps',
      instructions: [
        'Sit on a bench with back support',
        'Hold the barbell behind your head at neck level',
        'Press the bar overhead until arms are fully extended',
        'Lower slowly back to starting position',
        'Keep your core engaged and maintain proper form',
        'Use a spotter if lifting heavy weights',
      ],
    ),
    Exercise(
      name: 'Dumbbell Bench Seated Press',
      videoPath: 'assets/videos/shoulder/shoulder_dumbbell_bench_seated_press.mp4',
      description:
          'Seated dumbbell press that provides stability and allows for independent arm movement. Each arm works independently, helping correct muscle imbalances.',
      target: 'Shoulders, Triceps',
      equipment: 'Dumbbells, Bench',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Sit on a bench with back support',
        'Hold dumbbells at shoulder level with palms facing forward',
        'Press the dumbbells up until arms are fully extended',
        'Lower them slowly back to shoulder level',
        'Keep your core engaged and maintain control',
        'Focus on squeezing your shoulders at the top',
      ],
    ),
    Exercise(
      name: 'Dumbbell Arnold Press',
      videoPath: 'assets/videos/shoulder/shoulder_dumbbell_arnold_press.mp4',
      description:
          'Named after Arnold Schwarzenegger, this exercise combines shoulder press with rotation. Targets all three deltoid heads through a unique range of motion.',
      target: 'Shoulders (All Heads), Triceps',
      equipment: 'Dumbbells',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Sit or stand holding dumbbells at shoulder level with palms facing you',
        'Press the dumbbells up while rotating your wrists',
        'At the top, palms should face forward',
        'Reverse the motion on the way down',
        'Keep your core engaged throughout',
        'Control the rotation and press smoothly',
      ],
    ),
    Exercise(
      name: 'Lever Military Press',
      videoPath: 'assets/videos/shoulder/shoulder_lever_military_press.mp4',
      description:
          'Machine-based overhead press that provides safety and stability. Perfect for beginners or when you want to isolate shoulders without worrying about balance.',
      target: 'Shoulders, Triceps',
      equipment: 'Shoulder Press Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Sit in the machine with back against the pad',
        'Adjust the seat so handles are at shoulder level',
        'Press the handles up until arms are fully extended',
        'Lower slowly back to starting position',
        'Keep your core engaged and maintain proper posture',
        'Focus on the shoulder contraction throughout',
      ],
    ),
    Exercise(
      name: 'Dumbbell Seated Lateral Raise',
      videoPath: 'assets/videos/shoulder/shoulder_dumbbell_seated_lateral.mp4',
      description:
          'Isolation exercise that targets the medial (side) deltoids. Seated position eliminates momentum and ensures strict form for maximum muscle activation.',
      target: 'Shoulders (Medial Delts)',
      equipment: 'Dumbbells, Bench',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Sit on a bench holding dumbbells at your sides',
        'Raise the dumbbells out to your sides until parallel to floor',
        'Keep a slight bend in your elbows',
        'Squeeze your shoulders at the top',
        'Lower slowly with control',
        'Focus on the lateral deltoid contraction',
      ],
    ),
    Exercise(
      name: 'One Arm Lateral Raise',
      videoPath: 'assets/videos/shoulder/shoulder_one_arm_lateral_raise.mp4',
      description:
          'Unilateral exercise that allows you to focus on each shoulder independently. Helps identify and correct strength imbalances while building shoulder width.',
      target: 'Shoulders (Medial Delts)',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps per arm',
      instructions: [
        'Stand holding a dumbbell in one hand at your side',
        'Raise the dumbbell out to your side until parallel to floor',
        'Keep a slight bend in your elbow',
        'Squeeze your shoulder at the top',
        'Lower slowly and repeat with other arm',
        'Keep your core engaged and avoid swinging',
      ],
    ),
    Exercise(
      name: 'Dumbbell Seated Front Raise',
      videoPath: 'assets/videos/shoulder/shoulder_dumbbell_seated_front_raise.mp4',
      description:
          'Targets the anterior (front) deltoids. Seated position provides stability and eliminates momentum, ensuring maximum isolation of the front delts.',
      target: 'Shoulders (Anterior Delts)',
      equipment: 'Dumbbells, Bench',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Sit on a bench holding dumbbells in front of your thighs',
        'Raise the dumbbells forward until parallel to floor',
        'Keep your arms straight with slight bend in elbows',
        'Squeeze your front delts at the top',
        'Lower slowly with control',
        'Focus on the anterior deltoid contraction',
      ],
    ),
    Exercise(
      name: 'Dumbbell Rear Lateral Raise',
      videoPath: 'assets/videos/shoulder/shoulder_dumbbell_rear_lateral_raise.mp4',
      description:
          'Targets the posterior (rear) deltoids. Essential for balanced shoulder development and improving posture. The rear delts are often underdeveloped.',
      target: 'Shoulders (Posterior Delts)',
      equipment: 'Dumbbells',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Stand or sit leaning forward slightly',
        'Hold dumbbells with arms hanging down',
        'Raise the dumbbells out to your sides',
        'Squeeze your rear delts at the top',
        'Lower slowly with control',
        'Keep your back straight and core engaged',
      ],
    ),
    Exercise(
      name: 'Dumbbell Incline Rear Lateral Raise',
      videoPath: 'assets/videos/shoulder/shoulder_dumbbell_incline_rear_lateral_raise.mp4',
      description:
          'Performed on an incline bench, this variation provides excellent isolation of the rear delts. The angle allows for a great stretch and contraction.',
      target: 'Shoulders (Posterior Delts)',
      equipment: 'Dumbbells, Incline Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Set bench to 30-45 degree incline',
        'Lie face down on the bench holding dumbbells',
        'Raise the dumbbells out to your sides',
        'Squeeze your rear delts at the top',
        'Lower slowly, feeling the stretch',
        'Keep your core engaged throughout',
      ],
    ),
    Exercise(
      name: 'Band One Arm Forward Raise',
      videoPath: 'assets/videos/shoulder/shoulder_band_one_arm_forward_raise.mp4',
      description:
          'Resistance band exercise that targets the anterior deltoids. Portable and versatile, perfect for home workouts or when you want variety in your training.',
      target: 'Shoulders (Anterior Delts)',
      equipment: 'Resistance Band',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps per arm',
      instructions: [
        'Stand on the resistance band with one foot',
        'Hold the band handle in one hand',
        'Raise your arm forward until parallel to floor',
        'Squeeze your front delt at the top',
        'Lower slowly and repeat with other arm',
        'Keep constant tension on the band',
      ],
    ),
    Exercise(
      name: 'Cable Crossover Reverse',
      videoPath: 'assets/videos/shoulder/shoulder_cable_crossover_reverse.mp4',
      description:
          'Cable exercise that targets the rear deltoids with constant tension. The crossover motion provides a unique angle for rear delt development.',
      target: 'Shoulders (Posterior Delts)',
      equipment: 'Cable Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Stand between two cable machines with handles at chest height',
        'Cross your arms and grab opposite handles',
        'Pull the cables apart, squeezing your rear delts',
        'Keep your arms slightly bent',
        'Return slowly to starting position',
        'Maintain constant tension throughout',
      ],
    ),
    Exercise(
      name: 'Cable Rear Delt Row',
      videoPath: 'assets/videos/shoulder/shoulder_cable_rear_delt_row.mp4',
      description:
          'Cable rowing exercise that specifically targets the rear deltoids. The cable provides constant tension, maximizing rear delt activation.',
      target: 'Shoulders (Posterior Delts), Rhomboids',
      equipment: 'Cable Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Stand facing the cable machine with handle at chest height',
        'Grab the handle with both hands',
        'Pull the handle to your chest, focusing on rear delts',
        'Squeeze your rear delts at the peak',
        'Return slowly with control',
        'Keep your core engaged and maintain good posture',
      ],
    ),
    Exercise(
      name: 'EZ Barbell Antigravity Press',
      videoPath: 'assets/videos/shoulder/shoulder_Ez_barbell_antigravity_press.mp4',
      description:
          'Lie face down on a bench and press an EZ barbell overhead. Highly effective for isolating the shoulders and upper back without spinal load.',
      target: 'Shoulders, Upper Back',
      equipment: 'EZ Barbell, Bench',
      difficulty: 'Advanced',
      setsReps: '3 sets × 8-12 reps',
      instructions: [
        'Lie face down on a flat or incline bench.',
        'Hold the EZ barbell overhand, elbows bent at 90 degrees.',
        'Press the bar straight forward/overhead in line with your torso.',
      ],
    ),
    Exercise(
      name: 'Resistance Band Standing Rear Delt Row',
      videoPath: 'assets/videos/shoulder/shoulder_band_standing _rear_delt row.mp4',
      description:
          'Target your rear deltoids and upper back standing using a resistance band. Perfect for posture correction and rotator cuff health.',
      target: 'Shoulders (Rear Delts), Upper Back',
      equipment: 'Resistance Band',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Anchor band at chest height, stand holding band with arms extended.',
        'Pull elbows back and out wide, squeezing rear delts.',
        'Return slowly to starting stretch.',
      ],
    ),
    Exercise(
      name: 'Barbell Wide Grip Upright Row',
      videoPath: 'assets/videos/shoulder/shoulder_barbell_upright_row(wide-grip).mp4',
      description:
          'Upright rowing movement performed with a wide barbell grip to focus the load onto the lateral deltoids rather than the traps.',
      target: 'Shoulders (Lateral Delts), Traps',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Stand holding barbell with a wide overhand grip.',
        'Pull the bar straight up to chest height, keeping elbows high.',
        'Lower slowly with control.',
      ],
    ),
    Exercise(
      name: 'Cable Front Raise',
      videoPath: 'assets/videos/shoulder/shoulder_cable_frontraise.mp4',
      description:
          'Provides constant tension throughout the entire movement to isolate the anterior (front) deltoids.',
      target: 'Shoulders (Anterior Delts)',
      equipment: 'Cable Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Stand facing away from cable machine, grab handle between legs.',
        'Raise arm forward until parallel to floor.',
        'Lower under control, keeping tension.',
      ],
    ),
    Exercise(
      name: 'Cable Lateral Raise',
      videoPath: 'assets/videos/shoulder/shoulder_cable_lateral_raise.mp4',
      description:
          'Cable lateral raise targets the lateral deltoids with constant resistance from bottom to top, maximizing shoulder width.',
      target: 'Shoulders (Lateral Delts)',
      equipment: 'Cable Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Stand next to cable machine, grab handle with opposite hand.',
        'Raise arm out to the side in a smooth arc to shoulder level.',
        'Lower slowly against cable tension.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Alternating Press',
      videoPath: 'assets/videos/shoulder/shoulder_dumbell_alternative_press.mp4',
      description:
          'Alternating overhead press that allows you to focus on the stability and drive of each shoulder independently.',
      target: 'Shoulders, Triceps',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10 reps per arm',
      instructions: [
        'Hold dumbbells at shoulders.',
        'Press one dumbbell overhead to full extension while keeping the other stationary.',
        'Lower it and repeat with the other arm.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Lateral Raises (Alt)',
      videoPath: 'assets/videos/shoulder/shoulder_dumbell_lateral_raises.mp4',
      description:
          'Alternative high-definition demonstration of the standing dumbbell lateral raise to build shoulder caps.',
      target: 'Shoulders (Lateral Delts)',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Stand holding dumbbells at your sides.',
        'Raise arms out to sides in an arc until parallel to floor.',
        'Lower slowly with control.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Seated Front Raise (Alt)',
      videoPath: 'assets/videos/shoulder/shoulder_dumbell_seated_frontraise.mp4',
      description:
          'Alternative high-definition demonstration of the seated dumbbell front raise, isolating the anterior delts.',
      target: 'Shoulders (Anterior Delts)',
      equipment: 'Dumbbells, Bench',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Sit flat on bench with dumbbells.',
        'Raise weights forward to shoulder height with palms down.',
        'Lower under control.',
      ],
    ),
    Exercise(
      name: 'Lever Seated Reverse Fly',
      videoPath: 'assets/videos/shoulder/shoulder_lever_seated_reverse_fly.mp4',
      description:
          'Machine reverse fly to fully isolate the posterior deltoids and upper back muscles safely and effectively.',
      target: 'Shoulders (Rear Delts), Rhomboids',
      equipment: 'Reverse Fly Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Sit facing the pad, grip handles.',
        'Pull arms straight back in a wide arc, squeezing rear delts.',
        'Return slowly to starting point.',
      ],
    ),
    Exercise(
      name: 'Barbell Rear Delt Raise',
      videoPath: 'assets/videos/shoulder/shoulder_barbell_rear_delt_raise.mp4',
      description:
          'Standing or bent-over barbell raise targeting the rear delts and middle back.',
      target: 'Shoulders (Rear Delts), Upper Back',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Bend at hips with flat back holding barbell.',
        'Raise bar behind you/upwards keeping arms straight.',
        'Contract rear delts at peak and lower with control.',
      ],
    ),
    Exercise(
      name: 'Barbell Shrug',
      videoPath: 'assets/videos/shoulder/shoulder_barbell_shrug.mp4',
      description:
          'Classic compound lift targeting the upper trapezius muscles to build shoulder width and neck thickness.',
      target: 'Traps, Upper Back',
      equipment: 'Barbell',
      difficulty: 'Beginner',
      setsReps: '4 sets × 12-15 reps',
      instructions: [
        'Stand upright holding barbell in front of thighs.',
        'Elevate shoulders as high as possible, squeezing traps at top.',
        'Lower bar slowly back to stretch.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Incline Shrug',
      videoPath: 'assets/videos/shoulder/shoulder_dumbell_incline_shrug.mp4',
      description:
          'Performed lying face down on an incline bench, this variation shifts focus to the middle and lower traps.',
      target: 'Traps (Middle & Lower)',
      equipment: 'Dumbbells, Incline Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Lie face down on an incline bench holding dumbbells.',
        'Shrug shoulders upwards and backwards, squeezing shoulder blades.',
        'Lower weights under control.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Shrug',
      videoPath: 'assets/videos/shoulder/shoulder_dumbell_shrug.mp4',
      description:
          'A trap developer that allows a more natural range of motion than a barbell since the weights are held at your sides.',
      target: 'Traps',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      setsReps: '4 sets × 12-15 reps',
      instructions: [
        'Hold dumbbells at your sides, stand upright.',
        'Shrug shoulders straight up toward ears.',
        'Lower slowly, feeling the stretch.',
      ],
    ),
    Exercise(
      name: 'Lever Shrug',
      videoPath: 'assets/videos/shoulder/shoulder_lever_shrug.mp4',
      description:
          'Machine shrug providing a guided path and maximum stability to isolate the trapezius muscles safely.',
      target: 'Traps',
      equipment: 'Shrug Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 12-15 reps',
      instructions: [
        'Stand inside machine, grip handles.',
        'Shrug shoulders upwards, holding squeeze at top.',
        'Return under control to start.',
      ],
    ),
  ];

  static const List<Exercise> biceps = [
    Exercise(
      name: 'Barbell Curl',
      videoPath: 'assets/videos/biceps/biceps_barbell_curl.mp4',
      description:
          'The classic biceps builder. This fundamental exercise targets both biceps heads effectively, building overall arm mass and strength. Perfect for developing peak and width.',
      target: 'Biceps, Forearms',
      equipment: 'Barbell',
      difficulty: 'Beginner',
      setsReps: '4 sets × 8-12 reps',
      instructions: [
        'Stand with feet shoulder-width apart, holding a barbell with an underhand grip',
        'Keep your elbows close to your torso and your upper arms stationary',
        'Curl the barbell up by contracting your biceps until the bar is at shoulder level',
        'Squeeze your biceps hard at the top of the movement',
        'Slowly lower the barbell back to the starting position',
        'Keep your core tight and avoid swinging your body',
      ],
    ),
    Exercise(
      name: 'EZ Barbell Biceps Curl',
      videoPath: 'assets/videos/biceps/biceps_ez_barbell_biceps_curl.mp4',
      description:
          'The angled grip reduces wrist strain while still providing excellent biceps activation. Ideal for those with wrist issues or looking for variety in their biceps training.',
      target: 'Biceps, Forearms',
      equipment: 'EZ Barbell',
      difficulty: 'Beginner',
      setsReps: '4 sets × 8-12 reps',
      instructions: [
        'Stand holding an EZ bar with an underhand grip on the angled handles',
        'Keep your elbows stationary and close to your body',
        'Curl the bar up by contracting your biceps',
        'Pause at the top and squeeze your biceps',
        'Lower the weight slowly with control',
        'Maintain proper form throughout the movement',
      ],
    ),
    Exercise(
      name: 'Barbell Drag Curl',
      videoPath: 'assets/videos/biceps/biceps_barbell_drag_curl.mp4',
      description:
          'Advanced variation that keeps constant tension on the biceps. By dragging the bar close to your body, you eliminate momentum and maximize muscle activation.',
      target: 'Biceps',
      equipment: 'Barbell',
      difficulty: 'Advanced',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Stand holding a barbell with an underhand grip',
        'Keep the bar close to your body throughout the movement',
        'Drag the bar up your torso by flexing your biceps',
        'Keep your elbows back and stationary',
        'Focus on the biceps contraction without swinging',
        'Lower the bar slowly along the same path',
      ],
    ),
    Exercise(
      name: 'Barbell Prone Incline Curl',
      videoPath: 'assets/videos/biceps/biceps_barbell_prone_incline_curl.mp4',
      description:
          'Performed on an incline bench, this variation provides a deep stretch and eliminates cheating. The angle targets the long head of the biceps for peak development.',
      target: 'Biceps (Long Head)',
      equipment: 'Barbell, Incline Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Set an incline bench to 45-60 degrees',
        'Lie face down on the bench with arms hanging down',
        'Hold the barbell with an underhand grip',
        'Curl the bar up by flexing your biceps',
        'Squeeze at the top and feel the stretch at the bottom',
        'Control the negative portion of the movement',
      ],
    ),
    Exercise(
      name: 'Dumbbell Biceps Curl',
      videoPath: 'assets/videos/biceps/biceps_dumbell_biceps_curl.mp4',
      description:
          'Allows independent arm movement, helping correct muscle imbalances. Each arm works independently, ensuring balanced biceps development and improved coordination.',
      target: 'Biceps, Forearms',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Stand holding dumbbells at your sides with palms facing forward',
        'Keep your elbows close to your torso and upper arms stationary',
        'Curl the weights up by contracting your biceps',
        'Rotate your wrists slightly outward as you curl',
        'Squeeze your biceps at the top',
        'Lower the dumbbells slowly with control',
      ],
    ),
    Exercise(
      name: 'Dumbbell Alternative Biceps Curl',
      videoPath: 'assets/videos/biceps/biceps_dumbell_alternative_biceps_curl.mp4',
      description:
          'Alternating arm movement allows for better focus on each bicep. This unilateral approach helps identify and correct strength imbalances while maintaining intensity.',
      target: 'Biceps, Forearms',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps per arm',
      instructions: [
        'Stand holding dumbbells at your sides',
        'Curl one dumbbell up while keeping the other arm stationary',
        'Lower the first dumbbell as you curl the other',
        'Alternate arms in a controlled, rhythmic motion',
        'Focus on the contraction in each arm',
        'Keep your core engaged and avoid swinging',
      ],
    ),
    Exercise(
      name: 'Dumbbell Alternative Seated Curl',
      videoPath: 'assets/videos/biceps/biceps_dumbell_alternative_seated_curl.mp4',
      description:
          'Seated position eliminates momentum and body swing. This strict form ensures maximum biceps isolation and is perfect for focusing on muscle contraction.',
      target: 'Biceps, Forearms',
      equipment: 'Dumbbells, Bench',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps per arm',
      instructions: [
        'Sit on a bench with back support, holding dumbbells at your sides',
        'Keep your feet flat on the floor and back against the pad',
        'Alternate curling each dumbbell up',
        'Focus on strict form without using momentum',
        'Squeeze each bicep at the top of the curl',
        'Lower each weight slowly and with control',
      ],
    ),
    Exercise(
      name: 'Dumbbell Concentration Curl',
      videoPath: 'assets/videos/biceps/biceps_dumbell_concentration_curl.mp4',
      description:
          'The ultimate biceps isolation exercise. Sitting and bracing your arm eliminates all momentum, forcing pure biceps contraction. Excellent for peak development.',
      target: 'Biceps',
      equipment: 'Dumbbell, Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps per arm',
      instructions: [
        'Sit on a bench with legs spread apart',
        'Rest your elbow on the inside of your thigh',
        'Hold a dumbbell with an underhand grip',
        'Curl the weight up by flexing only your bicep',
        'Squeeze hard at the top of the movement',
        'Lower slowly and feel the stretch',
      ],
    ),
    Exercise(
      name: 'Dumbbell Prone Incline Curl',
      videoPath: 'assets/videos/biceps/biceps_dumbell_prone_incline_curl.mp4',
      description:
          'Lying face down on an incline bench provides a unique angle that stretches the biceps deeply. This position targets the long head for superior peak development.',
      target: 'Biceps (Long Head)',
      equipment: 'Dumbbells, Incline Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Set an incline bench to 45-60 degrees',
        'Lie face down with arms hanging down',
        'Hold dumbbells with an underhand grip',
        'Curl both dumbbells up simultaneously',
        'Feel the deep stretch at the bottom',
        'Squeeze your biceps at the top',
      ],
    ),
    Exercise(
      name: 'Dumbbell Seated Preacher Curl',
      videoPath: 'assets/videos/biceps/biceps_dumbell_seated_preacher_curl.mp4',
      description:
          'The preacher bench provides support and eliminates cheating. This strict movement ensures maximum biceps activation and is excellent for building peak and definition.',
      target: 'Biceps',
      equipment: 'Dumbbell, Preacher Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps per arm',
      instructions: [
        'Sit at a preacher bench with your arm resting on the pad',
        'Hold a dumbbell with an underhand grip',
        'Curl the weight up by flexing your bicep',
        'Keep your arm fully supported on the pad',
        'Squeeze hard at the top',
        'Lower slowly and feel the stretch',
      ],
    ),
    Exercise(
      name: 'Dumbbell Crossbody Hammer Curl',
      videoPath: 'assets/videos/biceps/biceps_dumbell_crossbody_hammer_curl.mp4',
      description:
          'Neutral grip variation that targets the brachialis and brachioradialis. The crossbody motion adds a unique angle, building arm thickness and width.',
      target: 'Brachialis, Brachioradialis, Biceps',
      equipment: 'Dumbbells',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps per arm',
      instructions: [
        'Stand holding dumbbells with a neutral grip (palms facing each other)',
        'Curl one dumbbell across your body toward the opposite shoulder',
        'Focus on the brachialis contraction',
        'Lower slowly and repeat with the other arm',
        'Alternate arms in a controlled motion',
        'Keep your core engaged throughout',
      ],
    ),
    Exercise(
      name: 'Cable One Arm Curl',
      videoPath: 'assets/videos/biceps/biceps_cable_one_arm_curl.mp4',
      description:
          'Cable provides constant tension throughout the entire range of motion. The one-arm approach allows for focused concentration and helps correct imbalances.',
      target: 'Biceps, Forearms',
      equipment: 'Cable Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 10-12 reps per arm',
      instructions: [
        'Stand facing a cable machine with a handle attached at the bottom',
        'Grab the handle with an underhand grip',
        'Keep your elbow stationary and close to your body',
        'Curl the handle up by contracting your bicep',
        'Feel the constant tension from the cable',
        'Lower slowly and repeat with the other arm',
      ],
    ),
    Exercise(
      name: 'Cable Standing Inner Curl',
      videoPath: 'assets/videos/biceps/biceps_cable_standing_inner_curl.mp4',
      description:
          'The inner grip targets the short head of the biceps. Cable resistance provides constant tension, maximizing muscle activation throughout the entire movement.',
      target: 'Biceps (Short Head)',
      equipment: 'Cable Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Stand between two cable machines with handles at the bottom',
        'Grab both handles with an underhand grip',
        'Keep your elbows stationary and close to your body',
        'Curl both handles up simultaneously',
        'Focus on squeezing your biceps at the top',
        'Lower slowly and maintain constant tension',
      ],
    ),
    Exercise(
      name: 'Dumbbell Incline Curl',
      videoPath: 'assets/videos/biceps/biceps_dumbell_incline_curl.mp4',
      description:
          'Sit on an incline bench to place the biceps under a deep stretch at the bottom of the movement. Excellent for building the long head of the biceps.',
      target: 'Biceps (Long Head)',
      equipment: 'Dumbbells, Incline Bench',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Set incline bench to 45 degrees.',
        'Sit back, arms hanging straight down.',
        'Curl dumbbells up, keeping elbows stationary.',
        'Squeeze biceps at the top and lower slowly.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Incline Hammer Curl',
      videoPath: 'assets/videos/biceps/biceps_dumbell_incline_hammer_curl.mp4',
      description:
          'Incline bench variation with a neutral hammer grip. Targets the brachialis and brachioradialis from a stretched position to build upper arm thickness.',
      target: 'Brachialis, Brachioradialis, Biceps',
      equipment: 'Dumbbells, Incline Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Sit back on a 45-degree incline bench with dumbbells.',
        'Hold weights with a neutral grip (palms facing each other).',
        'Curl dumbbells up, maintaining the neutral grip.',
        'Slowly lower to full stretch.',
      ],
    ),
    Exercise(
      name: 'Dumbbell One Arm Zottman Preacher Curl',
      videoPath: 'assets/videos/biceps/biceps_dumbell_one_zottman_preacher_curl.mp4',
      description:
          'Combines the strict isolation of the preacher bench with the forearm-building rotation of the Zottman curl. Perform one arm at a time for complete focus.',
      target: 'Biceps, Forearms',
      equipment: 'Dumbbell, Preacher Bench',
      difficulty: 'Advanced',
      setsReps: '3 sets × 10-12 reps per arm',
      instructions: [
        'Rest arm on preacher pad, holding dumbbell underhand.',
        'Curl weight up to shoulder level.',
        'At the top, rotate wrist so palm faces forward (overhand).',
        'Lower slowly in overhand grip, then rotate back to underhand at the bottom.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Lying Supine Curl',
      videoPath: 'assets/videos/biceps/biceps_lying_supine_dumbell_curl.mp4',
      description:
          'Performed lying flat on a bench, this movement completely isolates the biceps by eliminating legs and lower back assist, targeting overall arm mass.',
      target: 'Biceps',
      equipment: 'Dumbbells, Flat Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12 reps',
      instructions: [
        'Lie flat on your back on a bench, holding dumbbells.',
        'Extend arms straight down toward the floor, palms up.',
        'Curl dumbbells up toward shoulders, keeping upper arms vertical.',
        'Lower with control back to the starting stretch.',
      ],
    ),
  ];

  static const List<Exercise> triceps = [
    Exercise(
      name: 'Cable Lying Extension',
      videoPath: 'assets/videos/triceps/triceps_cable_lying_extension.mp4',
      description:
          'Isolation exercise performed lying down, providing excellent stability and focus on the triceps. The cable provides constant tension throughout the movement.',
      target: 'Triceps',
      equipment: 'Cable Machine, Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Lie on a flat bench with a cable machine behind your head',
        'Grab the cable attachment with an overhand grip',
        'Keep your elbows stationary and close to your head',
        'Extend your arms fully by contracting your triceps',
        'Squeeze at the top and feel the triceps contraction',
        'Lower slowly back to starting position',
      ],
    ),
    Exercise(
      name: 'Cable Overhead Triceps Extension',
      videoPath: 'assets/videos/triceps/triceps_cable_overhead_triceps_extension.mp4',
      description:
          'Standing overhead extension that targets all three heads of the triceps. The cable provides constant tension, maximizing muscle activation throughout the range of motion.',
      target: 'Triceps (All Heads)',
      equipment: 'Cable Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Stand facing away from the cable machine',
        'Grab the cable attachment with both hands overhead',
        'Keep your elbows close to your head and stationary',
        'Lower the cable behind your head by bending elbows',
        'Extend your arms fully, squeezing your triceps',
        'Control the weight throughout the movement',
      ],
    ),
    Exercise(
      name: 'Cable Pushdown',
      videoPath: 'assets/videos/triceps/triceps_cable_pushdown.mp4',
      description:
          'The most popular triceps exercise. Targets the lateral and medial heads effectively. The cable provides constant tension, making it perfect for building triceps mass.',
      target: 'Triceps (Lateral & Medial Heads)',
      equipment: 'Cable Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-15 reps',
      instructions: [
        'Stand facing the cable machine with handle at chest height',
        'Grab the handle with an overhand grip',
        'Keep your elbows pinned to your sides',
        'Push the handle down until arms are fully extended',
        'Squeeze your triceps hard at the bottom',
        'Return slowly to starting position',
      ],
    ),
    Exercise(
      name: 'Cable Rope High Pulley Extension',
      videoPath: 'assets/videos/triceps/triceps_cable_rope_high_pulley_extension.mp4',
      description:
          'Rope attachment allows for a natural hand position and better triceps contraction. The high pulley angle targets the triceps from a different angle.',
      target: 'Triceps',
      equipment: 'Cable Machine, Rope Attachment',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Attach rope to high pulley on cable machine',
        'Grab the rope with both hands, palms facing each other',
        'Keep elbows close to your sides',
        'Push the rope down, separating your hands at the bottom',
        'Squeeze your triceps and feel the contraction',
        'Return to starting position with control',
      ],
    ),
    Exercise(
      name: 'Cable Standing One Arm Extension',
      videoPath: 'assets/videos/triceps/triceps_cable_standing_one_arm_extension.mp4',
      description:
          'Unilateral exercise that allows you to focus on each arm independently. Helps identify and correct strength imbalances while building triceps mass.',
      target: 'Triceps',
      equipment: 'Cable Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps per arm',
      instructions: [
        'Stand facing the cable machine with handle at shoulder height',
        'Grab the handle with one hand using an overhand grip',
        'Keep your elbow pinned to your side',
        'Extend your arm down until fully straight',
        'Squeeze your triceps at the bottom',
        'Return slowly and repeat with other arm',
      ],
    ),
    Exercise(
      name: 'Close Grip Push-up',
      videoPath: 'assets/videos/triceps/triceps_close_grip_pushup.mp4',
      description:
          'Bodyweight exercise that targets triceps effectively. The close hand position increases triceps activation while also engaging chest and shoulders.',
      target: 'Triceps, Chest, Shoulders',
      equipment: 'None',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-15 reps',
      instructions: [
        'Start in plank position with hands close together (diamond shape)',
        'Keep your body in a straight line from head to heels',
        'Lower your body by bending elbows, keeping them close to body',
        'Push back up by extending arms, focusing on triceps',
        'Keep your core engaged throughout',
        'Maintain proper form throughout all reps',
      ],
    ),
    Exercise(
      name: 'Dumbbell Incline Triceps Extension',
      videoPath: 'assets/videos/triceps/triceps_dumbell_incline_triceps_extension.mp4',
      description:
          'Performed on an incline bench, this variation provides a different angle of resistance. The incline position targets the triceps uniquely.',
      target: 'Triceps',
      equipment: 'Dumbbell, Incline Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Set bench to 30-45 degree incline',
        'Lie back holding one dumbbell with both hands overhead',
        'Keep your elbows stationary and close to your head',
        'Lower the dumbbell behind your head by bending elbows',
        'Extend your arms fully, squeezing your triceps',
        'Control the weight throughout the movement',
      ],
    ),
    Exercise(
      name: 'Dumbbell One Arm Triceps Extension',
      videoPath: 'assets/videos/triceps/triceps_dumbell_one_arm_triceps_extension.mp4',
      description:
          'Unilateral exercise that allows independent arm work. Helps correct imbalances and provides focused triceps isolation on each arm.',
      target: 'Triceps',
      equipment: 'Dumbbell',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps per arm',
      instructions: [
        'Stand or sit holding a dumbbell in one hand',
        'Raise the dumbbell overhead with arm fully extended',
        'Keep your elbow stationary and close to your head',
        'Lower the dumbbell behind your head by bending elbow',
        'Extend your arm fully, squeezing your triceps',
        'Repeat with the other arm',
      ],
    ),
    Exercise(
      name: 'Dumbbell Seated Kickback',
      videoPath: 'assets/videos/triceps/triceps_dumbell_seated_kickback.mp4',
      description:
          'Seated position provides stability and eliminates momentum. The kickback motion isolates the triceps effectively, perfect for building definition.',
      target: 'Triceps',
      equipment: 'Dumbbell, Bench',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps per arm',
      instructions: [
        'Sit on a bench leaning forward slightly',
        'Hold a dumbbell in one hand with elbow bent at 90 degrees',
        'Keep your elbow pinned to your side',
        'Extend your arm back by contracting your triceps',
        'Squeeze at the top and hold for a moment',
        'Return slowly and repeat with other arm',
      ],
    ),
    Exercise(
      name: 'Dumbbell Seated Triceps Extension',
      videoPath: 'assets/videos/triceps/triceps_dumbell_seated_triceps_extension.mp4',
      description:
          'Seated position eliminates body swing and momentum. This strict form ensures maximum triceps isolation and is excellent for building triceps mass.',
      target: 'Triceps',
      equipment: 'Dumbbell, Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Sit on a bench with back support',
        'Hold one dumbbell with both hands overhead',
        'Keep your elbows close to your head and stationary',
        'Lower the dumbbell behind your head by bending elbows',
        'Extend your arms fully, squeezing your triceps',
        'Control the weight throughout the movement',
      ],
    ),
    Exercise(
      name: 'EZ Barbell Lying Extension',
      videoPath: 'assets/videos/triceps/triceps_ez_barbell_lying_extension.mp4',
      description:
          'Lying position provides excellent stability and triceps isolation. The EZ bar reduces wrist strain compared to a straight barbell.',
      target: 'Triceps',
      equipment: 'EZ Barbell, Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Lie on a flat bench holding an EZ bar with narrow grip',
        'Start with arms extended over your chest',
        'Lower the bar to your forehead by bending elbows',
        'Keep your elbows stationary and pointing forward',
        'Extend your arms fully, squeezing your triceps',
        'Control the weight throughout',
      ],
    ),
    Exercise(
      name: 'Lever Seated Dips',
      videoPath: 'assets/videos/triceps/triceps_liver_seated_dips.mp4',
      description:
          'Machine-based exercise that provides safety and stability. Perfect for beginners or when you want to isolate triceps without worrying about balance.',
      target: 'Triceps, Shoulders',
      equipment: 'Dip Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Sit in the dip machine with your back against the pad',
        'Grip the handles with palms facing down',
        'Lower your body by bending your elbows',
        'Keep your elbows close to your body',
        'Push back up by extending your arms',
        'Focus on triceps contraction throughout',
      ],
    ),
    Exercise(
      name: 'Old School Reverse Extension',
      videoPath: 'assets/videos/triceps/triceps_old_school_reverse_extension.mp4',
      description:
          'Classic triceps exercise with a reverse grip. The underhand grip targets the triceps from a unique angle, providing variety in your training.',
      target: 'Triceps',
      equipment: 'Cable Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Stand facing the cable machine with handle at chest height',
        'Grab the handle with an underhand (reverse) grip',
        'Keep your elbows pinned to your sides',
        'Extend your arms down until fully straight',
        'Squeeze your triceps at the bottom',
        'Return slowly to starting position',
      ],
    ),
    Exercise(
      name: 'Bench Dips',
      videoPath: 'assets/videos/triceps/triceps_bench_dips.mp4',
      description:
          'A classic bodyweight movement targeting the triceps, chest, and shoulders. Highly effective for building arms without equipment.',
      target: 'Triceps, Front Delts',
      equipment: 'Bench',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Place hands on the edge of the bench, feet extended forward.',
        'Lower your hips by bending at the elbows until they form a 90-degree angle.',
        'Press through your palms to return to the starting position.',
      ],
    ),
    Exercise(
      name: 'Cable Rope Pushdown',
      videoPath: 'assets/videos/triceps/triceps_cable_pushdown_rope.mp4',
      description:
          'A variation of the cable pushdown using a rope attachment to allow a greater range of motion and flare at the bottom for lateral head activation.',
      target: 'Triceps (Lateral Head)',
      equipment: 'Cable Machine, Rope',
      difficulty: 'Beginner',
      setsReps: '4 sets × 12-15 reps',
      instructions: [
        'Attach rope to high pulley, stand close, elbow pinned.',
        'Push hands down and flare them outward at the bottom.',
        'Return slowly to chest level.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Close Grip Press',
      videoPath: 'assets/videos/triceps/triceps_dumbell_closegrip_press.mp4',
      description:
          'A close grip chest press using dumbbells pressed together. Shifts the load away from the chest directly onto the triceps.',
      target: 'Triceps, Inner Chest',
      equipment: 'Dumbbells, Flat Bench',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Lie on flat bench, hold dumbbells pressed against each other over chest.',
        'Lower dumbbells slowly until they touch your lower chest.',
        'Press straight up explosively, maintaining pressure between dumbbells.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Lying Alternate Triceps Extension',
      videoPath: 'assets/videos/triceps/triceps_dumbell_lying_alternate_extension.mp4',
      description:
          'Also known as alternating skull crushers. Allows you to focus on the extension and contraction of each tricep independently.',
      target: 'Triceps',
      equipment: 'Dumbbells, Flat Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps per arm',
      instructions: [
        'Lie on bench holding dumbbells overhead.',
        'Lower one weight to the side of your head by bending at the elbow.',
        'Extend back up, then repeat with the opposite arm.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Lying Triceps Extension',
      videoPath: 'assets/videos/triceps/triceps_dumbell_lying_extension.mp4',
      description:
          'Skull crushers performed with dumbbells. Isolates the triceps and provides a deep stretch at the bottom without elbow strain.',
      target: 'Triceps',
      equipment: 'Dumbbells, Flat Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12 reps',
      instructions: [
        'Lie flat on bench, hold dumbbells straight up.',
        'Bend elbows to lower weights near your ears.',
        'Extend arms straight up, squeezing triceps.',
      ],
    ),
    Exercise(
      name: 'Dumbbell Pronate Triceps Extension',
      videoPath: 'assets/videos/triceps/triceps_dumbell_pronate_triceps_extension.mp4',
      description:
          'Triceps extension performed with a pronated (overhand) grip, shifting emphasis to target the lateral head of the triceps.',
      target: 'Triceps (Lateral Head)',
      equipment: 'Dumbbells, Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Hold dumbbells overhand (palms facing away).',
        'Lower weights towards forehead.',
        'Contract triceps to extend arms fully.',
      ],
    ),
    Exercise(
      name: 'Barbell Close Grip Bench Press',
      videoPath: 'assets/videos/triceps/tricpes_barbell_close_grip_bench_press.mp4',
      description:
          'A compound movement that targets the triceps with heavy resistance. Hands are positioned shoulder-width apart to focus load on the arms.',
      target: 'Triceps, Chest, Shoulders',
      equipment: 'Barbell, Flat Bench',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 8-12 reps',
      instructions: [
        'Lie on bench, grip bar at shoulder-width.',
        'Lower bar slowly to mid-chest, keeping elbows close to your sides.',
        'Press bar up explosively.',
      ],
    ),
    Exercise(
      name: 'Close Grip Pushups (Alt)',
      videoPath: 'assets/videos/triceps/triceps_close_grip_pushups.mp4',
      description:
          'An alternative high-definition demonstration of the close grip bodyweight pushup to maximize triceps development.',
      target: 'Triceps, Chest',
      equipment: 'Bodyweight',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-15 reps',
      instructions: [
        'Place hands close together on floor under chest.',
        'Lower body until chest is close to floor.',
        'Push straight up focusing on triceps extension.',
      ],
    ),
  ];

  static const List<Exercise> abs = [
    Exercise(
      name: 'V-Up',
      videoPath: 'assets/videos/abs/abs_v-up.mp4',
      description:
          'Advanced core exercise that targets the entire abdominal region. Combines a crunch with a leg raise, creating a V-shape with your body.',
      target: 'Upper Abs, Lower Abs, Hip Flexors',
      equipment: 'None',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Lie flat on your back with arms extended overhead',
        'Simultaneously lift your torso and legs off the ground',
        'Reach your hands toward your feet, creating a V-shape',
        'Keep your core tight and avoid using momentum',
        'Lower slowly back to starting position',
        'Breathe out as you lift, breathe in as you lower',
      ],
    ),
    Exercise(
      name: 'Vertical Leg Raise',
      videoPath: 'assets/videos/abs/abs_vertical_leg_raise.mp4',
      description:
          'Targets the lower abdominals and hip flexors. Hanging from a bar challenges your grip strength while building core stability.',
      target: 'Lower Abs, Hip Flexors',
      equipment: 'Pull-up Bar',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Hang from a pull-up bar with arms fully extended',
        'Keep your legs straight and together',
        'Lift your legs up until they are parallel to the ground',
        'Squeeze your lower abs at the top',
        'Lower slowly with control',
        'Avoid swinging or using momentum',
        'Keep your core engaged throughout',
      ],
    ),
    Exercise(
      name: 'Incline Leg Hip Raise',
      videoPath: 'assets/videos/abs/abs_incline_leg_hip_raise.mp4',
      description:
          'Performed on an incline bench, this exercise targets the lower abs with added resistance from gravity. Great for building lower ab strength.',
      target: 'Lower Abs, Hip Flexors',
      equipment: 'Incline Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Lie on an incline bench with your head higher than your feet',
        'Hold onto the bench behind your head for support',
        'Lift your legs and hips up toward your chest',
        'Squeeze your lower abs at the top',
        'Lower slowly with control',
        'Keep your core engaged throughout',
        'Avoid arching your back excessively',
      ],
    ),
    Exercise(
      name: 'Twisting Crunch',
      videoPath: 'assets/videos/abs/abs_twisting_crunch.mp4',
      description:
          'Crunch variation with rotation that targets the obliques. The twisting motion engages the side abdominals for a complete core workout.',
      target: 'Upper Abs, Obliques',
      equipment: 'None',
      difficulty: 'Beginner',
      setsReps: '3 sets × 15-20 reps per side',
      instructions: [
        'Lie on your back with knees bent and feet flat',
        'Place your hands behind your head',
        'Crunch up while rotating your torso',
        'Bring your right elbow toward your left knee',
        'Lower back down and alternate sides',
        'Keep your core engaged throughout',
        'Avoid pulling on your neck',
      ],
    ),
    Exercise(
      name: 'Air Twist Crunch',
      videoPath: 'assets/videos/abs/abs_air_twist_crunch.mp4',
      description:
          'Dynamic core exercise that combines a crunch with a twisting motion. Targets the obliques while improving rotational strength.',
      target: 'Upper Abs, Obliques',
      equipment: 'None',
      difficulty: 'Beginner',
      setsReps: '3 sets × 15-20 reps',
      instructions: [
        'Lie on your back with knees bent',
        'Lift your shoulders off the ground',
        'Rotate your torso side to side',
        'Keep your core tight throughout',
        'Move in a controlled, rhythmic motion',
        'Breathe naturally throughout',
        'Focus on the oblique contraction',
      ],
    ),
    Exercise(
      name: 'Cable Kneeling Crunch',
      videoPath: 'assets/videos/abs/abs_cable_kneeling_crunch.mp4',
      description:
          'Kneeling cable crunch that provides constant resistance throughout the movement. Excellent for building upper ab strength with progressive resistance.',
      target: 'Upper Abs',
      equipment: 'Cable Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Kneel facing away from the cable machine',
        'Hold the rope attachment behind your head',
        'Crunch down, bringing your elbows toward your knees',
        'Squeeze your abs at the bottom',
        'Return slowly to starting position',
        'Keep constant tension on the cable',
        'Avoid using your arms to pull',
      ],
    ),
    Exercise(
      name: 'Cable Standing Crunch',
      videoPath: 'assets/videos/abs/abs_cable_standing_crunch.mp4',
      description:
          'Standing cable crunch that targets the upper abs while engaging your core stabilizers. The standing position challenges balance and coordination.',
      target: 'Upper Abs, Core Stabilizers',
      equipment: 'Cable Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Stand facing away from the cable machine',
        'Hold the rope attachment overhead',
        'Crunch down, bringing your elbows toward your hips',
        'Squeeze your abs at the bottom',
        'Return slowly to starting position',
        'Keep your core engaged throughout',
        'Maintain good posture',
      ],
    ),
    Exercise(
      name: 'Cable Twist (Up/Down)',
      videoPath: 'assets/videos/abs/abs_cable_twist(up_down).mp4',
      description:
          'Dynamic cable exercise that combines vertical and rotational movement. Targets the obliques and entire core with constant resistance.',
      target: 'Obliques, Core',
      equipment: 'Cable Machine',
      difficulty: 'Advanced',
      setsReps: '3 sets × 12-15 reps per side',
      instructions: [
        'Stand sideways to the cable machine',
        'Hold the handle with both hands',
        'Rotate your torso while moving up and down',
        'Keep your core tight throughout',
        'Control the movement in both directions',
        'Alternate sides after completing reps',
        'Maintain constant tension on the cable',
      ],
    ),
    Exercise(
      name: 'Lever Seated Leg Raise',
      videoPath: 'assets/videos/abs/abs_lever_seated_leg_raise.mp4',
      description:
          'Machine-based leg raise that targets the lower abs. The seated position provides back support while isolating the abdominal muscles.',
      target: 'Lower Abs',
      equipment: 'Ab Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Sit in the ab machine with back support',
        'Place your forearms on the pads',
        'Lift your knees up toward your chest',
        'Squeeze your lower abs at the top',
        'Lower slowly with control',
        'Keep your core engaged throughout',
        'Avoid using momentum',
      ],
    ),
    Exercise(
      name: 'Weighted Leg Extension',
      videoPath: 'assets/videos/abs/abs_weighted_leg_extension.mp4',
      description:
          'Advanced core exercise that targets the lower abs with added resistance. The weighted variation increases difficulty and muscle activation.',
      target: 'Lower Abs, Hip Flexors',
      equipment: 'Dumbbell or Ankle Weights',
      difficulty: 'Advanced',
      setsReps: '3 sets × 10-12 reps',
      instructions: [
        'Lie on your back holding a weight between your feet',
        'Keep your legs straight',
        'Lift your legs up until perpendicular to the ground',
        'Lower slowly with control',
        'Keep your lower back pressed to the floor',
        'Squeeze your lower abs throughout',
        'Breathe out as you lift, breathe in as you lower',
      ],
    ),
    Exercise(
      name: '45 Degree Side Bend',
      videoPath: 'assets/videos/abs/abs_45_degree_side_bend.mp4',
      description:
          'Isolation exercise that targets the obliques. The 45-degree angle provides optimal muscle activation for the side abdominals.',
      target: 'Obliques',
      equipment: 'Dumbbell (optional)',
      difficulty: 'Beginner',
      setsReps: '3 sets × 15-20 reps per side',
      instructions: [
        'Stand with feet shoulder-width apart',
        'Hold a dumbbell in one hand (optional)',
        'Bend to the side, lowering the weight',
        'Feel the stretch in your opposite oblique',
        'Return to starting position',
        'Alternate sides after completing reps',
        'Keep your core engaged throughout',
      ],
    ),
    Exercise(
      name: 'Stretching: Chin to Chest',
      videoPath: 'assets/videos/abs/abs_stretching_chin_to_chest.mp4',
      description:
          'Stretching exercise that releases tension in the neck and upper back. Essential for maintaining flexibility and preventing muscle tightness.',
      target: 'Neck, Upper Back',
      equipment: 'None',
      difficulty: 'Beginner',
      setsReps: 'Hold for 30 seconds, repeat 3 times',
      instructions: [
        'Sit or stand with good posture',
        'Slowly lower your chin toward your chest',
        'Feel the stretch in the back of your neck',
        'Hold the position for 30 seconds',
        'Breathe deeply and relax',
        'Return slowly to starting position',
        'Repeat as needed',
      ],
    ),
    Exercise(
      name: 'Stretching: Spinal Stretch',
      videoPath: 'assets/videos/abs/abs_stretching_spinal_stretch.mp4',
      description:
          'Gentle spinal mobility exercise that stretches the entire back and core. Helps improve posture and relieve tension after ab workouts.',
      target: 'Spine, Core, Back',
      equipment: 'None',
      difficulty: 'Beginner',
      setsReps: 'Hold for 30 seconds, repeat 3 times',
      instructions: [
        'Sit on the floor with legs extended',
        'Bend forward, reaching toward your toes',
        'Feel the stretch along your spine',
        'Hold the position for 30 seconds',
        'Breathe deeply and relax',
        'Return slowly to starting position',
        'Focus on lengthening your spine',
      ],
    ),
  ];

  static const List<Exercise> cardio = [
    Exercise(
      name: 'Battling Ropes',
      videoPath: 'assets/videos/cardio/cardio_battling_ropes.mp4',
      description:
          'High-intensity full-body exercise that builds explosive power and cardiovascular endurance. The alternating wave motion engages your core, shoulders, and legs simultaneously.',
      target: 'Full Body, Cardiovascular',
      equipment: 'Battling Ropes',
      difficulty: 'Intermediate',
      setsReps: '3-5 sets × 30-60 seconds',
      instructions: [
        'Stand with feet shoulder-width apart, holding one rope in each hand',
        'Alternate creating waves by raising and lowering each arm rapidly',
        'Keep your core engaged and maintain a slight squat position',
        'Focus on creating powerful, consistent waves',
        'Breathe rhythmically and maintain intensity',
        'Rest 30-60 seconds between sets',
      ],
    ),
    Exercise(
      name: 'Bridge Pose',
      videoPath: 'assets/videos/cardio/cardio_bridge_pose.mp4',
      description:
          'Yoga-inspired exercise that strengthens the glutes, hamstrings, and core while improving flexibility. Great for active recovery and low-impact cardio.',
      target: 'Glutes, Hamstrings, Core',
      equipment: 'Mat (Optional)',
      difficulty: 'Beginner',
      setsReps: '3 sets × 10-15 reps',
      instructions: [
        'Lie on your back with knees bent and feet flat on the floor',
        'Place your arms at your sides with palms facing down',
        'Press through your heels and lift your hips up',
        'Squeeze your glutes at the top and hold for 2-3 seconds',
        'Lower your hips slowly back to the starting position',
        'Keep your core engaged throughout the movement',
      ],
    ),
    Exercise(
      name: 'Burpee',
      videoPath: 'assets/videos/cardio/cardio_burpee.mp4',
      description:
          'The ultimate full-body cardio exercise. Combines squat, plank, push-up, and jump into one explosive movement. Burns maximum calories in minimum time.',
      target: 'Full Body, Cardiovascular',
      equipment: 'None',
      difficulty: 'Advanced',
      setsReps: '3-5 sets × 8-15 reps',
      instructions: [
        'Start in a standing position with feet shoulder-width apart',
        'Squat down and place your hands on the floor',
        'Jump your feet back into a plank position',
        'Perform a push-up (optional for beginners)',
        'Jump your feet back to squat position',
        'Explode up with arms overhead, landing softly',
        'Repeat immediately for continuous movement',
      ],
    ),
    Exercise(
      name: 'Flexian Leg Sit Up',
      videoPath: 'assets/videos/cardio/cardio_flexian_leg_sit_up.mp4',
      description:
          'Dynamic core exercise that combines sit-ups with leg movements. Targets your abs while providing cardiovascular benefits and improving coordination.',
      target: 'Abs, Core, Hip Flexors',
      equipment: 'Mat (Optional)',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-20 reps',
      instructions: [
        'Lie on your back with legs extended and arms behind your head',
        'Simultaneously lift your torso and bring knees toward chest',
        'Touch your elbows to your knees at the top',
        'Lower back down with control, extending legs',
        'Keep your core engaged throughout',
        'Maintain a steady rhythm',
      ],
    ),
    Exercise(
      name: 'Jumping Jack',
      videoPath: 'assets/videos/cardio/cardio_jumping_jack.mp4',
      description:
          'Classic cardio exercise that gets your heart rate up quickly. Simple yet effective for warming up or as part of a HIIT workout. Great for all fitness levels.',
      target: 'Full Body, Cardiovascular',
      equipment: 'None',
      difficulty: 'Beginner',
      setsReps: '3-5 sets × 20-50 reps',
      instructions: [
        'Stand with feet together and arms at your sides',
        'Jump up, spreading your legs shoulder-width apart',
        'Simultaneously raise your arms overhead',
        'Jump back to starting position',
        'Land softly on the balls of your feet',
        'Maintain a steady, rhythmic pace',
      ],
    ),
    Exercise(
      name: 'Jumping Rope',
      videoPath: 'assets/videos/cardio/cardio_jumping_rope.mp4',
      description:
          'One of the most efficient cardio exercises. Burns calories fast, improves coordination, and builds endurance. Portable and requires minimal space.',
      target: 'Calves, Shoulders, Cardiovascular',
      equipment: 'Jump Rope',
      difficulty: 'Beginner',
      setsReps: '3-5 sets × 30-120 seconds',
      instructions: [
        'Hold the rope handles at hip level with elbows close to body',
        'Jump lightly on the balls of your feet',
        'Turn the rope with your wrists, not your arms',
        'Land softly and maintain a steady rhythm',
        'Keep your core engaged and back straight',
        'Start with shorter intervals and build up',
      ],
    ),
    Exercise(
      name: 'Plyo Slide Lunge Stretch',
      videoPath: 'assets/videos/cardio/cardio_plyo_slide_lunge_stretch.mp4',
      description:
          'Dynamic lunge variation that combines strength, power, and flexibility. The sliding motion adds a unique challenge while improving hip mobility.',
      target: 'Legs, Glutes, Hip Flexors',
      equipment: 'Slide Board or Towel',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps per leg',
      instructions: [
        'Start in a lunge position with one foot on the slide',
        'Slide the back foot backward while maintaining lunge position',
        'Push through the front heel to return to starting position',
        'Alternate legs or complete all reps on one side',
        'Keep your front knee aligned over your ankle',
        'Maintain an upright torso throughout',
      ],
    ),
    Exercise(
      name: 'Stationary Bike',
      videoPath: 'assets/videos/cardio/cardio_stationary_bike.mp4',
      description:
          'Low-impact cardio exercise perfect for all fitness levels. Great for building endurance, burning calories, and improving cardiovascular health without stressing joints.',
      target: 'Legs, Cardiovascular',
      equipment: 'Stationary Bike',
      difficulty: 'Beginner',
      setsReps: '20-60 minutes continuous',
      instructions: [
        'Adjust the seat height so your leg is almost fully extended at bottom',
        'Start pedaling at a comfortable pace',
        'Maintain proper posture with core engaged',
        'Adjust resistance to match your fitness level',
        'Keep a steady rhythm and breathe consistently',
        'Gradually increase intensity or duration over time',
      ],
    ),
    Exercise(
      name: 'Treadmill Running',
      videoPath: 'assets/videos/cardio/cardio_treadmill_running.mp4',
      description:
          'Classic cardio exercise that builds endurance and burns calories. The controlled environment allows you to track speed, distance, and incline precisely.',
      target: 'Legs, Cardiovascular',
      equipment: 'Treadmill',
      difficulty: 'Beginner',
      setsReps: '20-60 minutes continuous',
      instructions: [
        'Start with a warm-up walk for 2-3 minutes',
        'Gradually increase speed to your running pace',
        'Maintain good posture with slight forward lean',
        'Land on midfoot, not heel, for better efficiency',
        'Swing arms naturally and keep core engaged',
        'Cool down with a walk before stopping',
      ],
    ),
    Exercise(
      name: 'Walk Wave Machine',
      videoPath: 'assets/videos/cardio/cardio_walk_wave_machine.mp4',
      description:
          'Low-impact cardio machine that simulates walking motion. Perfect for beginners, rehabilitation, or active recovery days. Provides smooth, natural movement.',
      target: 'Legs, Cardiovascular',
      equipment: 'Wave Machine',
      difficulty: 'Beginner',
      setsReps: '20-45 minutes continuous',
      instructions: [
        'Step onto the machine and hold the handrails for balance',
        'Start with a slow, comfortable pace',
        'Maintain natural walking motion',
        'Keep your core engaged and posture upright',
        'Gradually increase speed or resistance',
        'Cool down gradually before stopping',
      ],
    ),
  ];

  static List<Exercise> get lats => back;

  static List<Exercise> get arms => [
        ...biceps,
        ...triceps,
      ];

  static List<Exercise> get strengthExercises => [
        ...chest,
        ...back,
        ...legs,
        ...shoulders,
        ...biceps,
        ...triceps,
        ...abs,
      ];

  static List<Exercise> get all => [
        ...chest,
        ...back,
        ...legs,
        ...shoulders,
        ...biceps,
        ...triceps,
        ...abs,
        ...cardio,
      ];

  static List<String> get allExerciseNames =>
      all.map((e) => e.name).toList(growable: false);

  static const List<String> difficultyFilterOptions = [
    'All',
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  static const List<String> equipmentFilterOptions = [
    'All',
    'Dumbbell',
    'Barbell',
    'Cable',
    'Machine',
    'Bodyweight',
    'Resistance Band',
  ];

  /// Maps legacy placeholder or shorthand exercise names to their canonical
  /// catalog name so existing saved workout plans and logs continue to resolve.
  static const Map<String, String> legacyAliases = {
    'wide grip pull up': 'Pull-ups Wide Back Grip',
    'pull-ups': 'Pull-ups Wide Back Grip',
    'pull ups': 'Pull-ups Wide Back Grip',
    'barbell bent over row': 'Barbell Underhand Bent Over Row',
    'barbell row': 'Barbell Underhand Bent Over Row',
    'lat pulldown': 'Cable Pulldown',
    'seated cable row': 'Cable Seated Row',
    'standing military press': 'Military Press',
    'overhead press': 'Military Press',
    'seated barbell press': 'Barbell Seated Behind Head Military Press',
    'dumbbell lateral raise': 'Dumbbell Seated Lateral Raise',
    'arnold press': 'Dumbbell Arnold Press',
    'dumbbell curl': 'Dumbbell Biceps Curl',
    'tricep pushdown': 'Cable Pushdown',
    'triceps pushdown': 'Cable Pushdown',
    'skull crushers': 'Cable Lying Extension',
    'barbell squat': 'Classic Barbell Squat',
    'deadlift': 'Barbell Straight Leg Deadlift',
  };

  /// Strips optional `[Day]` prefix or suffix tags and trims whitespace.
  static String normalizeExerciseName(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return '';
    final withoutLeadingTag =
        trimmed.replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '');
    final withoutTrailingTag =
        withoutLeadingTag.replaceFirst(RegExp(r'\s*\[[^\]]+\]$'), '');
    return withoutTrailingTag.trim();
  }

  /// Checks whether [exercise] matches [rawQuery] using canonical exercise names
  /// (plus legacy aliases for backward compatibility).
  static bool matchesSearchQuery(Exercise exercise, String? rawQuery) {
    if (rawQuery == null) return true;
    final normalizedQuery = normalizeExerciseName(rawQuery).toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    final canonicalNameLower = exercise.name.toLowerCase();
    if (canonicalNameLower.contains(normalizedQuery)) {
      return true;
    }

    final queryTokens = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (queryTokens.length > 1 &&
        queryTokens.every((token) => canonicalNameLower.contains(token))) {
      return true;
    }

    for (final entry in legacyAliases.entries) {
      if (entry.value.toLowerCase() == canonicalNameLower &&
          entry.key.contains(normalizedQuery)) {
        return true;
      }
    }

    return false;
  }

  /// Checks whether [exercise] matches [selectedDifficulty].
  static bool matchesDifficultyFilter(
    Exercise exercise,
    String? selectedDifficulty,
  ) {
    if (selectedDifficulty == null) return true;
    final trimmed = selectedDifficulty.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'all') return true;
    return exercise.difficulty.trim().toLowerCase() == trimmed.toLowerCase();
  }

  /// Checks whether [exercise] matches [selectedEquipment] based on its
  /// existing canonical equipment metadata string.
  static bool matchesEquipmentFilter(
    Exercise exercise,
    String? selectedEquipment,
  ) {
    if (selectedEquipment == null) return true;
    final filter = selectedEquipment.trim().toLowerCase();
    if (filter.isEmpty || filter == 'all') return true;

    final equip = exercise.equipment.trim().toLowerCase();
    if (equip.isEmpty) return false;

    switch (filter) {
      case 'dumbbell':
      case 'dumbbells':
        return equip.contains('dumbbell');
      case 'barbell':
        return equip.contains('barbell');
      case 'cable':
        return equip.contains('cable');
      case 'machine':
        final withoutCableMachine = equip.replaceAll('cable machine', '');
        return withoutCableMachine.contains('machine') ||
            withoutCableMachine.contains('sled');
      case 'bodyweight':
        return equip.contains('bodyweight') ||
            equip == 'none' ||
            equip.contains('pull-up bar') ||
            equip.contains('dip bars') ||
            equip == 'bench' ||
            equip == 'incline bench';
      case 'resistance band':
      case 'band':
        return equip.contains('band');
      default:
        return equip.contains(filter);
    }
  }

  /// Filters [source] exercises by canonical name search [query], [difficulty],
  /// and [equipment].
  static List<Exercise> filterExercises(
    List<Exercise> source, {
    String? query,
    String? difficulty,
    String? equipment,
  }) {
    return source.where((exercise) {
      return matchesSearchQuery(exercise, query) &&
          matchesDifficultyFilter(exercise, difficulty) &&
          matchesEquipmentFilter(exercise, equipment);
    }).toList(growable: false);
  }

  /// Finds an [Exercise] by canonical name, `[Day] Name`, or legacy alias across
  /// all 8 categories.
  static Exercise? findByName(String rawName) {
    final normalized = normalizeExerciseName(rawName);
    if (normalized.isEmpty) return null;
    final lower = normalized.toLowerCase();

    for (final exercise in all) {
      if (exercise.name.toLowerCase() == lower) {
        return exercise;
      }
    }

    final canonicalAlias = legacyAliases[lower];
    if (canonicalAlias != null) {
      final aliasLower = canonicalAlias.toLowerCase();
      for (final exercise in all) {
        if (exercise.name.toLowerCase() == aliasLower) {
          return exercise;
        }
            }
    }

    return null;
  }

  /// Returns the canonical display category label for an exercise name.
  static String? categoryFor(String rawName) {
    final resolved = findByName(rawName);
    if (resolved == null) return null;
    final lower = resolved.name.toLowerCase();

    if (chest.any((e) => e.name.toLowerCase() == lower)) return 'Chest';
    if (back.any((e) => e.name.toLowerCase() == lower)) return 'Back';
    if (legs.any((e) => e.name.toLowerCase() == lower)) return 'Legs';
    if (shoulders.any((e) => e.name.toLowerCase() == lower)) return 'Shoulders';
    if (biceps.any((e) => e.name.toLowerCase() == lower)) return 'Biceps';
    if (triceps.any((e) => e.name.toLowerCase() == lower)) return 'Triceps';
    if (abs.any((e) => e.name.toLowerCase() == lower)) return 'Abs';
    if (cardio.any((e) => e.name.toLowerCase() == lower)) return 'Cardio';
    return null;
  }
}
