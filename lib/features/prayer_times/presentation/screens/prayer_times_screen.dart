// lib/features/prayer_times/presentation/screens/prayer_times_screen.dart
import 'package:athkar_app/features/prayer_times/presentation/widgets/prayer_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/themes/app_theme.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../../core/infrastructure/services/logging/logger_service.dart';
import '../../../../core/infrastructure/services/permissions/permission_service.dart';
import '../../infrastructure/services/prayer_times_service.dart';
import '../../domain/models/prayer_time_model.dart';
import '../widgets/prayer_time_item.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/prayer_times_header.dart';

/// شاشة أوقات الصلاة
class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  late final PrayerTimesService _prayerTimesService;
  List<PrayerTimeModel> _prayerTimes = [];
  PrayerTimeModel? _nextPrayer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadPrayerTimes();
  }

  void _initializeService() {
    _prayerTimesService = PrayerTimesService(
      storage: getIt<StorageService>(),
      logger: getIt<LoggerService>(),
      permissions: getIt<PermissionService>(),
    );
  }

  Future<void> _loadPrayerTimes() async {
    setState(() => _isLoading = true);
    
    try {
      final times = await _prayerTimesService.getTodayPrayerTimes();
      final next = _prayerTimesService.getNextPrayer(times);
      
      setState(() {
        _prayerTimes = times;
        _nextPrayer = next;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      context.showErrorSnackBar('خطأ في تحميل أوقات الصلاة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(child: AppLoading.circular())
            : RefreshIndicator(
                onRefresh: _loadPrayerTimes,
                child: CustomScrollView(
                  slivers: [
                    // الهيدر
                    SliverToBoxAdapter(
                      child: PrayerTimesHeader(
                        onSettingsTap: _openSettings,
                        onLocationTap: _updateLocation,
                      ),
                    ),
                    
                    // بطاقة الصلاة القادمة
                    if (_nextPrayer != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(ThemeConstants.space4),
                          child: NextPrayerCard(
                            prayer: _nextPrayer!,
                            onNotificationToggle: () => _toggleNotification(_nextPrayer!),
                          ),
                        ),
                      ),
                    
                    // قائمة الصلوات
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ThemeConstants.space4,
                        vertical: ThemeConstants.space2,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final prayer = _prayerTimes[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: ThemeConstants.space3,
                              ),
                              child: PrayerTimeItem(
                                prayer: prayer,
                                isNext: prayer.id == _nextPrayer?.id,
                                onTap: () => _showPrayerDetails(prayer),
                                onNotificationToggle: () => _toggleNotification(prayer),
                              ),
                            );
                          },
                          childCount: _prayerTimes.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _openSettings() {
    HapticFeedback.lightImpact();
    // فتح شاشة الإعدادات
    context.showInfoSnackBar('إعدادات أوقات الصلاة');
  }

  void _updateLocation() {
    HapticFeedback.lightImpact();
    // تحديث الموقع
    context.showInfoSnackBar('تحديث الموقع');
  }

  void _toggleNotification(PrayerTimeModel prayer) {
    HapticFeedback.lightImpact();
    // تبديل حالة الإشعار
    _prayerTimesService.updateNotificationSettings(
      prayer.name,
      !prayer.isNotificationEnabled,
      prayer.notificationMinutesBefore,
    );
    context.showSuccessSnackBar(
      prayer.isNotificationEnabled
          ? 'تم إيقاف تنبيه ${prayer.arabicName}'
          : 'تم تفعيل تنبيه ${prayer.arabicName}',
    );
  }

  void _showPrayerDetails(PrayerTimeModel prayer) {
    HapticFeedback.lightImpact();
    // عرض تفاصيل الصلاة
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ThemeConstants.radiusXl),
        ),
      ),
      builder: (context) => PrayerDetailsSheet(
        prayer: prayer,
        onSettingsChanged: (enabled, minutesBefore) {
          _prayerTimesService.updateNotificationSettings(
            prayer.name,
            enabled,
            minutesBefore,
          );
          Navigator.pop(context);
          _loadPrayerTimes();
        },
      ),
    );
  }

  @override
  void dispose() {
    _prayerTimesService.dispose();
    super.dispose();
  }
}