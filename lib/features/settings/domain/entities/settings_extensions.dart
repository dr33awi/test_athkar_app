// lib/features/settings/domain/entities/settings_extensions.dart
import './settings.dart';
import '../../../../core/services/interfaces/notification_service.dart';

/// إضافات لكلاس Settings لدعم الميزات الجديدة
extension SettingsExtensions on Settings {
  /// الحصول على إعدادات أذكار النوم
  List<int> get sleepAthkarTime => [22, 0]; // 10:00 PM افتراضياً
  
  /// التحقق من تفعيل إشعارات أذكار النوم
  bool get enableSleepAthkarNotifications => false; // يمكن تفعيلها لاحقاً
  
  /// الحصول على تعديل وقت الصلاة بالدقائق
  int get prayerTimeAdjustment => 0; // افتراضياً بدون تعديل
  
  /// الحصول على دقائق التذكير قبل الصلاة
  int get prayerReminderMinutes => 15; // افتراضياً 15 دقيقة
  
  /// التحقق من تفعيل تذكيرات الصلاة
  bool get enablePrayerReminders => true;
  
  /// الحصول على أولوية إشعارات الأذكار
  NotificationPriority get athkarNotificationPriority => NotificationPriority.normal;
  
  /// الحصول على الصوت الافتراضي للإشعارات
  String? get defaultNotificationSound => null;
  
  /// الحصول على آخر موقع معروف - خط العرض
  double? get lastKnownLatitude => null;
  
  /// الحصول على آخر موقع معروف - خط الطول
  double? get lastKnownLongitude => null;
}

/// كلاس محدث للإعدادات مع الخصائص الجديدة
class EnhancedSettings extends Settings {
  final List<int> sleepAthkarTime;
  final bool enableSleepAthkarNotifications;
  final int prayerTimeAdjustment;
  final int prayerReminderMinutes;
  final bool enablePrayerReminders;
  final NotificationPriority athkarNotificationPriority;
  final String? defaultNotificationSound;
  final double? lastKnownLatitude;
  final double? lastKnownLongitude;
  
  EnhancedSettings({
    // الخصائص الأساسية من Settings
    bool enableNotifications = true,
    bool enablePrayerTimesNotifications = true,
    bool enableAthkarNotifications = true,
    bool enableDarkMode = false,
    String language = 'ar',
    int calculationMethod = 4,
    int asrMethod = 0,
    bool respectBatteryOptimizations = true,
    bool respectDoNotDisturb = true,
    bool enableHighPriorityForPrayers = true,
    bool enableSilentMode = false,
    int lowBatteryThreshold = 15,
    bool showAthkarReminders = true,
    List<int> morningAthkarTime = const [5, 0],
    List<int> eveningAthkarTime = const [17, 0],
    bool useCustomSounds = false,
    Map<String, String> notificationSounds = const {
      'prayer': 'adhan_sound',
      'athkar_morning': 'morning_athkar_sound',
      'athkar_evening': 'evening_athkar_sound',
      'reminder': 'reminder_sound',
    },
    bool enableActionButtons = true,
    
    // الخصائص الجديدة
    this.sleepAthkarTime = const [22, 0],
    this.enableSleepAthkarNotifications = false,
    this.prayerTimeAdjustment = 0,
    this.prayerReminderMinutes = 15,
    this.enablePrayerReminders = true,
    this.athkarNotificationPriority = NotificationPriority.normal,
    this.defaultNotificationSound,
    this.lastKnownLatitude,
    this.lastKnownLongitude,
  }) : super(
    enableNotifications: enableNotifications,
    enablePrayerTimesNotifications: enablePrayerTimesNotifications,
    enableAthkarNotifications: enableAthkarNotifications,
    enableDarkMode: enableDarkMode,
    language: language,
    calculationMethod: calculationMethod,
    asrMethod: asrMethod,
    respectBatteryOptimizations: respectBatteryOptimizations,
    respectDoNotDisturb: respectDoNotDisturb,
    enableHighPriorityForPrayers: enableHighPriorityForPrayers,
    enableSilentMode: enableSilentMode,
    lowBatteryThreshold: lowBatteryThreshold,
    showAthkarReminders: showAthkarReminders,
    morningAthkarTime: morningAthkarTime,
    eveningAthkarTime: eveningAthkarTime,
    useCustomSounds: useCustomSounds,
    notificationSounds: notificationSounds,
    enableActionButtons: enableActionButtons,
  );
  
