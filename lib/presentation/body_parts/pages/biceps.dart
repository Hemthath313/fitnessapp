import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/presentation/widgets/interactive_exercise_detail.dart';
import 'package:flutter/material.dart';

// Custom biceps exercise data with descriptions
class BicepsExercise {
  final String name;
  final String videoPath;
  final String description;
  final String target;
  final String equipment;
  final List<String> instructions;
  final String difficulty;
  final String setsReps;

  BicepsExercise({
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

class BicepsExercisesPage extends StatefulWidget {
  const BicepsExercisesPage({super.key});

  @override
  _BicepsExercisesPageState createState() => _BicepsExercisesPageState();
}

class _BicepsExercisesPageState extends State<BicepsExercisesPage> {
  // Only show exercises that have local videos
  final List<BicepsExercise> bicepsExercises = [
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
    BicepsExercise(
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
                'Biceps Workouts',
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
                    'Build Powerful Biceps',
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
                final exercise = bicepsExercises[index];
                return _buildExerciseCard(exercise, index);
              },
              childCount: bicepsExercises.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(BicepsExercise exercise, int index) {
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

  void _showExerciseDetails(BuildContext context, BicepsExercise exercise) {
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
        category: 'Biceps',
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
