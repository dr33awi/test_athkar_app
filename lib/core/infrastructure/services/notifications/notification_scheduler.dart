// lib/core/services/utils/notification_scheduler.dart
import 'dart:async';
import 'package:athkar_app/features/settings/domain/entities/settings_extensions.dart';

import '../../../../app/di/service_locator.dart';
import '../../../constants/app_constants.dart';
import '../device/battery/battery_service.dart';
import '../device/do_not_disturb/do_not_disturb_service.dart';
import 'notification_service.dart';
import '../../../../features/prayers/domain/prayer_times_service.dart';
import '../logging/logger_service.dart';
import 'notification_payload_handler.dart';
import 'notification_analytics.dart';
import '../../../../features/settings/domain/entities/settings.dart';

/// مساعد محسّن لجدولة الإشعارات المختلفة في التطبيق
class NotificationScheduler {
  final NotificationService _notificationService;
  final BatteryService _batteryService;
  final DoNotDisturbService _doNotDisturbService;
  final PrayerTimesService _prayerTimesService;
  final LoggerService _logger;
  final NotificationAnalytics _analytics;
  
  // تخزين معرفات الإشعارات التي تم جدولتها
  final Set<int> _scheduledNotificationIds = {};
  final Map<String, List<int>> _notificationIdsByType = {};
  
  // متغيرات الحالة
  bool _isScheduling = false;
  
  NotificationScheduler({
    NotificationService? notificationService,
    BatteryService? batteryService,
    DoNotDisturbService? doNotDisturbService,
    PrayerTimesService? prayerTimesService,
    LoggerService? logger,
    NotificationAnalytics? analytics,
  })  : _notificationService = notificationService ?? getIt<NotificationService>(),
        _batteryService = batteryService ?? getIt<BatteryService>(),
        _doNotDisturbService = doNotDisturbService ?? getIt<DoNotDisturbService>(),
        _prayerTimesService = prayerTimesService ?? getIt<PrayerTimesService>(),
        _logger = logger ?? getIt<LoggerService>(),
        _analytics = analytics ?? getIt<NotificationAnalytics>() {
    _logger.debug(message: 'NotificationScheduler initialized');
  }
  
  /// جدولة جميع الإشعارات بناءً على الإعدادات
  Future<SchedulingResult> scheduleAllNotifications(Settings settings) async {
    if (_isScheduling) {
      _logger.warning(message: 'Scheduling already in progress');
      return SchedulingResult(
        success: false,
        message: 'جدولة الإشعارات قيد التنفيذ بالفعل',
      );
    }
    
    _isScheduling = true;
    final stopwatch = Stopwatch()..start();
    
    try {
      _logger.info(message: 'Starting notification scheduling');
      
      if (!settings.enableNotifications) {
        await _cancelAllNotifications();
        _logger.info(message: 'All notifications cancelled - notifications disabled');
        return SchedulingResult(
          success: true,
          message: 'تم إلغاء جميع الإشعارات',
          cancelledCount: _scheduledNotificationIds.length,
        );
      }
      
      int scheduledCount = 0;
      int failedCount = 0;
      final List<String> errors = [];
      
      // جدولة إشعارات الأذكار
      if (settings.enableAthkarNotifications) {
        final athkarResult = await _scheduleAthkarNotifications(settings);
        scheduledCount += athkarResult.scheduledCount;
        failedCount += athkarResult.failedCount;
        errors.addAll(athkarResult.errors);
      } else {
        await _cancelNotificationsByType('athkar');
      }
      
      // جدولة إشعارات مواقيت الصلاة
      if (settings.enablePrayerTimesNotifications) {
        final prayerResult = await _schedulePrayerNotifications(settings);
        scheduledCount += prayerResult.scheduledCount;
        failedCount += prayerResult.failedCount;
        errors.addAll(prayerResult.errors);
      } else {
        await _cancelNotificationsByType('prayer');
      }
      
      stopwatch.stop();
      
      _logger.info(
        message: 'Notification scheduling completed',
        data: {
          'duration_ms': stopwatch.elapsedMilliseconds,
          'scheduled': scheduledCount,
          'failed': failedCount,
        }
      );
      
      _analytics.recordEvent('scheduling_completed', {
        'scheduled_count': scheduledCount,
        'failed_count': failedCount,
        'duration_ms': stopwatch.elapsedMilliseconds,
      });
      
      return SchedulingResult(
        success: failedCount == 0,
        message: _buildResultMessage(scheduledCount, failedCount),
        scheduledCount: scheduledCount,
        failedCount: failedCount,
        errors: errors,
      );
      
    } catch (e, s) {
      _logger.error(
        message: 'Error during notification scheduling',
        error: e,
        stackTrace: s
      );
      
      return SchedulingResult(
        success: false,
        message: 'حدث خطأ أثناء جدولة الإشعارات',
        errors: [e.toString()],
      );
    } finally {
      _isScheduling = false;
    }
  }
  
