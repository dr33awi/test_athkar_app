// lib/app/themes/components/unified_action_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../app/themes/theme_constants.dart';
import '../../../app/themes/app_theme.dart';

/// زر إجراء موحد يدعم أنماط متعددة
/// يجمع بين IconActionButton و CircularActionButton في مكون واحد
class ActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;
  final UnifiedButtonStyle style;
  
  // خصائص إضافية حسب النمط
  final bool showBorder;
  final double borderOpacity;
  final bool showShadow;
  final bool enableBlur;

  const ActionButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 48,
    this.tooltip,
    this.style = UnifiedButtonStyle.circular,
    this.showBorder = true,
    this.borderOpacity = 0.2,
    this.showShadow = true,
    this.enableBlur = false,
  }) : super(key: key);

  // Factory constructors للاستخدام السهل
  factory ActionButton.glass({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    double size = 40,
    String? tooltip,
  }) {
    return ActionButton(
      icon: icon,
      onPressed: onPressed,
      color: color,
      size: size,
      tooltip: tooltip,
      style: UnifiedButtonStyle.glass,
      enableBlur: true,
      showShadow: false,
    );
  }

  factory ActionButton.circular({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    double size = 48,
    String? tooltip,
  }) {
    return ActionButton(
      icon: icon,
      onPressed: onPressed,
      color: color,
      size: size,
      tooltip: tooltip,
      style: UnifiedButtonStyle.circular,
      showShadow: true,
      showBorder: false,
    );
  }

  @override
  State<ActionButton> createState() => _UnifiedActionButtonState();
}

enum UnifiedButtonStyle { glass, circular, flat }

class _UnifiedActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onPressed();
    
    if (mounted) {
      _animationController.forward().then((_) {
        if (mounted) {
          _animationController.reverse();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // حساب الألوان الفعالة
    final effectiveColor = widget.color ?? AppTheme.getPrimaryColor(context);
    final effectiveBackgroundColor = widget.backgroundColor ?? _getDefaultBackground(isDark);
    
    Widget buttonContent = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _buildButtonContent(context, effectiveColor, effectiveBackgroundColor),
        );
      },
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: buttonContent,
      );
    }

    return buttonContent;
  }

  Widget _buildButtonContent(BuildContext context, Color iconColor, Color bgColor) {
    Widget content;
    
    switch (widget.style) {
      case UnifiedButtonStyle.glass:
        content = _buildGlassButton(context, iconColor, bgColor);
        break;
      case UnifiedButtonStyle.circular:
        content = _buildCircularButton(context, iconColor, bgColor);
        break;
      case UnifiedButtonStyle.flat:
        content = _buildFlatButton(context, iconColor, bgColor);
        break;
    }
    
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _handleTap,
        customBorder: const CircleBorder(),
        splashColor: iconColor.withOpacity(0.3),
        highlightColor: iconColor.withOpacity(0.1),
        child: content,
      ),
    );
  }

  Widget _buildGlassButton(BuildContext context, Color iconColor, Color bgColor) {
    Widget button = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: widget.showBorder
            ? Border.all(
                color: iconColor.withOpacity(widget.borderOpacity),
                width: 1.5,
              )
            : null,
      ),
      child: Center(
        child: Icon(
          widget.icon,
          color: iconColor,
          size: widget.size * 0.5,
        ),
      ),
    );

    if (widget.enableBlur) {
      return ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: button,
        ),
      );
    }

    return button;
  }

  Widget _buildCircularButton(BuildContext context, Color iconColor, Color bgColor) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: widget.showShadow
            ? [
                BoxShadow(
                  color: iconColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          widget.icon,
          color: iconColor,
          size: widget.size * 0.5,
        ),
      ),
    );
  }

  Widget _buildFlatButton(BuildContext context, Color iconColor, Color bgColor) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          widget.icon,
          color: iconColor,
          size: widget.size * 0.5,
        ),
      ),
    );
  }

  Color _getDefaultBackground(bool isDark) {
    switch (widget.style) {
      case UnifiedButtonStyle.glass:
        return (isDark ? Colors.white : Colors.black).withOpacity(0.1);
      case UnifiedButtonStyle.circular:
        return (isDark ? Colors.white : Colors.black).withOpacity(0.05);
      case UnifiedButtonStyle.flat:
        return Colors.transparent;
    }
  }
}