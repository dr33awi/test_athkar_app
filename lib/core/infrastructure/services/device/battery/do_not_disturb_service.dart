// lib/core/infrastructure/services/device/do_not_disturb/do_not_disturb_service.dart

/// Generic system override priority
enum SystemOverridePriority {
  none,       // No override
  low,        // Low priority override
  medium,     // Medium priority override
  high,       // High priority override
  critical,   // Critical priority override (always override)
}

abstract class DoNotDisturbService {
  /// Check if Do Not Disturb is enabled
  Future<bool> isDoNotDisturbEnabled();
  
  /// Request Do Not Disturb permission
  Future<bool> requestDoNotDisturbPermission();
  
  /// Open Do Not Disturb settings
  Future<void> openDoNotDisturbSettings();
  
  /// Register listener for DND state changes
  Future<void> registerDoNotDisturbListener(Function(bool) onDoNotDisturbChange);
  
  /// Unregister DND listener
  Future<void> unregisterDoNotDisturbListener();
  
  /// Check if notification should override DND based on priority
  Future<bool> shouldOverrideDoNotDisturb(SystemOverridePriority priority);
  
  /// Get current DND policy details (if available)
  Future<Map<String, dynamic>> getDoNotDisturbPolicy();
  
  /// Set custom override handler (for feature-specific logic)
  void setOverrideHandler(DoNotDisturbOverrideHandler? handler);
}

/// Abstract handler for custom DND override logic
abstract class DoNotDisturbOverrideHandler {
  /// Determine if a notification should override DND
  Future<bool> shouldOverride(Map<String, dynamic>? notificationData);
  
  /// Get override priority for a notification
  SystemOverridePriority getOverridePriority(Map<String, dynamic>? notificationData);
}