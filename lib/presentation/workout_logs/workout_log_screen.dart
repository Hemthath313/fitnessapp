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
  String _category = 'Strength';
  final _logService = WorkoutLogService();

  void _addSet() {
    setState(() {
      _sets.add(WorkoutSet(weight: 0, reps: 0));
    });
  }

  void _removeSet(int index) {
    if (_sets.length > 1) {
      setState(() {
        _sets.removeAt(index);
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

    final log = WorkoutLog(
      id: '',
      exerciseName: _exerciseController.text,
      date: DateTime.now(),
      sets: _sets,
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
        title: const Text('Log Workout', style: TextStyle(color: Colors.white)),
        backgroundColor: ColorManager.background,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _exerciseController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Exercise Name',
                labelStyle: TextStyle(color: ColorManager.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: ColorManager.primary)),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Text('Category: ', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
                DropdownButton<String>(
                  value: _category,
                  dropdownColor: ColorManager.surface,
                  style: const TextStyle(color: Colors.white),
                  items: ['Strength', 'Cardio', 'Mobility', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => _category = val!),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Text('Sets', style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sets.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: ColorManager.primary,
                        radius: 12.r,
                        child: Text('${index + 1}', style: const TextStyle(color: Colors.black, fontSize: 12)),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Kg', labelStyle: TextStyle(color: Colors.grey)),
                          onChanged: (val) => _sets[index] = WorkoutSet(weight: double.tryParse(val) ?? 0, reps: _sets[index].reps),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Reps', labelStyle: TextStyle(color: Colors.grey)),
                          onChanged: (val) => _sets[index] = WorkoutSet(weight: _sets[index].weight, reps: int.tryParse(val) ?? 0),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeSet(index),
                      ),
                    ],
                  ),
                );
              },
            ),
            TextButton.icon(
              onPressed: _addSet,
              icon: const Icon(Icons.add, color: ColorManager.primary),
              label: const Text('Add Set', style: TextStyle(color: ColorManager.primary)),
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Notes',
                labelStyle: TextStyle(color: ColorManager.textSecondary),
                border: OutlineInputBorder(borderSide: BorderSide(color: ColorManager.surfaceLight)),
              ),
            ),
            SizedBox(height: 30.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                child: const Text('Save Workout', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
