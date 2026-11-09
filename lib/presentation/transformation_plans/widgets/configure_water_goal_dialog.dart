import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';

/// Friendly dialog allowing users to set a personal daily hydration target.
/// Adheres to guidelines: general wellness goal, non-medical advice.
class ConfigureWaterGoalDialog extends StatefulWidget {
  final double currentTargetMl;
  final TransformationProvider provider;

  const ConfigureWaterGoalDialog({
    super.key,
    required this.currentTargetMl,
    required this.provider,
  });

  static Future<void> show({
    required BuildContext context,
    required double currentTargetMl,
    required TransformationProvider provider,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ConfigureWaterGoalDialog(
        currentTargetMl: currentTargetMl,
        provider: provider,
      ),
    );
  }

  @override
  State<ConfigureWaterGoalDialog> createState() => _ConfigureWaterGoalDialogState();
}

class _ConfigureWaterGoalDialogState extends State<ConfigureWaterGoalDialog> {
  late double _selectedTargetMl;
  bool _isSaving = false;

  final List<double> _presets = [2000.0, 2500.0, 3000.0, 3500.0];

  @override
  void initState() {
    super.initState();
    _selectedTargetMl = widget.currentTargetMl > 0 ? widget.currentTargetMl : 2500.0;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorManager.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.water_drop_rounded, color: Colors.blue, size: 20),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Water Goal',
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'General wellness & recovery target',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            Text(
              'Customize your daily hydration target to suit your climate, activity level, and thirst. A common guideline is 2.0L – 3.5L per day.',
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 12.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16.h),

            // Target Display
            Center(
              child: Column(
                children: [
                  Text(
                    '${(_selectedTargetMl / 1000).toStringAsFixed(1)} Litres',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '(${_selectedTargetMl.toInt()} ml)',
                    style: TextStyle(
                      color: ColorManager.textTertiary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Presets
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              alignment: WrapAlignment.center,
              children: _presets.map((ml) {
                final isSelected = (_selectedTargetMl - ml).abs() < 50;
                return ChoiceChip(
                  key: Key('water_preset_${ml.toInt()}'),
                  label: Text('${(ml / 1000).toStringAsFixed(1)}L'),
                  selected: isSelected,
                  selectedColor: Colors.blue,
                  backgroundColor: ColorManager.surfaceDark,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : ColorManager.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedTargetMl = ml);
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16.h),

            // Fine tuning slider
            Slider(
              value: _selectedTargetMl.clamp(1500.0, 5000.0),
              min: 1500.0,
              max: 5000.0,
              divisions: 14, // 250ml steps
              activeColor: Colors.blue,
              inactiveColor: ColorManager.surfaceDark,
              onChanged: (val) => setState(() => _selectedTargetMl = val),
            ),
            SizedBox(height: 16.h),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  key: const Key('save_water_goal_button'),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final nav = Navigator.of(context);
                          setState(() => _isSaving = true);
                          await widget.provider.updateDailyWaterTarget(_selectedTargetMl);
                          nav.pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button.r)),
                  ),
                  child: Text(
                    _isSaving ? 'Saving...' : 'Set Goal',
                    style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
