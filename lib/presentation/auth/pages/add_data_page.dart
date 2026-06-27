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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> validateAndSubmit() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Name is required');
      return;
    }
    if (_surnameController.text.trim().isEmpty) {
      _showSnackBar('Surname is required');
      return;
    }
    if (_ageController.text.trim().isEmpty) {
      _showSnackBar('Age is required');
      return;
    }
    if (_heightController.text.trim().isEmpty) {
      _showSnackBar('Height is required');
      return;
    }
    if (_weightController.text.trim().isEmpty) {
      _showSnackBar('Weight is required');
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

    // All fields are valid, proceed to add data.
    await addUserData();
    context.go(Routes.mainRoute);
  }

  Future<void> addUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final email = authProvider.user!.email;

    try {
      await homeProvider
          .getUsersBMR(
            gender: _valueGender!,
            weight: double.parse(_weightController.text),
            height: double.parse(_heightController.text),
            age: int.parse(_ageController.text),
            activity: _valueActivity!,
            goal: _valueGoal!,
          )
          .then((_) => homeProvider.getUsersBMI(
                height: double.parse(_heightController.text),
                weight: double.parse(_weightController.text),
              ))
          .then(
            (_) => authProvider.addUserData(
              email: email!,
              name: _nameController.text,
              surname: _surnameController.text,
              age: int.parse(_ageController.text),
              context: context,
              gender: _valueGender!,
              height: double.parse(_heightController.text),
              weight: double.parse(_weightController.text),
              activity: _valueActivity!,
              bmr: homeProvider.userBMRwithGoal,
              goal: _valueGoal!,
              bmi: homeProvider.usersBMI,
            ),
          );
    } catch (e) {
      _showSnackBar('Failed to save data: ${e.toString()}');
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
