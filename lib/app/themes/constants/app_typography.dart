// lib/app/themes/constants/app_typography.dart
import 'package:flutter/material.dart';

/// نظام أنماط النصوص الموحد
/// مُحسَّن للغة العربية مع دعم كامل لـ RTL
class AppTypography {
  AppTypography._();

  // ===== الخطوط =====
  static const String fontFamilyArabic = 'Cairo';
  static const String fontFamilyEnglish = 'Inter';
  static const String fontFamilyMono = 'Courier New';

  // الخط الافتراضي هو العربي
  static const String fontFamily = fontFamilyArabic;

  // ===== أوزان الخطوط =====
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  // ===== أنماط العرض (Display) =====
  static const TextStyle display1 = TextStyle(
    fontSize: 40,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: -0.5,
    fontFamily: fontFamily,
  );

  static const TextStyle display2 = TextStyle(
    fontSize: 36,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: -0.5,
    fontFamily: fontFamily,
  );

  static const TextStyle display3 = TextStyle(
    fontSize: 32,
    fontWeight: bold,
    height: 1.3,
    letterSpacing: -0.3,
    fontFamily: fontFamily,
  );

  // ===== أنماط العناوين (Headings) =====
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: bold,
    height: 1.3,
    letterSpacing: -0.2,
    fontFamily: fontFamily,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: -0.1,
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

  static const TextStyle h6 = TextStyle(
    fontSize: 14,
    fontWeight: semiBold,
    height: 1.5,
    fontFamily: fontFamily,
  );

  // ===== أنماط النص الأساسي (Body) =====
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

  static const TextStyle body3 = TextStyle(
    fontSize: 12,
    fontWeight: regular,
    height: 1.5,
    fontFamily: fontFamily,
  );

  // ===== أنماط التسميات (Labels) =====
  static const TextStyle label1 = TextStyle(
    fontSize: 14,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.1,
    fontFamily: fontFamily,
  );

  static const TextStyle label2 = TextStyle(
    fontSize: 12,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.1,
    fontFamily: fontFamily,
  );

  // ===== أنماط التعليقات (Captions) =====
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: regular,
    height: 1.4,
    letterSpacing: 0.4,
    fontFamily: fontFamily,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: medium,
    height: 1.5,
    letterSpacing: 1.0,
    fontFamily: fontFamily,
  );

  // ===== أنماط الأزرار =====
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.2,
    letterSpacing: 0.5,
    fontFamily: fontFamily,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: semiBold,
    height: 1.2,
    letterSpacing: 0.5,
    fontFamily: fontFamily,
  );

  // ===== أنماط خاصة =====
  static const TextStyle quran = TextStyle(
    fontSize: 22,
    fontWeight: regular,
    height: 2.0,
    fontFamily: 'Amiri', // خط خاص للقرآن
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

  static const TextStyle code = TextStyle(
    fontSize: 14,
    fontWeight: regular,
    height: 1.5,
    fontFamily: fontFamilyMono,
  );

  // ===== دوال مساعدة =====
  static TextTheme createTextTheme({required Color color, Color? secondaryColor}) {
    final Color effectiveSecondaryColor = secondaryColor ?? color.withAlpha((0.7 * 255).round());
    return TextTheme(
      displayLarge: display1.copyWith(color: color),
      displayMedium: display2.copyWith(color: color),
      displaySmall: display3.copyWith(color: color),
      headlineLarge: h1.copyWith(color: color),
      headlineMedium: h2.copyWith(color: color),
      headlineSmall: h3.copyWith(color: color),
      titleLarge: h4.copyWith(color: color),
      titleMedium: h5.copyWith(color: color),
      titleSmall: h6.copyWith(color: color),
      bodyLarge: body1.copyWith(color: color),
      bodyMedium: body2.copyWith(color: effectiveSecondaryColor),
      bodySmall: body3.copyWith(color: effectiveSecondaryColor.withAlpha((0.8 * 255).round())),
      labelLarge: label1.copyWith(color: color),
      labelMedium: label2.copyWith(color: effectiveSecondaryColor),
      labelSmall: caption.copyWith(color: effectiveSecondaryColor),
    );
  }

  static TextStyle responsive(
    BuildContext context, {
    required TextStyle mobile,
    TextStyle? tablet,
    TextStyle? desktop,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024 && desktop != null) return desktop;
    if (width >= 600 && tablet != null) return tablet;
    return mobile;
  }

  static TextStyle withArabicHeight(TextStyle style) {
    return style.copyWith(height: (style.height ?? 1.0) * 1.15);
  }
}