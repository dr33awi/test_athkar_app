// lib/core/infrastructure/services/notifications/notification_service.dart

import 'models/notification_data.dart';

/// Generic notification service interface
abstract class NotificationService {
  /// Initialize the notification service
  Future<void> initialize({
    String? defaultIcon,
    NotificationChannel? defaultChannel,
    List<NotificationChannel>? channels,
    NotificationConfig? config,
  });

  /// Request notification permissions
  Future<bool> requestPermission();

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled();

  /// Create notification channel (Android)
  Future<void> createNotificationChannel(NotificationChannel channel);

  /// Delete notification channel (Android)
  Future<void> deleteNotificationChannel(String channelId);
  
  /// Get all notification channels (Android)
  Future<List<NotificationChannel>> getNotificationChannels();

  /// Show immediate notification
  Future<void> showNotification(NotificationData notification);
  
  /// Show progress notification
  Future<void> showProgressNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    int maxProgress = 100,
    bool indeterminate = false,
    String? channelId,
  });
  
  /// Show grouped notifications
  Future<void> showGroupedNotification({
    required String groupKey,
    required List<NotificationData> notifications,
    required NotificationData summary,
  });

  /// Schedule a notification
  Future<bool> scheduleNotification(NotificationData notification);

  /// Schedule a notification with timezone
  Future<bool> scheduleNotificationInTimeZone(
    NotificationData notification,
    String timeZoneId,
  );
  
  /// Schedule repeating notification
  Future<bool> scheduleRepeatingNotification(
    NotificationData notification,
    Duration interval,
  );

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id);

  /// Cancel multiple notifications
  Future<void> cancelNotifications(List<int> ids);

  /// Cancel all notifications
  Future<void> cancelAllNotifications();

  /// Cancel notifications by group
  Future<void> cancelNotificationsByGroup(String groupKey);
  
  /// Cancel notifications by tag
  Future<void> cancelNotificationsByTag(String tag);

  /// Get pending notifications
  Future<List<PendingNotification>> getPendingNotifications();

  /// Get active notifications (Android)
  Future<List<ActiveNotification>> getActiveNotifications();

  /// Update notification badge count (iOS)
  Future<void> updateBadgeCount(int count);

  /// Clear notification badge (iOS)
  Future<void> clearBadge();

  /// Set notification tap handler
  void setNotificationTapHandler(Function(AppNotificationResponse) handler);

  /// Set notification action handler
  void setNotificationActionHandler(Function(AppNotificationResponse) handler);
  
  /// Set notification received handler (foreground)
  void setNotificationReceivedHandler(Function(NotificationData) handler);
  
  /// Get notification analytics
  Map<String, dynamic> getAnalytics();
  
  /// Configure notification behavior
  void setConfiguration(NotificationConfig config);

  /// Dispose resources
  Future<void> dispose();
}

