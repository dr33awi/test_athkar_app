// lib/app/themes/constants/app_typography.dart

import 'package:flutter/material.dart';

/// نظام أنماط النصوص المبسط لتطبيق الأذكار
class AppTypography {
  AppTypography._();

  // الخطوط
  static const String fontFamilyArabic = 'Cairo';
  static const String fontFamilyQuran = 'Amiri';
  static const String fontFamily = fontFamilyArabic;

  // أوزان الخطوط
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // أنماط العناوين
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: bold,
    height: 1.3,
    fontFamily: fontFamily,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: semiBold,
    height: 1.3,
    fontFamily: fontFamily,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.4,
    fontFamily: fontFamily,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: semiBold,
    height: 1.4,
    fontFamily: fontFamily,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.5,
    fontFamily: fontFamily,
  );

  // أنماط النص الأساسي
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: regular,
    height: 1.6,
    fontFamily: fontFamily,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: regular,
    height: 1.6,
    fontFamily: fontFamily,
  );

  // أنماط التسميات
  static const TextStyle label1 = TextStyle(
    fontSize: 14,
    fontWeight: medium,
    height: 1.4,
    fontFamily: fontFamily,
  );

  static const TextStyle label2 = TextStyle(
    fontSize: 12,
    fontWeight: medium,
    height: 1.4,
    fontFamily: fontFamily,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: regular,
    height: 1.4,
    fontFamily: fontFamily,
  );

  // أنماط الأزرار
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.2,
    fontFamily: fontFamily,
  );

  // أنماط خاصة بالأذكار
  static const TextStyle quran = TextStyle(
    fontSize: 22,
    fontWeight: regular,
    height: 2.0,
    fontFamily: fontFamilyQuran,
  );

  static const TextStyle athkar = TextStyle(
    fontSize: 18,
    fontWeight: regular,
    height: 1.8,
    fontFamily: fontFamily,
  );

  static const TextStyle dua = TextStyle(
    fontSize: 16,
    fontWeight: regular,
    height: 1.7,
    fontFamily: fontFamily,
  );

  // إنشاء TextTheme
  static TextTheme createTextTheme({
    required Color color,
    Color? secondaryColor,
  }) {
    final Color effectiveSecondaryColor = secondaryColor ?? color.withOpacity(0.7);
    return TextTheme(
      displayLarge: h1.copyWith(color: color),
      displayMedium: h2.copyWith(color: color),
      displaySmall: h3.copyWith(color: color),
      headlineLarge: h1.copyWith(color: color),
      headlineMedium: h2.copyWith(color: color),
      headlineSmall: h3.copyWith(color: color),
      titleLarge: h4.copyWith(color: color),
      titleMedium: h5.copyWith(color: color),
      bodyLarge: body1.copyWith(color: color),
      bodyMedium: body2.copyWith(color: effectiveSecondaryColor),
      labelLarge: label1.copyWith(color: color),
      labelMedium: label2.copyWith(color: effectiveSecondaryColor),
      labelSmall: caption.copyWith(color: effectiveSecondaryColor),
    );
  }
}