import 'dart:convert';
import 'package:fitness_app/presentation/in_app_purchases/premimum_screen.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WorkoutGeneratorScreen extends StatefulWidget {
  const WorkoutGeneratorScreen({super.key});

  @override
  State<WorkoutGeneratorScreen> createState() => _WorkoutGeneratorScreenState();
}

class _WorkoutGeneratorScreenState extends State<WorkoutGeneratorScreen> {
  Gemini? gemini;
  bool _isLoading = false;
  bool _isKeyMissing = false;
  
  // Weekly Schedule Structure: 
  // [ { "day": "Monday", "focus": "Chest", "exercises": [...] }, ... ]
  List<Map<String, dynamic>> _generatedWeek = [];

  // Selections
  String _target = 'Full Body';
  String _level = 'Beginner';
  String _equipment = 'Gym (Full Equipment)';
  int _daysPerWeek = 3;

  final List<String> _targets = [
    'Full Body',
    'Upper Body',
    'Lower Body',
    'Muscle Build (Hypertrophy)',
    'Strength',
    'Fat Loss'
  ];
  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _equipments = [
    'Gym (Full Equipment)',
    'Home (Dumbbells)',
    'Bodyweight Only'
  ];
  final List<int> _daysOptions = [3, 4, 5, 6];

  @override
  void initState() {
    super.initState();
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      _isKeyMissing = true;
    } else {
      try {
        gemini = Gemini.instance;
      } catch (e) {
        _isKeyMissing = true;
      }
    }
  }


  Future<void> _generateWorkout() async {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    if (!subscriptionProvider.isPremium) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
      return;
    }

    if (gemini == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini API Key is missing!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedWeek = [];
    });

    // Detailed Prompt for Weekly Schedule
    final prompt =
        'Generate a $_daysPerWeek-day weekly fitness schedule for a $_level user focusing on $_target using $_equipment. '
        'Map the days to Monday, Tuesday, etc. (e.g. Monday: Chest, Tuesday: Back...). '
        'Return ONLY a valid JSON array. '
        'Structure: [{"day": "Monday", "focus": "Chest", "exercises": [{"name": "Bench Press", "sets": 3, "reps": 10}, ...]}, ...]. '
        'Include 4-5 exercises per workout day. Do not include markdown formatting.';

    try {
      final value = await gemini!.prompt(parts: [Part.text(prompt)]);
      final response = value?.output ?? '';
      
      print("Gemini Raw Response: $response");

      String jsonString = response.replaceAll('```json', '').replaceAll('```', '').trim();
      final startIndex = jsonString.indexOf('[');
      final endIndex = jsonString.lastIndexOf(']');
      if (startIndex != -1 && endIndex != -1) {
        jsonString = jsonString.substring(startIndex, endIndex + 1);
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      
      setState(() {
        _generatedWeek = List<Map<String, dynamic>>.from(decoded);
        _isLoading = false;
      });
      
    } catch (e) {
      print("Generation Error: $e");
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate. Try again or reduce days.')),
        );
      }
    }
  }

  bool _isSaving = false;

  // ... (existing code)

  Future<void> _saveAllWorkouts() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    final now = DateTime.now();
    int count = 0;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      for (var dayPlan in _generatedWeek) {
        final dayName = dayPlan['day'] ?? 'Day';
        final exercises = dayPlan['exercises'] as List<dynamic>? ?? [];

        for (var exercise in exercises) {
          final rawName = exercise['name'] ?? 'Exercise';
          final savedName = '[$dayName] $rawName'; 

          await provider.addNewWorkout(
            name: savedName,
            repNumber: int.tryParse(exercise['reps'].toString()) ?? 10,
            setNumber: int.tryParse(exercise['sets'].toString()) ?? 3,
            dateTime: now,
          );
          count++;
        }
      }

      // Refresh provider so the list is updated immediately
      await provider.fetchAndSetWorkouts();

      if (mounted) {
        Navigator.pop(context); // Pop dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved $count exercises to My Workouts!'),
            backgroundColor: Colors.green,
          ),
        );
        // Optional: Navigate back or clear generated week
        // setState(() { _generatedWeek = []; }); 
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ...

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Weekly Split',
              style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _isSaving ? null : _saveAllWorkouts,
              icon: Icon(Icons.save_alt, color: _isSaving ? Colors.grey : ColorManager.gradientStart),
              label: Text('Save Plan', style: TextStyle(color: _isSaving ? Colors.grey : ColorManager.limerGreen2)),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ..._generatedWeek.map((dayPlan) => _buildDayCard(dayPlan)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: const Text('AI Weekly Coach', style: TextStyle(color: Colors.white)),
        backgroundColor: ColorManager.background,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeManager.s16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isKeyMissing)
              _buildErrorBanner(),

            _buildSelectionSection(),
            SizedBox(height: 24.h),
            
            ElevatedButton(
              onPressed: (_isLoading || _isKeyMissing) ? null : _generateWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : Text(
                      'GENERATE WEEKLY PLAN',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
            ),
            SizedBox(height: 24.h),
            
            if (_generatedWeek.isNotEmpty) _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40.sp),
          SizedBox(height: 10.h),
          Text(
            'Missing API Key',
            style: TextStyle(color: Colors.red, fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          const Text(
            'Please add GEMINI_API_KEY to your lib/.env file.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorManager.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
           _buildDropdown('Days per Week', '$_daysPerWeek Days', _daysOptions.map((e) => '$e Days').toList(), 
            (val) => setState(() => _daysPerWeek = int.parse(val!.split(' ')[0]))),
           SizedBox(height: 16.h),
          _buildDropdown('Goal', _target, _targets, (val) => setState(() => _target = val!)),
          SizedBox(height: 16.h),
          _buildDropdown('Level', _level, _levels, (val) => setState(() => _level = val!)),
          SizedBox(height: 16.h),
          _buildDropdown('Equipment', _equipment, _equipments, (val) => setState(() => _equipment = val!)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: ColorManager.surface,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildDayCard(Map<String, dynamic> dayPlan) {
    final exercises = dayPlan['exercises'] as List<dynamic>? ?? [];
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ExpansionTile(
        backgroundColor: Colors.white.withOpacity(0.05),
        collapsedBackgroundColor: ColorManager.surface,
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text(
          dayPlan['day'] ?? 'Day',
          style: TextStyle(color: ColorManager.primary, fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        subtitle: Text(
          dayPlan['focus'] ?? 'Workout',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        children: exercises.map((e) => ListTile(
          dense: true,
          leading: Icon(Icons.fitness_center, color: Colors.white54, size: 18.sp),
          title: Text(
            e['name'],
            style: const TextStyle(color: Colors.white),
          ),
          trailing: Text(
            '${e['sets']}x${e['reps']}',
            style: TextStyle(color: ColorManager.textSecondary),
          ),
        )).toList(),
      ),
    );
  }
}
