import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:fitness_app/model/workout_split.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart'; // For vibration

class WorkoutSplitListPage extends StatelessWidget {
  final List<WorkoutSplit> workoutSplits;

  const WorkoutSplitListPage({super.key, required this.workoutSplits});

  void _navigateToPage(BuildContext context, int index) {
    HapticFeedback.lightImpact(); // Vibration feedback
    switch (index) {
      case 0:
        context.push(Routes.broSplit);
        break;
      case 1:
        context.push(Routes.pushPullLegsSplit);
        break;
      case 2:
        context.push(Routes.fullBodySplit);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Page not available')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Workout Splits',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: ColorManager.darkGrey,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              '"Push yourself because no one else is going to do it for you."',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: workoutSplits.length,
              itemBuilder: (context, index) {
                final split = workoutSplits[index];
                return Card(
                  elevation: 6,
                  margin: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black87, Colors.black54],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        // child: Image.asset(
                        //   split.imagePath,
                        //   width: 50,
                        //   height: 50,
                        //   fit: BoxFit.cover,
                        // ),
                      ),
                      title: Text(
                        split.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        split.description,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // CircularProgressIndicator(
                          //   value: split.progress / 100,
                          //   backgroundColor: Colors.grey,
                          //   color: Colors.greenAccent,
                          // ),
                          const SizedBox(height: 5),
                          Text(
                            '${split.recommendedDays} days/week',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      onTap: () => _navigateToPage(context, index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: ColorManager.darkGrey,
    );
  }
}
