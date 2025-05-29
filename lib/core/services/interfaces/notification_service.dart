// lib/core/services/interfaces/notification_service.dart

/// نوع تكرار الإشعارات
enum NotificationRepeatInterval {
  daily,
  weekly,
  monthly,
}

/// وقت إرسال الإشعار
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

/// أولوية الإشعار
enum NotificationPriority {
  low,
  normal,
  high,
  critical,
}

/// ظهور الإشعار في شاشة القفل
enum NotificationVisibility {
  public,
  secret,
  private,
}

/// بيانات الإشعار
class NotificationData {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final NotificationRepeatInterval? repeatInterval;
  final NotificationTime notificationTime;
  final NotificationPriority priority;
  final bool respectBatteryOptimizations;
  final bool respectDoNotDisturb;
  final String? soundName;
  final String channelId;
  final String? payload; // <--- تم التعديل: النوع الآن String?
  final NotificationVisibility visibility;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.repeatInterval,
    this.notificationTime = NotificationTime.custom,
    this.priority = NotificationPriority.normal,
    this.respectBatteryOptimizations = true,
    this.respectDoNotDisturb = true,
    this.soundName,
    this.channelId = 'default_channel',
    this.payload,
    this.visibility = NotificationVisibility.public,
  });
}

/// كلاس لتمثيل إجراء الإشعار
class NotificationAction {
  final String id;
  final String title;
  final bool? showsUserInterface; // <--- تم التعديل: إعادة الخاصية كاختيارية
  final bool? cancelNotification; // <--- تم التعديل: إعادة الخاصية كاختيارية

  NotificationAction({
    required this.id,
    required this.title,
    this.showsUserInterface,
    this.cancelNotification,
  });
}

/// واجهة خدمة الإشعارات
abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<bool> scheduleNotification(NotificationData notification);
  Future<bool> scheduleNotificationInTimeZone(
    NotificationData notification,
    String timeZoneId,
  );
  Future<bool> scheduleNotificationWithActions(
    NotificationData notification,
    List<NotificationAction> actions,
  );
  Future<void> cancelNotification(int id);
  Future<void> cancelNotificationsByIds(List<int> ids);
  Future<void> cancelNotificationsByTag(String tag);
  Future<void> cancelAllNotifications();
  Future<void> setRespectBatteryOptimizations(bool enabled);
  Future<void> setRespectDoNotDisturb(bool enabled);
  Future<bool> canSendNotificationsNow();
  Future<void> dispose();
}