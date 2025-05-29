// lib/app/themes/extensions/theme_extensions.dart
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

/// Extensions لتسهيل الوصول للثيم
extension ThemeExtension on BuildContext {
  // ===== الثيم الأساسي =====
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  
  // ===== الألوان =====
  Color get primaryColor => theme.primaryColor;
  Color get backgroundColor => theme.scaffoldBackgroundColor;
  Color get surfaceColor => colorScheme.surface;
  Color get cardColor => theme.cardColor;
  Color get errorColor => colorScheme.error;
  Color get dividerColor => theme.dividerColor;
  
  // ألوان النص
  Color get textPrimaryColor => AppColors.textPrimary(this);
  Color get textSecondaryColor => AppColors.textSecondary(this);
  
  // ألوان خاصة
  Color get successColor => AppColors.success;
  Color get warningColor => AppColors.warning;
  Color get infoColor => AppColors.info;
  
  // ===== الوضع =====
  bool get isDarkMode => theme.brightness == Brightness.dark;
  bool get isLightMode => !isDarkMode;
  
  // ===== أنماط النصوص =====
  TextStyle? get displayLarge => textTheme.displayLarge;
  TextStyle? get displayMedium => textTheme.displayMedium;
  TextStyle? get displaySmall => textTheme.displaySmall;
  
  TextStyle? get headlineLarge => textTheme.headlineLarge;
  TextStyle? get headlineMedium => textTheme.headlineMedium;
  TextStyle? get headlineSmall => textTheme.headlineSmall;
  
  TextStyle? get titleLarge => textTheme.titleLarge;
  TextStyle? get titleMedium => textTheme.titleMedium;
  TextStyle? get titleSmall => textTheme.titleSmall;
  
  TextStyle? get bodyLarge => textTheme.bodyLarge;
  TextStyle? get bodyMedium => textTheme.bodyMedium;
  TextStyle? get bodySmall => textTheme.bodySmall;
  
  TextStyle? get labelLarge => textTheme.labelLarge;
  TextStyle? get labelMedium => textTheme.labelMedium;
  TextStyle? get labelSmall => textTheme.labelSmall;
  
  // أنماط خاصة
  TextStyle get quranStyle => AppTypography.quran;
  TextStyle get athkarStyle => AppTypography.athkar;
  TextStyle get duaStyle => AppTypography.dua;
  
  // ===== الأبعاد =====
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get screenPadding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
  
  // نقاط التوقف
  bool get isMobile => AppDimens.isMobile(this);
  bool get isTablet => AppDimens.isTablet(this);
  bool get isDesktop => AppDimens.isDesktop(this);
  
  // الحشوات المتجاوبة
  EdgeInsets get responsivePadding => AppDimens.responsivePadding(this);
  
  // ===== المنصة =====
  bool get isIOS => theme.platform == TargetPlatform.iOS;
  bool get isAndroid => theme.platform == TargetPlatform.android;
  
  // ===== لوحة المفاتيح =====
  bool get isKeyboardOpen => viewInsets.bottom > 0;
  double get keyboardHeight => viewInsets.bottom;
  
  // ===== المنطقة الآمنة =====
  double get safeTop => screenPadding.top;
  double get safeBottom => screenPadding.bottom;
}

/// Extensions للألوان
extension ColorExtension on Color {
  /// إنشاء لون بشفافية
  Color opacity(double opacity) => withOpacity(opacity);
  
  /// تفتيح اللون
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  /// تغميق اللون
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

/// Extensions للنصوص
extension TextStyleExtension on TextStyle {
  /// تغيير حجم الخط
  TextStyle size(double size) => copyWith(fontSize: size);
  
  /// تغيير وزن الخط
  TextStyle weight(FontWeight weight) => copyWith(fontWeight: weight);
  
  /// تغيير لون النص
  TextStyle color(Color color) => copyWith(color: color);
  
  /// تغيير ارتفاع السطر
  TextStyle height(double height) => copyWith(height: height);
  
  /// جعل النص عريض
  TextStyle get bold => weight(AppTypography.bold);
  
  /// جعل النص متوسط
  TextStyle get medium => weight(AppTypography.medium);
  
  /// جعل النص عادي
  TextStyle get regular => weight(AppTypography.regular);
  
  /// إضافة تباعد بين الحروف
  TextStyle letterSpacing(double spacing) => copyWith(letterSpacing: spacing);
}

/// Extensions للحشوات
extension EdgeInsetsExtension on EdgeInsets {
  /// إضافة حشوة
  EdgeInsets add(EdgeInsets other) => EdgeInsets.only(
    left: left + other.left,
    top: top + other.top,
    right: right + other.right,
    bottom: bottom + other.bottom,
  );
  
  /// طرح حشوة
  EdgeInsets subtract(EdgeInsets other) => EdgeInsets.only(
    left: (left - other.left).clamp(0, double.infinity),
    top: (top - other.top).clamp(0, double.infinity),
    right: (right - other.right).clamp(0, double.infinity),
    bottom: (bottom - other.bottom).clamp(0, double.infinity),
  );
}

/// Extensions للأرقام
extension NumberExtension on num {
  /// تحويل لـ SizedBox بعرض
  SizedBox get w => SizedBox(width: toDouble());
  
  /// تحويل لـ SizedBox بارتفاع
  SizedBox get h => SizedBox(height: toDouble());
  
  /// تحويل لـ EdgeInsets متساوية
  EdgeInsets get all => EdgeInsets.all(toDouble());
  
  /// تحويل لـ EdgeInsets أفقية
  EdgeInsets get horizontal => EdgeInsets.symmetric(horizontal: toDouble());
  
  /// تحويل لـ EdgeInsets عمودية
  EdgeInsets get vertical => EdgeInsets.symmetric(vertical: toDouble());
  
  /// تحويل لـ BorderRadius
  BorderRadius get radius => BorderRadius.circular(toDouble());
}