// lib/app/themes/core/utils/arabic_helper.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';

/// مساعد للثيم العربي - يوفر خصائص وتنسيقات مناسبة للتطبيقات العربية
class ArabicThemeHelper {
  ArabicThemeHelper._();
  
  /// إعداد اتجاه النص للعربية
  static TextDirection get arabicTextDirection => TextDirection.rtl;
  
  /// التحقق من الوضع الداكن
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
  
  /// الحصول على الوان متوافقة مع معايير الوصول
  static Color getAccessibleTextColor(Color backgroundColor, {bool isSecondary = false}) {
    // حساب نسبة التباين للتأكد من مطابقة معايير WCAG 2.0
    final double luminance = backgroundColor.computeLuminance();
    
    if (luminance > 0.5) {
      // خلفية فاتحة تحتاج نص داكن
      return isSecondary ? const Color(0xFF505050) : const Color(0xFF202020);
    } else {
      // خلفية داكنة تحتاج نص فاتح
      return isSecondary ? const Color(0xDDFFFFFF) : Colors.white;
    }
  }
  
  /// تنسيقات مخصصة للنصوص العربية
  static TextStyle getArabicTextStyle({
    bool isBold = false,
    bool isLarge = false,
    bool isSecondary = false,
    Color? textColor,
    Color? backgroundColor,
    double? fontSize,
  }) {
    // تفضيل الخط وحجمه حسب المتطلبات العربية
    return TextStyle(
      fontFamily: AppTypography.fontFamilyArabic,
      height: 1.5, // ارتفاع مناسب للنصوص العربية
      fontSize: fontSize ?? (isLarge ? 18 : 16),
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: textColor ?? (isSecondary ? AppColors.lightTextSecondary : AppColors.lightTextPrimary),
      // خصائص إضافية للغة العربية
      letterSpacing: -0.3, // تقليل التباعد بين الحروف العربية
      wordSpacing: 0.5, // زيادة التباعد بين الكلمات
      locale: const Locale('ar'), // تحديد اللغة للمساعدة في تنسيق النص
    );
  }
  
  /// زخرفة لبطاقات مخصصة مع تحسين لمعايير الوصول
  static BoxDecoration getAccessibleCardDecoration(BuildContext context, {
    double opacity = AppColors.opacity30,
    double borderRadius = AppDimens.radiusLg,
  }) {
    final isDark = isDarkMode(context);
    final baseColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    
    return BoxDecoration(
      color: baseColor.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: baseColor.withOpacity(isDark ? 0.4 : 0.3),
        width: AppDimens.borderLight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.4 : 0.2),
          blurRadius: AppDimens.space3,
          offset: Offset(0, AppDimens.space1),
        ),
      ],
    );
  }
  
  /// تنسيق للأزرار المناسبة للتصميم العربي
  static ButtonStyle getArabicButtonStyle(BuildContext context, {
    bool isOutlined = false,
    double borderRadius = AppDimens.radiusMd,
  }) {
    final isDark = isDarkMode(context);
    final buttonColor = AppColors.primary;
    final textColor = isDark ? Colors.white : Colors.white;
    
    if (isOutlined) {
      return OutlinedButton.styleFrom(
        foregroundColor: buttonColor,
        side: BorderSide(
          color: buttonColor.withOpacity(isDark ? 0.7 : 0.5),
          width: AppDimens.borderLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: TextStyle(
          fontFamily: AppTypography.fontFamilyArabic,
          fontWeight: FontWeight.bold,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.space6,
          vertical: AppDimens.space4,
        ),
      );
    } else {
      return ElevatedButton.styleFrom(
        backgroundColor: buttonColor.withOpacity(AppColors.opacity90),
        foregroundColor: textColor,
        textStyle: TextStyle(
          fontFamily: AppTypography.fontFamilyArabic,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.space6,
          vertical: AppDimens.space4,
        ),
        shadowColor: Colors.transparent,
      );
    }
  }
  
  /// تخصيص المدخلات للغة العربية
  static InputDecoration getArabicInputDecoration(BuildContext context, {
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final isDark = isDarkMode(context);
    final fillColor = isDark 
      ? AppColors.darkCard.withOpacity(AppColors.opacity20) 
      : AppColors.lightCard.withOpacity(AppColors.opacity20);
    
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      fillColor: fillColor,
      filled: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppDimens.space4,
        vertical: AppDimens.space4,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: BorderSide(
          color: isDark 
            ? AppColors.primaryLight.withOpacity(0.5) 
            : Colors.white.withOpacity(0.3),
          width: AppDimens.borderLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: BorderSide(
          color: isDark 
            ? AppColors.primaryLight.withOpacity(0.5) 
            : Colors.white.withOpacity(0.3),
          width: AppDimens.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: BorderSide(
          color: AppColors.accentLight,
          width: AppDimens.borderThick,
        ),
      ),
      hintStyle: TextStyle(
        fontFamily: AppTypography.fontFamilyArabic,
        color: isDark 
          ? AppColors.darkTextSecondary.withOpacity(0.7) 
          : AppColors.lightTextSecondary.withOpacity(0.7),
      ),
      labelStyle: TextStyle(
        fontFamily: AppTypography.fontFamilyArabic,
        color: isDark 
          ? AppColors.darkTextPrimary.withOpacity(0.8) 
          : AppColors.lightTextPrimary.withOpacity(0.8),
      ),
      // التوجيه المناسب للعربية
      alignLabelWithHint: true,
      floatingLabelAlignment: FloatingLabelAlignment.start,
    );
  }
}