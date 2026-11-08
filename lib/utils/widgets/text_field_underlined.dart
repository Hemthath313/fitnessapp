import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/font_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TextFieldWidgetUnderLined extends StatelessWidget {
  const TextFieldWidgetUnderLined({
    super.key,
    this.inputFormatters,
    required this.controller,
    required this.labelHint,
    required this.obscureText,
    required this.keyboardType,
  });

  final TextEditingController controller;
  final bool obscureText;
  final String labelHint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: deviceWidth,
      child: Padding(
        padding: const EdgeInsets.only(bottom: PaddingManager.p8),
        child: TextField(
          inputFormatters: inputFormatters,
          controller: controller,
          obscureText: obscureText,
          autocorrect: false,
          keyboardType: keyboardType,
          cursorColor: ColorManager.white,
          style:  TextStyle(
            color: ColorManager.white,
            fontWeight: FontWightManager.bold,
          ),
          decoration: InputDecoration(
            labelText: labelHint,
            labelStyle:  TextStyle(
              color: ColorManager.white2,
              fontSize: 14.sp,
              letterSpacing: SizeManager.s1_5,
              fontWeight: FontWightManager.semiBold,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: ColorManager.limerGreen2,
                width: SizeManager.s0_7.h,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: ColorManager.limerGreen2,
                width: SizeManager.s0_7.h,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
