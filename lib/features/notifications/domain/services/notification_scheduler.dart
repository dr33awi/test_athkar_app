// lib/features/notifications/domain/services/notification_scheduler.dart

import 'package:athkar_app/features/prayers/domain/entities/prayer_times.dart';

/// Notification scheduler interface
abstract class NotificationScheduler {
  /// Schedule prayer time notifications
  Future<void> schedulePrayerNotifications({
    required List<PrayerTime> prayerTimes,
    String? soundName,
  });
  
  /// Schedule daily athkar reminder
  Future<void> scheduleAthkarReminder({
    required DateTime time,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  });
  
  /// Schedule recurring notification
  Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required DateTime startTime,
    required Duration interval,
    Map<String, dynamic>? payload,
  });
  
  /// Cancel prayer notifications
  Future<void> cancelPrayerNotifications();
  
  /// Cancel athkar reminders
  Future<void> cancelAthkarReminders();
  
  /// Cancel specific notification
  Future<void> cancelNotification(int id);
  
  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications();
  
  /// Get scheduled notifications count
  Future<int> getScheduledNotificationsCount();
  
  /// Update notification settings
  Future<void> updateNotificationSettings({
    bool? enablePrayerNotifications,
    bool? enableAthkarReminders,
    String? notificationSound,
    bool? enableVibration,
  });
}