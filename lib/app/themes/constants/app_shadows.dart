// lib/app/themes/constants/app_shadows.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// نظام الظلال الموحد للتطبيق
class AppShadows {
  AppShadows._();

  // ===== ظلال خفيفة =====
  static List<BoxShadow> elevation1 = [
    BoxShadow(
      color: Colors.black.withAlpha(AppColors.alpha10),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> elevation2 = [
    BoxShadow(
      color: Colors.black.withAlpha(AppColors.alpha10),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  // ===== ظلال متوسطة =====
  static List<BoxShadow> elevation4 = [
    BoxShadow(
      color: Colors.black.withAlpha(AppColors.alpha10),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevation6 = [
    BoxShadow(
      color: Colors.black.withAlpha(AppColors.alpha10),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  // ===== ظلال قوية =====
  static List<BoxShadow> elevation8 = [
    BoxShadow(
      color: Colors.black.withAlpha(AppColors.alpha20),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> elevation12 = [
    BoxShadow(
      color: Colors.black.withAlpha(AppColors.alpha20),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  // ===== ظلال ملونة =====
  static List<BoxShadow> coloredShadow(Color color, {double elevation = 4}) {
    return [
      BoxShadow(
        color: color.withAlpha(AppColors.alpha30),
        blurRadius: elevation * 2,
        offset: Offset(0, elevation),
      ),
    ];
  }

  // ===== ظلال داخلية =====
  static List<BoxShadow> innerShadow = [
    BoxShadow(
      color: Colors.black.withAlpha(AppColors.alpha10),
      blurRadius: 4,
      offset: const Offset(0, -2),
    ),
  ];

  // ===== ظلال للنص =====
  static List<Shadow> textShadow = [
    Shadow(
      color: Colors.black.withAlpha(AppColors.alpha30),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<Shadow> textGlow(Color color) {
    return [
      Shadow(
        color: color.withAlpha(AppColors.alpha50),
        blurRadius: 8,
      ),
    ];
  }

  // ===== ظلال متقدمة =====
  static List<BoxShadow> neumorphism({
    required Color backgroundColor,
    double intensity = 1.0,
  }) {
    final lightColor = backgroundColor.lighten(0.1 * intensity);
    final darkColor = backgroundColor.darken(0.2 * intensity);
    
    return [
      BoxShadow(
        color: darkColor.withAlpha(AppColors.alpha30),
        blurRadius: 10 * intensity,
        offset: Offset(5 * intensity, 5 * intensity),
      ),
      BoxShadow(
        color: lightColor.withAlpha(AppColors.alpha30),
        blurRadius: 10 * intensity,
        offset: Offset(-5 * intensity, -5 * intensity),
      ),
    ];
  }

  // ===== دوال مساعدة =====
  
  /// الحصول على ظل حسب الارتفاع
  static List<BoxShadow> elevationShadow(double elevation) {
    if (elevation <= 0) return [];
    if (elevation <= 1) return elevation1;
    if (elevation <= 2) return elevation2;
    if (elevation <= 4) return elevation4;
    if (elevation <= 6) return elevation6;
    if (elevation <= 8) return elevation8;
    return elevation12;
  }

  /// ظل متجاوب حسب الثيم
  static List<BoxShadow> responsiveShadow(
    BuildContext context,
    double elevation,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isDark) {
      // ظلال أقل وضوحاً في الوضع الداكن
      return elevationShadow(elevation * 0.5);
    }
    
    return elevationShadow(elevation);
  }
}

// Extension للون لإضافة دوال lighten و darken
extension ColorExtension on Color {
  Color lighten([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}