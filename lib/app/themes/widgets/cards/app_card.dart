// lib/app/themes/widgets/cards/app_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_animations.dart';
import '../../core/theme_extensions.dart';

/// بطاقة عامة قابلة لإعادة الاستخدام في جميع أنحاء التطبيق
/// تدعم أنماط مختلفة: عادية، متدرجة، زجاجية
class AppCard extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final String? content;
  final Widget? child;
  final IconData? leadingIcon;
  final Widget? leading;
  final IconData? trailingIcon;
  final Widget? trailing;
  final Color? primaryColor;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final CardStyle cardStyle;
  final double? elevation;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectable;
  final bool isSelected;
  final String? badge;
  final Color? badgeColor;
  final List<CardAction>? actions;
  final bool showShadow;
  final bool animate;
  final Duration? animationDuration;

  const AppCard({
    super.key,
    this.title,
    this.subtitle,
    this.content,
    this.child,
    this.leadingIcon,
    this.leading,
    this.trailingIcon,
    this.trailing,
    this.primaryColor,
    this.backgroundColor,
    this.gradientColors,
    this.cardStyle = CardStyle.normal,
    this.elevation,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.isSelectable = false,
    this.isSelected = false,
    this.badge,
    this.badgeColor,
    this.actions,
    this.showShadow = true,
    this.animate = true,
    this.animationDuration,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration ?? AppAnimations.durationFast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppAnimations.curveDefault,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      HapticFeedback.lightImpact();
      if (widget.animate) {
        if (mounted) {
          setState(() => _isPressed = true);
        }
        _animationController.forward().then((_) {
          if (mounted) {
            _animationController.reverse().then((value) {
              if (mounted) {
                setState(() => _isPressed = false);
              }
            });
          }
        });
      }
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardPrimaryColor = widget.primaryColor ?? theme.primaryColor;

    Widget cardContentWidget = _buildCardContent(context, isDark, cardPrimaryColor);

    if (widget.animate && widget.onTap != null) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: child,
          );
        },
        child: cardContentWidget,
      );
    }
    return cardContentWidget;
  }
  
  BorderRadius _getEffectiveBorderRadius(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.borderRadius != null) {
        return BorderRadius.circular(widget.borderRadius!);
    }
    if (theme.cardTheme.shape is RoundedRectangleBorder) {
        final shape = theme.cardTheme.shape as RoundedRectangleBorder;
        if (shape.borderRadius is BorderRadius) {
            return shape.borderRadius as BorderRadius;
        }
    }
    return BorderRadius.circular(AppDimens.radiusLg);
  }

  Widget _buildCardContent(BuildContext context, bool isDark, Color cardPrimaryColor) {
    final theme = Theme.of(context);
    final effectiveBorderRadiusValue = _getEffectiveBorderRadius(context);

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(
        horizontal: AppDimens.space4,
        vertical: AppDimens.space2,
      ),
      child: Material(
        elevation: widget.showShadow ? (widget.elevation ?? theme.cardTheme.elevation ?? AppDimens.elevation4) : 0,
        shadowColor: widget.showShadow ? cardPrimaryColor.withValues(alpha: AppColors.opacity20) : Colors.transparent,
        borderRadius: effectiveBorderRadiusValue,
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: _getCardDecoration(context, isDark, cardPrimaryColor, effectiveBorderRadiusValue),
          child: InkWell(
            onTap: widget.onTap != null ? _handleTap : null,
            onLongPress: widget.onLongPress,
            borderRadius: effectiveBorderRadiusValue,
            child: Stack(
              children: [
                Padding(
                  padding: widget.padding ?? const EdgeInsets.all(AppDimens.space4),
                  child: _buildContentStructure(context, isDark, cardPrimaryColor),
                ),
                if (widget.badge != null)
                  Positioned(
                    top: AppDimens.space2,
                    left: AppDimens.space2,
                    child: _buildBadgeWidget(context, cardPrimaryColor),
                  ),
                if (widget.isSelectable && widget.isSelected)
                  Positioned(
                    top: AppDimens.space2,
                    right: AppDimens.space2,
                    child: Container(
                      padding: const EdgeInsets.all(AppDimens.space1 / 2),
                      decoration: BoxDecoration(
                        color: cardPrimaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: _getCardBackgroundColor(context, isDark), width: 1.5)
                      ),
                      child: Icon(
                        Icons.check,
                        color: _getTextColor(context, isDark, cardPrimaryColor, isSecondary: false),
                        size: AppDimens.iconSm,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCardBackgroundColor(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return widget.backgroundColor ?? theme.cardTheme.color ?? (isDark
            ? AppColors.darkCard
            : AppColors.lightCard);
  }

  BoxDecoration _getCardDecoration(BuildContext context, bool isDark, Color cardPrimaryColor, BorderRadius borderRadius) {
    final cardBgColor = _getCardBackgroundColor(context, isDark);

    switch (widget.cardStyle) {
      case CardStyle.gradient:
        return BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: widget.gradientColors ?? [
              cardPrimaryColor,
              cardPrimaryColor.darken(0.2),
            ],
          ),
        );
      case CardStyle.glassmorphism:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: cardBgColor.withValues(alpha: AppColors.opacity70),
          border: Border.all(
            color: (isDark ? Colors.white : cardPrimaryColor).withValues(alpha: AppColors.opacity20),
            width: AppDimens.borderThin,
          ),
        );
      case CardStyle.outlined:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: cardBgColor,
          border: Border.all(
            color: cardPrimaryColor.withValues(alpha: AppColors.opacity30),
            width: AppDimens.borderMedium,
          ),
        );
      case CardStyle.normal:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: cardBgColor,
        );
    }
  }

  Widget _buildContentStructure(BuildContext context, bool isDark, Color cardPrimaryColor) {
    if (widget.child != null) {
      return widget.child!;
    }
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null || widget.leading != null || widget.trailing != null)
          _buildHeaderWidget(context, isDark, cardPrimaryColor),
        if (widget.subtitle != null) ...[
          if (widget.title != null) const SizedBox(height: AppDimens.space1),
          Text(
            widget.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _getTextColor(context, isDark, cardPrimaryColor, isSecondary: true),
            ),
          ),
        ],
        if (widget.content != null) ...[
          const SizedBox(height: AppDimens.space3),
          Text(
            widget.content!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: _getTextColor(context, isDark, cardPrimaryColor),
              height: 1.6,
            ),
          ),
        ],
        if (widget.actions != null && widget.actions!.isNotEmpty) ...[
          const SizedBox(height: AppDimens.space4),
          _buildActionsWidget(context, isDark, cardPrimaryColor),
        ],
      ],
    );
  }

  Widget _buildHeaderWidget(BuildContext context, bool isDark, Color cardPrimaryColor) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (widget.leading != null)
          widget.leading!
        else if (widget.leadingIcon != null)
          Container(
            padding: const EdgeInsets.all(AppDimens.space2),
            decoration: BoxDecoration(
              color: cardPrimaryColor.withValues(alpha: AppColors.opacity10),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Icon(
              widget.leadingIcon,
              color: cardPrimaryColor,
              size: AppDimens.iconMd,
            ),
          ),
        if ((widget.leading != null || widget.leadingIcon != null) && widget.title != null)
          const SizedBox(width: AppDimens.space3),
        if (widget.title != null)
          Expanded(
            child: Text(
              widget.title!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: _getTextColor(context, isDark, cardPrimaryColor),
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        if (widget.trailing != null)
          widget.trailing!
        else if (widget.trailingIcon != null)
          Icon(
            widget.trailingIcon,
            color: _getTextColor(context, isDark, cardPrimaryColor, isSecondary: true),
            size: AppDimens.iconMd,
          ),
      ],
    );
  }

  Widget _buildBadgeWidget(BuildContext context, Color cardPrimaryColor) {
    final theme = Theme.of(context);
    final badgeBgColor = widget.badgeColor ?? theme.colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space2,
        vertical: AppDimens.space1,
      ),
      decoration: BoxDecoration(
        color: badgeBgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Text(
        widget.badge!,
        style: AppTypography.caption.copyWith(
          color: ThemeData.estimateBrightnessForColor(badgeBgColor) == Brightness.dark
                 ? Colors.white
                 : Colors.black,
          fontWeight: AppTypography.semiBold,
        ),
      ),
    );
  }

  Widget _buildActionsWidget(BuildContext context, bool isDark, Color cardPrimaryColor) {
    return Wrap(
      spacing: AppDimens.space2,
      runSpacing: AppDimens.space2,
      children: widget.actions!.map((action) {
        return _CardActionButton(
          action: action,
          cardPrimaryColor: cardPrimaryColor,
          isDark: isDark,
          isGradientCard: widget.cardStyle == CardStyle.gradient,
          cardBackgroundColor: _getCardBackgroundColor(context, isDark),
        );
      }).toList(),
    );
  }

  Color _getTextColor(BuildContext context, bool isDark, Color cardPrimaryColor, {bool isSecondary = false}) {
    final theme = Theme.of(context);
    if (widget.cardStyle == CardStyle.gradient) {
      return Colors.white.withValues(alpha: isSecondary ? AppColors.opacity70 : 1.0);
    }
    
    Color? customBgColor = widget.backgroundColor;
    if (customBgColor != null) {
         return ThemeData.estimateBrightnessForColor(customBgColor) == Brightness.dark
             ? (isSecondary ? AppColors.darkTextSecondary : AppColors.darkTextPrimary)
             : (isSecondary ? AppColors.lightTextSecondary : AppColors.lightTextPrimary);
    }

    return isSecondary
      ? (theme.textTheme.bodyMedium?.color ?? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))
      : (theme.textTheme.bodyLarge?.color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary));
  }
}

