// lib/core/infrastructure/services/device/do_not_disturb/do_not_disturb_service.dart

/// System override priority levels
enum SystemOverridePriority {
  none,       // No override
  low,        // Low priority override
  medium,     // Medium priority override
  high,       // High priority override
  critical,   // Critical priority override (always override)
}

/// Do Not Disturb service interface
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
  
  /// Get current DND policy details
  Future<Map<String, dynamic>> getDoNotDisturbPolicy();
  
  /// Set custom override handler
  void setOverrideHandler(DoNotDisturbOverrideHandler? handler);
  
  /// Check if system allows critical alerts
  Future<bool> canShowCriticalAlerts();
  
  /// Get DND schedule (if available)
  Future<DoNotDisturbSchedule?> getDoNotDisturbSchedule();
}

/// DND override handler interface
abstract class DoNotDisturbOverrideHandler {
  /// Determine if a notification should override DND
  Future<bool> shouldOverride(Map<String, dynamic>? notificationData);
  
  /// Get override priority for a notification
  SystemOverridePriority getOverridePriority(Map<String, dynamic>? notificationData);
}

/// DND schedule information
class DoNotDisturbSchedule {
  final bool isEnabled;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final List<int>? activeDays; // 1-7 (Monday-Sunday)
  
  DoNotDisturbSchedule({
    required this.isEnabled,
    this.startTime,
    this.endTime,
    this.activeDays,
  });
}

class TimeOfDay {
  final int hour;
  final int minute;
  
  TimeOfDay({required this.hour, required this.minute});
}