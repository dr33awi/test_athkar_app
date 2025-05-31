// lib/core/infrastructure/services/notifications/utils/notification_retry_manager.dart
import 'dart:convert';
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import '../models/notification_data.dart';
import '../../storage/storage_service.dart';
import '../../logging/logger_service.dart';
import '../../../../../app/di/service_locator.dart';

/// Manager for retrying failed notifications
class NotificationRetryManager {
  final StorageService _storage;
  final LoggerService? _logger;
  final Queue<RetryableNotification> _retryQueue = Queue<RetryableNotification>();
  final Map<int, int> _retryAttempts = {};
  final Map<int, DateTime> _lastRetryTime = {};
  final Map<int, List<String>> _retryHistory = {};
  
  Timer? _retryTimer;
  bool _isProcessing = false;
  bool _isDisposed = false;
  
  // Retry configuration
  static const int maxRetryAttempts = 3;
  static const Duration initialRetryDelay = Duration(seconds: 30);
  static const Duration maxRetryDelay = Duration(minutes: 30);
  static const Duration retryCheckInterval = Duration(minutes: 1);
  static const String storageKey = 'pending_notifications';
  static const String historyKey = 'notification_retry_history';
  
  // Backoff strategy
  static const double backoffMultiplier = 2.0;
  static const bool useJitter = true;
  
  NotificationRetryManager({
    StorageService? storage,
    LoggerService? logger,
  })  : _storage = storage ?? getIt<StorageService>(),
        _logger = logger {
    _initialize();
  }
  
  void _initialize() {
    _logger?.debug(message: '[RetryManager] Initializing...');
    _loadPendingNotifications();
    _loadRetryHistory();
    _startRetryTimer();
  }
  
  /// Check if notification can be retried
  Future<bool> shouldRetry(int notificationId) async {
    final attempts = _retryAttempts[notificationId] ?? 0;
    final canRetry = attempts < maxRetryAttempts;
    
    _logger?.debug(
      message: '[RetryManager] Should retry check',
      data: {
        'id': notificationId,
        'attempts': attempts,
        'max_attempts': maxRetryAttempts,
        'can_retry': canRetry,
      },
    );
    
    return canRetry;
  }
  
  /// Queue notification for retry
  Future<void> queueForRetry(NotificationData notification) async {
    if (_isDisposed) return;
    
    final attempts = _retryAttempts[notification.id] ?? 0;
    
    if (attempts >= maxRetryAttempts) {
      _logger?.warning(
        message: '[RetryManager] Max retry attempts reached',
        data: {'id': notification.id, 'attempts': attempts},
      );
      
      // Record failure in history
      _recordRetryEvent(notification.id, 'max_attempts_reached');
      return;
    }
    
    final nextRetryTime = _calculateNextRetryTime(attempts);
    final retryable = RetryableNotification(
      notification: notification,
      attemptNumber: attempts + 1,
      nextRetryTime: nextRetryTime,
      queuedAt: DateTime.now(),
      failureReason: notification.additionalData?['failure_reason'] as String?,
    );
    
    _retryQueue.add(retryable);
    _retryAttempts[notification.id] = attempts + 1;
    _lastRetryTime[notification.id] = DateTime.now();
    
    // Record in history
    _recordRetryEvent(notification.id, 'queued', {
      'attempt': attempts + 1,
      'next_retry': nextRetryTime.toIso8601String(),
    });
    
    await _savePendingNotifications();
    
    _logger?.info(
      message: '[RetryManager] Notification queued for retry',
      data: {
        'id': notification.id,
        'attempt': attempts + 1,
        'next_retry': nextRetryTime.toIso8601String(),
        'queue_size': _retryQueue.length,
      },
    );
  }
  
