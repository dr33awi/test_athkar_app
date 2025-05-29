// lib/app/themes/widgets/cards/app_quote_card.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_animations.dart';

/// بطاقة عامة لعرض الاقتباسات والحكم
class AppQuoteCard extends StatelessWidget {
  final String quote;
  final String? author;
  final String? category;
  final Color? primaryColor;
  final List<Color>? gradientColors;
  final IconData quoteIcon;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool showQuoteMarks;
  final bool animate;
  final TextStyle? quoteStyle;
  final TextStyle? authorStyle;

  const AppQuoteCard({
    Key? key,
    required this.quote,
    this.author,
    this.category,
    this.primaryColor,
    this.gradientColors,
    this.quoteIcon = Icons.format_quote_rounded,
    this.margin,
    this.padding,
    this.showQuoteMarks = true,
    this.animate = true,
    this.quoteStyle,
    this.authorStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = primaryColor ?? theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;
    
    // ألوان التدرج
    final colors = gradientColors ?? [
      baseColor,
      baseColor.withOpacity(0.8),
    ];
    
    // لون النص المتباين
    final textColor = _getContrastingTextColor(colors.first);
    final subtextColor = textColor.withOpacity(AppColors.opacity70);
    
    Widget card = Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: AppDimens.space4,
        vertical: AppDimens.space2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: colors,
          stops: const [0.2, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(AppColors.opacity30),
            blurRadius: AppDimens.space3,
            offset: const Offset(0, AppDimens.space1),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppDimens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // الفئة
            if (category != null) _buildCategory(textColor, subtextColor),
            
            if (category != null) const SizedBox(height: AppDimens.space2),
            
            // الاقتباس
            _buildQuote(context, textColor),
            
            // المؤلف
            if (author != null) ...[
              const SizedBox(height: AppDimens.space3),
              _buildAuthor(textColor, subtextColor),
            ],
          ],
        ),
      ),
    );
    
    if (animate) {
      return AppAnimations.bounceIn(
        child: card,
        duration: AppAnimations.durationNormal,
      );
    }
    
    return card;
  }

  Widget _buildCategory(Color textColor, Color subtextColor) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space3,
          vertical: AppDimens.space1,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(AppColors.opacity20),
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
        child: Text(
          category!,
          style: AppTypography.label2.copyWith(
            color: textColor,
            fontWeight: AppTypography.semiBold,
          ),
        ),
      ),
    );
  }

  Widget _buildQuote(BuildContext context, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space4),
      decoration: BoxDecoration(
        color: textColor.withOpacity(AppColors.opacity10),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: textColor.withOpacity(AppColors.opacity20),
          width: AppDimens.borderThin,
        ),
      ),
      child: Stack(
        children: [
          if (showQuoteMarks) ...[
            // علامة اقتباس في البداية
            Positioned(
              top: -4,
              right: -4,
              child: Icon(
                quoteIcon,
                size: AppDimens.iconSm,
                color: textColor.withOpacity(AppColors.opacity50),
              ),
            ),
            // علامة اقتباس في النهاية
            Positioned(
              bottom: -4,
              left: -4,
              child: Transform.rotate(
                angle: 3.14159,
                child: Icon(
                  quoteIcon,
                  size: AppDimens.iconSm,
                  color: textColor.withOpacity(AppColors.opacity50),
                ),
              ),
            ),
          ],
          
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimens.space1,
              horizontal: AppDimens.space2,
            ),
            child: Text(
              quote,
              textAlign: TextAlign.center,
              style: quoteStyle ?? AppTypography.body1.copyWith(
                color: textColor,
                fontSize: 18,
                fontWeight: AppTypography.medium,
                height: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthor(Color textColor, Color subtextColor) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space3,
          vertical: AppDimens.space1,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(AppColors.opacity20),
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
        child: Text(
          author!,
          style: authorStyle ?? AppTypography.caption.copyWith(
            color: textColor,
            fontWeight: AppTypography.medium,
          ),
        ),
      ),
    );
  }

  /// الحصول على لون نص متباين مع الخلفية
  Color _getContrastingTextColor(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  /// إنشاء بطاقة اقتباس بسيطة
  factory AppQuoteCard.simple({
    required String quote,
    String? author,
    Color? color,
  }) {
    return AppQuoteCard(
      quote: quote,
      author: author,
      primaryColor: color,
      showQuoteMarks: false,
    );
  }

  /// إنشاء بطاقة اقتباس ديني
  factory AppQuoteCard.religious({
    required String quote,
    required String source,
    Color? color,
  }) {
    return AppQuoteCard(
      quote: quote,
      author: source,
      category: 'حديث شريف',
      primaryColor: color ?? AppColors.primary,
      quoteStyle: AppTypography.athkar,
    );
  }
}