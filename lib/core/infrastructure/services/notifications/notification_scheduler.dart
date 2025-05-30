// lib/core/infrastructure/services/notifications/notification_scheduler.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models/notification_data.dart';
import 'models/notification_schedule.dart';
import 'notification_service.dart';
import '../logging/logger_service.dart';
import '../storage/storage_service.dart';
import '../timezone/timezone_service.dart';
import '../../../../app/di/service_locator.dart';

/// Generic notification scheduler that can be used by any feature
class NotificationScheduler {
  final NotificationService _notificationService;
  final LoggerService _logger;
  final StorageService _storage;
  final TimezoneService _timezoneService;
  
  static const String _scheduledNotificationsKey = 'scheduled_notifications';
  final Map<String, List<ScheduledNotification>> _scheduledNotifications = {};
  final Map<String, Timer> _timers = {};
  
  NotificationScheduler({
    NotificationService? notificationService,
    LoggerService? logger,
    StorageService? storage,
    TimezoneService? timezoneService,
  })  : _notificationService = notificationService ?? getIt<NotificationService>(),
        _logger = logger ?? getIt<LoggerService>(),
        _storage = storage ?? getIt<StorageService>(),
        _timezoneService = timezoneService ?? getIt<TimezoneService>() {
    _loadScheduledNotifications();
  }
  