  /// جدولة إشعارات الأذكار
  Future<SchedulingTypeResult> _scheduleAthkarNotifications(Settings settings) async {
    if (!settings.showAthkarReminders) {
      await _cancelNotificationsByType('athkar');
      return SchedulingTypeResult();
    }
    
    int scheduled = 0;
    int failed = 0;
    final errors = <String>[];
    
    // جدولة أذكار الصباح
    try {
      if (await _scheduleMorningAthkarNotification(settings)) {
        scheduled++;
      } else {
        failed++;
      }
    } catch (e) {
      failed++;
      errors.add('أذكار الصباح: $e');
    }
    
    // جدولة أذكار المساء
    try {
      if (await _scheduleEveningAthkarNotification(settings)) {
        scheduled++;
      } else {
        failed++;
      }
    } catch (e) {
      failed++;
      errors.add('أذكار المساء: $e');
    }
    
    // جدولة أذكار النوم إذا كانت مفعلة
    if (settings.enableSleepAthkarNotifications) {
      try {
        if (await _scheduleSleepAthkarNotification(settings)) {
          scheduled++;
        } else {
          failed++;
        }
      } catch (e) {
        failed++;
        errors.add('أذكار النوم: $e');
      }
    }
    
    return SchedulingTypeResult(
      scheduledCount: scheduled,
      failedCount: failed,
      errors: errors,
    );
  }
  
  /// جدولة إشعار أذكار الصباح
  Future<bool> _scheduleMorningAthkarNotification(Settings settings) async {
    final notificationTime = _calculateNextNotificationTime(
      settings.morningAthkarTime[0],
      settings.morningAthkarTime[1],
    );
    
    final actions = settings.enableActionButtons
        ? [
            NotificationAction(id: 'read_now', title: 'قراءة الآن'),
            NotificationAction(id: 'remind_later', title: 'تذكير لاحقًا'),
          ]
        : null;
    
    final payload = NotificationPayloadHandler.buildAthkarPayload(
      categoryId: 'morning',
      categoryName: 'أذكار الصباح',
    );
    
    final notification = NotificationData(
      id: AppConstants.morningAthkarNotificationId,
      title: 'أذكار الصباح',
      body: 'حان وقت أذكار الصباح، اضغط هنا لقراءة الأذكار',
      scheduledDate: notificationTime,
      repeatInterval: NotificationRepeatInterval.daily,
      notificationTime: NotificationTime.morning,
      priority: _getNotificationPriority(settings, 'athkar'),
      respectBatteryOptimizations: settings.respectBatteryOptimizations,
      respectDoNotDisturb: settings.respectDoNotDisturb,
      channelId: AppConstants.athkarNotificationChannelId,
      soundName: _getNotificationSound(settings, 'athkar_morning'),
      payload: payload,
      visibility: NotificationVisibility.public,
    );
    
    bool scheduled;
    if (actions != null) {
      scheduled = await _notificationService.scheduleNotificationWithActions(
        notification,
        actions,
      );
    } else {
      scheduled = await _notificationService.scheduleNotification(notification);
    }
    
    if (scheduled) {
      _addScheduledNotification(notification.id, 'athkar');
    }
    
    return scheduled;
  }
  
