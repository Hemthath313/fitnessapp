import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/presentation/cardio_workouts/cardio_log_panel.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef CardioExercise = Exercise;

class CardioExercisesPage extends StatefulWidget {
  const CardioExercisesPage({super.key});

  @override
  _CardioExercisesPageState createState() => _CardioExercisesPageState();
}

class _CardioExercisesPageState extends State<CardioExercisesPage> {
  // Centralized cardio exercise catalog
  final List<CardioExercise> cardioExercises = ExerciseData.cardio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar with gradient
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: ColorManager.background,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Cardio Workouts',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24.sp,
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
                    color: ColorManager.limerGreen2.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            iconTheme: IconThemeData(color: ColorManager.textPrimary),
          ),

          // Header Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Boost Your Cardio',
                    style: TextStyle(
                      color: ColorManager.primaryText,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Premium video workouts',
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 16.sp,
                    ),
                  ),
                  const SizedBox(height: 8),
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
    final hasEquipment = exercise.equipment.trim().isNotEmpty;
    return Container(
      key: ValueKey('exercise_card_${exercise.name}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        boxShadow: [
          BoxShadow(
            color: ColorManager.limerGreen2.withValues(alpha: 0.05),
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
                    height: 92,
                    child: ExerciseVideoPlayer(
                      videoPath: exercise.videoPath,
                      height: 92,
                      width: 110,
                      showThumbnailOnly: true,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Exercise details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        exercise.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exercise.setsReps,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ColorManager.primaryText,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasEquipment) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              size: 13,
                              color: ColorManager.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                exercise.equipment,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ColorManager.textPrimary.withValues(alpha: 0.85),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: ColorManager.limerGreen2.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                exercise.difficulty,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ColorManager.primaryText,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              exercise.target,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ColorManager.textSecondary,
                                fontSize: 12.sp,
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
                            color: ColorManager.limerGreen2.withValues(alpha: 0.3),
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
                          fit: BoxFit.contain,
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
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Description
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorManager.surface,
                        boxShadow: ColorManager.cardShadow,
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                      ),
                      child: Text(
                        exercise.description,
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 16.sp,
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
                        color: ColorManager.primaryText,
                        fontSize: 20.sp,
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
                          boxShadow: ColorManager.cardShadow,
                          borderRadius: BorderRadius.circular(AppRadius.small),
                          border: Border.all(
                            color: ColorManager.limerGreen2.withValues(alpha: 0.2),
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
                                  style:  TextStyle(
                                    color: ColorManager.onMint,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
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
                                  fontSize: 14.sp,
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

            // Timer + Log cardio, then Close
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: CardioLogPanel(exerciseName: exercise.name),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.limerGreen2,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child:  Text(
                    'Close',
                    style: TextStyle(
                      color: ColorManager.onMint,
                      fontSize: 18.sp,
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
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(
          color: ColorManager.limerGreen2.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ColorManager.primaryText, size: 20),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
