// lib/core/constants/app_constants.dart
class AppConstants {
  // App Info
  static const String appName = 'Athkar App';
  static const String appVersion = '1.0.0';
  
  // Default Language
  static const String defaultLanguage = 'ar';
  
  // Storage Keys (Generic)
  static const String settingsKey = 'app_settings';
  static const String userPreferencesKey = 'user_preferences';
  static const String cacheKey = 'app_cache';
  
  // Notification Channels (Generic)
  static const String defaultNotificationChannel = 'default_channel';
  static const String highPriorityChannel = 'high_priority_channel';
  static const String reminderChannel = 'reminder_channel';
  
  // Time Constants
  static const Duration defaultCacheDuration = Duration(hours: 24);
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);
  
  // Retry Policy
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Analytics
  static const int maxAnalyticsEvents = 100;
  static const Duration analyticsFlushInterval = Duration(minutes: 5);
  
  // Battery Optimization
  static const int defaultMinBatteryLevel = 15;
  
  // UI Constants
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const double defaultBorderRadius = 8.0;
  static const double defaultPadding = 16.0;
}