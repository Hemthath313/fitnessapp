import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/models/transformation_daily_log_model.dart';
import 'package:fitness_app/presentation/transformation_plans/models/transformation_meal_plan_model.dart';
import 'package:fitness_app/presentation/transformation_plans/models/transformation_schedule_override.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_meal_plan_generator.dart';
import 'package:fitness_app/services/notification_service.dart';

/// Provider managing Transformation Plans state, active enrolment,
/// daily progression checkmarks, milestone unlocks, and Firestore persistence.
class TransformationProvider with ChangeNotifier {
  UserTransformationState? _activeTransformation;
  List<UserTransformationState> _history = [];
  bool _isLoading = false;
  String? _error;
  bool _isLifecycleOperationInProgress = false;

  SubscriptionProvider? _subscriptionProvider;

  /// Attaches the trusted SubscriptionProvider instance (e.g. from ProxyProvider)
  void attachSubscriptionProvider(SubscriptionProvider? provider) {
    _subscriptionProvider = provider;
  }

  @visibleForTesting
  bool? entitlementOverrideForTesting;

  @visibleForTesting
  static bool defaultEntitlementForTesting = true;

  Future<bool> _isEntitled(SubscriptionProvider? callerSubProvider) async {
    if (entitlementOverrideForTesting != null) {
      return entitlementOverrideForTesting!;
    }

    final sub = callerSubProvider ?? _subscriptionProvider;
    if (sub != null) {
      return sub.isPremium;
    }

    // In unit testing environments using userIdOverrideForTesting:
    if (userIdOverrideForTesting != null) {
      return defaultEntitlementForTesting;
    }

    final uid = _uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getString(SubscriptionProvider.getCacheKey(uid));
        if (cachedJson != null && cachedJson.trim().isNotEmpty) {
          final dynamic decoded = jsonDecode(cachedJson);
          if (decoded is Map) {
            final map = Map<String, dynamic>.from(decoded);
            final cachedPremium = map['isPremium'] == true;
            final cachedLifetime = map['isLifetime'] == true;
            if (cachedPremium && !cachedLifetime && map['expirationDate'] != null) {
              final exp = DateTime.tryParse(map['expirationDate'].toString());
              if (exp != null && DateTime.now().isAfter(exp)) {
                return false;
              }
            }
            if (cachedPremium) return true;
          }
        }
      } catch (e) {
        debugPrint('TransformationProvider: Error reading cached subscription: $e');
      }
    }

    return false;
  }

  @visibleForTesting
  String? userIdOverrideForTesting;

  @visibleForTesting
  Map<String, dynamic>? Function(String uid)? activeDocFetcherForTesting;

  @visibleForTesting
  List<Map<String, dynamic>>? Function(String uid)? historyDocFetcherForTesting;

  @visibleForTesting
  Future<void> Function(String uid, Map<String, dynamic> data)? activeDocSaverForTesting;

  @visibleForTesting
  Future<void> Function(String uid, Map<String, dynamic> data)? historyDocSaverForTesting;

  @visibleForTesting
  Future<void> Function(
    String uid, {
    Map<String, dynamic>? activeData,
    bool deleteActive,
    Map<String, dynamic>? historyData,
    String? historyDocId,
  })? batchCommitForTesting;

  /// The active plan with [UserTransformationState.currentDay] resolved for
  /// today (self-paced, see [UserTransformationState.resolveProgress]).
  /// The stored value is only a floor, so the plan never moves backwards.
  UserTransformationState? get activeTransformation {
    final state = _activeTransformation;
    if (state == null) return null;
    final day = _resolvedDayFor(state);
    if (day != state.currentDay) {
      _activeTransformation = state.copyWith(currentDay: day);
    }
    return _activeTransformation;
  }

  /// Clock used for day resolution; tests can override it.
  DateTime Function() clockForTesting = DateTime.now;

  bool Function(int) _restDayFn(UserTransformationState state) {
    final blueprint = TransformationPlansData.getById(state.planId);
    return (int d) => blueprint?.getDayBlueprint(d)?.isRestDay ?? false;
  }

  int _resolvedDayFor(UserTransformationState state) {
    final now = clockForTesting();
    final resolved =
        state.resolveProgress(now, isRestDay: _restDayFn(state)).day;
    final floor = state.currentDay.clamp(1, state.totalDays < 1 ? 1 : state.totalDays);
    return resolved > floor ? resolved : floor;
  }

  /// Milestones unlock when the programme reaches their day: the highest
  /// completed day counts, not just how many days were ticked.
  List<TransformationMilestone> _evaluateMilestones(
      List<TransformationMilestone> milestones, List<int> completed) {
    final reached = completed.isEmpty
        ? 0
        : [completed.length, completed.reduce((a, b) => a > b ? a : b)]
            .reduce((a, b) => a > b ? a : b);
    return milestones.map((m) {
      if (!m.isAchieved && reached >= m.triggerDay) {
        return m.copyWith(isAchieved: true, achievedAt: DateTime.now());
      }
      return m;
    }).toList();
  }

  /// Saves rest days the user has already passed as completed (so progress
  /// can reach 100% and milestones fire) and stores the resolved current day.
  Future<void> _syncProgress() async {
    final state = _activeTransformation;
    final uid = _uid;
    if (state == null || uid == null || !state.isActive) return;

    final now = clockForTesting();
    final result = state.resolveProgress(now, isRestDay: _restDayFn(state));
    final indices = List<int>.from(state.completedDayIndices);
    final dates = Map<int, String>.from(state.completedDayDates);
    result.passedRestDays.forEach((d, date) {
      if (!indices.contains(d)) {
        indices.add(d);
        dates[d] = UserTransformationState.dateKey(date);
      }
    });
    indices.sort();
    final floor = state.currentDay.clamp(1, state.totalDays < 1 ? 1 : state.totalDays);
    final day = result.day > floor ? result.day : floor;

    if (indices.length == state.completedDayIndices.length &&
        day == state.currentDay) {
      return;
    }

    final updated = state.copyWith(
      completedDayIndices: indices,
      completedDayDates: dates,
      milestones: _evaluateMilestones(state.milestones, indices),
      currentDay: day,
    );
    _activeTransformation = updated;
    try {
      if (activeDocSaverForTesting != null) {
        await activeDocSaverForTesting!(uid, updated.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current')
            .set(updated.toMap());
      }
    } catch (e) {
      debugPrint('TransformationProvider: Error syncing progress: $e');
    }
  }
  List<UserTransformationState> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLifecycleOperationInProgress => _isLifecycleOperationInProgress;
  bool get hasActiveTransformation =>
      _activeTransformation != null && _activeTransformation!.status == 'active';

  /// Currently active programme blueprint
  TransformationPlanBlueprint? get activeBlueprint {
    if (_activeTransformation == null) return null;
    return TransformationPlansData.getById(_activeTransformation!.planId);
  }

  /// Current day's blueprint from the active plan
  TransformationDayBlueprint? get currentDayBlueprint {
    final blueprint = activeBlueprint;
    final state = activeTransformation;
    if (blueprint == null || state == null) return null;
    return blueprint.getDayBlueprint(state.currentDay);
  }

  /// Milestones already unlocked
  List<TransformationMilestone> get achievedMilestones {
    if (_activeTransformation == null) return [];
    return _activeTransformation!.milestones.where((m) => m.isAchieved).toList();
  }

  /// Milestones pending unlock
  List<TransformationMilestone> get upcomingMilestones {
    if (_activeTransformation == null) return [];
    return _activeTransformation!.milestones.where((m) => !m.isAchieved).toList();
  }

  String? get _uid {
    if (userIdOverrideForTesting != null) return userIdOverrideForTesting;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  TransformationProvider({bool autoLoad = true}) {
    if (autoLoad) {
      loadTransformation();
    }
  }

  /// Loads active transformation and completion history from Firestore
  Future<void> loadTransformation() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      _activeTransformation = null;
      _history = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (activeDocFetcherForTesting != null) {
        final data = activeDocFetcherForTesting!(uid);
        if (data != null) {
          _activeTransformation = UserTransformationState.fromMap(data);
        } else {
          _activeTransformation = null;
        }

        if (historyDocFetcherForTesting != null) {
          final historyData = historyDocFetcherForTesting!(uid) ?? [];
          _history = historyData
              .map((d) => UserTransformationState.fromMap(d))
              .toList();
          _history.sort((a, b) {
            final dateA = a.completedAt ?? a.targetEndDate;
            final dateB = b.completedAt ?? b.targetEndDate;
            return dateB.compareTo(dateA);
          });
        }
      } else {
        // Fetch active transformation document
        final activeDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current')
            .get();

        if (activeDoc.exists && activeDoc.data() != null) {
          _activeTransformation =
              UserTransformationState.fromMap(activeDoc.data()!);
        } else {
          _activeTransformation = null;
        }

        // Fetch transformation history without orderBy('completedAt') so documents
        // without completedAt (e.g. legacy or migrated records) remain visible.
        final historySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('transformation_history')
            .get();

        _history = historySnapshot.docs
            .map((doc) => UserTransformationState.fromMap(doc.data()))
            .toList();

        _history.sort((a, b) {
          final dateA = a.completedAt ?? a.targetEndDate;
          final dateB = b.completedAt ?? b.targetEndDate;
          return dateB.compareTo(dateA);
        });
      }
      await _syncProgress();
    } catch (e) {
      debugPrint('TransformationProvider: Error loading transformation: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enrolls the user into a selected transformation programme
  Future<void> enrollInPlan({
    required TransformationPlanBlueprint blueprint,
    required double targetCalories,
    required Map<String, double> targetMacros,
    SubscriptionProvider? subscriptionProvider,
    String? workoutLocation,
    String? experienceLevel,
    List<String>? availableEquipment,
    String? dietaryPreference,
    String? foodRestrictions,
    List<String>? allergies,
    String? injuries,
    int workoutDurationMinutes = 45,
    int workoutDaysPerWeek = 4,
    double? startingWeight,
    double? targetWeight,
    Map<String, double>? startingMeasurements,
  }) async {
    if (_isLifecycleOperationInProgress) {
      debugPrint('TransformationProvider: Lifecycle operation already in progress, ignoring duplicate call');
      return;
    }

    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    final hasEntitlement = await _isEntitled(subscriptionProvider);
    if (!hasEntitlement) {
      _error =
          'Active Premium subscription required to enroll in transformation programmes.';
      notifyListeners();
      return;
    }

    _isLifecycleOperationInProgress = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final prev = _activeTransformation;

      // If there was an active transformation with tracked data for a DIFFERENT plan, archive it to history with 'switched'
      final bool shouldArchivePrev = prev != null &&
          prev.planId != blueprint.id &&
          prev.hasTrackedData;

      UserTransformationState? archivedPrev;
      String? prevHistoryId;
      if (shouldArchivePrev) {
        archivedPrev = prev.copyWith(
          status: 'switched',
          completedAt: now,
        );
        prevHistoryId = '${archivedPrev.planId}_${now.millisecondsSinceEpoch}';
      }

      final targetEnd = now.add(Duration(days: blueprint.durationDays));
      final defaultMilestones =
          TransformationPlansData.createDefaultMilestones(blueprint);

      final cleanAllergies = allergies ??
          (foodRestrictions != null && foodRestrictions.isNotEmpty
              ? foodRestrictions
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty && e.toLowerCase() != 'none')
                  .toList()
              : const <String>[]);

      final newState = UserTransformationState(
        planId: blueprint.id,
        planTitle: blueprint.title,
        startDate: now,
        targetEndDate: targetEnd,
        currentDay: 1,
        totalDays: blueprint.durationDays,
        status: 'active',
        completedDayIndices: [],
        targetCalories: targetCalories,
        targetMacros: targetMacros,
        milestones: defaultMilestones,
        workoutLocation: workoutLocation,
        experienceLevel: experienceLevel,
        availableEquipment: availableEquipment ?? [],
        dietaryPreference: dietaryPreference,
        foodRestrictions: foodRestrictions,
        allergies: cleanAllergies,
        injuries: injuries,
        workoutDurationMinutes: workoutDurationMinutes,
        workoutDaysPerWeek: workoutDaysPerWeek,
        startingWeight: startingWeight,
        targetWeight: targetWeight,
        startingMeasurements: startingMeasurements ?? const {},
      );

      // Persist atomically
      if (batchCommitForTesting != null) {
        await batchCommitForTesting!(
          uid,
          activeData: newState.toMap(),
          deleteActive: false,
          historyData: archivedPrev?.toMap(),
          historyDocId: prevHistoryId,
        );
      } else if (activeDocSaverForTesting != null || historyDocSaverForTesting != null) {
        if (archivedPrev != null && historyDocSaverForTesting != null) {
          await historyDocSaverForTesting!(uid, archivedPrev.toMap());
        }
        if (activeDocSaverForTesting != null) {
          await activeDocSaverForTesting!(uid, newState.toMap());
        }
      } else {
        final batch = FirebaseFirestore.instance.batch();
        final activeRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current');

        if (archivedPrev != null && prevHistoryId != null) {
          final historyRef = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('transformation_history')
              .doc(prevHistoryId);
          batch.set(historyRef, archivedPrev.toMap());
        }

        batch.set(activeRef, newState.toMap());
        await batch.commit();
      }

      // Provider state updated ONLY after successful commit
      if (archivedPrev != null) {
        _history.insert(0, archivedPrev);
      }
      _activeTransformation = newState;
    } catch (e) {
      debugPrint('TransformationProvider: Error enrolling in plan: $e');
      _error = e.toString();
    } finally {
      _isLifecycleOperationInProgress = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates onboarding preferences & targets without resetting programme progress
  Future<void> updatePreferences({
    String? workoutLocation,
    String? experienceLevel,
    List<String>? availableEquipment,
    String? dietaryPreference,
    String? foodRestrictions,
    List<String>? allergies,
    String? injuries,
    int? workoutDurationMinutes,
    int? workoutDaysPerWeek,
    double? targetCalories,
    Map<String, double>? targetMacros,
  }) async {
    final current = _activeTransformation;
    final uid = _uid;
    if (current == null || uid == null) return;

    final updatedState = current.copyWith(
      workoutLocation: workoutLocation ?? current.workoutLocation,
      experienceLevel: experienceLevel ?? current.experienceLevel,
      availableEquipment: availableEquipment ?? current.availableEquipment,
      dietaryPreference: dietaryPreference ?? current.dietaryPreference,
      foodRestrictions: foodRestrictions ?? current.foodRestrictions,
      allergies: allergies ?? current.allergies,
      injuries: injuries ?? current.injuries,
      workoutDurationMinutes: workoutDurationMinutes ?? current.workoutDurationMinutes,
      workoutDaysPerWeek: workoutDaysPerWeek ?? current.workoutDaysPerWeek,
      targetCalories: targetCalories ?? current.targetCalories,
      targetMacros: targetMacros ?? current.targetMacros,
    );

    try {
      if (activeDocSaverForTesting != null) {
        await activeDocSaverForTesting!(uid, updatedState.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current')
            .set(updatedState.toMap());
      }
      _activeTransformation = updatedState;
      notifyListeners();
    } catch (e) {
      debugPrint('TransformationProvider: Error updating preferences: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // NUTRITION & MEAL PLANNING EXTENSIONS
  // ──────────────────────────────────────────────────────────────────────────

  final Set<String> _loggedMealKeysToday = {};

  bool isMealLoggedToday(String mealKey) => _loggedMealKeysToday.contains(mealKey);

  void markMealLoggedToday(String mealKey) {
    _loggedMealKeysToday.add(mealKey);
    notifyListeners();
  }

  /// Generates the complete 5-meal daily plan for any specified day of the programme
  TransformationDailyMealPlan? getMealPlanForDay(int dayNumber) {
    final state = _activeTransformation;
    if (state == null) return null;

    final plan = TransformationMealPlanGenerator.generateDailyMealPlan(
      dayNumber: dayNumber,
      targetCalories: state.targetCalories,
      targetMacros: state.targetMacros,
      dietaryPreference: state.dietaryPreference,
      allergies: state.allergies,
      programmeId: state.planId,
      customSubstitutions: state.mealSubstitutions,
    );

    // Apply isLogged state if already logged today
    final updatedMeals = plan.meals.map((m) {
      final key = 'day_${dayNumber}_meal_${m.id}';
      return m.copyWith(isLogged: isMealLoggedToday(key));
    }).toList();

    return TransformationDailyMealPlan(
      dayNumber: plan.dayNumber,
      plannedCalories: plan.plannedCalories,
      plannedProtein: plan.plannedProtein,
      plannedCarbs: plan.plannedCarbs,
      plannedFat: plan.plannedFat,
      meals: updatedMeals,
      isSafe: plan.isSafe,
      flaggedForReview: plan.flaggedForReview,
      reviewMessage: plan.reviewMessage,
    );
  }

  /// Swaps an ingredient in the user's active transformation meal plan and persists the choice
  Future<void> updateMealSubstitution({
    required String substitutionKey,
    required String foodId,
  }) async {
    final state = _activeTransformation;
    final uid = _uid;
    if (state == null || uid == null) return;

    final updatedSubstitutions = Map<String, String>.from(state.mealSubstitutions);
    updatedSubstitutions[substitutionKey] = foodId;

    final updatedState = state.copyWith(mealSubstitutions: updatedSubstitutions);

    try {
      if (activeDocSaverForTesting != null) {
        await activeDocSaverForTesting!(uid, updatedState.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current')
            .set(updatedState.toMap());
      }
      _activeTransformation = updatedState;
      notifyListeners();
    } catch (e) {
      debugPrint('TransformationProvider: Error saving meal substitution: $e');
    }
  }

  /// Logs a transformation meal directly into the existing ConsumptionProvider tracking system
  Future<void> logMealToConsumptionTracker({
    required BuildContext context,
    required TransformationMeal meal,
    required int dayNumber,
    double portionMultiplier = 1.0,
  }) async {
    final consumptionProvider =
        Provider.of<ConsumptionProvider>(context, listen: false);

    final scaledCalories = meal.totalCalories * portionMultiplier;
    final scaledProtein = meal.totalProtein * portionMultiplier;
    final scaledCarbs = meal.totalCarbs * portionMultiplier;
    final scaledFat = meal.totalFat * portionMultiplier;

    final now = DateTime.now();

    await consumptionProvider.addNewMeal(
      title: 'Transformation ${meal.name}',
      amount: portionMultiplier,
      calories: scaledCalories,
      proteins: scaledProtein,
      carbs: scaledCarbs,
      fats: scaledFat,
      dateTime: now,
    );

    final key = 'day_${dayNumber}_meal_${meal.id}';
    markMealLoggedToday(key);
  }

  /// Checks if a specific 1-based day has been completed
  bool isDayCompleted(int dayIndex) {
    if (_activeTransformation == null) return false;
    return _activeTransformation!.completedDayIndices.contains(dayIndex);
  }

  /// Explicitly marks a day completed in the programme (idempotent: does nothing if already completed)
  ///
  /// [summary] ({'sets', 'minutes', 'prs'}) is stored for the home card. If
  /// the day is already done (a repeat), only the summary is refreshed.
  Future<void> markDayCompleted(int dayIndex, {Map<String, int>? summary}) async {
    final current = _activeTransformation;
    final uid = _uid;
    if (current == null) return;
    if (!isDayCompleted(dayIndex)) {
      await toggleDayCompletion(dayIndex, summary: summary);
      return;
    }
    if (summary == null || uid == null) return;
    final summaries =
        Map<int, Map<String, int>>.from(current.completedDaySummaries)
          ..[dayIndex] = summary;
    final updated = current.copyWith(completedDaySummaries: summaries);
    try {
      if (activeDocSaverForTesting != null) {
        await activeDocSaverForTesting!(uid, updated.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current')
            .set(updated.toMap());
      }
      _activeTransformation = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('TransformationProvider: Error saving day summary: $e');
    }
  }

  /// Toggles completion status of a day in the programme
  Future<void> toggleDayCompletion(int dayIndex, {Map<String, int>? summary}) async {
    final current = _activeTransformation;
    final uid = _uid;
    if (current == null || uid == null) return;

    final updatedIndices = List<int>.from(current.completedDayIndices);
    final updatedDates = Map<int, String>.from(current.completedDayDates);
    final updatedSummaries =
        Map<int, Map<String, int>>.from(current.completedDaySummaries);
    if (updatedIndices.contains(dayIndex)) {
      updatedIndices.remove(dayIndex);
      updatedDates.remove(dayIndex);
      updatedSummaries.remove(dayIndex);
    } else {
      if (summary != null) updatedSummaries[dayIndex] = summary;
      updatedIndices.add(dayIndex);
      // Record when it was done so the plan can move on tomorrow.
      updatedDates[dayIndex] =
          UserTransformationState.dateKey(clockForTesting());
    }
    updatedIndices.sort();

    final updatedMilestones =
        _evaluateMilestones(current.milestones, updatedIndices);

    var updatedState = current.copyWith(
      completedDayIndices: updatedIndices,
      completedDayDates: updatedDates,
      completedDaySummaries: updatedSummaries,
      milestones: updatedMilestones,
    );
    updatedState = updatedState.copyWith(
        currentDay: _resolvedDayFor(updatedState));

    try {
      if (activeDocSaverForTesting != null) {
        await activeDocSaverForTesting!(uid, updatedState.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current')
            .set(updatedState.toMap());
      }
      _activeTransformation = updatedState;
      notifyListeners();
    } catch (e) {
      debugPrint('TransformationProvider: Error toggling day completion: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Records a weekly check-in, updating progress and saving to Firestore
  Future<void> recordWeeklyCheckIn(TransformationWeeklyCheckIn checkIn) async {
    final current = _activeTransformation;
    final uid = _uid;
    if (current == null || uid == null) return;

    final updatedCheckIns = List<TransformationWeeklyCheckIn>.from(current.weeklyCheckIns);
    final existingIndex = updatedCheckIns.indexWhere((c) => c.weekNumber == checkIn.weekNumber);
    if (existingIndex >= 0) {
      updatedCheckIns[existingIndex] = checkIn;
    } else {
      updatedCheckIns.add(checkIn);
    }
    updatedCheckIns.sort((a, b) => a.weekNumber.compareTo(b.weekNumber));

    final updatedState = current.copyWith(
      weeklyCheckIns: updatedCheckIns,
    );

    try {
      if (activeDocSaverForTesting != null) {
        await activeDocSaverForTesting!(uid, updatedState.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current')
            .set(updatedState.toMap());
      }
      _activeTransformation = updatedState;
      notifyListeners();
    } catch (e) {
      debugPrint('TransformationProvider: Error saving weekly check-in: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Marks a milestone as celebrated to prevent duplicate celebration dialogs
  Future<void> markMilestoneCelebrated(String milestoneId) async {
    final current = _activeTransformation;
    final uid = _uid;
    if (current == null || uid == null) return;

    if (current.celebratedMilestoneIds.contains(milestoneId)) return;

    final updatedCelebrated = List<String>.from(current.celebratedMilestoneIds)..add(milestoneId);
    final updatedState = current.copyWith(
      celebratedMilestoneIds: updatedCelebrated,
    );

    try {
      if (activeDocSaverForTesting != null) {
        await activeDocSaverForTesting!(uid, updatedState.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current')
            .set(updatedState.toMap());
      }
      _activeTransformation = updatedState;
      notifyListeners();
    } catch (e) {
      debugPrint('TransformationProvider: Error marking milestone celebrated: $e');
    }
  }

  /// Returns uncelebrated milestones that have been achieved
  List<TransformationMilestone> get uncelebratedMilestones {
    final current = _activeTransformation;
    if (current == null) return [];
    return current.milestones
        .where((m) => m.isAchieved && !current.celebratedMilestoneIds.contains(m.id))
        .toList();
  }

  /// Sets the active day cursor (e.g. user navigating through days)
  Future<void> setCurrentDay(int day) async {
    final current = _activeTransformation;
    final uid = _uid;
    if (current == null || uid == null) return;
    if (day < 1 || day > current.totalDays) return;

    final updatedState = current.copyWith(currentDay: day);

    try {
      if (activeDocSaverForTesting != null) {
        await activeDocSaverForTesting!(uid, updatedState.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current')
            .update({'currentDay': day});
      }
      _activeTransformation = updatedState;
      notifyListeners();
    } catch (e) {
      debugPrint('TransformationProvider: Error setting current day: $e');
    }
  }

  /// Completes and archives the active plan into transformation_history
  Future<void> completePlan() async {
    if (_isLifecycleOperationInProgress) {
      debugPrint('TransformationProvider: Lifecycle operation already in progress, ignoring duplicate call');
      return;
    }
    final current = _activeTransformation;
    final uid = _uid;
    if (current == null || uid == null) return;

    _isLifecycleOperationInProgress = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final completedState = current.copyWith(
        status: 'completed',
        completedAt: now,
      );

      final historyDocId = '${current.planId}_${now.millisecondsSinceEpoch}';

      if (batchCommitForTesting != null) {
        await batchCommitForTesting!(
          uid,
          activeData: null,
          deleteActive: true,
          historyData: completedState.toMap(),
          historyDocId: historyDocId,
        );
      } else if (activeDocSaverForTesting != null || historyDocSaverForTesting != null) {
        if (historyDocSaverForTesting != null) {
          await historyDocSaverForTesting!(uid, completedState.toMap());
        }
        if (activeDocSaverForTesting != null) {
          await activeDocSaverForTesting!(uid, {});
        }
      } else {
        final batch = FirebaseFirestore.instance.batch();
        final activeRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current');
        final historyRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('transformation_history')
            .doc(historyDocId);

        batch.set(historyRef, completedState.toMap());
        batch.delete(activeRef);
        await batch.commit();
      }

      // Provider state updated ONLY after successful commit
      _history.insert(0, completedState);
      _activeTransformation = null;
      try {
        await NotificationService().cancelTransformationDailyAccountabilityReminder();
      } catch (_) {}
    } catch (e) {
      debugPrint('TransformationProvider: Error completing plan: $e');
      _error = e.toString();
    } finally {
      _isLifecycleOperationInProgress = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Abandons the currently active transformation plan
  Future<void> abandonPlan() async {
    if (_isLifecycleOperationInProgress) {
      debugPrint('TransformationProvider: Lifecycle operation already in progress, ignoring duplicate call');
      return;
    }
    final uid = _uid;
    final current = _activeTransformation;
    if (uid == null || current == null) return;

    _isLifecycleOperationInProgress = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final bool shouldArchive = current.hasTrackedData;
      UserTransformationState? abandonedState;
      String? historyDocId;

      if (shouldArchive) {
        abandonedState = current.copyWith(
          status: 'abandoned',
          completedAt: now,
        );
        historyDocId = '${current.planId}_${now.millisecondsSinceEpoch}';
      }

      if (batchCommitForTesting != null) {
        await batchCommitForTesting!(
          uid,
          activeData: null,
          deleteActive: true,
          historyData: abandonedState?.toMap(),
          historyDocId: historyDocId,
        );
      } else if (activeDocSaverForTesting != null || historyDocSaverForTesting != null) {
        if (abandonedState != null && historyDocSaverForTesting != null) {
          await historyDocSaverForTesting!(uid, abandonedState.toMap());
        }
        if (activeDocSaverForTesting != null) {
          await activeDocSaverForTesting!(uid, {});
        }
      } else {
        final batch = FirebaseFirestore.instance.batch();
        final activeRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current');

        if (abandonedState != null && historyDocId != null) {
          final historyRef = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('transformation_history')
              .doc(historyDocId);
          batch.set(historyRef, abandonedState.toMap());
        }

        batch.delete(activeRef);
        await batch.commit();
      }

      // Provider state updated ONLY after successful commit
      if (abandonedState != null) {
        _history.insert(0, abandonedState);
      }
      _activeTransformation = null;
      try {
        await NotificationService().cancelTransformationDailyAccountabilityReminder();
      } catch (_) {}
    } catch (e) {
      debugPrint('TransformationProvider: Error abandoning plan: $e');
      _error = e.toString();
    } finally {
      _isLifecycleOperationInProgress = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // PHASE 8: Daily Accountability, Consumption Synchronization & Adherence
  // ---------------------------------------------------------------------------

  /// Computes or retrieves a structured TransformationDailyLog for any specified date.
  /// Seamlessly evaluates workout completion, food/calories, protein, water and recovery
  /// using live data from the canonical ConsumptionProvider and transformation state.
  TransformationDailyLog getDailyLogForDate({
    required DateTime date,
    ConsumptionProvider? consumptionProvider,
  }) {
    final state = _activeTransformation;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = dateStr == todayStr;

    if (state == null) {
      return TransformationDailyLog.calculate(
        planId: '',
        dayNumber: 1,
        dateString: dateStr,
        workoutCompleted: false,
        isRestDay: false,
        actualCalories: 0,
        targetCalories: 2000,
        actualProtein: 0,
        targetProtein: 140,
        actualWaterMl: 0,
        targetWaterMl: 2500,
        isToday: isToday,
      );
    }

    // Determine 1-based sequential programme day number based on start date
    final startMidnight = DateTime(state.startDate.year, state.startDate.month, state.startDate.day);
    final targetMidnight = DateTime(date.year, date.month, date.day);
    final daysDifference = targetMidnight.difference(startMidnight).inDays;
    int calculatedDay = daysDifference + 1;
    if (calculatedDay < 1) calculatedDay = 1;
    if (calculatedDay > state.totalDays) calculatedDay = state.totalDays;

    final blueprint = activeBlueprint ?? TransformationPlansData.getById(state.planId);
    final dayBlueprint = blueprint?.getDayBlueprint(calculatedDay);
    final isRestDay = dayBlueprint?.isRestDay ?? false;
    final workoutCompleted = isDayCompleted(calculatedDay);

    // Existing saved log if present
    final existingLog = state.dailyLogs[dateStr];

    // Read live consumption data
    double actualCalories = existingLog?.actualCalories ?? 0.0;
    double actualProtein = existingLog?.actualProtein ?? 0.0;
    double actualWaterMl = existingLog?.actualWaterMl ?? 0.0;

    if (consumptionProvider != null) {
      // 1. Calories (from meals logged today or consumedCalories)
      final mealCaloriesSum = consumptionProvider.meals
          .where((m) => DateFormat('yyyy-MM-dd').format(m.dateTime) == dateStr)
          .fold<double>(0.0, (total, m) => total + m.calories);

      if (isToday) {
        final homeCalories = consumptionProvider.consumedCalories.toDouble();
        actualCalories = homeCalories > 0 ? homeCalories : mealCaloriesSum;
      } else {
        actualCalories = mealCaloriesSum > 0 ? mealCaloriesSum : (existingLog?.actualCalories ?? 0.0);
      }

      // 2. Protein
      final mealProteinSum = consumptionProvider.meals
          .where((m) => DateFormat('yyyy-MM-dd').format(m.dateTime) == dateStr)
          .fold<double>(0.0, (total, m) => total + m.proteins);

      if (isToday) {
        actualProtein = mealProteinSum;
      } else {
        actualProtein = mealProteinSum > 0 ? mealProteinSum : (existingLog?.actualProtein ?? 0.0);
      }

      // 3. Water
      if (isToday && consumptionProvider.waterADay > 0) {
        actualWaterMl = consumptionProvider.waterADay;
      } else {
        final waterSum = consumptionProvider.water
            .where((w) => DateFormat('yyyy-MM-dd').format(w.dateTime) == dateStr)
            .fold<double>(0.0, (total, w) => total + w.amount);
        actualWaterMl = waterSum > 0 ? waterSum : (existingLog?.actualWaterMl ?? 0.0);
      }
    }

    return TransformationDailyLog.calculate(
      planId: state.planId,
      dayNumber: calculatedDay,
      dateString: dateStr,
      workoutCompleted: workoutCompleted,
      isRestDay: isRestDay,
      actualCalories: actualCalories,
      targetCalories: state.targetCalories,
      actualProtein: actualProtein,
      targetProtein: state.targetMacros['protein'] ?? 140.0,
      actualWaterMl: actualWaterMl,
      targetWaterMl: state.dailyWaterTargetMl,
      recoveryLevel: existingLog?.recoveryLevel,
      recoveryNote: existingLog?.recoveryNote,
      isToday: isToday,
    );
  }

  /// Persists a daily accountability record under the user's active transformation state
  Future<void> saveDailyLog(TransformationDailyLog log) async {
    final state = _activeTransformation;
    final uid = _uid;
    if (state == null || uid == null) return;

    final updatedLogs = Map<String, TransformationDailyLog>.from(state.dailyLogs);
    updatedLogs[log.dateString] = log;

    final updatedState = state.copyWith(dailyLogs: updatedLogs);

    try {
      if (activeDocSaverForTesting != null) {
        await activeDocSaverForTesting!(uid, updatedState.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current')
            .set(updatedState.toMap());
      }
      _activeTransformation = updatedState;
      notifyListeners();
    } catch (e) {
      debugPrint('TransformationProvider: Error saving daily log: $e');
    }
  }

  /// Updates recovery check-in for a given date and persists the recalculation
  Future<void> updateRecoveryCheckIn({
    required DateTime date,
    required String level,
    String? note,
    ConsumptionProvider? consumptionProvider,
  }) async {
    final liveLog = getDailyLogForDate(date: date, consumptionProvider: consumptionProvider);
    final evaluatedWithRecovery = TransformationDailyLog.calculate(
      planId: liveLog.planId,
      dayNumber: liveLog.dayNumber,
      dateString: liveLog.dateString,
      workoutCompleted: liveLog.workoutStatus == AccountabilityStatus.completed,
      isRestDay: liveLog.isRestDay,
      actualCalories: liveLog.actualCalories,
      targetCalories: liveLog.targetCalories,
      actualProtein: liveLog.actualProtein,
      targetProtein: liveLog.targetProtein,
      actualWaterMl: liveLog.actualWaterMl,
      targetWaterMl: liveLog.targetWaterMl,
      recoveryLevel: level,
      recoveryNote: note ?? liveLog.recoveryNote,
      isToday: liveLog.dateString == DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    await saveDailyLog(evaluatedWithRecovery);
  }

  /// Configures the user's personalized daily water target
  Future<void> updateDailyWaterTarget(double targetMl) async {
    final state = _activeTransformation;
    final uid = _uid;
    if (state == null || uid == null) return;

    final updatedState = state.copyWith(dailyWaterTargetMl: targetMl);

    try {
      if (activeDocSaverForTesting != null) {
        await activeDocSaverForTesting!(uid, updatedState.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current')
            .set(updatedState.toMap());
      }
      _activeTransformation = updatedState;
      notifyListeners();
    } catch (e) {
      debugPrint('TransformationProvider: Error updating daily water target: $e');
    }
  }

  /// Generates weekly adherence summary across a rolling window of actual recorded data
  TransformationWeeklyAdherenceSummaryData getWeeklyAdherenceSummary({
    DateTime? referenceDate,
    int daysCount = 7,
    ConsumptionProvider? consumptionProvider,
  }) {
    final state = _activeTransformation;
    final ref = referenceDate ?? DateTime.now();
    final dailyScores = <String, double>{};

    int workoutsCompletedCount = 0;
    int calorieConsistencyCount = 0;
    int proteinConsistencyCount = 0;
    int waterGoalConsistencyCount = 0;
    double totalScoresSum = 0.0;
    int assessableDaysCount = 0;

    for (int i = daysCount - 1; i >= 0; i--) {
      final date = ref.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final log = state?.dailyLogs[dateStr] ??
          (state != null && dateStr == todayStr
              ? getDailyLogForDate(date: date, consumptionProvider: consumptionProvider)
              : null);

      if (log != null && log.hasEnoughData) {
        dailyScores[dateStr] = log.dailyAdherenceScore;
        totalScoresSum += log.dailyAdherenceScore;
        assessableDaysCount++;

        if (log.workoutStatus == AccountabilityStatus.completed) {
          workoutsCompletedCount++;
        }
        if (log.calorieStatus == AccountabilityStatus.completed) {
          calorieConsistencyCount++;
        }
        if (log.proteinStatus == AccountabilityStatus.completed) {
          proteinConsistencyCount++;
        }
        if (log.waterStatus == AccountabilityStatus.completed) {
          waterGoalConsistencyCount++;
        }
      }
    }

    final double avgScore = assessableDaysCount > 0
        ? (totalScoresSum / assessableDaysCount).roundToDouble()
        : 0.0;

    return TransformationWeeklyAdherenceSummaryData(
      averageAdherenceScore: avgScore,
      dailyScores: dailyScores,
      workoutsCompletedCount: workoutsCompletedCount,
      calorieConsistencyCount: calorieConsistencyCount,
      proteinConsistencyCount: proteinConsistencyCount,
      waterGoalConsistencyCount: waterGoalConsistencyCount,
      hasEnoughData: assessableDaysCount > 0,
      daysTracked: assessableDaysCount,
    );
  }

  /// Reschedules an incomplete programme day to a new calendar date.
  /// Preserves the original day number and sequence while updating the calendar schedule.
  Future<bool> rescheduleDay({
    required int dayNumber,
    required DateTime newDate,
    String? note,
  }) async {
    final state = _activeTransformation;
    final uid = _uid;
    if (state == null || uid == null) return false;

    // Rule 1 & 5: Completed workouts cannot be rescheduled
    if (state.isDayCompleted(dayNumber)) {
      debugPrint('TransformationProvider: Cannot reschedule an already completed workout (Day $dayNumber).');
      return false;
    }

    final blueprint = activeBlueprint ?? TransformationPlansData.getById(state.planId);
    final dayBlueprint = blueprint?.getDayBlueprint(dayNumber);

    // Rule 9: Rest days remain rest days
    if (dayBlueprint?.isRestDay == true) {
      debugPrint('TransformationProvider: Rest days cannot be rescheduled.');
      return false;
    }

    final originalDate = state.getOriginalDateForDay(dayNumber);
    final normalizedNewDate = DateTime(newDate.year, newDate.month, newDate.day);

    final override = TransformationScheduleOverride(
      dayNumber: dayNumber,
      originalDate: originalDate,
      scheduledDate: normalizedNewDate,
      status: 'rescheduled',
      updatedAt: DateTime.now(),
      note: note,
    );

    final updatedOverrides = Map<int, TransformationScheduleOverride>.from(state.scheduleOverrides);
    updatedOverrides[dayNumber] = override;

    final updatedState = state.copyWith(scheduleOverrides: updatedOverrides);

    try {
      if (activeDocSaverForTesting != null) {
        await activeDocSaverForTesting!(uid, updatedState.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current')
            .set(updatedState.toMap());
      }
      _activeTransformation = updatedState;

      // Update notifications
      try {
        await NotificationService().scheduleTransformationWorkoutReminder(
          dayNumber: dayNumber,
          scheduledDate: normalizedNewDate,
          dayName: dayBlueprint?.muscleGroup ?? 'Workout',
          planTitle: state.planTitle,
        );
      } catch (_) {}

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('TransformationProvider: Error rescheduling day $dayNumber: $e');
      return false;
    }
  }

  /// Skips a workout day without marking it completed.
  /// Explains that the workout remains recorded as skipped, not completed.
  Future<bool> skipDay({
    required int dayNumber,
    String? reason,
  }) async {
    final state = _activeTransformation;
    final uid = _uid;
    if (state == null || uid == null) return false;

    if (state.isDayCompleted(dayNumber)) return false;

    final originalDate = state.getOriginalDateForDay(dayNumber);
    final scheduledDate = state.getScheduledDateForDay(dayNumber);

    final override = TransformationScheduleOverride(
      dayNumber: dayNumber,
      originalDate: originalDate,
      scheduledDate: scheduledDate,
      status: 'skipped',
      updatedAt: DateTime.now(),
      note: reason,
    );

    final updatedOverrides = Map<int, TransformationScheduleOverride>.from(state.scheduleOverrides);
    updatedOverrides[dayNumber] = override;

    final updatedState = state.copyWith(scheduleOverrides: updatedOverrides);

    try {
      if (activeDocSaverForTesting != null) {
        await activeDocSaverForTesting!(uid, updatedState.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current')
            .set(updatedState.toMap());
      }
      _activeTransformation = updatedState;

      // Cancel reminder for this skipped day
      try {
        await NotificationService().cancelTransformationWorkoutReminder(dayNumber);
      } catch (_) {}

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('TransformationProvider: Error skipping day $dayNumber: $e');
      return false;
    }
  }

  /// Resets a day back to its original planned schedule date
  Future<bool> resetDaySchedule({required int dayNumber}) async {
    final state = _activeTransformation;
    final uid = _uid;
    if (state == null || uid == null) return false;

    final updatedOverrides = Map<int, TransformationScheduleOverride>.from(state.scheduleOverrides);
    updatedOverrides.remove(dayNumber);

    final updatedState = state.copyWith(scheduleOverrides: updatedOverrides);

    try {
      if (activeDocSaverForTesting != null) {
        await activeDocSaverForTesting!(uid, updatedState.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('active_transformation')
            .doc('current')
            .set(updatedState.toMap());
      }
      _activeTransformation = updatedState;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('TransformationProvider: Error resetting schedule for day $dayNumber: $e');
      return false;
    }
  }

  /// Returns weekly scheduling metrics and advisory recommendations
  TransformationWeeklyScheduleData getWeeklyScheduleSummary({int? weekNumber}) {
    final state = _activeTransformation;
    final currentWeek = weekNumber ?? state?.currentWeekNumber ?? 1;

    if (state == null) {
      return TransformationWeeklyScheduleData(
        weekNumber: currentWeek,
        plannedWorkouts: 0,
        completedWorkouts: 0,
        rescheduledWorkouts: 0,
        skippedWorkouts: 0,
        advisoryInsights: const ['Consistent with planned schedule.'],
      );
    }

    final blueprint = activeBlueprint ?? TransformationPlansData.getById(state.planId);
    final startDay = (currentWeek - 1) * 7 + 1;
    final endDay = (startDay + 6).clamp(1, state.totalDays);

    int plannedCount = 0;
    int completedCount = 0;
    int rescheduledCount = 0;
    int skippedCount = 0;

    for (int dayNum = startDay; dayNum <= endDay; dayNum++) {
      final dayBlueprint = blueprint?.getDayBlueprint(dayNum);
      if (dayBlueprint != null && !dayBlueprint.isRestDay) {
        plannedCount++;
        if (state.isDayCompleted(dayNum)) {
          completedCount++;
        } else if (state.isDaySkipped(dayNum)) {
          skippedCount++;
        }
        if (state.isDayRescheduled(dayNum)) {
          rescheduledCount++;
        }
      }
    }

    final insights = <String>[];
    if (skippedCount >= 2) {
      insights.add('Multiple sessions skipped. Consider reducing weekly training days rather than forcing catch-up.');
    } else if (rescheduledCount > 0) {
      insights.add('$rescheduledCount session(s) rescheduled this week to fit your schedule.');
    } else if (completedCount == plannedCount && plannedCount > 0) {
      insights.add('All planned sessions completed for Week $currentWeek!');
    } else {
      insights.add('Consistent with planned schedule.');
    }

    return TransformationWeeklyScheduleData(
      weekNumber: currentWeek,
      plannedWorkouts: plannedCount,
      completedWorkouts: completedCount,
      rescheduledWorkouts: rescheduledCount,
      skippedWorkouts: skippedCount,
      advisoryInsights: insights,
    );
  }
}

/// Structured summary of weekly schedule performance
class TransformationWeeklyScheduleData {
  final int weekNumber;
  final int plannedWorkouts;
  final int completedWorkouts;
  final int rescheduledWorkouts;
  final int skippedWorkouts;
  final List<String> advisoryInsights;

  const TransformationWeeklyScheduleData({
    required this.weekNumber,
    required this.plannedWorkouts,
    required this.completedWorkouts,
    required this.rescheduledWorkouts,
    required this.skippedWorkouts,
    required this.advisoryInsights,
  });
}

/// Structured summary of weekly adherence and habit consistency
class TransformationWeeklyAdherenceSummaryData {
  final double averageAdherenceScore;
  final Map<String, double> dailyScores;
  final int workoutsCompletedCount;
  final int calorieConsistencyCount;
  final int proteinConsistencyCount;
  final int waterGoalConsistencyCount;
  final bool hasEnoughData;
  final int daysTracked;

  const TransformationWeeklyAdherenceSummaryData({
    required this.averageAdherenceScore,
    required this.dailyScores,
    required this.workoutsCompletedCount,
    required this.calorieConsistencyCount,
    required this.proteinConsistencyCount,
    required this.waterGoalConsistencyCount,
    required this.hasEnoughData,
    required this.daysTracked,
  });
}
