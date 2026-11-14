import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomGoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;

  const CustomGoogleSignInButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(
            color: ColorManager.surfaceLight,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button.r),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.google,
              color: ColorManager.primaryText,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'Sign in with Google',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
