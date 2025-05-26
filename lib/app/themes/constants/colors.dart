// ===== lib/app/themes/constants/colors.dart =====
import 'package:flutter/material.dart';

/// ثوابت الألوان للتطبيق
class AppColors {
  // Private constructor
  AppColors._();

  // ===== Primary Colors =====
  static const Color primary = Color(0xFF0B8457);
  static const Color primaryLight = Color(0xFF1FA06D);
  static const Color primaryDark = Color(0xFF076842);
  static const Color primarySoft = Color(0xFF4DB381);
  
  // ===== Accent Colors =====
  static const Color accent = Color(0xFF2ECC71);
  static const Color accentLight = Color(0xFF5DADE2);
  static const Color accentDark = Color(0xFF27AE60);
  
  // ===== Semantic Colors =====
  static const Color success = Color(0xFF27AE60);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);
  
  // ===== Neutral Colors - Light Mode =====
  static const Color background = Color(0xFFFCFDFC);
  static const Color surface = Color(0xFFF5FAF8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);
  
  // ===== Neutral Colors - Dark Mode =====
  static const Color darkBackground = Color(0xFF0A1F17);
  static const Color darkSurface = Color(0xFF0D2920);
  static const Color darkCard = Color(0xFF122A20);
  static const Color darkDivider = Color(0xFF2A3F35);
  
  // ===== Text Colors - Light Mode =====
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);
  
  // ===== Text Colors - Dark Mode =====
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFBDBDBD);
  static const Color darkTextHint = Color(0xFF757575);
  static const Color darkTextDisabled = Color(0xFF616161);
  
  // ===== State Colors =====
  static const Color disabled = Color(0xFFE0E0E0);
  static const Color disabledText = Color(0xFF9E9E9E);
  static const Color hover = Color(0x0A000000);
  static const Color focus = Color(0x1F000000);
  static const Color selected = Color(0x14000000);
  static const Color activated = Color(0x1F000000);
  
  // ===== Special Colors =====
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  
  // ===== Gradient Colors =====
  static const List<Color> primaryGradient = [primaryLight, primary];
  static const List<Color> accentGradient = [accent, accentDark];
  static const List<Color> successGradient = [Color(0xFF5DCEA1), success];
  static const List<Color> errorGradient = [Color(0xFFFF6B6B), error];
  
  // ===== Opacity Values =====
  static const double opacity5 = 0.05;
  static const double opacity10 = 0.10;
  static const double opacity20 = 0.20;
  static const double opacity30 = 0.30;
  static const double opacity40 = 0.40;
  static const double opacity50 = 0.50;
  static const double opacity60 = 0.60;
  static const double opacity70 = 0.70;
  static const double opacity80 = 0.80;
  static const double opacity90 = 0.90;
}

// ===== lib/app/themes/constants/dimensions.dart =====

/// ثوابت الأبعاد والمسافات
class AppDimens {
  // Private constructor
  AppDimens._();

  // ===== Spacing System (Base 4px) =====
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
  static const double space20 = 80.0; // 7xl
  static const double space24 = 96.0; // 8xl
  
  // ===== Border Radius =====
  static const double radiusNone = 0.0;
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2xl = 24.0;
  static const double radius3xl = 32.0;
  static const double radiusFull = 999.0;
  
  // ===== Border Width =====
  static const double borderNone = 0.0;
  static const double borderThin = 0.5;
  static const double borderLight = 1.0;
  static const double borderMedium = 1.5;
  static const double borderThick = 2.0;
  static const double borderHeavy = 3.0;
  
  // ===== Icon Sizes =====
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;
  static const double icon2xl = 48.0;
  static const double icon3xl = 64.0;
  
  // ===== Component Heights =====
  static const double heightXs = 32.0;
  static const double heightSm = 36.0;
  static const double heightMd = 40.0;
  static const double heightLg = 48.0;
  static const double heightXl = 56.0;
  static const double height2xl = 64.0;
  
  // ===== App Bar Height =====
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 64.0;
  
  // ===== Bottom Navigation Height =====
  static const double bottomNavHeight = 56.0;
  static const double bottomNavHeightWithLabel = 64.0;
  
  // ===== FAB Sizes =====
  static const double fabSizeMini = 40.0;
  static const double fabSizeRegular = 56.0;
  static const double fabSizeExtended = 48.0;
  
  // ===== Avatar Sizes =====
  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 72.0;
  static const double avatar2xl = 96.0;
  
  // ===== Elevation =====
  static const double elevationNone = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation3 = 3.0;
  static const double elevation4 = 4.0;
  static const double elevation6 = 6.0;
  static const double elevation8 = 8.0;
  static const double elevation12 = 12.0;
  static const double elevation16 = 16.0;
  static const double elevation24 = 24.0;
}

// ===== lib/app/themes/constants/typography.dart =====

/// ثوابت أنماط النصوص
class AppTypography {
  // Private constructor
  AppTypography._();

  // ===== Font Families =====
  static const String fontFamily = 'Cairo';
  static const String fontFamilyEnglish = 'Inter';
  static const String fontFamilyMono = 'Courier New';
  
  // ===== Display Styles =====
  static const TextStyle display = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  // ===== Headline Styles =====
  static const TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.3,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.1,
  );
  
  // ===== Title Styles =====
  static const TextStyle title1 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );
  
  static const TextStyle title2 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
  );
  
  static const TextStyle title3 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.1,
  );
  
  // ===== Body Styles =====
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );
  
  static const TextStyle body3 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );
  
  // ===== Label Styles =====
  static const TextStyle label1 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );
  
  static const TextStyle label2 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );
  
  // ===== Caption & Overline =====
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.4,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 1.5,
  );
  
  // ===== Button Text =====
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  // ===== Special Styles =====
  static const TextStyle code = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    fontFamily: fontFamilyMono,
  );
  
  // ===== Font Weights =====
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

// ===== lib/app/themes/constants/shadows.dart =====

/// ثوابت الظلال والتأثيرات
class AppShadows {
  // Private constructor
  AppShadows._();

  // ===== Elevation Shadows =====
  static List<BoxShadow> get none => [];
  
  static List<BoxShadow> get elevation1 => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 1,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> get elevation2 => [
    BoxShadow(
      color: Colors.black.withOpacity(0.07),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> get elevation3 => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 2,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get elevation4 => [
    BoxShadow(
      color: Colors.black.withOpacity(0.09),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 3,
      offset: const Offset(0, 3),
    ),
  ];
  
  static List<BoxShadow> get elevation6 => [
    BoxShadow(
      color: Colors.black.withOpacity(0.11),
      blurRadius: 6,
      offset: const Offset(0, 3),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 5),
    ),
  ];
  
  static List<BoxShadow> get elevation8 => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 5,
      offset: const Offset(0, 7),
    ),
  ];
  
  // ===== Colored Shadows =====
  static List<BoxShadow> colored(Color color, {double opacity = 0.3}) => [
    BoxShadow(
      color: color.withOpacity(opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  // ===== Glow Effect =====
  static List<BoxShadow> glow(Color color, {double opacity = 0.4}) => [
    BoxShadow(
      color: color.withOpacity(opacity * 0.6),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: color.withOpacity(opacity),
      blurRadius: 10,
      spreadRadius: -5,
    ),
  ];
  
  // ===== Inner Shadow (using decoration) =====
  static BoxDecoration innerShadow({
    Color color = Colors.black,
    double opacity = 0.1,
    double blur = 10,
    Offset offset = const Offset(0, 2),
  }) {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(opacity),
          blurRadius: blur,
          offset: offset,
          spreadRadius: -blur / 2,
        ),
      ],
    );
  }
}