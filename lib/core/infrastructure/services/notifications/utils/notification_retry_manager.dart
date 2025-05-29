// lib/core/infrastructure/services/notifications/notification_retry_manager.dart
import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/notification_data.dart';
import '../../storage/storage_service.dart';
import '../../../../../app/di/service_locator.dart';

/// Manager for retrying failed notifications
class NotificationRetryManager {
  final StorageService _storage;
  final Queue<RetryableNotification> _retryQueue = Queue<RetryableNotification>();
  final Map<int, int> _retryAttempts = {};
  final Map<int, DateTime> _lastRetryTime = {};
  
  Timer? _retryTimer;
  bool _isProcessing = false;
  
  // Retry settings
  static const int maxRetryAttempts = 3;
  static const Duration initialRetryDelay = Duration(seconds: 30);
  static const Duration maxRetryDelay = Duration(minutes: 30);
  static const String storageKey = 'pending_notifications';
  
  NotificationRetryManager({StorageService? storage})
      : _storage = storage ?? getIt<StorageService>() {
    _loadPendingNotifications();
    _startRetryTimer();
  }
  
  /// Check if notification can be retried
  Future<bool> shouldRetry(int notificationId) async {
    final attempts = _retryAttempts[notificationId] ?? 0;
    return attempts < maxRetryAttempts;
  }
  
  /// Queue notification for retry
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
  
  /// Process retry queue
  Future<void> processRetryQueue() async {
    if (_isProcessing || _retryQueue.isEmpty) return;
    
    _isProcessing = true;
    final now = DateTime.now();
    final toProcess = <RetryableNotification>[];
    
    // Collect notifications ready for retry
    while (_retryQueue.isNotEmpty) {
      final item = _retryQueue.first;
      if (item.nextRetryTime.isBefore(now)) {
        toProcess.add(_retryQueue.removeFirst());
      } else {
        break;
      }
    }
    
    // Process notifications
    for (final item in toProcess) {
      try {
        _logDebug('Retrying notification ${item.notification.id}');
        
        // Retry notification through callback
        await _onRetryCallback?.call(item.notification);
        
        // Remove from retry tracking on success
        _retryAttempts.remove(item.notification.id);
        _lastRetryTime.remove(item.notification.id);
        
      } catch (e) {
        _logDebug('Retry failed for notification ${item.notification.id}: $e');
        
        // Re-queue if not at max attempts
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
  
  /// Calculate next retry time
  DateTime _calculateNextRetryTime(int attemptNumber) {
    // Exponential backoff
    final delaySeconds = initialRetryDelay.inSeconds * (1 << attemptNumber);
    final delay = Duration(seconds: delaySeconds.clamp(
      initialRetryDelay.inSeconds,
      maxRetryDelay.inSeconds,
    ));
    
    return DateTime.now().add(delay);
  }
  
  /// Load pending notifications from storage
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
  
  /// Save pending notifications to storage
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
  
  /// Serialize notification for storage
  Map<String, dynamic> _serializeNotification(RetryableNotification item) {
    return {
      'notification': {
        'id': item.notification.id,
        'title': item.notification.title,
        'body': item.notification.body,
        'scheduled_date': item.notification.scheduledDate.toIso8601String(),
        'repeat_interval': item.notification.repeatInterval.index,
        'category': item.notification.category.index,
        'notification_time': item.notification.notificationTime.index,
        'priority': item.notification.priority.index,
        'visibility': item.notification.visibility.index,
        'channel_id': item.notification.channelId,
        'payload': item.notification.payload,
        'sound_name': item.notification.soundName,
        'icon_name': item.notification.iconName,
        'group_key': item.notification.groupKey,
        'show_when': item.notification.showWhen,
        'ongoing': item.notification.ongoing,
        'auto_cancel': item.notification.autoCancel,
        'play_sound': item.notification.playSound,
        'enable_vibration': item.notification.enableVibration,
        'enable_lights': item.notification.enableLights,
        'respect_battery': item.notification.respectBatteryOptimizations,
        'respect_dnd': item.notification.respectDoNotDisturb,
        'vibration_pattern': item.notification.vibrationPattern,
        'color': item.notification.color,
        'additional_data': item.notification.additionalData,
      },
      'attempt_number': item.attemptNumber,
      'next_retry_time': item.nextRetryTime.toIso8601String(),
    };
  }
  
  /// Deserialize notification from storage
  RetryableNotification? _deserializeNotification(Map<String, dynamic> data) {
    try {
      final notifData = data['notification'] as Map<String, dynamic>;
      
      final notification = NotificationData(
        id: notifData['id'] as int,
        title: notifData['title'] as String,
        body: notifData['body'] as String,
        scheduledDate: DateTime.parse(notifData['scheduled_date'] as String),
        repeatInterval: NotificationRepeatInterval.values[notifData['repeat_interval'] as int],
        category: NotificationCategory.values[notifData['category'] as int],
        notificationTime: NotificationTime.values[notifData['notification_time'] as int],
        priority: NotificationPriority.values[notifData['priority'] as int],
        visibility: NotificationVisibility.values[notifData['visibility'] as int],
        channelId: notifData['channel_id'] as String,
        payload: notifData['payload'] as Map<String, dynamic>?,
        soundName: notifData['sound_name'] as String?,
        iconName: notifData['icon_name'] as String?,
        groupKey: notifData['group_key'] as String?,
        showWhen: notifData['show_when'] as bool? ?? true,
        ongoing: notifData['ongoing'] as bool? ?? false,
        autoCancel: notifData['auto_cancel'] as bool? ?? true,
        playSound: notifData['play_sound'] as bool? ?? true,
        enableVibration: notifData['enable_vibration'] as bool? ?? true,
        enableLights: notifData['enable_lights'] as bool? ?? false,
        respectBatteryOptimizations: notifData['respect_battery'] as bool? ?? true,
        respectDoNotDisturb: notifData['respect_dnd'] as bool? ?? true,
        vibrationPattern: (notifData['vibration_pattern'] as List?)?.cast<int>(),
        color: notifData['color'] as int?,
        additionalData: notifData['additional_data'] as Map<String, dynamic>?,
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
  
  /// Start retry timer
  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      processRetryQueue();
    });
  }
  
  /// Stop retry timer
  void _stopRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
  
  /// Set retry callback
  Function(NotificationData)? _onRetryCallback;
  void setRetryCallback(Function(NotificationData) callback) {
    _onRetryCallback = callback;
  }
  
  /// Get retry statistics
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
  
  /// Clear retry queue
  Future<void> clearRetryQueue() async {
    _retryQueue.clear();
    _retryAttempts.clear();
    _lastRetryTime.clear();
    await _storage.remove(storageKey);
    _logDebug('Retry queue cleared');
  }
  
  /// Dispose resources
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

/// Retryable notification
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