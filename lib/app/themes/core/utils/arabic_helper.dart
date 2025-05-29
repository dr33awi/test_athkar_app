// lib/app/themes/core/utils/arabic_helper.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';
// import '../theme_extensions.dart'; // Removed unused import

class ArabicThemeHelper {
  ArabicThemeHelper._();

  static TextDirection get arabicTextDirection => TextDirection.rtl;

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getAccessibleTextColor(BuildContext context, Color backgroundColor, {bool isSecondary = false}) {
    final ThemeData theme = Theme.of(context);
    if (ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark) {
      return isSecondary ? theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()) : theme.colorScheme.onSurface;
    } else {
      return isSecondary ? theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()) : theme.colorScheme.onSurface;
    }
  }

  static TextStyle getArabicTextStyle(BuildContext context, {
    bool isBold = false,
    bool isLarge = false,
    bool isSecondary = false,
    Color? customTextColor,
    double? fontSize,
  }) {
    final ThemeData theme = Theme.of(context);
    final Color defaultTextColor = isSecondary
        ? (theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary(context))
        : (theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary(context));

    return TextStyle(
      fontFamily: AppTypography.fontFamilyArabic,
      height: 1.5,
      fontSize: fontSize ?? (isLarge ? 18 : 16),
      fontWeight: isBold ? AppTypography.bold : AppTypography.regular,
      color: customTextColor ?? defaultTextColor,
      letterSpacing: -0.3,
      wordSpacing: 0.5,
      locale: const Locale('ar'),
    );
  }

  static BoxDecoration getAccessibleCardDecoration(BuildContext context, {
    double opacity = 1.0,
    double borderRadius = AppDimens.radiusLg,
  }) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkTheme = theme.brightness == Brightness.dark;
    final cardColorFromTheme = theme.cardTheme.color ?? AppColors.card(context);

    return BoxDecoration(
      color: cardColorFromTheme.withAlpha((opacity * 255).round()),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (theme.dividerTheme.color ?? AppColors.divider(context)).withAlpha((isDarkTheme ? (0.4*255).round() : (0.3 * 255).round())),
        width: AppDimens.borderLight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha((isDarkTheme ? (0.15*255).round() : (0.08 * 255).round())),
          blurRadius: AppDimens.space2,
          offset: const Offset(0, AppDimens.space1),
        ),
      ],
    );
  }

  static ButtonStyle getArabicButtonStyle(BuildContext context, {
    bool isOutlined = false,
    double borderRadius = AppDimens.radiusMd,
    Color? customBackgroundColor,
    Color? customForegroundColor,
  }) {
    final ThemeData theme = Theme.of(context);

    if (isOutlined) {
      return OutlinedButton.styleFrom(
        foregroundColor: customForegroundColor ?? theme.colorScheme.primary,
        backgroundColor: customBackgroundColor,
        side: BorderSide(
          color: customForegroundColor ?? theme.colorScheme.primary,
          width: AppDimens.borderMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: AppTypography.button.copyWith(fontFamily: AppTypography.fontFamilyArabic),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space6,
          vertical: AppDimens.space4,
        ),
      );
    } else {
      return ElevatedButton.styleFrom(
        backgroundColor: customBackgroundColor ?? theme.colorScheme.primary,
        foregroundColor: customForegroundColor ?? theme.colorScheme.onPrimary,
        textStyle: AppTypography.button.copyWith(fontFamily: AppTypography.fontFamilyArabic),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space6,
          vertical: AppDimens.space4,
        ),
        shadowColor: Colors.transparent,
      );
    }
  }

  static InputDecoration getArabicInputDecoration(BuildContext context, {
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final ThemeData theme = Theme.of(context);
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      fillColor: theme.inputDecorationTheme.fillColor,
      filled: theme.inputDecorationTheme.filled,
      contentPadding: theme.inputDecorationTheme.contentPadding ?? const EdgeInsets.symmetric(horizontal: AppDimens.space4, vertical: AppDimens.space4), // Added const to default
      border: theme.inputDecorationTheme.border,
      enabledBorder: theme.inputDecorationTheme.enabledBorder,
      focusedBorder: theme.inputDecorationTheme.focusedBorder,
      hintStyle: theme.inputDecorationTheme.hintStyle?.copyWith(fontFamily: AppTypography.fontFamilyArabic),
      labelStyle: theme.inputDecorationTheme.labelStyle?.copyWith(fontFamily: AppTypography.fontFamilyArabic),
      alignLabelWithHint: true,
      floatingLabelAlignment: FloatingLabelAlignment.start,
    );
  }
}