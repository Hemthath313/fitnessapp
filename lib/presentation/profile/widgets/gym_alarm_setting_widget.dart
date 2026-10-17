import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:intl/intl.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';

class GymAlarmSettingWidget extends StatefulWidget {
  const GymAlarmSettingWidget({super.key});

  @override
  State<GymAlarmSettingWidget> createState() => _GymAlarmSettingWidgetState();
}

class _GymAlarmSettingWidgetState extends State<GymAlarmSettingWidget> {
  // 1. Daily Gym Alarm
  bool _isAlarmEnabled = false;
  TimeOfDay _alarmTime = const TimeOfDay(hour: 6, minute: 0);

  // 2. Smart Workout Reminders (Split Days)
  bool _isWorkoutNotifEnabled = false;
  TimeOfDay _workoutNotifTime = const TimeOfDay(hour: 8, minute: 0);

  // 3. Streak Protection
  bool _isStreakNotifEnabled = true;

  // 4. Rest Day Recovery
  bool _isRecoveryNotifEnabled = false;

  // 5. Water Reminder
  bool _isWaterNotifEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAlarmEnabled = prefs.getBool('gym_alarm_enabled') ?? false;
      final alarmHour = prefs.getInt('gym_alarm_hour') ?? 6;
      final alarmMin = prefs.getInt('gym_alarm_minute') ?? 0;
      _alarmTime = TimeOfDay(hour: alarmHour, minute: alarmMin);

      _isWorkoutNotifEnabled =
          prefs.getBool('notif_workout_reminders_enabled') ?? false;
      final workoutHour = prefs.getInt('notif_workout_hour') ?? 8;
      final workoutMin = prefs.getInt('notif_workout_minute') ?? 0;
      _workoutNotifTime = TimeOfDay(hour: workoutHour, minute: workoutMin);

