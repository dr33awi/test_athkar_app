// lib/app/themes/theme_exports.dart
/// ملف تصدير موحد لجميع مكونات نظام الثيم
/// يسهل استيراد جميع المكونات من مكان واحد
library app_theme;

// ===== الثيم الأساسي =====
export 'app_theme.dart';

// ===== الثوابت الموحدة =====
export 'theme_constants.dart';

// ===== Extensions =====
export 'core/theme_extensions.dart';

// ===== البطاقات =====
export 'widgets/cards/app_card.dart';
export 'widgets/cards/athkar_card.dart';

// ===== الحوارات =====
export 'widgets/dialogs/app_info_dialog.dart';

// ===== التغذية الراجعة =====
export 'widgets/feedback/app_snackbar.dart';

// ===== التخطيط =====
export 'widgets/layout/app_bar.dart';

// ===== الحالات =====
export 'widgets/states/app_empty_state.dart';

// ===== المكونات الأساسية =====
export 'widgets/core/app_button.dart';
export 'widgets/core/app_text_field.dart';
export 'widgets/core/app_loading.dart';

// ===== تصدير حزم الحركات =====
export 'package:flutter_staggered_animations/flutter_staggered_animations.dart'
    show
        AnimationConfiguration,
        AnimationLimiter,
        FadeInAnimation,
        SlideAnimation,
        ScaleAnimation,
        FlipAnimation;