  /// جدولة إشعار أذكار المساء
  Future<bool> _scheduleEveningAthkarNotification(Settings settings) async {
    final notificationTime = _calculateNextNotificationTime(
      settings.eveningAthkarTime[0],
      settings.eveningAthkarTime[1],
    );
    
    final actions = settings.enableActionButtons
        ? [
            NotificationAction(id: 'read_now', title: 'قراءة الآن'),
            NotificationAction(id: 'remind_later', title: 'تذكير لاحقًا'),
          ]
        : null;
    
    final payload = NotificationPayloadHandler.buildAthkarPayload(
      categoryId: 'evening',
      categoryName: 'أذكار المساء',
    );
    
    final notification = NotificationData(
      id: AppConstants.eveningAthkarNotificationId,
      title: 'أذكار المساء',
      body: 'حان وقت أذكار المساء، اضغط هنا لقراءة الأذكار',
      scheduledDate: notificationTime,
      repeatInterval: NotificationRepeatInterval.daily,
      notificationTime: NotificationTime.evening,
      priority: _getNotificationPriority(settings, 'athkar'),
      respectBatteryOptimizations: settings.respectBatteryOptimizations,
      respectDoNotDisturb: settings.respectDoNotDisturb,
      channelId: AppConstants.athkarNotificationChannelId,
      soundName: _getNotificationSound(settings, 'athkar_evening'),
      payload: payload,
      visibility: NotificationVisibility.public,
    );
    
    bool scheduled;
    if (actions != null) {
      scheduled = await _notificationService.scheduleNotificationWithActions(
        notification,
        actions,
      );
    } else {
      scheduled = await _notificationService.scheduleNotification(notification);
    }
    
    if (scheduled) {
      _addScheduledNotification(notification.id, 'athkar');
    }
    
    return scheduled;
  }
  
  /// جدولة إشعار أذكار النوم
  Future<bool> _scheduleSleepAthkarNotification(Settings settings) async {
    final notificationTime = _calculateNextNotificationTime(
      settings.sleepAthkarTime[0],
      settings.sleepAthkarTime[1],
    );
    
    final payload = NotificationPayloadHandler.buildAthkarPayload(
      categoryId: 'sleep',
      categoryName: 'أذكار النوم',
    );
    
    final notification = NotificationData(
      id: AppConstants.sleepAthkarNotificationId,
      title: 'أذكار النوم',
      body: 'حان وقت أذكار النوم، اضغط هنا لقراءة الأذكار',
      scheduledDate: notificationTime,
      repeatInterval: NotificationRepeatInterval.daily,
      notificationTime: NotificationTime.custom,
      priority: _getNotificationPriority(settings, 'athkar'),
      respectBatteryOptimizations: settings.respectBatteryOptimizations,
      respectDoNotDisturb: settings.respectDoNotDisturb,
      channelId: AppConstants.athkarNotificationChannelId,
      soundName: _getNotificationSound(settings, 'athkar_sleep'),
      payload: payload,
      visibility: NotificationVisibility.public,
    );
    
    final scheduled = await _notificationService.scheduleNotification(notification);
    
    if (scheduled) {
      _addScheduledNotification(notification.id, 'athkar');
    }
    
    return scheduled;
  }
  
  /// جدولة إشعارات مواقيت الصلاة
  Future<SchedulingTypeResult> _schedulePrayerNotifications(Settings settings) async {
    int scheduled = 0;
    int failed = 0;
    final errors = <String>[];
    
    try {
      // الحصول على الموقع
      final location = await _getLocation(settings);
      if (location == null) {
        return SchedulingTypeResult(
          failedCount: 1,
          errors: ['لا يمكن تحديد الموقع لحساب مواقيت الصلاة'],
        );
      }
      
      // معلمات حساب مواقيت الصلاة
      final params = PrayerTimesCalculationParams(
        calculationMethod: _getCalculationMethodFromSettings(settings.calculationMethod),
        adjustmentMinutes: settings.prayerTimeAdjustment,
        asrMethodIndex: settings.asrMethod,
      );
      
      // جدولة الصلوات للأيام القادمة
      const daysToSchedule = 7;
      for (int i = 0; i < daysToSchedule; i++) {
        final dayResult = await _schedulePrayerTimesForDay(
          settings,
          location.latitude,
          location.longitude,
          params,
          i,
        );
        
        scheduled += dayResult.scheduledCount;
        failed += dayResult.failedCount;
        errors.addAll(dayResult.errors);
      }
      
    } catch (e) {
      _logger.error(
        message: 'Error scheduling prayer notifications',
        error: e,
      );
      errors.add('خطأ عام: $e');
      failed++;
    }
    
    return SchedulingTypeResult(
      scheduledCount: scheduled,
      failedCount: failed,
      errors: errors,
    );
  }
  
