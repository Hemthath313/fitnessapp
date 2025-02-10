import 'dart:developer'; // For logging
import 'package:fitness_app/services/rapid_api_services.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

class ChestExercisesPage extends StatefulWidget {
  const ChestExercisesPage({super.key});

  @override
  _ChestExercisesPageState createState() => _ChestExercisesPageState();
}

class _ChestExercisesPageState extends State<ChestExercisesPage> {
  final RapidApiService _apiService = RapidApiService();
  List<dynamic> exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchExercises();
  }

  Future<void> fetchExercises() async {
    try {
      log('Fetching chest exercises from API...'); // Log before network call
      final data = await _apiService.getTargetWorkoutData('pectorals', {});
      log('API response: $data'); // Log API response
      setState(() {
        exercises = data;
        isLoading = false;
      });
    } catch (e) {
      log('Error fetching exercises: $e'); // Log error
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching exercises: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.black,
      appBar: AppBar(
        title: Text('Chest Exercises'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : exercises.isEmpty
              ? Center(child: Text('No exercises found.'))
              : ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: Image.network(
                          exercise['gifUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(exercise['name']),
                        subtitle: Text(exercise['equipment']),
                        onTap: () => showExerciseDetails(context, exercise),
                      ),
                    );
                  },
                ),
    );
  }

  void showExerciseDetails(BuildContext context, dynamic exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exercise['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target: ${exercise['target']}'),
            SizedBox(height: 10),
            Text('Equipment: ${exercise['equipment']}'),
            SizedBox(height: 10),
            Text('Instructions:'),
            for (String step in exercise['instructions'])
              Text('- $step', style: TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
