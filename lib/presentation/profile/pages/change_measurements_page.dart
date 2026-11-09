import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/profile/providers/profile_provider.dart';
import 'package:fitness_app/presentation/progress/progress_data.dart';
import 'package:fitness_app/presentation/settings/widgets/change_password_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/widgets/lime_green_rounded_button.dart';
import 'package:fitness_app/utils/widgets/text_field_widget.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';

class ChangeMeasurementsPage extends StatefulWidget {
  const ChangeMeasurementsPage({super.key});

  @override
  State<ChangeMeasurementsPage> createState() => _ChangeMeasurementsPageState();
}

class _ChangeMeasurementsPageState extends State<ChangeMeasurementsPage> {
  final TextEditingController _chestController = TextEditingController();
  final TextEditingController _shoulderController = TextEditingController();
  final TextEditingController _bicepsController = TextEditingController();
  final TextEditingController _foreArmController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _hipsController = TextEditingController();
  final TextEditingController _thighCotroller = TextEditingController();
  final TextEditingController _calfController = TextEditingController();

  String? _valueActivity;
  String? _valueGoals;

  @override
  void initState() {
    super.initState();
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    _chestController.text = ProgressData.prefill(homeProvider.userData['chest']);
    _shoulderController.text = ProgressData.prefill(homeProvider.userData['shoulders']);
    _bicepsController.text = ProgressData.prefill(homeProvider.userData['biceps']);
    _foreArmController.text = ProgressData.prefill(homeProvider.userData['foreArm']);
    _waistController.text = ProgressData.prefill(homeProvider.userData['waist']);
    _hipsController.text = ProgressData.prefill(homeProvider.userData['hips']);
    _thighCotroller.text = ProgressData.prefill(homeProvider.userData['thigh']);
    _calfController.text = ProgressData.prefill(homeProvider.userData['calf']);
    _valueActivity = homeProvider.userData['activity'];
    _valueGoals = homeProvider.userData['goal'];
  }

  @override
  void dispose() {
    super.dispose();
    _chestController.dispose();
    _shoulderController.dispose();
    _bicepsController.dispose();
    _foreArmController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _thighCotroller.dispose();
    _calfController.dispose();
  }

  void _onChangedActivity(Object? selectedActivityValue) {
    if (selectedActivityValue is String) {
      setState(() {
        _valueActivity = selectedActivityValue;
      });
    }
  }

  void _onChangedGoals(Object? selectedGoalsValue) {
    if (selectedGoalsValue is String) {
      setState(() {
        _valueGoals = selectedGoalsValue;
      });
    }
  }

  bool _saving = false;

  /// Reads one field. A blank field keeps the previously saved value, so
  /// users can update just one measurement.
  double? _readField(TextEditingController c, String key) {
    final typed = ProgressData.parseNumber(c.text);
    if (typed != null) return typed;
    final previous = Provider.of<HomeProvider>(context, listen: false)
        .userData[key];
    return previous is num && previous > 0 ? previous.toDouble() : null;
  }

  /// First validation error, or null when everything can be saved.
  String? _validate() {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final fields = <(TextEditingController, String, String)>[
      (_chestController, 'chest', 'Chest'),
      (_shoulderController, 'shoulders', 'Shoulders'),
      (_bicepsController, 'biceps', 'Biceps'),
      (_foreArmController, 'foreArm', 'Forearm'),
      (_waistController, 'waist', 'Waist'),
      (_hipsController, 'hips', 'Hips'),
      (_thighCotroller, 'thigh', 'Thigh'),
      (_calfController, 'calf', 'Calf'),
    ];
    for (final (controller, key, name) in fields) {
      final previous = homeProvider.userData[key];
      final hasPrevious = previous is num && previous > 0;
      final error = ProgressData.validateMeasurement(
        controller.text,
        name,
        allowBlank: hasPrevious,
      );
      if (error != null) return error;
    }
    return null;
  }

