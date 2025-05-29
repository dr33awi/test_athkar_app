// lib/app/themes/widgets/states/app_empty_state.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_animations.dart';

/// مكون عام لعرض الحالات الفارغة
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
    Key? key,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultIconColor = iconColor ?? 
        AppColors.textSecondary(context).withOpacity(AppColors.opacity50);
    
    Widget content = Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppDimens.space5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            // الأيقونة
            customIcon ?? Icon(
              icon,
              size: iconSize ?? AppDimens.icon2xl * 1.5,
              color: defaultIconColor,
            ),
            
            const SizedBox(height: AppDimens.space4),
            
            // العنوان
            Text(
              title,
              style: AppTypography.h5.copyWith(
                color: iconColor ?? AppColors.textPrimary(context),
              ),
              textAlign: alignment == CrossAxisAlignment.center 
                ? TextAlign.center 
                : TextAlign.start,
            ),
            
            // العنوان الفرعي
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
            
            // زر الإجراء
            if (action != null) ...[
              const SizedBox(height: AppDimens.space5),
              action!,
            ],
          ],
        ),
      ),
    );
    
    if (animate) {
      return AppAnimations.bounceIn(
        child: content,
        duration: AppAnimations.durationNormal,
      );
    }
    
    return content;
  }

  /// حالة فارغة للقوائم
  static Widget list({
    String title = 'لا توجد عناصر',
    String? subtitle,
    Widget? action,
  }) {
    return AppEmptyState(
      icon: Icons.inbox_outlined,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  /// حالة فارغة للبحث
  static Widget search({
    String title = 'لا توجد نتائج',
    String? subtitle = 'جرب البحث بكلمات مختلفة',
    Widget? action,
  }) {
    return AppEmptyState(
      icon: Icons.search_off,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  /// حالة فارغة للمفضلة
  static Widget favorites({
    String title = 'لا توجد مفضلات',
    String? subtitle = 'أضف عناصر إلى المفضلة لتظهر هنا',
    Widget? action,
  }) {
    return AppEmptyState(
      icon: Icons.favorite_border,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  /// حالة عدم وجود اتصال
  static Widget noConnection({
    String title = 'لا يوجد اتصال',
    String? subtitle = 'تحقق من اتصالك بالإنترنت',
    Widget? action,
  }) {
    return AppEmptyState(
      icon: Icons.wifi_off,
      title: title,
      subtitle: subtitle,
      iconColor: AppColors.error,
      action: action,
    );
  }

  /// حالة خطأ عامة
  static Widget error({
    String title = 'حدث خطأ',
    String? subtitle,
    Widget? action,
  }) {
    return AppEmptyState(
      icon: Icons.error_outline,
      title: title,
      subtitle: subtitle,
      iconColor: AppColors.error,
      action: action,
    );
  }
}