import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  final _exerciseController = TextEditingController();
  final _notesController = TextEditingController();
  final List<WorkoutSet> _sets = [WorkoutSet(weight: 0, reps: 0)];
  final List<TextEditingController> _weightControllers = [TextEditingController()];
  final List<TextEditingController> _repControllers = [TextEditingController()];
  
  String _category = 'Strength';
  final _logService = WorkoutLogService();

  @override
  void dispose() {
    _exerciseController.dispose();
    _notesController.dispose();
    for (var c in _weightControllers) {
      c.dispose();
    }
    for (var c in _repControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSet() {
    setState(() {
      _sets.add(WorkoutSet(weight: 0, reps: 0));
      _weightControllers.add(TextEditingController());
      _repControllers.add(TextEditingController());
    });
  }

  void _removeSet(int index) {
    if (_sets.length > 1) {
      setState(() {
        _sets.removeAt(index);
        _weightControllers[index].dispose();
        _weightControllers.removeAt(index);
        _repControllers[index].dispose();
        _repControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveLog() async {
    if (_exerciseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exercise name')),
      );
      return;
    }

    final List<WorkoutSet> finalSets = [];
    for (int i = 0; i < _sets.length; i++) {
      final weight = double.tryParse(_weightControllers[i].text) ?? 0.0;
      final reps = int.tryParse(_repControllers[i].text) ?? 0;
      finalSets.add(WorkoutSet(weight: weight, reps: reps));
    }

    final log = WorkoutLog(
      id: '',
      exerciseName: _exerciseController.text.trim(),
      date: DateTime.now(),
      sets: finalSets,
      notes: _notesController.text,
      category: _category,
    );

    try {
      await _logService.addLog(log);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving log: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text('Log Workout', style: TextStyle(color: ColorManager.textPrimary)),
        backgroundColor: ColorManager.background,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _exerciseController,
              style: TextStyle(color: ColorManager.textPrimary),
              decoration: InputDecoration(
                labelText: 'Exercise Name',
                labelStyle: TextStyle(color: ColorManager.textSecondary),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: ColorManager.primary, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: ColorManager.divider),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Text('Category: ', style: TextStyle(color: ColorManager.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                SizedBox(width: 12.w),
                DropdownButton<String>(
                  value: _category,
                  dropdownColor: ColorManager.surface,
                  style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold, fontSize: 16.sp),
                  items: ['Strength', 'Cardio', 'Mobility', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => _category = val!),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Text('Sets', style: TextStyle(color: ColorManager.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            
            // Sets Table (Weight, Reps Input Form matching workout execution)
            Card(
              color: ColorManager.surface,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTableHeaderCell('Set'),
                        _buildTableHeaderCell('Weight (kg)'),
                        _buildTableHeaderCell('Reps'),
                        _buildTableHeaderCell('Action'),
                      ],
                    ),
                    const Divider(),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sets.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Set Number Badge
                              Expanded(
                                child: Center(
                                  child: CircleAvatar(
                                    radius: 12.r,
                                    backgroundColor: ColorManager.primary.withOpacity(0.15),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: ColorManager.primary,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Weight input field
                              Expanded(
                                child: Center(
                                  child: SizedBox(
                                    width: 65.w,
                                    height: 32.h,
                                    child: TextField(
                                      controller: _weightControllers[index],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        filled: true,
                                        fillColor: ColorManager.divider.withOpacity(0.3),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Reps input field
                              Expanded(
                                child: Center(
                                  child: SizedBox(
                                    width: 65.w,
                                    height: 32.h,
                                    child: TextField(
                                      controller: _repControllers[index],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        filled: true,
                                        fillColor: ColorManager.divider.withOpacity(0.3),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Delete Button
                              Expanded(
                                child: Center(
                                  child: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                    onPressed: () => _removeSet(index),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    TextButton.icon(
                      onPressed: _addSet,
                      icon: Icon(Icons.add, color: ColorManager.primary),
                      label: Text('Add Set', style: TextStyle(color: ColorManager.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20.h),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: TextStyle(color: ColorManager.textPrimary),
              decoration: InputDecoration(
                labelText: 'Notes',
                labelStyle: TextStyle(color: ColorManager.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: ColorManager.divider)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: ColorManager.divider)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: ColorManager.primary, width: 2),
                ),
              ),
            ),
            SizedBox(height: 30.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  elevation: 4,
                ),
                child: const Text('Save Workout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ColorManager.textTertiary,
          fontWeight: FontWeight.bold,
          fontSize: 11.sp,
        ),
      ),
    );
  }
}
