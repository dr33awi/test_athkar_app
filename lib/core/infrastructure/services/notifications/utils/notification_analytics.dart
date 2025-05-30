// lib/core/infrastructure/services/notifications/utils/notification_analytics.dart

import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../../logging/logger_service.dart';

/// System for tracking notification analytics and user interactions
class NotificationAnalytics {
  final LoggerService? _logger;
  
  // Statistics tracking
  final Map<String, int> _scheduledByType = {};
  final Map<int, DateTime> _scheduledTimes = {};
  final Map<String, int> _interactionsByAction = {};
  final Map<int, List<String>> _notificationInteractions = {};
  final Map<String, int> _errorsByType = {};
  final Queue<AnalyticsEvent> _recentEvents = Queue<AnalyticsEvent>();
  final Map<String, int> _suppressionReasons = {};
  
  // Performance metrics
  final Map<String, List<int>> _latencyByType = {};
  final Map<String, int> _deliverySuccess = {};
  final Map<String, int> _deliveryFailure = {};
  
  // Time-based analytics
  final Map<int, List<DateTime>> _hourlyDistribution = {};
  final Map<String, Map<String, int>> _categoryMetrics = {};
  
  // Constants
  static const int _maxRecentEvents = 100;
  static const int _maxLatencyRecords = 50;

  NotificationAnalytics({LoggerService? logger}) : _logger = logger;

  /// Record notification scheduled
  void recordNotificationScheduled(int id, String type) {
    _scheduledByType[type] = (_scheduledByType[type] ?? 0) + 1;
    _scheduledTimes[id] = DateTime.now();
    
    // Track hourly distribution
    final hour = DateTime.now().hour;
    _hourlyDistribution.putIfAbsent(hour, () => []).add(DateTime.now());
    
    // Update category metrics
    _updateCategoryMetric(type, 'scheduled', 1);
    
    _addEvent(AnalyticsEvent(
      type: 'notification_scheduled',
      timestamp: DateTime.now(),
      data: {'id': id, 'type': type},
    ));
    
    _logDebug('Notification scheduled - ID: $id, Type: $type');
  }

  /// Record notification interaction
  void recordNotificationInteraction(int id, String action) {
    _interactionsByAction[action] = (_interactionsByAction[action] ?? 0) + 1;
    
    if (!_notificationInteractions.containsKey(id)) {
      _notificationInteractions[id] = [];
    }
    _notificationInteractions[id]!.add(action);
    
    // Calculate interaction latency
    if (_scheduledTimes.containsKey(id)) {
      final latency = DateTime.now().difference(_scheduledTimes[id]!).inMilliseconds;
      _recordLatency('interaction', latency);
    }
    
    // Update delivery success
    _deliverySuccess[action] = (_deliverySuccess[action] ?? 0) + 1;
    
    _addEvent(AnalyticsEvent(
      type: 'notification_interaction',
      timestamp: DateTime.now(),
      data: {'id': id, 'action': action},
    ));
    
    _logDebug('Notification interaction - ID: $id, Action: $action');
  }

  /// Record error
  void recordError(String errorType, String details) {
    _errorsByType[errorType] = (_errorsByType[errorType] ?? 0) + 1;
    
    // Update delivery failure
    _deliveryFailure[errorType] = (_deliveryFailure[errorType] ?? 0) + 1;
    
    _addEvent(AnalyticsEvent(
      type: 'error',
      timestamp: DateTime.now(),
      data: {'error_type': errorType, 'details': details},
    ));
    
    _logDebug('Error recorded - Type: $errorType, Details: $details');
  }

  /// Record general event
  void recordEvent(String eventType, [Map<String, dynamic>? data]) {
    _addEvent(AnalyticsEvent(
      type: eventType,
      timestamp: DateTime.now(),
      data: data ?? {},
    ));
    
    _logDebug('Event recorded - Type: $eventType');
  }

  /// Record notification suppressed
  void recordNotificationSuppressed(String reason) {
    _suppressionReasons[reason] = (_suppressionReasons[reason] ?? 0) + 1;
    
    _updateCategoryMetric('system', 'suppressed', 1);
    
    _addEvent(AnalyticsEvent(
      type: 'notification_suppressed',
      timestamp: DateTime.now(),
      data: {'reason': reason},
    ));
    
    _logDebug('Notification suppressed - Reason: $reason');
  }
  
  /// Record latency
  void _recordLatency(String type, int milliseconds) {
    _latencyByType.putIfAbsent(type, () => []).add(milliseconds);
    
    // Keep only recent records
    if (_latencyByType[type]!.length > _maxLatencyRecords) {
      _latencyByType[type]!.removeAt(0);
    }
  }
  
