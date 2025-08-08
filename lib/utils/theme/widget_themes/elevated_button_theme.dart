import 'package:flutter/material.dart';
import 'package:optilay_prototype_app/utils/constants/colors.dart';
import 'package:optilay_prototype_app/utils/constants/sizes.dart';

/* -- Light & Dark Elevated Button Themes -- */
class MyElevatedButtonTheme {
  MyElevatedButtonTheme._(); //To avoid creating instances

  /* -- Light Theme -- */
  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: MyColors.light,
      backgroundColor: MyColors.primary,
      disabledForegroundColor: MyColors.darkGrey,
      disabledBackgroundColor: MyColors.buttonDisabled,
      side: const BorderSide(color: MyColors.primary),
      padding: const EdgeInsets.symmetric(vertical: MySizes.buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MySizes.buttonRadius),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        color: MyColors.textWhite,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
    ),
  );

  /* -- Dark Theme -- */
  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: MyColors.light,
      backgroundColor: MyColors.primary,
      disabledForegroundColor: MyColors.darkGrey,
      disabledBackgroundColor: MyColors.darkerGrey,
      side: const BorderSide(color: MyColors.primary),
      padding: const EdgeInsets.symmetric(vertical: MySizes.buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MySizes.buttonRadius),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        color: MyColors.textWhite,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
    ),
  );
}
