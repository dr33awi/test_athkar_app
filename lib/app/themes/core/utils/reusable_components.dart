// lib/app/themes/core/utils/reusable_components.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';
import '../theme_extensions.dart';

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
        horizontal: AppDimens.space2,
        vertical: AppDimens.space4,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimens.space2),
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha((AppColors.opacity10 * 255).round()),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Icon(
                icon,
                color: theme.primaryColor,
                size: AppDimens.iconMd,
              ),
            ),
            const SizedBox(width: AppDimens.space3),
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
                size: AppDimens.iconSm,
              ),
              label: Text(actionText ?? ''),
              onPressed: () {
                HapticFeedback.lightImpact();
                onActionPressed!();
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.secondary,
                textStyle: AppTypography.label1.copyWith(
                  fontWeight: AppTypography.semiBold,
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

    BorderRadius cardBorderRadius = BorderRadius.circular(AppDimens.radiusMd);
    final cardShape = theme.cardTheme.shape;
    if (cardShape is RoundedRectangleBorder) {
      final br = cardShape.borderRadius;
      if (br is BorderRadius) {
        cardBorderRadius = br;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.space4,
        vertical: AppDimens.space2,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: cardBorderRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space4),
          child: Row(
            children: [
              Container(
                width: AppDimens.avatarLg,
                height: AppDimens.avatarLg,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withAlpha((AppColors.opacity10 * 255).round()),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Icon(
                  icon,
                  color: effectiveIconColor,
                  size: AppDimens.iconLg,
                ),
              ),
              const SizedBox(width: AppDimens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    const SizedBox(height: AppDimens.space1),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: (theme.textTheme.bodySmall?.color ?? AppColors.lightTextSecondary).withAlpha((AppColors.opacity70 * 255).round()),
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
                  color: (theme.textTheme.bodySmall?.color ?? AppColors.lightTextSecondary).withAlpha((0.6 * 255).round()),
                  size: AppDimens.iconSm,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThemedActionButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final ButtonStyle? style;

  const ThemedActionButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color progressIndicatorColor;

    final currentButtonForegroundColor = style?.foregroundColor?.resolve({}) ?? 
                                        (isOutlined 
                                            ? theme.outlinedButtonTheme.style?.foregroundColor?.resolve({}) 
                                            : theme.elevatedButtonTheme.style?.foregroundColor?.resolve({}));

    if (isOutlined) {
      progressIndicatorColor = foregroundColor ?? currentButtonForegroundColor ?? theme.colorScheme.primary;
    } else {
      progressIndicatorColor = foregroundColor ?? currentButtonForegroundColor ?? theme.colorScheme.onPrimary;
    }

    final buttonChild = isLoading
        ? SizedBox(
            width: AppDimens.iconMd,
            height: AppDimens.iconMd,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(progressIndicatorColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppDimens.iconSm),
                const SizedBox(width: AppDimens.space2),
              ],
              Text(text, style: AppTypography.buttonSmall),
            ],
          );

    ButtonStyle? baseStyle = isOutlined
        ? theme.outlinedButtonTheme.style
        : theme.elevatedButtonTheme.style;

    ButtonStyle? effectiveStyle = style ?? baseStyle;
    
    if (backgroundColor != null || foregroundColor != null) {
        effectiveStyle = effectiveStyle?.copyWith(
        backgroundColor: WidgetStateProperty.all(backgroundColor),
        foregroundColor: WidgetStateProperty.all(foregroundColor),
      );
    }
    
    final Size? currentMinimumSize = effectiveStyle?.minimumSize?.resolve({});
    if (isFullWidth) {
      if (currentMinimumSize == null || currentMinimumSize.width != double.infinity) {
        effectiveStyle = effectiveStyle?.copyWith(
          minimumSize: WidgetStateProperty.all(Size(double.infinity, currentMinimumSize?.height ?? AppDimens.buttonHeight))
        );
      }
    }


    final Widget button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading || onPressed == null ? null : onPressed,
            style: effectiveStyle,
            child: buttonChild,
          )
        : ElevatedButton(
            onPressed: isLoading || onPressed == null ? null : onPressed,
            style: effectiveStyle,
            child: buttonChild,
          );
    
    // This outer SizedBox might be redundant if minimumSize is correctly handled in the style
    final resolvedMinSize = effectiveStyle?.minimumSize?.resolve({});
    if (isFullWidth && (resolvedMinSize == null || resolvedMinSize.width != double.infinity)) {
       return SizedBox(
        width: double.infinity,
        height: resolvedMinSize?.height ?? AppDimens.buttonHeight,
        child: button,
      );
    }
    return button;
  }
}

class ThemedListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? tileColor;
  final EdgeInsetsGeometry? contentPadding;

  const ThemedListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.tileColor,
    this.contentPadding,
  }) : assert(icon == null || leading == null, 'Cannot provide both icon and leading.');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.primaryColor;

    Widget? resolvedLeading = leading;
    if (icon != null) {
      resolvedLeading = CircleAvatar(
        backgroundColor: effectiveIconColor.withAlpha((AppColors.opacity10 * 255).round()),
        foregroundColor: effectiveIconColor,
        child: Icon(icon),
      );
    }

    return ListTile(
      leading: resolvedLeading,
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: subtitle != null ? Text(subtitle!, style: theme.textTheme.bodyMedium) : null,
      trailing: trailing ?? (onTap != null ? Icon(Icons.arrow_forward_ios_rounded, size: AppDimens.iconSm, color: theme.dividerTheme.color) : null),
      onTap: onTap,
      tileColor: tileColor,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: AppDimens.space4, vertical: AppDimens.space2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

class ThemedLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const ThemedLoadingIndicator({
    super.key,
    this.message,
    this.size = AppDimens.iconXl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                color: theme.progressIndicatorTheme.color ?? theme.primaryColor,
                strokeWidth: 3.5,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppDimens.space4),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: (theme.textTheme.bodySmall?.color ?? AppColors.lightTextSecondary).withAlpha((AppColors.opacity70*255).round()),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ThemedCircleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  const ThemedCircleIcon({
    super.key,
    required this.icon,
    this.size = AppDimens.avatarMd,
    this.backgroundColor,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor.withAlpha((AppColors.opacity10 * 255).round());
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

class ThemedDividerWithText extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;

  const ThemedDividerWithText({
    super.key,
    required this.text,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color effectiveDividerColor = theme.dividerTheme.color!; // Assert non-null

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space4),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space3),
            child: Text(
              text,
              style: textStyle ?? theme.textTheme.bodySmall?.copyWith(color: effectiveDividerColor.withAlpha((0.8 * 255).round())),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class ThemedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const ThemedStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.primaryColor;
    
    BorderRadius cardBorderRadius = BorderRadius.circular(AppDimens.radiusMd);
    final cardShape = theme.cardTheme.shape;
    if (cardShape is RoundedRectangleBorder) {
      final br = cardShape.borderRadius;
      if (br is BorderRadius) {
        cardBorderRadius = br;
      }
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: cardBorderRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    color: effectiveColor,
                    size: AppDimens.iconLg,
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: AppDimens.iconSm,
                      color: (theme.textTheme.bodySmall?.color ?? AppColors.lightTextSecondary).withAlpha((0.6 * 255).round()),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.space2),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: effectiveColor,
                  fontWeight: AppTypography.bold,
                ),
              ),
              const SizedBox(height: AppDimens.space1),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                   color: (theme.textTheme.bodySmall?.color ?? AppColors.lightTextSecondary).withAlpha((0.8 * 255).round())
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThemedEmptyMessage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const ThemedEmptyMessage({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color surfaceContainerHighestColor = theme.colorScheme.surfaceContainerHighest ?? theme.cardTheme.color ?? theme.colorScheme.surface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ThemedCircleIcon(
              icon: icon,
              size: AppDimens.icon2xl * 1.8,
              backgroundColor: surfaceContainerHighestColor.withAlpha((AppColors.opacity50 * 255).round()),
              iconColor: (theme.textTheme.bodySmall?.color ?? AppColors.lightTextSecondary).withAlpha((0.6 * 255).round()),
            ),
            const SizedBox(height: AppDimens.space5),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimens.space3),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: (theme.textTheme.bodySmall?.color ?? AppColors.lightTextSecondary).withAlpha((0.8 * 255).round()),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppDimens.space6),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class ThemedLinearProgress extends StatelessWidget {
  final double value;
  final double height;
  final Color? backgroundColor;
  final Color? valueColor;
  final String? label;

  const ThemedLinearProgress({
    super.key,
    required this.value,
    this.height = AppDimens.space2,
    this.backgroundColor,
    this.valueColor,
    this.label,
  }) : assert(value >= 0.0 && value <= 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color effectiveDividerColor = theme.dividerTheme.color!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: theme.textTheme.labelMedium,
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: AppTypography.semiBold),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space1),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            backgroundColor: backgroundColor ?? effectiveDividerColor.withAlpha((AppColors.opacity50 * 255).round()),
            valueColor: AlwaysStoppedAnimation<Color>(
              valueColor ?? theme.progressIndicatorTheme.color ?? theme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

class ThemedAlertCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;
  final Color? textColor;
  final VoidCallback? onClose;

  const ThemedAlertCard({
    super.key,
    required this.message,
    required this.icon,
    this.color,
    this.textColor,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alertColor = color ?? AppColors.info;
    final effectiveTextColor = textColor ?? alertColor.darken(0.2);

    return Container(
      padding: const EdgeInsets.all(AppDimens.space3),
      decoration: BoxDecoration(
        color: alertColor.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: alertColor.withAlpha((0.4 * 255).round()),
          width: AppDimens.borderThin,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: alertColor,
            size: AppDimens.iconMd,
          ),
          const SizedBox(width: AppDimens.space3),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: effectiveTextColor),
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: (theme.textTheme.bodySmall?.color ?? AppColors.lightTextSecondary).withAlpha((0.7 * 255).round()),
                size: AppDimens.iconSm,
              ),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
        ],
      ),
    );
  }
}