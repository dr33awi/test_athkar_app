// lib/app/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/app_colors.dart';
import 'constants/app_dimensions.dart';
import 'constants/app_typography.dart';
import 'constants/app_animations.dart';
import 'core/theme_extensions.dart'; // For ColorExtensionMethods (which includes darken)

/// نظام الثيم الموحد للتطبيق
/// يدعم الوضع الفاتح والداكن مع تحسينات للغة العربية
class AppTheme {
  AppTheme._();

  static ThemeData lightTheme() {
    return _buildTheme(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      backgroundColor: AppColors.lightBackground,
      surfaceColor: AppColors.lightSurface,
      cardColor: AppColors.lightCard,
      textPrimaryColor: AppColors.lightTextPrimary,
      textSecondaryColor: AppColors.lightTextSecondary,
      dividerColor: AppColors.lightDivider,
    );
  }

  static ThemeData darkTheme() {
    return _buildTheme(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryLight,
      backgroundColor: AppColors.darkBackground,
      surfaceColor: AppColors.darkSurface,
      cardColor: AppColors.darkCard,
      textPrimaryColor: AppColors.darkTextPrimary,
      textSecondaryColor: AppColors.darkTextSecondary,
      dividerColor: AppColors.darkDivider,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color cardColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
    required Color dividerColor,
  }) {
    final bool isDark = brightness == Brightness.dark;

    final Color onPrimaryColor = ThemeData.estimateBrightnessForColor(primaryColor) == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final Color onSecondaryColor = ThemeData.estimateBrightnessForColor(AppColors.accent) == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final Color onTertiaryColor = ThemeData.estimateBrightnessForColor(AppColors.accentLight) == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: onPrimaryColor,
        secondary: AppColors.accent,
        onSecondary: onSecondaryColor,
        tertiary: AppColors.accentLight,
        onTertiary: onTertiaryColor,
        error: AppColors.error,
        onError: Colors.white,
        surface: backgroundColor,
        onSurface: textPrimaryColor,
        surfaceContainerHighest: cardColor,
        onSurfaceVariant: textSecondaryColor,
        outline: dividerColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h4.copyWith(
          color: textPrimaryColor,
        ),
        iconTheme: IconThemeData( // Cannot be const as textPrimaryColor is dynamic
          color: textPrimaryColor,
          size: AppDimens.iconMd,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: backgroundColor,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: AppDimens.elevationNone,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
      ),
      textTheme: AppTypography.createTextTheme(color: textPrimaryColor, secondaryColor: textSecondaryColor),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          disabledBackgroundColor: AppColors.disabled.withAlpha((AppColors.opacity30 * 255).round()),
          disabledForegroundColor: AppColors.disabledText.withAlpha((AppColors.opacity70 * 255).round()),
          elevation: AppDimens.elevationNone,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space6,
            vertical: AppDimens.space4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          textStyle: AppTypography.button,
          minimumSize: const Size(AppDimens.heightLg, AppDimens.buttonHeight),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(
            color: primaryColor,
            width: AppDimens.borderMedium,
          ),
          disabledForegroundColor: AppColors.disabledText.withAlpha((AppColors.opacity70 * 255).round()),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space6,
            vertical: AppDimens.space4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          textStyle: AppTypography.button,
          minimumSize: const Size(AppDimens.heightLg, AppDimens.buttonHeight),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          disabledForegroundColor: AppColors.disabledText.withAlpha((AppColors.opacity70 * 255).round()),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space4,
            vertical: AppDimens.space2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: surfaceColor.withAlpha(isDark ? (AppColors.opacity10 * 255).round() : (AppColors.opacity50 * 255).round()),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space4,
          vertical: AppDimens.space4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(
            color: dividerColor,
            width: AppDimens.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(
            color: dividerColor,
            width: AppDimens.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(
            color: primaryColor,
            width: AppDimens.borderThick,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(
            color: AppColors.error,
            width: AppDimens.borderLight,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(
            color: AppColors.error,
            width: AppDimens.borderThick,
          ),
        ),
        hintStyle: AppTypography.body2.copyWith(
          color: textSecondaryColor.withAlpha((AppColors.opacity70 * 255).round()), // Adjusted opacity value slightly
        ),
        labelStyle: AppTypography.body2.copyWith(
          color: textSecondaryColor,
        ),
        errorStyle: AppTypography.caption.copyWith(
          color: AppColors.error,
        ),
        alignLabelWithHint: true,
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: AppDimens.borderLight,
        space: AppDimens.space1,
      ),
      iconTheme: IconThemeData( // Cannot be const, uses dynamic textPrimaryColor (line 198 area)
        color: textPrimaryColor,
        size: AppDimens.iconMd,
      ),
      primaryIconTheme: IconThemeData( // Cannot be const, uses dynamic primaryColor (line 205 area)
        color: primaryColor,
        size: AppDimens.iconMd,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: dividerColor.withAlpha((AppColors.opacity50 * 255).round()),
        circularTrackColor: dividerColor.withAlpha((AppColors.opacity50 * 255).round()),
      ),
      pageTransitionsTheme: AppAnimations.pageTransitionsTheme,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor.withAlpha((AppColors.opacity70 * 255).round()), // Adjusted opacity value
        type: BottomNavigationBarType.fixed,
        elevation: AppDimens.elevation8,
        selectedLabelStyle: AppTypography.label2.copyWith(
          fontWeight: AppTypography.semiBold,
        ),
        unselectedLabelStyle: AppTypography.label2,
        selectedIconTheme: const IconThemeData( // Can be const
          size: AppDimens.iconMd,
        ),
        unselectedIconTheme: const IconThemeData( // Can be const
          size: AppDimens.iconMd,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        deleteIconColor: textSecondaryColor,
        disabledColor: AppColors.disabled.withAlpha((AppColors.opacity30 * 255).round()),
        selectedColor: primaryColor,
        secondarySelectedColor: AppColors.accent,
        labelPadding: const EdgeInsets.symmetric(horizontal: AppDimens.space2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space3,
          vertical: AppDimens.space1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
        labelStyle: AppTypography.label2.copyWith(
          color: textPrimaryColor,
        ),
        secondaryLabelStyle: AppTypography.label2.copyWith(
          color: ThemeData.estimateBrightnessForColor(primaryColor) == Brightness.dark
                 ? AppColors.darkTextPrimary
                 : AppColors.lightTextPrimary,
        ),
        brightness: brightness,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor.withAlpha((AppColors.opacity70 * 255).round()), // Adjusted opacity
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: primaryColor,
            width: AppDimens.borderThick,
          ),
        ),
        labelStyle: AppTypography.label1.copyWith(
          fontWeight: AppTypography.semiBold,
        ),
        unselectedLabelStyle: AppTypography.label1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        elevation: AppDimens.elevation4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        titleTextStyle: AppTypography.h5.copyWith(color: textPrimaryColor),
        contentTextStyle: AppTypography.body2.copyWith(color: textSecondaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        elevation: AppDimens.elevation8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          if (states.contains(WidgetState.disabled)) {
            return isDark ? AppColors.darkSurface : AppColors.lightSurface;
          }
          return isDark ? AppColors.darkTextSecondary : AppColors.lightTextHint;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withAlpha((AppColors.opacity50 * 255).round());
          }
          if (states.contains(WidgetState.disabled)) {
            return (isDark ? AppColors.darkSurface : AppColors.lightSurface).withAlpha((AppColors.opacity50 * 255).round());
          }
          return (isDark ? AppColors.darkTextSecondary : AppColors.lightTextHint).withAlpha((AppColors.opacity30 * 255).round());
        }),
         overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return primaryColor.withAlpha((AppColors.opacity10 * 255).round());
          }
          return null;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          if (states.contains(WidgetState.disabled)) {
             return isDark ? AppColors.darkSurface : AppColors.lightSurface;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(onPrimaryColor),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(
              width: AppDimens.borderMedium,
              color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextHint).withAlpha((AppColors.opacity50 * 255).round()),
            );
          }
          return BorderSide(
            width: AppDimens.borderMedium,
            color: primaryColor,
          );
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXs),
        ),
         overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return primaryColor.withAlpha((AppColors.opacity10 * 255).round());
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
           if (states.contains(WidgetState.disabled)) {
             return isDark ? AppColors.darkSurface : AppColors.lightSurface;
          }
          return textSecondaryColor;
        }),
         overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return primaryColor.withAlpha((AppColors.opacity10 * 255).round());
          }
          return null;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withAlpha((AppColors.opacity30 * 255).round()),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withAlpha((AppColors.opacity20 * 255).round()),
        valueIndicatorColor: primaryColor.darken(0.1),
        valueIndicatorTextStyle: AppTypography.caption.copyWith(color: onPrimaryColor),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurface : AppColors.lightSurface).withAlpha((AppColors.opacity90 * 255).round()),
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        textStyle: AppTypography.caption.copyWith(color: textPrimaryColor),
        preferBelow: false,
      ),
    );
  }

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color primary(BuildContext context) => Theme.of(context).primaryColor;
  static Color background(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color surface(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color card(BuildContext context) => Theme.of(context).cardTheme.color ?? (isDark(context) ? AppColors.darkCard : AppColors.lightCard);
  static Color textPrimary(BuildContext context) => Theme.of(context).textTheme.bodyLarge?.color ?? (isDark(context) ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
  static Color textSecondary(BuildContext context) => Theme.of(context).textTheme.bodyMedium?.color ?? (isDark(context) ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);
  static Color error(BuildContext context) => Theme.of(context).colorScheme.error;
  static Color success(BuildContext context) => AppColors.success;
  static Color warning(BuildContext context) => AppColors.warning;
  static Color info(BuildContext context) => AppColors.info;
}