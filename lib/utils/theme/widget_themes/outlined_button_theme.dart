import 'package:flutter/material.dart';
import 'package:optilay_prototype_app/utils/constants/colors.dart';
import 'package:optilay_prototype_app/utils/constants/sizes.dart';

/* -- Light & Dark Outlined Button Themes -- */
class MyOutlinedButtonTheme {
  MyOutlinedButtonTheme._(); //To avoid creating instances

  /* -- Light Theme -- */
  static final lightOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      elevation: 0,
      foregroundColor: MyColors.dark,
      side: const BorderSide(color: MyColors.borderPrimary),
      padding: const EdgeInsets.symmetric(
        vertical: MySizes.buttonHeight,
        horizontal: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MySizes.buttonRadius),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        color: MyColors.black,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
    ),
  );

  /* -- Dark Theme -- */
  static final darkOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: MyColors.light,
      side: const BorderSide(color: MyColors.borderPrimary),
      padding: const EdgeInsets.symmetric(
        vertical: MySizes.buttonHeight,
        horizontal: 20,
      ),
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
