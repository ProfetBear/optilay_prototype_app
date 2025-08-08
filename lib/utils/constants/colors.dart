import 'package:flutter/material.dart';

class MyColors {
  // App theme colors
  static const Color primary = Colors.teal;
  static const Color secondary = Colors.deepPurple;
  static const Color green = Colors.green;
  static const Color blue = Colors.blue;

  // Text colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textWhite = Colors.white;

  // Background colors
  static const Color light = Color.fromARGB(255, 251, 251, 251);
  static const Color dark = Color(0xFF272727);
  static const Color primaryBackground = Color(0xFFF3F5FF);

  // Background Container colors
  static const Color lightContainer = Color.fromARGB(255, 251, 251, 251);
  static Color darkContainer = MyColors.white.withOpacity(0.1);

  // Button colors
  static const Color buttonPrimary = Color.fromARGB(255, 17, 32, 184);
  static const Color buttonSecondary = Color(0xFF6C757D);
  static const Color buttonDisabled = Color(0xFFC4C4C4);

  // Border colors
  static const Color borderPrimary = Color(0xFFD9D9D9);
  static const Color borderSecondary = Color(0xFFE6E6E6);

  // Error and validation colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  // Neutral Shades
  static const Color black = Color(0xFF232323);
  static const Color darkerGrey = Color(0xFF4F4F4F);
  static const Color darkGrey = Color(0xFF939393);
  static const Color grey = Color(0xFFE0E0E0);
  static const Color softGrey = Color(0xFFF4F4F4);
  static const Color lightGrey = Color(0xFFF9F9F9);
  static const Color white = Color(0xFFFFFFFF);

  // Category Colors
  static const Color sport = Color.fromARGB(255, 4, 66, 117);
  static const Color culture = Color.fromARGB(255, 255, 225, 106);
  static const Color events = Color.fromARGB(255, 244, 67, 54);
  static const Color wellness = Color.fromARGB(255, 29, 134, 29);
}
