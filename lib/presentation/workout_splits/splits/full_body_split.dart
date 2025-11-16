import 'package:flutter/material.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:go_router/go_router.dart';

class FullBodyPage extends StatelessWidget {
  const FullBodyPage({super.key});

  void _showExerciseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ColorManager.black,
          title: const Text(
            "View Exercises?",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Do you want to see the detailed exercises for this split?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("No", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(Routes.bodypartsPage);
              },
              child: const Text("Yes", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final splits = [
      {
        'title': 'Full Body Day',
        'focus': 'Squats, Bench Press, Rows, Deadlifts, Overhead Press',
        'day': 'Monday'
      },
      {
        'title': 'Full Body Day',
        'focus': 'Squats, Bench Press, Rows, Deadlifts, Overhead Press',
        'day': 'Wednesday'
      },
      {
        'title': 'Full Body Day',
        'focus': 'Squats, Bench Press, Rows, Deadlifts, Overhead Press',
        'day': 'Friday'
      },
    ];

    return Scaffold(
      backgroundColor: ColorManager.darkGrey,
      appBar: AppBar(
        title: const Text(
          'Full Body Split Workout',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: ColorManager.darkGrey,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: splits.length,
                itemBuilder: (context, index) {
                  final split = splits[index];
                  return Card(
                    color: ColorManager.surface,
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      title: Text(
                        '${split['day']} - ${split['title']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        'Focus: ${split['focus']}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => _showExerciseDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor:  ColorManager.limerGreen2,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("View Exercises",
                  style: TextStyle(color: Colors.black, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
