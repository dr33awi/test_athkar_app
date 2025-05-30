// lib/features/notifications/infrastructure/services/notification_scheduler_impl.dart

import 'package:athkar_app/features/prayers/domain/entities/prayer_times.dart';

import '../../../../core/infrastructure/services/logging/logger_service.dart';
import '../../../../core/infrastructure/services/notifications/notification_service.dart';
import '../../../../core/infrastructure/services/notifications/models/notification_data.dart';
import '../../../prayers/domain/services/prayer_times_service.dart';
import '../../domain/services/notification_scheduler.dart';

/// Implementation of notification scheduler
class NotificationSchedulerImpl implements NotificationScheduler {
  final NotificationService _notificationService;
  final PrayerTimesService _prayerTimesService;
  final LoggerService? _logger;
  
  // Notification ID ranges
  static const int _prayerNotificationIdStart = 1000;
  static const int _athkarNotificationIdStart = 2000;
  static const int _recurringNotificationIdStart = 3000;
  
  // Notification channels
  static const String _prayerChannelId = 'prayer_notifications';
  static const String _athkarChannelId = 'athkar_reminders';
  
  NotificationSchedulerImpl({
    required NotificationService notificationService,
    required PrayerTimesService prayerTimesService,
    LoggerService? logger,
  })  : _notificationService = notificationService,
        _prayerTimesService = prayerTimesService,
        _logger = logger {
    _initializeChannels();
  }
  
