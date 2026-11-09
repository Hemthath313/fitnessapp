import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/presentation/profile/widgets/gym_alarm_setting_widget.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Full list of reminder switches. They used to sit inline in the middle of
/// the Profile tab, which made it very long; the tab now shows a one-line
/// summary that opens this page.
class ReminderSettingsPage extends StatelessWidget {
  const ReminderSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'Reminders',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorManager.background,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 16.h),
          child: const GymAlarmSettingWidget(),
        ),
      ),
    );
  }
}
