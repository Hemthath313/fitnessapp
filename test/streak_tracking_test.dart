import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/streak_calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Gym Buddy Schedule-Aware Workout Streak Policy Tests', () {
    test(
      '1. Planned rest days preserve current streak without incrementing (e.g., Sunday Rest after Mon/Wed/Fri)',
      () {
        final schedule = StatisticsProvider.parseWeekdayNames(
          ['Monday', 'Wednesday', 'Friday'],
        );

        // Completed Mon Oct 5, Wed Oct 7, Fri Oct 9
        final completed = [
          DateTime(2026, 10, 5, 18, 30),
          DateTime(2026, 10, 7, 19, 0),
          DateTime(2026, 10, 9, 17, 45),
        ];

        // Evaluate on Saturday Oct 10 (Planned Rest Day)
        final satStreak = StatisticsProvider.calculateCurrentStreak(
          completedDates: completed,
          scheduledWeekdays: schedule,
          referenceNow: DateTime(2026, 10, 10, 14, 0),
        );
        expect(satStreak, 3);

        // Evaluate on Sunday Oct 11 (Planned Rest Day — next workout Monday)
        final sunStreak = StatisticsProvider.calculateCurrentStreak(
          completedDates: completed,
          scheduledWeekdays: schedule,
          referenceNow: DateTime(2026, 10, 11, 9, 30),
        );
        expect(sunStreak, 3);
      },
    );

    test(
      '2. Pending scheduled workout day today does not reset streak prematurely, and increments once completed',
      () {
        final schedule = StatisticsProvider.parseWeekdayNames(
          ['Monday', 'Wednesday', 'Friday'],
        );

        final completedBeforeToday = [
          DateTime(2026, 10, 5, 18, 0),
          DateTime(2026, 10, 7, 18, 0),
          DateTime(2026, 10, 9, 18, 0),
        ];

        // Monday Oct 12 at 10:00 AM — scheduled workout not finished yet (pending)
        final pendingMondayStreak = StatisticsProvider.calculateCurrentStreak(
          completedDates: completedBeforeToday,
          scheduledWeekdays: schedule,
          referenceNow: DateTime(2026, 10, 12, 10, 0),
        );
        expect(pendingMondayStreak, 3);

        // Monday Oct 12 at 6:30 PM — workout completed today
        final completedMondayStreak = StatisticsProvider.calculateCurrentStreak(
          completedDates: [
            ...completedBeforeToday,
            DateTime(2026, 10, 12, 18, 30),
          ],
          scheduledWeekdays: schedule,
          referenceNow: DateTime(2026, 10, 12, 18, 35),
        );
        expect(completedMondayStreak, 4);
      },
    );

    test(
      '3. Missed scheduled workout day resets streak; workouts after a missed day start a fresh streak',
      () {
        final schedule = StatisticsProvider.parseWeekdayNames(
          ['Monday', 'Wednesday', 'Friday'],
        );

        // Completed Mon Oct 5 and Wed Oct 7, but MISSED Fri Oct 9
        final missedFridayDates = [
          DateTime(2026, 10, 5, 18, 0),
          DateTime(2026, 10, 7, 18, 0),
        ];

        // On Saturday Oct 10 (after missing Friday Oct 9), streak is 0
        final satAfterMissedFri = StatisticsProvider.calculateCurrentStreak(
          completedDates: missedFridayDates,
          scheduledWeekdays: schedule,
          referenceNow: DateTime(2026, 10, 10, 9, 0),
        );
        expect(satAfterMissedFri, 0);

        // If user missed Wed Oct 7, but completed Fri Oct 9, then on Sunday Oct 11 streak is 1 (just Friday)
        final recoveredOnFriday = [
          DateTime(2026, 10, 5, 18, 0), // Mon
          // Missed Wed Oct 7
          DateTime(2026, 10, 9, 18, 0), // Fri
        ];
        final sunAfterRecovery = StatisticsProvider.calculateCurrentStreak(
          completedDates: recoveredOnFriday,
          scheduledWeekdays: schedule,
          referenceNow: DateTime(2026, 10, 11, 11, 0),
        );
        expect(sunAfterRecovery, 1);

        final longest = StatisticsProvider.calculateLongestStreak(
          completedDates: recoveredOnFriday,
          scheduledWeekdays: schedule,
        );
        expect(longest, 1);
      },
    );

    test(
      '4. Does not use a fixed 3- or 4-day gap: 1-day/week schedule (6 planned rest days) preserves streak across full week',
      () {
        // User only trains on Saturdays (6 consecutive rest days Sun..Fri)
        final saturdayOnlySchedule =
            StatisticsProvider.parseWeekdayNames(['Saturday']);

        final completedSaturdays = [
          DateTime(2026, 9, 26, 10, 0), // Saturday 1
          DateTime(2026, 10, 3, 10, 0), // Saturday 2
        ];

        // Check on Friday Oct 9 (6 days since last workout on Oct 3 — all 6 are planned rest days)
        final fridayStreak = StatisticsProvider.calculateCurrentStreak(
          completedDates: completedSaturdays,
          scheduledWeekdays: saturdayOnlySchedule,
          referenceNow: DateTime(2026, 10, 9, 20, 0),
        );
        expect(fridayStreak, 2);

        // Check on Saturday Oct 10 morning before workout (pending scheduled day)
        final satMorningStreak = StatisticsProvider.calculateCurrentStreak(
          completedDates: completedSaturdays,
          scheduledWeekdays: saturdayOnlySchedule,
          referenceNow: DateTime(2026, 10, 10, 8, 0),
        );
        expect(satMorningStreak, 2);

        // If Saturday Oct 10 is missed, on Sunday Oct 11 streak breaks to 0
        final sunAfterMissedSat = StatisticsProvider.calculateCurrentStreak(
          completedDates: completedSaturdays,
          scheduledWeekdays: saturdayOnlySchedule,
          referenceNow: DateTime(2026, 10, 11, 8, 0),
        );
        expect(sunAfterMissedSat, 0);
      },
    );

    test(
      '5. Free and Premium users achieve identical streaks across manual logs, predefined plans, and AI workouts',
      () {
        final freeUserStats = StatisticsProvider();
        final premiumUserStats = StatisticsProvider();

        final workoutDates = [
          DateTime(2026, 10, 5, 7, 30), // Manual exercise log (Free user) / Session (Premium)
          DateTime(2026, 10, 6, 18, 0),
          DateTime(2026, 10, 8, 18, 15),
          DateTime(2026, 10, 9, 17, 45),
        ];
        const fourDaySplit = ['Monday', 'Tuesday', 'Thursday', 'Friday'];
        final sundayRest = DateTime(2026, 10, 11, 10, 0);

        // Free user with selected training days and manual/predefined workout sessions
        freeUserStats.configureStreakStateForTesting(
          completedDates: workoutDates,
          scheduledDays: fourDaySplit,
          referenceNow: sundayRest,
        );

        // Premium user with AI-generated 4-day split
        premiumUserStats.configureStreakStateForTesting(
          completedDates: workoutDates,
          scheduledDays: fourDaySplit,
          referenceNow: sundayRest,
        );

        expect(freeUserStats.currentStreak, 4);
        expect(premiumUserStats.currentStreak, 4);
        expect(freeUserStats.longestStreak, 4);
        expect(premiumUserStats.longestStreak, 4);
        expect(freeUserStats.isRestDay(sundayRest), isTrue);
        expect(freeUserStats.isMaintainingStreak, isTrue);

        // Free user with NO schedule logging consecutive manual workouts (Yesterday & Today)
        final unscheduledFreeUser = StatisticsProvider();
        unscheduledFreeUser.configureStreakStateForTesting(
          completedDates: [
            DateTime(2026, 10, 10, 18, 0),
            DateTime(2026, 10, 11, 9, 0),
          ],
          scheduledDays: const [],
          referenceNow: sundayRest,
        );
        expect(unscheduledFreeUser.hasActiveSchedule, isFalse);
        expect(unscheduledFreeUser.currentStreak, 2);
      },
    );

    test(
      '6. Deduplicates multiple workout sessions and legacy records on the same local calendar day',
      () {
        final schedule = StatisticsProvider.parseWeekdayNames(
          ['Monday', 'Wednesday', 'Friday'],
        );

        // Multiple sessions/logs recorded on Monday Oct 5 and Wednesday Oct 7
        final duplicateRecords = [
          DateTime(2026, 10, 5, 7, 0), // Morning session
          DateTime(2026, 10, 5, 7, 0), // Exact duplicate from finishedWorkoutsData
          DateTime(2026, 10, 5, 18, 30), // Evening manual exercise log
          DateTime(2026, 10, 7, 12, 15), // Wed session
          DateTime(2026, 10, 7, 19, 45), // Wed second log
        ];

        final deduped =
            StatisticsProvider.normalizeAndDeduplicateDates(duplicateRecords);
        expect(deduped.length, 2);

        final streak = StatisticsProvider.calculateCurrentStreak(
          completedDates: duplicateRecords,
          scheduledWeekdays: schedule,
          referenceNow: DateTime(2026, 10, 8, 10, 0), // Thursday rest day
        );
        expect(streak, 2);
      },
    );

    test(
      '7. Preserves valid stored streak when today is a rest day or pending day, without overwriting with zero',
      () {
        final schedule = StatisticsProvider.parseWeekdayNames(
          ['Monday', 'Wednesday', 'Friday'],
        );

        // Stored streak is 6 with lastWorkoutDate = Friday Oct 9, evaluated on Sunday Oct 11 (Rest Day)
        final preservedOnRestDay = StatisticsProvider.calculateCurrentStreak(
          completedDates: [DateTime(2026, 10, 9, 18, 0)],
          scheduledWeekdays: schedule,
          storedStreak: 6,
          lastWorkoutDate: DateTime(2026, 10, 9, 18, 0),
          referenceNow: DateTime(2026, 10, 11, 9, 0),
        );
        expect(preservedOnRestDay, 6);

        // Evaluated on Monday Oct 12 before workout (pending scheduled day) -> still preserved as 6
        final preservedOnPendingDay = StatisticsProvider.calculateCurrentStreak(
          completedDates: [DateTime(2026, 10, 9, 18, 0)],
          scheduledWeekdays: schedule,
          storedStreak: 6,
          lastWorkoutDate: DateTime(2026, 10, 9, 18, 0),
          referenceNow: DateTime(2026, 10, 12, 9, 0),
        );
        expect(preservedOnPendingDay, 6);

        // Evaluated on Monday Oct 12 AFTER completing Monday's workout -> increments to 7!
        final incrementedAfterTodayWorkout =
            StatisticsProvider.calculateCurrentStreak(
          completedDates: [
            DateTime(2026, 10, 9, 18, 0),
            DateTime(2026, 10, 12, 18, 0),
          ],
          scheduledWeekdays: schedule,
          storedStreak: 6,
          lastWorkoutDate: DateTime(2026, 10, 9, 18, 0),
          referenceNow: DateTime(2026, 10, 12, 19, 0),
        );
        expect(incrementedAfterTodayWorkout, 7);
      },
    );

    test(
      '8. Date, month, year, and UTC timezone boundaries normalize accurately without off-by-one errors',
      () {
        final schedule = StatisticsProvider.parseWeekdayNames(
          ['Monday', 'Wednesday', 'Friday'],
        );

        // Cross-month & cross-year boundary:
        // Mon Dec 28, 2026 -> Wed Dec 30, 2026 -> Fri Jan 1, 2027
        // Evaluated on Sun Jan 3, 2027 (Rest day)
        final crossYearDates = [
          DateTime(2026, 12, 28, 20, 0),
          DateTime(2026, 12, 30, 21, 30),
          DateTime(2027, 1, 1, 11, 0),
        ];

        final crossYearStreak = StatisticsProvider.calculateCurrentStreak(
          completedDates: crossYearDates,
          scheduledWeekdays: schedule,
          referenceNow: DateTime(2027, 1, 3, 10, 0),
        );
        expect(crossYearStreak, 3);

        // UTC timestamp conversion to local calendar day deduplicates with local timestamp on same day
        final localEvening = DateTime(2026, 10, 9, 23, 30);
        final utcEquivalent = localEvening.toUtc();
        final dedupedUtcAndLocal =
            StatisticsProvider.normalizeAndDeduplicateDates(
          [localEvening, utcEquivalent],
        );
        expect(dedupedUtcAndLocal.length, 1);
        expect(
          dedupedUtcAndLocal.first,
          DateTime(localEvening.year, localEvening.month, localEvening.day),
        );
      },
    );

    test(
      '9. Empty history and no schedule yields 0 streak and first-workout empty state flags',
      () {
        final stats = StatisticsProvider();
        stats.configureStreakStateForTesting(
          completedDates: const [],
          scheduledDays: const [],
          referenceNow: DateTime(2026, 10, 11, 10, 0),
        );

        expect(stats.currentStreak, 0);
        expect(stats.longestStreak, 0);
        expect(stats.hasActiveSchedule, isFalse);
        expect(stats.hasWorkoutHistory, isFalse);
        expect(stats.isMaintainingStreak, isFalse);
      },
    );

    testWidgets(
      '10. StreakCalendarWidget displays first-workout empty state when no schedule/history, and rest-day preserved state on Sunday Rest',
      (WidgetTester tester) async {
        final stats = StatisticsProvider();
        stats.configureStreakStateForTesting(
          completedDates: const [],
          scheduledDays: const [],
        );

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => ChangeNotifierProvider<StatisticsProvider>.value(
              value: stats,
              child: const MaterialApp(
                home: Scaffold(
                  body: StreakCalendarWidget(),
                ),
              ),
            ),
          ),
        );

        // Verify empty state messaging
        expect(find.text('Start Your First Workout'), findsOneWidget);
        expect(
          find.text('Complete your first workout to start a streak'),
          findsOneWidget,
        );

        // Now configure active 3-day split with completed workouts on Mon, Wed, Fri
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        // Schedule all weekdays EXCEPT today so today is guaranteed to be a planned rest day
        const allDays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        final todayName = allDays[today.weekday - 1];
        final restTodaySchedule =
            allDays.where((d) => d != todayName).toList();
        final yesterday = DateTime(today.year, today.month, today.day - 1);
        final twoDaysAgo = DateTime(today.year, today.month, today.day - 2);

        stats.configureStreakStateForTesting(
          completedDates: [twoDaysAgo, yesterday],
          scheduledDays: restTodaySchedule,
          referenceNow: today,
        );
        await tester.pump();

        expect(find.text('2 Day Streak!'), findsOneWidget);
        expect(
          find.text('Planned rest day — streak preserved!'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '11. Regression: Free-user schedule persists through startup sync, resetWeeklyTarget, and widget builds when split is empty',
      (WidgetTester tester) async {
        final stats = StatisticsProvider();
        final sunOct11 = DateTime(2026, 10, 11, 10, 0);

        // Free user selects Mon/Wed/Fri and completes Mon Oct 5, Wed Oct 7, Fri Oct 9
        stats.configureStreakStateForTesting(
          completedDates: [
            DateTime(2026, 10, 5, 18, 0),
            DateTime(2026, 10, 7, 18, 0),
            DateTime(2026, 10, 9, 18, 0),
          ],
          scheduledDays: const ['Monday', 'Wednesday', 'Friday'],
          referenceNow: sunOct11,
        );
        await tester.pump();

        expect(stats.hasActiveSchedule, isTrue);
        expect(
          stats.scheduledDayNames,
          equals(['Monday', 'Wednesday', 'Friday']),
        );
        expect(stats.currentStreak, 3);

        // Simulate MainPage startup sync where free user has an empty premium AI split (groupedSplitWorkouts.keys is empty)
        stats.syncSplitSchedule(const []);
        stats.resetWeeklyTarget();
        await tester.pump();

        // Schedule and streak must NOT be wiped
        expect(stats.hasActiveSchedule, isTrue);
        expect(
          stats.scheduledDayNames,
          equals(['Monday', 'Wednesday', 'Friday']),
        );
        expect(stats.weeklyTarget, 3);
        expect(stats.currentStreak, 3);

        // Verify SharedPreferences still holds scheduled_workout_days and a fresh provider restores it
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getStringList('scheduled_workout_days'),
          equals(['Monday', 'Wednesday', 'Friday']),
        );

        final restoredStats = StatisticsProvider();
        await restoredStats.restoreSavedScheduleFromPrefs();
        expect(restoredStats.hasActiveSchedule, isTrue);
        expect(
          restoredStats.scheduledDayNames,
          equals(['Monday', 'Wednesday', 'Friday']),
        );

        // Build StreakCalendarWidget with the free-user provider state
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) =>
                ChangeNotifierProvider<StatisticsProvider>.value(
              value: stats,
              child: const MaterialApp(
                home: Scaffold(
                  body: StreakCalendarWidget(),
                ),
              ),
            ),
          ),
        );

        expect(find.text('3 Day Streak!'), findsOneWidget);
        expect(stats.hasActiveSchedule, isTrue);
      },
    );

    test(
      '12. Regression: Stored streak is invalidated after a missed scheduled day and resets to 1 on recovery',
      () {
        final schedule = StatisticsProvider.parseWeekdayNames(
          ['Monday', 'Wednesday', 'Friday'],
        );
        final fridayOct9 = DateTime(2026, 10, 9, 18, 0);

        // User had storedStreak = 6 as of Friday Oct 9, then missed scheduled Monday Oct 12.
        // Calculation runs on Tuesday Oct 13 -> old streak (6) MUST NOT be preserved; result must be 0.
        final tuesdayAfterMissedMonday =
            StatisticsProvider.calculateCurrentStreak(
          completedDates: [fridayOct9],
          scheduledWeekdays: schedule,
          storedStreak: 6,
          lastWorkoutDate: fridayOct9,
          referenceNow: DateTime(2026, 10, 13, 10, 0),
        );
        expect(tuesdayAfterMissedMonday, 0);

        // User then completes Wednesday Oct 14 after missing Monday Oct 12 -> new streak must be 1 (not 6 or 7).
        final wednesdayOct14 = DateTime(2026, 10, 14, 18, 30);
        final wednesdayRecoveryStreak =
            StatisticsProvider.calculateCurrentStreak(
          completedDates: [fridayOct9, wednesdayOct14],
          scheduledWeekdays: schedule,
          storedStreak: 6,
          lastWorkoutDate: fridayOct9,
          referenceNow: DateTime(2026, 10, 14, 19, 0),
        );
        expect(wednesdayRecoveryStreak, 1);
      },
    );

    test(
      '13. Regression: Unanchored storedStreak with only today in completedDates and lastWorkoutDate null or today returns 1, not 5',
      () {
        final schedule = StatisticsProvider.parseWeekdayNames(
          ['Monday', 'Wednesday', 'Friday'],
        );
        final today = DateTime(2026, 10, 12, 18, 0);

        // Case A: storedStreak = 5, completedDates = [today], lastWorkoutDate = null
        final streakWithNullLastDate =
            StatisticsProvider.calculateCurrentStreak(
          completedDates: [today],
          scheduledWeekdays: schedule,
          storedStreak: 5,
          lastWorkoutDate: null,
          referenceNow: today,
        );
        expect(streakWithNullLastDate, 1);

        // Case B: storedStreak = 5, completedDates = [today], lastWorkoutDate = today
        final streakWithTodayLastDate =
            StatisticsProvider.calculateCurrentStreak(
          completedDates: [today],
          scheduledWeekdays: schedule,
          storedStreak: 5,
          lastWorkoutDate: today,
          referenceNow: today,
        );
        expect(streakWithTodayLastDate, 1);

        // Case C: storedStreak = 5, completedDates = [], lastWorkoutDate = null
        final streakWithEmptyHistory =
            StatisticsProvider.calculateCurrentStreak(
          completedDates: const [],
          scheduledWeekdays: schedule,
          storedStreak: 5,
          lastWorkoutDate: null,
          referenceNow: today,
        );
        expect(streakWithEmptyHistory, 0);
      },
    );

    test(
      '14. Regression: Bonus workout on a planned rest day increments streak once for that date and preserves across next rest day',
      () {
        final schedule = StatisticsProvider.parseWeekdayNames(
          ['Monday', 'Wednesday', 'Friday'],
        );

        // Completed Mon Oct 5, Wed Oct 7, Fri Oct 9 (3 scheduled days)
        // Plus two bonus sessions on Saturday Oct 10 (a planned rest day)
        final datesWithSaturdayBonus = [
          DateTime(2026, 10, 5, 18, 0), // Mon
          DateTime(2026, 10, 7, 18, 0), // Wed
          DateTime(2026, 10, 9, 18, 0), // Fri
          DateTime(2026, 10, 10, 10, 0), // Sat bonus session 1 (Rest Day)
          DateTime(2026, 10, 10, 17, 30), // Sat bonus session 2 (same day duplicate)
        ];

        // On Saturday Oct 10, streak increments once for Saturday -> 4 (not 5)
        final satStreak = StatisticsProvider.calculateCurrentStreak(
          completedDates: datesWithSaturdayBonus,
          scheduledWeekdays: schedule,
          referenceNow: DateTime(2026, 10, 10, 20, 0),
        );
        expect(satStreak, 4);

        // On Sunday Oct 11 (Rest Day), streak of 4 is preserved
        final sunStreak = StatisticsProvider.calculateCurrentStreak(
          completedDates: datesWithSaturdayBonus,
          scheduledWeekdays: schedule,
          referenceNow: DateTime(2026, 10, 11, 11, 0),
        );
        expect(sunStreak, 4);
      },
    );

    test(
      '15. Regression: Changing training schedule preserves verified streak and applies new schedule prospectively',
      () {
        final stats = StatisticsProvider();
        final sunOct11 = DateTime(2026, 10, 11, 12, 0);

        // User starts on Mon/Wed/Fri and completes all 3 workouts in the week
        stats.configureStreakStateForTesting(
          completedDates: [
            DateTime(2026, 10, 5, 18, 0), // Mon
            DateTime(2026, 10, 7, 18, 0), // Wed
            DateTime(2026, 10, 9, 18, 0), // Fri
          ],
          scheduledDays: const ['Monday', 'Wednesday', 'Friday'],
          referenceNow: sunOct11,
        );
        expect(stats.currentStreak, 3);

        // On Sunday Oct 11, user switches schedule to Tue/Thu/Sat.
        // Historical Tue Oct 6, Thu Oct 8, Sat Oct 10 must NOT retroactively break the 3-day streak!
        stats.updateScheduledDays(
          const ['Tuesday', 'Thursday', 'Saturday'],
          effectiveDate: sunOct11,
        );
        expect(stats.currentStreak, 3);
        expect(
          stats.scheduledDayNames,
          equals(['Tuesday', 'Thursday', 'Saturday']),
        );

        // On Tuesday Oct 13 morning (pending under new schedule), streak is still 3
        final pendingTueStreak = StatisticsProvider.calculateCurrentStreak(
          completedDates: stats.completedWorkoutDates,
          scheduledWeekdays: stats.scheduledWeekdays,
          previousScheduledWeekdays:
              StatisticsProvider.parseWeekdayNames(['Monday', 'Wednesday', 'Friday']),
          scheduleEffectiveDate: sunOct11,
          streakAtScheduleChange: 3,
          lastWorkoutDate: DateTime(2026, 10, 9, 18, 0),
          referenceNow: DateTime(2026, 10, 13, 9, 0),
        );
        expect(pendingTueStreak, 3);

        // Completing Tuesday Oct 13 increments streak to 4
        final completedTueStreak = StatisticsProvider.calculateCurrentStreak(
          completedDates: [
            ...stats.completedWorkoutDates,
            DateTime(2026, 10, 13, 18, 0),
          ],
          scheduledWeekdays: stats.scheduledWeekdays,
          previousScheduledWeekdays:
              StatisticsProvider.parseWeekdayNames(['Monday', 'Wednesday', 'Friday']),
          scheduleEffectiveDate: sunOct11,
          streakAtScheduleChange: 3,
          lastWorkoutDate: DateTime(2026, 10, 9, 18, 0),
          referenceNow: DateTime(2026, 10, 13, 19, 0),
        );
        expect(completedTueStreak, 4);

        // Missing Tuesday Oct 13 and evaluating on Wednesday Oct 14 breaks the streak to 0 (prospective enforcement)
        final missedProspectiveTueStreak =
            StatisticsProvider.calculateCurrentStreak(
          completedDates: stats.completedWorkoutDates,
          scheduledWeekdays: stats.scheduledWeekdays,
          previousScheduledWeekdays:
              StatisticsProvider.parseWeekdayNames(['Monday', 'Wednesday', 'Friday']),
          scheduleEffectiveDate: sunOct11,
          streakAtScheduleChange: 3,
          lastWorkoutDate: DateTime(2026, 10, 9, 18, 0),
          referenceNow: DateTime(2026, 10, 14, 9, 0),
        );
        expect(missedProspectiveTueStreak, 0);
      },
    );

    test(
      '16. Regression: Empty workout history clears stale non-zero in-memory streak state',
      () {
        final stats = StatisticsProvider();

        // Seed provider with an active 3-day streak
        stats.configureStreakStateForTesting(
          completedDates: [
            DateTime(2026, 10, 5, 18, 0),
            DateTime(2026, 10, 7, 18, 0),
            DateTime(2026, 10, 9, 18, 0),
          ],
          scheduledDays: const ['Monday', 'Wednesday', 'Friday'],
          referenceNow: DateTime(2026, 10, 11, 10, 0),
        );
        expect(stats.currentStreak, 3);
        expect(stats.hasWorkoutHistory, isTrue);

        // Now reconcile with empty history even when a stale storedStreak = 5 is passed
        stats.configureStreakStateForTesting(
          completedDates: const [],
          scheduledDays: const ['Monday', 'Wednesday', 'Friday'],
          storedStreak: 5,
          lastWorkoutDate: null,
          referenceNow: DateTime(2026, 10, 11, 10, 0),
        );

        expect(stats.currentStreak, 0);
        expect(stats.totalWorkouts, 0);
        expect(stats.lastWorkoutDate, isNull);
        expect(stats.hasWorkoutHistory, isFalse);
        expect(stats.isMaintainingStreak, isFalse);
      },
    );

    test(
      '17. Regression: Full lifecycle — First workout (1) -> rest/pending (1) -> missed scheduled day (0) -> recovery workout (1)',
      () {
        final schedule = StatisticsProvider.parseWeekdayNames(
          ['Monday', 'Wednesday', 'Friday'],
        );

        // Step 0: Empty history -> 0
        expect(
          StatisticsProvider.calculateCurrentStreak(
            completedDates: const [],
            scheduledWeekdays: schedule,
            referenceNow: DateTime(2026, 10, 5, 9, 0),
          ),
          0,
        );

        // Step 1: First workout completed on Monday Oct 5 -> 1
        final monOct5 = DateTime(2026, 10, 5, 18, 0);
        expect(
          StatisticsProvider.calculateCurrentStreak(
            completedDates: [monOct5],
            scheduledWeekdays: schedule,
            referenceNow: DateTime(2026, 10, 5, 19, 0),
          ),
          1,
        );

        // Step 2: Preserved on Tuesday Oct 6 rest day (1) and Wednesday Oct 7 morning pending (1)
        expect(
          StatisticsProvider.calculateCurrentStreak(
            completedDates: [monOct5],
            scheduledWeekdays: schedule,
            referenceNow: DateTime(2026, 10, 6, 12, 0),
          ),
          1,
        );
        expect(
          StatisticsProvider.calculateCurrentStreak(
            completedDates: [monOct5],
            scheduledWeekdays: schedule,
            referenceNow: DateTime(2026, 10, 7, 9, 0),
          ),
          1,
        );

        // Step 3: User misses Wednesday Oct 7 -> evaluated on Thursday Oct 8 -> resets to 0
        expect(
          StatisticsProvider.calculateCurrentStreak(
            completedDates: [monOct5],
            scheduledWeekdays: schedule,
            storedStreak: 1,
            lastWorkoutDate: monOct5,
            referenceNow: DateTime(2026, 10, 8, 9, 0),
          ),
          0,
        );

        // Step 4: User completes recovery workout on Friday Oct 9 -> streak is 1 on Friday and Sunday rest day
        final friOct9 = DateTime(2026, 10, 9, 18, 0);
        expect(
          StatisticsProvider.calculateCurrentStreak(
            completedDates: [monOct5, friOct9],
            scheduledWeekdays: schedule,
            storedStreak: 1,
            lastWorkoutDate: monOct5,
            referenceNow: DateTime(2026, 10, 9, 19, 0),
          ),
          1,
        );
        expect(
          StatisticsProvider.calculateCurrentStreak(
            completedDates: [monOct5, friOct9],
            scheduledWeekdays: schedule,
            storedStreak: 1,
            lastWorkoutDate: friOct9,
            referenceNow: DateTime(2026, 10, 11, 10, 0),
          ),
          1,
        );
      },
    );
  });
}