      _isStreakNotifEnabled =
          prefs.getBool('notif_streak_reminders_enabled') ?? true;
      _isRecoveryNotifEnabled =
          prefs.getBool('notif_recovery_reminders_enabled') ?? false;
      _isWaterNotifEnabled =
          prefs.getBool('notif_water_reminders_enabled') ?? false;
    });
  }

  Future<bool> _ensurePermission() async {
    final hasPerm = await NotificationService().hasNotificationPermission();
    if (hasPerm) return true;

    final granted =
        await NotificationService().requestNotificationPermissions();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enable notification permissions in your device settings to receive reminders.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
    return granted;
  }

  Future<void> _toggleDailyAlarm(bool enabled) async {
    if (enabled) {
      final granted = await _ensurePermission();
      if (!granted) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gym_alarm_enabled', enabled);
    setState(() => _isAlarmEnabled = enabled);

    if (enabled) {
      await NotificationService().scheduleDailyGymAlarm(_alarmTime);
    } else {
      await NotificationService().cancelDailyGymAlarm();
    }
  }

  Future<void> _selectAlarmTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: ColorManager.primary,
              onPrimary: Colors.black,
              surface: ColorManager.surface,
              onSurface: ColorManager.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _alarmTime) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('gym_alarm_hour', picked.hour);
      await prefs.setInt('gym_alarm_minute', picked.minute);
      setState(() {
        _alarmTime = picked;
      });
      if (_isAlarmEnabled) {
        await NotificationService().scheduleDailyGymAlarm(picked);
      }
    }
  }

  Future<void> _toggleWorkoutReminders(bool enabled) async {
    if (enabled) {
      final granted = await _ensurePermission();
      if (!granted) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_workout_reminders_enabled', enabled);
    setState(() => _isWorkoutNotifEnabled = enabled);

    if (enabled) {
      final wp = Provider.of<WorkoutProvider>(context, listen: false);
      final splitDays = wp.groupedSplitWorkouts.keys.toList();
      final todayName = DateFormat('EEEE').format(DateTime.now());
      final completedDays =
          wp.isDayWorkoutCompletedToday(todayName) ? [todayName] : <String>[];
      if (splitDays.isNotEmpty) {
        await NotificationService().scheduleWorkoutDayReminders(
          scheduledDays: splitDays,
          time: _workoutNotifTime,
          completedDays: completedDays,
        );
      }
    } else {
      await NotificationService().cancelWorkoutDayReminders();
    }
  }

  Future<void> _selectWorkoutNotifTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _workoutNotifTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: ColorManager.primary,
              onPrimary: Colors.black,
              surface: ColorManager.surface,
              onSurface: ColorManager.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _workoutNotifTime) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notif_workout_hour', picked.hour);
      await prefs.setInt('notif_workout_minute', picked.minute);
      setState(() {
        _workoutNotifTime = picked;
      });
      if (_isWorkoutNotifEnabled) {
        final wp = Provider.of<WorkoutProvider>(context, listen: false);
        final splitDays = wp.groupedSplitWorkouts.keys.toList();
        final todayName = DateFormat('EEEE').format(DateTime.now());
        final completedDays =
            wp.isDayWorkoutCompletedToday(todayName) ? [todayName] : <String>[];
        if (splitDays.isNotEmpty) {
          await NotificationService().scheduleWorkoutDayReminders(
            scheduledDays: splitDays,
            time: picked,
            completedDays: completedDays,
          );
        }
      }
    }
  }

  Future<void> _toggleStreakReminders(bool enabled) async {
    if (enabled) {
      final granted = await _ensurePermission();
      if (!granted) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_streak_reminders_enabled', enabled);
    setState(() => _isStreakNotifEnabled = enabled);

    if (enabled) {
      await NotificationService().scheduleStreakReminder();
    } else {
      await NotificationService().cancelStreakReminder();
    }
  }

  Future<void> _toggleRecoveryReminders(bool enabled) async {
    if (enabled) {
      final granted = await _ensurePermission();
      if (!granted) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_recovery_reminders_enabled', enabled);
    setState(() => _isRecoveryNotifEnabled = enabled);

    if (enabled) {
      final wp = Provider.of<WorkoutProvider>(context, listen: false);
      const weekDays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final scheduledDays = wp.groupedSplitWorkouts.keys.toSet();
      final restDays =
          weekDays.where((d) => !scheduledDays.contains(d)).toList();
      if (restDays.isNotEmpty) {
        await NotificationService().scheduleRestDayReminders(restDays: restDays);
      }
    } else {
      await NotificationService().cancelRestDayReminders();
    }
  }

  Future<void> _toggleWaterReminders(bool enabled) async {
    if (enabled) {
      final granted = await _ensurePermission();
      if (!granted) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_water_reminders_enabled', enabled);
    setState(() => _isWaterNotifEnabled = enabled);

    if (enabled) {
      await NotificationService().scheduleWaterReminder();
    } else {
      await NotificationService().cancelWaterReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorManager.primary.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  color: ColorManager.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Notification Preferences',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // 1. Smart Workout Day Reminders
          _buildToggleRow(
            icon: Icons.fitness_center_rounded,
            color: ColorManager.primary,
            title: 'Workout Split Reminders',
            subtitle: 'Remind on scheduled training days',
            value: _isWorkoutNotifEnabled,
            onChanged: _toggleWorkoutReminders,
            extraContent: _isWorkoutNotifEnabled
                ? _buildTimeSelector(
                    label: 'Reminder Time',
                    time: _workoutNotifTime,
                    onTap: () => _selectWorkoutNotifTime(context),
                  )
                : null,
          ),
          Divider(color: ColorManager.divider, height: 20.h),

          // 2. Daily Gym Alarm
          _buildToggleRow(
            icon: Icons.alarm_rounded,
            color: Colors.orange,
            title: 'Daily Gym Alarm',
            subtitle: 'Alarm to wake up and get ready for training',
            value: _isAlarmEnabled,
            onChanged: _toggleDailyAlarm,
            extraContent: _isAlarmEnabled
                ? _buildTimeSelector(
                    label: 'Alarm Time',
                    time: _alarmTime,
                    onTap: () => _selectAlarmTime(context),
                  )
                : null,
          ),
          Divider(color: ColorManager.divider, height: 20.h),

          // 3. Friendly Streak Protection
          _buildToggleRow(
            icon: Icons.local_fire_department_rounded,
            color: Colors.amber,
            title: 'Gentle Streak Protection',
            subtitle: 'Friendly reminder after 48h of inactivity (zero guilt)',
            value: _isStreakNotifEnabled,
            onChanged: _toggleStreakReminders,
          ),
          Divider(color: ColorManager.divider, height: 20.h),

          // 4. Rest Day Recovery Tips
          _buildToggleRow(
            icon: Icons.self_improvement_rounded,
            color: Colors.blueAccent,
            title: 'Rest Day Recovery Tips',
            subtitle: 'Morning recovery guidance on planned rest days',
            value: _isRecoveryNotifEnabled,
            onChanged: _toggleRecoveryReminders,
          ),
          Divider(color: ColorManager.divider, height: 20.h),

          // 5. Hydration Reminder
          _buildToggleRow(
            icon: Icons.water_drop_rounded,
            color: Colors.cyan,
            title: 'Hydration Reminder',
            subtitle: 'Daily 6:00 PM water target check-in',
            value: _isWaterNotifEnabled,
            onChanged: _toggleWaterReminders,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? extraContent,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: ColorManager.primary,
              activeTrackColor: ColorManager.primary.withOpacity(0.5),
            ),
          ],
        ),
        if (extraContent != null) ...[
          SizedBox(height: 8.h),
          extraContent,
        ],
      ],
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 40.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 12.sp,
            ),
          ),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: ColorManager.surface,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: ColorManager.primary),
              ),
              child: Text(
                time.format(context),
                style: TextStyle(
                  color: ColorManager.primary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
