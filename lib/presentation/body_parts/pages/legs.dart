import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

// Custom leg exercise data with descriptions
class LegExercise {
  final String name;
  final String videoPath;
  final String description;
  final String target;
  final String equipment;
  final List<String> instructions;
  final String difficulty;
  final String setsReps;

  LegExercise({
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

class LegExercisesPage extends StatefulWidget {
  const LegExercisesPage({super.key});

  @override
  _LegExercisesPageState createState() => _LegExercisesPageState();
}

class _LegExercisesPageState extends State<LegExercisesPage> {
  // Only show exercises that have local videos
  final List<LegExercise> legExercises = [
    LegExercise(
      name: 'Classic Barbell Squat',
      videoPath: 'assets/videos/legs/legs_classic_barbell_squat.mp4',
      description:
          'The king of leg exercises. Builds massive quadriceps, glutes, and hamstrings while engaging your core. Essential for lower body strength and power.',
      target: 'Quadriceps, Glutes, Hamstrings, Core',
      equipment: 'Barbell, Squat Rack',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 6-10 reps',
      instructions: [
        'Position the barbell on your upper back (not your neck)',
        'Stand with feet shoulder-width apart, toes slightly pointed out',
        'Keep your chest up and core tight',
        'Lower down by pushing your hips back and bending your knees',
        'Descend until your thighs are parallel to the floor or lower',
        'Drive through your heels to return to standing position',
        'Keep your knees tracking over your toes throughout',
      ],
    ),
    LegExercise(
      name: 'Barbell Front Chest Squat',
      videoPath: 'assets/videos/legs/legs_barbell_front_chest_squat.mp4',
      description:
          'Front-loaded squat variation that emphasizes quadriceps development. The front position requires more core stability and improves squat mechanics.',
      target: 'Quadriceps, Core, Upper Back',
      equipment: 'Barbell',
      difficulty: 'Advanced',
      setsReps: '4 sets × 6-10 reps',
      instructions: [
        'Rest the barbell on your front deltoids and upper chest',
        'Cross your arms to secure the bar or use a clean grip',
        'Stand with feet shoulder-width apart',
        'Keep your torso upright throughout the movement',
        'Lower down until thighs are parallel to floor',
        'Drive through your heels to stand up',
        'Maintain an upright posture to prevent the bar from rolling',
      ],
    ),
    LegExercise(
      name: 'Barbell Lunge',
      videoPath: 'assets/videos/legs/legs_barbell_lunge.mp4',
      description:
          'Unilateral leg exercise that builds strength and corrects muscle imbalances. Targets quads, glutes, and hamstrings while improving balance and coordination.',
      target: 'Quadriceps, Glutes, Hamstrings',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 10-12 reps per leg',
      instructions: [
        'Position barbell on your upper back',
        'Step forward with one leg into a lunge position',
        'Lower your back knee toward the ground',
        'Keep your front knee over your ankle, not past your toes',
        'Push through your front heel to return to start',
        'Alternate legs or complete all reps on one side first',
        'Keep your torso upright throughout',
      ],
    ),
    LegExercise(
      name: 'Dumbbell Lunge',
      videoPath: 'assets/videos/legs/legs_dumbbell_lunge.mp4',
      description:
          'Lunge variation using dumbbells for added resistance. Easier to balance than barbell lunges, making it great for beginners or when focusing on form.',
      target: 'Quadriceps, Glutes, Hamstrings',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps per leg',
      instructions: [
        'Hold dumbbells at your sides',
        'Step forward into a lunge position',
        'Lower until both knees are at 90-degree angles',
        'Keep your front knee aligned with your ankle',
        'Push through your front heel to return',
        'Maintain an upright torso throughout',
        'Alternate legs or complete all reps on one side',
      ],
    ),
    LegExercise(
      name: 'Dumbbell Goblet Squat',
      videoPath: 'assets/videos/legs/legs_dumbbell_goblet_squat.mp4',
      description:
          'Beginner-friendly squat variation that teaches proper squat mechanics. Holding the weight in front helps maintain an upright posture and engages the core.',
      target: 'Quadriceps, Glutes, Core',
      equipment: 'Dumbbell',
      difficulty: 'Beginner',
      setsReps: '4 sets × 12-15 reps',
      instructions: [
        'Hold a dumbbell vertically against your chest',
        'Stand with feet slightly wider than shoulder-width',
        'Keep your chest up and core engaged',
        'Lower down by pushing hips back and bending knees',
        'Descend until thighs are parallel to floor',
        'Drive through your heels to stand up',
        'Keep your knees tracking over your toes',
      ],
    ),
    LegExercise(
      name: 'Dumbbell Bar Grip Sumo Squat',
      videoPath: 'assets/videos/legs/legs_dumbbell_bar_grip_sumo_squat.mp4',
      description:
          'Wide-stance squat that targets inner thighs and glutes. The sumo position emphasizes the adductors and provides a different angle of muscle activation.',
      target: 'Quadriceps, Glutes, Inner Thighs',
      equipment: 'Dumbbell',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 12-15 reps',
      instructions: [
        'Stand with feet wider than shoulder-width, toes pointed out',
        'Hold a dumbbell with both hands between your legs',
        'Keep your chest up and core tight',
        'Lower down by pushing hips back',
        'Descend until thighs are parallel to floor',
        'Drive through your heels to stand up',
        'Feel the stretch in your inner thighs',
      ],
    ),
    LegExercise(
      name: 'Smith Chair Squat',
      videoPath: 'assets/videos/legs/legs_smith_chair_squat.mp4',
      description:
          'Machine-assisted squat using a Smith machine with a bench. Provides safety and stability while allowing you to focus on form and depth.',
      target: 'Quadriceps, Glutes',
      equipment: 'Smith Machine, Bench',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Position a bench behind you in the Smith machine',
        'Position the bar on your upper back',
        'Stand with feet shoulder-width apart',
        'Lower down until you touch the bench',
        'Drive through your heels to stand up',
        'Keep your core engaged throughout',
        'The bench helps ensure consistent depth',
      ],
    ),
    LegExercise(
      name: 'Close Feet Leg Press',
      videoPath: 'assets/videos/legs/legs_close_feet_leg_press.mp4',
      description:
          'Leg press variation with narrow foot placement that emphasizes the quadriceps. The close stance targets the outer quads and provides intense quad activation.',
      target: 'Quadriceps',
      equipment: 'Leg Press Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 12-15 reps',
      instructions: [
        'Sit in the leg press machine',
        'Place your feet close together on the platform',
        'Lower the weight by bending your knees',
        'Descend until your knees form a 90-degree angle',
        'Press through your feet to extend your legs',
        'Keep your back flat against the pad',
        'Focus on squeezing your quads at the top',
      ],
    ),
    LegExercise(
      name: 'Lever Leg Extension',
      videoPath: 'assets/videos/legs/legs_lever_leg_extension.mp4',
      description:
          'Isolation exercise that targets the quadriceps. Perfect for finishing your leg workout and achieving a deep quad pump.',
      target: 'Quadriceps',
      equipment: 'Leg Extension Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Sit in the leg extension machine',
        'Adjust the pad to rest on your lower shins',
        'Grasp the handles for stability',
        'Extend your legs until they are straight',
        'Squeeze your quads at the top',
        'Lower slowly with control',
        'Keep your back against the pad',
      ],
    ),
    LegExercise(
      name: 'Lever Lying Leg Curl',
      videoPath: 'assets/videos/legs/legs_lever_lying_leg_curl.mp4',
      description:
          'Isolation exercise for the hamstrings. The lying position provides excellent hamstring activation and helps balance quad-dominant training.',
      target: 'Hamstrings',
      equipment: 'Leg Curl Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Lie face down on the leg curl machine',
        'Position the pad on the back of your ankles',
        'Grasp the handles for stability',
        'Curl your heels toward your glutes',
        'Squeeze your hamstrings at the top',
        'Lower slowly with control',
        'Keep your hips pressed against the pad',
      ],
    ),
    LegExercise(
      name: 'Lever Kneeling Leg Curl',
      videoPath: 'assets/videos/legs/legs_lever_kneeling_leg_curl.mp4',
      description:
          'Kneeling leg curl variation that provides a different angle for hamstring development. The kneeling position offers unique muscle activation.',
      target: 'Hamstrings',
      equipment: 'Leg Curl Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Kneel on the machine with pad on back of ankles',
        'Grasp the handles for support',
        'Curl your heels toward your glutes',
        'Squeeze your hamstrings at the peak',
        'Lower slowly with control',
        'Keep your core engaged throughout',
        'Focus on the hamstring contraction',
      ],
    ),
    LegExercise(
      name: 'Band Bent Over Hip Extension',
      videoPath: 'assets/videos/legs/legs_band_bent_over_hip_extension.mp4',
      description:
          'Resistance band exercise that targets the glutes and hamstrings. Perfect for home workouts or as a warm-up before heavy leg training.',
      target: 'Glutes, Hamstrings',
      equipment: 'Resistance Band',
      difficulty: 'Beginner',
      setsReps: '3 sets × 15-20 reps per leg',
      instructions: [
        'Secure the band around your ankles or feet',
        'Bend forward at the hips, keeping back straight',
        'Extend one leg backward against the band resistance',
        'Squeeze your glute at the top',
        'Return slowly to starting position',
        'Alternate legs or complete all reps on one side',
        'Keep your core engaged throughout',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.darkGrey,
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar with gradient
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: ColorManager.black,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Leg Workouts',
                style: TextStyle(
                  color: Colors.white,
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
            iconTheme: IconThemeData(color: Colors.white),
          ),

          // Header Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build Powerful Legs',
                    style: TextStyle(
                      color: ColorManager.limerGreen2,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${legExercises.length} premium video workouts',
                    style: TextStyle(
                      color: Colors.white70,
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
                              color: Colors.white,
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
                final exercise = legExercises[index];
                return _buildExerciseCard(exercise, index);
              },
              childCount: legExercises.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(LegExercise exercise, int index) {
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
                  color: ColorManager.black,
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
                            style: TextStyle(
                              color: Colors.black,
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
                              color: Colors.white,
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
                        color: Colors.white70,
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
        color: ColorManager.black87,
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
                color: Colors.white70,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, LegExercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: ColorManager.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Player
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: ColorManager.limerGreen2.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ExerciseVideoPlayer(
                          videoPath: exercise.videoPath,
                          height: 300,
                          autoPlay: true, // Auto-play in detail view
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Exercise Name
                    Text(
                      exercise.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Description
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorManager.surface,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        exercise.description,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Info Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            'Target',
                            exercise.target,
                            Icons.center_focus_strong,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailCard(
                            'Equipment',
                            exercise.equipment,
                            Icons.sports_gymnastics,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            'Difficulty',
                            exercise.difficulty,
                            Icons.trending_up,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailCard(
                            'Sets & Reps',
                            exercise.setsReps,
                            Icons.repeat,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Instructions
                    Text(
                      'How to Perform',
                      style: TextStyle(
                        color: ColorManager.limerGreen2,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ...exercise.instructions.asMap().entries.map((entry) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ColorManager.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorManager.limerGreen2.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: ColorManager.limerGreen2,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Close Button
            Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.limerGreen2,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
