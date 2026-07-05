import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

// Custom cardio exercise data with descriptions
class CardioExercise {
  final String name;
  final String videoPath;
  final String description;
  final String target;
  final String equipment;
  final List<String> instructions;
  final String difficulty;
  final String setsReps;

  CardioExercise({
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

class CardioExercisesPage extends StatefulWidget {
  const CardioExercisesPage({super.key});

  @override
  _CardioExercisesPageState createState() => _CardioExercisesPageState();
}

class _CardioExercisesPageState extends State<CardioExercisesPage> {
  // Only show exercises that have local videos
  final List<CardioExercise> cardioExercises = [
    CardioExercise(
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
    CardioExercise(
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
    CardioExercise(
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
    CardioExercise(
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
    CardioExercise(
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
    CardioExercise(
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
    CardioExercise(
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
    CardioExercise(
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
    CardioExercise(
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
    CardioExercise(
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
            backgroundColor: ColorManager.background,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Cardio Workouts',
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
                    Icons.directions_run,
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
                    'Boost Your Cardio',
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
                final exercise = cardioExercises[index];
                return _buildExerciseCard(exercise, index);
              },
              childCount: cardioExercises.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(CardioExercise exercise, int index) {
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

  void _showExerciseDetails(BuildContext context, CardioExercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: ColorManager.background,
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
                color: ColorManager.divider,
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
                        color: ColorManager.textPrimary,
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
                          color: ColorManager.textSecondary,
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
                                  style: const TextStyle(
                                    color: Colors.white,
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
                                  color: ColorManager.textPrimary,
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
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
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
