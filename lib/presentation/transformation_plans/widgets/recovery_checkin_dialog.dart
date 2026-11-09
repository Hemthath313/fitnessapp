import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';

/// Modal bottom sheet allowing users to record their daily recovery status.
class RecoveryCheckInDialog extends StatefulWidget {
  final DateTime date;
  final TransformationProvider provider;
  final ConsumptionProvider? consumptionProvider;
  final String? initialLevel;
  final String? initialNote;

  const RecoveryCheckInDialog({
    super.key,
    required this.date,
    required this.provider,
    this.consumptionProvider,
    this.initialLevel,
    this.initialNote,
  });

  static Future<void> show({
    required BuildContext context,
    required DateTime date,
    required TransformationProvider provider,
    ConsumptionProvider? consumptionProvider,
    String? initialLevel,
    String? initialNote,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecoveryCheckInDialog(
        date: date,
        provider: provider,
        consumptionProvider: consumptionProvider,
        initialLevel: initialLevel,
        initialNote: initialNote,
      ),
    );
  }

  @override
  State<RecoveryCheckInDialog> createState() => _RecoveryCheckInDialogState();
}

class _RecoveryCheckInDialogState extends State<RecoveryCheckInDialog> {
  late String _selectedLevel;
  late TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialLevel ?? 'good';
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bedtime_rounded, color: ColorManager.primary, size: 20.sp),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Daily Recovery Check-In',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(tooltip: 'Close', 
                icon: Icon(Icons.close_rounded, color: ColorManager.textSecondary, size: 20.sp),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          Text(
            'How rested and recovered do you feel today? Honest check-ins keep your programme sustainable.',
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 12.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),

          // Recovery Options
          _buildOptionTile(
            key: const Key('recovery_option_good'),
            level: 'good',
            emoji: '⚡️',
            title: 'Well Rested & Energetic',
            subtitle: 'Ready to train, recovered muscles, quality sleep',
            color: ColorManager.success,
          ),
          SizedBox(height: 10.h),

          _buildOptionTile(
            key: const Key('recovery_option_moderate'),
            level: 'moderate',
            emoji: '👍',
            title: 'Moderate / Normal',
            subtitle: 'Slight soreness, balanced energy, manageable fatigue',
            color: const Color(0xFFFFA500),
          ),
          SizedBox(height: 10.h),

          _buildOptionTile(
            key: const Key('recovery_option_poor'),
            level: 'poor',
            emoji: '😴',
            title: 'High Fatigue / Need Extra Rest',
            subtitle: 'Restless sleep, high muscle soreness, low energy',
            color: ColorManager.error,
          ),
          SizedBox(height: 16.h),

          // Optional Note Field
          TextField(
            key: const Key('recovery_note_input'),
            controller: _noteController,
            style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Add an optional note (e.g. 7.5 hrs sleep, sore hamstrings)...',
              hintStyle: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp),
              filled: true,
              fillColor: ColorManager.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(12.w),
            ),
          ),
          SizedBox(height: 18.h),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('confirm_recovery_checkin_button'),
              onPressed: _isSaving
                  ? null
                  : () async {
                      final nav = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _isSaving = true);

                      try {
                        await widget.provider.updateRecoveryCheckIn(
                          date: widget.date,
                          level: _selectedLevel,
                          note: _noteController.text.trim().isNotEmpty
                              ? _noteController.text.trim()
                              : null,
                          consumptionProvider: widget.consumptionProvider,
                        );

                        if (mounted) {
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: const Text('✓ Daily recovery check-in recorded!'),
                              backgroundColor: ColorManager.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isSaving = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to save recovery check-in: $e'),
                              backgroundColor: ColorManager.error,
                            ),
                          );
                        }
                      }
                    },
              icon: _isSaving
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(color: ColorManager.onMint, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, color: ColorManager.onMint, size: 18),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Recovery Check-In',
                style: TextStyle(color: ColorManager.onMint, fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                padding: EdgeInsets.symmetric(vertical: 13.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button.r)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required Key key,
    required String level,
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedLevel == level;

    return InkWell(
      key: key,
      onTap: () => setState(() => _selectedLevel = level),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : ColorManager.surfaceDark,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : ColorManager.divider,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: 20.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? color : ColorManager.textPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
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
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20.sp)
            else
              Icon(Icons.radio_button_unchecked_rounded, color: ColorManager.textTertiary, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
