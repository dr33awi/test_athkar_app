// lib/core/services/utils/notification_retry_manager.dart
import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../interfaces/notification_service.dart';
import '../interfaces/storage_service.dart';
import '../../../app/di/service_locator.dart';

/// مدير إعادة المحاولة للإشعارات الفاشلة
class NotificationRetryManager {
  final StorageService _storage;
  final Queue<RetryableNotification> _retryQueue = Queue<RetryableNotification>();
  final Map<int, int> _retryAttempts = {};
  final Map<int, DateTime> _lastRetryTime = {};
  
  Timer? _retryTimer;
  bool _isProcessing = false;
  
  // إعدادات إعادة المحاولة
  static const int maxRetryAttempts = 3;
  static const Duration initialRetryDelay = Duration(seconds: 30);
  static const Duration maxRetryDelay = Duration(minutes: 30);
  static const String storageKey = 'pending_notifications';
  
  NotificationRetryManager({StorageService? storage})
      : _storage = storage ?? getIt<StorageService>() {
    _loadPendingNotifications();
    _startRetryTimer();
  }
  
  /// التحقق من إمكانية إعادة المحاولة
  Future<bool> shouldRetry(int notificationId) async {
    final attempts = _retryAttempts[notificationId] ?? 0;
    return attempts < maxRetryAttempts;
  }
  
  /// إضافة إشعار لقائمة إعادة المحاولة
  Future<void> queueForRetry(NotificationData notification) async {
    final attempts = _retryAttempts[notification.id] ?? 0;
    
    if (attempts >= maxRetryAttempts) {
      _logDebug('Max retry attempts reached for notification ${notification.id}');
      return;
    }
    
    final retryable = RetryableNotification(
      notification: notification,
      attemptNumber: attempts + 1,
      nextRetryTime: _calculateNextRetryTime(attempts),
    );
    
    _retryQueue.add(retryable);
    _retryAttempts[notification.id] = attempts + 1;
    _lastRetryTime[notification.id] = DateTime.now();
    
    await _savePendingNotifications();
    
    _logDebug('Notification ${notification.id} queued for retry (attempt ${attempts + 1})');
  }
  
  /// معالجة قائمة إعادة المحاولة
  Future<void> processRetryQueue() async {
    if (_isProcessing || _retryQueue.isEmpty) return;
    
    _isProcessing = true;
    final now = DateTime.now();
    final toProcess = <RetryableNotification>[];
    
    // جمع الإشعارات الجاهزة لإعادة المحاولة
    while (_retryQueue.isNotEmpty) {
      final item = _retryQueue.first;
      if (item.nextRetryTime.isBefore(now)) {
        toProcess.add(_retryQueue.removeFirst());
      } else {
        break; // القائمة مرتبة حسب الوقت
      }
    }
    
    // معالجة الإشعارات
    for (final item in toProcess) {
      try {
        _logDebug('Retrying notification ${item.notification.id}');
        
        // محاولة إعادة جدولة الإشعار
        // سيتم استدعاء NotificationService من خارج هذا الكلاس لتجنب التبعية الدائرية
        await _onRetryCallback?.call(item.notification);
        
        // إزالة من قائمة المحاولات عند النجاح
        _retryAttempts.remove(item.notification.id);
        _lastRetryTime.remove(item.notification.id);
        
      } catch (e) {
        _logDebug('Retry failed for notification ${item.notification.id}: $e');
        
        // إعادة إضافتها للقائمة إذا لم تصل للحد الأقصى
        if (await shouldRetry(item.notification.id)) {
          await queueForRetry(item.notification);
        } else {
          _logDebug('Giving up on notification ${item.notification.id} after max attempts');
          _retryAttempts.remove(item.notification.id);
          _lastRetryTime.remove(item.notification.id);
        }
      }
    }
    
    await _savePendingNotifications();
    _isProcessing = false;
  }
  
  /// حساب وقت إعادة المحاولة التالي
  DateTime _calculateNextRetryTime(int attemptNumber) {
    // Exponential backoff
    final delaySeconds = initialRetryDelay.inSeconds * (1 << attemptNumber);
    final delay = Duration(seconds: delaySeconds.clamp(
      initialRetryDelay.inSeconds,
      maxRetryDelay.inSeconds,
    ));
    
    return DateTime.now().add(delay);
  }
  
  /// تحميل الإشعارات المعلقة من التخزين
  Future<void> _loadPendingNotifications() async {
    try {
      final data = _storage.getMap(storageKey);
      if (data == null) return;
      
      final notifications = data['notifications'] as List?;
      if (notifications == null) return;
      
      for (final item in notifications) {
        final notification = _deserializeNotification(item);
        if (notification != null) {
          _retryQueue.add(notification);
          _retryAttempts[notification.notification.id] = notification.attemptNumber;
        }
      }
      
      _logDebug('Loaded ${_retryQueue.length} pending notifications');
    } catch (e) {
      _logDebug('Error loading pending notifications: $e');
    }
  }
  
