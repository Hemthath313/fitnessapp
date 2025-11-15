import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

// Custom chest exercise data with descriptions
class ChestExercise {
  final String name;
  final String videoPath;
  final String description;
  final String target;
  final String equipment;
  final List<String> instructions;
  final String difficulty;
  final String setsReps;

  ChestExercise({
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

class ChestExercisesPage extends StatefulWidget {
  const ChestExercisesPage({super.key});

  @override
  _ChestExercisesPageState createState() => _ChestExercisesPageState();
}

class _ChestExercisesPageState extends State<ChestExercisesPage> {
  // Only show exercises that have local videos
  final List<ChestExercise> chestExercises = [
    ChestExercise(
      name: 'Barbell Bench Press',
      videoPath: 'assets/videos/chest/chest_barbell_bench_press.mp4',
      description:
          'The king of chest exercises. This compound movement builds overall chest mass, shoulder strength, and triceps power. Essential for building a powerful upper body.',
      target: 'Chest, Shoulders, Triceps',
      equipment: 'Barbell, Bench',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 8-12 reps',
      instructions: [
        'Lie flat on the bench with your feet firmly planted on the ground',
        'Grip the barbell slightly wider than shoulder-width apart',
        'Unrack the bar and lower it to your chest with control (2-3 seconds)',
        'Press the bar up explosively until your arms are fully extended',
        'Keep your core tight, shoulder blades retracted, and maintain proper form',
        'Breathe out on the way up, breathe in on the way down',
      ],
    ),
    ChestExercise(
      name: 'Barbell Decline Bench Press',
      videoPath: 'assets/videos/chest/chest_barbell_decline_bench_press.mp4',
      description:
          'Targets the lower portion of your pectoral muscles. The decline angle increases activation of the lower chest, creating a well-rounded, defined chest development.',
      target: 'Lower Chest, Triceps',
      equipment: 'Barbell, Decline Bench',
      difficulty: 'Intermediate',
      setsReps: '4 sets × 8-10 reps',
      instructions: [
        'Secure yourself on the decline bench with your feet locked in place',
        'Grip the barbell with hands slightly wider than shoulder-width',
        'Lower the bar to your lower chest with controlled movement',
        'Press up powerfully, focusing on the lower chest contraction',
        'Maintain control throughout - don\'t let the bar bounce off your chest',
        'Keep your core engaged and maintain proper breathing rhythm',
      ],
    ),
    ChestExercise(
      name: 'Chest Dips',
      videoPath: 'assets/videos/chest/chest_dips.mp4',
      description:
          'Bodyweight exercise that targets the lower chest, shoulders, and triceps. Leaning forward emphasizes the chest muscles, making it an excellent bodyweight chest builder.',
      target: 'Lower Chest, Shoulders, Triceps',
      equipment: 'Dip Bars',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 8-12 reps',
      instructions: [
        'Grip the parallel bars and support your body weight',
        'Lean forward slightly to target the chest more',
        'Lower your body by bending your elbows until you feel a stretch',
        'Press up powerfully, focusing on chest contraction',
        'Keep your core tight and maintain control throughout',
        'Don\'t lock out your elbows at the top',
      ],
    ),
    ChestExercise(
      name: 'Band High Fly',
      videoPath: 'assets/videos/chest/chest_band_high_fly.mp4',
      description:
          'Resistance band exercise that targets the upper chest. The high angle emphasizes the clavicular head of the pectorals, perfect for building upper chest definition.',
      target: 'Upper Chest, Shoulders',
      equipment: 'Resistance Band',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Anchor the resistance band at chest height or above',
        'Hold the band handles with arms extended',
        'Pull the bands together in a wide arc motion',
        'Squeeze your chest muscles at the peak contraction',
        'Return to the starting position with control',
        'Keep constant tension throughout the movement',
      ],
    ),
    ChestExercise(
      name: 'Dumbbell Hammer Press',
      videoPath: 'assets/videos/chest/chest_dumbell_hammer_press.mp4',
      description:
          'Neutral grip press that reduces shoulder stress while building chest strength. The hammer grip (palms facing each other) is easier on the rotator cuffs.',
      target: 'Chest, Triceps',
      equipment: 'Dumbbells, Bench',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Lie on a bench holding dumbbells with neutral grip (palms facing each other)',
        'Press the dumbbells straight up until arms are extended',
        'Lower them with control to chest level',
        'Keep your wrists straight and maintain the neutral grip',
        'Focus on the chest contraction throughout',
        'This grip is gentler on the shoulders than traditional press',
      ],
    ),
    ChestExercise(
      name: 'Dumbbell Fly (Exercise Ball)',
      videoPath: 'assets/videos/chest/chest_dumbell_fly_exercise_ball.mp4',
      description:
          'Isolation exercise that stretches and contracts the chest muscles. Using an exercise ball adds core stability challenge, making it a functional movement.',
      target: 'Chest, Core',
      equipment: 'Dumbbells, Exercise Ball',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Lie on an exercise ball with your upper back supported',
        'Hold dumbbells with arms slightly bent (like hugging a tree)',
        'Lower the weights in a wide arc until you feel a stretch',
        'Bring them back together in a controlled motion',
        'Keep your core engaged to maintain balance on the ball',
        'Focus on the chest squeeze at the top of the movement',
      ],
    ),
    ChestExercise(
      name: 'Dumbbell Decline Fly (45°)',
      videoPath: 'assets/videos/chest/chest_dumbell_decline_fly_(45degree).mp4',
      description:
          'Isolates the lower chest muscles with a deep stretch. The decline angle maximizes lower pec activation, perfect for building the lower chest definition.',
      target: 'Lower Chest',
      equipment: 'Dumbbells, Decline Bench',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Secure yourself on a decline bench at 45 degrees',
        'Hold dumbbells with a slight bend in your elbows',
        'Lower the weights in a wide arc, feeling the stretch',
        'Bring them together in a controlled hugging motion',
        'Squeeze your chest muscles at the top',
        'Maintain control - don\'t let momentum take over',
      ],
    ),
    ChestExercise(
      name: 'Cable Standing Fly',
      videoPath: 'assets/videos/chest/chest_cable_standing_fly.mp4',
      description:
          'Provides constant tension throughout the movement. Standing position engages your core and stabilizers, making it a functional chest exercise with continuous muscle activation.',
      target: 'Chest, Core, Shoulders',
      equipment: 'Cable Machine',
      difficulty: 'Intermediate',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Stand between two cable machines with handles at chest height',
        'Grab the handles with a slight bend in your elbows',
        'Pull the cables together in front of you in an arc motion',
        'Squeeze your chest muscles hard at the peak contraction',
        'Return to the starting position with control',
        'Keep your core engaged and maintain good posture',
      ],
    ),
    ChestExercise(
      name: 'Lever Chest Press',
      videoPath: 'assets/videos/chest/chest_lever_chest_press.mp4',
      description:
          'Machine-based exercise that provides stability and safety. Perfect for beginners or when you want to isolate the chest without worrying about balance.',
      target: 'Chest, Triceps',
      equipment: 'Chest Press Machine',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Sit in the machine with your back flat against the pad',
        'Adjust the seat so handles are at chest level',
        'Press the handles forward until arms are extended',
        'Control the weight back to the starting position',
        'Keep your core engaged and maintain proper posture',
        'Focus on the chest contraction throughout the movement',
      ],
    ),
    ChestExercise(
      name: 'Lever Peck Deck Fly',
      videoPath: 'assets/videos/chest/chest_lever_peck_dec_fly.mp4',
      description:
          'Machine-based fly movement that isolates the chest muscles. The fixed path ensures proper form and maximum chest activation without stressing the shoulders.',
      target: 'Chest',
      equipment: 'Pec Deck Machine',
      difficulty: 'Beginner',
      setsReps: '3 sets × 12-15 reps',
      instructions: [
        'Sit in the machine with your back flat against the pad',
        'Place your forearms on the pads with elbows at 90 degrees',
        'Push the pads together in a controlled motion',
        'Squeeze your chest muscles hard at the peak',
        'Return to the starting position slowly',
        'Focus on the stretch and contraction of your chest',
      ],
    ),
    ChestExercise(
      name: 'Dumbbell Lying Hammer Press',
      videoPath: 'assets/videos/chest/chest_dumbell_lying_hamme_press.mp4',
      description:
          'Neutral grip variation that reduces shoulder stress. The hammer grip (palms facing each other) targets the chest while being easier on the rotator cuffs.',
      target: 'Chest, Triceps',
      equipment: 'Dumbbells, Bench',
      difficulty: 'Beginner',
      setsReps: '4 sets × 10-12 reps',
      instructions: [
        'Lie on a flat bench holding dumbbells with neutral grip',
        'Press the dumbbells straight up until arms are extended',
        'Lower them with control to chest level',
        'Keep your wrists straight and maintain the neutral grip',
        'Focus on the chest contraction throughout',
        'This grip is gentler on the shoulders',
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
                'Chest Workouts',
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
                    'Build a Powerful Chest',
                    style: TextStyle(
                      color: ColorManager.limerGreen2,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${chestExercises.length} premium video workouts',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorManager.black54,
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
                final exercise = chestExercises[index];
                return _buildExerciseCard(exercise, index);
              },
              childCount: chestExercises.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ChestExercise exercise, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorManager.black54,
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

  void _showExerciseDetails(BuildContext context, ChestExercise exercise) {
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
                        color: ColorManager.black54,
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
                          color: ColorManager.black54,
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
        color: ColorManager.black54,
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
