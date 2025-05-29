// lib/features/notifications/domain/services/athkar_notification_scheduler.dart
import 'package:get_it/get_it.dart';
import '../../core/infrastructure/services/notifications/models/notification_data.dart';
import '../../core/infrastructure/services/logging/logger_service.dart';
import '../../core/infrastructure/services/notifications/utils/notification_analytics.dart';

/// Feature-specific notification scheduler for Athkar
class AthkarNotificationScheduler {
  final NotificationService _notificationService;
  final LoggerService _logger;
  final NotificationAnalytics _analytics;

  AthkarNotificationScheduler({
    NotificationService? notificationService,
    LoggerService? logger,
    NotificationAnalytics? analytics,
  })  : _notificationService = notificationService ?? GetIt.instance<NotificationService>(),
        _logger = logger ?? GetIt.instance<LoggerService>(),
        _analytics = analytics ?? GetIt.instance<NotificationAnalytics>();

  /// Schedule morning athkar notification
  Future<bool> scheduleMorningAthkar({
    required int hour,
    required int minute,
    required String channelId,
    String? soundName,
  }) async {
    final notification = NotificationData(
      id: 1001, // Morning athkar ID
      title: 'أذكار الصباح',
      body: 'حان وقت أذكار الصباح، اضغط هنا لقراءة الأذكار',
      scheduledDate: _calculateNextTime(hour, minute),
      repeatInterval: NotificationRepeatInterval.daily,
      category: NotificationCategory.reminder,
      priority: NotificationPriority.high,
      channelId: channelId,
      soundName: soundName,
      payload: {
        'type': 'athkar',
        'category': 'morning',
        'route': '/athkar/morning',
      },
    );

    final scheduled = await _notificationService.scheduleNotification(notification);
    
    if (scheduled) {
      _logger.info(message: 'Morning athkar notification scheduled');
      _analytics.recordNotificationScheduled(notification.id, 'athkar_morning');
    }
    
    return scheduled;
  }

  /// Schedule evening athkar notification
  Future<bool> scheduleEveningAthkar({
    required int hour,
    required int minute,
    required String channelId,
    String? soundName,
  }) async {
    final notification = NotificationData(
      id: 1002, // Evening athkar ID
      title: 'أذكار المساء',
      body: 'حان وقت أذكار المساء، اضغط هنا لقراءة الأذكار',
      scheduledDate: _calculateNextTime(hour, minute),
      repeatInterval: NotificationRepeatInterval.daily,
      category: NotificationCategory.reminder,
      priority: NotificationPriority.high,
      channelId: channelId,
      soundName: soundName,
      payload: {
        'type': 'athkar',
        'category': 'evening',
        'route': '/athkar/evening',
      },
    );

    final scheduled = await _notificationService.scheduleNotification(notification);
    
    if (scheduled) {
      _logger.info(message: 'Evening athkar notification scheduled');
      _analytics.recordNotificationScheduled(notification.id, 'athkar_evening');
    }
    
    return scheduled;
  }

  /// Cancel all athkar notifications
  Future<void> cancelAllAthkarNotifications() async {
    await _notificationService.cancelNotifications([1001, 1002, 1003]);
    _logger.info(message: 'All athkar notifications cancelled');
  }

  DateTime _calculateNextTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    return scheduledTime;
  }
}

// lib/features/prayers/domain/services/prayer_notification_scheduler.dart
/// Feature-specific notification scheduler for Prayer Times
class PrayerNotificationScheduler {
  final NotificationService _notificationService;
  final LoggerService _logger;
  final NotificationAnalytics _analytics;

  PrayerNotificationScheduler({
    NotificationService? notificationService,
    LoggerService? logger,
    NotificationAnalytics? analytics,
  })  : _notificationService = notificationService ?? GetIt.instance<NotificationService>(),
        _logger = logger ?? GetIt.instance<LoggerService>(),
        _analytics = analytics ?? GetIt.instance<NotificationAnalytics>();

  /// Schedule prayer notification
  Future<bool> schedulePrayerNotification({
    required String prayerName,
    required DateTime prayerTime,
    required int notificationId,
    required String channelId,
    String? soundName,
    bool isReminder = false,
  }) async {
    final notification = NotificationData(
      id: notificationId,
      title: isReminder ? 'تذكير: صلاة $prayerName' : 'صلاة $prayerName',
      body: isReminder 
        ? 'سيحين وقت صلاة $prayerName قريبًا'
        : 'حان وقت صلاة $prayerName',
      scheduledDate: prayerTime,
      category: NotificationCategory.alarm,
      priority: NotificationPriority.max,
      channelId: channelId,
      soundName: soundName,
      payload: {
        'type': 'prayer',
        'prayer_name': prayerName,
        'prayer_time': prayerTime.toIso8601String(),
        'is_reminder': isReminder,
        'route': '/prayer-times',
      },
      visibility: NotificationVisibility.public,
    );

    final scheduled = await _notificationService.scheduleNotification(notification);
    
    if (scheduled) {
      _logger.info(
        message: 'Prayer notification scheduled',
        data: {
          'prayer': prayerName,
          'time': prayerTime.toIso8601String(),
          'isReminder': isReminder,
        },
      );
      _analytics.recordNotificationScheduled(notification.id, 'prayer_$prayerName');
    }
    
    return scheduled;
  }

  /// Cancel all prayer notifications
  Future<void> cancelAllPrayerNotifications() async {
    // Cancel notifications from ID 2000 to 2999
    final ids = List.generate(1000, (i) => 2000 + i);
    await _notificationService.cancelNotifications(ids);
    _logger.info(message: 'All prayer notifications cancelled');
  }
}