// lib/core/services/notification/models/notification_data.dart

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
  system,
  update,
  promotional,
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
  final List<int>? vibrationPattern;
  final int? color;
  final List<NotificationAction>? actions;
  final Map<String, dynamic>? metadata;

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
    this.vibrationPattern,
    this.color,
    this.actions,
    this.metadata,
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
    List<int>? vibrationPattern,
    int? color,
    List<NotificationAction>? actions,
    Map<String, dynamic>? metadata,
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
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      color: color ?? this.color,
      actions: actions ?? this.actions,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
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
    'vibrationPattern': vibrationPattern,
    'color': color,
    'metadata': metadata,
  };

  factory NotificationData.fromJson(Map<String, dynamic> json) => NotificationData(
    id: json['id'] as int,
    title: json['title'] as String,
    body: json['body'] as String,
    scheduledDate: DateTime.parse(json['scheduledDate'] as String),
    repeatInterval: NotificationRepeatInterval.values[json['repeatInterval'] as int],
    category: NotificationCategory.values[json['category'] as int],
    priority: NotificationPriority.values[json['priority'] as int],
    visibility: NotificationVisibility.values[json['visibility'] as int],
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
    vibrationPattern: (json['vibrationPattern'] as List?)?.cast<int>(),
    color: json['color'] as int?,
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

/// Notification action
class NotificationAction {
  final String id;
  final String title;
  final bool showsUserInterface;
  final bool cancelNotification;
  final String? icon;
  final Map<String, dynamic>? extras;

  NotificationAction({
    required this.id,
    required this.title,
    this.showsUserInterface = true,
    this.cancelNotification = false,
    this.icon,
    this.extras,
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
  final bool enableAnalytics;
  final bool enableRetryOnFailure;
  final int maxRetryAttempts;
  final Duration retryDelay;
  final Map<String, dynamic>? defaultPayload;
  final NotificationPriority? minimumPriorityForDnd;

  NotificationConfig({
    this.enableAnalytics = true,
    this.enableRetryOnFailure = true,
    this.maxRetryAttempts = 3,
    this.retryDelay = const Duration(seconds: 30),
    this.defaultPayload,
    this.minimumPriorityForDnd,
  });
}