  /// Process retry queue
  Future<void> processRetryQueue() async {
    if (_isProcessing || _retryQueue.isEmpty || _isDisposed) return;
    
    _isProcessing = true;
    _logger?.debug(
      message: '[RetryManager] Processing retry queue',
      data: {'queue_size': _retryQueue.length},
    );
    
    final now = DateTime.now();
    final toProcess = <RetryableNotification>[];
    final toRequeue = <RetryableNotification>[];
    
    // Collect notifications ready for retry
    while (_retryQueue.isNotEmpty) {
      final item = _retryQueue.removeFirst();
      if (item.nextRetryTime.isBefore(now)) {
        toProcess.add(item);
      } else {
        toRequeue.add(item);
      }
    }
    
    // Re-add items not ready yet
    _retryQueue.addAll(toRequeue);
    
    // Process notifications
    for (final item in toProcess) {
      if (_isDisposed) break;
      
      try {
        _logger?.info(
          message: '[RetryManager] Retrying notification',
          data: {
            'id': item.notification.id,
            'attempt': item.attemptNumber,
            'queued_duration': DateTime.now().difference(item.queuedAt).toString(),
          },
        );
        
        // Record retry attempt
        _recordRetryEvent(item.notification.id, 'retry_attempt', {
          'attempt': item.attemptNumber,
        });
        
        // Retry notification through callback
        await _onRetryCallback?.call(item.notification);
        
        // Remove from retry tracking on success
        _retryAttempts.remove(item.notification.id);
        _lastRetryTime.remove(item.notification.id);
        
        // Record success
        _recordRetryEvent(item.notification.id, 'retry_success', {
          'attempt': item.attemptNumber,
        });
        
        _logger?.info(
          message: '[RetryManager] Retry successful',
          data: {'id': item.notification.id},
        );
        
      } catch (e) {
        _logger?.error(
          message: '[RetryManager] Retry failed',
          error: e,
        );
        
        // Record failure
        _recordRetryEvent(item.notification.id, 'retry_failed', {
          'attempt': item.attemptNumber,
          'error': e.toString(),
        });
        
        // Re-queue if not at max attempts
        if (await shouldRetry(item.notification.id)) {
          await queueForRetry(
            item.notification.copyWith(
              additionalData: {
                ...?item.notification.additionalData,
                'failure_reason': e.toString(),
              },
            ),
          );
        } else {
          _logger?.warning(
            message: '[RetryManager] Giving up on notification after max attempts',
            data: {'id': item.notification.id},
          );
          
          _recordRetryEvent(item.notification.id, 'abandoned', {
            'total_attempts': _retryAttempts[item.notification.id],
          });
          
          _retryAttempts.remove(item.notification.id);
          _lastRetryTime.remove(item.notification.id);
        }
      }
    }
    
    await _savePendingNotifications();
    _isProcessing = false;
    
    _logger?.debug(
      message: '[RetryManager] Retry queue processing complete',
      data: {
        'processed': toProcess.length,
        'remaining': _retryQueue.length,
      },
    );
  }
  
  /// Calculate next retry time with exponential backoff
  DateTime _calculateNextRetryTime(int attemptNumber) {
    // Calculate base delay with exponential backoff
    var delaySeconds = initialRetryDelay.inSeconds * 
                      math.pow(backoffMultiplier, attemptNumber).toInt();
    
    // Apply max delay cap
    delaySeconds = math.min(delaySeconds, maxRetryDelay.inSeconds);
    
    // Add jitter to prevent thundering herd
    if (useJitter) {
      final jitter = (delaySeconds * 0.2 * (math.Random().nextDouble() - 0.5)).toInt();
      delaySeconds += jitter;
    }
    
    final delay = Duration(seconds: delaySeconds);
    
    _logger?.debug(
      message: '[RetryManager] Calculated retry delay',
      data: {
        'attempt': attemptNumber,
        'delay_seconds': delaySeconds,
        'delay': delay.toString(),
      },
    );
    
    return DateTime.now().add(delay);
  }
  