  /// جدولة مواقيت الصلاة ليوم واحد
  Future<SchedulingTypeResult> _schedulePrayerTimesForDay(
    Settings settings,
    double latitude,
    double longitude,
    PrayerTimesCalculationParams params,
    int dayOffset,
  ) async {
    int scheduled = 0;
    int failed = 0;
    final errors = <String>[];
    
    try {
      final date = DateTime.now().add(Duration(days: dayOffset));
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      final prayerTimes = await _prayerTimesService.getPrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: dateOnly,
        params: params,
      );
      
      // قائمة الصلوات
      final prayers = [
        PrayerInfo('الفجر', prayerTimes.fajr, NotificationTime.fajr, 2001),
        PrayerInfo('الظهر', prayerTimes.dhuhr, NotificationTime.dhuhr, 2002),
        PrayerInfo('العصر', prayerTimes.asr, NotificationTime.asr, 2003),
        PrayerInfo('المغرب', prayerTimes.maghrib, NotificationTime.maghrib, 2004),
        PrayerInfo('العشاء', prayerTimes.isha, NotificationTime.isha, 2005),
      ];
      
      // جدولة كل صلاة
      for (final prayer in prayers) {
        if (!_shouldSchedulePrayer(settings, prayer)) continue;
        
        try {
          final baseId = prayer.baseId + (dayOffset * 100);
          final reminderId = baseId + 100;
          
          // جدولة التذكير قبل الصلاة
          if (settings.enablePrayerReminders) {
            if (await _schedulePrayerReminder(
              settings,
              prayer,
              baseId: reminderId,
              dayOffset: dayOffset,
            )) {
              scheduled++;
            } else {
              failed++;
            }
          }
          
          // جدولة إشعار وقت الصلاة
          if (await _schedulePrayerNotification(
            settings,
            prayer,
            baseId: baseId,
            dayOffset: dayOffset,
          )) {
            scheduled++;
          } else {
            failed++;
          }
          
        } catch (e) {
          failed++;
          errors.add('${prayer.name} (يوم $dayOffset): $e');
        }
      }
      
    } catch (e) {
      errors.add('يوم $dayOffset: $e');
      failed = 10; // 5 صلوات × 2 إشعارات
    }
    
