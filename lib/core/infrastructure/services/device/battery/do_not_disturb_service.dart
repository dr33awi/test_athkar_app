// lib/core/services/device/do_not_disturb_service.dart

/// Generic DND override priorities
enum DoNotDisturbOverridePriority {
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
  Future<bool> shouldOverrideDoNotDisturb(DoNotDisturbOverridePriority priority);
  
  /// Get current DND policy details (if available)
  Future<Map<String, dynamic>> getDoNotDisturbPolicy();
  
  /// Set custom override rules
  Future<void> setOverrideRules(Map<DoNotDisturbOverridePriority, bool> rules);
  
  /// Get override statistics
  Future<Map<String, dynamic>> getOverrideStats();
}