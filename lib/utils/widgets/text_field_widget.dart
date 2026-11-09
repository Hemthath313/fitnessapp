import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TextFieldWidget extends StatelessWidget {
  const TextFieldWidget({
    super.key,
    required this.controller,
    required this.labelHint,
    required this.obscureText,
    required this.keyboardType,
    this.inputFormatters,
    this.width,
    this.height,
  });

  final TextEditingController controller;
  final bool obscureText;
  final String labelHint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 56.h,
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ColorManager.surfaceLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: TextField(
        inputFormatters: inputFormatters,
        controller: controller,
        obscureText: obscureText,
        textAlign: TextAlign.start,
        style: TextStyle(
          color: ColorManager.textPrimary,
          fontSize: 16.sp,
          height: 1.4,
        ),
        autocorrect: false,
        keyboardType: keyboardType,
        cursorColor: ColorManager.primary,
        decoration: InputDecoration(
          labelText: labelHint,
          labelStyle: TextStyle(
            color: ColorManager.textSecondary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: TextStyle(
            color: ColorManager.primaryText,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          hintText: labelHint,
          hintStyle: TextStyle(
            color: ColorManager.textTertiary,
            fontSize: 16.sp,
          ),
          filled: true,
          fillColor: Colors.transparent,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: ColorManager.primary,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: Colors.transparent,
              width: 0,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
        ),
      ),
    );
  }
}
