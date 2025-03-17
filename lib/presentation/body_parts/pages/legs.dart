import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fitness_app/services/rapid_api_services.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../utils/managers/color_manager.dart';

class LegExercisesPage extends StatefulWidget {
  const LegExercisesPage({super.key});

  @override
  _LegExercisesPageState createState() => _LegExercisesPageState();
}

class _LegExercisesPageState extends State<LegExercisesPage> {
  final RapidApiService _apiService = RapidApiService();
  List<dynamic> exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchExercises();
  }

  Future<void> fetchExercises() async {
    setState(() => isLoading = true);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        log('No internet connection.');
        Fluttertoast.showToast(
          msg: "Please check your internet connection",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() => isLoading = false);
        return;
      }

      log('Fetching leg exercises from API...');
      final data = await _apiService.getBodyPartsWorkoutData('upper legs', {});
      log('API response: $data');

      setState(() {
        exercises = data;
        isLoading = false;
      });
    } catch (e) {
      log('Error fetching exercises: $e');
      setState(() => isLoading = false);

      Fluttertoast.showToast(
        msg: "No internet connection. Please try again.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.darkGrey,
      appBar: AppBar(
        backgroundColor: ColorManager.darkGrey,
        title: Text(
          'Leg Exercises',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : exercises.isEmpty
              ? Center(
                  child: Text('No exercises found.',
                      style: TextStyle(color: Colors.white)))
              : ListView.builder(
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
                          exercise['name'],
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          'Equipment: ${exercise['equipment']}',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        onTap: () => showExerciseDetails(context, exercise),
                      ),
                    );
                  },
                ),
    );
  }

  void showExerciseDetails(BuildContext context, dynamic exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                  color: Colors.black87),
            ),
            SizedBox(height: 10),
            Text('Target: ${exercise['target']}',
                style: TextStyle(fontSize: 16, color: Colors.black87)),
            SizedBox(height: 5),
            Text('Equipment: ${exercise['equipment']}',
                style: TextStyle(fontSize: 16, color: Colors.black87)),
            SizedBox(height: 10),
            Text(
              'Instructions:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            for (String step in exercise['instructions'])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('- $step',
                    style: TextStyle(fontSize: 14, color: Colors.black87)),
              ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
