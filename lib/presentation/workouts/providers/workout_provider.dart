import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/services/review_service.dart';
import 'package:fitness_app/presentation/widgets/rating_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutProvider with ChangeNotifier {
  final List<WorkoutModel> _workouts = [];
  final List<WorkoutModel> _finishedWorkouts = [];
  final List<WorkoutModel> _allWorkouts = [];
  double? progressPercent;
  int? exercisesLeft;
  double? shownPercent;

  DateTime Function() _nowProvider = DateTime.now;

  @visibleForTesting
  Future<void> Function(List<WorkoutModel>)? onAddNewWorkoutsForTesting;

  @visibleForTesting
  Future<void> Function()? onFetchWorkoutsForTesting;

  @visibleForTesting
  Future<List<WorkoutModel>> Function()? remoteWorkoutsFetcherForTesting;

  @visibleForTesting
  String? userIdOverrideForTesting;

  DateTime get currentNow => _nowProvider();

  @visibleForTesting
  void setNowProviderForTesting(DateTime Function()? provider) {
    _nowProvider = provider ?? DateTime.now;
  }

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  String? get currentUserId {
    if (userIdOverrideForTesting != null) {
      return userIdOverrideForTesting;
    }
    return _currentUser?.uid;
  }

  bool get hasActiveSplit =>
      _allWorkouts.any((w) => w.name.startsWith('['));

  static const String _cachedWeeklyPlanPrefix = 'cached_active_weekly_plan_';

  static String getCacheKey(String? uid) {
    if (uid != null && uid.isNotEmpty) {
      return '$_cachedWeeklyPlanPrefix$uid';
    }
    return '${_cachedWeeklyPlanPrefix}default';
  }

  /// Persists the active weekly routine to local SharedPreferences
  Future<void> saveWeeklyPlanToCache(
    List<WorkoutModel> planWorkouts,
    String? uid,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = getCacheKey(uid);
      if (planWorkouts.isEmpty) {
        await prefs.remove(key);
      } else {
        final jsonList = planWorkouts.map((w) => w.toMap()).toList();
        await prefs.setString(key, jsonEncode(jsonList));
      }
    } catch (e) {
      debugPrint('WorkoutProvider: Failed to cache weekly plan: $e');
    }
  }

  /// Restores the active weekly routine from local SharedPreferences into memory
  Future<bool> restoreWeeklyPlanFromCache(String? uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = getCacheKey(uid);
      final cachedJson = prefs.getString(key);
      if (cachedJson != null && cachedJson.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(cachedJson);
        if (decoded is List) {
          final restored = decoded
              .whereType<Map>()
              .map((m) => WorkoutModel.fromMap(Map<String, dynamic>.from(m)))
              .toList();
          if (restored.isNotEmpty) {
            // Remove any existing weekly plan items in _allWorkouts before inserting to prevent duplicates
            _allWorkouts.removeWhere((w) => w.name.startsWith('['));
            _allWorkouts.addAll(restored);
            _workouts.removeWhere((w) => w.name.startsWith('['));
            _workouts.addAll(restored);
            _workouts.sort((a, b) => b.dateTime.compareTo(a.dateTime));
            notifyListeners();
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('WorkoutProvider: Failed to restore weekly plan from cache: $e');
    }
    return false;
  }

  /// Explicitly clears the local cache for a user
  Future<void> clearLocalRoutineCache(String? uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = getCacheKey(uid);
      await prefs.remove(key);
    } catch (e) {
      debugPrint('WorkoutProvider: Failed to clear weekly plan cache: $e');
    }
  }

  List<WorkoutModel> get workouts {
    return [..._workouts];
  }

  List<WorkoutModel> get finishedWourkouts {
    return [..._finishedWorkouts];
  }

  List<WorkoutModel> get allWorkouts {
    return [..._allWorkouts];
  }

  /// Total number of scheduled workout days in active split
  int get splitDaysCount {
    final planWorkouts = _allWorkouts.where((w) => w.name.startsWith('['));
    final Set<String> days = {};
    for (var w in planWorkouts) {
      final match = RegExp(r'^\[(\w+)\]').firstMatch(w.name);
      if (match != null) {
        days.add(match.group(1)!);
      }
    }
    return days.length;
  }

  /// Map of DayName -> List of WorkoutModel for the active split
  Map<String, List<WorkoutModel>> get groupedSplitWorkouts {
    final planWorkouts = _allWorkouts.where((w) => w.name.startsWith('['));
    final Map<String, List<WorkoutModel>> grouped = {};
    for (var w in planWorkouts) {
      final match = RegExp(r'^\[(\w+)\]').firstMatch(w.name);
      if (match != null) {
        grouped.putIfAbsent(match.group(1)!, () => []).add(w);
      }
    }
    return grouped;
  }

  /// Strictly matches whether a finished workout record represents completion of [dayName]'s scheduled routine.
  /// Avoids loose substring matching so unrelated ad-hoc workouts (e.g. 'Friday Core Workout') never collide.
  static bool matchesScheduledDayWorkoutName(
    String rawWorkoutName,
    String dayName,
  ) {
    final target = dayName.trim().toLowerCase();
    if (target.isEmpty) return false;
    final wName = rawWorkoutName.trim().toLowerCase();
    return wName == target ||
        wName == '$target routine' ||
        wName == 'custom_$target' ||
        wName.startsWith('[$target]');
  }

  bool isDayWorkoutCompletedToday(String dayName, {DateTime? now}) {
    final current = now ?? _nowProvider();
    return _finishedWorkouts.any((w) {
      final isSameDay = w.dateTime.year == current.year &&
          w.dateTime.month == current.month &&
          w.dateTime.day == current.day;
      if (!isSameDay) return false;
      return matchesScheduledDayWorkoutName(w.name, dayName);
    });
  }

  /// Checks if a scheduled day workout has been completed during the current calendar week
  bool isDayWorkoutCompletedThisWeek(String dayName, {DateTime? now}) {
    final current = now ?? _nowProvider();
    final monday = current.subtract(Duration(days: current.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return _finishedWorkouts.any((w) {
      final isThisWeek =
          !w.dateTime.isBefore(startOfWeek) && w.dateTime.isBefore(endOfWeek);
      if (!isThisWeek) return false;
      return matchesScheduledDayWorkoutName(w.name, dayName);
    });
  }

  void markWorkoutDayCompleted(String dayName, {DateTime? completedAt}) {
    final now = completedAt ?? _nowProvider();
    // Avoid duplicate additions in the same session
    if (!isDayWorkoutCompletedToday(dayName, now: now)) {
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

  @visibleForTesting
  void setAllWorkoutsForTesting(List<WorkoutModel> workouts) {
    _allWorkouts
      ..clear()
      ..addAll(workouts);
    notifyListeners();
  }

  @visibleForTesting
  void setFinishedWorkoutsForTesting(List<WorkoutModel> workouts) {
    _finishedWorkouts
      ..clear()
      ..addAll(workouts);
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
      final user = _currentUser;
      if (user == null) {
        final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
        final model = WorkoutModel(
          id: localId,
          name: name,
          repNumber: repNumber,
          setNumber: setNumber,
          dateTime: dateTime,
        );
        _workouts.add(model);
        _allWorkouts.add(model);
        _workouts.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        if (name.startsWith('[')) {
          final planWorkouts =
              _allWorkouts.where((w) => w.name.startsWith('[')).toList();
          await saveWeeklyPlanToCache(planWorkouts, currentUserId);
        }
        notifyListeners();
        return;
      }

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
      
      if (name.startsWith('[')) {
        final planWorkouts =
            _allWorkouts.where((w) => w.name.startsWith('[')).toList();
        await saveWeeklyPlanToCache(planWorkouts, currentUserId);
      }
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addNewWorkouts(List<WorkoutModel> newWorkouts) async {
    try {
      if (onAddNewWorkoutsForTesting != null) {
        await onAddNewWorkoutsForTesting!(newWorkouts);
      }

      final user = _currentUser;
      if (user == null) {
        final nowMicros = DateTime.now().microsecondsSinceEpoch;
        for (int i = 0; i < newWorkouts.length; i++) {
          final w = newWorkouts[i];
          final model = WorkoutModel(
            id: w.id.isNotEmpty ? w.id : 'local_${nowMicros}_$i',
            name: w.name,
            repNumber: w.repNumber,
            setNumber: w.setNumber,
            dateTime: w.dateTime,
          );
          _workouts.add(model);
          _allWorkouts.add(model);
        }
        _workouts.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        final planWorkouts =
            _allWorkouts.where((w) => w.name.startsWith('[')).toList();
        if (planWorkouts.isNotEmpty) {
          await saveWeeklyPlanToCache(planWorkouts, currentUserId);
        }
        notifyListeners();
        return;
      }

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
      
      final planWorkouts =
          _allWorkouts.where((w) => w.name.startsWith('[')).toList();
      if (planWorkouts.isNotEmpty) {
        await saveWeeklyPlanToCache(planWorkouts, currentUserId);
      }
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }


  Future fetchAndSetWorkouts() async {
    final uid = currentUserId;

    // Fast-path / startup restore: If memory has no active split, load from local cache first.
    if (!hasActiveSplit) {
      await restoreWeeklyPlanFromCache(uid);
    }

    if (onFetchWorkoutsForTesting != null) {
      try {
        await onFetchWorkoutsForTesting!();
      } catch (e) {
        if (!hasActiveSplit) {
          await restoreWeeklyPlanFromCache(uid);
        }
        return;
      }
      return;
    }

    if (remoteWorkoutsFetcherForTesting != null) {
      try {
        final remote = await remoteWorkoutsFetcherForTesting!();
        final planWorkouts =
            remote.where((w) => w.name.startsWith('[')).toList();
        _workouts
          ..removeWhere((w) => w.name.startsWith('['))
          ..addAll(planWorkouts)
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
        _allWorkouts
          ..removeWhere((w) => w.name.startsWith('['))
          ..addAll(planWorkouts);

        if (planWorkouts.isNotEmpty) {
          await saveWeeklyPlanToCache(planWorkouts, uid);
        } else {
          // Genuinely successful empty split from remote -> clear cache
          await clearLocalRoutineCache(uid);
        }
        notifyListeners();
      } catch (e) {
        // Transient network error: keep cache intact, ensure restored into memory
        if (!hasActiveSplit) {
          await restoreWeeklyPlanFromCache(uid);
        }
      }
      return;
    }

    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      // Firebase is not initialized (e.g. unit/widget test environment).
      // Preserve in-memory workouts configured for testing or restored from cache.
      notifyListeners();
      return;
    }

    // Check if user is authenticated
    if (user == null) {
      // Clear all workouts if user is not authenticated
      _workouts.clear();
      _allWorkouts.clear();
      _finishedWorkouts.clear();
      await clearLocalRoutineCache(null);
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

      final remotePlanWorkouts =
          allworkoutsLoaded.where((w) => w.name.startsWith('[')).toList();
      if (remotePlanWorkouts.isNotEmpty) {
        await saveWeeklyPlanToCache(remotePlanWorkouts, user.uid);
      } else {
        // Authoritative empty: user has no weekly routine in Firestore
        await clearLocalRoutineCache(user.uid);
      }

      notifyListeners();
    } catch (e) {
      // Handle permission denied or other errors gracefully
      debugPrint('Error fetching workouts: $e');

      // If it's a permission error, clear the data and cache
      if (e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('permission-denied')) {
        _workouts.clear();
        _allWorkouts.clear();
        _finishedWorkouts.clear();
        await clearLocalRoutineCache(user.uid);
        notifyListeners();
      } else {
        // Offline / network failure: restore cached routine so home/workout pages continue working
        if (!hasActiveSplit) {
          await restoreWeeklyPlanFromCache(user.uid);
        }
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

  Future<void> _clearRoutineCompletionFlagsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = prefs
          .getKeys()
          .where((k) =>
              k.startsWith('completed_routine_') ||
              k.startsWith('completed_any_routine_'))
          .toList();
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }

  Future<void> deleteWeeklyPlan() async {
    try {
      final user = _currentUser;
      if (user != null) {
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
      }

      // Clean local memory lists immediately
      _workouts.removeWhere((w) => w.name.startsWith('['));
      _allWorkouts.removeWhere((w) => w.name.startsWith('['));
      await _clearRoutineCompletionFlagsFromPrefs();
      await clearLocalRoutineCache(currentUserId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Replaces the active weekly plan atomically/defensively with rollback on failure.
  /// If saving the new plan fails, the previous active routine in memory is restored intact.
  Future<void> replaceWeeklyPlan(List<WorkoutModel> newPlanWorkouts) async {
    final previousWorkouts = List<WorkoutModel>.from(_workouts);
    final previousAllWorkouts = List<WorkoutModel>.from(_allWorkouts);

    try {
      await deleteWeeklyPlan();
      if (newPlanWorkouts.isNotEmpty) {
        await addNewWorkouts(newPlanWorkouts);
      }
      if (_currentUser != null) {
        await fetchAndSetWorkouts();
      }
    } catch (e) {
      _workouts
        ..clear()
        ..addAll(previousWorkouts);
      _allWorkouts
        ..clear()
        ..addAll(previousAllWorkouts);
      final prevPlan =
          _allWorkouts.where((w) => w.name.startsWith('[')).toList();
      if (prevPlan.isNotEmpty) {
        await saveWeeklyPlanToCache(prevPlan, currentUserId);
      }
      notifyListeners();
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
      final user = _currentUser;
      if (user != null) {
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
      }
      _workouts.removeWhere((w) => w.name == name);
      _allWorkouts.removeWhere((w) => w.id == allWorkoutId || w.name == name);
      if (name.startsWith('[')) {
        final remainingPlan =
            _allWorkouts.where((w) => w.name.startsWith('[')).toList();
        if (remainingPlan.isNotEmpty) {
          await saveWeeklyPlanToCache(remainingPlan, currentUserId);
        } else {
          await clearLocalRoutineCache(currentUserId);
        }
      }
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
      _finishedWorkouts.add(
        WorkoutModel(
          id: workoutID,
          name: name,
          repNumber: repNumber,
          setNumber: setNumber,
          dateTime: dateTime,
        ),
      );

      final user = _currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('finishedWorkouts')
            .doc(user.uid)
            .collection('finishedWorkoutsData')
            .doc()
            .set({
          'name': name,
          'repNumber': repNumber,
          'setNumber': setNumber,
          'dateTime': dateTime,
          'id': workoutID,
        });
      }

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
