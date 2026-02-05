import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

class LegExercisesPage extends StatefulWidget {
  const LegExercisesPage({super.key});

  @override
  _LegExercisesPageState createState() => _LegExercisesPageState();
}

class _LegExercisesPageState extends State<LegExercisesPage> {
  // Use centralized data
  final List<Exercise> legExercises = ExerciseData.legs;

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

  Widget _buildExerciseCard(Exercise exercise, int index) {
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

  void _showExerciseDetails(BuildContext context, Exercise exercise) {
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
            SafeArea(
              child: Padding(
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