  /// Update category metric
  void _updateCategoryMetric(String category, String metric, int value) {
    _categoryMetrics.putIfAbsent(category, () => {});
    _categoryMetrics[category]![metric] = 
        (_categoryMetrics[category]![metric] ?? 0) + value;
  }

  /// Get comprehensive statistics
  Map<String, dynamic> getStats() {
    return {
      'summary': _getSummaryStats(),
      'scheduled': {
        'by_type': Map<String, int>.from(_scheduledByType),
        'total': _scheduledByType.values.fold(0, (a, b) => a + b),
      },
      'interactions': {
        'by_action': Map<String, int>.from(_interactionsByAction),
        'total': _interactionsByAction.values.fold(0, (a, b) => a + b),
        'engagement_rate': _calculateEngagementRate(),
      },
      'errors': {
        'by_type': Map<String, int>.from(_errorsByType),
        'total': _errorsByType.values.fold(0, (a, b) => a + b),
        'error_rate': _calculateErrorRate(),
      },
      'suppressions': {
        'by_reason': Map<String, int>.from(_suppressionReasons),
        'total': _suppressionReasons.values.fold(0, (a, b) => a + b),
      },
      'performance': _getPerformanceMetrics(),
      'distribution': _getDistributionMetrics(),
      'categories': Map<String, Map<String, int>>.from(_categoryMetrics),
      'recent_events': _recentEvents.take(10).map((e) => e.toMap()).toList(),
    };
  }
  
  /// Get summary statistics
  Map<String, dynamic> _getSummaryStats() {
    final totalScheduled = _scheduledByType.values.fold(0, (a, b) => a + b);
    final totalInteractions = _interactionsByAction.values.fold(0, (a, b) => a + b);
    final totalErrors = _errorsByType.values.fold(0, (a, b) => a + b);
    final totalSuppressions = _suppressionReasons.values.fold(0, (a, b) => a + b);
    
    return {
      'total_scheduled': totalScheduled,
      'total_interactions': totalInteractions,
      'total_errors': totalErrors,
      'total_suppressions': totalSuppressions,
      'engagement_rate': _calculateEngagementRate(),
      'success_rate': _calculateSuccessRate(),
      'suppression_rate': totalScheduled > 0 
          ? (totalSuppressions / totalScheduled * 100).toStringAsFixed(2) + '%'
          : '0%',
    };
  }
  
  /// Get performance metrics
  Map<String, dynamic> _getPerformanceMetrics() {
    final metrics = <String, dynamic>{};
    
    // Calculate average latencies
    _latencyByType.forEach((type, latencies) {
      if (latencies.isNotEmpty) {
        final average = latencies.reduce((a, b) => a + b) / latencies.length;
        final min = latencies.reduce((a, b) => a < b ? a : b);
        final max = latencies.reduce((a, b) => a > b ? a : b);
        
        metrics['${type}_latency'] = {
          'average_ms': average.round(),
          'min_ms': min,
          'max_ms': max,
          'samples': latencies.length,
        };
      }
    });
    
    // Delivery metrics
    final totalDeliveryAttempts = 
        _deliverySuccess.values.fold(0, (a, b) => a + b) +
        _deliveryFailure.values.fold(0, (a, b) => a + b);
    
    if (totalDeliveryAttempts > 0) {
      final successCount = _deliverySuccess.values.fold(0, (a, b) => a + b);
      metrics['delivery_success_rate'] = 
          (successCount / totalDeliveryAttempts * 100).toStringAsFixed(2) + '%';
    }
    
    return metrics;
  }
  
  /// Get distribution metrics
  Map<String, dynamic> _getDistributionMetrics() {
    final hourlyStats = <String, int>{};
    
    // Calculate notifications per hour
    _hourlyDistribution.forEach((hour, timestamps) {
      hourlyStats['hour_$hour'] = timestamps.length;
    });
    
    // Find peak hours
    final peakHour = _findPeakHour();
    final quietHour = _findQuietHour();
    
    return {
      'hourly': hourlyStats,
      'peak_hour': peakHour,
      'quiet_hour': quietHour,
    };
  }

  /// Get statistics by type
  Map<String, dynamic> getStatsByType(String type) {
    final interactions = _getInteractionsByType(type);
    final totalInteractions = interactions.values.fold(0, (a, b) => a + b);
    
    return {
      'scheduled_count': _scheduledByType[type] ?? 0,
      'interactions': interactions,
      'interaction_count': totalInteractions,
      'success_rate': _calculateSuccessRate(type),
      'metrics': _categoryMetrics[type] ?? {},
    };
  }

