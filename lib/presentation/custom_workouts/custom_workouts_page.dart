import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CustomWorkoutsPage extends StatefulWidget {
  const CustomWorkoutsPage({super.key});

  @override
  State<CustomWorkoutsPage> createState() => _CustomWorkoutsPageState();
}

class _CustomWorkoutsPageState extends State<CustomWorkoutsPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
  }

  // Normalize date to ignore time for calendar comparisons
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _showWorkoutDetails(BuildContext context, List<WorkoutLog> dailyLogs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorManager.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workouts on ${DateFormat('MMM d, yyyy').format(dailyLogs.first.date)}',
                style: TextStyle(
                  color: ColorManager.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              if (dailyLogs.isEmpty)
                Text('No workouts logged.', style: TextStyle(color: ColorManager.textSecondary))
              else
                ...dailyLogs.map((log) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: ColorManager.primary, size: 20.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.exerciseName,
                              style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold, fontSize: 16.sp),
                            ),
                            Text(
                              '${log.sets.length} Sets',
                              style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = Provider.of<StatisticsProvider>(context);

    return Scaffold(
      backgroundColor: ColorManager.background,
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeManager.s16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'My Progress',
                style: TextStyle(color: ColorManager.white, fontSize: SizeManager.s24.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: SizeManager.s4.h),
              Text(
                'Track your journey and analyze your data',
                style: TextStyle(color: ColorManager.textSecondary, fontSize: SizeManager.s14.sp),
              ),
              SizedBox(height: SizeManager.s24.h),

              // High-level Stats Row
              Row(
                children: [
                  Expanded(child: _buildStatCard('Total Workouts', '${stats.totalWorkouts}', Icons.fitness_center_rounded, Colors.blue)),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildStatCard('Current Streak', '${stats.currentStreak} Days', Icons.local_fire_department_rounded, Colors.orange)),
                ],
              ),
              SizedBox(height: SizeManager.s32.h),

              // Calendar Section
              Text('Activity Calendar', style: TextStyle(color: ColorManager.white, fontSize: SizeManager.s18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: SizeManager.s16.h),
              StreamBuilder<List<WorkoutLog>>(
                stream: WorkoutLogService().getLogs(),
                builder: (context, snapshot) {
                  final logs = snapshot.data ?? [];
                  
                  // Group logs by Date
                  final Map<DateTime, List<WorkoutLog>> logsByDate = {};
                  for (var log in logs) {
                    final normalized = _normalizeDate(log.date);
                    if (logsByDate[normalized] == null) {
                      logsByDate[normalized] = [];
                    }
                    logsByDate[normalized]!.add(log);
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: ColorManager.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: ColorManager.divider),
                    ),
                    padding: EdgeInsets.all(8.w),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        
                        final normalizedSelected = _normalizeDate(selectedDay);
                        if (logsByDate.containsKey(normalizedSelected) && logsByDate[normalizedSelected]!.isNotEmpty) {
                          _showWorkoutDetails(context, logsByDate[normalizedSelected]!);
                        }
                      },
                      calendarFormat: CalendarFormat.month,
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(color: ColorManager.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold),
                        leftChevronIcon: Icon(Icons.chevron_left, color: ColorManager.textPrimary),
                        rightChevronIcon: Icon(Icons.chevron_right, color: ColorManager.textPrimary),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
                        weekendStyle: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
                      ),
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: TextStyle(color: ColorManager.textPrimary),
                        weekendTextStyle: TextStyle(color: ColorManager.textPrimary),
                        outsideTextStyle: TextStyle(color: ColorManager.textTertiary),
                        todayDecoration: BoxDecoration(
                          color: ColorManager.primary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: ColorManager.primary,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      eventLoader: (day) {
                        final normalized = _normalizeDate(day);
                        return logsByDate[normalized] ?? [];
                      },
                    ),
                  );
                },
              ),

              SizedBox(height: SizeManager.s32.h),

              Text('Analytics & Logs', style: TextStyle(color: ColorManager.white, fontSize: SizeManager.s18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: SizeManager.s16.h),

              // Deep Dive Cards
              _buildDeepDiveCard(
                context,
                title: 'Workout History',
                subtitle: 'Review past logs, sets, and weights lifted.',
                icon: Icons.history_toggle_off_rounded,
                color: Colors.teal,
                route: Routes.workoutHistoryRoute,
              ),
              SizedBox(height: SizeManager.s16.h),
              _buildDeepDiveCard(
                context,
                title: 'Strength Analytics',
                subtitle: 'Visualize your PRs and muscle group volume.',
                icon: Icons.bar_chart_rounded,
                color: Colors.deepPurple,
                route: Routes.strengthAnalyticsRoute,
              ),
              SizedBox(height: SizeManager.s16.h),
              _buildDeepDiveCard(
                context,
                title: '30-Day Transformation',
                subtitle: 'Compare progress photos over time.',
                icon: Icons.auto_graph_rounded,
                color: Colors.pink,
                route: Routes.sixPackChallengeRoute,
              ),
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 12.h),
          Text(value, style: TextStyle(color: ColorManager.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text(title, style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildDeepDiveCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required String route}) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: ColorManager.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4.h),
                  Text(subtitle, style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ColorManager.textTertiary),
          ],
        ),
      ),
    );
  }
}
