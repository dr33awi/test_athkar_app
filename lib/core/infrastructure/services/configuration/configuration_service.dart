// lib/core/infrastructure/services/configuration/configuration_service.dart

/// Environment types
enum Environment {
  development,
  staging,
  production,
}

/// Application configuration service
abstract class ConfigurationService {
  /// Get current environment
  Environment get environment;
  
  /// Get configuration value
  T? getValue<T>(String key, {T? defaultValue});
  
  /// Get string configuration
  String? getString(String key, {String? defaultValue});
  
  /// Get integer configuration
  int? getInt(String key, {int? defaultValue});
  
  /// Get double configuration
  double? getDouble(String key, {double? defaultValue});
  
  /// Get boolean configuration
  bool getBool(String key, {bool defaultValue = false});
  
  /// Get list configuration
  List<T>? getList<T>(String key, {List<T>? defaultValue});
  
  /// Get map configuration
  Map<String, dynamic>? getMap(String key, {Map<String, dynamic>? defaultValue});
  
  /// Set configuration value
  Future<void> setValue(String key, dynamic value);
  
  /// Set multiple values
  Future<void> setValues(Map<String, dynamic> values);
  
  /// Load configuration from source
  Future<void> loadConfiguration();
  
  /// Load configuration from JSON string
  Future<void> loadFromJson(String jsonString);
  
  /// Reload configuration
  Future<void> reloadConfiguration();
  
  /// Clear all configuration
  Future<void> clearConfiguration();
  
  /// Clear specific configuration section
  Future<void> clearSection(String section);
  
  /// Check if configuration key exists
  bool hasKey(String key);
  
  /// Get all configuration keys
  Set<String> getAllKeys();
  
  /// Get all keys in a section
  Set<String> getSectionKeys(String section);
  
  /// Export configuration
  Map<String, dynamic> exportConfiguration();
  
  /// Export specific section
  Map<String, dynamic> exportSection(String section);
  
  /// Import configuration
  Future<void> importConfiguration(Map<String, dynamic> config);
  
  /// Add configuration change listener
  void addChangeListener(String key, Function(dynamic) listener);
  
  /// Remove configuration change listener
  void removeChangeListener(String key, Function(dynamic) listener);
  
  /// Validate configuration
  Future<bool> validateConfiguration();
}

/// Configuration keys
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
  
  // UI Configuration
  static const String uiTheme = 'ui.theme';
  static const String uiLanguage = 'ui.language';
  static const String uiAnimationSpeed = 'ui.animation_speed';
  static const String uiFontSize = 'ui.font_size';
  static const String uiShowOnboarding = 'ui.show_onboarding';
  
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
}