// lib/app/themes/constants/app_dimensions.dart
import 'package:flutter/material.dart';

/// نظام الأبعاد والمسافات الموحد
/// يستخدم نظام 4px كأساس للمسافات
class AppDimens {
  AppDimens._();

  // ===== نظام المسافات (Base 4px) =====
  static const double space0 = 0.0;
  static const double space1 = 4.0;   // xs
  static const double space2 = 8.0;   // sm
  static const double space3 = 12.0;  // md
  static const double space4 = 16.0;  // lg
  static const double space5 = 20.0;  // xl
  static const double space6 = 24.0;  // 2xl
  static const double space8 = 32.0;  // 3xl
  static const double space10 = 40.0; // 4xl
  static const double space12 = 48.0; // 5xl
  static const double space16 = 64.0; // 6xl

  // ===== نصف القطر للزوايا =====
  static const double radiusNone = 0.0;
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2xl = 24.0;
  static const double radiusFull = 999.0;

  // ===== سمك الحدود =====
  static const double borderNone = 0.0;
  static const double borderThin = 0.5;
  static const double borderLight = 1.0;
  static const double borderMedium = 1.5;
  static const double borderThick = 2.0;

  // ===== أحجام الأيقونات =====
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;
  static const double icon2xl = 48.0;

  // ===== ارتفاعات المكونات =====
  static const double heightXs = 32.0;
  static const double heightSm = 36.0;
  static const double heightMd = 40.0;
  static const double heightLg = 48.0;
  static const double heightXl = 56.0;
  static const double height2xl = 64.0;

  // ===== ارتفاعات خاصة =====
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 56.0;
  static const double buttonHeight = 52.0;
  static const double inputHeight = 56.0;
  static const double fabSize = 56.0;
  static const double fabSizeMini = 40.0;

  // ===== أحجام الصور الرمزية =====
  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 72.0;

  // ===== الظلال =====
  static const double elevationNone = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation4 = 4.0;
  static const double elevation6 = 6.0;
  static const double elevation8 = 8.0;

  // ===== الحشوات الافتراضية =====
  static const EdgeInsets paddingZero = EdgeInsets.zero;
  static const EdgeInsets paddingXs = EdgeInsets.all(space1);
  static const EdgeInsets paddingSm = EdgeInsets.all(space2);
  static const EdgeInsets paddingMd = EdgeInsets.all(space4);
  static const EdgeInsets paddingLg = EdgeInsets.all(space6);
  static const EdgeInsets paddingXl = EdgeInsets.all(space8);

  // ===== الحشوات الأفقية =====
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: space2);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: space4);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: space6);

  // ===== الحشوات العمودية =====
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: space2);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: space4);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: space6);

  // ===== نقاط التوقف للتصميم المتجاوب =====
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 1024.0;
  static const double breakpointDesktop = 1440.0;

  // ===== دوال مساعدة للتصميم المتجاوب =====

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < breakpointMobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= breakpointMobile && width < breakpointTablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= breakpointTablet;
  }

  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) return paddingMd;
    if (isTablet(context)) return paddingLg;
    return paddingXl;
  }

  static double responsiveValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}