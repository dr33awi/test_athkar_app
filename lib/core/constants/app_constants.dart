// lib/core/constants/app_constants.dart

/// Generic application constants
class AppConstants {
  // Prevent instantiation
  AppConstants._();
  
  // App Info (Should be overridden by app-specific config)
  static const String appName = 'Flutter App';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // Default Locale
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'ar'];
  
  // Storage Keys
  static const String storagePrefix = 'app_';
  static const String settingsKey = '${storagePrefix}settings';
  static const String userPreferencesKey = '${storagePrefix}user_preferences';
  static const String cacheKey = '${storagePrefix}cache';
  static const String themeKey = '${storagePrefix}theme';
  static const String localeKey = '${storagePrefix}locale';
  static const String onboardingKey = '${storagePrefix}onboarding_completed';
  
  // Notification Channels
  static const String defaultNotificationChannel = 'default_channel';
  static const String highPriorityChannel = 'high_priority_channel';
  static const String reminderChannel = 'reminder_channel';
  static const String serviceChannel = 'service_channel';
  
  // Time Constants
  static const Duration defaultCacheDuration = Duration(hours: 24);
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  
  // Retry Policy
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration maxRetryDelay = Duration(seconds: 30);
  
  // Analytics
  static const int maxAnalyticsEvents = 100;
  static const Duration analyticsFlushInterval = Duration(minutes: 5);
  static const int maxAnalyticsRetries = 3;
  
  // Battery Optimization
  static const int defaultMinBatteryLevel = 15;
  static const int criticalBatteryLevel = 5;
  
  // UI Constants
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  static const double defaultBorderRadius = 8.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultElevation = 4.0;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // File Size Limits
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxVideoSizeBytes = 50 * 1024 * 1024; // 50MB
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  
  // Security
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int sessionTimeoutMinutes = 30;
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  
  // API Endpoints (Base URLs - should be configured per environment)
  static const String apiBaseUrl = 'https://api.example.com/v1';
  static const String cdnBaseUrl = 'https://cdn.example.com';
  
  // Feature Flags (Can be overridden by remote config)
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableDebugMode = false;
}