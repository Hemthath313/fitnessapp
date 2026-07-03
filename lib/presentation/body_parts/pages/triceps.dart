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
                    '${tricepsExercises.length} premium video workouts',
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
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorManager.limerGreen2.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showExerciseDetails(context, exercise),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Preview
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  height: 220,
                  width: double.infinity,
                  color: ColorManager.surface,
                  child: Stack(
                    children: [
                      ExerciseVideoPlayer(
                        videoPath: exercise.videoPath,
                        height: 220,
                        width: double.infinity,
                      ),
                      // Play button overlay
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: ColorManager.limerGreen2,
                            size: 40,
                          ),
                        ),
                      ),
                      // Difficulty badge
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: ColorManager.limerGreen2.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            exercise.difficulty,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Exercise Info
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise Name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: ColorManager.limerGreen2,
                          size: 20,
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Description
                    Text(
                      exercise.description,
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 16),

                    // Target & Equipment
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip(
                            Icons.center_focus_strong,
                            exercise.target,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoChip(
                            Icons.sports_gymnastics,
                            exercise.equipment,
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
