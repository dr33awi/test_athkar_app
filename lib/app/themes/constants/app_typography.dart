// lib/app/themes/constants/app_typography.dart
import 'package:flutter/material.dart';
import 'app_dimensions.dart';

/// نظام أنماط النصوص الموحد
/// مُحسَّن للغة العربية مع دعم كامل لـ RTL
class AppTypography {
  AppTypography._();

  // ===== الخطوط =====
  static const String fontFamilyArabic = 'Cairo';
  static const String fontFamilyEnglish = 'Inter';
  static const String fontFamilyMono = 'Courier New';
  static const String fontFamilyQuran = 'Amiri';

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

  static const TextStyle code = TextStyle(
    fontSize: 14,
    fontWeight: regular,
    height: 1.5,
    fontFamily: fontFamilyMono,
  );

  // ===== أنماط إضافية =====
  static const TextStyle quote = TextStyle(
    fontSize: 18,
    fontWeight: regular,
    height: 1.8,
    fontStyle: FontStyle.italic,
    fontFamily: fontFamily,
  );

  static const TextStyle numeric = TextStyle(
    fontSize: 20,
    fontWeight: bold,
    height: 1.2,
    fontFamily: fontFamilyEnglish,
  );

  static const TextStyle link = TextStyle(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    decoration: TextDecoration.underline,
    fontFamily: fontFamily,
  );

  // ===== دوال مساعدة =====
  
  /// إنشاء TextTheme مخصص
  static TextTheme createTextTheme({
    required Color color,
    Color? secondaryColor,
  }) {
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

  /// نمط النص المتجاوب
  static TextStyle responsive(
    BuildContext context, {
    required TextStyle mobile,
    TextStyle? tablet,
    TextStyle? desktop,
    TextStyle? wideScreen,
  }) {
    final deviceType = AppDimens.getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.wideScreen:
        return wideScreen ?? desktop ?? tablet ?? mobile;
    }
  }

  /// تطبيق ارتفاع مخصص للنص العربي
  static TextStyle withArabicHeight(TextStyle style) {
    return style.copyWith(height: (style.height ?? 1.0) * 1.15);
  }

  /// الحصول على نمط نص مخصص حسب الوزن
  static TextStyle getStyleByWeight(
    double fontSize,
    FontWeight weight, {
    double? height,
    double? letterSpacing,
    String? fontFamily,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      height: height ?? 1.5,
      letterSpacing: letterSpacing,
      fontFamily: fontFamily ?? AppTypography.fontFamily,
    );
  }

  /// تطبيق تأثيرات على النص
  static TextStyle applyEffects(
    TextStyle style, {
    List<Shadow>? shadows,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return style.copyWith(
      shadows: shadows,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }

  /// الحصول على حجم الخط المتجاوب
  static double responsiveFontSize(
    BuildContext context,
    double baseSize, {
    double? minSize,
    double? maxSize,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final scaleFactor = width / 375; // iPhone 8 width as base
    
    double scaledSize = baseSize * scaleFactor;
    
    if (minSize != null && scaledSize < minSize) {
      scaledSize = minSize;
    }
    
    if (maxSize != null && scaledSize > maxSize) {
      scaledSize = maxSize;
    }
    
    return scaledSize;
  }

  /// إنشاء نمط نص متدرج
  static ShaderMask gradientText({
    required Widget child,
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
      ).createShader(bounds),
      child: child,
    );
  }
}