// lib/app/themes/constants/app_animations.dart
import 'package:flutter/material.dart';

/// ثوابت الحركات فقط - استخدم flutter_staggered_animations للحركات الفعلية
class AppAnimations {
  AppAnimations._();

  // ===== مدد الحركات الموحدة =====
  static const Duration durationInstant = Duration(milliseconds: 100);
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 400);
  static const Duration durationVerySlow = Duration(milliseconds: 600);
  static const Duration durationExtraSlow = Duration(milliseconds: 1000);
  
  // ===== منحنيات الحركة الموحدة =====
  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveSharp = Curves.easeInOutCubic;
  static const Curve curveSmooth = Curves.easeInOutQuint;
  static const Curve curveBounce = Curves.elasticOut;
  static const Curve curveOvershoot = Curves.easeOutBack;
  static const Curve curveAnticipate = Curves.easeInBack;
  
  // ===== إعدادات الحركات المتسلسلة =====
  static const int defaultColumnDelay = 50;
  static const int defaultGridDelay = 100;
  static const int defaultListDelay = 75;
  
  // ===== PageTransitionsTheme للاستخدام في app_theme.dart =====
  static const PageTransitionsTheme pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );
}