  /// إنشاء نسخة محدثة من الإعدادات
  EnhancedSettings copyWith({
    bool? enableNotifications,
    bool? enablePrayerTimesNotifications,
    bool? enableAthkarNotifications,
    bool? enableDarkMode,
    String? language,
    int? calculationMethod,
    int? asrMethod,
    bool? respectBatteryOptimizations,
    bool? respectDoNotDisturb,
    bool? enableHighPriorityForPrayers,
    bool? enableSilentMode,
    int? lowBatteryThreshold,
    bool? showAthkarReminders,
    List<int>? morningAthkarTime,
    List<int>? eveningAthkarTime,
    bool? useCustomSounds,
    Map<String, String>? notificationSounds,
    bool? enableActionButtons,
    List<int>? sleepAthkarTime,
    bool? enableSleepAthkarNotifications,
    int? prayerTimeAdjustment,
    int? prayerReminderMinutes,
    bool? enablePrayerReminders,
    NotificationPriority? athkarNotificationPriority,
    String? defaultNotificationSound,
    double? lastKnownLatitude,
    double? lastKnownLongitude,
  }) {
    return EnhancedSettings(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enablePrayerTimesNotifications: enablePrayerTimesNotifications ?? this.enablePrayerTimesNotifications,
      enableAthkarNotifications: enableAthkarNotifications ?? this.enableAthkarNotifications,
      enableDarkMode: enableDarkMode ?? this.enableDarkMode,
      language: language ?? this.language,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      asrMethod: asrMethod ?? this.asrMethod,
      respectBatteryOptimizations: respectBatteryOptimizations ?? this.respectBatteryOptimizations,
      respectDoNotDisturb: respectDoNotDisturb ?? this.respectDoNotDisturb,
      enableHighPriorityForPrayers: enableHighPriorityForPrayers ?? this.enableHighPriorityForPrayers,
      enableSilentMode: enableSilentMode ?? this.enableSilentMode,
      lowBatteryThreshold: lowBatteryThreshold ?? this.lowBatteryThreshold,
      showAthkarReminders: showAthkarReminders ?? this.showAthkarReminders,
      morningAthkarTime: morningAthkarTime ?? this.morningAthkarTime,
      eveningAthkarTime: eveningAthkarTime ?? this.eveningAthkarTime,
      useCustomSounds: useCustomSounds ?? this.useCustomSounds,
      notificationSounds: notificationSounds ?? this.notificationSounds,
      enableActionButtons: enableActionButtons ?? this.enableActionButtons,
      sleepAthkarTime: sleepAthkarTime ?? this.sleepAthkarTime,
      enableSleepAthkarNotifications: enableSleepAthkarNotifications ?? this.enableSleepAthkarNotifications,
      prayerTimeAdjustment: prayerTimeAdjustment ?? this.prayerTimeAdjustment,
      prayerReminderMinutes: prayerReminderMinutes ?? this.prayerReminderMinutes,
      enablePrayerReminders: enablePrayerReminders ?? this.enablePrayerReminders,
      athkarNotificationPriority: athkarNotificationPriority ?? this.athkarNotificationPriority,
      defaultNotificationSound: defaultNotificationSound ?? this.defaultNotificationSound,
      lastKnownLatitude: lastKnownLatitude ?? this.lastKnownLatitude,
      lastKnownLongitude: lastKnownLongitude ?? this.lastKnownLongitude,
    );
  }
  
