// lib/app/themes/core/utils/reusable_components.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme_constants.dart';
import '../../text_styles.dart';
import '../theme_extensions.dart';

// ملاحظة: تم إزالة جميع الثوابت المحلية واستخدام ThemeConstants مباشرة

class ThemedSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onActionPressed;
  final IconData? actionIcon;
  final String? actionText;

  const ThemedSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.onActionPressed,
    this.actionIcon,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.space2,
        vertical: ThemeConstants.space4,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(ThemeConstants.space2),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: ThemeConstants.opacity10),
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
              ),
              child: Icon(
                icon,
                color: theme.primaryColor,
                size: ThemeConstants.iconMd,
              ),
            ),
            const SizedBox(width: ThemeConstants.space3),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge,
            ),
          ),
          if (onActionPressed != null)
            TextButton.icon(
              icon: Icon(
                actionIcon ?? Icons.arrow_forward_ios_rounded,
                size: ThemeConstants.iconSm,
              ),
              label: Text(actionText ?? ''),
              onPressed: () {
                HapticFeedback.lightImpact();
                onActionPressed!();
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.secondary,
                textStyle: AppTextStyles.label1.copyWith(
                  fontWeight: ThemeConstants.semiBold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ThemedInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? trailing;

  const ThemedInfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.primaryColor;

    BorderRadius cardBorderRadius = BorderRadius.circular(ThemeConstants.radiusMd);
    final cardShape = theme.cardTheme.shape;
    if (cardShape is RoundedRectangleBorder) {
      final br = cardShape.borderRadius;
      if (br is BorderRadius) {
        cardBorderRadius = br;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.space4,
        vertical: ThemeConstants.space2,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: cardBorderRadius,
        child: Padding(
          padding: const EdgeInsets.all(ThemeConstants.space4),
          child: Row(
            children: [
              Container(
                width: ThemeConstants.avatarLg,
                height: ThemeConstants.avatarLg,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: ThemeConstants.opacity10),
                  borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                ),
                child: Icon(
                  icon,
                  color: effectiveIconColor,
                  size: ThemeConstants.iconLg,
                ),
              ),
              const SizedBox(width: ThemeConstants.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: ThemeConstants.semiBold,
                      ),
                    ),
                    const SizedBox(height: ThemeConstants.space1),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: ThemeConstants.opacity70) ?? ThemeConstants.lightTextSecondary.withValues(alpha: ThemeConstants.opacity70),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6) ?? ThemeConstants.lightTextSecondary.withValues(alpha: 0.6),
                  size: ThemeConstants.iconSm,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// باقي المكونات بنفس الطريقة - استخدام ThemeConstants بدلاً من الثوابت المحلية

class ThemedCircleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  const ThemedCircleIcon({
    super.key,
    required this.icon,
    this.size = ThemeConstants.avatarMd,  // استخدم من ThemeConstants
    this.backgroundColor,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor.withValues(alpha: ThemeConstants.opacity10);
    final fgColor = iconColor ?? theme.primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: fgColor,
          size: size * 0.55,
        ),
      ),
    );
  }
}

// تابع باقي المكونات...