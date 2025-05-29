// lib/core/services/utils/notification_analytics.dart
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// نظام تحليلات لتتبع أداء الإشعارات وتفاعل المستخدم
class NotificationAnalytics {
  // إحصائيات الإشعارات المجدولة
  final Map<String, int> _scheduledByType = {};
  final Map<int, DateTime> _scheduledTimes = {};
  
  // إحصائيات التفاعل
  final Map<String, int> _interactionsByAction = {};
  final Map<int, List<String>> _notificationInteractions = {};
  
  // إحصائيات الأخطاء
  final Map<String, int> _errorsByType = {};
  final Queue<AnalyticsEvent> _recentEvents = Queue<AnalyticsEvent>();
  
  // إحصائيات القمع (suppression)
  final Map<String, int> _suppressionReasons = {};
  
  // حد أقصى للأحداث المحفوظة
  static const int _maxRecentEvents = 100;

  /// تسجيل جدولة إشعار
  void recordNotificationScheduled(int id, String type) {
    _scheduledByType[type] = (_scheduledByType[type] ?? 0) + 1;
    _scheduledTimes[id] = DateTime.now();
    
    _addEvent(AnalyticsEvent(
      type: 'notification_scheduled',
      timestamp: DateTime.now(),
      data: {'id': id, 'type': type},
    ));
    
    _logDebug('Notification scheduled - ID: $id, Type: $type');
  }

  /// تسجيل تفاعل مع إشعار
  void recordNotificationInteraction(int id, String action) {
    _interactionsByAction[action] = (_interactionsByAction[action] ?? 0) + 1;
    
    if (!_notificationInteractions.containsKey(id)) {
      _notificationInteractions[id] = [];
    }
    _notificationInteractions[id]!.add(action);
    
    _addEvent(AnalyticsEvent(
      type: 'notification_interaction',
      timestamp: DateTime.now(),
      data: {'id': id, 'action': action},
    ));
    
    _logDebug('Notification interaction - ID: $id, Action: $action');
  }

  /// تسجيل خطأ
  void recordError(String errorType, String details) {
    _errorsByType[errorType] = (_errorsByType[errorType] ?? 0) + 1;
    
    _addEvent(AnalyticsEvent(
      type: 'error',
      timestamp: DateTime.now(),
      data: {'error_type': errorType, 'details': details},
    ));
    
    _logDebug('Error recorded - Type: $errorType, Details: $details');
  }

  /// تسجيل حدث عام
  void recordEvent(String eventType, [Map<String, dynamic>? data]) {
    _addEvent(AnalyticsEvent(
      type: eventType,
      timestamp: DateTime.now(),
      data: data ?? {},
    ));
    
    _logDebug('Event recorded - Type: $eventType');
  }

  /// تسجيل قمع إشعار
  void recordNotificationSuppressed(String reason) {
    _suppressionReasons[reason] = (_suppressionReasons[reason] ?? 0) + 1;
    
    _addEvent(AnalyticsEvent(
      type: 'notification_suppressed',
      timestamp: DateTime.now(),
      data: {'reason': reason},
    ));
  }

  /// الحصول على الإحصائيات الكاملة
  Map<String, dynamic> getStats() {
    return {
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
      },
      'suppressions': {
        'by_reason': Map<String, int>.from(_suppressionReasons),
        'total': _suppressionReasons.values.fold(0, (a, b) => a + b),
      },
      'recent_events': _recentEvents.map((e) => e.toMap()).toList(),
    };
  }

  /// الحصول على إحصائيات نوع معين
  Map<String, dynamic> getStatsByType(String type) {
    return {
      'scheduled_count': _scheduledByType[type] ?? 0,
      'interactions': _getInteractionsByType(type),
      'success_rate': _calculateSuccessRate(type),
    };
  }

  /// حساب معدل التفاعل
  double _calculateEngagementRate() {
    final totalScheduled = _scheduledByType.values.fold(0, (a, b) => a + b);
    final totalInteractions = _interactionsByAction.values.fold(0, (a, b) => a + b);
    
    if (totalScheduled == 0) return 0.0;
    return (totalInteractions / totalScheduled * 100);
  }

  /// حساب معدل النجاح لنوع معين
  double _calculateSuccessRate(String type) {
    final scheduled = _scheduledByType[type] ?? 0;
    final errors = _errorsByType[type] ?? 0;
    
    if (scheduled == 0) return 0.0;
    return ((scheduled - errors) / scheduled * 100);
  }

  /// الحصول على التفاعلات حسب النوع
  Map<String, int> _getInteractionsByType(String type) {
    final Map<String, int> result = {};
    
    _notificationInteractions.forEach((id, actions) {
      // افتراض أن النوع يمكن استنتاجه من ID
      // في التطبيق الحقيقي، يجب تخزين هذه المعلومة
      for (final action in actions) {
        result[action] = (result[action] ?? 0) + 1;
      }
    });
    
    return result;
  }

  /// إضافة حدث للقائمة
  void _addEvent(AnalyticsEvent event) {
    _recentEvents.add(event);
    
    // الحفاظ على حد أقصى للأحداث
    while (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeFirst();
    }
  }

  /// تسجيل معلومات debug
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[NotificationAnalytics] $message');
    }
  }

  /// تنظيف البيانات القديمة
  void cleanOldData({Duration maxAge = const Duration(days: 30)}) {
    final cutoffDate = DateTime.now().subtract(maxAge);
    
    // تنظيف الأوقات المجدولة القديمة
    _scheduledTimes.removeWhere((id, time) => time.isBefore(cutoffDate));
    
    // تنظيف الأحداث القديمة
    while (_recentEvents.isNotEmpty && 
           _recentEvents.first.timestamp.isBefore(cutoffDate)) {
      _recentEvents.removeFirst();
    }
    
    _logDebug('Cleaned analytics data older than $maxAge');
  }

  /// إعادة تعيين جميع الإحصائيات
  void reset() {
    _scheduledByType.clear();
    _scheduledTimes.clear();
    _interactionsByAction.clear();
    _notificationInteractions.clear();
    _errorsByType.clear();
    _suppressionReasons.clear();
    _recentEvents.clear();
    
    _logDebug('Analytics reset');
  }

  /// تصدير البيانات
  String exportToJson() {
    return '${getStats()}';
  }

  /// التخلص من الموارد
  void dispose() {
    reset();
  }
}

/// حدث تحليلي
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