import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/profile/providers/profile_provider.dart';
import 'package:fitness_app/presentation/settings/widgets/change_password_app_bar.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/widgets/lime_green_rounded_button.dart';
import 'package:fitness_app/utils/widgets/text_field_widget.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ChangeWeightPage extends StatefulWidget {
  const ChangeWeightPage({super.key});

  @override
  State<ChangeWeightPage> createState() => _ChangeWeightPageState();
}

class _ChangeWeightPageState extends State<ChangeWeightPage> {
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    _weightController.text = homeProvider.userData['weight'].toString();
    super.initState();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> changeWeight() async {
    LoadingOverlay.show(context, message: 'Updating weight...');
    
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    try {
      await homeProvider
          .getUsersBMI(
            height: homeProvider.userData['height'],
            weight: double.parse(_weightController.text),
          )
          .then((_) => homeProvider.getUsersBMR(
                gender: homeProvider.userData['gender'],
                weight: double.parse(_weightController.text),
                height: homeProvider.userData['height'],
                age: homeProvider.userData['age'],
                activity: homeProvider.userData['activity'],
                goal: homeProvider.userData['goal'],
              ))
          .then(
            (_) => profileProvider.changeUsersWeight(
              bmi: homeProvider.usersBMI,
              bmr: homeProvider.userBMRwithGoal,
              weight: double.parse(_weightController.text),
              weightDateTime: DateTime.now().month,
              context: context,
            ),
          )
          .then(
            (_) => homeProvider.fetchUserData(),
          )
          .then(
            (_) {
              if (context.mounted) {
                LoadingOverlay.hide(context);
                Navigator.of(context).pop();
              }
            },
          );
    } catch (e) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.darkGrey,
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
                      StringsManager.changeWeightText,
                      textAlign: TextAlign.center,
                      style: StyleManager.settingsOptionTiteTextStyle,
                    ),
                  ),
                  SizedBox(
                    child: Image.asset(
                      ImageManager.weight,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                    child: TextFieldWidget(
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      controller: _weightController,
                      labelHint: StringsManager.weightHint,
                      obscureText: false,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  LimeGreenRoundedButtonWidget(
                    onTap: changeWeight,
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
