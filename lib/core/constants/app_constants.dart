// lib/core/constants/app_constants.dart

/// ثوابت التطبيق الخاصة بتطبيق الأذكار
class AppConstants {
  AppConstants._();
  
  // معلومات التطبيق
  static const String appName = 'تطبيق الأذكار';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // اللغة الافتراضية
  static const String defaultLanguage = 'ar';
  static const List<String> supportedLanguages = ['ar', 'en'];
  
  // مفاتيح التخزين
  static const String storagePrefix = 'athkar_';
  static const String settingsKey = '${storagePrefix}settings';
  static const String userPreferencesKey = '${storagePrefix}user_preferences';
  static const String themeKey = '${storagePrefix}theme';
  static const String localeKey = '${storagePrefix}locale';
  static const String onboardingKey = '${storagePrefix}onboarding_completed';
  static const String favoritesKey = '${storagePrefix}favorites';
  static const String athkarProgressKey = '${storagePrefix}athkar_progress';
  static const String lastReadKey = '${storagePrefix}last_read';
  
  // قنوات الإشعارات
  static const String athkarNotificationChannel = 'athkar_channel';
  static const String prayerNotificationChannel = 'prayer_channel';
  
  // ثوابت الوقت
  static const Duration defaultCacheDuration = Duration(hours: 24);
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  
  // إعدادات البطارية
  static const int defaultMinBatteryLevel = 15;
  static const int criticalBatteryLevel = 5;
  
  // ثوابت واجهة المستخدم
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const double defaultBorderRadius = 8.0;
  static const double defaultPadding = 16.0;
  
  // الصفحات
  static const int defaultPageSize = 20;
  
  // ميزات التطبيق
  static const bool enableAthkarReminders = true;
  static const bool enablePrayerTimes = true;
  static const bool enableQibla = true;
  static const bool enableTasbih = true;
}