import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/profile/profile_data.dart';
import 'package:fitness_app/presentation/profile/providers/profile_provider.dart';
import 'package:fitness_app/presentation/progress/progress_data.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/widgets/lime_green_rounded_button.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:fitness_app/utils/widgets/text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// Edit the personal details that sign-up collected (name, age, height,
/// gender). BMI and the daily calorie target depend on age, height and
/// gender, so they are recalculated when these change.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _surname = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _height = TextEditingController();
  String? _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = Provider.of<HomeProvider>(context, listen: false).userData;
    _firstName.text = (data['first name'] ?? '').toString();
    _surname.text = (data['surname'] ?? '').toString();
    _age.text = ProgressData.prefill(data['age']);
    _height.text = ProgressData.prefill(data['height']);
    final gender = data['gender'];
    _gender = ProfileData.genders.contains(gender) ? gender as String : null;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _surname.dispose();
    _age.dispose();
    _height.dispose();
    super.dispose();
  }

  String? _firstError() =>
      ProfileData.validateName(_firstName.text, 'First name') ??
      ProfileData.validateName(_surname.text, 'Surname', required: false) ??
      ProfileData.validateAge(_age.text) ??
      ProfileData.validateHeight(_height.text) ??
      ProfileData.validateGender(_gender);

  Future<void> _save() async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);

    final error = _firstError();
    if (error != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final firstName = _firstName.text.trim();
    final surname = _surname.text.trim();
    final age = ProfileData.parseAge(_age.text)!;
    final height = ProfileData.parseHeight(_height.text)!;
    final gender = _gender!;

    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    _saving = true;
    LoadingOverlay.show(context, message: 'Saving profile...');
    try {
      // Age, height and gender feed BMI and the calorie target. Recalculate
      // when we have what is needed; a profile without a valid activity or
      // goal yet still saves its personal details.
      final data = homeProvider.userData;
      final weight = (data['weight'] as num?)?.toDouble() ?? 0;
      double? bmi;
      double? bmr;
      if (weight > 0) {
        try {
          bmi = await homeProvider.getUsersBMI(height: height, weight: weight);
          bmr = await homeProvider.getUsersBMR(
            gender: gender,
            weight: weight,
            height: height,
            age: age,
            activity: (data['activity'] ?? '').toString(),
            goal: (data['goal'] ?? '').toString(),
          );
        } catch (e) {
          debugPrint('Skipping BMR recalculation: $e');
          bmr = null;
        }
      }

      await profileProvider.updatePersonalInfo(
        firstName: firstName,
        surname: surname,
        age: age,
        height: height,
        gender: gender,
        bmi: bmi,
        bmr: bmr,
      );
      await homeProvider.fetchUserData();

      if (mounted) {
        LoadingOverlay.hide(context);
        Navigator.of(context).pop();
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Couldn't save your profile. Check your connection and try again."),
          ),
        );
    } finally {
      _saving = false;
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: TextFieldWidget(
        controller: controller,
        labelHint: label,
        obscureText: false,
        keyboardType: keyboardType,
        inputFormatters: formatters,
      ),
    );
  }

  Widget _genderChoice(String value) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? ColorManager.mintGradient : null,
            color: selected ? null : ColorManager.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected ? Colors.transparent : ColorManager.divider,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: selected ? ColorManager.onMint : ColorManager.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorManager.background,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your age, height and gender are used to work out your BMI '
                'and daily calorie target, so keep them up to date.',
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              _field(_firstName, 'First name'),
              _field(_surname, 'Surname (optional)'),
              _field(
                _age,
                'Age',
                keyboardType: TextInputType.number,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
              _field(
                _height,
                'Height (cm)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'Gender',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  _genderChoice(ProfileData.male),
                  SizedBox(width: 12.w),
                  _genderChoice(ProfileData.female),
                ],
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: LimeGreenRoundedButtonWidget(
                  onTap: _save,
                  title: 'Save',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
