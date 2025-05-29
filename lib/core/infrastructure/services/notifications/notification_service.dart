// lib/core/infrastructure/services/notifications/notification_service.dart

/// Notification repeat interval
enum NotificationRepeatInterval {
  once,
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

/// Notification time of day
enum NotificationTime {
  morning,
  evening,
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha,
  custom,
}

/// Notification priority levels
enum NotificationPriority {
  min,
  low,
  normal,
  high,
  max,
  critical, // Added critical priority
}

/// Notification visibility on lock screen
enum NotificationVisibility {
  public,
  secret,
  private,
}

/// Generic notification category
enum NotificationCategory {
  general,
  reminder,
  alert,
  message,
  event,
  progress,
  social,
  error,
  transport,
  system,
  service,
  recommendation,
  status,
  alarm,
  call,
  email,
  promo,
  location,
  custom,
}

/// Notification data model
class NotificationData {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final NotificationRepeatInterval repeatInterval;
  final NotificationCategory category;
  final NotificationTime notificationTime;
  final NotificationPriority priority;
  final NotificationVisibility visibility;
  final String channelId;
  final Map<String, dynamic>? payload;
  final String? soundName;
  final String? iconName;
  final String? groupKey;
  final bool showWhen;
  final bool ongoing;
  final bool autoCancel;
  final bool playSound;
  final bool enableVibration;
  final bool enableLights;
  final bool respectBatteryOptimizations;
  final bool respectDoNotDisturb;
  final List<int>? vibrationPattern;
  final int? color;
  final List<NotificationAction>? actions;
  final Map<String, dynamic>? additionalData;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.repeatInterval = NotificationRepeatInterval.once,
    this.category = NotificationCategory.general,
    this.notificationTime = NotificationTime.custom,
    this.priority = NotificationPriority.normal,
    this.visibility = NotificationVisibility.private,
    this.channelId = 'default_channel',
    this.payload,
    this.soundName,
    this.iconName,
    this.groupKey,
    this.showWhen = true,
    this.ongoing = false,
    this.autoCancel = true,
    this.playSound = true,
    this.enableVibration = true,
    this.enableLights = false,
    this.respectBatteryOptimizations = true,
    this.respectDoNotDisturb = true,
    this.vibrationPattern,
    this.color,
    this.actions,
    this.additionalData,
  });

  /// Create a copy with modified values
  NotificationData copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? scheduledDate,
    NotificationRepeatInterval? repeatInterval,
    NotificationCategory? category,
    NotificationTime? notificationTime,
    NotificationPriority? priority,
    NotificationVisibility? visibility,
    String? channelId,
    Map<String, dynamic>? payload,
    String? soundName,
    String? iconName,
    String? groupKey,
    bool? showWhen,
    bool? ongoing,
    bool? autoCancel,
    bool? playSound,
    bool? enableVibration,
    bool? enableLights,
    bool? respectBatteryOptimizations,
    bool? respectDoNotDisturb,
    List<int>? vibrationPattern,
    int? color,
    List<NotificationAction>? actions,
    Map<String, dynamic>? additionalData,
  }) {
    return NotificationData(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      category: category ?? this.category,
      notificationTime: notificationTime ?? this.notificationTime,
      priority: priority ?? this.priority,
      visibility: visibility ?? this.visibility,
      channelId: channelId ?? this.channelId,
      payload: payload ?? this.payload,
      soundName: soundName ?? this.soundName,
      iconName: iconName ?? this.iconName,
      groupKey: groupKey ?? this.groupKey,
      showWhen: showWhen ?? this.showWhen,
      ongoing: ongoing ?? this.ongoing,
      autoCancel: autoCancel ?? this.autoCancel,
      playSound: playSound ?? this.playSound,
      enableVibration: enableVibration ?? this.enableVibration,
      enableLights: enableLights ?? this.enableLights,
      respectBatteryOptimizations: respectBatteryOptimizations ?? this.respectBatteryOptimizations,
      respectDoNotDisturb: respectDoNotDisturb ?? this.respectDoNotDisturb,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      color: color ?? this.color,
      actions: actions ?? this.actions,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}

/// Notification action
class NotificationAction {
  final String id;
  final String title;
  final bool showsUserInterface;
  final bool cancelNotification;
  final String? icon;
  final Map<String, dynamic>? additionalData;

  NotificationAction({
    required this.id,
    required this.title,
    this.showsUserInterface = true,
    this.cancelNotification = false,
    this.icon,
    this.additionalData,
  });
}

/// Notification channel configuration
class NotificationChannel {
  final String id;
  final String name;
  final String? description;
  final NotificationPriority importance;
  final bool playSound;
  final bool enableVibration;
  final bool enableLights;
  final bool showBadge;
  final String? soundName;
  final List<int>? vibrationPattern;
  final int? lightColor;

  NotificationChannel({
    required this.id,
    required this.name,
    this.description,
    this.importance = NotificationPriority.normal,
    this.playSound = true,
    this.enableVibration = true,
    this.enableLights = false,
    this.showBadge = true,
    this.soundName,
    this.vibrationPattern,
    this.lightColor,
  });
}

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

/// Pending notification info
class PendingNotification {
  final int id;
  final String? title;
  final String? body;
  final Map<String, dynamic>? payload;

  PendingNotification({
    required this.id,
    this.title,
    this.body,
    this.payload,
  });
}

/// Active notification info (Android)
class ActiveNotification {
  final int id;
  final String? channelId;
  final String? title;
  final String? body;
  final Map<String, dynamic>? payload;

  ActiveNotification({
    required this.id,
    this.channelId,
    this.title,
    this.body,
    this.payload,
  });
}

/// Notification response
class NotificationResponse {
  final int? id;
  final String? actionId;
  final String? input;
  final Map<String, dynamic>? payload;
  final NotificationResponseType type;

  NotificationResponse({
    this.id,
    this.actionId,
    this.input,
    this.payload,
    required this.type,
  });
}

/// Notification response type
enum NotificationResponseType {
  selectedNotification,
  selectedNotificationAction,
}

/// Base notification configuration
class NotificationConfig {
  final bool respectDoNotDisturb;
  final bool respectBatteryOptimization;
  final bool enableAnalytics;
  final bool enableRetryOnFailure;
  final int maxRetryAttempts;
  final Duration retryDelay;
  final Map<String, dynamic>? defaultPayload;

  NotificationConfig({
    this.respectDoNotDisturb = true,
    this.respectBatteryOptimization = true,
    this.enableAnalytics = true,
    this.enableRetryOnFailure = true,
    this.maxRetryAttempts = 3,
    this.retryDelay = const Duration(seconds: 30),
    this.defaultPayload,
  });
}