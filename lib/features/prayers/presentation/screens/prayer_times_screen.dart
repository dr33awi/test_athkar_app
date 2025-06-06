import 'package:athkar_app/features/home/widgets/prayer_times_card.dart';
import 'package:athkar_app/features/prayers/presentation/widgets/prayer_time_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/themes/app_theme.dart';
import '../providers/prayer_times_provider.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.simple(
        title: 'مواقيت الصلاة',
        actions: [
          AppBarAction(
            icon: Icons.notifications_outlined,
            onPressed: () => _navigateToNotifications(context),
            tooltip: 'الإشعارات',
          ),
          AppBarAction(
            icon: Icons.settings_outlined,
            onPressed: () => _navigateToSettings(context),
            tooltip: 'الإعدادات',
          ),
        ],
      ),
      body: Consumer<PrayerTimesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: AppLoading.page());
          }
          
          if (provider.hasError) {
            return AppEmptyState.error(
              message: provider.error,
              onRetry: () => _refreshPrayerTimes(context),
            );
          }
          
          if (provider.todayPrayerTimes == null) {
            return AppEmptyState.noData(
              message: 'لا توجد بيانات مواقيت الصلاة',
              onAction: () => _refreshPrayerTimes(context),
              actionText: 'تحميل المواقيت',
            );
          }
          
          return RefreshIndicator(
            onRefresh: () => _refreshPrayerTimes(context),
            child: AnimationLimiter(
              child: ListView(
                padding: const EdgeInsets.all(ThemeConstants.space4),
                children: AnimationConfiguration.toStaggeredList(
                  duration: ThemeConstants.durationNormal,
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    _buildNextPrayerSection(context, provider),
                    ThemeConstants.space4.h,
                    _buildAllPrayersSection(context, provider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildNextPrayerSection(
    BuildContext context,
    PrayerTimesProvider provider,
  ) {
    final nextPrayer = provider.nextPrayer;
    if (nextPrayer == null) return const SizedBox.shrink();
    
    return AppCard(
      type: CardType.normal,
      style: CardStyle.gradient,
      gradientColors: [
        context.primaryColor,
        context.primaryColor.darken(0.2),
      ],
      padding: const EdgeInsets.all(ThemeConstants.space5),
      child: Column(
        children: [
          Text(
            'الصلاة التالية',
            style: context.titleMedium?.textColor(Colors.white),
          ),
          ThemeConstants.space3.h,
          Text(
            nextPrayer.name,
            style: context.headlineMedium?.bold.textColor(Colors.white),
          ),
          ThemeConstants.space2.h,
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeConstants.space4,
              vertical: ThemeConstants.space2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(ThemeConstants.opacity20),
              borderRadius: BorderRadius.circular(ThemeConstants.radiusFull),
            ),
            child: Text(
              nextPrayer.formattedTime,
              style: context.titleLarge?.semiBold.textColor(Colors.white),
            ),
          ),
          ThemeConstants.space3.h,
          _buildCountdown(context, nextPrayer),
        ],
      ),
    );
  }
  
  Widget _buildCountdown(BuildContext context, PrayerTime prayer) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final remaining = prayer.timeRemaining;
        
        if (remaining.isNegative) {
          return Text(
            'حان وقت الصلاة',
            style: context.titleMedium?.textColor(Colors.white),
          );
        }
        
        final hours = remaining.inHours;
        final minutes = remaining.inMinutes % 60;
        final seconds = remaining.inSeconds % 60;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeUnit(context, hours, 'ساعة'),
            _buildTimeSeparator(context),
            _buildTimeUnit(context, minutes, 'دقيقة'),
            _buildTimeSeparator(context),
            _buildTimeUnit(context, seconds, 'ثانية'),
          ],
        );
      },
    );
  }
  
  Widget _buildTimeUnit(BuildContext context, int value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(ThemeConstants.space3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(ThemeConstants.opacity10),
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: context.headlineSmall?.bold.textColor(Colors.white),
          ),
        ),
        ThemeConstants.space1.h,
        Text(
          label,
          style: context.labelSmall?.textColor(Colors.white70),
        ),
      ],
    );
  }
  
  Widget _buildTimeSeparator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ThemeConstants.space2),
      child: Text(
        ':',
        style: context.headlineSmall?.bold.textColor(Colors.white),
      ),
    );
  }
  
  Widget _buildAllPrayersSection(
    BuildContext context,
    PrayerTimesProvider provider,
  ) {
    final prayers = provider.todayPrayerTimes!.prayers;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'جميع الأوقات',
          style: context.titleLarge?.semiBold,
        ),
        ThemeConstants.space3.h,
        ...prayers.map((prayer) => Padding(
          padding: const EdgeInsets.only(bottom: ThemeConstants.space3),
          child: PrayerTimeCard(
            prayerTime: prayer,
            isNext: prayer.id == provider.nextPrayer?.id,
            isCurrent: prayer.hasPassed && 
                      prayers.indexOf(prayer) == 
                      prayers.lastIndexWhere((p) => p.hasPassed),
          ),
        )),
      ],
    );
  }
  
  Future<void> _refreshPrayerTimes(BuildContext context) async {
    final provider = context.read<PrayerTimesProvider>();
    // استخدام الموقع المحفوظ أو الحصول على موقع جديد
    await provider.loadTodayPrayerTimes(
      latitude: 21.422510, // مكة المكرمة كمثال
      longitude: 39.826168,
    );
  }
  
  void _navigateToNotifications(BuildContext context) {
    Navigator.pushNamed(context, '/prayer-notifications');
  }
  
  void _navigateToSettings(BuildContext context) {
    Navigator.pushNamed(context, '/prayer-settings');
  }
}