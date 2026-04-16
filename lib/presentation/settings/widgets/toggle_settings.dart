import 'package:flutter/material.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';

/// Settings button with a trailing switch widget
class SettingsPageToggle extends StatelessWidget {
  const SettingsPageToggle({
    super.key,
    required this.deviceWidth,
    required this.iconData,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final double deviceWidth;
  final IconData iconData;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: PaddingManager.p12,
        left: PaddingManager.p12,
        right: PaddingManager.p12,
      ),
      child: Container(
        width: deviceWidth,
        height: SizeManager.s70.h,
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(
            RadiusManager.r15.r,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: PaddingManager.p12),
                child: Row(
                  children: [
                    Icon(
                      iconData,
                      size: SizeManager.s24,
                      color: ColorManager.textPrimary,
                    ),
                    const SizedBox(width: PaddingManager.p12),
                    Text(
                      title,
                      style: StyleManager.settingsButtonTextStyle,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: PaddingManager.p12),
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: ColorManager.primary,
                activeTrackColor: ColorManager.primary.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
