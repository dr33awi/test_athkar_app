// lib/app/themes/constants/app_gradients.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// نظام التدرجات اللونية الموحد
class AppGradients {
  AppGradients._();

  // ===== التدرجات الأساسية =====
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryDark = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accent = LinearGradient(
    colors: [AppColors.accentLight, AppColors.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== تدرجات الصلاة =====
  static const LinearGradient fajr = LinearGradient(
    colors: [Color(0xFF2C5F7C), Color(0xFF6A8CAF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient dhuhr = LinearGradient(
    colors: [Color(0xFFFFD662), Color(0xFFFFAA00)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient asr = LinearGradient(
    colors: [Color(0xFFFF8C42), Color(0xFFFF6B6B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient maghrib = LinearGradient(
    colors: [Color(0xFF355C7D), Color(0xFF6C5B7B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient isha = LinearGradient(
    colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ===== تدرجات الخلفيات =====
  static const LinearGradient backgroundLight = LinearGradient(
    colors: [Color(0xFFF5FAF8), Color(0xFFE8F5F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundDark = LinearGradient(
    colors: [Color(0xFF0A1F17), Color(0xFF122A20)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ===== تدرجات خاصة =====
  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient error = LinearGradient(
    colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warning = LinearGradient(
    colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient info = LinearGradient(
    colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== تدرجات شفافة =====
  static LinearGradient transparent({
    required Color color,
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
  }) {
    return LinearGradient(
      colors: [
        color,
        color.withAlpha(AppColors.alpha70),
        color.withAlpha(AppColors.alpha30),
        color.withAlpha(0),
      ],
      begin: begin,
      end: end,
    );
  }

  // ===== تدرج دائري =====
  static RadialGradient radial({
    required List<Color> colors,
    AlignmentGeometry center = Alignment.center,
    double radius = 0.8,
  }) {
    return RadialGradient(
      colors: colors,
      center: center,
      radius: radius,
    );
  }

  // ===== تدرج مخصص =====
  static LinearGradient custom({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    List<double>? stops,
  }) {
    return LinearGradient(
      colors: colors,
      begin: begin,
      end: end,
      stops: stops,
    );
  }

  // ===== دوال مساعدة =====
  
  /// تدرج من لون واحد
  static LinearGradient fromColor(
    Color color, {
    double intensity = 0.2,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: [
        color.lighten(intensity),
        color,
        color.darken(intensity),
      ],
      begin: begin,
      end: end,
    );
  }

  /// تدرج حسب الوقت
  static LinearGradient byTimeOfDay() {
    final hour = DateTime.now().hour;
    
    if (hour >= 4 && hour < 7) return fajr;
    if (hour >= 11 && hour < 15) return dhuhr;
    if (hour >= 15 && hour < 18) return asr;
    if (hour >= 18 && hour < 20) return maghrib;
    return isha;
  }

  /// تطبيق تدرج على نص
  static Widget applyToText({
    required String text,
    required Gradient gradient,
    TextStyle? style,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}

// Extension helper
extension on Color {
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