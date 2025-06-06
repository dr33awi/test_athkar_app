// lib/features/home/presentation/widgets/daily_verse_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/themes/app_theme.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/infrastructure/services/storage/storage_service.dart';

class DailyVerseCard extends StatefulWidget {
  const DailyVerseCard({super.key});

  @override
  State<DailyVerseCard> createState() => _DailyVerseCardState();
}

class _DailyVerseCardState extends State<DailyVerseCard> {
  late final StorageService _storageService;
  
  String _verseText = '';
  String _verseReference = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _storageService = context.getService<StorageService>();
    _loadDailyVerse();
  }

  Future<void> _loadDailyVerse() async {
    // محاكاة تحميل الآية اليومية
    await Future.delayed(ThemeConstants.durationFast);
    
    if (mounted) {
      setState(() {
        _verseText = 'وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ ۚ عَلَيْهِ تَوَكَّلْتُ وَإِلَيْهِ أُنِيبُ';
        _verseReference = 'سورة هود - الآية 88';
        _isLoading = false;
      });
    }
  }

  void _handleShare() {
    HapticFeedback.lightImpact();
    context.showInfoSnackBar('مشاركة الآية');
    // TODO: تنفيذ وظيفة المشاركة
  }

  void _handleCopy() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: '$_verseText\n$_verseReference'));
    context.showSuccessSnackBar('تم نسخ الآية');
  }

  void _handleFavorite() {
    HapticFeedback.lightImpact();
    // TODO: تنفيذ وظيفة المفضلة
    context.showSuccessSnackBar('تمت الإضافة للمفضلة');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: ThemeConstants.space4),
      child: AppCard(
        type: CardType.quote,
        style: CardStyle.gradient,
        gradientColors: [
          ThemeConstants.primary,
          ThemeConstants.primaryDark,
        ],
        content: _isLoading ? null : _verseText,
        source: _isLoading ? null : _verseReference,
        subtitle: 'آية اليوم',
        child: _isLoading ? _buildLoadingState() : null,
        actions: _isLoading ? null : [
          CardAction(
            icon: Icons.share_outlined,
            label: 'مشاركة',
            onPressed: _handleShare,
          ),
          CardAction(
            icon: Icons.copy_outlined,
            label: 'نسخ',
            onPressed: _handleCopy,
          ),
          CardAction(
            icon: Icons.favorite_border,
            label: 'مفضلة',
            onPressed: _handleFavorite,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: AppLoading.circular(
        color: Colors.white,
        size: LoadingSize.medium,
      ),
    );
  }
}