import 'dart:developer';
import 'package:fitness_app/presentation/challenges/daily_challenge.dart';
import 'package:fitness_app/services/rapid_api_services.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/managers/color_manager.dart';

class AbsExercisesPage extends StatefulWidget {
  const AbsExercisesPage({super.key});

  @override
  _AbsExercisesPageState createState() => _AbsExercisesPageState();
}

class _AbsExercisesPageState extends State<AbsExercisesPage> {
  final RapidApiService _apiService = RapidApiService();
  List<List<dynamic>> groupedExercises = [];
  bool isLoading = true;
  int completedDays = 0;

  @override
  void initState() {
    super.initState();
    fetchExercises();
  }

  Future<void> fetchExercises() async {
    try {
      log('Fetching 30-day six-pack challenge exercises from API...');
      final data = await _apiService.getTargetWorkoutData('abs', {});
      log('API response: $data');

      setState(() {
        groupedExercises = List.generate(
            30,
            (index) =>
                data.skip(index * 3).take(3).toList()); // 3 exercises per day
        isLoading = false;
      });
    } catch (e) {
      log('Error fetching exercises: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching exercises: $e')),
      );
    }
  }

  void completeDay(int day) {
    setState(() => completedDays = day);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Day $day complete! Well done!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.darkGrey,
      appBar: AppBar(
        backgroundColor: ColorManager.darkGrey,
        title: Text('30-Day Six-Pack Challenge',
            style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: groupedExercises.length,
              itemBuilder: (context, index) {
                final day = index + 1;
                final isUnlocked = day <= completedDays + 1;

                return Card(
                  color: isUnlocked ? ColorManager.black54 : Colors.grey[800],
                  margin: EdgeInsets.all(12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    title: Text(
                        'Day $day: ${groupedExercises[index].length} Exercises',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.white : Colors.white38)),
                    enabled: isUnlocked,
                    onTap: isUnlocked
                        ? () => context.push(
                              '${Routes.dailyExerciseRoute}?day=$day',
                              extra: groupedExercises[index],
                            )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}

// New Page to Show 3-4 Exercises for Each Day
