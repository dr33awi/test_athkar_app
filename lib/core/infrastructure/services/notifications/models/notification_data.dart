// lib/core/infrastructure/services/notifications/models/notification_data.dart

/// Generic notification repeat interval
enum NotificationRepeatInterval {
  once,
  hourly,
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

/// Generic notification priority levels
enum NotificationPriority {
  min,
  low,
  normal,
  high,
  max,
  critical,
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

/// Generic notification data model
class NotificationData {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final NotificationRepeatInterval repeatInterval;
  final NotificationCategory category;
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
  final bool respectSystemSettings;
  final List<int>? vibrationPattern;
  final int? color;
  final List<NotificationAction>? actions;
  final Map<String, dynamic>? additionalData;
  
  // Custom scheduling data that features can use
  final Map<String, dynamic>? customSchedulingData;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.repeatInterval = NotificationRepeatInterval.once,
    this.category = NotificationCategory.general,
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
    this.respectSystemSettings = true,
    this.vibrationPattern,
    this.color,
    this.actions,
    this.additionalData,
    this.customSchedulingData,
  });

  /// Create a copy with modified values
  NotificationData copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? scheduledDate,
    NotificationRepeatInterval? repeatInterval,
    NotificationCategory? category,
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
    bool? respectSystemSettings,
    List<int>? vibrationPattern,
    int? color,
    List<NotificationAction>? actions,
    Map<String, dynamic>? additionalData,
    Map<String, dynamic>? customSchedulingData,
  }) {
    return NotificationData(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      category: category ?? this.category,
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
      respectSystemSettings: respectSystemSettings ?? this.respectSystemSettings,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      color: color ?? this.color,
      actions: actions ?? this.actions,
      additionalData: additionalData ?? this.additionalData,
      customSchedulingData: customSchedulingData ?? this.customSchedulingData,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate.toIso8601String(),
      'repeatInterval': repeatInterval.index,
      'category': category.index,
      'priority': priority.index,
      'visibility': visibility.index,
      'channelId': channelId,
      'payload': payload,
      'soundName': soundName,
      'iconName': iconName,
      'groupKey': groupKey,
      'showWhen': showWhen,
      'ongoing': ongoing,
      'autoCancel': autoCancel,
      'playSound': playSound,
      'enableVibration': enableVibration,
      'enableLights': enableLights,
      'respectSystemSettings': respectSystemSettings,
      'vibrationPattern': vibrationPattern,
      'color': color,
      'actions': actions?.map((a) => a.toJson()).toList(),
      'additionalData': additionalData,
      'customSchedulingData': customSchedulingData,
    };
  }

  /// Create from JSON
  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      repeatInterval: NotificationRepeatInterval.values[json['repeatInterval'] as int? ?? 0],
      category: NotificationCategory.values[json['category'] as int? ?? 0],
      priority: NotificationPriority.values[json['priority'] as int? ?? 2],
      visibility: NotificationVisibility.values[json['visibility'] as int? ?? 2],
      channelId: json['channelId'] as String? ?? 'default_channel',
      payload: json['payload'] as Map<String, dynamic>?,
      soundName: json['soundName'] as String?,
      iconName: json['iconName'] as String?,
      groupKey: json['groupKey'] as String?,
      showWhen: json['showWhen'] as bool? ?? true,
      ongoing: json['ongoing'] as bool? ?? false,
      autoCancel: json['autoCancel'] as bool? ?? true,
      playSound: json['playSound'] as bool? ?? true,
      enableVibration: json['enableVibration'] as bool? ?? true,
      enableLights: json['enableLights'] as bool? ?? false,
      respectSystemSettings: json['respectSystemSettings'] as bool? ?? true,
      vibrationPattern: (json['vibrationPattern'] as List?)?.cast<int>(),
      color: json['color'] as int?,
      actions: (json['actions'] as List?)
          ?.map((a) => NotificationAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      customSchedulingData: json['customSchedulingData'] as Map<String, dynamic>?,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'showsUserInterface': showsUserInterface,
      'cancelNotification': cancelNotification,
      'icon': icon,
      'additionalData': additionalData,
    };
  }

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      id: json['id'] as String,
      title: json['title'] as String,
      showsUserInterface: json['showsUserInterface'] as bool? ?? true,
      cancelNotification: json['cancelNotification'] as bool? ?? false,
      icon: json['icon'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }
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
  final bool respectSystemSettings;
  final bool enableAnalytics;
  final bool enableRetryOnFailure;
  final int maxRetryAttempts;
  final Duration retryDelay;
  final Map<String, dynamic>? defaultPayload;
  
  // System constraint handlers
  final SystemConstraintHandler? systemConstraintHandler;

  NotificationConfig({
    this.respectSystemSettings = true,
    this.enableAnalytics = true,
    this.enableRetryOnFailure = true,
    this.maxRetryAttempts = 3,
    this.retryDelay = const Duration(seconds: 30),
    this.defaultPayload,
    this.systemConstraintHandler,
  });
}

/// Abstract handler for system constraints
abstract class SystemConstraintHandler {
  /// Check if notification should be sent based on system constraints
  Future<bool> shouldSendNotification(NotificationData notification);
  
  /// Get override priority based on notification data
  SystemOverridePriority getOverridePriority(NotificationData notification);
}

/// System override priority levels
enum SystemOverridePriority {
  none,
  low,
  medium,
  high,
  critical,
}