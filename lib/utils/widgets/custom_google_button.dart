import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomGoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;

  const CustomGoogleSignInButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50.h,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: ColorManager.limeGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             FaIcon(FontAwesomeIcons.google, color: ColorManager.limerGreen2),
            SizedBox(width: 12.w),
            Text(
              'Sign in with Google',
              style: StyleManager.loginPageSubTextTextStyle.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