  Future<void> _initializeChannels() async {
    // Create prayer notification channel
    await _notificationService.createNotificationChannel(
      NotificationChannel(
        id: _prayerChannelId,
        name: 'تنبيهات الصلاة',
        description: 'تنبيهات أوقات الصلاة',
        importance: NotificationPriority.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    
    // Create athkar reminder channel
    await _notificationService.createNotificationChannel(
      NotificationChannel(
        id: _athkarChannelId,
        name: 'تذكير الأذكار',
        description: 'تذكيرات الأذكار اليومية',
        importance: NotificationPriority.normal,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
  }
  
  @override
  Future<void> schedulePrayerNotifications({
    required List<PrayerTime> prayerTimes,
    String? soundName,
  }) async {
    try {
      _logger?.info(
        message: 'Scheduling prayer notifications',
        data: {'count': prayerTimes.length},
      );
      
      // Cancel existing prayer notifications
      await cancelPrayerNotifications();
      
      // Schedule notifications for each prayer
      for (int i = 0; i < prayerTimes.length; i++) {
        final prayer = prayerTimes[i];
        
        if (!prayer.isNotificationEnabled || prayer.id == 'sunrise') {
          continue;
        }
        
        final notificationId = _prayerNotificationIdStart + i;
        final notificationTime = prayer.notificationOffset != null
            ? prayer.time.add(Duration(minutes: prayer.notificationOffset!))
            : prayer.time;
        
        final notification = NotificationData(
          id: notificationId,
          title: 'حان وقت ${prayer.name}',
          body: 'حان الآن وقت صلاة ${prayer.name}',
          scheduledDate: notificationTime,
          category: NotificationCategory.alarm,
          priority: NotificationPriority.high,
          channelId: _prayerChannelId,
          soundName: soundName,
          payload: {
            'type': 'prayer',
            'prayer_id': prayer.id,
            'prayer_name': prayer.name,
            'prayer_time': prayer.time.toIso8601String(),
          },
          showWhen: true,
          playSound: true,
          enableVibration: true,
          autoCancel: false,
        );
        
        await _notificationService.scheduleNotification(notification);
      }
      
      _logger?.info(message: 'Prayer notifications scheduled successfully');
      
    } catch (e, s) {
      _logger?.error(
        message: 'Error scheduling prayer notifications',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
  
  @override
  Future<void> scheduleAthkarReminder({
    required DateTime time,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    try {
      _logger?.info(
        message: 'Scheduling athkar reminder',
        data: {
          'time': time.toIso8601String(),
          'title': title,
        },
      );
      
      final notificationId = _athkarNotificationIdStart + time.millisecondsSinceEpoch % 1000;
      
      final notification = NotificationData(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: time,
        repeatInterval: NotificationRepeatInterval.daily,
        category: NotificationCategory.reminder,
        priority: NotificationPriority.normal,
        channelId: _athkarChannelId,
        payload: {
          'type': 'athkar_reminder',
          ...?payload,
        },
        showWhen: true,
        playSound: true,
        enableVibration: true,
      );
      
      await _notificationService.scheduleNotification(notification);
      
      _logger?.info(message: 'Athkar reminder scheduled successfully');
      
    } catch (e, s) {
      _logger?.error(
        message: 'Error scheduling athkar reminder',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
  
  @override
  Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required DateTime startTime,
    required Duration interval,
    Map<String, dynamic>? payload,
  }) async {
    try {
      _logger?.info(
        message: 'Scheduling recurring notification',
        data: {
          'id': id,
          'title': title,
          'interval': interval.toString(),
        },
      );
      
      final notificationId = _recurringNotificationIdStart + id;
      
      await _notificationService.scheduleRepeatingNotification(
        NotificationData(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: startTime,
          category: NotificationCategory.reminder,
          priority: NotificationPriority.normal,
          channelId: _athkarChannelId,
          payload: {
            'type': 'recurring',
            'id': id,
            ...?payload,
          },
        ),
        interval,
      );
      
      _logger?.info(message: 'Recurring notification scheduled successfully');
      
    } catch (e, s) {
      _logger?.error(
        message: 'Error scheduling recurring notification',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
  
  @override
  Future<void> cancelPrayerNotifications() async {
    try {
      _logger?.info(message: 'Cancelling prayer notifications');
      
      // Cancel notifications in prayer ID range
      final notifications = await _notificationService.getPendingNotifications();
      final prayerNotificationIds = notifications
          .where((n) => n.id >= _prayerNotificationIdStart && n.id < _athkarNotificationIdStart)
          .map((n) => n.id)
          .toList();
      
      await _notificationService.cancelNotifications(prayerNotificationIds);
      
      _logger?.info(
        message: 'Prayer notifications cancelled',
        data: {'count': prayerNotificationIds.length},
      );
      
    } catch (e, s) {
      _logger?.error(
        message: 'Error cancelling prayer notifications',
        error: e,
        stackTrace: s,
      );
    }
  }
  
  @override
  Future<void> cancelAthkarReminders() async {
    try {
      _logger?.info(message: 'Cancelling athkar reminders');
      
      // Cancel notifications in athkar ID range
      final notifications = await _notificationService.getPendingNotifications();
      final athkarNotificationIds = notifications
          .where((n) => n.id >= _athkarNotificationIdStart && n.id < _recurringNotificationIdStart)
          .map((n) => n.id)
          .toList();
      
      await _notificationService.cancelNotifications(athkarNotificationIds);
      
      _logger?.info(
        message: 'Athkar reminders cancelled',
        data: {'count': athkarNotificationIds.length},
      );
      
    } catch (e, s) {
      _logger?.error(
        message: 'Error cancelling athkar reminders',
        error: e,
        stackTrace: s,
      );
    }
  }
  
  @override
  Future<void> cancelNotification(int id) async {
    await _notificationService.cancelNotification(id);
  }
  
  @override
  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }
  
  @override
  Future<int> getScheduledNotificationsCount() async {
    final notifications = await _notificationService.getPendingNotifications();
    return notifications.length;
  }
  
  @override
  Future<void> updateNotificationSettings({
    bool? enablePrayerNotifications,
    bool? enableAthkarReminders,
    String? notificationSound,
    bool? enableVibration,
  }) async {
    try {
      _logger?.info(
        message: 'Updating notification settings',
        data: {
          'enablePrayerNotifications': enablePrayerNotifications,
          'enableAthkarReminders': enableAthkarReminders,
          'notificationSound': notificationSound,
          'enableVibration': enableVibration,
        },
      );
      
      // Update notification configuration
      _notificationService.setConfiguration(
        NotificationConfig(
          defaultPayload: {
            'sound': notificationSound,
            'vibration': enableVibration,
          },
        ),
      );
      
      // Handle prayer notifications toggle
      if (enablePrayerNotifications == false) {
        await cancelPrayerNotifications();
      }
      
      // Handle athkar reminders toggle
      if (enableAthkarReminders == false) {
        await cancelAthkarReminders();
      }
      
      _logger?.info(message: 'Notification settings updated successfully');
      
    } catch (e, s) {
      _logger?.error(
        message: 'Error updating notification settings',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    _logger?.debug(message: 'Disposing NotificationScheduler');
  }
}