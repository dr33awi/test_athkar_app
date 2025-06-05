// lib/app/themes/widgets/cards/athkar_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'app_card.dart';
import '../../theme_constants.dart';

/// بطاقة خاصة بعرض الأذكار - تستخدم AppCard الموحدة
class AthkarCard extends StatelessWidget {
  final String content;
  final String? source;
  final int currentCount;
  final int totalCount;
  final bool isFavorite;
  final Color? primaryColor;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onInfo;
  final bool showActions;
  final bool showCounter;
  final bool isCompleted;
  final IconData? categoryIcon;

  const AthkarCard({
    super.key,
    required this.content,
    this.source,
    this.currentCount = 0,
    this.totalCount = 1,
    this.isFavorite = false,
    this.primaryColor,
    this.onTap,
    this.onFavoriteToggle,
    this.onCopy,
    this.onShare,
    this.onInfo,
    this.showActions = true,
    this.showCounter = true,
    this.isCompleted = false,
    this.categoryIcon,
  });

  void _handleCopy(BuildContext context) {
    String textToCopy = content;
    if (source != null) {
      textToCopy += '\n\nالمصدر: $source';
    }
    
    Clipboard.setData(ClipboardData(text: textToCopy)).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم نسخ الذكر'),
            backgroundColor: primaryColor ?? ThemeConstants.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
            ),
          ),
        );
      }
    });
    
    onCopy?.call();
  }

  void _handleShare() {
    String textToShare = content;
    if (source != null) {
      textToShare += '\n\nالمصدر: $source';
    }
    
    Share.share(textToShare, subject: 'ذكر من تطبيق الأذكار');
    onShare?.call();
  }

  @override
  Widget build(BuildContext context) {
    // إعداد الإجراءات
    final List<CardAction> actions = [];
    
    if (showActions) {
      actions.add(CardAction(
        icon: Icons.copy,
        label: 'نسخ',
        onPressed: () => _handleCopy(context),
      ));
      
      actions.add(CardAction(
        icon: Icons.share,
        label: 'مشاركة',
        onPressed: _handleShare,
      ));
      
      if (onInfo != null) {
        actions.add(CardAction(
          icon: Icons.info_outline,
          label: 'فضل الذكر',
          onPressed: onInfo!,
        ));
      }
    }

    // استخدام AppCard الموحدة
    return AppCard.athkar(
      content: content,
      source: source,
      currentCount: showCounter ? currentCount : 0,
      totalCount: showCounter ? totalCount : 1,
      isFavorite: isFavorite,
      primaryColor: primaryColor,
      onTap: onTap,
      onFavoriteToggle: onFavoriteToggle,
      actions: actions,
    );
  }
}