import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';

class GymAlarmSettingWidget extends StatefulWidget {
  const GymAlarmSettingWidget({super.key});

  @override
  State<GymAlarmSettingWidget> createState() => _GymAlarmSettingWidgetState();
}

class _GymAlarmSettingWidgetState extends State<GymAlarmSettingWidget> {
  bool _isAlarmEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 6, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadAlarmSettings();
  }

  Future<void> _loadAlarmSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAlarmEnabled = prefs.getBool('gym_alarm_enabled') ?? false;
      final hour = prefs.getInt('gym_alarm_hour') ?? 6;
      final minute = prefs.getInt('gym_alarm_minute') ?? 0;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveAlarmSettings(bool enabled, TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gym_alarm_enabled', enabled);
    await prefs.setInt('gym_alarm_hour', time.hour);
    await prefs.setInt('gym_alarm_minute', time.minute);

    if (enabled) {
      await NotificationService().scheduleDailyGymAlarm(time);
    } else {
      await NotificationService().cancelDailyGymAlarm();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _isAlarmEnabled = true; // Auto-enable if they pick a time
      });
      await _saveAlarmSettings(true, picked);
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
            color: ColorManager.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.alarm,
                  color: ColorManager.primary,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Gym Alarm',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Get a push notification to wake up',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isAlarmEnabled,
                onChanged: (value) {
                  setState(() {
                    _isAlarmEnabled = value;
                  });
                  _saveAlarmSettings(value, _selectedTime);
                },
                activeColor: ColorManager.primary,
                activeTrackColor: ColorManager.primary.withOpacity(0.5),
              ),
            ],
          ),
          if (_isAlarmEnabled) ...[
            SizedBox(height: 16.h),
            Divider(color: ColorManager.primary.withOpacity(0.2)),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alarm Time',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 14.sp,
                  ),
                ),
                GestureDetector(
                  onTap: () => _selectTime(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: ColorManager.darkGrey,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: ColorManager.primary),
                    ),
                    child: Text(
                      _selectedTime.format(context),
                      style: TextStyle(
                        color: ColorManager.primary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
