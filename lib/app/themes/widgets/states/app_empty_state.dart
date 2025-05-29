// lib/app/themes/widgets/states/app_empty_state.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_animations.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final double? iconSize;
  final Widget? action;
  final Widget? customIcon;
  final EdgeInsetsGeometry? padding;
  final bool animate;
  final CrossAxisAlignment alignment;

  const AppEmptyState({
    super.key, // Applied super.key
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.iconSize,
    this.action,
    this.customIcon,
    this.padding,
    this.animate = true,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context); // Removed as it was unused
    final defaultIconColor = this.iconColor ?? AppColors.textSecondary(context).withAlpha((AppColors.opacity50 * 255).round()); // Corrected withAlpha

    Widget contentWidget = Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppDimens.space5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            customIcon ?? Icon(
              icon,
              size: iconSize ?? AppDimens.icon2xl * 1.5,
              color: defaultIconColor,
            ),
            const SizedBox(height: AppDimens.space4),
            Text(
              title,
              style: AppTypography.h5.copyWith(
                color: iconColor ?? AppColors.textPrimary(context), // Removed unnecessary 'this.'
              ),
              textAlign: alignment == CrossAxisAlignment.center
                ? TextAlign.center
                : TextAlign.start,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimens.space2),
              Text(
                subtitle!,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary(context),
                ),
                textAlign: alignment == CrossAxisAlignment.center
                  ? TextAlign.center
                  : TextAlign.start,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppDimens.space5),
              action!,
            ],
          ],
        ),
      ),
    );

    if (animate) {
      return AnimationConfiguration.synchronized(
        duration: AppAnimations.durationNormal,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleAnimation(
              scale: 0.5,
              curve: AppAnimations.curveBounce,
              duration: AppAnimations.durationSlow,
              child: FadeInAnimation(
                child: customIcon ?? Icon(
                  icon,
                  size: iconSize ?? AppDimens.icon2xl * 1.5,
                  color: defaultIconColor,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space4),
            SlideAnimation(
              verticalOffset: 20,
              curve: AppAnimations.curveDefault,
              delay: const Duration(milliseconds: 100),
              child: FadeInAnimation(
                child: Text(
                  title,
                  style: AppTypography.h5.copyWith(
                    color: iconColor ?? AppColors.textPrimary(context), // Removed unnecessary 'this.'
                  ),
                  textAlign: alignment == CrossAxisAlignment.center
                    ? TextAlign.center
                    : TextAlign.start,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimens.space2),
              SlideAnimation(
                verticalOffset: 20,
                curve: AppAnimations.curveDefault,
                delay: const Duration(milliseconds: 200),
                child: FadeInAnimation(
                  child: Text(
                    subtitle!,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                    textAlign: alignment == CrossAxisAlignment.center
                      ? TextAlign.center
                      : TextAlign.start,
                  ),
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppDimens.space5),
              SlideAnimation(
                verticalOffset: 20,
                curve: AppAnimations.curveDefault,
                delay: const Duration(milliseconds: 300),
                child: FadeInAnimation(
                  child: action!,
                ),
              ),
            ],
          ],
        ),
      );
    }
    return contentWidget;
  }

  static Widget list({
    String title = 'لا توجد عناصر',
    String? subtitle,
    Widget? action,
  }) {
    if (action == null && subtitle == null) {
      return AppEmptyState(
        icon: Icons.inbox_outlined,
        title: title,
      );
    }
    return AppEmptyState(
      icon: Icons.inbox_outlined,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  static Widget search({
    String title = 'لا توجد نتائج',
    String? subtitle = 'جرب البحث بكلمات مختلفة',
    Widget? action,
  }) {
    if (action == null) {
       return AppEmptyState(
        icon: Icons.search_off,
        title: title,
        subtitle: subtitle, // Default string literals are const compatible
      );
    }
    return AppEmptyState(
      icon: Icons.search_off,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  static Widget favorites({
    String title = 'لا توجد مفضلات',
    String? subtitle = 'أضف عناصر إلى المفضلة لتظهر هنا',
    Widget? action,
  }) {
    if (action == null) {
      return AppEmptyState(
        icon: Icons.favorite_border,
        title: title,
        subtitle: subtitle,
      );
    }
    return AppEmptyState(
      icon: Icons.favorite_border,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  static Widget noConnection({ // Line 166 for error
    String title = 'لا يوجد اتصال',
    String? subtitle = 'تحقق من اتصالك بالإنترنت',
    Widget? action,
  }) {
    if (action == null) {
      // AppColors.error is const. Defaults for title & subtitle are const.
      // This should be const.
      return AppEmptyState(
        icon: Icons.wifi_off,
        title: title,
        subtitle: subtitle,
        iconColor: AppColors.error,
      );
    }
    return AppEmptyState(
      icon: Icons.wifi_off,
      title: title,
      subtitle: subtitle,
      iconColor: AppColors.error,
      action: action,
    );
  }

  static Widget error({ // Line 232 for error (approx.)
    String title = 'حدث خطأ',
    String? subtitle,
    Widget? action,
  }) {
    if (action == null && subtitle == null) {
       return AppEmptyState(
        icon: Icons.error_outline,
        title: title,
        iconColor: AppColors.error,
      );
    }
    return AppEmptyState(
      icon: Icons.error_outline,
      title: title,
      subtitle: subtitle,
      iconColor: AppColors.error,
      action: action,
    );
  }
}