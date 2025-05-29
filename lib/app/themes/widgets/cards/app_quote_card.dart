// lib/app/themes/widgets/cards/app_quote_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_animations.dart';
// import '../../core/theme_extensions.dart'; // For ColorExtensionMethods if needed

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
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = primaryColor ?? theme.primaryColor;

    final List<Color> effectiveGradientColors = gradientColors ?? [
      baseColor,
      baseColor.withAlpha((0.8 * 255).round()),
    ];

    final textColor = _getContrastingTextColor(effectiveGradientColors.first);
    // final subtextColor = textColor.withAlpha((AppColors.opacity70 * 255).round()); // Unused variable

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
          colors: effectiveGradientColors,
          stops: const [0.2, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withAlpha((AppColors.opacity30 * 255).round()),
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
            if (category != null) _buildCategory(textColor),
            if (category != null) const SizedBox(height: AppDimens.space2),
            _buildQuote(textColor),
            if (author != null) ...[
              const SizedBox(height: AppDimens.space3),
              _buildAuthor(textColor),
            ],
          ],
        ),
      ),
    );

    if (animate) {
      return AnimationConfiguration.synchronized(
        duration: AppAnimations.durationNormal,
        child: SlideAnimation(
          horizontalOffset: 50,
          curve: AppAnimations.curveSmooth,
          child: FadeInAnimation(
            curve: AppAnimations.curveDefault,
            child: card,
          ),
        ),
      );
    }
    return card;
  }

  Widget _buildCategory(Color textColor) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space3,
          vertical: AppDimens.space1,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((AppColors.opacity20 * 255).round()),
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

  Widget _buildQuote(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space4),
      decoration: BoxDecoration(
        color: textColor.withAlpha((AppColors.opacity10 * 255).round()),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: textColor.withAlpha((AppColors.opacity20 * 255).round()),
          width: AppDimens.borderThin,
        ),
      ),
      child: Stack(
        children: [
          if (showQuoteMarks) ...[
            Positioned(
              top: -4,
              right: -4,
              child: Icon(
                quoteIcon,
                size: AppDimens.iconSm,
                color: textColor.withAlpha((AppColors.opacity50 * 255).round()),
              ),
            ),
            Positioned(
              bottom: -4,
              left: -4,
              child: Transform.rotate(
                angle: 3.14159,
                child: Icon(
                  quoteIcon,
                  size: AppDimens.iconSm,
                  color: textColor.withAlpha((AppColors.opacity50 * 255).round()),
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

  Widget _buildAuthor(Color textColor) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space3,
          vertical: AppDimens.space1,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((AppColors.opacity20 * 255).round()),
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

  Color _getContrastingTextColor(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

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

  factory AppQuoteCard.religious({
    required String quote,
    required String source,
    Color? color,
  }) {
    return AppQuoteCard(
      quote: quote,
      author: source,
      category: 'حديث شريف',
      primaryColor: color ?? AppColors.primary, // Direct use of AppColors
      quoteStyle: AppTypography.athkar,
    );
  }
}