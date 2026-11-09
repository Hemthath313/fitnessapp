import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';
import 'package:fitness_app/utils/router/router.dart';

/// Launcher widget to safely open the canonical DayWorkoutSessionPage from deep links,
/// notification payloads, or navigation routes.
/// Ensures workouts are loaded, prevents duplicate session creations, and handles cold-starts.
class WorkoutSessionLauncherPage extends StatefulWidget {
  final String dayName;
  final List<dynamic>? initialWorkouts;
  final String? planId;
  final int? planDay;

  const WorkoutSessionLauncherPage({
    super.key,
    required this.dayName,
    this.initialWorkouts,
    this.planId,
    this.planDay,
  });

  @override
  State<WorkoutSessionLauncherPage> createState() =>
      _WorkoutSessionLauncherPageState();
}

class _WorkoutSessionLauncherPageState
    extends State<WorkoutSessionLauncherPage> {
  static const List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic>? _workouts;
  late String _resolvedDay;

  @override
  void initState() {
    super.initState();
    if (widget.planId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final sub = Provider.of<SubscriptionProvider?>(context, listen: false);
        if (sub != null && !sub.isPremium) {
          context.pushReplacement(Routes.premiumScreen);
          return;
        }
      });
    }
    _resolveAndLoadSession();
  }

  @override
  void didUpdateWidget(covariant WorkoutSessionLauncherPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dayName != widget.dayName ||
        oldWidget.initialWorkouts != widget.initialWorkouts) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _workouts = null;
      });
      _resolveAndLoadSession();
    }
  }

  String _normalizeDayName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'today') {
      return DateFormat('EEEE').format(DateTime.now());
    }
    for (final day in _weekDays) {
      if (day.toLowerCase() == trimmed.toLowerCase()) {
        return day;
      }
    }
    return trimmed;
  }

  Future<void> _resolveAndLoadSession() async {
    _resolvedDay = _normalizeDayName(widget.dayName);

    if (widget.initialWorkouts != null && widget.initialWorkouts!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _workouts = widget.initialWorkouts;
          _isLoading = false;
        });
      }
      return;
    }

    final wp = Provider.of<WorkoutProvider>(context, listen: false);

    // If workouts haven't been fetched yet (cold start from notification), fetch them
    if (wp.allWorkouts.isEmpty) {
      try {
        await wp.fetchAndSetWorkouts();
      } catch (e) {
        debugPrint('Error fetching workouts in launcher: $e');
      }
    }

    if (!mounted) return;

    final grouped = wp.groupedSplitWorkouts;
    List<dynamic> targetWorkouts = grouped[_resolvedDay] ?? [];

    // Fallback: case-insensitive check
    if (targetWorkouts.isEmpty) {
      for (var entry in grouped.entries) {
        if (entry.key.toLowerCase() == _resolvedDay.toLowerCase()) {
          _resolvedDay = entry.key;
          targetWorkouts = entry.value;
          break;
        }
      }
    }

    if (targetWorkouts.isNotEmpty) {
      setState(() {
        _workouts = targetWorkouts;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No workout routine found for $_resolvedDay.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ColorManager.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ColorManager.primary),
              SizedBox(height: 16.h),
              Text(
                'Loading today\'s workout...',
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _workouts == null || _workouts!.isEmpty) {
      return Scaffold(
        backgroundColor: ColorManager.background,
        appBar: AppBar(
          backgroundColor: ColorManager.background,
          elevation: 0,
          leading: IconButton(tooltip: 'Back', 
            icon: Icon(Icons.arrow_back, color: ColorManager.white),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.mainRoute);
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bedtime_rounded,
                    size: 48.sp, color: Colors.blueAccent),
                SizedBox(height: 16.h),
                Text(
                  _errorMessage ?? 'No scheduled workout found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Today might be a planned rest day or your routine hasn\'t been generated yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    foregroundColor: ColorManager.onMint,
                    padding: EdgeInsets.symmetric(
                        horizontal: 24.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button.r),
                    ),
                  ),
                  onPressed: () => context.go(Routes.mainRoute),
                  child: const Text(
                    'Go to Home',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DayWorkoutSessionPage(
      dayName: _resolvedDay,
      workouts: _workouts!,
      planId: widget.planId,
      planDay: widget.planDay,
    );
  }
}
