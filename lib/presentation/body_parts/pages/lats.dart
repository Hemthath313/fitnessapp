import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/presentation/widgets/interactive_exercise_detail.dart';
import 'package:flutter/material.dart';

// Custom back exercise data with descriptions
class BackExercise {
  final String name;
  final String videoPath;
  final String description;
  final String target;
  final String equipment;
  final List<String> instructions;
  final String difficulty;
  final String setsReps;

  BackExercise({
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

class LatExercisesPage extends StatefulWidget {
  const LatExercisesPage({super.key});

  @override
  _LatExercisesPageState createState() => _LatExercisesPageState();
}

class _LatExercisesPageState extends State<LatExercisesPage> {
  // Only show exercises that have local videos
  final List<BackExercise> backExercises = [
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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
    BackExercise(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar with gradient
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: ColorManager.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Back Workouts',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorManager.black,
                      ColorManager.darkGrey,
                      ColorManager.black,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: ColorManager.limerGreen2.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            iconTheme: IconThemeData(color: ColorManager.textPrimary),
          ),

          // Header Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build a Powerful Back',
                    style: TextStyle(
                      color: ColorManager.limerGreen2,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Premium video workouts',
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorManager.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: ColorManager.limerGreen2.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: ColorManager.limerGreen2,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All exercises include detailed video demonstrations and step-by-step instructions.',
                            style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Exercises List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final exercise = backExercises[index];
                return _buildExerciseCard(exercise, index);
              },
              childCount: backExercises.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(BackExercise exercise, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorManager.limerGreen2.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showExerciseDetails(context, exercise),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video/Thumbnail preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 110,
                    height: 85,
                    child: ExerciseVideoPlayer(
                      videoPath: exercise.videoPath,
                      height: 85,
                      width: 110,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Exercise details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exercise.setsReps,
                        style: TextStyle(
                          color: ColorManager.limerGreen2,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ColorManager.limerGreen2.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              exercise.difficulty,
                              style: TextStyle(
                                color: ColorManager.limerGreen2,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exercise.target,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ColorManager.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ColorManager.limerGreen2.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ColorManager.limerGreen2, size: 16),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, BackExercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => InteractiveExerciseDetailWidget(
        name: exercise.name,
        videoPath: exercise.videoPath,
        description: exercise.description,
        target: exercise.target,
        equipment: exercise.equipment,
        instructions: exercise.instructions,
        difficulty: exercise.difficulty,
        setsReps: exercise.setsReps,
        category: 'Lats',
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: ColorManager.limerGreen2.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ColorManager.limerGreen2, size: 20),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