  /// Record retry event in history
  void _recordRetryEvent(int notificationId, String event, [Map<String, dynamic>? data]) {
    _retryHistory.putIfAbsent(notificationId, () => []).add(
      jsonEncode({
        'event': event,
        'timestamp': DateTime.now().toIso8601String(),
        if (data != null) ...data,
      }),
    );
    
    // Limit history size
    if (_retryHistory[notificationId]!.length > 20) {
      _retryHistory[notificationId]!.removeAt(0);
    }
    
    _saveRetryHistory();
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
      
      _logger?.info(
        message: '[RetryManager] Loaded pending notifications',
        data: {'count': _retryQueue.length},
      );
    } catch (e) {
      _logger?.error(
        message: '[RetryManager] Error loading pending notifications',
        error: e,
      );
    }
  }
  
  /// Save pending notifications to storage
  Future<void> _savePendingNotifications() async {
    if (_isDisposed) return;
    
    try {
      final notifications = _retryQueue
          .map((item) => _serializeNotification(item))
          .toList();
      
      await _storage.setMap(storageKey, {
        'notifications': notifications,
        'saved_at': DateTime.now().toIso8601String(),
        'version': 1,
      });
      
      _logger?.debug(
        message: '[RetryManager] Saved pending notifications',
        data: {'count': notifications.length},
      );
    } catch (e) {
      _logger?.error(
        message: '[RetryManager] Error saving pending notifications',
        error: e,
      );
    }
  }
  
  /// Load retry history from storage
  Future<void> _loadRetryHistory() async {
    try {
      final data = _storage.getMap(historyKey);
      if (data == null) return;
      
      data.forEach((key, value) {
        if (value is List) {
          _retryHistory[int.parse(key)] = value.cast<String>();
        }
      });
      
      _logger?.debug(
        message: '[RetryManager] Loaded retry history',
        data: {'entries': _retryHistory.length},
      );
    } catch (e) {
      _logger?.error(
        message: '[RetryManager] Error loading retry history',
        error: e,
      );
    }
  }
  
  /// Save retry history to storage
  Future<void> _saveRetryHistory() async {
    if (_isDisposed) return;
    
    try {
      final historyMap = <String, List<String>>{};
      _retryHistory.forEach((id, events) {
        historyMap[id.toString()] = events;
      });
      
      await _storage.setMap(historyKey, historyMap);
    } catch (e) {
      _logger?.error(
        message: '[RetryManager] Error saving retry history',
        error: e,
      );
    }
  }
  
  /// Serialize notification for storage
  Map<String, dynamic> _serializeNotification(RetryableNotification item) {
    return {
      'notification': item.notification.toJson(),
      'attempt_number': item.attemptNumber,
      'next_retry_time': item.nextRetryTime.toIso8601String(),
      'queued_at': item.queuedAt.toIso8601String(),
      'failure_reason': item.failureReason,
    };
  }
  
  /// Deserialize notification from storage
  RetryableNotification? _deserializeNotification(Map<String, dynamic> data) {
    try {
      final notifData = data['notification'] as Map<String, dynamic>;
      final notification = NotificationData.fromJson(notifData);
      
      return RetryableNotification(
        notification: notification,
        attemptNumber: data['attempt_number'] as int,
        nextRetryTime: DateTime.parse(data['next_retry_time'] as String),
        queuedAt: DateTime.parse(data['queued_at'] as String),
        failureReason: data['failure_reason'] as String?,
      );
    } catch (e) {
      _logger?.error(
        message: '[RetryManager] Error deserializing notification',
        error: e,
      );
      return null;
    }
  }
  
  /// Start retry timer
  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(retryCheckInterval, (_) {
      if (!_isDisposed) {
        processRetryQueue();
      }
    });
    
    _logger?.debug(message: '[RetryManager] Retry timer started');
  }
  
  /// Stop retry timer
  void _stopRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _logger?.debug(message: '[RetryManager] Retry timer stopped');
  }
  
  /// Set retry callback
  Function(NotificationData)? _onRetryCallback;
  void setRetryCallback(Function(NotificationData) callback) {
    _onRetryCallback = callback;
    _logger?.debug(message: '[RetryManager] Retry callback set');
  }
  
  /// Get retry statistics
  Map<String, dynamic> getRetryStats() {
    final queuedByPriority = <String, int>{};
    final queuedByCategory = <String, int>{};
    
    for (final item in _retryQueue) {
      final priority = item.notification.priority.toString();
      final category = item.notification.category.toString();
      
      queuedByPriority[priority] = (queuedByPriority[priority] ?? 0) + 1;
      queuedByCategory[category] = (queuedByCategory[category] ?? 0) + 1;
    }
    
    return {
      'queue_size': _retryQueue.length,
      'total_attempts': _retryAttempts.values.fold(0, (a, b) => a + b),
      'notifications_with_retries': _retryAttempts.length,
      'is_processing': _isProcessing,
      'by_priority': queuedByPriority,
      'by_category': queuedByCategory,
      'next_retry_times': _retryQueue
          .take(5)
          .map((item) => {
                'id': item.notification.id,
                'time': item.nextRetryTime.toIso8601String(),
                'attempt': item.attemptNumber,
              })
          .toList(),
    };
  }
  
  /// Get retry history for a notification
  List<Map<String, dynamic>> getNotificationHistory(int notificationId) {
    final events = _retryHistory[notificationId] ?? [];
    return events.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }
  
  /// Clear retry queue
  Future<void> clearRetryQueue() async {
    _retryQueue.clear();
    _retryAttempts.clear();
    _lastRetryTime.clear();
    await _storage.remove(storageKey);
    
    _logger?.info(message: '[RetryManager] Retry queue cleared');
  }
  
  /// Clear retry history
  Future<void> clearRetryHistory() async {
    _retryHistory.clear();
    await _storage.remove(historyKey);
    
    _logger?.info(message: '[RetryManager] Retry history cleared');
  }
  
  /// Remove specific notification from retry queue
  Future<void> removeFromRetryQueue(int notificationId) async {
    _retryQueue.removeWhere((item) => item.notification.id == notificationId);
    _retryAttempts.remove(notificationId);
    _lastRetryTime.remove(notificationId);
    
    await _savePendingNotifications();
    
    _logger?.debug(
      message: '[RetryManager] Notification removed from retry queue',
      data: {'id': notificationId},
    );
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    if (_isDisposed) return;
    
    _logger?.debug(message: '[RetryManager] Disposing...');
    
    _isDisposed = true;
    _stopRetryTimer();
    await _savePendingNotifications();
    await _saveRetryHistory();
    
    _retryQueue.clear();
    _retryAttempts.clear();
    _lastRetryTime.clear();
    _retryHistory.clear();
    _isProcessing = false;
    _onRetryCallback = null;
    
    _logger?.info(message: '[RetryManager] Disposed');
  }
}

/// Retryable notification with metadata
class RetryableNotification {
  final NotificationData notification;
  final int attemptNumber;
  final DateTime nextRetryTime;
  final DateTime queuedAt;
  final String? failureReason;
  
  RetryableNotification({
    required this.notification,
    required this.attemptNumber,
    required this.nextRetryTime,
    required this.queuedAt,
    this.failureReason,
  });
  
  /// Time remaining until retry
  Duration get timeUntilRetry {
    final remaining = nextRetryTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  /// Check if ready for retry
  bool get isReadyForRetry => DateTime.now().isAfter(nextRetryTime);
}