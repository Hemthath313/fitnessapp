import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/services/review_service.dart';
import 'package:fitness_app/presentation/widgets/rating_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WorkoutProvider with ChangeNotifier {
  final List<WorkoutModel> _workouts = [];
  final List<WorkoutModel> _finishedWorkouts = [];
  final List<WorkoutModel> _allWorkouts = [];
  double? progressPercent;
  int? exercisesLeft;
  double? shownPercent;

  List<WorkoutModel> get workouts {
    return [..._workouts];
  }

  List<WorkoutModel> get finishedWourkouts {
    return [..._finishedWorkouts];
  }

  List<WorkoutModel> get allWorkouts {
    return [..._allWorkouts];
  }

  bool isDayWorkoutCompletedToday(String dayName) {
    final now = DateTime.now();
    return _finishedWorkouts.any((w) {
      final isSameDay = w.dateTime.year == now.year &&
          w.dateTime.month == now.month &&
          w.dateTime.day == now.day;
      if (!isSameDay) return false;
      return w.name == dayName ||
          w.name == 'custom_$dayName' ||
          w.name.contains(dayName);
    });
  }

  void markWorkoutDayCompleted(String dayName) {
    final now = DateTime.now();
    // Avoid duplicate additions in the same session
    if (!isDayWorkoutCompletedToday(dayName)) {
      _finishedWorkouts.add(WorkoutModel(
        id: 'custom_${dayName}_${now.millisecondsSinceEpoch}',
        name: dayName,
        repNumber: 0,
        setNumber: 1,
        dateTime: now,
      ));
    }
    notifyListeners();
  }

  void clearAllWorkouts() {
    _workouts.clear();
    _allWorkouts.clear();
    _finishedWorkouts.clear();
    progressPercent = null;
    exercisesLeft = null;
    shownPercent = null;
    notifyListeners();
  }

  Future<void> getProgressPercent() async {
    final int allWorkoutsNum = _allWorkouts.length;
    final int finishedWorkoutsNum = _finishedWorkouts.length;
    progressPercent = finishedWorkoutsNum / allWorkoutsNum;
    shownPercent = progressPercent! * 100;
    exercisesLeft = allWorkoutsNum - finishedWorkoutsNum;
  }

  Future<void> addNewWorkout({
    required String name,
    required int repNumber,
    required int setNumber,
    required DateTime dateTime,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final workoutDoc = FirebaseFirestore.instance
          .collection('workouts')
          .doc(user.uid)
          .collection('workoutData')
          .doc();
      
      final allWorkoutDoc = FirebaseFirestore.instance
          .collection('allWorkouts')
          .doc(user.uid)
          .collection('allWorkoutsData')
          .doc();

      final workoutModel = WorkoutModel(
        id: workoutDoc.id,
        name: name,
        repNumber: repNumber,
        setNumber: setNumber,
        dateTime: dateTime,
      );

       final allWorkoutModel = WorkoutModel(
        id: allWorkoutDoc.id,
        name: name,
        repNumber: repNumber,
        setNumber: setNumber,
        dateTime: dateTime,
      );

      await workoutDoc.set({
        'name': name,
        'repNumber': repNumber,
        'setNumber': setNumber,
        'dateTime': dateTime,
      });

      await allWorkoutDoc.set({
        'name': name,
        'repNumber': repNumber,
        'setNumber': setNumber,
        'dateTime': dateTime,
      });

      // Update local state immediately
      _workouts.add(workoutModel);
      _allWorkouts.add(allWorkoutModel);
      
      // Sort to keep order correct
      _workouts.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      // _allWorkouts might need sorting too depending on usage, but usually it is grouped by day or listed
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addNewWorkouts(List<WorkoutModel> newWorkouts) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final batch = FirebaseFirestore.instance.batch();
      final List<WorkoutModel> workoutsToAdd = [];
      final List<WorkoutModel> allWorkoutsToAdd = [];

      for (var workout in newWorkouts) {
        final workoutDoc = FirebaseFirestore.instance
            .collection('workouts')
            .doc(user.uid)
            .collection('workoutData')
            .doc();
        
        final allWorkoutDoc = FirebaseFirestore.instance
            .collection('allWorkouts')
            .doc(user.uid)
            .collection('allWorkoutsData')
            .doc();

        final workoutModel = WorkoutModel(
          id: workoutDoc.id,
          name: workout.name,
          repNumber: workout.repNumber,
          setNumber: workout.setNumber,
          dateTime: workout.dateTime,
        );

        final allWorkoutModel = WorkoutModel(
          id: allWorkoutDoc.id,
          name: workout.name,
          repNumber: workout.repNumber,
          setNumber: workout.setNumber,
          dateTime: workout.dateTime,
        );

        batch.set(workoutDoc, {
          'name': workout.name,
          'repNumber': workout.repNumber,
          'setNumber': workout.setNumber,
          'dateTime': workout.dateTime,
        });

        batch.set(allWorkoutDoc, {
          'name': workout.name,
          'repNumber': workout.repNumber,
          'setNumber': workout.setNumber,
          'dateTime': workout.dateTime,
        });

        workoutsToAdd.add(workoutModel);
        allWorkoutsToAdd.add(allWorkoutModel);
      }

      await batch.commit();

      // Update local state immediately
      _workouts.addAll(workoutsToAdd);
      _allWorkouts.addAll(allWorkoutsToAdd);
      
      // Sort to keep order correct
      _workouts.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }


  Future fetchAndSetWorkouts() async {
    User? user = FirebaseAuth.instance.currentUser;

    // Check if user is authenticated
    if (user == null) {
      // Clear all workouts if user is not authenticated
      _workouts.clear();
      _allWorkouts.clear();
      _finishedWorkouts.clear();
      notifyListeners();
      return;
    }

    try {
      final workoutSnapshot = await FirebaseFirestore.instance
          .collection('workouts')
          .doc(user.uid)
          .collection('workoutData')
          .get();
      final allWorkoutSnapshot = await FirebaseFirestore.instance
          .collection('allWorkouts')
          .doc(user.uid)
          .collection('allWorkoutsData')
          .get();
      final finishedworkoutSnapshot = await FirebaseFirestore.instance
          .collection('finishedWorkouts')
          .doc(user.uid)
          .collection('finishedWorkoutsData')
          .get();

      final List<WorkoutModel> loadedWorkouts = [];
      final List<WorkoutModel> allworkoutsLoaded = [];
      final List<WorkoutModel> loadedFinishedWorkouts = [];

      for (var doc in workoutSnapshot.docs) {
        final workoutData = doc.data();
        loadedWorkouts.add(
          WorkoutModel(
            id: doc.id,
            name: workoutData['name'],
            repNumber: workoutData['repNumber'],
            setNumber: workoutData['setNumber'],
            dateTime: (workoutData['dateTime'] as Timestamp).toDate(),
          ),
        );
      }
      for (var doc in allWorkoutSnapshot.docs) {
        final allWorkoutData = doc.data();
        allworkoutsLoaded.add(
          WorkoutModel(
            id: doc.id,
            name: allWorkoutData['name'],
            repNumber: allWorkoutData['repNumber'],
            setNumber: allWorkoutData['setNumber'],
            dateTime: (allWorkoutData['dateTime'] as Timestamp).toDate(),
          ),
        );
      }

      for (var doc in finishedworkoutSnapshot.docs) {
        final finishedWorkoutsData = doc.data();
        loadedFinishedWorkouts.add(
          WorkoutModel(
            id: doc.id,
            name: finishedWorkoutsData['name'],
            repNumber: finishedWorkoutsData['repNumber'],
            setNumber: finishedWorkoutsData['setNumber'],
            dateTime: (finishedWorkoutsData['dateTime'] as Timestamp).toDate(),
          ),
        );
      }
      loadedWorkouts.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      _workouts.clear();
      _workouts.addAll(loadedWorkouts);
      _allWorkouts.clear();
      _allWorkouts.addAll(allworkoutsLoaded);
      _finishedWorkouts.clear();
      _finishedWorkouts.addAll(loadedFinishedWorkouts);

      notifyListeners();
    } catch (e) {
      // Handle permission denied or other errors gracefully
      print('Error fetching workouts: $e');
      
      // If it's a permission error, clear the data
      if (e.toString().contains('PERMISSION_DENIED') || 
          e.toString().contains('permission-denied')) {
        _workouts.clear();
        _allWorkouts.clear();
        _finishedWorkouts.clear();
        notifyListeners();
      } else {
        rethrow;
      }
    }
  }

  Future<void> clearWorkoutsIfDayChanges(DateTime lastDateTime) async {
    DateTime now = DateTime.now();

    if (isLastDateTimeDifferent(now, lastDateTime)) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // Clean ONLY ad-hoc, ephemeral one-off workouts from the daily queue.
        // DO NOT delete AI weekly plan workouts [Monday], [Wednesday], etc.!
        await FirebaseFirestore.instance
            .collection('workouts')
            .doc(user.uid)
            .collection('workoutData')
            .get()
            .then((workoutSnapshot) {
          for (var doc in workoutSnapshot.docs) {
            final name = doc.data()['name'] as String? ?? '';
            // Protect recurring AI weekly plan items
            if (name.startsWith('[')) continue;
            DateTime workoutDateTime = (doc['dateTime'] as Timestamp).toDate();
            if (isWorkoutDateDifferent(now, workoutDateTime)) {
              doc.reference.delete();
            }
          }
        });

        // NOTE: finishedWorkouts MUST NEVER be deleted! It is the user's permanent completed workout history and streak source!
        // NOTE: allWorkouts MUST NEVER be deleted! It holds the user's weekly split routines and workout templates!
      } catch (e) {
        rethrow;
      }
    }
  }

  bool isLastDateTimeDifferent(DateTime now, DateTime lastDateTime) {
    return now.year != lastDateTime.year ||
        now.month != lastDateTime.month ||
        now.day != lastDateTime.day;
  }

  bool isWorkoutDateDifferent(DateTime now, DateTime workoutDateTime) {
    return now.year != workoutDateTime.year ||
        now.month != workoutDateTime.month ||
        now.day != workoutDateTime.day;
  }

  Future<void> deleteWorkout({required String workoutID}) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('workouts')
          .doc(user!.uid)
          .collection('workoutData')
          .doc(workoutID)
          .delete();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAllWorkout({required String allWorkoutID}) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('allWorkouts')
          .doc(user!.uid)
          .collection('allWorkoutsData')
          .doc(allWorkoutID)
          .delete();

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteWeeklyPlan() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final batch = FirebaseFirestore.instance.batch();

      // Fetch from workouts subcollection
      final workoutsSnapshot = await FirebaseFirestore.instance
          .collection('workouts')
          .doc(user.uid)
          .collection('workoutData')
          .get();

      for (var doc in workoutsSnapshot.docs) {
        final name = doc.data()['name'] as String? ?? '';
        if (name.startsWith('[')) {
          batch.delete(doc.reference);
        }
      }

      // Fetch from allWorkouts subcollection
      final allWorkoutsSnapshot = await FirebaseFirestore.instance
          .collection('allWorkouts')
          .doc(user.uid)
          .collection('allWorkoutsData')
          .get();

      for (var doc in allWorkoutsSnapshot.docs) {
        final name = doc.data()['name'] as String? ?? '';
        if (name.startsWith('[')) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();

      // Clean local memory lists immediately
      _workouts.removeWhere((w) => w.name.startsWith('['));
      _allWorkouts.removeWhere((w) => w.name.startsWith('['));
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Restores or ensures a complete 3-Day Split (Monday, Wednesday, Friday)
  /// Used if past bugs wiped Monday or Friday, giving the user a complete routine.
  Future<void> restoreDefaultThreeDaySplit() async {
    final now = DateTime.now();
    final List<WorkoutModel> workoutsToAdd = [];

    final existingDays = <String>{};
    for (var w in _allWorkouts) {
      final match = RegExp(r'^\[(\w+)\]').firstMatch(w.name);
      if (match != null) {
        existingDays.add(match.group(1)!);
      }
    }

    // Default Monday Plan (Full Body A)
    if (!existingDays.contains('Monday')) {
      workoutsToAdd.addAll([
        WorkoutModel(id: '', name: '[Monday] Barbell Bench Press', repNumber: 10, setNumber: 4, dateTime: now),
        WorkoutModel(id: '', name: '[Monday] Barbell Bent Over Row', repNumber: 10, setNumber: 4, dateTime: now),
        WorkoutModel(id: '', name: '[Monday] Classic Barbell Squat', repNumber: 10, setNumber: 4, dateTime: now),
        WorkoutModel(id: '', name: '[Monday] Standing Military Press', repNumber: 10, setNumber: 3, dateTime: now),
        WorkoutModel(id: '', name: '[Monday] Barbell Curl', repNumber: 12, setNumber: 3, dateTime: now),
      ]);
    }

    // Default Wednesday Plan (Full Body B)
    if (!existingDays.contains('Wednesday')) {
      workoutsToAdd.addAll([
        WorkoutModel(id: '', name: '[Wednesday] Incline Dumbbell Press', repNumber: 10, setNumber: 4, dateTime: now),
        WorkoutModel(id: '', name: '[Wednesday] Lat Pulldown', repNumber: 10, setNumber: 4, dateTime: now),
        WorkoutModel(id: '', name: '[Wednesday] Leg Press', repNumber: 12, setNumber: 4, dateTime: now),
        WorkoutModel(id: '', name: '[Wednesday] Dumbbell Lateral Raise', repNumber: 15, setNumber: 3, dateTime: now),
        WorkoutModel(id: '', name: '[Wednesday] Tricep Pushdown', repNumber: 12, setNumber: 3, dateTime: now),
      ]);
    }

    // Default Friday Plan (Full Body C)
    if (!existingDays.contains('Friday')) {
      workoutsToAdd.addAll([
        WorkoutModel(id: '', name: '[Friday] Chest Dips', repNumber: 12, setNumber: 3, dateTime: now),
        WorkoutModel(id: '', name: '[Friday] Seated Cable Row', repNumber: 10, setNumber: 4, dateTime: now),
        WorkoutModel(id: '', name: '[Friday] Barbell Lunge', repNumber: 10, setNumber: 3, dateTime: now),
        WorkoutModel(id: '', name: '[Friday] Arnold Press', repNumber: 10, setNumber: 3, dateTime: now),
        WorkoutModel(id: '', name: '[Friday] Dumbbell Curl', repNumber: 12, setNumber: 3, dateTime: now),
      ]);
    }

    if (workoutsToAdd.isNotEmpty) {
      await addNewWorkouts(workoutsToAdd);
      await fetchAndSetWorkouts();
    }
  }

  Future<void> deleteWorkoutByNameAndAllWorkoutId({
    required String name,
    required String allWorkoutId,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final batch = FirebaseFirestore.instance.batch();

      // Delete from allWorkouts
      final allWorkoutRef = FirebaseFirestore.instance
          .collection('allWorkouts')
          .doc(user.uid)
          .collection('allWorkoutsData')
          .doc(allWorkoutId);
      batch.delete(allWorkoutRef);

      // Query workouts collection to find matching document by name
      final workoutsSnapshot = await FirebaseFirestore.instance
          .collection('workouts')
          .doc(user.uid)
          .collection('workoutData')
          .where('name', isEqualTo: name)
          .get();

      for (var doc in workoutsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }


  Future<void> finishWorkout({
    required String workoutID,
    required String name,
    required int repNumber,
    required int setNumber,
    required DateTime dateTime,
    BuildContext? context,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('finishedWorkouts')
          .doc(user!.uid)
          .collection('finishedWorkoutsData')
          .doc()
          .set({
        'name': name,
        'repNumber': repNumber,
        'setNumber': setNumber,
        'dateTime': dateTime,
        'id': workoutID,
      });

      // Increment review counter
      try {
        final bool isEligible = await ReviewService().incrementWorkoutsLogged();
        if (isEligible && context != null && context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => const RatingPromptDialog(),
          );
        }
      } catch (e) {
        print('Error incrementing workouts count for review: $e');
      }

      // Update streak and statistics
      // This needs to be called from the widget that has access to context

      notifyListeners();
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  static Future<void> updateStatisticsAfterWorkout(BuildContext context) async {
    try {
      final statisticsProvider =
          Provider.of<StatisticsProvider>(context, listen: false);
      await statisticsProvider.updateStreak();

      // Check for new achievements and show notification
      final newAchievements = statisticsProvider.unlockedAchievements;

      if (newAchievements.isNotEmpty) {
        // Show achievement notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('🎉 New Achievement Unlocked: ${newAchievements.last}!'),
            backgroundColor: Colors.amber,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error updating statistics: $e');
    }
  }
}
