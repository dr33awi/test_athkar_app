// lib/core/constants/app_constants.dart

import '../infrastructure/services/notifications/notification_service.dart';
import '../../app/themes/theme_constants.dart';

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
  
  // قنوات الإشعارات - استخدم من ThemeConstants
  static const String athkarNotificationChannel = ThemeConstants.athkarNotificationChannel;
  static const String prayerNotificationChannel = ThemeConstants.prayerNotificationChannel;
  
  // ثوابت الوقت - استخدم من ThemeConstants
  static const Duration defaultCacheDuration = ThemeConstants.defaultCacheDuration;
  static const Duration splashDuration = ThemeConstants.splashDuration;
  static const Duration debounceDelay = ThemeConstants.debounceDelay;
  
  // إعدادات البطارية - استخدم من ThemeConstants
  static const int defaultMinBatteryLevel = ThemeConstants.defaultMinBatteryLevel;
  static const int criticalBatteryLevel = ThemeConstants.criticalBatteryLevel;
  
  // ثوابت واجهة المستخدم - استخدم من ThemeConstants
  static const Duration defaultAnimationDuration = ThemeConstants.durationNormal;
  static const double defaultBorderRadius = ThemeConstants.radiusMd;
  static const double defaultPadding = ThemeConstants.space4;
  
  // الصفحات
  static const int defaultPageSize = 20;
  
  // ميزات التطبيق
  static const bool enableAthkarReminders = true;
  static const bool enablePrayerTimes = true;
  static const bool enableQibla = true;
  static const bool enableTasbih = true;
}