  /// Schedule a notification with a specific schedule
  Future<void> scheduleNotification({
    required String featureId,
    required NotificationData notification,
    required NotificationSchedule schedule,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.info(
        message: 'Scheduling notification',
        data: {
          'featureId': featureId,
          'notificationId': notification.id,
          'schedule': schedule.toJson(),
        },
      );
      
      // Create scheduled notification
      final scheduledNotification = ScheduledNotification(
        featureId: featureId,
        notification: notification,
        schedule: schedule,
        metadata: metadata,
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      // Add to scheduled notifications
      _scheduledNotifications.putIfAbsent(featureId, () => []).add(scheduledNotification);
      
      // Schedule based on type
      await _scheduleBasedOnType(scheduledNotification);
      
      // Save to storage
      await _saveScheduledNotifications();
      
      _logger.logEvent('notification_scheduled', parameters: {
        'feature': featureId,
        'type': schedule.type.toString(),
        'id': notification.id,
      });
    } catch (e, s) {
      _logger.error(
        message: 'Error scheduling notification',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
  
  /// Schedule multiple notifications
  Future<void> scheduleMultipleNotifications({
    required String featureId,
    required List<NotificationData> notifications,
    required NotificationSchedule schedule,
    Map<String, dynamic>? metadata,
  }) async {
    for (final notification in notifications) {
      await scheduleNotification(
        featureId: featureId,
        notification: notification,
        schedule: schedule,
        metadata: metadata,
      );
    }
  }
  
  /// Cancel scheduled notifications for a feature
  Future<void> cancelFeatureNotifications(String featureId) async {
    try {
      _logger.info(
        message: 'Cancelling feature notifications',
        data: {'featureId': featureId},
      );
      
      final notifications = _scheduledNotifications[featureId] ?? [];
      
      // Cancel all notifications
      for (final scheduled in notifications) {
        await _notificationService.cancelNotification(scheduled.notification.id);
      }
      
      // Cancel timers
      _timers[featureId]?.cancel();
      _timers.remove(featureId);
      
      // Remove from memory
      _scheduledNotifications.remove(featureId);
      
      // Save to storage
      await _saveScheduledNotifications();
      
      _logger.logEvent('feature_notifications_cancelled', parameters: {
        'feature': featureId,
        'count': notifications.length,
      });
    } catch (e) {
      _logger.error(
        message: 'Error cancelling feature notifications',
        error: e,
      );
    }
  }
  
  /// Cancel specific notification
  Future<void> cancelNotification(String featureId, int notificationId) async {
    try {
      await _notificationService.cancelNotification(notificationId);
      
      // Remove from scheduled
      _scheduledNotifications[featureId]?.removeWhere(
        (n) => n.notification.id == notificationId,
      );
      
      await _saveScheduledNotifications();
    } catch (e) {
      _logger.error(
        message: 'Error cancelling notification',
        error: e,
      );
    }
  }
  
  /// Update notification schedule
  Future<void> updateNotificationSchedule({
    required String featureId,
    required int notificationId,
    required NotificationSchedule newSchedule,
  }) async {
    try {
      // Find the notification
      final notifications = _scheduledNotifications[featureId] ?? [];
      final index = notifications.indexWhere(
        (n) => n.notification.id == notificationId,
      );
      
      if (index == -1) {
        _logger.warning(
          message: 'Notification not found for update',
          data: {'featureId': featureId, 'notificationId': notificationId},
        );
        return;
      }
      
      // Update schedule
      final updated = notifications[index].copyWith(schedule: newSchedule);
      notifications[index] = updated;
      
      // Reschedule
      await _notificationService.cancelNotification(notificationId);
      await _scheduleBasedOnType(updated);
      
      await _saveScheduledNotifications();
      
      _logger.info(
        message: 'Notification schedule updated',
        data: {'featureId': featureId, 'notificationId': notificationId},
      );
    } catch (e) {
      _logger.error(
        message: 'Error updating notification schedule',
        error: e,
      );
    }
  }
  
  /// Get scheduled notifications for a feature
  List<ScheduledNotification> getFeatureNotifications(String featureId) {
    return List.unmodifiable(_scheduledNotifications[featureId] ?? []);
  }
  
  /// Get all scheduled notifications
  Map<String, List<ScheduledNotification>> getAllScheduledNotifications() {
    return Map.unmodifiable(_scheduledNotifications);
  }
  
  /// Check if feature has scheduled notifications
  bool hasScheduledNotifications(String featureId) {
    return (_scheduledNotifications[featureId]?.isNotEmpty ?? false);
  }
  
  /// Pause notifications for a feature
  Future<void> pauseFeatureNotifications(String featureId) async {
    final notifications = _scheduledNotifications[featureId] ?? [];
    
    for (final scheduled in notifications) {
      scheduled.isActive = false;
      await _notificationService.cancelNotification(scheduled.notification.id);
    }
    
    _timers[featureId]?.cancel();
    await _saveScheduledNotifications();
    
    _logger.info(
      message: 'Feature notifications paused',
      data: {'featureId': featureId},
    );
  }
  
  /// Resume notifications for a feature
  Future<void> resumeFeatureNotifications(String featureId) async {
    final notifications = _scheduledNotifications[featureId] ?? [];
    
    for (final scheduled in notifications) {
      scheduled.isActive = true;
      await _scheduleBasedOnType(scheduled);
    }
    
    await _saveScheduledNotifications();
    
    _logger.info(
      message: 'Feature notifications resumed',
      data: {'featureId': featureId},
    );
  }
  
  // Private methods
  
  Future<void> _scheduleBasedOnType(ScheduledNotification scheduled) async {
    switch (scheduled.schedule.type) {
      case ScheduleType.once:
        await _scheduleOnce(scheduled);
        break;
      case ScheduleType.daily:
        await _scheduleDaily(scheduled);
        break;
      case ScheduleType.weekly:
        await _scheduleWeekly(scheduled);
        break;
      case ScheduleType.custom:
        await _scheduleCustom(scheduled);
        break;
      case ScheduleType.interval:
        await _scheduleInterval(scheduled);
        break;
    }
  }
  
  Future<void> _scheduleOnce(ScheduledNotification scheduled) async {
    if (scheduled.schedule.dateTime == null) return;
    
    await _notificationService.scheduleNotification(
      scheduled.notification.copyWith(
        scheduledDate: scheduled.schedule.dateTime!,
      ),
    );
  }
  
  Future<void> _scheduleDaily(ScheduledNotification scheduled) async {
    if (scheduled.schedule.timeOfDay == null) return;
    
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      scheduled.schedule.timeOfDay!.hour,
      scheduled.schedule.timeOfDay!.minute,
    );
    
    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    await _notificationService.scheduleNotification(
      scheduled.notification.copyWith(
        scheduledDate: scheduledDate,
        repeatInterval: NotificationRepeatInterval.daily,
      ),
    );
  }
  
  Future<void> _scheduleWeekly(ScheduledNotification scheduled) async {
    if (scheduled.schedule.weekDays == null || 
        scheduled.schedule.weekDays!.isEmpty ||
        scheduled.schedule.timeOfDay == null) return;
    
    // Schedule for each selected day
    for (final weekDay in scheduled.schedule.weekDays!) {
      final nextDate = _getNextWeekdayDate(
        weekDay,
        scheduled.schedule.timeOfDay!,
      );
      
      await _notificationService.scheduleNotification(
        scheduled.notification.copyWith(
          id: scheduled.notification.id + weekDay * 1000, // Unique ID per day
          scheduledDate: nextDate,
          repeatInterval: NotificationRepeatInterval.weekly,
        ),
      );
    }
  }
  
  Future<void> _scheduleCustom(ScheduledNotification scheduled) async {
    if (scheduled.schedule.customDates == null || 
        scheduled.schedule.customDates!.isEmpty) return;
    
    for (int i = 0; i < scheduled.schedule.customDates!.length; i++) {
      final date = scheduled.schedule.customDates![i];
      if (date.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          scheduled.notification.copyWith(
            id: scheduled.notification.id + i * 1000, // Unique ID per date
            scheduledDate: date,
          ),
        );
      }
    }
  }
  
  Future<void> _scheduleInterval(ScheduledNotification scheduled) async {
    if (scheduled.schedule.interval == null) return;
    
    // Cancel existing timer
    _timers[scheduled.featureId]?.cancel();
    
    // Create new timer
    _timers[scheduled.featureId] = Timer.periodic(
      scheduled.schedule.interval!,
      (timer) async {
        if (scheduled.isActive) {
          await _notificationService.showNotification(
            scheduled.notification.copyWith(
              scheduledDate: DateTime.now(),
            ),
          );
        }
      },
    );
  }
  
  DateTime _getNextWeekdayDate(int weekday, NotificationTimeOfDay time) {
    final now = DateTime.now();
    var daysUntilTarget = (weekday - now.weekday) % 7;
    
    // If it's the same day but time has passed, schedule for next week
    if (daysUntilTarget == 0) {
      final todayScheduled = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      if (todayScheduled.isBefore(now)) {
        daysUntilTarget = 7;
      }
    }
    
    final targetDate = now.add(Duration(days: daysUntilTarget));
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      time.hour,
      time.minute,
    );
  }
  
  Future<void> _loadScheduledNotifications() async {
    try {
      final data = _storage.getMap(_scheduledNotificationsKey);
      if (data == null) return;
      
      data.forEach((featureId, notificationsList) {
        if (notificationsList is List) {
          _scheduledNotifications[featureId] = notificationsList
              .map((n) => ScheduledNotification.fromJson(n))
              .toList();
        }
      });
      
      // Reschedule active notifications
      for (final entry in _scheduledNotifications.entries) {
        for (final scheduled in entry.value) {
          if (scheduled.isActive) {
            await _scheduleBasedOnType(scheduled);
          }
        }
      }
      
      _logger.debug(
        message: 'Loaded scheduled notifications',
        data: {'count': _scheduledNotifications.length},
      );
    } catch (e) {
      _logger.error(
        message: 'Error loading scheduled notifications',
        error: e,
      );
    }
  }
  
  Future<void> _saveScheduledNotifications() async {
    try {
      final data = <String, dynamic>{};
      
      _scheduledNotifications.forEach((featureId, notifications) {
        data[featureId] = notifications
            .map((n) => n.toJson())
            .toList();
      });
      
      await _storage.setMap(_scheduledNotificationsKey, data);
    } catch (e) {
      _logger.error(
        message: 'Error saving scheduled notifications',
        error: e,
      );
    }
  }
  
  /// Clean up resources
  Future<void> dispose() async {
    // Cancel all timers
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    
    // Save state
    await _saveScheduledNotifications();
    
    _logger.debug(message: 'NotificationScheduler disposed');
  }
}

/// Scheduled notification wrapper
class ScheduledNotification {
  final String featureId;
  final NotificationData notification;
  final NotificationSchedule schedule;
  final Map<String, dynamic>? metadata;
  bool isActive;
  final DateTime createdAt;
  DateTime? lastTriggered;
  
