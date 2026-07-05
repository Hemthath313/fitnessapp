import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/presentation/widgets/interactive_exercise_detail.dart';
import 'package:flutter/material.dart';

// Custom shoulder exercise data with descriptions
class ShoulderExercise {
  final String name;
  final String videoPath;
  final String description;
  final String target;
  final String equipment;
  final List<String> instructions;
  final String difficulty;
  final String setsReps;

  ShoulderExercise({
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

class ShoulderExercisesPage extends StatefulWidget {
  const ShoulderExercisesPage({super.key});

  @override
  _ShoulderExercisesPageState createState() => _ShoulderExercisesPageState();
}

class _ShoulderExercisesPageState extends State<ShoulderExercisesPage> {
  // Only show exercises that have local videos
  final List<ShoulderExercise> shoulderExercises = [
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
    ShoulderExercise(
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
                'Shoulder Workouts',
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
                    'Build Powerful Shoulders',
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
                final exercise = shoulderExercises[index];
                return _buildExerciseCard(exercise, index);
              },
              childCount: shoulderExercises.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ShoulderExercise exercise, int index) {
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

  void _showExerciseDetails(BuildContext context, ShoulderExercise exercise) {
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
        category: 'Shoulder',
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
