// lib/app/themes/widgets/cards/app_completion_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'app_card.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_animations.dart';

/// بطاقة عامة لعرض رسائل الإكمال أو النجاح
class AppCompletionCard extends StatelessWidget {
  final String title;
  final String message;
  final String? subMessage;
  final IconData icon;
  final Color? primaryColor;
  final List<CompletionAction> actions;
  final Widget? customIcon;
  final EdgeInsetsGeometry? margin;
  final bool animate;

  const AppCompletionCard({
    super.key,
    required this.title,
    required this.message,
    this.subMessage,
    this.icon = Icons.check_circle_outline,
    this.primaryColor,
    this.actions = const [],
    this.customIcon,
    this.margin,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = primaryColor ?? theme.primaryColor;
    
    Widget content = AppCard(
      margin: margin,
      padding: const EdgeInsets.all(AppDimens.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // الأيقونة
          customIcon ?? _buildDefaultIcon(color),
          const SizedBox(height: AppDimens.space5),
          
          // العنوان
          Text(
            title,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.space3),
          
          // الرسالة الرئيسية
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body1.copyWith(
              color: AppColors.textPrimary(context),
              height: 1.5,
            ),
          ),
          
          // الرسالة الفرعية
          if (subMessage != null) ...[
            const SizedBox(height: AppDimens.space2),
            Text(
              subMessage!,
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
          
          // الإجراءات
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppDimens.space6),
            _buildActions(context, color),
          ],
        ],
      ),
    );
    
    if (animate) {
      return AnimationConfiguration.synchronized(
        duration: AppAnimations.durationSlow,
        child: ScaleAnimation(
          scale: 0.5,
          curve: AppAnimations.curveBounce,
          child: FadeInAnimation(
            curve: AppAnimations.curveDefault,
            child: content,
          ),
        ),
      );
    }
    
    return content;
  }

  Widget _buildDefaultIcon(Color color) {
    return ScaleAnimation(
      duration: AppAnimations.durationVerySlow,
      scale: 0.0,
      curve: AppAnimations.curveBounce,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(AppColors.opacity10),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(AppColors.opacity30),
            width: AppDimens.borderMedium,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: AppDimens.icon2xl,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, Color color) {
    return AnimationLimiter(
      child: Column(
        children: actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          final isFirst = index == 0;
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: AppAnimations.durationNormal,
            delay: Duration(milliseconds: index * 100),
            child: SlideAnimation(
              verticalOffset: 20,
              curve: AppAnimations.curveDefault,
              child: FadeInAnimation(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index < actions.length - 1 
                      ? AppDimens.space3 
                      : 0,
                  ),
                  child: _CompletionActionButton(
                    action: action,
                    isPrimary: isFirst,
                    color: color,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// إجراء يمكن تنفيذه في بطاقة الإكمال
class CompletionAction {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  
  const CompletionAction({
    required this.label,
    required this.onPressed,
    this.icon,
  });
}

/// زر إجراء خاص ببطاقة الإكمال
class _CompletionActionButton extends StatelessWidget {
  final CompletionAction action;
  final bool isPrimary;
  final Color color;
  
  const _CompletionActionButton({
    required this.action,
    required this.isPrimary,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          action.onPressed();
        },
        icon: action.icon != null 
          ? Icon(action.icon, size: AppDimens.iconMd)
          : const SizedBox.shrink(),
        label: Text(action.label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
        ),
      );
    }
    
    return OutlinedButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        action.onPressed();
      },
      icon: action.icon != null 
        ? Icon(action.icon, size: AppDimens.iconMd)
        : const SizedBox.shrink(),
      label: Text(action.label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
        side: BorderSide(color: color, width: AppDimens.borderMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
      ),
    );
  }
}