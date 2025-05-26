// lib/app/themes/constants/app_colors.dart
import 'package:flutter/material.dart';

/// نظام الألوان الموحد للتطبيق
/// يدعم الوضع الفاتح والداكن مع اللون الأساسي #0B8457
class AppColors {
  AppColors._();

  // ===== الألوان الأساسية =====
  static const Color primary = Color(0xFF0B8457);
  static const Color primaryLight = Color(0xFF1FA06D);
  static const Color primaryDark = Color(0xFF076842);
  static const Color primarySoft = Color(0xFF4DB381);
  
  // تدرجات اللون الأساسي
  static const List<Color> primaryGradient = [primaryLight, primary];
  
  // ===== ألوان ثانوية =====
  static const Color accent = Color(0xFF2ECC71);
  static const Color accentLight = Color(0xFF5DADE2);
  static const Color accentDark = Color(0xFF27AE60);
  
  // ===== ألوان دلالية =====
  static const Color success = Color(0xFF27AE60);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);
  
  // ===== الوضع الفاتح =====
  static const Color lightBackground = Color(0xFFFCFDFC);
  static const Color lightSurface = Color(0xFFF5FAF8);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE0E0E0);
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightTextHint = Color(0xFF9E9E9E);
  
  // ===== الوضع الداكن =====
  static const Color darkBackground = Color(0xFF0A1F17);
  static const Color darkSurface = Color(0xFF0D2920);
  static const Color darkCard = Color(0xFF122A20);
  static const Color darkDivider = Color(0xFF2A3F35);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFBDBDBD);
  static const Color darkTextHint = Color(0xFF757575);
  
  // ===== ألوان خاصة بالتطبيق الإسلامي =====
  static const Color athkarBackground = Color(0xFFF0F9F4);
  static const Color prayerActive = Color(0xFF1FA06D);
  static const Color qiblaAccent = Color(0xFF0B8457);
  static const Color tasbihAccent = Color(0xFF4DB381);
  
  // ===== ألوان الحالات =====
  static const Color disabled = Color(0xFFE0E0E0);
  static const Color disabledText = Color(0xFF9E9E9E);
  static const Color transparent = Colors.transparent;
  
  // ===== قيم الشفافية =====
  static const double opacity5 = 0.05;
  static const double opacity10 = 0.10;
  static const double opacity20 = 0.20;
  static const double opacity30 = 0.30;
  static const double opacity50 = 0.50;
  static const double opacity70 = 0.70;
  static const double opacity90 = 0.90;
  
  // ===== دوال مساعدة =====
  
  /// الحصول على لون الخلفية حسب الوضع
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }
  
  /// الحصول على لون السطح حسب الوضع
  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }
  
  /// الحصول على لون البطاقة حسب الوضع
  static Color card(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : lightCard;
  }
  
  /// الحصول على لون النص الأساسي حسب الوضع
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : lightTextPrimary;
  }
  
  /// الحصول على لون النص الثانوي حسب الوضع
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }
  
  /// الحصول على لون الفاصل حسب الوضع
  static Color divider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkDivider
        : lightDivider;
  }
  
  /// إنشاء لون بشفافية
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  /// التحقق من الوضع الداكن
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}