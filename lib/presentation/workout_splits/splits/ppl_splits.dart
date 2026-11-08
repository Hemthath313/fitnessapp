import 'package:flutter/material.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PPLPage extends StatelessWidget {
  const PPLPage({super.key});

  void _showExerciseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ColorManager.background,
          title: Text(
            "View Exercises?",
            style: TextStyle(color: ColorManager.textPrimary),
          ),
          content: Text(
            "Do you want to see the detailed exercises for this split?",
            style: TextStyle(color: ColorManager.textSecondary),
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
        'title': 'Push Day',
        'focus': 'Chest, Shoulders, Triceps',
        'day': 'Monday'
      },
      {'title': 'Pull Day', 'focus': 'Back, Biceps', 'day': 'Tuesday'},
      {
        'title': 'Leg Day',
        'focus': 'Quads, Hamstrings, Glutes, Abs',
        'day': 'Wednesday'
      },
      {
        'title': 'Push Day',
        'focus': 'Chest, Shoulders, Triceps',
        'day': 'Thursday'
      },
      {'title': 'Pull Day', 'focus': 'Back, Biceps', 'day': 'Friday'},
      {
        'title': 'Leg Day',
        'focus': 'Quads, Hamstrings, Glutes, Abs',
        'day': 'Saturday'
      },
      {
        'title': 'Rest/Recovery',
        'focus': 'Recovery & Mobility',
        'day': 'Sunday'
      },
    ];

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'PPL Workout',
          style: TextStyle(color: ColorManager.textPrimary),
        ),
        backgroundColor: ColorManager.background,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
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
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                      subtitle: Text(
                        'Focus: ${split['focus']}',
                        style: TextStyle(color: ColorManager.textSecondary),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => _showExerciseDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor:ColorManager.limerGreen2,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child:  Text("View Exercises",
                  style: TextStyle(color: Colors.black, fontSize: 16.sp)),
            ),
          ],
        ),
      ),
    );
  }
}
