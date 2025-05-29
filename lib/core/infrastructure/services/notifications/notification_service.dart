// lib/core/services/notifications/notification_service.dart

import 'models/notification_data.dart';

/// Generic notification service interface
abstract class NotificationService {
  /// Initialize the notification service
  Future<void> initialize({
    String? defaultIcon,
    NotificationChannel? defaultChannel,
    List<NotificationChannel>? channels,
  });

  /// Request notification permissions
  Future<bool> requestPermission();

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled();

  /// Create notification channel (Android)
  Future<void> createNotificationChannel(NotificationChannel channel);

  /// Delete notification channel (Android)
  Future<void> deleteNotificationChannel(String channelId);

  /// Show immediate notification
  Future<void> showNotification(NotificationData notification);

  /// Schedule a notification
  Future<bool> scheduleNotification(NotificationData notification);

  /// Schedule a notification with timezone
  Future<bool> scheduleNotificationInTimeZone(
    NotificationData notification,
    String timeZoneId,
  );

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id);

  /// Cancel multiple notifications
  Future<void> cancelNotifications(List<int> ids);

  /// Cancel all notifications
  Future<void> cancelAllNotifications();

  /// Cancel notifications by group
  Future<void> cancelNotificationsByGroup(String groupKey);

  /// Get pending notifications
  Future<List<PendingNotification>> getPendingNotifications();

  /// Get active notifications (Android)
  Future<List<ActiveNotification>> getActiveNotifications();

  /// Update notification badge count (iOS)
  Future<void> updateBadgeCount(int count);

  /// Clear notification badge (iOS)
  Future<void> clearBadge();

  /// Set notification tap handler
  void setNotificationTapHandler(Function(NotificationResponse) handler);

  /// Set notification action handler
  void setNotificationActionHandler(
    Function(NotificationResponse) handler,
  );

  /// Dispose resources
  Future<void> dispose();
}