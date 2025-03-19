import 'dart:developer'; // For logging
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart' as ConnectivityResult;
import 'package:fitness_app/services/rapid_api_services.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BicepsExercisesPage extends StatefulWidget {
  const BicepsExercisesPage({super.key});

  @override
  _BicepsExercisesPageState createState() => _BicepsExercisesPageState();
}

class _BicepsExercisesPageState extends State<BicepsExercisesPage> {
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

      log('Fetching biceps exercises from API...');
      final data = await _apiService.getTargetWorkoutData('biceps', {});
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
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: ColorManager.darkGrey,
        title: Text(
          'Biceps Exercises',
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
                          exercise['name']
                              .toString()
                              .split(' ')
                              .map((word) =>
                                  word[0].toUpperCase() + word.substring(1))
                              .join(' '),
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
}
