// lib/app/themes/core/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/colors.dart';
import 'constants/dimensions.dart';
import 'constants/typography.dart';
import 'constants/shadows.dart';

/// الثيم الموحد للتطبيق
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// إنشاء الثيم الفاتح
  static ThemeData lightTheme() => _buildTheme(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    backgroundColor: AppColors.background,
    surfaceColor: AppColors.surface,
    cardColor: AppColors.card,
    textPrimaryColor: AppColors.textPrimary,
    textSecondaryColor: AppColors.textSecondary,
    dividerColor: AppColors.divider,
    errorColor: AppColors.error,
  );

  /// إنشاء الثيم الداكن
  static ThemeData darkTheme() => _buildTheme(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryLight,
    backgroundColor: AppColors.darkBackground,
    surfaceColor: AppColors.darkSurface,
    cardColor: AppColors.darkCard,
    textPrimaryColor: AppColors.darkTextPrimary,
    textSecondaryColor: AppColors.darkTextSecondary,
    dividerColor: AppColors.darkDivider,
    errorColor: AppColors.error,
  );

  /// بناء الثيم الأساسي
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color cardColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
    required Color dividerColor,
    required Color errorColor,
  }) {
    final bool isDark = brightness == Brightness.dark;
    
    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      
      // Color Scheme
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: isDark ? AppColors.darkBackground : Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        tertiary: AppColors.accentLight,
        onTertiary: Colors.white,
        error: errorColor,
        onError: Colors.white,
        background: backgroundColor,
        onBackground: textPrimaryColor,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
        surfaceVariant: cardColor,
        onSurfaceVariant: textSecondaryColor,
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.headline3.copyWith(
          color: textPrimaryColor,
          fontFamily: AppTypography.fontFamily,
        ),
        iconTheme: IconThemeData(
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
      
      // Card Theme
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(color: textPrimaryColor),
        displayMedium: AppTypography.headline1.copyWith(color: textPrimaryColor),
        displaySmall: AppTypography.headline2.copyWith(color: textPrimaryColor),
        headlineLarge: AppTypography.headline1.copyWith(color: textPrimaryColor),
        headlineMedium: AppTypography.headline2.copyWith(color: textPrimaryColor),
        headlineSmall: AppTypography.headline3.copyWith(color: textPrimaryColor),
        titleLarge: AppTypography.title1.copyWith(color: textPrimaryColor),
        titleMedium: AppTypography.title2.copyWith(color: textPrimaryColor),
        titleSmall: AppTypography.title3.copyWith(color: textPrimaryColor),
        bodyLarge: AppTypography.body1.copyWith(color: textPrimaryColor),
        bodyMedium: AppTypography.body2.copyWith(color: textPrimaryColor),
        bodySmall: AppTypography.body3.copyWith(color: textSecondaryColor),
        labelLarge: AppTypography.label1.copyWith(color: textPrimaryColor),
        labelMedium: AppTypography.label2.copyWith(color: textPrimaryColor),
        labelSmall: AppTypography.caption.copyWith(color: textSecondaryColor),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.disabledText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space6,
            vertical: AppDimens.space4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          textStyle: AppTypography.button,
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space6,
            vertical: AppDimens.space4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          textStyle: AppTypography.button,
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
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
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        fillColor: surfaceColor,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space4,
          vertical: AppDimens.space4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(
            color: dividerColor,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(
            color: dividerColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(
            color: errorColor,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(
            color: errorColor,
            width: 2,
          ),
        ),
        hintStyle: AppTypography.body2.copyWith(
          color: textSecondaryColor.withOpacity(0.6),
        ),
        labelStyle: AppTypography.body2.copyWith(
          color: textSecondaryColor,
        ),
        errorStyle: AppTypography.caption.copyWith(
          color: errorColor,
        ),
      ),
      
      // Other Theme Properties
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: AppDimens.space6,
      ),
      
      iconTheme: IconThemeData(
        color: textPrimaryColor,
        size: AppDimens.iconMd,
      ),
      
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: dividerColor,
        circularTrackColor: dividerColor,
      ),
      
      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
  
  // ===== Helper Methods =====
  
  /// التحقق من الوضع الداكن
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
  
  /// الحصول على اللون الأساسي
  static Color primary(BuildContext context) {
    return Theme.of(context).primaryColor;
  }
  
  /// الحصول على لون الخلفية
  static Color background(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }
  
  /// الحصول على لون السطح
  static Color surface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }
  
  /// الحصول على لون البطاقة
  static Color card(BuildContext context) {
    return Theme.of(context).cardColor;
  }
  
  /// الحصول على لون النص الأساسي
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.color!;
  }
  
  /// الحصول على لون النص الثانوي
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.color!;
  }
  
  /// الحصول على لون الخطأ
  static Color error(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }
  
  /// الحصول على لون النجاح
  static Color success(BuildContext context) {
    return AppColors.success;
  }
  
  /// الحصول على لون التحذير
  static Color warning(BuildContext context) {
    return AppColors.warning;
  }
  
  /// الحصول على لون المعلومات
  static Color info(BuildContext context) {
    return AppColors.info;
  }
  
  /// الحصول على TextTheme
  static TextTheme textTheme(BuildContext context) {
    return Theme.of(context).textTheme;
  }
  
  /// الحصول على ColorScheme
  static ColorScheme colorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }
  
  // ===== Responsive Helpers =====
  
  /// عرض الشاشة
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// ارتفاع الشاشة
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// عرض نسبي
  static double widthPercent(BuildContext context, double percent) {
    return screenWidth(context) * percent;
  }
  
  /// ارتفاع نسبي
  static double heightPercent(BuildContext context, double percent) {
    return screenHeight(context) * percent;
  }
  
  /// هل الجهاز موبايل
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < 600;
  }
  
  /// هل الجهاز تابلت
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= 600 && width < 1200;
  }
  
  /// هل الجهاز كمبيوتر
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= 1200;
  }
  
  // ===== Platform Helpers =====
  
  /// هل المنصة iOS
  static bool isIOS(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS;
  }
  
  /// هل المنصة Android
  static bool isAndroid(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.android;
  }
  
  // ===== SafeArea Helpers =====
  
  /// الحشوة العلوية الآمنة
  static double safeTop(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
  
  /// الحشوة السفلية الآمنة
  static double safeBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }
  
  // ===== Keyboard Helpers =====
  
  /// هل لوحة المفاتيح مفتوحة
  static bool isKeyboardOpen(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }
  
  /// ارتفاع لوحة المفاتيح
  static double keyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }
}