  Future<void> updateUsersMeasurements() async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);

    final chest = _readField(_chestController, 'chest')!;
    final shoulders = _readField(_shoulderController, 'shoulders')!;
    final biceps = _readField(_bicepsController, 'biceps')!;
    final foreArm = _readField(_foreArmController, 'foreArm')!;
    final waist = _readField(_waistController, 'waist')!;
    final hips = _readField(_hipsController, 'hips')!;
    final thigh = _readField(_thighCotroller, 'thigh')!;
    final calf = _readField(_calfController, 'calf')!;

    await homeProvider.getUsersBMR(
      gender: homeProvider.userData['gender'],
      weight: homeProvider.userData['weight'],
      height: homeProvider.userData['height'],
      age: homeProvider.userData['age'],
      activity: _valueActivity!,
      goal: _valueGoals!,
    );
    await homeProvider.getUsersBMI(
      height: homeProvider.userData['height'],
      weight: homeProvider.userData['weight'],
    );
    if (!mounted) return;
    await profileProvider.updateUsersData(
      bmr: homeProvider.userBMRwithGoal,
      activity: _valueActivity!,
      context: context,
      goal: _valueGoals!,
      chest: chest,
      shoulders: shoulders,
      biceps: biceps,
      foreArm: foreArm,
      waist: waist,
      hips: hips,
      thigh: thigh,
      calf: calf,
    );
  }

  Future<void> _onSavePressed() async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);

    final error = _validate();
    if (error != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (_valueActivity == null || _valueGoals == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Please choose your activity level and goal')),
        );
      return;
    }

    _saving = true;
    LoadingOverlay.show(context, message: 'Updating measurements...');
    try {
      await updateUsersMeasurements();
      await Provider.of<HomeProvider>(context, listen: false).fetchUserData();
      if (mounted) {
        LoadingOverlay.hide(context);
        Navigator.of(context).pop();
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Measurements saved')));
    } catch (e) {
      debugPrint('Error saving measurements: $e');
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Couldn't save your measurements. Check your connection and try again."),
          ),
        );
    } finally {
      _saving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: PreferredSize(
        preferredSize: Size(
          double.infinity,
          SizeManager.s60.h,
        ),
        child: const ChangeDataPagesAppBar(),
      ),
      body: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(PaddingManager.p28),
                    child: Text(
                      StringsManager.changeMeasurementsText,
                      textAlign: TextAlign.center,
                      style: StyleManager.settingsOptionTiteTextStyle,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(PaddingManager.p28),
                    child: Column(
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: PaddingManager.p12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 8.w),
                                  child: TextFieldWidget(
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    controller: _chestController,
                                    labelHint: StringsManager.chest,
                                    obscureText: false,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8.w),
                                  child: TextFieldWidget(
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    controller: _shoulderController,
                                    labelHint: StringsManager.shoulders,
                                    obscureText: false,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: PaddingManager.p12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 8.w),
                                  child: TextFieldWidget(
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    controller: _bicepsController,
                                    labelHint: StringsManager.biceps,
                                    obscureText: false,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8.w),
                                  child: TextFieldWidget(
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    controller: _foreArmController,
                                    labelHint: StringsManager.foreArm,
                                    obscureText: false,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: PaddingManager.p12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 8.w),
                                  child: TextFieldWidget(
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    controller: _waistController,
                                    labelHint: StringsManager.waist,
                                    obscureText: false,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8.w),
                                  child: TextFieldWidget(
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    controller: _hipsController,
                                    labelHint: StringsManager.hips,
                                    obscureText: false,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: PaddingManager.p12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 8.w),
                                  child: TextFieldWidget(
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    controller: _thighCotroller,
                                    labelHint: StringsManager.thigh,
                                    obscureText: false,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8.w),
                                  child: TextFieldWidget(
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    controller: _calfController,
                                    labelHint: StringsManager.calf,
                                    obscureText: false,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(top: PaddingManager.p56),
                          child: Container(
                            width: SizeManager.s400.w,
                            height: SizeManager.s50.h,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: ColorManager.limerGreen2,
                                  width: SizeManager.s0_7.h,
                                ),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2(
                                // dropdownDecoration: BoxDecoration(
                                //   color: ColorManager.darkGrey,
                                //   borderRadius: BorderRadius.circular(
                                //     RadiusManager.r15.r,
                                //   ),
                                // ),
                                onChanged: _onChangedActivity,
                                value: _valueActivity,
                                // iconSize: SizeManager.s0,
                                hint: Text(
                                  StringsManager.activityHint,
                                  style:
                                      StyleManager.registerTextfieldTextStyle,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: StringsManager.activityLowHint,
                                    child: Text(
                                      StringsManager.activityLowHint,
                                      style: StyleManager
                                          .registerTextfieldTextStyle,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: StringsManager.activityLightHint,
                                    child: Text(
                                      StringsManager.activityLightHint,
                                      style: StyleManager
                                          .registerTextfieldTextStyle,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: StringsManager.activityModerateHint,
                                    child: Text(
                                      StringsManager.activityModerateHint,
                                      style: StyleManager
                                          .registerTextfieldTextStyle,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: StringsManager.activityHighHint,
                                    child: Text(
                                      StringsManager.activityHighHint,
                                      style: StyleManager
                                          .registerTextfieldTextStyle,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: StringsManager.activityVeryHighHint,
                                    child: Text(
                                      StringsManager.activityVeryHighHint,
                                      style: StyleManager
                                          .registerTextfieldTextStyle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(top: PaddingManager.p28),
                          child: Container(
                            width: SizeManager.s400.w,
                            height: SizeManager.s50.h,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: ColorManager.limerGreen2,
                                  width: SizeManager.s0_7.h,
                                ),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2(
                                // dropdownDecoration: BoxDecoration(
                                //   color: ColorManager.darkGrey,
                                //   borderRadius: BorderRadius.circular(
                                //     RadiusManager.r15.r,
                                //   ),
                                // ),
                                onChanged: _onChangedGoals,
                                value: _valueGoals,
                                // iconSize: SizeManager.s0,
                                hint: Text(
                                  StringsManager.goalHint,
                                  style:
                                      StyleManager.registerTextfieldTextStyle,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: StringsManager.lose,
                                    child: Text(
                                      StringsManager.loseWeightHint,
                                      style: StyleManager
                                          .registerTextfieldTextStyle,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: StringsManager.maintain,
                                    child: Text(
                                      StringsManager.maintainWeightHint,
                                      style: StyleManager
                                          .registerTextfieldTextStyle,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: StringsManager.gain,
                                    child: Text(
                                      StringsManager.gainWeightHint,
                                      style: StyleManager
                                          .registerTextfieldTextStyle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  LimeGreenRoundedButtonWidget(
                    onTap: _onSavePressed,
                    title: StringsManager.next,
                  )
                ],
              ),
            ),
          )),
    ).animate().fadeIn(
          duration: 500.ms,
        );
  }
}