enum CardStyle {
  normal,
  gradient,
  glassmorphism,
  outlined,
}

class CardAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const CardAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });
}

class _CardActionButton extends StatelessWidget {
  final CardAction action;
  final Color cardPrimaryColor;
  final bool isDark;
  final bool isGradientCard;
  final Color cardBackgroundColor;

  const _CardActionButton({
    required this.action,
    required this.cardPrimaryColor,
    required this.isDark,
    required this.isGradientCard,
    required this.cardBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = action.color ?? cardPrimaryColor;
    final Color effectiveTextColor;

    if (isGradientCard) {
      effectiveTextColor = Colors.white;
    } else {
      bool isButtonBgLight = ThemeData.estimateBrightnessForColor(buttonColor.withValues(alpha: AppColors.opacity10)) == Brightness.light;
      if (isDark) {
        effectiveTextColor = isButtonBgLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary;
      } else {
        effectiveTextColor = action.color != null
            ? (ThemeData.estimateBrightnessForColor(action.color!) == Brightness.dark ? Colors.white : Colors.black)
            : cardPrimaryColor;
      }
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          action.onPressed();
        },
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        splashColor: buttonColor.withValues(alpha: AppColors.opacity20),
        highlightColor: buttonColor.withValues(alpha: AppColors.opacity10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space3,
            vertical: AppDimens.space2,
          ),
          decoration: BoxDecoration(
            color: isGradientCard
                ? Colors.white.withValues(alpha: AppColors.opacity20)
                : buttonColor.withValues(alpha: AppColors.opacity10),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(
              color: isGradientCard
                  ? Colors.white.withValues(alpha: AppColors.opacity30)
                  : buttonColor.withValues(alpha: AppColors.opacity30),
              width: AppDimens.borderThin,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.icon,
                color: effectiveTextColor,
                size: AppDimens.iconSm,
              ),
              const SizedBox(width: AppDimens.space2),
              Text(
                action.label,
                style: AppTypography.label2.copyWith(
                  color: effectiveTextColor,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}