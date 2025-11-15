import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
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
                'Back Workouts',
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
                    'Build a Powerful Back',
                    style: TextStyle(
                      color: ColorManager.limerGreen2,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${backExercises.length} premium video workouts',
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

  void _showExerciseDetails(BuildContext context, BackExercise exercise) {
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