  ScheduledNotification({
    required this.featureId,
    required this.notification,
    required this.schedule,
    this.metadata,
    this.isActive = true,
    required this.createdAt,
    this.lastTriggered,
  });
  
  ScheduledNotification copyWith({
    String? featureId,
    NotificationData? notification,
    NotificationSchedule? schedule,
    Map<String, dynamic>? metadata,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastTriggered,
  }) {
    return ScheduledNotification(
      featureId: featureId ?? this.featureId,
      notification: notification ?? this.notification,
      schedule: schedule ?? this.schedule,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastTriggered: lastTriggered ?? this.lastTriggered,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'featureId': featureId,
      'notification': notification.toJson(),
      'schedule': schedule.toJson(),
      'metadata': metadata,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggered': lastTriggered?.toIso8601String(),
    };
  }
  
  factory ScheduledNotification.fromJson(Map<String, dynamic> json) {
    return ScheduledNotification(
      featureId: json['featureId'] as String,
      notification: NotificationData.fromJson(json['notification']),
      schedule: NotificationSchedule.fromJson(json['schedule']),
      metadata: json['metadata'] as Map<String, dynamic>?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastTriggered: json['lastTriggered'] != null 
          ? DateTime.parse(json['lastTriggered'] as String)
          : null,
    );
  }
}