  /// تحويل إلى Map للحفظ
  Map<String, dynamic> toJson() {
    return {
      // الخصائص الأساسية
      'enableNotifications': enableNotifications,
      'enablePrayerTimesNotifications': enablePrayerTimesNotifications,
      'enableAthkarNotifications': enableAthkarNotifications,
      'enableDarkMode': enableDarkMode,
      'language': language,
      'calculationMethod': calculationMethod,
      'asrMethod': asrMethod,
      'respectBatteryOptimizations': respectBatteryOptimizations,
      'respectDoNotDisturb': respectDoNotDisturb,
      'enableHighPriorityForPrayers': enableHighPriorityForPrayers,
      'enableSilentMode': enableSilentMode,
      'lowBatteryThreshold': lowBatteryThreshold,
      'showAthkarReminders': showAthkarReminders,
      'morningAthkarTime': morningAthkarTime,
      'eveningAthkarTime': eveningAthkarTime,
      'useCustomSounds': useCustomSounds,
      'notificationSounds': notificationSounds,
      'enableActionButtons': enableActionButtons,
      
      // الخصائص الجديدة
      'sleepAthkarTime': sleepAthkarTime,
      'enableSleepAthkarNotifications': enableSleepAthkarNotifications,
      'prayerTimeAdjustment': prayerTimeAdjustment,
      'prayerReminderMinutes': prayerReminderMinutes,
      'enablePrayerReminders': enablePrayerReminders,
      'athkarNotificationPriority': athkarNotificationPriority.index,
      'defaultNotificationSound': defaultNotificationSound,
      'lastKnownLatitude': lastKnownLatitude,
      'lastKnownLongitude': lastKnownLongitude,
    };
  }
  
  /// إنشاء من Map
  factory EnhancedSettings.fromJson(Map<String, dynamic> json) {
    return EnhancedSettings(
      enableNotifications: json['enableNotifications'] ?? true,
      enablePrayerTimesNotifications: json['enablePrayerTimesNotifications'] ?? true,
      enableAthkarNotifications: json['enableAthkarNotifications'] ?? true,
      enableDarkMode: json['enableDarkMode'] ?? false,
      language: json['language'] ?? 'ar',
      calculationMethod: json['calculationMethod'] ?? 4,
      asrMethod: json['asrMethod'] ?? 0,
      respectBatteryOptimizations: json['respectBatteryOptimizations'] ?? true,
      respectDoNotDisturb: json['respectDoNotDisturb'] ?? true,
      enableHighPriorityForPrayers: json['enableHighPriorityForPrayers'] ?? true,
      enableSilentMode: json['enableSilentMode'] ?? false,
      lowBatteryThreshold: json['lowBatteryThreshold'] ?? 15,
      showAthkarReminders: json['showAthkarReminders'] ?? true,
      morningAthkarTime: List<int>.from(json['morningAthkarTime'] ?? [5, 0]),
      eveningAthkarTime: List<int>.from(json['eveningAthkarTime'] ?? [17, 0]),
      useCustomSounds: json['useCustomSounds'] ?? false,
      notificationSounds: Map<String, String>.from(json['notificationSounds'] ?? {
        'prayer': 'adhan_sound',
        'athkar_morning': 'morning_athkar_sound',
        'athkar_evening': 'evening_athkar_sound',
        'reminder': 'reminder_sound',
      }),
      enableActionButtons: json['enableActionButtons'] ?? true,
      sleepAthkarTime: List<int>.from(json['sleepAthkarTime'] ?? [22, 0]),
      enableSleepAthkarNotifications: json['enableSleepAthkarNotifications'] ?? false,
      prayerTimeAdjustment: json['prayerTimeAdjustment'] ?? 0,
      prayerReminderMinutes: json['prayerReminderMinutes'] ?? 15,
      enablePrayerReminders: json['enablePrayerReminders'] ?? true,
      athkarNotificationPriority: NotificationPriority.values[
        json['athkarNotificationPriority'] ?? NotificationPriority.normal.index
      ],
      defaultNotificationSound: json['defaultNotificationSound'],
      lastKnownLatitude: json['lastKnownLatitude'],
      lastKnownLongitude: json['lastKnownLongitude'],
    );
  }
}