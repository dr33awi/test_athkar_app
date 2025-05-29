// lib/app/themes/core/utils/reusable_components.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';

/// عنوان قسم متناسق مع الثيم
class ThemedSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onActionPressed;
  final IconData? actionIcon;
  final String? actionText;
  
  const ThemedSectionHeader({
    Key? key,
    required this.title,
    this.icon,
    this.onActionPressed,
    this.actionIcon,
    this.actionText,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.space2, 
        vertical: AppDimens.space4,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Icon(
                icon,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: AppDimens.space4),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          if (onActionPressed != null) 
            TextButton.icon(
              icon: Icon(
                actionIcon ?? Icons.arrow_forward,
                size: 18,
              ),
              label: Text(actionText ?? ''),
              onPressed: () {
                HapticFeedback.lightImpact();
                onActionPressed!();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                textStyle: TextStyle(
                  fontFamily: AppTypography.fontFamilyArabic,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// بطاقة معلومات أنيقة
class ThemedInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? trailing;
  
  const ThemedInfoCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.trailing,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.primaryColor;
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppDimens.space4,
        vertical: AppDimens.space2,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(AppDimens.space4),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Icon(
                  icon,
                  color: effectiveIconColor,
                  size: 26,
                ),
              ),
              SizedBox(width: AppDimens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppDimens.space1),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
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
                  color: theme.textTheme.bodySmall?.color,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر شائع للتطبيق
class ThemedActionButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  
  const ThemedActionButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  State<ThemedActionButton> createState() => _ThemedActionButtonState();
}

class _ThemedActionButtonState extends State<ThemedActionButton> {
  @override
  Widget build(BuildContext context) {
    final buttonChild = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.foregroundColor ?? Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20),
                SizedBox(width: AppDimens.space2),
              ],
              Text(widget.text),
            ],
          );

    final button = widget.isOutlined
        ? OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.foregroundColor,
              side: BorderSide(
                color: widget.backgroundColor ?? Theme.of(context).primaryColor,
              ),
            ),
            child: buttonChild,
          )
        : ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.backgroundColor,
              foregroundColor: widget.foregroundColor,
            ),
            child: buttonChild,
          );

    if (widget.isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    return button;
  }
}

/// قائمة عناصر مع تصميم أنيق
class ThemedListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  
  const ThemedListItem({
    Key? key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.trailing,
    this.iconColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
        child: Icon(
          icon,
          color: iconColor ?? Theme.of(context).primaryColor,
        ),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// مؤشر التحميل المتوافق مع الثيم
class ThemedLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  
  const ThemedLoadingIndicator({
    Key? key,
    this.message,
    this.size = 40,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: AppDimens.space5),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// أيقونة مع خلفية دائرية
class ThemedCircleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  
  const ThemedCircleIcon({
    Key? key,
    required this.icon,
    this.size = 44,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor.withOpacity(0.1);
    final fgColor = iconColor ?? theme.primaryColor;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: fgColor,
        size: size * 0.5,
      ),
    );
  }
}

/// فاصل مع نص في المنتصف
class ThemedDividerWithText extends StatelessWidget {
  final String text;
  
  const ThemedDividerWithText({
    Key? key,
    required this.text,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimens.space4),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: theme.dividerColor,
              thickness: AppDimens.borderThin,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimens.space4),
            child: Text(
              text,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Divider(
              color: theme.dividerColor,
              thickness: AppDimens.borderThin,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة معلومات إحصائية
class ThemedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  
  const ThemedStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.primaryColor;
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(AppDimens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: effectiveColor,
                    size: AppDimens.iconMd,
                  ),
                  Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: AppDimens.iconSm,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                ],
              ),
              SizedBox(height: AppDimens.space3),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppDimens.space1),
              Text(
                title,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// رسالة فارغة
class ThemedEmptyMessage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;
  
  const ThemedEmptyMessage({
    Key? key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.action,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.space5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ThemedCircleIcon(
              icon: icon,
              size: 80,
              backgroundColor: theme.colorScheme.surface,
              iconColor: theme.textTheme.bodySmall?.color,
            ),
            SizedBox(height: AppDimens.space5),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: AppDimens.space2),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: AppDimens.space5),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// شريط التقدم الخطي
class ThemedLinearProgress extends StatelessWidget {
  final double value;
  final double height;
  final Color? backgroundColor;
  final Color? valueColor;
  final String? label;
  
  const ThemedLinearProgress({
    Key? key,
    required this.value,
    this.height = 8,
    this.backgroundColor,
    this.valueColor,
    this.label,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          SizedBox(height: AppDimens.space2),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            backgroundColor: backgroundColor ?? theme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              valueColor ?? theme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// بطاقة التنبيه
class ThemedAlertCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;
  final VoidCallback? onClose;
  
  const ThemedAlertCard({
    Key? key,
    required this.message,
    required this.icon,
    this.color,
    this.onClose,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final alertColor = color ?? AppColors.info;
    
    return Container(
      padding: EdgeInsets.all(AppDimens.space4),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: alertColor.withOpacity(0.3),
          width: AppDimens.borderThin,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: alertColor,
            size: 24,
          ),
          SizedBox(width: AppDimens.space4),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: Icon(
                Icons.close,
                color: Theme.of(context).textTheme.bodySmall?.color,
                size: 20,
              ),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
        ],
      ),
    );
  }
}