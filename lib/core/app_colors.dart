import 'package:flutter/material.dart';

/// Mirrors the Tailwind `neutral` scale plus the status accents used across
/// the Probahi web app's design system (`static/css/main.css`), so the
/// mobile app reads as the same product.
class AppColors {
  AppColors._();

  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);

  static const Color sky50 = Color(0xFFF0F9FF);
  static const Color sky200 = Color(0xFFBAE6FD);
  static const Color sky600 = Color(0xFF0284C7);

  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald600 = Color(0xFF059669);

  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber600 = Color(0xFFD97706);

  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red200 = Color(0xFFFECACA);
  static const Color red600 = Color(0xFFDC2626);

  static const Color white = Color(0xFFFFFFFF);
}
