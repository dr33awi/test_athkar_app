// lib/app/themes/widgets/dialogs/app_info_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';

/// حوار عام لعرض المعلومات
class AppInfoDialog extends StatelessWidget {
  final String title;
  final String? content;
  final String? subtitle;
  final IconData icon;
  final Color? accentColor;
  final String closeButtonText;
  final List<DialogAction>? actions;
  final Widget? customContent;
  final bool barrierDismissible;

  const AppInfoDialog({
    Key? key,
    required this.title,
    this.content,
    this.subtitle,
    this.icon = Icons.info_outline,
    this.accentColor,
    this.closeButtonText = 'إغلاق',
    this.actions,
    this.customContent,
    this.barrierDismissible = true,
  }) : super(key: key);

  /// عرض الحوار
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? content,
    String? subtitle,
    IconData icon = Icons.info_outline,
    Color? accentColor,
    String closeButtonText = 'إغلاق',
    List<DialogAction>? actions,
    Widget? customContent,
    bool barrierDismissible = true,
    bool hapticFeedback = true,
  }) {
    if (hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppInfoDialog(
        title: title,
        content: content,
        subtitle: subtitle,
        icon: icon,
        accentColor: accentColor,
        closeButtonText: closeButtonText,
        actions: actions,
        customContent: customContent,
        barrierDismissible: barrierDismissible,
      ),
    );
  }

  /// عرض حوار تأكيد
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    IconData icon = Icons.help_outline,
    Color? accentColor,
    bool destructive = false,
  }) {
    return show<bool>(
      context: context,
      title: title,
      content: content,
      icon: icon,
      accentColor: destructive ? AppColors.error : accentColor,
      closeButtonText: cancelText,
      actions: [
        DialogAction(
          label: confirmText,
          onPressed: () => Navigator.of(context).pop(true),
          isPrimary: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.primaryColor;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: color, size: AppDimens.iconMd),
          const SizedBox(width: AppDimens.space3),
          Expanded(
            child: Text(
              title,
              style: AppTypography.h5,
            ),
          ),
        ],
      ),
      content: customContent ?? _buildDefaultContent(context, color),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      actionsPadding: const EdgeInsets.only(
        left: AppDimens.space4,
        right: AppDimens.space4,
        bottom: AppDimens.space3,
      ),
      actions: _buildActions(context, color),
    );
  }

  Widget? _buildDefaultContent(BuildContext context, Color color) {
    if (content == null && subtitle == null) return null;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content != null)
          Text(
            content!,
            style: AppTypography.body1.copyWith(
              height: 1.6,
            ),
          ),
        if (subtitle != null) ...[
          const SizedBox(height: AppDimens.space3),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space3,
              vertical: AppDimens.space2,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(AppColors.opacity10),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(
                color: color.withOpacity(AppColors.opacity20),
                width: AppDimens.borderThin,
              ),
            ),
            child: Text(
              subtitle!,
              style: AppTypography.body2.copyWith(
                color: color,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context, Color color) {
    final defaultActions = <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          closeButtonText,
          style: TextStyle(color: color),
        ),
      ),
    ];
    
    if (actions == null || actions!.isEmpty) {
      return defaultActions;
    }
    
    final customActions = actions!.map((action) {
      if (action.isPrimary) {
        return ElevatedButton(
          onPressed: action.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
          ),
          child: Text(action.label),
        );
      }
      
      return TextButton(
        onPressed: action.onPressed,
        child: Text(
          action.label,
          style: TextStyle(
            color: action.isDestructive ? AppColors.error : color,
          ),
        ),
      );
    }).toList();
    
    return [...customActions, ...defaultActions];
  }
}

/// إجراء في الحوار
class DialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;
  
  const DialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });
}