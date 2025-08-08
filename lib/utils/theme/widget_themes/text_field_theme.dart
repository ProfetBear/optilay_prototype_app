import 'package:flutter/material.dart';
import 'package:optilay_prototype_app/utils/constants/colors.dart';
import 'package:optilay_prototype_app/utils/constants/sizes.dart';

class MyTextFormFieldTheme {
  MyTextFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: MyColors.darkGrey,
    suffixIconColor: MyColors.darkGrey,
    // constraints: const BoxConstraints.expand(height: MySizes.inputFieldHeight),
    labelStyle: const TextStyle().copyWith(
      fontSize: MySizes.fontSizeMd,
      color: MyColors.black,
      fontFamily: 'Poppins',
    ),
    hintStyle: const TextStyle().copyWith(
      fontSize: MySizes.fontMySizesm,
      color: MyColors.black,
      fontFamily: 'Poppins',
    ),
    errorStyle: const TextStyle().copyWith(
      fontStyle: FontStyle.normal,
      fontFamily: 'Poppins',
    ),
    floatingLabelStyle: const TextStyle().copyWith(
      color: MyColors.black.withOpacity(0.8),
      fontFamily: 'Poppins',
    ),
    border: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(MySizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: MyColors.grey),
    ),
    enabledBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(MySizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: MyColors.grey),
    ),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(MySizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: MyColors.dark),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(MySizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: MyColors.warning),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(MySizes.inputFieldRadius),
      borderSide: const BorderSide(width: 2, color: MyColors.warning),
    ),
  );

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 2,
    prefixIconColor: MyColors.darkGrey,
    suffixIconColor: MyColors.darkGrey,
    // constraints: const BoxConstraints.expand(height: MySizes.inputFieldHeight),
    labelStyle: const TextStyle().copyWith(
      fontSize: MySizes.fontSizeMd,
      color: MyColors.white,
      fontFamily: 'Poppins',
    ),
    hintStyle: const TextStyle().copyWith(
      fontSize: MySizes.fontMySizesm,
      color: MyColors.white,
      fontFamily: 'Poppins',
    ),
    floatingLabelStyle: const TextStyle().copyWith(
      color: MyColors.white.withOpacity(0.8),
      fontFamily: 'Poppins',
    ),
    border: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(MySizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: MyColors.darkGrey),
    ),
    enabledBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(MySizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: MyColors.darkGrey),
    ),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(MySizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: MyColors.white),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(MySizes.inputFieldRadius),
      borderSide: const BorderSide(width: 1, color: MyColors.warning),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(MySizes.inputFieldRadius),
      borderSide: const BorderSide(width: 2, color: MyColors.warning),
    ),
  );
}
