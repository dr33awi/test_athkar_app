// lib/app/themes/theme_exports.dart
/// ملف تصدير موحد لجميع مكونات نظام الثيم
/// يسهل استيراد جميع المكونات من مكان واحد
library app_theme;

import 'package:flutter/material.dart';

// Import actual classes from their correct paths
import 'constants/app_colors.dart';
import 'constants/app_dimensions.dart';
// import 'constants/app_typography.dart'; // Unused direct import, already exported below
import 'constants/app_animations.dart';
import 'widgets/cards/app_card.dart' as app_card_widget;
import 'widgets/states/app_empty_state.dart';
import 'widgets/feedback/app_snackbar.dart';
import 'core/utils/reusable_components.dart';

// ===== الثيم الأساسي =====
export 'app_theme.dart';

// ===== الثوابت =====
export 'constants/app_colors.dart';
export 'constants/app_dimensions.dart';
export 'constants/app_typography.dart';
export 'constants/app_animations.dart';
export 'constants/app_shadows.dart';
export 'constants/app_icons.dart';
export 'constants/app_gradients.dart';
// ===== الأدوات الأساسية =====
export 'core/theme_extensions.dart';
export 'core/utils/arabic_helper.dart';
export 'core/utils/reusable_components.dart';

// ===== البطاقات =====
export 'widgets/cards/app_card.dart';
export 'widgets/cards/app_completion_card.dart';
export 'widgets/cards/app_quote_card.dart';
export 'widgets/cards/athkar_card.dart';

// ===== الحوارات =====
export 'widgets/dialogs/app_info_dialog.dart';

// ===== التغذية الراجعة =====
export 'widgets/feedback/app_snackbar.dart';

// ===== التخطيط =====
export 'widgets/layout/app_bar.dart';

// ===== الحالات =====
export 'widgets/states/app_empty_state.dart';

// ===== تصدير الحزم المستخدمة =====
export 'package:flutter_staggered_animations/flutter_staggered_animations.dart'
    show
        AnimationConfiguration,
        AnimationLimiter,
        FadeInAnimation,
        SlideAnimation,
        ScaleAnimation,
        FlipAnimation;

// ===== دوال مساعدة سريعة =====
class ThemeUtils {
  ThemeUtils._();
  static ThemeData of(BuildContext context) => Theme.of(context);
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color primaryColor(BuildContext context) => Theme.of(context).primaryColor;
  static Color backgroundColor(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color textColor(BuildContext context) => AppColors.textPrimary(context);
  static Widget withTheme({ required Widget child, required ThemeData theme, }) {
    return Theme( data: theme, child: child, );
  }
}

// ===== مكونات شائعة الاستخدام =====
class QuickComponents {
  QuickComponents._();
  static Widget card({ required String title, String? subtitle, IconData? icon, VoidCallback? onTap, Key? key, }) {
    return app_card_widget.AppCard( key: key, title: title, subtitle: subtitle, leadingIcon: icon, onTap: onTap, );
  }
  static Widget emptyState({ required String message, IconData icon = Icons.inbox_outlined, Key? key, }) {
    return AppEmptyState( key: key, icon: icon, title: message, );
  }
  static Widget button({ required String text, required VoidCallback onPressed, bool isOutlined = false, Key? key, }) {
    return ThemedActionButton( key: key, text: text, onPressed: onPressed, isOutlined: isOutlined, );
  }
  static void showSuccess(BuildContext context, String message) {
    AppSnackBar.showSuccess(context: context, message: message);
  }
  static void showError(BuildContext context, String message) {
    AppSnackBar.showError(context: context, message: message);
  }
}

// ===== ثوابت مفيدة =====
class ThemeConstants {
  ThemeConstants._();
  static const Duration instant = AppAnimations.durationInstant;
  static const Duration fast = AppAnimations.durationFast;
  static const Duration normal = AppAnimations.durationNormal;
  static const Duration slow = AppAnimations.durationSlow;
  static const double spaceXS = AppDimens.space1;
  static const double spaceSM = AppDimens.space2;
  static const double spaceMD = AppDimens.space4;
  static const double spaceLG = AppDimens.space6;
  static const double spaceXL = AppDimens.space8;
  static const double iconSM = AppDimens.iconSm;
  static const double iconMD = AppDimens.iconMd;
  static const double iconLG = AppDimens.iconLg;
  static const double radiusSM = AppDimens.radiusSm;
  static const double radiusMD = AppDimens.radiusMd;
  static const double radiusLG = AppDimens.radiusLg;
  static const double radiusFull = AppDimens.radiusFull;
}