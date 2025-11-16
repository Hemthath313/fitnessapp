import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/presentation/workouts/widgets/workouts_app_bar.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/list_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/widgets/lime_green_rounded_button.dart';
import 'package:fitness_app/utils/widgets/text_field_widget.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class NewExercisePage extends StatefulWidget {
  const NewExercisePage({super.key});

  @override
  State<NewExercisePage> createState() => _NewExercisePageState();
}

class _NewExercisePageState extends State<NewExercisePage> {
  final TextEditingController _setNumberController = TextEditingController();
  final TextEditingController _repNumberController = TextEditingController();

  String? _valueExercise;

  @override
  void dispose() {
    _setNumberController.dispose();
    _repNumberController.dispose();

    super.dispose();
  }

  void _onChangedExercise(Object? selectedGenderValue) {
    if (selectedGenderValue is String) {
      setState(() {
        _valueExercise = selectedGenderValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(
          deviceWidth,
          SizeManager.s60.h,
        ),
        child: const NewExercisePageAppBar(),
      ),
      backgroundColor: ColorManager.darkGrey,
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: PaddingManager.p8),
                child: SizedBox(
                  width: SizeManager.s250.w,
                  height: SizeManager.s250.h,
                  child: Image.asset(
                    ImageManager.exerciseLogo,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: PaddingManager.p28,
                  right: PaddingManager.p28,
                ),
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
                      // dropdownMaxHeight: deviceHeight / 2,
                      // dropdownDecoration: BoxDecoration(
                      //   color: ColorManager.darkGrey,
                      //   borderRadius: BorderRadius.circular(
                      //     RadiusManager.r15.r,
                      //   ),
                      // ),
                      onChanged: _onChangedExercise,
                      value: _valueExercise,
                      hint: Text(
                        StringsManager.exerciseHint,
                        style: StyleManager.registerTextfieldTextStyle,
                      ),
                      items: ListManager.exercisesList,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(PaddingManager.p28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: TextFieldWidget(
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          controller: _setNumberController,
                          labelHint: StringsManager.setNumberHint,
                          obscureText: false,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 8.w),
                        child: TextFieldWidget(
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          controller: _repNumberController,
                          labelHint: StringsManager.repNumberHint,
                          keyboardType: TextInputType.number,
                          obscureText: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              LimeGreenRoundedButtonWidget(
                onTap: () async {
                  LoadingOverlay.show(context, message: 'Adding workout...');
                  try {
                    await workoutProvider.addNewWorkout(
                      name: _valueExercise!,
                      repNumber: int.parse(_repNumberController.text),
                      setNumber: int.parse(_setNumberController.text),
                      dateTime: DateTime.now(),
                    );
                    await workoutProvider.getProgressPercent();
                    if (context.mounted) {
                      LoadingOverlay.hide(context);
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      LoadingOverlay.hide(context);
                    }
                    rethrow;
                  }
                },
                title: StringsManager.add,
              )
            ],
          ),
        ),
      ),
    );
  }
}
