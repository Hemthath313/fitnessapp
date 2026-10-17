import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/workout_tools/plate_calculator_sheet.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/services/notification_service.dart';
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

  void _showOneRepMaxDialog(BuildContext context) {
    final weightController = TextEditingController(text: '80');
    final repsController = TextEditingController(text: '8');
    double estimatedMax = 80.0 * (1.0 + 8.0 / 30.0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: ColorManager.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            title: Row(
              children: [
                Icon(Icons.speed_rounded, color: ColorManager.primary, size: 24.sp),
                SizedBox(width: 8.w),
                Text('1-Rep Max Estimator', style: TextStyle(color: ColorManager.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calculate your maximum single-rep strength using the Epley formula.',
                  style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: ColorManager.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          labelStyle: TextStyle(color: ColorManager.textTertiary),
                          filled: true,
                          fillColor: ColorManager.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                        ),
                        onChanged: (_) {
                          final w = double.tryParse(weightController.text) ?? 0;
                          final r = double.tryParse(repsController.text) ?? 1;
                          setModalState(() {
                            estimatedMax = w * (1.0 + r / 30.0);
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: repsController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: ColorManager.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Reps Completed',
                          labelStyle: TextStyle(color: ColorManager.textTertiary),
                          filled: true,
                          fillColor: ColorManager.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                        ),
                        onChanged: (_) {
                          final w = double.tryParse(weightController.text) ?? 0;
                          final r = double.tryParse(repsController.text) ?? 1;
                          setModalState(() {
                            estimatedMax = w * (1.0 + r / 30.0);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text('ESTIMATED 1-REP MAX', style: TextStyle(color: ColorManager.primary, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                      SizedBox(height: 4.h),
                      Text('${estimatedMax.toStringAsFixed(1)} kg', style: TextStyle(color: ColorManager.white, fontSize: 24.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Done', style: TextStyle(color: ColorManager.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

        if (grouped.isEmpty) {
          return _buildNoPlanCard(context);
        }

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
      },
    );
  }

  /// Empty State: No Plan Active -> Invite user to review and activate their personalized plan
  Widget _buildNoPlanCard(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider?>(context);
    final stats = Provider.of<StatisticsProvider?>(context);
    final userGoal = homeProvider?.userData['goal']?.toString();
    final bool hasOnboardingGoal = userGoal != null && userGoal.isNotEmpty;
    final bool hasExistingSchedule = stats != null && stats.hasActiveSchedule;

    final String title = hasOnboardingGoal
        ? 'Activate Your $userGoal Plan'
        : 'Build Your AI Workout Plan';
    final String subtitle = hasOnboardingGoal
        ? 'We prepared an adaptive starter split tailored to your goal ($userGoal). Review your schedule and tap to activate.'
        : 'Choose 3 to 6 days per week with smart exercises, rest timers, and video guides.';
    final String buttonLabel = hasOnboardingGoal
        ? 'Review & Activate Plan'
        : 'Build My Plan with AI';

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
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
                        Flexible(
                          child: Text(
                            hasOnboardingGoal
                                ? 'PERSONALIZED FOR YOU'
                                : 'AI WORKOUT ROUTINE',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  hasExistingSchedule
                      ? '${stats.scheduledDayNames.length}-Day Schedule'
                      : '3-6 Day Splits',
                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                color: ColorManager.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
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
                  buttonLabel,
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
    scrollerCards.add(_buildAiCustomizerCard(context, sortedDays));

    // Card: Pro Workout Toolkit (Plate Math + 1RM)
    scrollerCards.add(_buildProToolkitCard(context));

    // Card: Adaptive Strength Partner & PR Vault
    scrollerCards.add(_buildStrengthPartnerCard(context));

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
                        Icon(Icons.auto_awesome, color: ColorManager.primary, size: 16.sp),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            'AI Workout Schedule',
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
                icon: Icon(Icons.refresh_rounded, size: 13.sp, color: Colors.black),
                label: Text(
                  'Re-plan',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11.sp,
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

        // 3. Compact Horizontal Scroller Deck (~204.h)
        SizedBox(
          height: 204.h,
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
          borderRadius: BorderRadius.circular(12.r),
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
              bgColor = hasWorkout && isCompletedToday
                  ? const Color(0xFF1E4331)
                  : Colors.blueAccent.withValues(alpha: 0.18);
              textColor = hasWorkout && isCompletedToday
                  ? const Color(0xFF81C784)
                  : Colors.blueAccent;
              border = Border.all(
                color: hasWorkout && isCompletedToday ? const Color(0xFF4CAF50) : Colors.blueAccent,
                width: 1,
              );
            } else if (isDayDone) {
              bgColor = const Color(0xFF1E4331).withValues(alpha: 0.5);
              textColor = const Color(0xFF81C784);
              border = Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.6), width: 1);
            } else if (isNext) {
              bgColor = ColorManager.primary.withValues(alpha: 0.15);
              textColor = ColorManager.primary;
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
                        fontSize: 10.sp,
                        fontWeight: isToday || isNext || hasWorkout || isDayDone ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    if (isToday && !hasWorkout)
                      Text('REST', style: TextStyle(color: Colors.blueAccent, fontSize: 8.sp, fontWeight: FontWeight.bold))
                    else if (isDayDone)
                      Text('DONE', style: TextStyle(color: const Color(0xFF81C784), fontSize: 8.sp, fontWeight: FontWeight.bold))
                    else if (isNext)
                      Text('NEXT', style: TextStyle(color: ColorManager.primary, fontSize: 8.sp, fontWeight: FontWeight.bold))
                    else if (hasWorkout)
                      Text('${grouped[day]!.length}ex', style: TextStyle(color: ColorManager.textTertiary, fontSize: 8.sp))
                    else
                      Text('—', style: TextStyle(color: Colors.white24, fontSize: 8.sp)),
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

    return Container(
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF4CAF50).withValues(alpha: 0.6)
              : ColorManager.primary.withValues(alpha: 0.6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? const Color(0xFF4CAF50) : ColorManager.primary).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(14.w),
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
                    color: isCompleted
                        ? const Color(0xFF1E4331)
                        : ColorManager.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                          : ColorManager.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.flash_on_rounded,
                        size: 11.sp,
                        color: isCompleted ? const Color(0xFF4CAF50) : ColorManager.primary,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          isCompleted
                              ? 'COMPLETED TODAY ✓'
                              : (isNextUp ? 'NEXT UP (TOMORROW)' : 'TODAY\'S TARGET'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCompleted ? const Color(0xFF81C784) : ColorManager.primary,
                            fontSize: 9.sp,
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
                    style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 10.sp, fontWeight: FontWeight.w600),
                  ),
                )
              else
                Flexible(
                  child: Text(
                    '${workouts.length} Exercises · ~45 min',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ColorManager.textTertiary, fontSize: 10.sp),
                  ),
                ),
            ],
          ),

          // Title & Focus
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$dayName Routine',
                style: TextStyle(color: ColorManager.white, fontSize: 17.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              Text(
                isCompleted
                    ? 'All ${workouts.length} exercises logged. Streak extended! 🔥'
                    : 'Scheduled full session with animated rest timers & set logs.',
                style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          // Exercise Pills Horizontal Wrap / Preview
          Wrap(
            spacing: 5.w,
            runSpacing: 4.h,
            children: [
              ...exerciseNames.take(3).map((name) => Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF1E4331) : ColorManager.surfaceDark,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: ColorManager.divider),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: isCompleted ? const Color(0xFFE8F5E9) : ColorManager.textSecondary,
                    fontSize: 10.sp,
                  ),
                ),
              )),
              if (exerciseNames.length > 3)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: ColorManager.surfaceDark,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '+${exerciseNames.length - 3} more',
                    style: TextStyle(color: ColorManager.primary, fontSize: 10.sp, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
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
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history_toggle_off_rounded,
                        color: Colors.amber, size: 14.sp),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: Text(
                        'Missed $missedDayName? Tap to resume missed workout',
                        style: TextStyle(
                          color: Colors.amber.shade200,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.amber, size: 14.sp),
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
                color: isCompleted ? Colors.white : Colors.black,
              ),
              label: Text(
                isCompleted
                    ? 'Repeat $dayName Workout'
                    : (isNextUp ? 'Start $dayName Workout Early' : 'Start Workout Session'),
                style: TextStyle(
                  color: isCompleted ? Colors.white : Colors.black,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? const Color(0xFF2E7D32) : ColorManager.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
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

    return Container(
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: isDone ? const Color(0xFF4CAF50).withValues(alpha: 0.4) : ColorManager.divider),
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFF1E4331) : ColorManager.surfaceDark,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  isDone ? 'COMPLETED ✓' : 'SCHEDULED',
                  style: TextStyle(
                    color: isDone ? const Color(0xFF81C784) : ColorManager.textTertiary,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text('${workouts.length} Exercises', style: TextStyle(color: ColorManager.textTertiary, fontSize: 10.sp)),
            ],
          ),

          Text(
            '$dayName Routine',
            style: TextStyle(color: ColorManager.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),

          Wrap(
            spacing: 5.w,
            runSpacing: 4.h,
            children: [
              ...exerciseNames.take(3).map((name) => Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: ColorManager.surfaceDark,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(name, style: TextStyle(color: ColorManager.textSecondary, fontSize: 10.sp)),
              )),
              if (exerciseNames.length > 3)
                Text('+${exerciseNames.length - 3} more', style: TextStyle(color: ColorManager.textTertiary, fontSize: 10.sp)),
            ],
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
              icon: Icon(Icons.play_arrow_rounded, size: 14.sp, color: ColorManager.textPrimary),
              label: Text(
                isDone ? 'Repeat Session' : 'Start $dayName Session',
                style: TextStyle(color: ColorManager.textPrimary, fontSize: 11.sp, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ColorManager.divider),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card 3: AI Split Customizer & Re-plan Card
  Widget _buildAiCustomizerCard(BuildContext context, List<String> activeDays) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorManager.surfaceDark,
            ColorManager.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: ColorManager.primary, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                'AI Routine Customizer',
                style: TextStyle(color: ColorManager.primary, fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            'Change frequency, target goal, or equipment in seconds.',
            style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
          ),
          Wrap(
            spacing: 6.w,
            children: [
              _buildFeatureBadge('${activeDays.length} Days Active'),
              _buildFeatureBadge('Full Equipment'),
              _buildFeatureBadge('Hypertrophy'),
            ],
          ),
          SizedBox(
            width: double.infinity,
            height: 36.h,
            child: ElevatedButton.icon(
              onPressed: () => context.push(Routes.workoutGeneratorRoute),
              icon: Icon(Icons.flash_on_rounded, size: 14.sp, color: Colors.black),
              label: Text('Re-generate Split with AI', style: TextStyle(color: Colors.black, fontSize: 11.sp, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card 4: Pro Lifting Tools Card (Plate Calculator + 1RM Estimator)
  Widget _buildProToolkitCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                'Lifting Tools & Calculators',
                style: TextStyle(color: Colors.amber, fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            'Avoid gym math. Visual barbell loading and 1-rep max calculator.',
            style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => PlateCalculatorSheet.show(context),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: ColorManager.surfaceDark,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: ColorManager.divider),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.fitness_center_rounded, color: ColorManager.primary, size: 16.sp),
                        SizedBox(height: 3.h),
                        Text('Plate Math', style: TextStyle(color: ColorManager.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                        Text('Olympic Bar', style: TextStyle(color: ColorManager.textTertiary, fontSize: 8.sp)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: InkWell(
                  onTap: () => _showOneRepMaxDialog(context),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: ColorManager.surfaceDark,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: ColorManager.divider),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.speed_rounded, color: Colors.amber, size: 16.sp),
                        SizedBox(height: 3.h),
                        Text('1RM Calc', style: TextStyle(color: ColorManager.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                        Text('Max Strength', style: TextStyle(color: ColorManager.textTertiary, fontSize: 8.sp)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card 5: Strength & PR Vault Partner
  Widget _buildStrengthPartnerCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: ColorManager.primary.withOpacity(0.35)),
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Strength Partner & PRs',
                    style: TextStyle(color: ColorManager.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: ColorManager.textTertiary, size: 12.sp),
            ],
          ),
          Text(
            'Track your Estimated 1RMs, progressive overload benchmarks, and PR vault.',
            style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
          ),
          InkWell(
            onTap: () => context.push(Routes.strengthAnalyticsRoute),
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: ColorManager.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, color: ColorManager.primary, size: 14.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Open PR Vault & Analytics',
                    style: TextStyle(color: ColorManager.primary, fontSize: 11.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Text(text, style: TextStyle(color: ColorManager.textSecondary, fontSize: 9.sp)),
    );
  }
}
