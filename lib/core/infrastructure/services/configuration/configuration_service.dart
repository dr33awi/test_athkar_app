// lib/core/services/configuration/configuration_service.dart

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
  
  /// Load configuration from source
  Future<void> loadConfiguration();
  
  /// Reload configuration
  Future<void> reloadConfiguration();
  
  /// Clear all configuration
  Future<void> clearConfiguration();
  
  /// Check if configuration key exists
  bool hasKey(String key);
  
  /// Get all configuration keys
  Set<String> getAllKeys();
  
  /// Export configuration
  Map<String, dynamic> exportConfiguration();
  
  /// Import configuration
  Future<void> importConfiguration(Map<String, dynamic> config);
}

/// Configuration keys
class ConfigKeys {
  ConfigKeys._();
  
  // API Configuration
  static const String apiBaseUrl = 'api.base_url';
  static const String apiTimeout = 'api.timeout';
  static const String apiRetryCount = 'api.retry_count';
  static const String apiKey = 'api.key';
  
  // App Configuration
  static const String appName = 'app.name';
  static const String appVersion = 'app.version';
  static const String appBuildNumber = 'app.build_number';
  static const String appEnvironment = 'app.environment';
  
  // Feature Flags
  static const String featureAnalytics = 'feature.analytics';
  static const String featureCrashlytics = 'feature.crashlytics';
  static const String featurePerformance = 'feature.performance';
  static const String featureOfflineMode = 'feature.offline_mode';
  static const String featureDebugMode = 'feature.debug_mode';
  
  // UI Configuration
  static const String uiTheme = 'ui.theme';
  static const String uiLanguage = 'ui.language';
  static const String uiAnimationSpeed = 'ui.animation_speed';
  
  // Storage Configuration
  static const String storageCacheEnabled = 'storage.cache_enabled';
  static const String storageCacheDuration = 'storage.cache_duration';
  static const String storageEncryptionEnabled = 'storage.encryption_enabled';
  
  // Notification Configuration
  static const String notificationEnabled = 'notification.enabled';
  static const String notificationSound = 'notification.sound';
  static const String notificationVibration = 'notification.vibration';
  
  // Security Configuration
  static const String securityPinEnabled = 'security.pin_enabled';
  static const String securityBiometricEnabled = 'security.biometric_enabled';
  static const String securitySessionTimeout = 'security.session_timeout';
}