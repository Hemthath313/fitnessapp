import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyExercisePage extends StatelessWidget {
  final List<dynamic> exercises;
  final int day;
  final VoidCallback onComplete;

  const DailyExercisePage({
    super.key,
    required this.exercises,
    required this.day,
    required this.onComplete,
  });

  Future<Map<String, dynamic>> fetchProgress() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    print('Fetching progress for user ID: $userId');

    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    print('Firestore Snapshot Data: ${snapshot.data()}');

    final progressData = snapshot.data()?['progress'] ?? {};
    print('Six Pack Challenge Progress Data: $progressData');

    return progressData['sixPackChallenge'] ?? {};
  }

  bool isDayUnlocked(Map<String, dynamic> progressData, int day) {
    final completionDateStr = progressData['completionDate'] ?? '';
    final lastCompletedDay = progressData['lastCompletedDay'] ?? 0;

    final completionDate =
        DateTime.tryParse(completionDateStr)?.toLocal() ?? DateTime.now();
    final today = DateTime.now();

    // Compare only the date parts
    final isNewDay = today.year > completionDate.year ||
        today.month > completionDate.month ||
        today.day > completionDate.day;

    return isNewDay || day <= lastCompletedDay + 1;
  }

  String getDefaultSetsAndReps(String exerciseName, exercise) {
    final lowerName = exerciseName.toLowerCase();

    if (lowerName.contains('crunch') || lowerName.contains('sit-up')) {
      return '4 sets of 20 reps';
    } else if (lowerName.contains('plank')) {
      return '3 sets of 1-minute hold';
    } else if (lowerName.contains('leg raise') ||
        lowerName.contains('bicycle')) {
      return '4 sets of 15 reps';
    } else if (lowerName.contains('mountain climber') ||
        lowerName.contains('flutter kick')) {
      return '4 sets of 30 seconds';
    } else {
      return '3 sets of 12 reps'; // Default for other abs exercises
    }
  }

  void showExerciseDetails(BuildContext context, dynamic exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  exercise['gifUrl'],
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              exercise['name']
                  .toString()
                  .split(' ')
                  .map((word) => word[0].toUpperCase() + word.substring(1))
                  .join(' '),
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.white),
            ),
            SizedBox(height: 10),
            Text(
                'Target: ${exercise['target'].toString().split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ')}',
                style: TextStyle(fontSize: 16, color: ColorManager.white)),
            SizedBox(height: 5),
            Text(
                'Equipment: ${exercise['equipment'].toString().split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ')}',
                style: TextStyle(fontSize: 16, color: ColorManager.white)),
            SizedBox(height: 10),
            Text(
              'Sets & Reps:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.white),
            ),
            Text(
              getDefaultSetsAndReps(exercise['name'], exercise['equipment']),
              style: TextStyle(fontSize: 16, color: ColorManager.white),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.limerGreen2),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.darkGrey,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: ColorManager.darkGrey,
        title:
            Text('Day $day Exercises', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder(
        future: fetchProgress(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading progress data.',
                  style: TextStyle(color: Colors.white)),
            );
          }

          final progressData = snapshot.data as Map<String, dynamic>? ?? {};

          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              final isUnlocked = isDayUnlocked(progressData, day);

              return Card(
                color: isUnlocked ? ColorManager.black54 : Colors.grey[800],
                margin: EdgeInsets.all(12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 4,
                child: ListTile(
                  onTap: isUnlocked
                      ? () => showExerciseDetails(context, exercise)
                      : null,
                  contentPadding: EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      exercise['gifUrl'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    '${exercise['name']}'
                        .toString()
                        .split(' ')
                        .map(
                            (word) => word[0].toUpperCase() + word.substring(1))
                        .join(' '),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.white : Colors.white54),
                  ),
                  subtitle: Text(
                      'Equipment: ${exercise['equipment'].toString().split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ')}',
                      style:
                          TextStyle(fontSize: 16, color: ColorManager.white)),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.limerGreen2),
          onPressed: () async {
            final userId = FirebaseAuth.instance.currentUser!.uid;
            print('Marking Day $day as complete for user: $userId');

            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({
              'progress.sixPackChallenge.lastCompletedDay': day,
              'progress.sixPackChallenge.completionDate':
                  DateTime.now().toIso8601String(),
            });
            onComplete();
            Navigator.pop(context);
          },
          child: Text('Mark Day $day as Complete',
              style: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }
}