    return SchedulingTypeResult(
      scheduledCount: scheduled,
      failedCount: failed,
      errors: errors,
    );
  }
  
  /// جدولة تذكير قبل الصلاة
  Future<bool> _schedulePrayerReminder(
    Settings settings,
    PrayerInfo prayer, {
    required int baseId,
    required int dayOffset,
  }) async {
    final now = DateTime.now();
    final reminderMinutes = settings.prayerReminderMinutes;
    final reminderTime = prayer.time.subtract(Duration(minutes: reminderMinutes));
    
    // تجاهل التذكيرات التي مرت
    if (dayOffset == 0 && reminderTime.isBefore(now)) {
      return false;
    }
    
    final payload = NotificationPayloadHandler.buildPrayerPayload(
      prayerName: prayer.name,
      prayerTime: prayer.time,
      isReminder: true,
    );
    
    final notification = NotificationData(
      id: baseId,
      title: 'تذكير: صلاة ${prayer.name}',
      body: 'سيحين وقت صلاة ${prayer.name} بعد $reminderMinutes دقيقة',
      scheduledDate: reminderTime,
      notificationTime: prayer.notificationTime,
      priority: _getNotificationPriority(settings, 'prayer_reminder'),
      respectBatteryOptimizations: settings.respectBatteryOptimizations,
      respectDoNotDisturb: false, // تذكيرات الصلاة تتجاوز DND دائماً
      channelId: AppConstants.prayerTimesNotificationChannelId,
      soundName: _getNotificationSound(settings, 'prayer_reminder'),
      payload: payload,
      visibility: NotificationVisibility.public,
    );
    
    final scheduled = await _notificationService.scheduleNotification(notification);
    
    if (scheduled) {
      _addScheduledNotification(notification.id, 'prayer_reminder');
    }
    
    return scheduled;
  }
  
  /// جدولة إشعار وقت الصلاة
  Future<bool> _schedulePrayerNotification(
    Settings settings,
    PrayerInfo prayer, {
    required int baseId,
    required int dayOffset,
  }) async {
    final now = DateTime.now();
    
    // تجاهل الصلوات التي مرت
    if (dayOffset == 0 && prayer.time.isBefore(now)) {
      return false;
    }
    
    final actions = settings.enableActionButtons
        ? [
            NotificationAction(id: 'view_times', title: 'عرض المواقيت'),
            NotificationAction(
              id: 'dismiss',
              title: 'إغلاق',
              cancelNotification: true,
            ),
          ]
        : null;
    
    final payload = NotificationPayloadHandler.buildPrayerPayload(
      prayerName: prayer.name,
      prayerTime: prayer.time,
      isReminder: false,
    );
    
    final notification = NotificationData(
      id: baseId,
      title: 'صلاة ${prayer.name}',
      body: 'حان وقت صلاة ${prayer.name}',
      scheduledDate: prayer.time,
      notificationTime: prayer.notificationTime,
      priority: _getNotificationPriority(settings, 'prayer'),
      respectBatteryOptimizations: settings.respectBatteryOptimizations,
      respectDoNotDisturb: false, // إشعارات الصلاة تتجاوز DND دائماً
      channelId: AppConstants.prayerTimesNotificationChannelId,
      soundName: _getNotificationSound(settings, 'prayer'),
      payload: payload,
      visibility: NotificationVisibility.public,
    );
    
    bool scheduled;
    if (actions != null) {
      scheduled = await _notificationService.scheduleNotificationWithActions(
        notification,
        actions,
      );
    } else {
      scheduled = await _notificationService.scheduleNotification(notification);
    }
    
    if (scheduled) {
      _addScheduledNotification(notification.id, 'prayer');
    }
    
    return scheduled;
  }
  
  /// إلغاء جميع الإشعارات
  Future<void> _cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
    _scheduledNotificationIds.clear();
    _notificationIdsByType.clear();
  }
  
  /// إلغاء الإشعارات حسب النوع
  Future<void> _cancelNotificationsByType(String type) async {
    final ids = _notificationIdsByType[type] ?? [];
    if (ids.isNotEmpty) {
      await _notificationService.cancelNotificationsByIds(ids);
      _scheduledNotificationIds.removeAll(ids);
      _notificationIdsByType.remove(type);
    }
  }
  
  /// إضافة معرف إشعار مجدول
  void _addScheduledNotification(int id, String type) {
    _scheduledNotificationIds.add(id);
    _notificationIdsByType[type] ??= [];
    _notificationIdsByType[type]!.add(id);
  }
  
  /// حساب الوقت التالي للإشعار
  DateTime _calculateNextNotificationTime(int hour, int minute) {
    final now = DateTime.now();
    var notificationTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    if (notificationTime.isBefore(now)) {
      notificationTime = notificationTime.add(const Duration(days: 1));
    }
    
    return notificationTime;
  }
  
  /// الحصول على الموقع
  Future<Location?> _getLocation(Settings settings) async {
    // في التطبيق الحقيقي، يجب استخدام موقع المستخدم الفعلي
    // هنا نستخدم موقع افتراضي للتوضيح
    return Location(
      latitude: settings.lastKnownLatitude ?? 21.422487,
      longitude: settings.lastKnownLongitude ?? 39.826206,
    );
  }
  
  /// تحديد ما إذا كان يجب جدولة صلاة معينة
  bool _shouldSchedulePrayer(Settings settings, PrayerInfo prayer) {
    // يمكن إضافة منطق لتمكين/تعطيل صلوات معينة
    return true;
  }
  
  /// الحصول على أولوية الإشعار
  NotificationPriority _getNotificationPriority(Settings settings, String type) {
    if (type.contains('prayer') && settings.enableHighPriorityForPrayers) {
      return NotificationPriority.high;
    }
    
    switch (type) {
      case 'athkar':
        return settings.athkarNotificationPriority;
      case 'prayer':
        return NotificationPriority.critical;
      case 'prayer_reminder':
        return NotificationPriority.high;
      default:
        return NotificationPriority.normal;
    }
  }
  
  /// الحصول على صوت الإشعار
  String? _getNotificationSound(Settings settings, String type) {
    if (settings.enableSilentMode) return null;
    
    return settings.notificationSounds[type] ?? settings.defaultNotificationSound;
  }
  
  /// تحويل رقم طريقة الحساب إلى اسم الطريقة
  String _getCalculationMethodFromSettings(int methodIndex) {
    const methods = [
      'karachi',
      'north_america',
      'muslim_world_league',
      'egyptian',
      'umm_al_qura',
      'dubai',
      'qatar',
      'kuwait',
      'singapore',
      'turkey',
      'tehran',
    ];
    
    return methodIndex < methods.length 
        ? methods[methodIndex] 
        : 'muslim_world_league';
  }
  
  /// بناء رسالة النتيجة
  String _buildResultMessage(int scheduled, int failed) {
    if (failed == 0) {
      return 'تم جدولة $scheduled إشعار بنجاح';
    } else if (scheduled == 0) {
      return 'فشلت جدولة جميع الإشعارات ($failed)';
    } else {
      return 'تم جدولة $scheduled إشعار، فشل $failed';
    }
  }
  
  /// الحصول على حالة الإشعارات
  Future<NotificationStatus> getNotificationStatus() async {
    final canSendNow = await _notificationService.canSendNotificationsNow();
    final hasPermission = await _notificationService.requestPermission();
    final batteryLevel = await _batteryService.getBatteryLevel();
    final isCharging = await _batteryService.isCharging();
    final isPowerSaveMode = await _batteryService.isPowerSaveMode();
    final dndEnabled = await _doNotDisturbService.isDoNotDisturbEnabled();
    
    return NotificationStatus(
      canSendNow: canSendNow,
      hasPermission: hasPermission,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      isPowerSaveMode: isPowerSaveMode,
      dndEnabled: dndEnabled,
      scheduledCount: _scheduledNotificationIds.length,
      scheduledByType: Map.from(_notificationIdsByType.map(
        (k, v) => MapEntry(k, v.length),
      )),
      isScheduling: _isScheduling,
    );
  }
  
  /// إعادة جدولة جميع الإشعارات
  Future<SchedulingResult> rescheduleAllNotifications(Settings settings) async {
    _logger.info(message: 'Rescheduling all notifications');
    
    await _cancelAllNotifications();
    return await scheduleAllNotifications(settings);
  }
  
  /// الحصول على إحصائيات الجدولة
  Map<String, dynamic> getSchedulingStats() {
    return {
      'total_scheduled': _scheduledNotificationIds.length,
      'by_type': Map.from(_notificationIdsByType.map(
        (k, v) => MapEntry(k, v.length),
      )),
      'is_scheduling': _isScheduling,
      'analytics': _analytics.getStats(),
    };
  }
}

