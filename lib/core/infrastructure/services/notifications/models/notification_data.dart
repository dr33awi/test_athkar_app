// lib/core/infrastructure/services/notifications/models/notification_data.dart

/// فترات تكرار الإشعارات
enum NotificationRepeatInterval {
  once,
  daily,
  weekly,
  custom,
}

/// مستويات أولوية الإشعارات
enum NotificationPriority {
  low,
  normal,
  high,
}

/// فئات إشعارات تطبيق الأذكار
enum NotificationCategory {
  athkarReminder,    // تذكيرات الأذكار اليومية
  prayerTime,        // إشعارات مواقيت الصلاة
  specialEvent,      // المناسبات الدينية (رمضان، العيد، إلخ)
}

/// بيانات الإشعار
class NotificationData {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final NotificationRepeatInterval repeatInterval;
  final NotificationCategory category;
  final NotificationPriority priority;
  final String channelId;
  final Map<String, dynamic>? payload;
  final bool playSound;
  final bool enableVibration;
  final List<NotificationAction>? actions;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.repeatInterval = NotificationRepeatInterval.once,
    this.category = NotificationCategory.athkarReminder,
    this.priority = NotificationPriority.normal,
    this.channelId = 'athkar_channel',
    this.payload,
    this.playSound = false,
    this.enableVibration = true,
    this.actions,
  });

  NotificationData copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? scheduledDate,
    NotificationRepeatInterval? repeatInterval,
    NotificationCategory? category,
    NotificationPriority? priority,
    String? channelId,
    Map<String, dynamic>? payload,
    bool? playSound,
    bool? enableVibration,
    List<NotificationAction>? actions,
  }) {
    return NotificationData(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      channelId: channelId ?? this.channelId,
      payload: payload ?? this.payload,
      playSound: playSound ?? this.playSound,
      enableVibration: enableVibration ?? this.enableVibration,
      actions: actions ?? this.actions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate.toIso8601String(),
      'repeatInterval': repeatInterval.index,
      'category': category.index,
      'priority': priority.index,
      'channelId': channelId,
      'payload': payload,
      'playSound': playSound,
      'enableVibration': enableVibration,
      'actions': actions?.map((a) => a.toJson()).toList(),
    };
  }

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      repeatInterval: NotificationRepeatInterval.values[json['repeatInterval'] as int? ?? 0],
      category: NotificationCategory.values[json['category'] as int? ?? 0],
      priority: NotificationPriority.values[json['priority'] as int? ?? 1],
      channelId: json['channelId'] as String? ?? 'athkar_channel',
      payload: json['payload'] as Map<String, dynamic>?,
      playSound: json['playSound'] as bool? ?? false,
      enableVibration: json['enableVibration'] as bool? ?? true,
      actions: (json['actions'] as List?)
          ?.map((a) => NotificationAction.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// إجراء الإشعار
class NotificationAction {
  final String id;
  final String title;

  NotificationAction({
    required this.id,
    required this.title,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      id: json['id'] as String,
      title: json['title'] as String,
    );
  }
}

/// قناة الإشعارات
class NotificationChannel {
  final String id;
  final String name;
  final String? description;
  final NotificationPriority importance;
  final bool playSound;
  final bool enableVibration;
  final bool showBadge;

  NotificationChannel({
    required this.id,
    required this.name,
    this.description,
    this.importance = NotificationPriority.normal,
    this.playSound = false,
    this.enableVibration = true,
    this.showBadge = true,
  });
}