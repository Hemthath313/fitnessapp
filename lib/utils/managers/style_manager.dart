import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/font_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class StyleManager {
  static TextStyle get splashText1TextStyle => TextStyle(
    color: ColorManager.white,
    fontSize: 24.sp,
    fontWeight: FontWightManager.bold,
  );
  static TextStyle get splashText2TextStyle => TextStyle(
    color: ColorManager.lighGrey,
    fontSize: 18.sp,
    fontWeight: FontWightManager.semiBold,
  );
  static TextStyle get loginPageSubButtonSmallTextStyle => TextStyle(
    color: ColorManager.primaryText,
    fontSize: 16.sp,
    fontWeight: FontWightManager.bold,
    letterSpacing: SizeManager.s0_7,
  );
  static TextStyle get loginPageSubTextTextStyle => TextStyle(
    color: ColorManager.white,
    fontSize: 13.sp,
    fontWeight: FontWightManager.medium,
    letterSpacing: SizeManager.s0_7,
  );
  static TextStyle get registerPageHaveAccTextStyle => TextStyle(
    color: ColorManager.white,
    fontSize: 13.sp,
    fontWeight: FontWightManager.medium,
    letterSpacing: SizeManager.s0_7,
  );
  static TextStyle get abTitleTextStyle => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWightManager.semiBold,
    letterSpacing: SizeManager.s3,
  );
  static TextStyle get forgotPWErrorTextStyle => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWightManager.semiBold,
    letterSpacing: SizeManager.s3,
    color: ColorManager.white,
  );
  static TextStyle get forgotPWErrorContentTextStyle => TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWightManager.regular,
    letterSpacing: SizeManager.s1,
    color: ColorManager.white,
  );
  static TextStyle get appbarTitleTextStyle => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.bold,
    letterSpacing: SizeManager.s5,
    color: ColorManager.white,
  );
  static TextStyle get accountButtonTextStyle => TextStyle(
    color: ColorManager.darkGrey,
    fontSize: 18.sp,
    fontWeight: FontWightManager.semiBold,
    letterSpacing: SizeManager.s1_5,
  );
  static TextStyle get settingsButtonTextStyle => TextStyle(
    color: ColorManager.white,
    fontSize: 16.sp,
    fontWeight: FontWightManager.regular,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get registerSpacerStyle => TextStyle(
    color: ColorManager.white,
    fontSize: 16.sp,
    fontWeight: FontWightManager.semiBold,
    letterSpacing: SizeManager.s1_5,
  );
  static TextStyle get registerTextfieldTextStyle => TextStyle(
    color: ColorManager.white,
    fontSize: 14.sp,
    letterSpacing: SizeManager.s1_5,
    fontWeight: FontWightManager.semiBold,
  );
  static TextStyle get settingsPageSpacerTextStyle => TextStyle(
    color: ColorManager.white,
    fontSize: 20.sp,
    fontWeight: FontWeight.bold,
    letterSpacing: SizeManager.s0_5,
  );
  static TextStyle get deleteAccPopUpButtonTextStyle => TextStyle(
    color: ColorManager.white,
    fontWeight: FontWightManager.bold,
    fontSize: 24.sp,
    letterSpacing: SizeManager.s3,
  );
  static TextStyle get deleteAccPopUpTitleTextStyle => TextStyle(
    color: ColorManager.primaryText,
    fontSize: 20.sp,
    fontWeight: FontWightManager.semiBold,
  );
  static TextStyle get homePageS17BoldWhite => TextStyle(
    color: ColorManager.white,
    fontSize: 16.sp,
    fontWeight: FontWightManager.bold,
  );
  static TextStyle get homePageS20BoldWhite => TextStyle(
    color: ColorManager.white,
    fontSize: 20.sp,
    fontWeight: FontWightManager.bold,
  );
  static TextStyle get homePageS12RegularWhite2 => TextStyle(
    color: ColorManager.white2,
    fontSize: 12.sp,
    fontWeight: FontWightManager.regular,
  );
  static TextStyle get homePageTextSpacerTextStyle => TextStyle(
    color: ColorManager.white,
    fontWeight: FontWightManager.semiBold,
    fontSize: 24.sp,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get homePageS18BoldDarkGrey => TextStyle(
    color: ColorManager.darkGrey,
    fontSize: 18.sp,
    fontWeight: FontWightManager.bold,
  );
  static TextStyle get homePageS20BoldDarkGrey => TextStyle(
    color: ColorManager.darkGrey,
    fontSize: 24.sp,
    fontWeight: FontWightManager.bold,
  );
  static TextStyle get homePageS16RegularDarkGrey => TextStyle(
    color: ColorManager.darkGrey,
    fontSize: 16.sp,
    fontWeight: FontWightManager.regular,
  );
  static TextStyle get homePageCarouselTitle => TextStyle(
    color: ColorManager.primaryText,
    fontSize: 24.sp,
    fontWeight: FontWightManager.bold,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get homePageS14RegularWhite2L1 => TextStyle(
    color: ColorManager.white2,
    fontWeight: FontWightManager.regular,
    fontSize: 14.sp,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get homePagePogressBarTextStyle => TextStyle(
    color: ColorManager.white,
    fontSize: 18.sp,
    fontWeight: FontWightManager.semiBold,
  );
  static TextStyle get homePageTodaysProgressTextSTyle => TextStyle(
    color: ColorManager.white,
    fontWeight: FontWightManager.bold,
    fontSize: 20.sp,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get drinkPageHeadLineTextStyle => TextStyle(
    color: ColorManager.white,
    fontSize: 24.sp,
    fontWeight: FontWightManager.bold,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get newExerciseButtonTextSTyle => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWightManager.bold,
    letterSpacing: SizeManager.s3,
    color: ColorManager.darkGrey,
  );
  static TextStyle get weightProfTextSTyle => TextStyle(
    color: ColorManager.white,
    fontSize: 13.sp,
    fontWeight: FontWightManager.semiBold,
  );
  static TextStyle get weightDataRowTextStyleWhite => TextStyle(
    color: ColorManager.white,
    fontSize: 18.sp,
    fontWeight: FontWightManager.bold,
  );
  static TextStyle get weightDataRowTextStyleLime => TextStyle(
    color: ColorManager.primaryText,
    fontSize: 20.sp,
    fontWeight: FontWightManager.bold,
  );
  static TextStyle get exerciseRepAndSetHintTextStyle => TextStyle(
    fontSize: 16.sp,
    color: ColorManager.white2,
    fontWeight: FontWightManager.regular,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get exerciseRepAndSetNumberTextStyle => TextStyle(
    fontSize: 18.sp,
    color: ColorManager.primaryText,
    fontWeight: FontWightManager.bold,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get exerciseNameTextStyle => TextStyle(
    fontSize: 20.sp,
    color: ColorManager.white,
    fontWeight: FontWightManager.regular,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get settingsOptionTiteTextStyle => TextStyle(
    color: ColorManager.white,
    fontWeight: FontWightManager.bold,
    letterSpacing: SizeManager.s3,
    fontSize: 24.sp,
  );
  static TextStyle get editTextButtonTextStyle => TextStyle(
    color: ColorManager.white,
    fontSize: 16.sp,
    fontWeight: FontWightManager.regular,
    letterSpacing: SizeManager.s1,
    decoration: TextDecoration.underline,
  );
  static TextStyle get profieloggedinTextStyle => TextStyle(
    color: ColorManager.primaryText,
    fontSize: 18.sp,
    fontWeight: FontWightManager.bold,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get profileLoginDataTextStyle => TextStyle(
    color: ColorManager.white,
    fontSize: 16.sp,
    fontWeight: FontWightManager.regular,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get profileBodyMeasurmentsNameTextSTyle => TextStyle(
    color: ColorManager.primaryText,
    fontSize: 16.sp,
    fontWeight: FontWightManager.semiBold,
  );
  static TextStyle get profileBodyMeasurementsDataTextStyle => TextStyle(
    color: ColorManager.white,
    fontSize: 16.sp,
    fontWeight: FontWightManager.regular,
  );
  static TextStyle get homeTitleNameTextStyle => TextStyle(
    color: ColorManager.grey,
    fontSize: 16.sp,
    letterSpacing: SizeManager.s0_7,
  );
  static TextStyle get homeTitleDataTextStyle => TextStyle(
    color: ColorManager.white,
    fontSize: 18.sp,
    letterSpacing: SizeManager.s0_7,
  );
  static TextStyle get fitnessBmiTextStyle => TextStyle(
    color: ColorManager.white2,
    fontSize: 12.sp,
    fontWeight: FontWightManager.regular,
  );
  static TextStyle get percentValueOfMealTextStyle => TextStyle(
    fontSize: 18.sp,
    color: ColorManager.white,
    fontWeight: FontWightManager.bold,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get percentValueOfMealTitleTextSTyle => TextStyle(
    fontSize: 16.sp,
    color: ColorManager.white2,
    fontWeight: FontWightManager.regular,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get mealWidgetDataTextStyle => TextStyle(
    fontSize: 16.sp,
    color: ColorManager.white2,
    fontWeight: FontWightManager.regular,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get mealWidgetTitleTextStyle => TextStyle(
    fontSize: 20.sp,
    color: ColorManager.white,
    fontWeight: FontWightManager.semiBold,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get addDataTitleTextStyle => TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWightManager.semiBold,
    color: ColorManager.white,
  );
  static TextStyle get drinkPageSpacerTextStyle => TextStyle(
    color: ColorManager.white,
    fontWeight: FontWightManager.semiBold,
    fontSize: 18.sp,
    letterSpacing: SizeManager.s1,
  );
  static TextStyle get skillNameTextStyle => TextStyle(
    color: ColorManager.white,
    fontSize: 20.sp,
    fontWeight: FontWightManager.bold,
    letterSpacing: SizeManager.s1,
  );
}
