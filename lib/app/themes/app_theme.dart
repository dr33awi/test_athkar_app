// lib/app/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/app_colors.dart'; //
import 'constants/app_dimensions.dart'; //
import 'constants/app_typography.dart'; //
import 'constants/app_animations.dart'; //

/// نظام الثيم الموحد للتطبيق
/// يدعم الوضع الفاتح والداكن مع تحسينات للغة العربية
class AppTheme {
  AppTheme._();

  /// إنشاء الثيم الفاتح
  static ThemeData lightTheme() {
    return _buildTheme(
      brightness: Brightness.light,
      primaryColor: AppColors.primary, //
      backgroundColor: AppColors.lightBackground, //
      surfaceColor: AppColors.lightSurface, //
      cardColor: AppColors.lightCard, //
      textPrimaryColor: AppColors.lightTextPrimary, //
      textSecondaryColor: AppColors.lightTextSecondary, //
      dividerColor: AppColors.lightDivider, //
    );
  }

  /// إنشاء الثيم الداكن
  static ThemeData darkTheme() {
    return _buildTheme(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryLight, //
      backgroundColor: AppColors.darkBackground, //
      surfaceColor: AppColors.darkSurface, //
      cardColor: AppColors.darkCard, //
      textPrimaryColor: AppColors.darkTextPrimary, //
      textSecondaryColor: AppColors.darkTextSecondary, //
      dividerColor: AppColors.darkDivider, //
    );
  }

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
  }) {
    final bool isDark = brightness == Brightness.dark;

    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily, //

      // نظام الألوان
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: isDark ? AppColors.darkBackground : Colors.white, //
        secondary: AppColors.accent, //
        onSecondary: Colors.white,
        tertiary: AppColors.accentLight, //
        onTertiary: Colors.white,
        error: AppColors.error, //
        onError: Colors.white,
        background: backgroundColor,
        onBackground: textPrimaryColor,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
        surfaceVariant: cardColor,
        onSurfaceVariant: textSecondaryColor,
      ),

      // شريط التطبيق
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h4.copyWith( //
          color: textPrimaryColor,
        ),
        iconTheme: IconThemeData(
          color: textPrimaryColor,
          size: AppDimens.iconMd, //
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: backgroundColor,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),

      // البطاقات
      // =========== المنطقة المصححة ===========
      cardTheme: CardThemeData( // تم التغيير هنا
        color: cardColor,
        elevation: AppDimens.elevationNone, //
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd), //
        ),
      ),
      // ======================================

      // أنماط النصوص
      textTheme: AppTypography.createTextTheme(color: textPrimaryColor), //

      // الأزرار المرتفعة
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? AppColors.darkBackground : Colors.white, //
          disabledBackgroundColor: AppColors.disabled, //
          disabledForegroundColor: AppColors.disabledText, //
          elevation: AppDimens.elevationNone, //
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space6, //
            vertical: AppDimens.space4, //
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd), //
          ),
          textStyle: AppTypography.button, //
          minimumSize: const Size(double.infinity, AppDimens.buttonHeight), //
        ),
      ),

      // الأزرار المحددة
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(
            color: primaryColor,
            width: AppDimens.borderMedium, //
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space6, //
            vertical: AppDimens.space4, //
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd), //
          ),
          textStyle: AppTypography.button, //
          minimumSize: const Size(double.infinity, AppDimens.buttonHeight), //
        ),
      ),

      // الأزرار النصية
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space4, //
            vertical: AppDimens.space2, //
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd), //
          ),
          textStyle: AppTypography.button, //
        ),
      ),

      // حقول الإدخال
      inputDecorationTheme: InputDecorationTheme(
        fillColor: surfaceColor,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space4, //
          vertical: AppDimens.space4, //
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd), //
          borderSide: BorderSide(
            color: dividerColor,
            width: AppDimens.borderLight, //
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd), //
          borderSide: BorderSide(
            color: dividerColor,
            width: AppDimens.borderLight, //
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd), //
          borderSide: BorderSide(
            color: primaryColor,
            width: AppDimens.borderThick, //
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd), //
          borderSide: BorderSide(
            color: AppColors.error, //
            width: AppDimens.borderLight, //
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd), //
          borderSide: BorderSide(
            color: AppColors.error, //
            width: AppDimens.borderThick, //
          ),
        ),
        hintStyle: AppTypography.body2.copyWith( //
          color: textSecondaryColor.withOpacity(0.6),
        ),
        labelStyle: AppTypography.body2.copyWith( //
          color: textSecondaryColor,
        ),
        errorStyle: AppTypography.caption.copyWith( //
          color: AppColors.error, //
        ),
        // دعم RTL للعربية
        alignLabelWithHint: true,
      ),

      // الفواصل
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: AppDimens.borderLight, //
        space: AppDimens.space6, //
      ),

      // الأيقونات
      iconTheme: IconThemeData(
        color: textPrimaryColor,
        size: AppDimens.iconMd, //
      ),

      // مؤشرات التقدم
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: dividerColor,
        circularTrackColor: dividerColor,
      ),

      // انتقالات الصفحات
      pageTransitionsTheme: AppAnimations.pageTransitionsTheme, //

      // شريط التنقل السفلي
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: AppDimens.elevation8, //
        selectedLabelStyle: AppTypography.label2.copyWith( //
          fontWeight: AppTypography.semiBold, //
        ),
        unselectedLabelStyle: AppTypography.label2, //
        selectedIconTheme: const IconThemeData(
          size: AppDimens.iconMd, //
        ),
        unselectedIconTheme: const IconThemeData(
          size: AppDimens.iconMd, //
        ),
      ),

      // الشرائح
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        deleteIconColor: textSecondaryColor,
        disabledColor: AppColors.disabled, //
        selectedColor: primaryColor,
        secondarySelectedColor: AppColors.accent, //
        labelPadding: const EdgeInsets.symmetric(horizontal: AppDimens.space2), //
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space3, //
          vertical: AppDimens.space1, //
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusFull), //
        ),
        labelStyle: AppTypography.label2.copyWith( //
          color: textPrimaryColor,
        ),
        secondaryLabelStyle: AppTypography.label2.copyWith( //
          color: isDark ? AppColors.darkBackground : Colors.white, //
        ),
        brightness: brightness,
      ),

      // أشرطة التبويب
      // =========== المنطقة المصححة ===========
      tabBarTheme: TabBarThemeData( // تم التغيير هنا
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: primaryColor,
            width: AppDimens.borderThick, //
          ),
        ),
        labelStyle: AppTypography.label1.copyWith( //
          fontWeight: AppTypography.semiBold, //
        ),
        unselectedLabelStyle: AppTypography.label1, //
      ),
      // ======================================
    );
  }

  // ===== دوال مساعدة للوصول السريع =====

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
    return AppColors.success; //
  }

  /// الحصول على لون التحذير
  static Color warning(BuildContext context) {
    return AppColors.warning; //
  }

  /// الحصول على لون المعلومات
  static Color info(BuildContext context) {
    return AppColors.info; //
  }
}