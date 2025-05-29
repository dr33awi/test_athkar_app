// lib/features/athkar/widgets/athkar_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'app_card.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';

/// بطاقة خاصة بعرض الأذكار
/// تستخدم AppCard كأساس مع تخصيصات إضافية للأذكار
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
    Key? key,
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
  }) : super(key: key);

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
            backgroundColor: primaryColor ?? AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
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

    return AppCard(
      cardStyle: CardStyle.gradient,
      primaryColor: primaryColor,
      onTap: onTap,
      gradientColors: primaryColor != null ? [
        primaryColor!,
        HSLColor.fromColor(primaryColor!)
            .withLightness(HSLColor.fromColor(primaryColor!).lightness * 0.7)
            .toColor(),
      ] : null,
      actions: actions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الرأس مع العداد والمفضلة
          if (showCounter || onFavoriteToggle != null)
            _buildHeader(context),
          
          if (showCounter || onFavoriteToggle != null)
            const SizedBox(height: AppDimens.space3),
          
          // محتوى الذكر
          _buildContent(context),
          
          // المصدر
          if (source != null) ...[
            const SizedBox(height: AppDimens.space3),
            _buildSource(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // العداد
        if (showCounter)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(AppColors.opacity20),
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space3,
              vertical: AppDimens.space1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (categoryIcon != null) ...[
                  Icon(
                    categoryIcon,
                    color: Colors.white,
                    size: AppDimens.iconSm,
                  ),
                  const SizedBox(width: AppDimens.space1),
                ],
                Text(
                  'عدد التكرار $currentCount/$totalCount',
                  style: AppTypography.label2.copyWith(
                    color: Colors.white,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ],
            ),
          ),
        
        // زر المفضلة
        if (onFavoriteToggle != null)
          Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
                size: AppDimens.iconMd,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                onFavoriteToggle!();
              },
              tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
              splashRadius: AppDimens.iconMd,
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(AppColors.opacity10),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(
          color: Colors.white.withOpacity(AppColors.opacity20),
          width: AppDimens.borderThin,
        ),
      ),
      child: Stack(
        children: [
          // علامة اقتباس في البداية
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.format_quote,
              size: AppDimens.iconSm,
              color: Colors.white.withOpacity(AppColors.opacity50),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.space2),
            child: Text(
              content,
              textAlign: TextAlign.center,
              style: AppTypography.athkar.copyWith(
                color: Colors.white,
                fontSize: 20,
                fontWeight: AppTypography.semiBold,
                height: 2.0,
              ),
            ),
          ),
          
          // علامة اقتباس في النهاية
          Positioned(
            bottom: 0,
            left: 0,
            child: Transform.rotate(
              angle: 3.14159, // 180 درجة
              child: Icon(
                Icons.format_quote,
                size: AppDimens.iconSm,
                color: Colors.white.withOpacity(AppColors.opacity50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSource(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space4,
          vertical: AppDimens.space2,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(AppColors.opacity20),
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
        child: Text(
          source!,
          style: AppTypography.label1.copyWith(
            color: Colors.white,
            fontWeight: AppTypography.semiBold,
          ),
        ),
      ),
    );
  }
}