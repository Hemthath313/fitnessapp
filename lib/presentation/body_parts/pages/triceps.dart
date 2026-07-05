import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/presentation/widgets/interactive_exercise_detail.dart';
import 'package:flutter/material.dart';

// Custom triceps exercise data with descriptions
class TricepsExercise {
  final String name;
  final String videoPath;
  final String description;
  final String target;
  final String equipment;
  final List<String> instructions;
  final String difficulty;
  final String setsReps;

  TricepsExercise({
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

class TricepsExercisesPage extends StatefulWidget {
  const TricepsExercisesPage({super.key});

  @override
  _TricepsExercisesPageState createState() => _TricepsExercisesPageState();
}

class _TricepsExercisesPageState extends State<TricepsExercisesPage> {
  // Only show exercises that have local videos
  final List<TricepsExercise> tricepsExercises = [
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
    TricepsExercise(
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
                'Triceps Workouts',
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
                    'Build Powerful Triceps',
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
                final exercise = tricepsExercises[index];
                return _buildExerciseCard(exercise, index);
              },
              childCount: tricepsExercises.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(TricepsExercise exercise, int index) {
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

  void _showExerciseDetails(BuildContext context, TricepsExercise exercise) {
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
        category: 'Triceps',
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
