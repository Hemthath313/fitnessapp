import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/gradient_hero_card.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/utils/managers/card_size_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/presentation/home/widgets/routine_no_plan_card.dart';
import 'package:fitness_app/presentation/home/widgets/routine_toolkit_cards.dart';
import 'package:fitness_app/presentation/home/widgets/transformation_hero_card.dart';

class HomeAiRoutineCard extends StatefulWidget {
  const HomeAiRoutineCard({super.key});

  @override
  State<HomeAiRoutineCard> createState() => _HomeAiRoutineCardState();
}

class _HomeAiRoutineCardState extends State<HomeAiRoutineCard> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPageIndex = 0;
  Set<String> _localCompletedRoutineDaysToday = <String>{};

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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkLocalCompletion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      DateTime now = DateTime.now();
      if (mounted) {
        final wp = Provider.of<WorkoutProvider?>(context, listen: false);
        if (wp != null) {
          now = wp.currentNow;
        }
      }
      final todayKey = DateFormat('yyyy-MM-dd').format(now);
      final completedDays = <String>{};
      for (final day in _weekDays) {
        if (prefs.getBool('completed_routine_${day}_$todayKey') == true) {
          completedDays.add(day.toLowerCase());
        }
      }

      if (mounted &&
          (completedDays.length != _localCompletedRoutineDaysToday.length ||
              !completedDays.containsAll(_localCompletedRoutineDaysToday))) {
        setState(() {
          _localCompletedRoutineDaysToday = completedDays;
        });
      }
    } catch (_) {}
  }

  String _getNextWorkoutDay(String currentDay, Map<String, List<WorkoutModel>> grouped) {
    final currentIndex = _weekDays.indexOf(currentDay);
    if (currentIndex == -1) return '';

    for (int i = 1; i <= 6; i++) {
      final next = _weekDays[(currentIndex + i) % 7];
      if (grouped.containsKey(next)) {
        return next;
      }
    }
    return '';
  }

  String? _findMissedWorkoutDay(
    String todayName,
    Map<String, List<WorkoutModel>> grouped,
    WorkoutProvider wp,
  ) {
    final todayIndex = _weekDays.indexOf(todayName);
    if (todayIndex <= 0) return null; // Monday is the start of the week

    // Check earlier scheduled days this week (from Monday up to yesterday)
    for (int i = 0; i < todayIndex; i++) {
      final prevDay = _weekDays[i];
      if (grouped.containsKey(prevDay)) {
        final completed = wp.isDayWorkoutCompletedThisWeek(prevDay) ||
            _localCompletedRoutineDaysToday.contains(prevDay.toLowerCase());
        if (!completed) {
          return prevDay;
        }
      }
    }
    return null;
  }

  Future<void> _confirmResetPlan(
      BuildContext context, WorkoutProvider workoutProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ColorManager.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Reset your plan?', style: TextStyle(color: ColorManager.textPrimary)),
        content: Text(
          'This will clear your current workout split so you can build a fresh one.',
          style: TextStyle(color: ColorManager.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Cancel', style: TextStyle(color: ColorManager.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: ColorManager.error),
            child: const Text('Reset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await workoutProvider.deleteWeeklyPlan();
      await workoutProvider.fetchAndSetWorkouts();
      if (context.mounted) {
        final statsProvider =
            Provider.of<StatisticsProvider>(context, listen: false);
        await statsProvider.clearScheduledDays();
        await statsProvider.resetWeeklyTarget();
      }
      _localCompletedRoutineDaysToday = <String>{};
      try {
        await NotificationService().cancelWorkoutDayReminders();
        await NotificationService().cancelRestDayReminders();
      } catch (_) {}
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final transformationProvider = Provider.of<TransformationProvider?>(context);

    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, _) {
        // Priority 1: Active Transformation Programme
        if (transformationProvider != null &&
            transformationProvider.hasActiveTransformation) {
          return TransformationHeroCard(transformationProvider: transformationProvider);
        }

        // Priority 2: Active AI Workout Routine
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

        if (grouped.isNotEmpty) {
          final todayName =
              DateFormat('EEEE').format(workoutProvider.currentNow);
          final bool isCompletedToday = grouped.containsKey(todayName) &&
              (_localCompletedRoutineDaysToday
                      .contains(todayName.toLowerCase()) ||
                  workoutProvider.isDayWorkoutCompletedToday(todayName) ||
                  workoutProvider.isDayWorkoutCompletedThisWeek(todayName));

          return _buildHorizontalScrollerHub(
            context: context,
            grouped: grouped,
            isCompletedToday: isCompletedToday,
            workoutProvider: workoutProvider,
          );
        }

        // Priority 3: No Active Workout Plan
        return const NoPlanCard();
      },
    );
  }

  /// Compact Horizontal Scroller Hub (Nike/Hevy/Apple Fitness inspired)
  Widget _buildHorizontalScrollerHub({
    required BuildContext context,
    required Map<String, List<WorkoutModel>> grouped,
    required bool isCompletedToday,
    required WorkoutProvider workoutProvider,
  }) {
    final todayName = DateFormat('EEEE').format(workoutProvider.currentNow);
    final bool isTodayWorkoutDay = grouped.containsKey(todayName);
    final String nextWorkoutDay = _getNextWorkoutDay(todayName, grouped);

    final sortedDays = grouped.keys.toList()
      ..sort((a, b) => _weekDays.indexOf(a).compareTo(_weekDays.indexOf(b)));

    // Prepare Cards List for the Horizontal Scroller Deck
    final List<Widget> scrollerCards = [];
    final Map<String, int> dayToCardIndex = {};

    final String? missedDayName =
        _findMissedWorkoutDay(todayName, grouped, workoutProvider);
    final List<WorkoutModel>? missedWorkouts =
        missedDayName != null ? grouped[missedDayName] : null;

    // Card 1: Active Focus Card (Today if scheduled, or Next Up if today is rest)
    if (isTodayWorkoutDay) {
      dayToCardIndex[todayName] = scrollerCards.length;
      scrollerCards.add(_buildActiveDayCard(
        context: context,
        dayName: todayName,
        workouts: grouped[todayName]!,
        isToday: true,
        isCompleted: isCompletedToday,
        isNextUp: false,
        missedDayName: missedDayName,
        missedWorkouts: missedWorkouts,
      ));
    } else {
      // Today is Rest Day -> Focus Card is Next Scheduled Day (e.g. Friday)
      if (nextWorkoutDay.isNotEmpty && grouped.containsKey(nextWorkoutDay)) {
        dayToCardIndex[nextWorkoutDay] = scrollerCards.length;
        scrollerCards.add(_buildActiveDayCard(
          context: context,
          dayName: nextWorkoutDay,
          workouts: grouped[nextWorkoutDay]!,
          isToday: false,
          isCompleted: false,
          isNextUp: true,
          restDayName: todayName,
          missedDayName: missedDayName,
          missedWorkouts: missedWorkouts,
        ));
      }
    }

    // Add remaining days in the split (e.g. Wednesday completed, Monday upcoming)
    for (var day in sortedDays) {
      if (dayToCardIndex.containsKey(day)) continue; // Already added as focus card
      dayToCardIndex[day] = scrollerCards.length;
      final bool isDayDone = (day == todayName && isCompletedToday) ||
          _localCompletedRoutineDaysToday.contains(day.toLowerCase()) ||
          workoutProvider.isDayWorkoutCompletedThisWeek(day);

      scrollerCards.add(_buildStandardSplitCard(
        context: context,
        dayName: day,
        workouts: grouped[day]!,
        isDone: isDayDone,
      ));
    }

    // Card: AI Split Customizer & Quick Modifier
    scrollerCards.add(RoutineCustomizerCard(activeDays: sortedDays));

    // Card: Pro Workout Toolkit (Plate Math + 1RM)
    scrollerCards.add(const ProToolkitCard());

    // Card: Adaptive Strength Partner & PR Vault
    scrollerCards.add(const StrengthPartnerCard());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Bar: Title, Split Subtitle & Quick Re-plan
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: ColorManager.primaryText, size: 16.sp),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            'Workout Schedule',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ColorManager.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
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
                icon: Icon(Icons.refresh_rounded, size: 13.sp, color: ColorManager.onMint),
                label: Text(
                  'Re-plan',
                  style: TextStyle(
                    color: ColorManager.onMint,
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
                icon: Icon(Icons.delete_outline_rounded, color: ColorManager.errorText),
                iconSize: 18.sp,
                tooltip: 'Reset Schedule',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // 2. Interactive 7-Day Anchor Strip (Mon to Sun)
        _buildSevenDayAnchorStrip(
          todayName: todayName,
          nextWorkoutDay: nextWorkoutDay,
          grouped: grouped,
          dayToCardIndex: dayToCardIndex,
          isCompletedToday: isCompletedToday,
          workoutProvider: workoutProvider,
        ),
        SizedBox(height: 12.h),

        // 3. Compact Horizontal Scroller Deck (same height as the Challenges shelf)
        SizedBox(
          height: AppCardSize.shelfHeight(context),
          child: PageView.builder(
            controller: _pageController,
            itemCount: scrollerCards.length,
            onPageChanged: (idx) {
              setState(() {
                _currentPageIndex = idx;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: scrollerCards[index],
              );
            },
          ),
        ),
        SizedBox(height: 8.h),

        // 4. Dot Page Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(scrollerCards.length, (idx) {
            final bool isSelected = idx == _currentPageIndex;
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: isSelected ? 16.w : 6.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isSelected ? ColorManager.primary : ColorManager.divider,
                borderRadius: BorderRadius.circular(4.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Interactive 7-Day Anchor Strip: Tapping any scheduled day animates directly to that card!
  Widget _buildSevenDayAnchorStrip({
    required String todayName,
    required String nextWorkoutDay,
    required Map<String, List<WorkoutModel>> grouped,
    required Map<String, int> dayToCardIndex,
    required bool isCompletedToday,
    required WorkoutProvider workoutProvider,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: ColorManager.surfaceDark,
          borderRadius: BorderRadius.circular(AppRadius.small.r),
          border: Border.all(color: ColorManager.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekDays.map((day) {
            final isToday = day == todayName;
            final hasWorkout = grouped.containsKey(day);
            final isNext = day == nextWorkoutDay;
            final isDayDone = (isToday && isCompletedToday) ||
                _localCompletedRoutineDaysToday.contains(day.toLowerCase()) ||
                workoutProvider.isDayWorkoutCompletedThisWeek(day);
            final dayShort = day.substring(0, 3);

            Color bgColor = Colors.transparent;
            Color textColor = ColorManager.textTertiary;
            Border? border;

            if (isToday) {
              // Today: brand-blue outline; a soft green tint once it's done
              // (same treatment as the other completed days).
              final bool todayDone = hasWorkout && isCompletedToday;
              bgColor = todayDone
                  ? ColorManager.successText.withValues(alpha: 0.14)
                  : ColorManager.primary.withValues(alpha: 0.14);
              textColor = todayDone
                  ? ColorManager.successText
                  : ColorManager.primaryText;
              border = Border.all(
                color: todayDone ? ColorManager.successText : ColorManager.primaryText,
                width: 1.4,
              );
            } else if (isDayDone) {
              bgColor = ColorManager.successText.withValues(alpha: 0.14);
              textColor = ColorManager.successText;
              border = Border.all(color: ColorManager.successText.withValues(alpha: 0.6), width: 1);
            } else if (isNext) {
              bgColor = ColorManager.primary.withValues(alpha: 0.15);
              textColor = ColorManager.primaryText;
              border = Border.all(color: ColorManager.primary.withValues(alpha: 0.6), width: 1);
            } else if (hasWorkout) {
              textColor = ColorManager.textPrimary;
            }

            return InkWell(
              onTap: () {
                if (dayToCardIndex.containsKey(day)) {
                  _pageController.animateToPage(
                    dayToCardIndex[day]!,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOut,
                  );
                }
              },
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8.r),
                  border: border,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayShort,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12.sp,
                        fontWeight: isToday || isNext || hasWorkout || isDayDone ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    if (isToday && !hasWorkout)
                      Text('REST', style: TextStyle(color: ColorManager.infoText, fontSize: 12.sp, fontWeight: FontWeight.bold))
                    else if (isDayDone)
                      Text('DONE', style: TextStyle(color: ColorManager.successText, fontSize: 12.sp, fontWeight: FontWeight.bold))
                    else if (isNext)
                      Text('NEXT', style: TextStyle(color: ColorManager.primaryText, fontSize: 12.sp, fontWeight: FontWeight.bold))
                    else if (hasWorkout)
                      Text('${grouped[day]!.length}ex', style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp))
                    else
                      Text('—', style: TextStyle(color: ColorManager.textDisabled, fontSize: 12.sp)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Card 1: Active Focus Card (Immediate Next Session or Completed Today)
  /// Picks the mint anatomy cut-out that best matches the exercises of a day.
  String _anatomyAssetFor(List<String> exerciseNames, String dayName) {
    final text = exerciseNames.join(' ').toLowerCase();
    const rules = <String, List<String>>{
      'chest': ['chest', 'bench', 'push-up', 'push up', 'fly', 'pec'],
      'back': ['back', 'row', 'pull-up', 'pull up', 'lat', 'deadlift', 'pulldown'],
      'shoulders': ['shoulder', 'overhead', 'lateral', 'delt', 'press'],
      'biceps': ['bicep', 'curl'],
      'triceps': ['tricep', 'dip', 'pushdown', 'extension', 'skull'],
      'legs': ['leg', 'squat', 'lunge', 'calf', 'glute', 'hamstring', 'quad'],
      'abs': ['abs', 'crunch', 'plank', 'core', 'sit-up', 'sit up'],
      'cardio': ['cardio', 'run', 'jump', 'burpee', 'hiit', 'cycle'],
    };
    String? best;
    int bestScore = 0;
    rules.forEach((key, words) {
      var score = 0;
      for (final w in words) {
        if (text.contains(w)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        best = key;
      }
    });
    const fallback = ['chest', 'back', 'legs', 'shoulders', 'abs', 'biceps', 'cardio'];
    final idx = _weekDays.indexOf(dayName);
    best ??= fallback[(idx < 0 ? 0 : idx) % fallback.length];
    return 'assets/images/anatomy_mint/mint_$best.png';
  }

  /// Gradient day card (blue on even weekdays, coral on odd). A finished day
  /// keeps its colour; only the small status pill says it's done.
  /// built on the shared [GradientHeroCard].
  Widget _gradientDayShell({
    required String dayName,
    required List<String> exerciseNames,
    required bool isDone,
    required Widget child,
  }) {
    final idx = _weekDays.indexOf(dayName);
    final bool warm = idx >= 0 && idx.isOdd;
    return GradientHeroCard(
      tone: warm ? HeroTone.coral : HeroTone.teal,
      imageAsset: _anatomyAssetFor(exerciseNames, dayName),
      imageSize: 118.w,
      imageTop: 26.h,
      radius: AppRadius.hero.r,
      padding: EdgeInsets.all(14.w),
      child: child,
    );
  }

  Widget _buildActiveDayCard({
    required BuildContext context,
    required String dayName,
    required List<WorkoutModel> workouts,
    required bool isToday,
    required bool isCompleted,
    required bool isNextUp,
    String? restDayName,
    String? missedDayName,
    List<WorkoutModel>? missedWorkouts,
  }) {
    final exerciseNames = workouts
        .map((w) => w.name.replaceAll(RegExp(r'^\[\w+\]\s*'), '').trim())
        .toList();

    return _gradientDayShell(
      dayName: dayName,
      exerciseNames: exerciseNames,
      isDone: isCompleted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Status Chip + Estimated Meta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.flash_on_rounded,
                        size: 11.sp,
                        color: isCompleted ? ColorManager.successText : Colors.white,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          isCompleted
                              ? 'DONE TODAY'
                              : (isNextUp ? 'NEXT UP (TOMORROW)' : 'TODAY\'S TARGET'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              if (restDayName != null)
                Flexible(
                  child: Text(
                    'Today: $restDayName Rest',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 12.sp, fontWeight: FontWeight.w600),
                  ),
                )
              else
                Flexible(
                  child: Text(
                    '${workouts.length} Exercises · ~45 min',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white60, fontSize: 12.sp),
                  ),
                ),
            ],
          ),

          // Title & Focus
          Padding(
 padding: EdgeInsets.only(right: 84.w),
 child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$dayName Routine',
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              Text(
                isCompleted
                    ? 'All ${workouts.length} exercises logged. Streak extended! 🔥'
                    : 'Scheduled full session with animated rest timers & set logs.',
                style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
 ),

          // Exercise Pills Horizontal Wrap / Preview
          Padding(
 padding: EdgeInsets.only(right: 70.w),
 child: Wrap(
            spacing: 5.w,
            runSpacing: 4.h,
            children: [
              ...exerciseNames.take(3).map((name) => Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                ),
              )),
              if (exerciseNames.length > 3)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '+${exerciseNames.length - 3} more',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
 ),

          // Missed Workout Catch-Up Action (Non-destructive, opt-in)
          if (missedDayName != null &&
              missedWorkouts != null &&
              missedWorkouts.isNotEmpty &&
              !isCompleted &&
              missedDayName != dayName)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DayWorkoutSessionPage(
                      dayName: missedDayName,
                      workouts: missedWorkouts,
                    ),
                  ),
                ).then((_) {
                  _checkLocalCompletion();
                  if (mounted) setState(() {});
                });
              },
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                margin: EdgeInsets.only(bottom: 6.h),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: ColorManager.premium.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: ColorManager.premium.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history_toggle_off_rounded,
                        color: ColorManager.warningText, size: 14.sp),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: Text(
                        'Missed $missedDayName? Tap to resume missed workout',
                        style: TextStyle(
                          color: Colors.amber.shade200,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: ColorManager.warningText, size: 14.sp),
                  ],
                ),
              ),
            ),

          // Bottom Action Button
          SizedBox(
            width: double.infinity,
            height: 38.h,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DayWorkoutSessionPage(
                      dayName: dayName,
                      workouts: workouts,
                    ),
                  ),
                ).then((_) {
                  _checkLocalCompletion();
                  if (mounted) setState(() {});
                });
              },
              icon: Icon(
                isCompleted ? Icons.refresh_rounded : Icons.play_arrow_rounded,
                size: 16.sp,
                color: Colors.white,
              ),
              label: Text(
                isCompleted
                    ? 'Repeat $dayName Workout'
                    : (isNextUp ? 'Start $dayName Workout Early' : 'Start Workout Session'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                // Done: quiet outlined button. Not done: solid dark button.
                backgroundColor: isCompleted ? Colors.transparent : Colors.black.withValues(alpha: 0.35),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button.r),
                  side: isCompleted
                      ? const BorderSide(color: Colors.white38)
                      : BorderSide.none,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card 2: Standard Split Day Card (e.g. Wednesday or Monday)
  Widget _buildStandardSplitCard({
    required BuildContext context,
    required String dayName,
    required List<WorkoutModel> workouts,
    required bool isDone,
  }) {
    final exerciseNames = workouts
        .map((w) => w.name.replaceAll(RegExp(r'^\[\w+\]\s*'), '').trim())
        .toList();

    return _gradientDayShell(
      dayName: dayName,
      exerciseNames: exerciseNames,
      isDone: isDone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  isDone ? '✓ DONE' : 'SCHEDULED',
                  style: TextStyle(
                    color: isDone ? ColorManager.successLight : Colors.white70,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text('${workouts.length} Exercises', style: TextStyle(color: Colors.white60, fontSize: 12.sp)),
            ],
          ),

          Padding(
 padding: EdgeInsets.only(right: 84.w),
 child: Text(
            '$dayName Routine',
            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
 ),

          Padding(
 padding: EdgeInsets.only(right: 70.w),
 child: Wrap(
            spacing: 5.w,
            runSpacing: 4.h,
            children: [
              ...exerciseNames.take(3).map((name) => Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(name, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
              )),
              if (exerciseNames.length > 3)
                Text('+${exerciseNames.length - 3} more', style: TextStyle(color: Colors.white60, fontSize: 12.sp)),
            ],
          ),
 ),

          SizedBox(
            width: double.infinity,
            height: 36.h,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DayWorkoutSessionPage(
                      dayName: dayName,
                      workouts: workouts,
                    ),
                  ),
                ).then((_) {
                  _checkLocalCompletion();
                  if (mounted) setState(() {});
                });
              },
              icon: Icon(isDone ? Icons.refresh_rounded : Icons.play_arrow_rounded, size: 14.sp, color: Colors.white),
              label: Text(
                isDone ? 'Repeat Session' : 'Start $dayName Session',
                style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button.r)),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