  /// حفظ الإشعارات المعلقة في التخزين
  Future<void> _savePendingNotifications() async {
    try {
      final notifications = _retryQueue
          .map((item) => _serializeNotification(item))
          .toList();
      
      await _storage.setMap(storageKey, {
        'notifications': notifications,
        'saved_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logDebug('Error saving pending notifications: $e');
    }
  }
  
  /// تسلسل إشعار لحفظه
  Map<String, dynamic> _serializeNotification(RetryableNotification item) {
    return {
      'notification': {
        'id': item.notification.id,
        'title': item.notification.title,
        'body': item.notification.body,
        'scheduled_date': item.notification.scheduledDate.toIso8601String(),
        'repeat_interval': item.notification.repeatInterval?.index,
        'notification_time': item.notification.notificationTime.index,
        'priority': item.notification.priority.index,
        'respect_battery': item.notification.respectBatteryOptimizations,
        'respect_dnd': item.notification.respectDoNotDisturb,
        'sound_name': item.notification.soundName,
        'channel_id': item.notification.channelId,
        'payload': item.notification.payload,
        'visibility': item.notification.visibility.index,
      },
      'attempt_number': item.attemptNumber,
      'next_retry_time': item.nextRetryTime.toIso8601String(),
    };
  }
  
  /// استرجاع إشعار من التسلسل
  RetryableNotification? _deserializeNotification(Map<String, dynamic> data) {
    try {
      final notifData = data['notification'] as Map<String, dynamic>;
      
      final notification = NotificationData(
        id: notifData['id'] as int,
        title: notifData['title'] as String,
        body: notifData['body'] as String,
        scheduledDate: DateTime.parse(notifData['scheduled_date'] as String),
        repeatInterval: notifData['repeat_interval'] != null
            ? NotificationRepeatInterval.values[notifData['repeat_interval'] as int]
            : null,
        notificationTime: NotificationTime.values[notifData['notification_time'] as int],
        priority: NotificationPriority.values[notifData['priority'] as int],
        respectBatteryOptimizations: notifData['respect_battery'] as bool,
        respectDoNotDisturb: notifData['respect_dnd'] as bool,
        soundName: notifData['sound_name'] as String?,
        channelId: notifData['channel_id'] as String,
        payload: notifData['payload'] as String?,
        visibility: NotificationVisibility.values[notifData['visibility'] as int],
      );
      
      return RetryableNotification(
        notification: notification,
        attemptNumber: data['attempt_number'] as int,
        nextRetryTime: DateTime.parse(data['next_retry_time'] as String),
      );
    } catch (e) {
      _logDebug('Error deserializing notification: $e');
      return null;
    }
  }
  
  /// بدء مؤقت إعادة المحاولة
  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      processRetryQueue();
    });
  }
  
  /// إيقاف مؤقت إعادة المحاولة
  void _stopRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
  
  /// تعيين callback لإعادة المحاولة
  Function(NotificationData)? _onRetryCallback;
  void setRetryCallback(Function(NotificationData) callback) {
    _onRetryCallback = callback;
  }
  
  /// الحصول على إحصائيات إعادة المحاولة
  Map<String, dynamic> getRetryStats() {
    return {
      'queue_size': _retryQueue.length,
      'retry_attempts': Map<int, int>.from(_retryAttempts),
      'is_processing': _isProcessing,
      'next_retry_times': _retryQueue
          .take(5)
          .map((item) => {
                'id': item.notification.id,
                'time': item.nextRetryTime.toIso8601String(),
              })
          .toList(),
    };
  }
  
  /// مسح قائمة إعادة المحاولة
  Future<void> clearRetryQueue() async {
    _retryQueue.clear();
    _retryAttempts.clear();
    _lastRetryTime.clear();
    await _storage.remove(storageKey);
    _logDebug('Retry queue cleared');
  }
  
  /// التخلص من الموارد
  Future<void> dispose() async {
    _stopRetryTimer();
    await _savePendingNotifications();
    _retryQueue.clear();
    _retryAttempts.clear();
    _lastRetryTime.clear();
    _isProcessing = false;
  }
  
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[NotificationRetryManager] $message');
    }
  }
}

/// إشعار قابل لإعادة المحاولة
class RetryableNotification {
  final NotificationData notification;
  final int attemptNumber;
  final DateTime nextRetryTime;
  
  RetryableNotification({
    required this.notification,
    required this.attemptNumber,
    required this.nextRetryTime,
  });
}