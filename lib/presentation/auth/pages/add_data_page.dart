import 'package:fitness_app/presentation/auth/widgets/add_data_widgets.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/utils/widgets/lime_green_rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../home/providers/home_provider.dart';
import '../providers/auth_provider.dart';

class AddDataPage extends StatefulWidget {
  const AddDataPage({super.key});

  @override
  State<AddDataPage> createState() => _AddDataPageState();
}

class _AddDataPageState extends State<AddDataPage> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String? _valueGender;
  String? _valueActivity;
  String? _valueGoal;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  void _onChangedGender(Object? selectedGenderValue) {
    if (selectedGenderValue is String) {
      setState(() {
        _valueGender = selectedGenderValue;
      });
    }
  }

  void _onChangedActivity(Object? selectedActivityValue) {
    if (selectedActivityValue is String) {
      setState(() {
        _valueActivity = selectedActivityValue;
      });
    }
  }

  void _onChangedGoal(Object? selectedGoalValue) {
    if (selectedGoalValue is String) {
      setState(() {
        _valueGoal = selectedGoalValue;
      });
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> validateAndSubmit() async {
    if (_isSubmitting) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Name is required');
      return;
    }

    final surname = _surnameController.text.trim();
    if (surname.isEmpty) {
      _showSnackBar('Surname is required');
      return;
    }

    final ageText = _ageController.text.trim();
    if (ageText.isEmpty) {
      _showSnackBar('Age is required');
      return;
    }
    final age = int.tryParse(ageText);
    if (age == null) {
      _showSnackBar('Please enter a valid age');
      return;
    }
    if (age < 13 || age > 120) {
      _showSnackBar('Age must be between 13 and 120');
      return;
    }

    final heightText = _heightController.text.trim();
    if (heightText.isEmpty) {
      _showSnackBar('Height is required');
      return;
    }
    final height = double.tryParse(heightText);
    if (height == null) {
      _showSnackBar('Please enter a valid height');
      return;
    }
    if (height < 50 || height > 260) {
      _showSnackBar('Height must be between 50 and 260 cm');
      return;
    }

    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      _showSnackBar('Weight is required');
      return;
    }
    final weight = double.tryParse(weightText);
    if (weight == null) {
      _showSnackBar('Please enter a valid weight');
      return;
    }
    if (weight < 20 || weight > 400) {
      _showSnackBar('Weight must be between 20 and 400 kg');
      return;
    }

    if (_valueGender == null) {
      _showSnackBar('Please select gender');
      return;
    }
    if (_valueActivity == null) {
      _showSnackBar('Please select activity level');
      return;
    }
    if (_valueGoal == null) {
      _showSnackBar('Please select a goal');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await addUserData(
        age: age,
        height: height,
        weight: weight,
        name: name,
        surname: surname,
        gender: _valueGender!,
        activity: _valueActivity!,
        goal: _valueGoal!,
      );

      if (success && mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final uid = authProvider.currentUserId;
        if (uid != null) {
          await AuthProvider.setCachedOnboardingStatus(uid, true);
        }
        if (mounted) {
          context.go(Routes.mainRoute);
        }
      }
    } catch (e) {
      _showSnackBar('Failed to save profile: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<bool> addUserData({
    required int age,
    required double height,
    required double weight,
    required String name,
    required String surname,
    required String gender,
    required String activity,
    required String goal,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final email = authProvider.user?.email ?? '';

    try {
      await homeProvider.getUsersBMR(
        gender: gender,
        weight: weight,
        height: height,
        age: age,
        activity: activity,
        goal: goal,
      );

      await homeProvider.getUsersBMI(
        height: height,
        weight: weight,
      );

      if (!mounted) return false;

      await authProvider.addUserData(
        email: email,
        name: name,
        surname: surname,
        age: age,
        context: context,
        gender: gender,
        height: height,
        weight: weight,
        activity: activity,
        bmr: homeProvider.userBMRwithGoal,
        goal: goal,
        bmi: homeProvider.usersBMI,
      );

      return true;
    } catch (e) {
      _showSnackBar('Failed to save data: ${e.toString()}');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: ColorManager.background,
        elevation: SizeManager.s0,
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: PaddingManager.p28),
                child: Center(
                  child: Text(
                    StringsManager.enterData,
                    textAlign: TextAlign.center,
                    style: StyleManager.addDataTitleTextStyle,
                  ),
                ),
              ),
              AddDataWidgets(
                ageController: _ageController,
                heightController: _heightController,
                weightController: _weightController,
                onChangedGender: _onChangedGender,
                valueGender: _valueGender,
                valueActivity: _valueActivity,
                onChangedActivity: _onChangedActivity,
                nameController: _nameController,
                surnameController: _surnameController,
                valueGoal: _valueGoal,
                onChangedGoal: _onChangedGoal,
              ),
              LimeGreenRoundedButtonWidget(
                isLoading: _isSubmitting,
                onTap: validateAndSubmit,
                title: StringsManager.next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
