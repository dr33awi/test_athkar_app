// lib/app/themes/core/theme_extensions.dart
import 'package:flutter/material.dart';
// import '../app_theme.dart'; // Removed unused import
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

/// Extensions لتسهيل الوصول للثيم
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  Color get primaryColor => theme.primaryColor;
  Color get backgroundColor => theme.scaffoldBackgroundColor;
  Color get surfaceColor => colorScheme.surface;
  Color get cardThemeColor => theme.cardTheme.color ?? (isDarkMode ? AppColors.darkCard : AppColors.lightCard);
  Color get errorColor => colorScheme.error;
  Color get dividerThemeColor => theme.dividerTheme.color ?? (isDarkMode ? AppColors.darkDivider : AppColors.lightDivider);

  Color get textPrimaryColor => AppColors.textPrimary(this);
  Color get textSecondaryColor => AppColors.textSecondary(this);

  Color get successColor => AppColors.success;
  Color get warningColor => AppColors.warning;
  Color get infoColor => AppColors.info;

  bool get isDarkMode => theme.brightness == Brightness.dark;
  bool get isLightMode => !isDarkMode;

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

  TextStyle get quranStyle => AppTypography.quran;
  TextStyle get athkarStyle => AppTypography.athkar;
  TextStyle get duaStyle => AppTypography.dua;

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get screenPadding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  bool get isMobile => AppDimens.isMobile(this);
  bool get isTablet => AppDimens.isTablet(this);
  bool get isDesktop => AppDimens.isDesktop(this);

  EdgeInsets get responsivePadding => AppDimens.responsivePadding(this);

  bool get isIOS => theme.platform == TargetPlatform.iOS;
  bool get isAndroid => theme.platform == TargetPlatform.android;

  bool get isKeyboardOpen => viewInsets.bottom > 0;
  double get keyboardHeight => viewInsets.bottom;

  double get safeTop => screenPadding.top;
  double get safeBottom => screenPadding.bottom;
}

extension ColorExtensionMethods on Color {
  Color opacity(double opacityValue) => withAlpha((opacityValue * 255).round().clamp(0, 255));

  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

extension TextStyleExtensionMethods on TextStyle {
  TextStyle size(double s) => copyWith(fontSize: s);
  TextStyle weight(FontWeight w) => copyWith(fontWeight: w);
  TextStyle textStyleColor(Color c) => copyWith(color: c);
  TextStyle textHeight(double h) => copyWith(height: h);

  TextStyle get bold => weight(AppTypography.bold);
  TextStyle get medium => weight(AppTypography.medium);
  TextStyle get regular => weight(AppTypography.regular);

  TextStyle letterSpacing(double spacing) => copyWith(letterSpacing: spacing);
}

extension EdgeInsetsExtensionMethods on EdgeInsets {
  EdgeInsets add(EdgeInsets other) => EdgeInsets.only(
    left: left + other.left,
    top: top + other.top,
    right: right + other.right,
    bottom: bottom + other.bottom,
  );

  EdgeInsets subtract(EdgeInsets other) => EdgeInsets.only(
    left: (left - other.left).clamp(0.0, double.infinity),
    top: (top - other.top).clamp(0.0, double.infinity),
    right: (right - other.right).clamp(0.0, double.infinity),
    bottom: (bottom - other.bottom).clamp(0.0, double.infinity),
  );
}

extension NumberExtensionMethods on num {
  SizedBox get w => SizedBox(width: toDouble());
  SizedBox get h => SizedBox(height: toDouble());

  EdgeInsets get allPadding => EdgeInsets.all(toDouble());
  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(horizontal: toDouble());
  EdgeInsets get verticalPadding => EdgeInsets.symmetric(vertical: toDouble());

  BorderRadius get borderRadius => BorderRadius.circular(toDouble());
}