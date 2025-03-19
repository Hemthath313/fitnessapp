import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/services/rapid_api_services.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
    fetchProgress();
  }

  Future<void> fetchProgress() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    final progressData = snapshot.data()?['progress'] ?? {};
    final sixPackProgress = progressData['sixPackChallenge'] ?? {};

    final lastCompletedDay = sixPackProgress['lastCompletedDay'] ?? 0;
    final completionDateStr = sixPackProgress['completionDate'] ?? '';

    final completionDate =
        DateTime.tryParse(completionDateStr)?.toLocal() ?? DateTime.now();
    final today = DateTime.now();

    // Unlock next day only if a new day has started AND the previous day was completed
    final isNewDay = today.difference(completionDate).inDays >= 1;

    setState(() {
      completedDays = isNewDay ? lastCompletedDay + 1 : lastCompletedDay;
    });
  }

  void fetchExercises() async {
    try {
      if (!(await Connectivity().checkConnectivity())
          .contains(ConnectivityResult.none)) {
        final data = await _apiService.getTargetWorkoutData('abs', {});
        setState(() {
          groupedExercises = List.generate(
              30, (index) => data.skip(index * 3).take(3).toList());
          isLoading = false;
        });
      } else {
        Fluttertoast.showToast(
          msg: "No internet connection. Please try again.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // void completeDay(int day) async {
  //   print('Completing day $day...');
  //   final userId = FirebaseAuth.instance.currentUser!.uid;

  //   await FirebaseFirestore.instance.collection('users').doc(userId).update({
  //     'progress.sixPackChallenge.lastCompletedDay': day,
  //     'progress.sixPackChallenge.completionDate':
  //         DateTime.now().toIso8601String(),
  //   });

  //   fetchProgress();

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text('Day $day complete! Well done!')),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.darkGrey,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
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
                final isUnlocked = day <= completedDays;
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
                        ? () async {
                            await context.push(
                              '${Routes.dailyExerciseRoute}?day=$day',
                              extra: groupedExercises[index],
                            );

                            // Refresh progress when returning
                            fetchProgress();
                          }
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
