// lib/core/infrastructure/services/configuration/config_keys.dart

/// Configuration keys used throughout the application
/// Organized by category for better maintainability
class ConfigKeys {
  ConfigKeys._();
  
  // API Configuration
  static const String apiBaseUrl = 'api.base_url';
  static const String apiTimeout = 'api.timeout';
  static const String apiRetryCount = 'api.retry_count';
  static const String apiRetryDelay = 'api.retry_delay';
  static const String apiKey = 'api.key';
  static const String apiVersion = 'api.version';
  
  // App Configuration
  static const String appName = 'app.name';
  static const String appVersion = 'app.version';
  static const String appBuildNumber = 'app.build_number';
  static const String appEnvironment = 'app.environment';
  static const String appDebugMode = 'app.debug_mode';
  static const String appLogLevel = 'app.log_level';
  
  // Feature Flags
  static const String featureAnalytics = 'feature.analytics';
  static const String featureCrashlytics = 'feature.crashlytics';
  static const String featurePerformance = 'feature.performance';
  static const String featureOfflineMode = 'feature.offline_mode';
  static const String featureDebugMode = 'feature.debug_mode';
  static const String featureRemoteConfig = 'feature.remote_config';
  static const String featurePrayerNotifications = 'feature.prayer_notifications';
  static const String featureAthkarReminders = 'feature.athkar_reminders';
  
  // UI Configuration
  static const String uiTheme = 'ui.theme';
  static const String uiLanguage = 'ui.language';
  static const String uiAnimationSpeed = 'ui.animation_speed';
  static const String uiFontSize = 'ui.font_size';
  static const String uiShowOnboarding = 'ui.show_onboarding';
  static const String uiArabicCalligraphy = 'ui.arabic_calligraphy';
  
  // Storage Configuration
  static const String storageCacheEnabled = 'storage.cache_enabled';
  static const String storageCacheDuration = 'storage.cache_duration';
  static const String storageEncryptionEnabled = 'storage.encryption_enabled';
  static const String storageMaxSize = 'storage.max_size';
  
  // Notification Configuration
  static const String notificationEnabled = 'notification.enabled';
  static const String notificationSound = 'notification.sound';
  static const String notificationVibration = 'notification.vibration';
  static const String notificationLed = 'notification.led';
  static const String notificationMinInterval = 'notification.min_interval';
  static const String notificationPrayerOffset = 'notification.prayer_offset';
  static const String notificationAthkarTime = 'notification.athkar_time';
  
  // Security Configuration
  static const String securityPinEnabled = 'security.pin_enabled';
  static const String securityBiometricEnabled = 'security.biometric_enabled';
  static const String securitySessionTimeout = 'security.session_timeout';
  static const String securityMaxLoginAttempts = 'security.max_login_attempts';
  
  // Privacy Configuration
  static const String privacyCollectAnalytics = 'privacy.collect_analytics';
  static const String privacyCollectCrashReports = 'privacy.collect_crash_reports';
  static const String privacyShareData = 'privacy.share_data';
  
  // Performance Configuration
  static const String performanceImageCaching = 'performance.image_caching';
  static const String performanceDataPrefetch = 'performance.data_prefetch';
  static const String performanceLazyLoading = 'performance.lazy_loading';
  
  // Prayer Times Configuration
  static const String prayerCalculationMethod = 'prayer.calculation_method';
  static const String prayerAsrMethod = 'prayer.asr_method';
  static const String prayerHighLatitudeRule = 'prayer.high_latitude_rule';
  static const String prayerTimeAdjustments = 'prayer.time_adjustments';
  
  // Athkar Configuration
  static const String athkarMorningTime = 'athkar.morning_time';
  static const String athkarEveningTime = 'athkar.evening_time';
  static const String athkarDailyReminders = 'athkar.daily_reminders';
  static const String athkarVibrationEnabled = 'athkar.vibration_enabled';
  static const String athkarSoundEnabled = 'athkar.sound_enabled';
  
  // Location Configuration
  static const String locationAutoUpdate = 'location.auto_update';
  static const String locationUpdateInterval = 'location.update_interval';
  static const String locationDefaultLatitude = 'location.default_latitude';
  static const String locationDefaultLongitude = 'location.default_longitude';
  static const String locationDefaultCity = 'location.default_city';
  static const String locationDefaultCountry = 'location.default_country';
}

/// Configuration sections for grouping related settings
class ConfigSections {
  ConfigSections._();
  
  static const String api = 'api';
  static const String app = 'app';
  static const String feature = 'feature';
  static const String ui = 'ui';
  static const String storage = 'storage';
  static const String notification = 'notification';
  static const String security = 'security';
  static const String privacy = 'privacy';
  static const String performance = 'performance';
  static const String prayer = 'prayer';
  static const String athkar = 'athkar';
  static const String location = 'location';
}

/// Default configuration values
class ConfigDefaults {
  ConfigDefaults._();
  
  // API Defaults
  static const int apiTimeout = 30; // seconds
  static const int apiRetryCount = 3;
  static const int apiRetryDelay = 2; // seconds
  
  // App Defaults
  static const String appName = 'Athkar App';
  static const String appLanguage = 'ar';
  static const bool appDebugMode = false;
  
  // Notification Defaults
  static const bool notificationEnabled = true;
  static const bool notificationSound = true;
  static const bool notificationVibration = true;
  static const int notificationMinInterval = 60; // minutes
  static const int notificationPrayerOffset = 0; // minutes
  
  // Storage Defaults
  static const bool storageCacheEnabled = true;
  static const int storageCacheDuration = 86400; // seconds (24 hours)
  static const int storageMaxSize = 104857600; // bytes (100 MB)
  
  // Security Defaults
  static const int securitySessionTimeout = 30; // minutes
  static const int securityMaxLoginAttempts = 5;
  
  // Performance Defaults
  static const bool performanceImageCaching = true;
  static const bool performanceDataPrefetch = true;
  static const bool performanceLazyLoading = true;
  
  // Prayer Defaults
  static const String prayerCalculationMethod = 'UmmAlQura';
  static const String prayerAsrMethod = 'Standard';
  static const String prayerHighLatitudeRule = 'MiddleOfTheNight';
  
  // Location Defaults
  static const bool locationAutoUpdate = true;
  static const int locationUpdateInterval = 3600; // seconds (1 hour)
}