  /// Calculate engagement rate
  double _calculateEngagementRate() {
    final totalScheduled = _scheduledByType.values.fold(0, (a, b) => a + b);
    final totalInteractions = _interactionsByAction.values.fold(0, (a, b) => a + b);
    
    if (totalScheduled == 0) return 0.0;
    return (totalInteractions / totalScheduled * 100);
  }

  /// Calculate success rate
  String _calculateSuccessRate([String? type]) {
    int scheduled = 0;
    int errors = 0;
    
    if (type != null) {
      scheduled = _scheduledByType[type] ?? 0;
      errors = _errorsByType[type] ?? 0;
    } else {
      scheduled = _scheduledByType.values.fold(0, (a, b) => a + b);
      errors = _errorsByType.values.fold(0, (a, b) => a + b);
    }
    
    if (scheduled == 0) return '0%';
    return ((scheduled - errors) / scheduled * 100).toStringAsFixed(2) + '%';
  }
  
  /// Calculate error rate
  String _calculateErrorRate() {
    final totalScheduled = _scheduledByType.values.fold(0, (a, b) => a + b);
    final totalErrors = _errorsByType.values.fold(0, (a, b) => a + b);
    
    if (totalScheduled == 0) return '0%';
    return (totalErrors / totalScheduled * 100).toStringAsFixed(2) + '%';
  }

  /// Get interactions by type
  Map<String, int> _getInteractionsByType(String type) {
    final Map<String, int> result = {};
    
    // This is a simplified implementation
    // In a real app, you'd track type information with interactions
    _notificationInteractions.forEach((id, actions) {
      for (final action in actions) {
        result[action] = (result[action] ?? 0) + 1;
      }
    });
    
    return result;
  }
  
  /// Find peak notification hour
  int? _findPeakHour() {
    if (_hourlyDistribution.isEmpty) return null;
    
    int maxHour = 0;
    int maxCount = 0;
    
    _hourlyDistribution.forEach((hour, timestamps) {
      if (timestamps.length > maxCount) {
        maxCount = timestamps.length;
        maxHour = hour;
      }
    });
    
    return maxHour;
  }
  
  /// Find quietest notification hour
  int? _findQuietHour() {
    if (_hourlyDistribution.isEmpty) return null;
    
    int minHour = 0;
    int minCount = _hourlyDistribution.values.first.length;
    
    _hourlyDistribution.forEach((hour, timestamps) {
      if (timestamps.length < minCount) {
        minCount = timestamps.length;
        minHour = hour;
      }
    });
    
    return minHour;
  }

  /// Add event to queue
  void _addEvent(AnalyticsEvent event) {
    _recentEvents.add(event);
    
    // Maintain max events limit
    while (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeFirst();
    }
  }

  /// Log debug message
  void _logDebug(String message) {
    _logger?.debug(message: '[NotificationAnalytics] $message');
  }

  /// Clean old data
  void cleanOldData({Duration maxAge = const Duration(days: 30)}) {
    final cutoffDate = DateTime.now().subtract(maxAge);
    
    // Clean scheduled times
    _scheduledTimes.removeWhere((id, time) => time.isBefore(cutoffDate));
    
    // Clean hourly distribution
    _hourlyDistribution.forEach((hour, timestamps) {
      timestamps.removeWhere((time) => time.isBefore(cutoffDate));
    });
    
    // Clean events
    while (_recentEvents.isNotEmpty && 
           _recentEvents.first.timestamp.isBefore(cutoffDate)) {
      _recentEvents.removeFirst();
    }
    
    _logDebug('Cleaned analytics data older than $maxAge');
  }

  /// Reset all statistics
  void reset() {
    _scheduledByType.clear();
    _scheduledTimes.clear();
    _interactionsByAction.clear();
    _notificationInteractions.clear();
    _errorsByType.clear();
    _suppressionReasons.clear();
    _recentEvents.clear();
    _latencyByType.clear();
    _deliverySuccess.clear();
    _deliveryFailure.clear();
    _hourlyDistribution.clear();
    _categoryMetrics.clear();
    
    _logDebug('Analytics reset');
  }

  /// Export data as JSON string
  String exportToJson() {
    return '${getStats()}';
  }

  /// Dispose resources
  void dispose() {
    reset();
  }
}

/// Analytics event
class AnalyticsEvent {
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  AnalyticsEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}