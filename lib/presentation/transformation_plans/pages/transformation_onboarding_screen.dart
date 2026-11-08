import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/utils/tdee_calculator.dart';

/// Multi-step onboarding flow to personalize equipment, workout schedule,
/// and calibrated nutrition targets before launching a transformation programme.
class TransformationOnboardingScreen extends StatefulWidget {
  final TransformationPlanBlueprint? plan;
  final String? planId;

  const TransformationOnboardingScreen({
    super.key,
    this.plan,
    this.planId,
  });

  @override
  State<TransformationOnboardingScreen> createState() =>
      _TransformationOnboardingScreenState();
}

class _TransformationOnboardingScreenState
    extends State<TransformationOnboardingScreen> {
  int _currentStep = 0;
  late final TransformationPlanBlueprint _plan;

  // Step 1: Profile & Target
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;
  String _selectedGender = 'Male';
  String _activityLevel = 'MODERATE';

  // Step 2: Training Environment
  String _workoutLocation = 'gym'; // 'gym' | 'home'
  String _experienceLevel = 'Intermediate';
  final Set<String> _selectedEquipment = {'Barbell', 'Dumbbells', 'Cables', 'Machines'};
  int _daysPerWeek = 4;
  int _workoutDuration = 45;

  // Step 3: Nutrition & Limitations
  String _dietaryPreference = 'Non-vegetarian';
  final Set<String> _selectedAllergies = {'None'};
  final Set<String> _selectedInjuries = {'None'};

  // Step 4: Calibrated Results
  double _calculatedTDEE = 2200;
  double _calculatedTargetCalories = 1800;
  Map<String, double> _calculatedMacros = {'protein': 150, 'carbs': 180, 'fat': 50};

  @override
  void initState() {
    super.initState();
    _plan = widget.plan ??
        (widget.planId != null
            ? TransformationPlansData.getById(widget.planId!)
            : null) ??
        TransformationPlansData.weightLoss60;

    if (_plan.id == 'beginner_fitness_30') {
      _daysPerWeek = 3;
      _workoutDuration = 30;
      _experienceLevel = 'Beginner';
    }

    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _targetWeightController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final subscriptionProvider =
          Provider.of<SubscriptionProvider?>(context, listen: false);
      if (subscriptionProvider != null && !subscriptionProvider.isPremium) {
        context.pushReplacement(Routes.premiumScreen);
        return;
      }
      _prefillExistingProfileData();
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _prefillExistingProfileData() {
    final homeProvider = Provider.of<HomeProvider?>(context, listen: false);
    final userData = homeProvider?.userData ?? {};

    final age = (userData['age'] as num?)?.toInt() ?? 25;
    final height = (userData['height'] as num?)?.toDouble() ?? 175.0;
    final weight = (userData['weight'] as num?)?.toDouble() ?? 75.0;
    final gender = userData['gender']?.toString() ?? 'Male';
    final activity = userData['activity']?.toString() ?? 'MODERATE';

    setState(() {
      _ageController.text = age.toString();
      _heightController.text = height.toStringAsFixed(0);
      _weightController.text = weight.toStringAsFixed(1);
      _selectedGender = gender.isNotEmpty ? gender : 'Male';
      _activityLevel = activity.isNotEmpty ? activity : 'MODERATE';

      // Default target weight based on plan
      if (_plan.goal == 'LOSE') {
        _targetWeightController.text = (weight * 0.92).toStringAsFixed(1);
      } else if (_plan.goal == 'GAIN') {
        _targetWeightController.text = (weight * 1.06).toStringAsFixed(1);
      } else {
        _targetWeightController.text = weight.toStringAsFixed(1);
      }

      if (_plan.id == 'beginner_fitness_30') {
        _daysPerWeek = 3;
        _workoutDuration = 30;
        _experienceLevel = 'Beginner';
      }
    });

    _recalculateNutrition();
  }

  void _recalculateNutrition() {
    final age = int.tryParse(_ageController.text) ?? 25;
    final height = double.tryParse(_heightController.text) ?? 175.0;
    final weight = double.tryParse(_weightController.text) ?? 75.0;

    final tdee = TDEECalculator.calculateTDEE(
      gender: _selectedGender,
      weightKg: weight,
      heightCm: height,
      age: age,
      activityLevel: _activityLevel,
    );

    final targetCalories = TDEECalculator.calculateTargetCalories(
      tdee: tdee,
      goal: _plan.goal,
      gender: _selectedGender,
    );

    final macros = TDEECalculator.calculateMacros(
      targetCalories: targetCalories,
      goal: _plan.goal,
      weightKg: weight,
    );

    setState(() {
      _calculatedTDEE = tdee;
      _calculatedTargetCalories = targetCalories;
      _calculatedMacros = macros;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'Personalize Your Challenge',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorManager.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(tooltip: 'Back', 
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorManager.textPrimary,
            size: 16.sp,
          ),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator
            _buildStepIndicator(),
            Divider(color: ColorManager.divider, height: 1),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: _buildCurrentStep(),
              ),
            ),

            // Bottom Navigation Controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Profile', 'Training', 'Nutrition', 'Confirm'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? ColorManager.success
                              : (isCurrent ? ColorManager.primary : ColorManager.divider),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        steps[index],
                        style: TextStyle(
                          color: isCurrent
                              ? ColorManager.primary
                              : (isCompleted ? ColorManager.textPrimary : ColorManager.textTertiary),
                          fontSize: 11.sp,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1) SizedBox(width: 6.w),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Profile();
      case 1:
        return _buildStep2Training();
      case 2:
        return _buildStep3NutritionAndHealth();
      case 3:
      default:
        return _buildStep4ReviewAndCalibrate();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 1: Profile & Baseline Verification
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStep1Profile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified_user_rounded, color: ColorManager.primary, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'Profile & Metrics',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          'Reusing your saved Gym Buddy profile. Adjust if anything has changed.',
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
        ),
        SizedBox(height: 16.h),

        // Gender Selector
        Text(
          'Gender',
          style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            _buildSelectableChip('Male', _selectedGender == 'Male', () {
              setState(() => _selectedGender = 'Male');
              _recalculateNutrition();
            }),
            SizedBox(width: 10.w),
            _buildSelectableChip('Female', _selectedGender == 'Female', () {
              setState(() => _selectedGender = 'Female');
              _recalculateNutrition();
            }),
          ],
        ),
        SizedBox(height: 16.h),

        // Age, Height, Weight Row
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                label: 'Age',
                controller: _ageController,
                suffix: 'yrs',
                onChanged: (_) => _recalculateNutrition(),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildInputField(
                label: 'Height',
                controller: _heightController,
                suffix: 'cm',
                onChanged: (_) => _recalculateNutrition(),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildInputField(
                label: 'Weight',
                controller: _weightController,
                suffix: 'kg',
                onChanged: (_) => _recalculateNutrition(),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Target Weight
        _buildInputField(
          label: 'Target Weight (Goal for ${_plan.durationDays} Days)',
          controller: _targetWeightController,
          suffix: 'kg',
        ),
        SizedBox(height: 8.h),
        Text(
          'Target weight is used to measure progression milestones and safe weekly pace.',
          style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 2: Training Environment & Equipment
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStep2Training() {
    final equipmentOptions = [
      'Barbell',
      'Dumbbells',
      'Cables',
      'Machines',
      'Pull-up Bar',
      'Resistance Bands',
      'Bodyweight Only',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workout Environment',
          style: TextStyle(color: ColorManager.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.h),
        Text(
          'Where will you perform this transformation programme?',
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
        ),
        SizedBox(height: 12.h),

        // Location Selector
        Row(
          children: [
            Expanded(
              child: _buildLocationCard(
                title: 'Full Gym',
                icon: Icons.fitness_center_rounded,
                selected: _workoutLocation == 'gym',
                onTap: () {
                  setState(() {
                    _workoutLocation = 'gym';
                    _selectedEquipment.addAll({'Barbell', 'Dumbbells', 'Cables', 'Machines'});
                  });
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildLocationCard(
                title: 'Home Workout',
                icon: Icons.home_rounded,
                selected: _workoutLocation == 'home',
                onTap: () {
                  setState(() {
                    _workoutLocation = 'home';
                    _selectedEquipment.remove('Cables');
                    _selectedEquipment.remove('Machines');
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 18.h),

        // Workout Experience Level
        Text(
          'Workout Experience',
          style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6.h),
        Row(
          children: ['Beginner', 'Intermediate', 'Advanced'].map((lvl) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: _buildSelectableChip(
                  lvl,
                  _experienceLevel == lvl,
                  () => setState(() => _experienceLevel = lvl),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 18.h),

        // Available Equipment
        Text(
          'Available Equipment',
          style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: equipmentOptions.map((eq) {
            final isSelected = _selectedEquipment.contains(eq);
            return _buildSelectableChip(eq, isSelected, () {
              setState(() {
                if (isSelected) {
                  _selectedEquipment.remove(eq);
                } else {
                  _selectedEquipment.add(eq);
                }
              });
            });
          }).toList(),
        ),
        SizedBox(height: 18.h),

        // Workout Days / Week
        Text(
          'Available Training Days per Week: $_daysPerWeek Days',
          style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        Slider(
          value: _daysPerWeek.toDouble(),
          min: 3,
          max: 6,
          divisions: 3,
          activeColor: ColorManager.primary,
          inactiveColor: ColorManager.surfaceDark,
          onChanged: (val) => setState(() => _daysPerWeek = val.toInt()),
        ),

        // Preferred Workout Duration
        Text(
          'Target Workout Duration',
          style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6.h),
        Row(
          children: [30, 45, 60, 75].map((mins) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: _buildSelectableChip(
                  '$mins m',
                  _workoutDuration == mins,
                  () => setState(() => _workoutDuration = mins),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 3: Nutrition & Health Limitations
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStep3NutritionAndHealth() {
    final diets = ['Non-vegetarian', 'Vegetarian', 'Vegan', 'Other'];
    final allergies = ['None', 'Dairy', 'Gluten', 'Nuts', 'Shellfish'];
    final injuries = ['None', 'Lower Back', 'Knees', 'Shoulders', 'Wrists'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrition & Preferences',
          style: TextStyle(color: ColorManager.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.h),
        Text(
          'Tailors dietary advice, macro distributions, and meal suggestions.',
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
        ),
        SizedBox(height: 14.h),

        // Dietary Preference
        Text(
          'Dietary Type',
          style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: diets.map((d) {
            return _buildSelectableChip(d, _dietaryPreference == d, () {
              setState(() => _dietaryPreference = d);
            });
          }).toList(),
        ),
        SizedBox(height: 16.h),

        // Food Allergies
        Text(
          'Food Allergies / Intolerances',
          style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: allergies.map((a) {
            final isSelected = _selectedAllergies.contains(a);
            return _buildSelectableChip(a, isSelected, () {
              setState(() {
                if (a == 'None') {
                  _selectedAllergies.clear();
                  _selectedAllergies.add('None');
                } else {
                  _selectedAllergies.remove('None');
                  if (isSelected) {
                    _selectedAllergies.remove(a);
                    if (_selectedAllergies.isEmpty) _selectedAllergies.add('None');
                  } else {
                    _selectedAllergies.add(a);
                  }
                }
              });
            });
          }).toList(),
        ),
        SizedBox(height: 16.h),

        // Physical Limitations / Injuries
        Text(
          'Injuries or Joint Restrictions',
          style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.h),
        Text(
          'Exercises stressing affected joints will suggest safer alternatives.',
          style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: injuries.map((inj) {
            final isSelected = _selectedInjuries.contains(inj);
            return _buildSelectableChip(inj, isSelected, () {
              setState(() {
                if (inj == 'None') {
                  _selectedInjuries.clear();
                  _selectedInjuries.add('None');
                } else {
                  _selectedInjuries.remove('None');
                  if (isSelected) {
                    _selectedInjuries.remove(inj);
                    if (_selectedInjuries.isEmpty) _selectedInjuries.add('None');
                  } else {
                    _selectedInjuries.add(inj);
                  }
                }
              });
            });
          }).toList(),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 4: Calibrated Targets & Final Confirmation
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStep4ReviewAndCalibrate() {
    _recalculateNutrition();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_plan.iconEmoji, style: TextStyle(fontSize: 20.sp)),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _plan.title,
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_plan.durationDays} Days • ${_plan.phases.length} Progressive Phases',
                    style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Calibrated Nutrition Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorManager.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'CALIBRATED NUTRITION TARGET',
                      style: TextStyle(
                        color: ColorManager.primary,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '${_calculatedTDEE.toStringAsFixed(0)} kcal TDEE',
                    style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _calculatedTargetCalories.toStringAsFixed(0),
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'kcal / day',
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Macro Pills
              Row(
                children: [
                  _buildMacroPill('Protein', '${_calculatedMacros['protein']?.toStringAsFixed(0)}g', ColorManager.accent),
                  SizedBox(width: 8.w),
                  _buildMacroPill('Carbs', '${_calculatedMacros['carbs']?.toStringAsFixed(0)}g', ColorManager.primary),
                  SizedBox(width: 8.w),
                  _buildMacroPill('Fats', '${_calculatedMacros['fat']?.toStringAsFixed(0)}g', ColorManager.warning),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                'Note: Calorie and macro values are scientifically estimated baselines. Individual metabolism and rate of progress vary.',
                style: TextStyle(
                  color: ColorManager.textTertiary,
                  fontSize: 11.sp,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Personalized Summary Card
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: ColorManager.surfaceDark,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalized Training Setup',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              _buildSummaryRow('Environment', _workoutLocation == 'gym' ? 'Full Gym' : 'Home Workout'),
              _buildSummaryRow('Experience', _experienceLevel),
              _buildSummaryRow('Schedule', '$_daysPerWeek Days/Week (${_workoutDuration}m/session)'),
              _buildSummaryRow('Diet', _dietaryPreference),
              if (!_selectedInjuries.contains('None'))
                _buildSummaryRow('Restrictions', _selectedInjuries.join(', ')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp)),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: ColorManager.textPrimary, fontSize: 11.sp, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String name, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 13.sp, fontWeight: FontWeight.bold)),
            Text(name, style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: ColorManager.textPrimary, fontSize: 12.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: ColorManager.textPrimary, fontSize: 14.sp),
          onChanged: onChanged,
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
            filled: true,
            fillColor: ColorManager.surface,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: ColorManager.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: ColorManager.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: ColorManager.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? ColorManager.primary : ColorManager.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? ColorManager.primary : ColorManager.divider,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : ColorManager.textPrimary,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: selected ? ColorManager.primary.withValues(alpha: 0.12) : ColorManager.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? ColorManager.primary : ColorManager.divider,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28.sp, color: selected ? ColorManager.primary : ColorManager.textSecondary),
            SizedBox(height: 6.h),
            Text(
              title,
              style: TextStyle(
                color: selected ? ColorManager.primary : ColorManager.textPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final isLastStep = _currentStep == 3;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        border: Border(top: BorderSide(color: ColorManager.divider)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ColorManager.divider),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Back', style: TextStyle(color: ColorManager.textPrimary)),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              key: const Key('onboarding_next_or_confirm_button'),
              onPressed: isLastStep ? _handleConfirmEnrolment : () => setState(() => _currentStep++),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 0,
              ),
              child: Text(
                isLastStep ? 'Launch Programme Roadmap' : 'Continue',
                style: TextStyle(color: ColorManager.onMint, fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirmEnrolment() async {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider?>(context, listen: false);
    final isPremium = subscriptionProvider?.isPremium ?? false;
    if (!isPremium) {
      if (mounted) {
        context.push(Routes.premiumScreen);
      }
      return;
    }

    final provider = Provider.of<TransformationProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider?>(context, listen: false);
    final userData = homeProvider?.userData ?? {};

    final startingWeight = double.tryParse(_weightController.text) ??
        (userData['weight'] as num?)?.toDouble();
    final targetWeight = double.tryParse(_targetWeightController.text);

    final startingMeasurements = <String, double>{};
    for (final key in ['waist', 'chest', 'biceps', 'hips', 'thigh']) {
      final val = userData[key];
      if (val is num) {
        startingMeasurements[key] = val.toDouble();
      }
    }

    await provider.enrollInPlan(
      blueprint: _plan,
      subscriptionProvider: subscriptionProvider,
      targetCalories: _calculatedTargetCalories,
      targetMacros: _calculatedMacros,
      workoutLocation: _workoutLocation,
      experienceLevel: _experienceLevel,
      availableEquipment: _selectedEquipment.toList(),
      dietaryPreference: _dietaryPreference,
      foodRestrictions: _selectedAllergies.contains('None') ? '' : _selectedAllergies.join(', '),
      allergies: _selectedAllergies.contains('None') ? [] : _selectedAllergies.toList(),
      injuries: _selectedInjuries.contains('None') ? '' : _selectedInjuries.join(', '),
      workoutDurationMinutes: _workoutDuration,
      workoutDaysPerWeek: _daysPerWeek,
      startingWeight: startingWeight,
      targetWeight: targetWeight,
      startingMeasurements: startingMeasurements,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Personalized Roadmap generated for ${_plan.title}!'),
          backgroundColor: ColorManager.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate to Roadmap
      context.pushReplacement(Routes.transformationRoadmapRoute);
    }
  }
}
