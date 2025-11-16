import 'package:fitness_app/presentation/settings/providers/settings_provider.dart';
import 'package:fitness_app/presentation/settings/widgets/delete_account_app_bar.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/widgets/lime_green_rounded_button.dart';
import 'package:fitness_app/utils/widgets/text_field_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isGoogleUser = false;

  @override
  void initState() {
    super.initState();
    _checkUserProvider();
  }

  void _checkUserProvider() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Check if user signed in with Google
      _isGoogleUser = user.providerData
          .any((provider) => provider.providerId == 'google.com');

      if (_isGoogleUser) {
        // Pre-fill email for Google users
        _emailController.text = user.email ?? '';
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    Future<void> deleteAccount() async {
      if (isValid) {
        try {
          await settingsProvider
              .deleteUser(
            email: _emailController.text,
            password: _passwordController.text,
            isGoogleUser: _isGoogleUser,
          )
              .then((value) {
            setState(() {
              settingsProvider.signOut(context: context);
              context.push(Routes.loginRoute);
            });
          });
        } catch (e) {
          rethrow;
        }
      } else {
        Navigator.of(context).pop();
      }
    }

    popUp() {
      return showDialog(
          barrierDismissible: false,
          context: context,
          builder: (_) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RadiusManager.r15.r),
              ),
              titleTextStyle: StyleManager.deleteAccPopUpTitleTextStyle,
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              backgroundColor: ColorManager.darkGrey,
              title: const Text(
                StringsManager.uSure,
                textAlign: TextAlign.center,
              ),
              actions: [
                GestureDetector(
                  onTap: deleteAccount,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorManager.grey3,
                      borderRadius: BorderRadius.circular(RadiusManager.r15.r),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(PaddingManager.p8),
                      child: Text(
                        StringsManager.yes,
                        style: StyleManager.deleteAccPopUpButtonTextStyle,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorManager.grey3,
                      borderRadius: BorderRadius.circular(RadiusManager.r15.r),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: PaddingManager.p8,
                        bottom: PaddingManager.p8,
                        right: PaddingManager.p14,
                        left: PaddingManager.p14,
                      ),
                      child: Text(
                        StringsManager.no,
                        style: StyleManager.deleteAccPopUpButtonTextStyle,
                      ),
                    ),
                  ),
                )
              ],
            );
          });
    }

    return Scaffold(
      backgroundColor: ColorManager.darkGrey,
      appBar: PreferredSize(
        preferredSize: Size(
          double.infinity,
          SizeManager.s60.h,
        ),
        child: const DeleteAccountPageAppBar(),
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
                      _isGoogleUser
                          ? 'To delete your account, please confirm your email address below. This action cannot be undone.'
                          : StringsManager.deleteAccContent,
                      textAlign: TextAlign.center,
                      style: StyleManager.settingsOptionTiteTextStyle,
                    ),
                  ),
                  if (_isGoogleUser)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: PaddingManager.p28,
                        right: PaddingManager.p28,
                        bottom: PaddingManager.p20,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(PaddingManager.p12),
                        decoration: BoxDecoration(
                          color: ColorManager.limerGreen2.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(SizeManager.s8.r),
                          border: Border.all(
                            color: ColorManager.limerGreen2.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: ColorManager.limerGreen2,
                              size: SizeManager.s20.sp,
                            ),
                            SizedBox(width: SizeManager.s8.w),
                            Expanded(
                              child: Text(
                                'Since you signed in with Google, you only need to confirm your email address.',
                                style: StyleManager.settingsOptionTiteTextStyle
                                    .copyWith(
                                  fontSize: SizeManager.s12.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                    child: TextFieldWidget(
                      controller: _emailController,
                      labelHint: StringsManager.emailHint,
                      obscureText: false,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  if (!_isGoogleUser)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                      child: TextFieldWidget(
                        controller: _passwordController,
                        labelHint: StringsManager.passwordHint,
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: true,
                      ),
                    ),
                  LimeGreenRoundedButtonWidget(
                    onTap: popUp,
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

  bool get isValid {
    if (_isGoogleUser) {
      // For Google users, only email is required
      return _emailController.text.isNotEmpty;
    } else {
      // For regular users, both email and password required
      return _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    }
  }
}
