import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/presentation/widgets/interactive_exercise_detail.dart';
import 'package:flutter/material.dart';

// Custom abs exercise data with descriptions
class AbsExercise {
  final String name;
  final String videoPath;
  final String description;
  final String target;
  final String equipment;
  final List<String> instructions;
  final String difficulty;
  final String setsReps;

  AbsExercise({
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

class AbsExercisesPage extends StatefulWidget {
  const AbsExercisesPage({super.key});

  @override
  _AbsExercisesPageState createState() => _AbsExercisesPageState();
}

class _AbsExercisesPageState extends State<AbsExercisesPage> {
  // Only show exercises that have local videos
  final List<AbsExercise> absExercises = [
    AbsExercise(
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
    AbsExercise(
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
    AbsExercise(
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
    AbsExercise(
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
    AbsExercise(
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
    AbsExercise(
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
    AbsExercise(
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
    AbsExercise(
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
    AbsExercise(
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
    AbsExercise(
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
    AbsExercise(
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
    AbsExercise(
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
    AbsExercise(
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
                'Abs Workouts',
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
                    'Build a Strong Core',
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
                final exercise = absExercises[index];
                return _buildExerciseCard(exercise, index);
              },
              childCount: absExercises.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(AbsExercise exercise, int index) {
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

  void _showExerciseDetails(BuildContext context, AbsExercise exercise) {
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
        category: 'Abs',
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
