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
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'Log Weight',
          style: TextStyle(
            color: ColorManager.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorManager.background,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.white),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 30.h),
              // Scale Icon in circle
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorManager.primary.withOpacity(0.15), width: 2),
                ),
                child: Icon(
                  Icons.scale,
                  color: ColorManager.primary,
                  size: 56.sp,
                ),
              ),
              SizedBox(height: 32.h),
              
              // Helper text
              Text(
                'Enter your current weight:',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              
              // Custom interactive weight input
              Center(
                child: Container(
                  width: 160.w,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: ColorManager.surface,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: ColorManager.divider),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      IntrinsicWidth(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          style: TextStyle(
                            color: ColorManager.white,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'kg',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              
              // Detailed Tip Text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'Keeping your weight up to date ensures your calorie budgets, progress charts, and training intensity recommendations remain accurate.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 48.h),
              
              // Continue button
              LimeGreenRoundedButtonWidget(
                onTap: changeWeight,
                title: StringsManager.next,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
          duration: 500.ms,
        );
  }
}
