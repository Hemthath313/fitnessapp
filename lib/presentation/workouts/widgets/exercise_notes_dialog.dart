import 'dart:io';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExerciseNotesDialog extends StatefulWidget {
  final String exerciseName;
  final String? existingNotes;

  const ExerciseNotesDialog({
    super.key,
    required this.exerciseName,
    this.existingNotes,
  });

  static Future<String?> show(
    BuildContext context, {
    required String exerciseName,
    String? existingNotes,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => ExerciseNotesDialog(
        exerciseName: exerciseName,
        existingNotes: existingNotes,
      ),
    );
  }

  @override
  State<ExerciseNotesDialog> createState() => _ExerciseNotesDialogState();
}

class _ExerciseNotesDialogState extends State<ExerciseNotesDialog> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _setController = TextEditingController();
  final TextEditingController _repController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingNotes != null) {
      _notesController.text = widget.existingNotes!;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _setController.dispose();
    _repController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorManager.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeManager.s20.r),
      ),
      child: Container(
        padding: EdgeInsets.all(SizeManager.s20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.exerciseName,
                    style: StyleManager.appbarTitleTextStyle.copyWith(
                      fontSize: 18.sp,
                    ),
                  ),
                ),
                IconButton(tooltip: 'Close', 
                  icon: Icon(Icons.close, color: ColorManager.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: SizeManager.s16.h),

            // Workout details
            Text(
              'Track Your Progress',
              style: TextStyle(
                color: ColorManager.white70,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: SizeManager.s12.h),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _setController,
                    label: 'Sets',
                    hint: '3',
                    icon: Icons.repeat,
                  ),
                ),
                SizedBox(width: SizeManager.s8.w),
                Expanded(
                  child: _buildTextField(
                    controller: _repController,
                    label: 'Reps',
                    hint: '10',
                    icon: Icons.format_list_numbered,
                  ),
                ),
                SizedBox(width: SizeManager.s8.w),
                Expanded(
                  child: _buildTextField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    hint: '20',
                    icon: Icons.monitor_weight,
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeManager.s16.h),

            // Notes
            Text(
              'Notes',
              style: TextStyle(
                color: ColorManager.white70,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: SizeManager.s8.h),
            TextField(
              controller: _notesController,
              maxLines: 4,
              style: TextStyle(color: ColorManager.white),
              decoration: InputDecoration(
                hintText: 'How did it feel? Any tips?',
                hintStyle: TextStyle(color: ColorManager.white70),
                filled: true,
                fillColor: ColorManager.black87,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SizeManager.s12.r),
                  borderSide: BorderSide(color: ColorManager.grey3),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SizeManager.s12.r),
                  borderSide: BorderSide(color: ColorManager.grey3),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SizeManager.s12.r),
                  borderSide: BorderSide(color: ColorManager.limerGreen2),
                ),
              ),
            ),
            SizedBox(height: SizeManager.s20.h),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: ColorManager.white70),
                  ),
                ),
                SizedBox(width: SizeManager.s8.w),
                ElevatedButton(
                  onPressed: () {
                    final notes = _notesController.text;
                    final workoutData = {
                      'sets': _setController.text,
                      'reps': _repController.text,
                      'weight': _weightController.text,
                      'notes': notes,
                    };
                    Navigator.pop(context, workoutData.toString());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.limerGreen2,
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeManager.s24.w,
                      vertical: SizeManager.s12.h,
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(color: ColorManager.darkGrey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: ColorManager.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: ColorManager.white70),
        hintStyle: TextStyle(color: ColorManager.white70),
        prefixIcon: Icon(icon, color: ColorManager.limerGreen2),
        filled: true,
        fillColor: ColorManager.black87,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeManager.s12.r),
          borderSide: BorderSide(color: ColorManager.grey3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeManager.s12.r),
          borderSide: BorderSide(color: ColorManager.grey3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeManager.s12.r),
          borderSide: BorderSide(color: ColorManager.limerGreen2),
        ),
      ),
    );
  }
}
