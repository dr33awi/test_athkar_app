// lib/app/themes/widgets/cards/app_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_animations.dart';

/// بطاقة عامة قابلة لإعادة الاستخدام في جميع أنحاء التطبيق
/// تدعم أنماط مختلفة: عادية، متدرجة، زجاجية
class AppCard extends StatefulWidget {
  // المحتوى الأساسي
  final String? title;
  final String? subtitle;
  final String? content;
  final Widget? child;
  
  // الأيقونات والصور
  final IconData? leadingIcon;
  final Widget? leading;
  final IconData? trailingIcon;
  final Widget? trailing;
  
  // الألوان والتصميم
  final Color? primaryColor;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final CardStyle cardStyle;
  final double? elevation;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  
  // التفاعلات
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectable;
  final bool isSelected;
  
  // ميزات إضافية
  final String? badge;
  final Color? badgeColor;
  final List<CardAction>? actions;
  final bool showShadow;
  final bool animate;
  final Duration? animationDuration;
  
  const AppCard({
    Key? key,
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
  }) : super(key: key);

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
        setState(() => _isPressed = true);
        _animationController.forward().then((_) {
          _animationController.reverse();
          setState(() => _isPressed = false);
        });
      }
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.primaryColor ?? AppColors.primary;
    
    Widget cardContent = _buildCardContent(context, isDark, primaryColor);
    
    if (widget.animate) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: cardContent,
          );
        },
      );
    }
    
    return cardContent;
  }

  Widget _buildCardContent(BuildContext context, bool isDark, Color primaryColor) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(
        horizontal: AppDimens.space4,
        vertical: AppDimens.space2,
      ),
      child: Material(
        elevation: widget.showShadow ? (widget.elevation ?? AppDimens.elevation4) : 0,
        shadowColor: primaryColor.withOpacity(AppColors.opacity20),
        borderRadius: BorderRadius.circular(
          widget.borderRadius ?? AppDimens.radiusLg,
        ),
        color: Colors.transparent,
        child: Container(
          decoration: _getCardDecoration(isDark, primaryColor),
          child: InkWell(
            onTap: widget.onTap != null ? _handleTap : null,
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(
              widget.borderRadius ?? AppDimens.radiusLg,
            ),
            child: Stack(
              children: [
                // المحتوى الرئيسي
                Padding(
                  padding: widget.padding ?? const EdgeInsets.all(AppDimens.space4),
                  child: _buildContent(context, isDark, primaryColor),
                ),
                
                // الشارة
                if (widget.badge != null)
                  Positioned(
                    top: AppDimens.space2,
                    left: AppDimens.space2,
                    child: _buildBadge(context),
                  ),
                
                // مؤشر التحديد
                if (widget.isSelectable && widget.isSelected)
                  Positioned(
                    top: AppDimens.space2,
                    right: AppDimens.space2,
                    child: Container(
                      width: AppDimens.iconMd,
                      height: AppDimens.iconMd,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
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

  BoxDecoration _getCardDecoration(bool isDark, Color primaryColor) {
    final borderRadius = BorderRadius.circular(
      widget.borderRadius ?? AppDimens.radiusLg,
    );
    
    switch (widget.cardStyle) {
      case CardStyle.gradient:
        return BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: widget.gradientColors ?? [
              primaryColor,
              primaryColor.darken(0.2),
            ],
          ),
        );
        
      case CardStyle.glassmorphism:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: (widget.backgroundColor ?? (isDark 
            ? AppColors.darkCard 
            : AppColors.lightCard)).withOpacity(AppColors.opacity70),
          border: Border.all(
            color: (isDark 
              ? Colors.white 
              : primaryColor).withOpacity(AppColors.opacity20),
            width: AppDimens.borderThin,
          ),
          backgroundBlendMode: BlendMode.overlay,
        );
        
      case CardStyle.outlined:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: widget.backgroundColor ?? (isDark 
            ? AppColors.darkCard 
            : AppColors.lightCard),
          border: Border.all(
            color: primaryColor.withOpacity(AppColors.opacity30),
            width: AppDimens.borderMedium,
          ),
        );
        
      case CardStyle.normal:
      default:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: widget.backgroundColor ?? (isDark 
            ? AppColors.darkCard 
            : AppColors.lightCard),
        );
    }
  }

  Widget _buildContent(BuildContext context, bool isDark, Color primaryColor) {
    if (widget.child != null) {
      return widget.child!;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // الرأس (العنوان والأيقونات)
        if (widget.title != null || widget.leading != null || widget.trailing != null)
          _buildHeader(context, isDark, primaryColor),
        
        // العنوان الفرعي
        if (widget.subtitle != null) ...[
          if (widget.title != null) const SizedBox(height: AppDimens.space1),
          Text(
            widget.subtitle!,
            style: AppTypography.body2.copyWith(
              color: _getTextColor(isDark, isSecondary: true),
            ),
          ),
        ],
        
        // المحتوى
        if (widget.content != null) ...[
          const SizedBox(height: AppDimens.space3),
          Text(
            widget.content!,
            style: AppTypography.body1.copyWith(
              color: _getTextColor(isDark),
              height: 1.6,
            ),
          ),
        ],
        
        // الإجراءات
        if (widget.actions != null && widget.actions!.isNotEmpty) ...[
          const SizedBox(height: AppDimens.space4),
          _buildActions(context, isDark, primaryColor),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color primaryColor) {
    return Row(
      children: [
        // الأيقونة أو العنصر الأمامي
        if (widget.leading != null)
          widget.leading!
        else if (widget.leadingIcon != null)
          Container(
            padding: const EdgeInsets.all(AppDimens.space2),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(AppColors.opacity10),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Icon(
              widget.leadingIcon,
              color: primaryColor,
              size: AppDimens.iconMd,
            ),
          ),
        
        if ((widget.leading != null || widget.leadingIcon != null) && widget.title != null)
          const SizedBox(width: AppDimens.space3),
        
        // العنوان
        if (widget.title != null)
          Expanded(
            child: Text(
              widget.title!,
              style: AppTypography.h5.copyWith(
                color: _getTextColor(isDark),
              ),
            ),
          ),
        
        // العنصر الخلفي
        if (widget.trailing != null)
          widget.trailing!
        else if (widget.trailingIcon != null)
          Icon(
            widget.trailingIcon,
            color: _getTextColor(isDark, isSecondary: true),
            size: AppDimens.iconMd,
          ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space2,
        vertical: AppDimens.space1,
      ),
      decoration: BoxDecoration(
        color: widget.badgeColor ?? AppColors.accent,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Text(
        widget.badge!,
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontWeight: AppTypography.semiBold,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark, Color primaryColor) {
    return Wrap(
      spacing: AppDimens.space2,
      runSpacing: AppDimens.space2,
      children: widget.actions!.map((action) {
        return _CardActionButton(
          action: action,
          primaryColor: primaryColor,
          isDark: isDark,
          isGradient: widget.cardStyle == CardStyle.gradient,
        );
      }).toList(),
    );
  }

  Color _getTextColor(bool isDark, {bool isSecondary = false}) {
    if (widget.cardStyle == CardStyle.gradient) {
      return Colors.white.withOpacity(isSecondary ? AppColors.opacity70 : 1.0);
    }
    
    return isSecondary
      ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
  }
}

/// أنماط البطاقة المتاحة
enum CardStyle {
  normal,
  gradient,
  glassmorphism,
  outlined,
}

/// إجراء يمكن تنفيذه على البطاقة
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

/// زر الإجراء الخاص بالبطاقة
class _CardActionButton extends StatelessWidget {
  final CardAction action;
  final Color primaryColor;
  final bool isDark;
  final bool isGradient;
  
  const _CardActionButton({
    required this.action,
    required this.primaryColor,
    required this.isDark,
    required this.isGradient,
  });
  
  @override
  Widget build(BuildContext context) {
    final buttonColor = action.color ?? primaryColor;
    final textColor = isGradient 
      ? Colors.white 
      : (isDark ? AppColors.darkTextPrimary : buttonColor);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          action.onPressed();
        },
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space3,
            vertical: AppDimens.space2,
          ),
          decoration: BoxDecoration(
            color: isGradient 
              ? Colors.white.withOpacity(AppColors.opacity20)
              : buttonColor.withOpacity(AppColors.opacity10),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(
              color: isGradient
                ? Colors.white.withOpacity(AppColors.opacity30)
                : buttonColor.withOpacity(AppColors.opacity30),
              width: AppDimens.borderThin,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.icon,
                color: textColor,
                size: AppDimens.iconSm,
              ),
              const SizedBox(width: AppDimens.space2),
              Text(
                action.label,
                style: AppTypography.label2.copyWith(
                  color: textColor,
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

/// Extension لتسهيل إنشاء ألوان داكنة
extension ColorExtension on Color {
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}