// كلاسات مساعدة

/// معلومات الصلاة
class PrayerInfo {
  final String name;
  final DateTime time;
  final NotificationTime notificationTime;
  final int baseId;
  
  PrayerInfo(this.name, this.time, this.notificationTime, this.baseId);
}

/// معلومات الموقع
class Location {
  final double latitude;
  final double longitude;
  
  Location({required this.latitude, required this.longitude});
}

/// نتيجة الجدولة
class SchedulingResult {
  final bool success;
  final String message;
  final int scheduledCount;
  final int failedCount;
  final int cancelledCount;
  final List<String> errors;
  
  SchedulingResult({
    required this.success,
    required this.message,
    this.scheduledCount = 0,
    this.failedCount = 0,
    this.cancelledCount = 0,
    this.errors = const [],
  });
}

/// نتيجة جدولة نوع معين
class SchedulingTypeResult {
  final int scheduledCount;
  final int failedCount;
  final List<String> errors;
  
  SchedulingTypeResult({
    this.scheduledCount = 0,
    this.failedCount = 0,
    this.errors = const [],
  });
}

/// حالة الإشعارات
class NotificationStatus {
  final bool canSendNow;
  final bool hasPermission;
  final int batteryLevel;
  final bool isCharging;
  final bool isPowerSaveMode;
  final bool dndEnabled;
  final int scheduledCount;
  final Map<String, int> scheduledByType;
  final bool isScheduling;
  
  NotificationStatus({
    required this.canSendNow,
    required this.hasPermission,
    required this.batteryLevel,
    required this.isCharging,
    required this.isPowerSaveMode,
    required this.dndEnabled,
    required this.scheduledCount,
    required this.scheduledByType,
    required this.isScheduling,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'can_send_now': canSendNow,
      'has_permission': hasPermission,
      'battery_level': batteryLevel,
      'is_charging': isCharging,
      'power_save_mode': isPowerSaveMode,
      'dnd_enabled': dndEnabled,
      'scheduled_count': scheduledCount,
      'scheduled_by_type': scheduledByType,
      'is_scheduling': isScheduling,
    };
  }
}