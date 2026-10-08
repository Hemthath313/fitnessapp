import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/widgets/interactive_exercise_detail.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeAiRoutineCard extends StatefulWidget {
  const HomeAiRoutineCard({super.key});

  @override
  State<HomeAiRoutineCard> createState() => _HomeAiRoutineCardState();
}

class _HomeAiRoutineCardState extends State<HomeAiRoutineCard> {
  bool _isLocalCompletedToday = false;
  bool _hasAttemptedAutoHeal = false;

  static const List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _checkLocalCompletion();
  }

  Future<void> _checkLocalCompletion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayName = DateFormat('EEEE').format(DateTime.now());

      final completedRoutine = prefs.getBool('completed_routine_${todayName}_$todayKey') ?? false;
      final completedAny = prefs.getBool('completed_any_routine_$todayKey') ?? false;

      if (mounted && (completedRoutine || completedAny) != _isLocalCompletedToday) {
        setState(() {
          _isLocalCompletedToday = completedRoutine || completedAny;
        });
      }
    } catch (_) {}
  }

  void _triggerAutoHealIfNeeded(Map<String, List<WorkoutModel>> grouped, WorkoutProvider wp) {
    if (_hasAttemptedAutoHeal) return;
    // If user's plan only has Wednesday (truncated by previous midnight deletion bug),
    // automatically restore Monday and Friday so their 3-day split is intact.
    if (grouped.length == 1 && grouped.containsKey('Wednesday')) {
      _hasAttemptedAutoHeal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await wp.restoreDefaultThreeDaySplit();
          if (mounted) setState(() {});
        } catch (_) {}
      });
    }
  }

  String _getNextWorkoutDay(String currentDay, Map<String, List<WorkoutModel>> grouped) {
    final currentIndex = _weekDays.indexOf(currentDay);
    if (currentIndex == -1) return '';

    // Search ahead in the week (1 to 6 days ahead)
    for (int i = 1; i <= 6; i++) {
      final next = _weekDays[(currentIndex + i) % 7];
      if (grouped.containsKey(next)) {
        return next;
      }
    }

    return '';
  }

  void _confirmResetPlan(BuildContext context, WorkoutProvider workoutProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ColorManager.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Reset AI Plan?', style: TextStyle(color: ColorManager.textPrimary)),
        content: Text(
          'This will clear your current AI workout split so you can build a fresh one.',
          style: TextStyle(color: ColorManager.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Cancel', style: TextStyle(color: ColorManager.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await workoutProvider.deleteWeeklyPlan();
      await workoutProvider.fetchAndSetWorkouts();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = Provider.of<StatisticsProvider>(context);
    final bool isCompletedToday = _isLocalCompletedToday || stats.hasWorkoutToday;

    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, _) {
        final planWorkouts = workoutProvider.allWorkouts
            .where((w) => w.name.startsWith('['))
            .toList();

        final Map<String, List<WorkoutModel>> grouped = {};
        for (var w in planWorkouts) {
          final match = RegExp(r'^\[(\w+)\]').firstMatch(w.name);
          if (match != null) {
            final day = match.group(1)!;
            grouped.putIfAbsent(day, () => []).add(w);
          }
        }

        // Auto-heal incomplete split in the background
        _triggerAutoHealIfNeeded(grouped, workoutProvider);

        if (grouped.isEmpty) {
          return _buildNoPlanCard(context);
        }

        return _buildWeeklyScheduleCard(
          context: context,
          grouped: grouped,
          isCompletedToday: isCompletedToday,
          workoutProvider: workoutProvider,
        );
      },
    );
  }

  /// Empty State: No Plan Active -> Invite user to generate one
  Widget _buildNoPlanCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: ColorManager.primary.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorManager.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: ColorManager.primary, size: 13.sp),
                      SizedBox(width: 5.w),
                      Text(
                        'AI WORKOUT ROUTINE',
                        style: TextStyle(
                          color: ColorManager.primary,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '3-6 Day Splits',
                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'Build Your AI Workout Plan',
              style: TextStyle(
                color: ColorManager.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Choose 3 to 6 days per week with smart exercises, rest timers, and video guides.',
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 12.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(Routes.workoutGeneratorRoute),
                icon: Icon(Icons.flash_on_rounded, size: 18.sp, color: Colors.black),
                label: Text(
                  'Build My Plan with AI',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The Hero AI Weekly Schedule on Home (Matching the original AI Hub clarity!)
  Widget _buildWeeklyScheduleCard({
    required BuildContext context,
    required Map<String, List<WorkoutModel>> grouped,
    required bool isCompletedToday,
    required WorkoutProvider workoutProvider,
  }) {
    final todayName = DateFormat('EEEE').format(DateTime.now());
    final bool isTodayWorkoutDay = grouped.containsKey(todayName);
    final String nextWorkoutDay = _getNextWorkoutDay(todayName, grouped);

    final sortedDays = grouped.keys.toList()
      ..sort((a, b) => _weekDays.indexOf(a).compareTo(_weekDays.indexOf(b)));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: ColorManager.divider,
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header: Title, Split Type, Re-plan & Reset
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: ColorManager.primary, size: 16.sp),
                          SizedBox(width: 6.w),
                          Text(
                            'AI Workout Schedule',
                            style: TextStyle(
                              color: ColorManager.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${sortedDays.length}-Day Split (${sortedDays.join(' · ')})',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push(Routes.workoutGeneratorRoute),
                  icon: Icon(Icons.refresh_rounded, size: 14.sp, color: Colors.black),
                  label: Text(
                    'Re-plan',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
                SizedBox(width: 4.w),
                IconButton(
                  onPressed: () => _confirmResetPlan(context, workoutProvider),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  iconSize: 20.sp,
                  tooltip: 'Reset Schedule',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Today's Status Banner (Smart & Truthful)
            _buildTodayStatusBanner(
              todayName: todayName,
              isTodayWorkoutDay: isTodayWorkoutDay,
              isCompletedToday: isCompletedToday,
              nextWorkoutDay: nextWorkoutDay,
              grouped: grouped,
            ),
            SizedBox(height: 14.h),

            // The Split Days List (Monday, Wednesday, Friday)
            ...sortedDays.map((day) {
              final workouts = grouped[day]!;
              final bool isToday = day == todayName;
              final bool isNextUp = day == nextWorkoutDay;
              final bool isDoneToday = isToday && isCompletedToday;

              return _buildDayCard(
                context: context,
                day: day,
                workouts: workouts,
                isToday: isToday,
                isNextUp: isNextUp,
                isDoneToday: isDoneToday,
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Compact status strip indicating where the user stands today
  Widget _buildTodayStatusBanner({
    required String todayName,
    required bool isTodayWorkoutDay,
    required bool isCompletedToday,
    required String nextWorkoutDay,
    required Map<String, List<WorkoutModel>> grouped,
  }) {
    if (isTodayWorkoutDay) {
      if (isCompletedToday) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xFF1E4331),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: const Color(0xFF4CAF50), size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '$todayName Workout Crushed! 🔥 Great job today.',
                  style: TextStyle(
                    color: const Color(0xFFE8F5E9),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (nextWorkoutDay.isNotEmpty)
                Text(
                  'Next: $nextWorkoutDay',
                  style: TextStyle(color: const Color(0xFF81C784), fontSize: 11.sp),
                ),
            ],
          ),
        );
      } else {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: ColorManager.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: ColorManager.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.fitness_center_rounded, color: ColorManager.primary, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Today ($todayName) is Workout Day! ${grouped[todayName]!.length} exercises scheduled.',
                  style: TextStyle(
                    color: ColorManager.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // Today is a Rest Day (e.g. Thursday)
      final tomorrowIndex = (_weekDays.indexOf(todayName) + 1) % 7;
      final tomorrowName = _weekDays[tomorrowIndex];
      final bool isTomorrowNext = nextWorkoutDay == tomorrowName;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.bedtime_rounded, color: Colors.blueAccent, size: 18.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Today ($todayName) is Rest & Recovery.',
                style: TextStyle(
                  color: Colors.blueAccent.shade100,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (nextWorkoutDay.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  isTomorrowNext ? 'Tomorrow: $nextWorkoutDay' : 'Next: $nextWorkoutDay',
                  style: TextStyle(
                    color: ColorManager.primary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  /// Individual Day Card (Monday, Wednesday, Friday) with [Start Day] button and exercises
  Widget _buildDayCard({
    required BuildContext context,
    required String day,
    required List<WorkoutModel> workouts,
    required bool isToday,
    required bool isNextUp,
    required bool isDoneToday,
  }) {
    Color borderColor = ColorManager.divider;
    Color dayColor = ColorManager.textPrimary;
    Widget? badge;

    if (isDoneToday) {
      borderColor = const Color(0xFF4CAF50).withValues(alpha: 0.5);
      dayColor = const Color(0xFF81C784);
      badge = Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1E4331),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
        ),
        child: Text(
          'COMPLETED ✓',
          style: TextStyle(color: const Color(0xFF81C784), fontSize: 9.sp, fontWeight: FontWeight.bold),
        ),
      );
    } else if (isNextUp) {
      borderColor = ColorManager.primary.withValues(alpha: 0.6);
      dayColor = ColorManager.primary;
      badge = Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: ColorManager.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: ColorManager.primary.withValues(alpha: 0.4)),
        ),
        child: Text(
          'NEXT UP',
          style: TextStyle(color: ColorManager.primary, fontSize: 9.sp, fontWeight: FontWeight.bold),
        ),
      );
    } else if (isToday) {
      borderColor = ColorManager.primary;
      dayColor = ColorManager.primary;
      badge = Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: ColorManager.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          'TODAY',
          style: TextStyle(color: ColorManager.primary, fontSize: 9.sp, fontWeight: FontWeight.bold),
        ),
      );
    }

    final exerciseNames = workouts
        .map((w) => w.name.replaceAll(RegExp(r'^\[\w+\]\s*'), '').trim())
        .toList();

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: isNextUp || isToday ? 1.4 : 1),
      ),
      child: ExpansionTile(
        initiallyExpanded: isToday || isNextUp,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        tilePadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        title: Row(
          children: [
            Text(
              day,
              style: TextStyle(
                color: dayColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (badge != null) ...[
              SizedBox(width: 8.w),
              badge,
            ],
          ],
        ),
        subtitle: Text(
          '${workouts.length} Exercises',
          style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DayWorkoutSessionPage(
                  dayName: day,
                  workouts: workouts,
                ),
              ),
            ).then((_) {
              _checkLocalCompletion();
              if (mounted) setState(() {});
            });
          },
          icon: Icon(
            isDoneToday ? Icons.refresh_rounded : Icons.play_arrow_rounded,
            size: 16.sp,
            color: Colors.white,
          ),
          label: Text(
            isDoneToday ? 'Repeat' : 'Start Day',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDoneToday ? const Color(0xFF2E7D32) : ColorManager.primary,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: Column(
              children: [
                Divider(color: ColorManager.divider, height: 16.h),
                ...workouts.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final w = entry.value;
                  final name = exerciseNames[idx];

                  return _buildExerciseRow(
                    context: context,
                    workout: w,
                    displayName: name,
                    isDone: isDoneToday,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Row for each exercise within a day
  Widget _buildExerciseRow({
    required BuildContext context,
    required WorkoutModel workout,
    required String displayName,
    required bool isDone,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFF1E4331) : ColorManager.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? Icons.check_rounded : Icons.fitness_center_rounded,
              size: 13.sp,
              color: isDone ? const Color(0xFF4CAF50) : ColorManager.primary,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: isDone ? const Color(0xFFE8F5E9) : ColorManager.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: isDone ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
                Text(
                  '${workout.setNumber} sets × ${workout.repNumber} reps',
                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showExerciseDetailModal(context, displayName, workout),
            icon: Icon(Icons.info_outline_rounded, color: ColorManager.textTertiary, size: 18.sp),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'View Guide',
          ),
        ],
      ),
    );
  }

  void _showExerciseDetailModal(BuildContext context, String cleanName, WorkoutModel workout) {
    Exercise? foundExercise;
    try {
      final allExercises = [
        ...ExerciseData.chest,
        ...ExerciseData.back,
        ...ExerciseData.shoulders,
        ...ExerciseData.arms,
        ...ExerciseData.legs,
      ];
      foundExercise = allExercises.firstWhere((e) => e.name.toLowerCase() == cleanName.toLowerCase());
    } catch (_) {}

    String category = 'Chest';
    if (foundExercise != null) {
      if (ExerciseData.chest.any((e) => e.name == foundExercise!.name)) {
        category = 'Chest';
      } else if (ExerciseData.arms.any((e) => e.name == foundExercise!.name)) {
        category = 'Arms';
      } else if (ExerciseData.back.any((e) => e.name == foundExercise!.name)) {
        category = 'Back';
      } else if (ExerciseData.legs.any((e) => e.name == foundExercise!.name)) {
        category = 'Legs';
      } else if (ExerciseData.shoulders.any((e) => e.name == foundExercise!.name)) {
        category = 'Shoulders';
      }
    }

    final exerciseToUse = foundExercise ?? Exercise(
      name: cleanName,
      videoPath: '',
      description: 'Custom exercise routine.',
      target: 'General',
      equipment: 'Gym / Dumbbells',
      instructions: const ['Perform the scheduled sets with proper form.'],
      difficulty: 'All Levels',
      setsReps: '${workout.setNumber} sets × ${workout.repNumber} reps',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => InteractiveExerciseDetailWidget(
        name: exerciseToUse.name,
        videoPath: exerciseToUse.videoPath,
        description: exerciseToUse.description,
        target: exerciseToUse.target,
        equipment: exerciseToUse.equipment,
        instructions: exerciseToUse.instructions,
        difficulty: exerciseToUse.difficulty,
        setsReps: exerciseToUse.setsReps,
        category: category,
      ),
    );
  }
}
