import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/profile/providers/profile_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';

/// Screen allowing the user to record their structured weekly check-in.
class TransformationWeeklyCheckInScreen extends StatefulWidget {
  final int? weekNumber;

  const TransformationWeeklyCheckInScreen({
    super.key,
    this.weekNumber,
  });

  @override
  State<TransformationWeeklyCheckInScreen> createState() =>
      _TransformationWeeklyCheckInScreenState();
}

class _TransformationWeeklyCheckInScreenState
    extends State<TransformationWeeklyCheckInScreen> {
  late final TextEditingController _weightController;
  late final TextEditingController _waistController;
  late final TextEditingController _chestController;
  late final TextEditingController _armsController;
  late final TextEditingController _hipsController;
  late final TextEditingController _thighsController;
  late final TextEditingController _notesController;

  String _fatigueLevel = 'Normal / Manageable';
  int _targetWeek = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _waistController = TextEditingController();
    _chestController = TextEditingController();
    _armsController = TextEditingController();
    _hipsController = TextEditingController();
    _thighsController = TextEditingController();
    _notesController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillExistingData();
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _waistController.dispose();
    _chestController.dispose();
    _armsController.dispose();
    _hipsController.dispose();
    _thighsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _prefillExistingData() {
    final transformationProvider =
        Provider.of<TransformationProvider?>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider?>(context, listen: false);
    final state = transformationProvider?.activeTransformation;

    _targetWeek = widget.weekNumber ?? state?.currentWeekNumber ?? 1;

    // Prefill weight from existing home provider or active state
    final latestWeight = (homeProvider?.userData['weight'] as num?)?.toDouble() ??
        state?.startingWeight;
    if (latestWeight != null) {
      _weightController.text = latestWeight.toStringAsFixed(1);
    }

    // Prefill measurements if available
    final userData = homeProvider?.userData ?? {};
    if (userData['waist'] != null) {
      _waistController.text = userData['waist'].toString();
    }
    if (userData['chest'] != null) {
      _chestController.text = userData['chest'].toString();
    }
    if (userData['biceps'] != null) {
      _armsController.text = userData['biceps'].toString();
    }
    if (userData['hips'] != null) {
      _hipsController.text = userData['hips'].toString();
    }
    if (userData['thigh'] != null) {
      _thighsController.text = userData['thigh'].toString();
    }

    // If check-in already recorded for this week, prefill its values
    if (state != null) {
      final existingCheckIn = state.weeklyCheckIns
          .where((c) => c.weekNumber == _targetWeek)
          .toList();
      if (existingCheckIn.isNotEmpty) {
        final c = existingCheckIn.first;
        if (c.weight != null) _weightController.text = c.weight!.toStringAsFixed(1);
        if (c.notes != null) _notesController.text = c.notes!;
        if (c.fatigueLevel != null) _fatigueLevel = c.fatigueLevel!;
        if (c.measurements.containsKey('waist')) {
          _waistController.text = c.measurements['waist']!.toString();
        }
        if (c.measurements.containsKey('chest')) {
          _chestController.text = c.measurements['chest']!.toString();
        }
        if (c.measurements.containsKey('biceps')) {
          _armsController.text = c.measurements['biceps']!.toString();
        }
        if (c.measurements.containsKey('hips')) {
          _hipsController.text = c.measurements['hips']!.toString();
        }
        if (c.measurements.containsKey('thigh')) {
          _thighsController.text = c.measurements['thigh']!.toString();
        }
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final transformationProvider =
        Provider.of<TransformationProvider?>(context);
    final state = transformationProvider?.activeTransformation;

    if (state == null) {
      return Scaffold(
        backgroundColor: ColorManager.background,
        appBar: AppBar(title: const Text('Weekly Check-In')),
        body: const Center(child: Text('No active transformation found.')),
      );
    }

    // Compute weekly workout adherence
    final weekStartDay = (_targetWeek - 1) * 7 + 1;
    final weekEndDay = (_targetWeek * 7).clamp(1, state.totalDays);
    final scheduledDaysInWeek = weekEndDay - weekStartDay + 1;

    final completedThisWeek = state.completedDayIndices
        .where((d) => d >= weekStartDay && d <= weekEndDay)
        .length;
    final adherencePct = scheduledDaysInWeek > 0
        ? (completedThisWeek / scheduledDaysInWeek * 100).toInt()
        : 0;

    final currentWeightInput = double.tryParse(_weightController.text);
    final startingWeight = state.startingWeight;
    final weightDelta = (currentWeightInput != null && startingWeight != null)
        ? currentWeightInput - startingWeight
        : null;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'Week $_targetWeek Check-In',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: AppText.appBarTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorManager.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Weekly Performance Summary Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ColorManager.surface,
                boxShadow: ColorManager.cardShadow,
                borderRadius: BorderRadius.circular(AppRadius.tile.r),
                border: Border.all(color: ColorManager.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Weekly Adherence',
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: adherencePct >= 80
                              ? ColorManager.success.withValues(alpha: 0.15)
                              : ColorManager.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '$adherencePct% Completed',
                          style: TextStyle(
                            color: adherencePct >= 80
                                ? ColorManager.successText
                                : ColorManager.primaryText,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Workouts completed: $completedThisWeek of $scheduledDaysInWeek scheduled days (Days $weekStartDay–$weekEndDay)',
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // 2. Weight Entry & Delta
            Text(
              'Current Weight (kg)',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('weekly_weight_input'),
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: ColorManager.surface,
                      hintText: 'e.g. 74.5',
                      suffixText: 'kg',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: ColorManager.divider),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                if (weightDelta != null) ...[
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: weightDelta <= 0
                          ? ColorManager.success.withValues(alpha: 0.15)
                          : ColorManager.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Since Start',
                          style: TextStyle(
                            color: ColorManager.textTertiary,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${weightDelta > 0 ? '+' : ''}${weightDelta.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: weightDelta <= 0
                                ? ColorManager.successText
                                : ColorManager.accentText,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 20.h),

            // 3. Body Measurements (Optional)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Body Measurements (Optional, cm)',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementField('Waist', _waistController),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _buildMeasurementField('Chest', _chestController),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _buildMeasurementField('Arms', _armsController),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementField('Hips', _hipsController),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _buildMeasurementField('Thighs', _thighsController),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
            SizedBox(height: 20.h),

            // 4. Fatigue & Recovery Level
            Text(
              'Fatigue & Recovery Level',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              children: [
                'Low / Fresh',
                'Normal / Manageable',
                'High / Fatigued',
              ].map((level) {
                final isSelected = _fatigueLevel == level;
                return ChoiceChip(
                  label: Text(level),
                  selected: isSelected,
                  selectedColor: ColorManager.primary,
                  backgroundColor: ColorManager.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? ColorManager.onMint : ColorManager.textSecondary,
                    fontSize: 12.sp,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _fatigueLevel = level);
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20.h),

            // 5. Personal Notes / Feedback
            Text(
              'Weekly Notes & Observations',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              key: const Key('weekly_notes_input'),
              controller: _notesController,
              maxLines: 3,
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 13.sp,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: ColorManager.surface,
                hintText:
                    'How did your energy, sleep, diet, and recovery feel this week?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: ColorManager.divider),
                ),
              ),
            ),
            SizedBox(height: 30.h),

            // 6. Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('save_weekly_check_in_button'),
                onPressed: _isSaving ? null : _saveCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button.r),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorManager.onMint,
                        ),
                      )
                    : Text(
                        'Submit Week $_targetWeek Check-In',
                        style: TextStyle(
                          color: ColorManager.onMint,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementField(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ColorManager.textSecondary,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 4.h),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
          ],
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 13.sp,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: ColorManager.surface,
            hintText: '0.0',
            contentPadding:
                EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: ColorManager.divider),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveCheckIn() async {
    setState(() => _isSaving = true);

    try {
      final transformationProvider =
          Provider.of<TransformationProvider>(context, listen: false);
      final profileProvider =
          Provider.of<ProfileProvider?>(context, listen: false);
      final homeProvider = Provider.of<HomeProvider?>(context, listen: false);
      final state = transformationProvider.activeTransformation;

      if (state == null) return;

      final currentWeight = double.tryParse(_weightController.text);
      final startingWeight = state.startingWeight ?? currentWeight;
      final weightChange = (currentWeight != null && startingWeight != null)
          ? currentWeight - startingWeight
          : null;

      final measurements = <String, double>{};
      if (double.tryParse(_waistController.text) != null) {
        measurements['waist'] = double.parse(_waistController.text);
      }
      if (double.tryParse(_chestController.text) != null) {
        measurements['chest'] = double.parse(_chestController.text);
      }
      if (double.tryParse(_armsController.text) != null) {
        measurements['biceps'] = double.parse(_armsController.text);
      }
      if (double.tryParse(_hipsController.text) != null) {
        measurements['hips'] = double.parse(_hipsController.text);
      }
      if (double.tryParse(_thighsController.text) != null) {
        measurements['thigh'] = double.parse(_thighsController.text);
      }

      // Compute weekly workouts
      final weekStartDay = (_targetWeek - 1) * 7 + 1;
      final weekEndDay = (_targetWeek * 7).clamp(1, state.totalDays);
      final scheduledDaysInWeek = weekEndDay - weekStartDay + 1;
      final completedThisWeek = state.completedDayIndices
          .where((d) => d >= weekStartDay && d <= weekEndDay)
          .length;
      final adherence = scheduledDaysInWeek > 0
          ? (completedThisWeek / scheduledDaysInWeek)
          : 0.0;

      final checkIn = TransformationWeeklyCheckIn(
        weekNumber: _targetWeek,
        checkInDate: DateTime.now(),
        weight: currentWeight,
        weightChange: weightChange,
        workoutsCompleted: completedThisWeek,
        workoutsScheduled: scheduledDaysInWeek,
        adherencePercentage: adherence,
        measurements: measurements,
        fatigueLevel: _fatigueLevel,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      await transformationProvider.recordWeeklyCheckIn(checkIn);

      // If user provided a new weight, sync to ProfileProvider and HomeProvider
      if (currentWeight != null && profileProvider != null && mounted) {
        try {
          final height =
              (homeProvider?.userData['height'] as num?)?.toDouble() ?? 175.0;
          await homeProvider?.getUsersBMI(height: height, weight: currentWeight);
          if (mounted) {
            await profileProvider.changeUsersWeight(
              weight: currentWeight,
              bmi: homeProvider?.usersBMI ?? 22.0,
              bmr: homeProvider?.userBMRwithGoal ?? 2000.0,
              weightDateTime: DateTime.now().month,
              context: context,
            );
          }
        } catch (_) {
          // Keep check-in successful even if network sync fails
        }
      }

      // If user provided measurements, sync to ProfileProvider
      if (measurements.isNotEmpty && profileProvider != null && mounted) {
        try {
          final activity =
              homeProvider?.userData['activity']?.toString() ?? 'MODERATE';
          final goal = homeProvider?.userData['goal']?.toString() ?? 'MAINTAIN';
          final bmr = homeProvider?.userBMRwithGoal ?? 2000.0;

          await profileProvider.updateUsersData(
            context: context,
            activity: activity,
            goal: goal,
            bmr: bmr,
            chest: measurements['chest'] ??
                (homeProvider?.userData['chest'] as num?)?.toDouble() ??
                0.0,
            shoulders:
                (homeProvider?.userData['shoulders'] as num?)?.toDouble() ??
                    0.0,
            biceps: measurements['biceps'] ??
                (homeProvider?.userData['biceps'] as num?)?.toDouble() ??
                0.0,
            foreArm:
                (homeProvider?.userData['foreArm'] as num?)?.toDouble() ?? 0.0,
            waist: measurements['waist'] ??
                (homeProvider?.userData['waist'] as num?)?.toDouble() ??
                0.0,
            hips: measurements['hips'] ??
                (homeProvider?.userData['hips'] as num?)?.toDouble() ??
                0.0,
            thigh: measurements['thigh'] ??
                (homeProvider?.userData['thigh'] as num?)?.toDouble() ??
                0.0,
            calf:
                (homeProvider?.userData['calf'] as num?)?.toDouble() ?? 0.0,
          );
        } catch (_) {
          // Keep check-in successful even if network sync fails
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Week $_targetWeek check-in recorded successfully!', style: const TextStyle(color: Colors.white)),
            backgroundColor: ColorManager.successDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save check-in: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: ColorManager.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
