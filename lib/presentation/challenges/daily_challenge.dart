import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

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
              exercise['name'],
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.white),
            ),
            SizedBox(height: 10),
            Text('Target: ${exercise['target']}',
                style: TextStyle(fontSize: 16, color: ColorManager.white)),
            SizedBox(height: 5),
            Text('Equipment: ${exercise['equipment']}',
                style: TextStyle(fontSize: 16, color: ColorManager.white)),
            SizedBox(height: 10),
            Text(
              'Instructions:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.white),
            ),
            for (String step in exercise['instructions'])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('- $step',
                    style: TextStyle(fontSize: 14, color: ColorManager.white)),
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
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return Card(
            color: ColorManager.black54,
            margin: EdgeInsets.all(12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 4,
            child: ListTile(
              onTap: () => showExerciseDetails(context, exercise),
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
              title: Text('${exercise['name']}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text('Equipment: ${exercise['equipment']}',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.limerGreen2),
          onPressed: () {
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
