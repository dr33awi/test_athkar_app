// lib/core/infrastructure/services/device/battery/default_dnd_override_handler.dart

import 'package:athkar_app/core/infrastructure/services/device/do_not_disturb/do_not_disturb_service.dart';

/// Default implementation of DND override handler
class DefaultDoNotDisturbOverrideHandler implements DoNotDisturbOverrideHandler {
  @override
  Future<bool> shouldOverride(Map<String, dynamic>? notificationData) async {
    if (notificationData == null) return false;
    
    // Check priority
    final priority = getOverridePriority(notificationData);
    
    switch (priority) {
      case SystemOverridePriority.critical:
      case SystemOverridePriority.high:
        return true;
      case SystemOverridePriority.medium:
        // Check additional conditions for medium priority
        final isUrgent = notificationData['urgent'] as bool? ?? false;
        final isImportant = notificationData['important'] as bool? ?? false;
        return isUrgent || isImportant;
      case SystemOverridePriority.low:
      case SystemOverridePriority.none:
        return false;
    }
  }
  
  @override
  SystemOverridePriority getOverridePriority(Map<String, dynamic>? notificationData) {
    if (notificationData == null) return SystemOverridePriority.none;
    
    // Check various priority indicators
    final priorityString = notificationData['priority'] as String?;
    final priorityInt = notificationData['priority_level'] as int?;
    final isCritical = notificationData['critical'] as bool? ?? false;
    final isUrgent = notificationData['urgent'] as bool? ?? false;
    final isImportant = notificationData['important'] as bool? ?? false;
    
    // String-based priority
    if (priorityString != null) {
      switch (priorityString.toLowerCase()) {
        case 'critical':
        case 'emergency':
          return SystemOverridePriority.critical;
        case 'high':
        case 'urgent':
          return SystemOverridePriority.high;
        case 'medium':
        case 'normal':
          return SystemOverridePriority.medium;
        case 'low':
          return SystemOverridePriority.low;
        default:
          return SystemOverridePriority.none;
      }
    }
    
    // Integer-based priority (0-4 scale)
    if (priorityInt != null) {
      if (priorityInt >= 4) return SystemOverridePriority.critical;
      if (priorityInt >= 3) return SystemOverridePriority.high;
      if (priorityInt >= 2) return SystemOverridePriority.medium;
      if (priorityInt >= 1) return SystemOverridePriority.low;
      return SystemOverridePriority.none;
    }
    
    // Boolean flags
    if (isCritical) return SystemOverridePriority.critical;
    if (isUrgent) return SystemOverridePriority.high;
    if (isImportant) return SystemOverridePriority.medium;
    
    return SystemOverridePriority.none;
  }
}