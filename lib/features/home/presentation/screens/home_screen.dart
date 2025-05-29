// lib/features/home/presentation/screens/home_screen.dart
import 'package:athkar_app/app/themes/widgets/glassmorphism_widgets.dart';
import 'package:athkar_app/app/themes/core/utils/reusable_components.dart';
import 'package:athkar_app/app/themes/screen_template.dart';
import 'package:athkar_app/app/themes/theme_constants.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/features/home/models/daily_quote_model.dart';
import 'package:athkar_app/features/home/presentation/quotes/services/daily_quote_service.dart';
import 'package:athkar_app/features/home/presentation/quotes/widgets/quote_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../athkar/presentation/providers/athkar_provider.dart';
import '../../../prayers/presentation/providers/prayer_times_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../app/themes/loading_widget.dart';
import '../../../prayers/presentation/widgets/prayer_times_section.dart';
import '../widgets/category_grid.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  // متحكمات العرض
  final PageController _pageController = PageController();
  final ValueNotifier<int> _pageIndex = ValueNotifier<int>(0);
  
  // خدمة الاقتباسات
  final DailyQuoteService _quoteService = DailyQuoteService();
  List<HighlightItem> _highlights = [];
  bool _highlightsLoaded = false;
  
  // للتحكم في حالة السحب للتحديث
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    
    // تأخير قصير لضمان تجهيز Provider
    Future.microtask(() {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final prayerTimesProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
      
      // تعيين موقع افتراضي مؤقت (سيتم استبداله بموقع المستخدم الحقيقي)
      // الإحداثيات الافتراضية لمكة المكرمة
      prayerTimesProvider.setLocation(
        latitude: 21.422510,
        longitude: 39.826168,
      );
      
      // تحميل مواقيت الصلاة إذا كانت الإعدادات جاهزة
      if (settingsProvider.settings != null) {
        prayerTimesProvider.loadTodayPrayerTimes(settingsProvider.settings!);
      }
    });
    
    // تحميل الاقتباسات اليومية
    _initQuoteService();
  }
  
  Future<void> _initQuoteService() async {
    if (mounted) {
      setState(() {
        _highlightsLoaded = false; // نجعل حالة التحميل نشطة عند بدء التحميل
      });
    }
    
    try {
      await _quoteService.initialize();
      final dailyHighlights = await _quoteService.getDailyHighlights();
      if (mounted) {
        setState(() {
          _highlights = dailyHighlights;
          _highlightsLoaded = true;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل الاقتباسات: $e');
      if (mounted) {
        setState(() {
          _highlights = const [
            HighlightItem(
              headerTitle: 'آية اليوم',
              headerIcon: Icons.menu_book_rounded,
              quote: '﴿ الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُمْ بِذِكْرِ اللَّهِ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
              source: 'سورة الرعد – آية 28',
            ),
            HighlightItem(
              headerTitle: 'حديث اليوم',
              headerIcon: Icons.format_quote_rounded,
              quote: 'قال رسول الله ﷺ: «مَن قال سبحان الله وبحمده في يومٍ مائة مرة، حُطَّت خطاياه وإن كانت مثل زبد البحر»',
              source: 'متفق عليه',
            ),
          ];
          _highlightsLoaded = true;
          _isRefreshing = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _pageIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    
    return ScreenTemplate(
      title: AppConstants.appName,
      showBackButton: false,
      backgroundColor: isDark ? ThemeColors.darkBackground : ThemeColors.lightBackground,
      actions: [
        IconButton(
          icon: Icon(Icons.favorite, color: AppTheme.getTextColor(context)),
          tooltip: 'المفضلة',
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, AppRouter.favorites);
          },
        ),
        IconButton(
          icon: Icon(Icons.settings, color: AppTheme.getTextColor(context)),
          tooltip: 'الإعدادات',
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, AppRouter.settingsRoute);
          },
        ),
      ],
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return Center(
              child: LoadingWidget(color: AppTheme.getPrimaryColor(context)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // تأثير اهتزاز عند السحب للتحديث
              HapticFeedback.mediumImpact();
              
              // تحديث كل من البيانات
              setState(() {
                _isRefreshing = true;
                _highlightsLoaded = false;
              });
              
              // تحديث بيانات مواقيت الصلاة
              if (settingsProvider.settings != null) {
                await Provider.of<PrayerTimesProvider>(context, listen: false)
                    .refreshData(settingsProvider.settings!);
              }
              
              // تحديث الاقتباسات اليومية
              await _quoteService.refreshDailyHighlights().then((highlightsList) {
                if (mounted) {
                  setState(() {
                    _highlights = highlightsList;
                    _highlightsLoaded = true;
                    _isRefreshing = false;
                  });
                }
              });
            },
            color: AppTheme.getPrimaryColor(context),
            backgroundColor: AppTheme.getBackgroundColor(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // قسم مواقيت الصلاة
                _buildPrayerTimesSection(),
                const SizedBox(height: 20),
                
                // قسم الاقتباسات اليومية
                _buildDailyQuotesSection(context),
                const SizedBox(height: 20),
                
                // قسم الفئات
                _buildCategoriesSection(context),
                
                // معلومات إضافية
                Center(
                  child: SoftContainer(
                    width: 200,
                    height: 40,
                    borderRadius: ThemeSizes.borderRadiusLarge,
                    hasBorder: true,
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Text(
                        '${AppConstants.appName} - ${AppConstants.appVersion}',
                        style: AppTheme.getCaptionStyle(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // قسم مواقيت الصلاة المحسن
  Widget _buildPrayerTimesSection() {
    return SoftCard(
      borderRadius: ThemeSizes.borderRadiusLarge,
      hasBorder: true,
      elevation: 2,
      padding: const EdgeInsets.all(ThemeSizes.marginMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
                    ),
                    child: Icon(
                      Icons.access_time_rounded,
                      color: AppTheme.getPrimaryColor(context),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: ThemeSizes.marginSmall),
                  Text(
                    'مواقيت الصلاة',
                    style: AppTheme.getHeadingStyle(context, fontSize: 18),
                  ),
                ],
              ),
              SoftButton(
                text: 'عرض الكل',
                icon: Icons.arrow_forward,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, AppRouter.prayerTimes);
                },
                isOutlined: true,
                isFullWidth: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeSizes.marginMedium,
                  vertical: ThemeSizes.marginSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeSizes.marginSmall),
          Divider(color: AppTheme.getDividerColor(context)),
          const SizedBox(height: ThemeSizes.marginSmall),
          const PrayerTimesSection(),
        ],
      ),
    );
  }
  
  // بناء قسم الاقتباسات اليومية
  Widget _buildDailyQuotesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThemedSectionHeader(
          title: 'اقتباسات اليوم',
          icon: Icons.auto_awesome,
          actionIcon: Icons.refresh_rounded,
          onActionPressed: () {
            HapticFeedback.lightImpact();
            _quoteService.refreshDailyHighlights().then((highlights) {
              if (mounted) {
                setState(() {
                  _highlights = highlights;
                });
              }
            });
          },
        ),
        
        // عرض الاقتباسات أو مؤشر التحميل
        !_highlightsLoaded
          ? _buildLoadingHighlightsCard(context)
          : QuoteCarousel(
              highlights: _highlights,
              pageController: _pageController,
              pageIndex: _pageIndex,
              onQuoteTap: (quoteItem) {
                HapticFeedback.mediumImpact();
                Navigator.pushNamed(
                  context,
                  AppRouter.quoteDetails,
                  arguments: quoteItem,
                );
              },
            ),
      ],
    );
  }
  
  // قسم الفئات المحسن
  Widget _buildCategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThemedSectionHeader(
          title: 'الأقسام',
          icon: Icons.grid_view_rounded,
        ),
        const SizedBox(height: ThemeSizes.marginSmall),
        
        // قسم شبكة الفئات
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 300, // تحديد ارتفاع أقصى للقائمة
          ),
          child: CustomScrollView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              const CategoryGrid(),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  // مؤشر التحميل المحسن
  Widget _buildLoadingHighlightsCard(BuildContext context) {
    return SoftCard(
      borderRadius: ThemeSizes.borderRadiusLarge,
      hasBorder: true,
      elevation: 2,
      child: Container(
        height: 200,
        width: double.infinity,
        padding: const EdgeInsets.all(ThemeSizes.marginMedium),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.getPrimaryColor(context),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                _isRefreshing 
                    ? 'جاري تحديث المقتبسات...' 
                    : 'جاري تحميل المقتبسات...',
                style: AppTheme.getBodyStyle(context, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}