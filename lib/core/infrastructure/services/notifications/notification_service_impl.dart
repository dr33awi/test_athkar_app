// lib/core/infrastructure/services/notifications/notification_service_impl.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'models/notification_data.dart' hide NotificationResponse, NotificationVisibility;
import '../device/battery/battery_service.dart';
import '../device/battery/do_not_disturb_service.dart';
import '../timezone/timezone_service.dart';
import '../logging/logger_service.dart';
import 'utils/notification_payload_handler.dart';
import 'utils/notification_analytics.dart';
import 'utils/notification_retry_manager.dart';
import '../../../../app/di/service_locator.dart';

/// Callback for background notifications
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  if (kDebugMode) {
    print('Notification tapped in background: ${notificationResponse.id}');
  }
}

/// Implementation of notification service
class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final BatteryService _batteryService;
  final DoNotDisturbService _doNotDisturbService;
  final TimezoneService _timezoneService;
  final LoggerService _logger;
  final NotificationAnalytics _analytics;
  final NotificationRetryManager _retryManager;

  // Service settings
  NotificationConfig _config = NotificationConfig();
  bool _isInitialized = false;
  bool _isDisposed = false;

  // Callbacks
  Function(NotificationResponse)? _onNotificationTapped;
  Function(NotificationResponse)? _onNotificationAction;
  
  // Registered channels
  final Map<String, NotificationChannel> _registeredChannels = {};

  NotificationServiceImpl(
    this._flutterLocalNotificationsPlugin,
    this._batteryService,
    this._doNotDisturbService,
    this._timezoneService, {
    LoggerService? logger,
    NotificationAnalytics? analytics,
    NotificationRetryManager? retryManager,
  })  : _logger = logger ?? getIt<LoggerService>(),
        _analytics = analytics ?? NotificationAnalytics(),
        _retryManager = retryManager ?? NotificationRetryManager() {
    _logger.debug(message: "NotificationServiceImpl constructed");
    
    // Set retry callback
    _retryManager.setRetryCallback((notification) async {
      await scheduleNotification(notification);
    });
  }

  @override
  Future<void> initialize({
    String? defaultIcon,
    NotificationChannel? defaultChannel,
    List<NotificationChannel>? channels,
  }) async {
    if (_isInitialized || _isDisposed) {
      _logger.debug(
        message: "NotificationService initialize skipped",
        data: {'initialized': _isInitialized, 'disposed': _isDisposed}
      );
      return;
    }

    _logger.info(message: "Initializing NotificationService...");

    try {
      // Initialize timezones
      await _timezoneService.initializeTimeZones();
      _logger.debug(message: "Timezones initialized for notifications");

      // Android settings
      final AndroidInitializationSettings androidInitSettings =
          AndroidInitializationSettings(defaultIcon ?? '@mipmap/ic_launcher');

      // iOS/macOS settings
      const DarwinInitializationSettings darwinInitSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: darwinInitSettings,
        macOS: darwinInitSettings,
      );

      // Initialize plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // Create default channel
      if (defaultChannel != null) {
        await createNotificationChannel(defaultChannel);
      }

      // Create additional channels
      if (channels != null) {
        for (final channel in channels) {
          await createNotificationChannel(channel);
        }
      }

      // Create default channels if none provided
      if (defaultChannel == null && (channels == null || channels.isEmpty)) {
        await _createDefaultNotificationChannels();
      }

      _isInitialized = true;
      _logger.info(message: "NotificationService initialized successfully");
      
      _analytics.recordEvent('notification_service_initialized');
    } catch (e, s) {
      _logger.error(
        message: "Error initializing NotificationService",
        error: e,
        stackTrace: s
      );
      _analytics.recordError('initialization_failed', e.toString());
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> _createDefaultNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final defaultChannel = NotificationChannel(
      id: 'default_channel',
      name: 'Default Notifications',
      description: 'Default notification channel',
      importance: NotificationPriority.normal,
    );

    final highPriorityChannel = NotificationChannel(
      id: 'high_priority_channel',
      name: 'Important Notifications',
      description: 'High priority notifications',
      importance: NotificationPriority.high,
    );

    await createNotificationChannel(defaultChannel);
    await createNotificationChannel(highPriorityChannel);
  }

  @override
  Future<void> createNotificationChannel(NotificationChannel channel) async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return;

    final androidChannel = AndroidNotificationChannel(
      channel.id,
      channel.name,
      description: channel.description,
      importance: _mapPriorityToImportance(channel.importance),
      playSound: channel.playSound,
      enableVibration: channel.enableVibration,
      enableLights: channel.enableLights,
      showBadge: channel.showBadge,
      vibrationPattern: channel.vibrationPattern,
      ledColor: channel.lightColor != null ? Color(channel.lightColor!) : null,
    );

    await androidPlugin.createNotificationChannel(androidChannel);
    _registeredChannels[channel.id] = channel;
    
    _logger.debug(
      message: "Notification channel created",
      data: {'channelId': channel.id, 'name': channel.name}
    );
  }

  @override
  Future<void> deleteNotificationChannel(String channelId) async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.deleteNotificationChannel(channelId);
      _registeredChannels.remove(channelId);
      
      _logger.debug(
        message: "Notification channel deleted",
        data: {'channelId': channelId}
      );
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    _logger.info(
      message: "Notification response received",
      data: {
        'id': response.id,
        'actionId': response.actionId,
        'input': response.input,
        'payload': response.payload,
      }
    );

    // Record interaction
    _analytics.recordNotificationInteraction(
      response.id ?? 0,
      response.actionId ?? 'tap',
    );

    // Convert to our response type
    final notificationResponse = NotificationResponse(
      id: response.id,
      actionId: response.actionId,
      input: response.input,
      payload: response.payload != null 
          ? NotificationPayloadHandler.decode(response.payload!)
          : null,
      type: response.actionId != null 
          ? NotificationResponseType.selectedNotificationAction
          : NotificationResponseType.selectedNotification,
    );

    // Call appropriate handler
    if (response.actionId != null && _onNotificationAction != null) {
      _onNotificationAction!(notificationResponse);
    } else if (_onNotificationTapped != null) {
      _onNotificationTapped!(notificationResponse);
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (_isDisposed) {
      _logger.warning(message: "requestPermission called after dispose");
      return false;
    }

    _logger.debug(message: "Requesting notification permissions...");
    
    try {
      bool? granted = false;
      
      if (Platform.isIOS || Platform.isMacOS) {
        final plugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        granted = await plugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (Platform.isAndroid) {
        final androidImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
          granted = await androidImplementation.requestNotificationsPermission();
        } else {
          granted = true; // Pre-Android 13
        }
      }
      
      final isGranted = granted ?? false;
      _logger.info(message: "Notification permission granted: $isGranted");
      _analytics.recordEvent('permission_requested', {'granted': isGranted});
      
      return isGranted;
    } catch (e, s) {
      _logger.error(
        message: "Error requesting notification permission",
        error: e,
        stackTrace: s
      );
      _analytics.recordError('permission_request_failed', e.toString());
      return false;
    }
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    if (_isDisposed) return false;
    
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await androidPlugin?.areNotificationsEnabled() ?? false;
      } else if (Platform.isIOS) {
        // For iOS, check if permission is granted
        return await requestPermission();
      }
      return true;
    } catch (e) {
      _logger.error(
        message: "Error checking if notifications are enabled",
        error: e,
      );
      return false;
    }
  }

  @override
  Future<void> showNotification(NotificationData notification) async {
    if (!_isInitialized || _isDisposed) {
      _logger.warning(
        message: "Cannot show notification - service not ready",
        data: {'id': notification.id}
      );
      return;
    }

    // Check if can send
    if (!await _shouldSendNotification(notification)) {
      _logger.info(
        message: "Notification suppressed by system conditions",
        data: {'id': notification.id}
      );
      return;
    }

    try {
      final notificationDetails = _buildNotificationDetails(notification);
      final payload = notification.payload != null 
          ? NotificationPayloadHandler.encode(notification.payload!)
          : null;

      await _flutterLocalNotificationsPlugin.show(
        notification.id,
        notification.title,
        notification.body,
        notificationDetails,
        payload: payload,
      );

      _logger.info(
        message: "Notification shown",
        data: {'id': notification.id, 'title': notification.title}
      );
      
      _analytics.recordEvent('notification_shown', {
        'id': notification.id,
        'category': notification.category.toString(),
      });
    } catch (e, s) {
      _logger.error(
        message: "Error showing notification",
        error: e,
        stackTrace: s
      );
      _analytics.recordError('show_notification_failed', e.toString());
    }
  }

  @override
  Future<bool> scheduleNotification(NotificationData notification) async {
    return _scheduleNotificationInternal(notification, null);
  }

  @override
  Future<bool> scheduleNotificationInTimeZone(
    NotificationData notification,
    String timeZoneId,
  ) async {
    return _scheduleNotificationInternal(notification, timeZoneId);
  }

  Future<bool> _scheduleNotificationInternal(
    NotificationData notification,
    String? timeZoneId,
  ) async {
    if (!_isInitialized || _isDisposed) {
      _logger.warning(
        message: "Cannot schedule notification - service not ready",
        data: {'id': notification.id}
      );
      return false;
    }

    // Check if can send
    if (!await _shouldSendNotification(notification)) {
      _logger.info(
        message: "Notification scheduling deferred by system conditions",
        data: {'id': notification.id}
      );
      
      // Queue for retry if enabled
      if (_config.enableRetryOnFailure) {
        await _retryManager.queueForRetry(notification);
      }
      
      return false;
    }

    _logger.info(
      message: "Scheduling notification",
      data: {
        'id': notification.id,
        'title': notification.title,
        'scheduled_time': notification.scheduledDate.toIso8601String(),
        'timezone': timeZoneId ?? 'local',
      }
    );

    try {
      final notificationDetails = _buildNotificationDetails(notification);
      final payload = notification.payload != null 
          ? NotificationPayloadHandler.encode(notification.payload!)
          : null;

      // Calculate time in timezone
      tz.TZDateTime scheduledTZDateTime;
      if (timeZoneId != null) {
        scheduledTZDateTime = _timezoneService.getDateTimeInTimeZone(
          notification.scheduledDate,
          timeZoneId,
        );
      } else {
        scheduledTZDateTime = _timezoneService.getLocalTZDateTime(
          notification.scheduledDate,
        );
      }

      // Check if time is in the future
      final now = tz.TZDateTime.now(scheduledTZDateTime.location);
      if (scheduledTZDateTime.isBefore(now)) {
        _logger.warning(
          message: "Scheduled time is in the past",
          data: {
            'id': notification.id,
            'scheduled': scheduledTZDateTime.toIso8601String(),
            'now': now.toIso8601String(),
          }
        );
        
        // Adjust for repeating notifications
        if (notification.repeatInterval != NotificationRepeatInterval.once) {
          scheduledTZDateTime = _getNextValidScheduleTime(
            scheduledTZDateTime,
            notification.repeatInterval,
          );
          _logger.info(
            message: "Adjusted schedule time to future",
            data: {'new_time': scheduledTZDateTime.toIso8601String()}
          );
        } else {
          return false;
        }
      }

      // Schedule notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notification.id,
        notification.title,
        notification.body,
        scheduledTZDateTime,
        notificationDetails,
        androidScheduleMode: _getAndroidScheduleMode(notification),
        payload: payload,
        matchDateTimeComponents: notification.repeatInterval != NotificationRepeatInterval.once
            ? _mapRepeatIntervalToDateTimeComponents(notification.repeatInterval)
            : null,
      );

      _logger.info(
        message: "Notification scheduled successfully",
        data: {'id': notification.id}
      );
      
      _analytics.recordNotificationScheduled(
        notification.id,
        notification.category.toString(),
      );
      
      return true;
    } catch (e, s) {
      _logger.error(
        message: "Error scheduling notification",
        error: e,
        stackTrace: s
      );
      
      _analytics.recordError('scheduling_failed', e.toString());
      
      // Queue for retry if enabled
      if (_config.enableRetryOnFailure) {
        await _retryManager.queueForRetry(notification);
      }
      
      return false;
    }
  }

  NotificationDetails _buildNotificationDetails(NotificationData notification) {
    // Android details
    AndroidNotificationDetails? androidDetails;
    if (Platform.isAndroid) {
      final channel = _registeredChannels[notification.channelId];
      final actions = notification.actions
          ?.map((action) => AndroidNotificationAction(
                action.id,
                action.title,
                showsUserInterface: action.showsUserInterface,
                cancelNotification: action.cancelNotification,
                icon: action.icon,
              ))
          .toList();

      androidDetails = AndroidNotificationDetails(
        notification.channelId,
        channel?.name ?? notification.channelId,
        channelDescription: channel?.description,
        importance: _mapPriorityToImportance(notification.priority),
        priority: _mapPriorityToAndroidPriority(notification.priority),
        playSound: notification.playSound && notification.soundName != null,
        sound: notification.soundName != null
            ? RawResourceAndroidNotificationSound(
                notification.soundName!.replaceAll(RegExp(r'\.(mp3|wav)$'), ''),
              )
            : null,
        visibility: _mapVisibility(notification.visibility),
        actions: actions,
        styleInformation: const BigTextStyleInformation(''),
        groupKey: notification.groupKey,
        setAsGroupSummary: false,
        ongoing: notification.ongoing,
        autoCancel: notification.autoCancel,
        showWhen: notification.showWhen,
        enableVibration: notification.enableVibration,
        vibrationPattern: notification.vibrationPattern,
        enableLights: notification.enableLights,
        color: notification.color != null ? Color(notification.color!) : null,
        icon: notification.iconName,
      );
    }

    // iOS/macOS details
    DarwinNotificationDetails? darwinDetails;
    if (Platform.isIOS || Platform.isMacOS) {
      darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: notification.playSound,
        sound: notification.soundName,
        threadIdentifier: notification.groupKey ?? notification.channelId,
        interruptionLevel: _mapPriorityToInterruptionLevel(notification.priority),
      );
    }

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  Future<bool> _shouldSendNotification(NotificationData notification) async {
    if (_isDisposed) return false;

    // Check battery optimization
    if (_config.respectBatteryOptimization && notification.respectBatteryOptimizations) {
      try {
        final canSend = await _batteryService.canSendNotification();
        if (!canSend) {
          _logger.info(
            message: "Notification suppressed by battery optimization",
            data: {'id': notification.id}
          );
          _analytics.recordNotificationSuppressed('battery');
          return false;
        }
      } catch (e) {
        _logger.warning(
          message: "Error checking battery status",
          data: {'error': e.toString()}
        );
      }
    }

    // Check Do Not Disturb
    if (_config.respectDoNotDisturb && notification.respectDoNotDisturb) {
      try {
        final dndEnabled = await _doNotDisturbService.isDoNotDisturbEnabled();
        if (dndEnabled) {
          final overrideType = _getDoNotDisturbOverrideType(notification);
          final shouldOverride = await _doNotDisturbService.shouldOverrideDoNotDisturb(overrideType);
          
          if (!shouldOverride) {
            _logger.info(
              message: "Notification suppressed by DND",
              data: {'id': notification.id}
            );
            _analytics.recordNotificationSuppressed('dnd');
            return false;
          }
        }
      } catch (e) {
        _logger.warning(
          message: "Error checking DND status",
          data: {'error': e.toString()}
        );
      }
    }

    return true;
  }

  DoNotDisturbOverrideType _getDoNotDisturbOverrideType(NotificationData notification) {
    // Critical notifications always override
    if (notification.priority == NotificationPriority.critical) {
      return DoNotDisturbOverrideType.critical;
    }
    
    // Prayer notifications override
    if (_isPrayerNotification(notification.notificationTime)) {
      return DoNotDisturbOverrideType.prayer;
    }
    
    // Important athkar override
    if (notification.notificationTime == NotificationTime.morning ||
        notification.notificationTime == NotificationTime.evening) {
      return DoNotDisturbOverrideType.importantAthkar;
    }
    
    return DoNotDisturbOverrideType.none;
  }

  bool _isPrayerNotification(NotificationTime time) {
    return time == NotificationTime.fajr ||
           time == NotificationTime.dhuhr ||
           time == NotificationTime.asr ||
           time == NotificationTime.maghrib ||
           time == NotificationTime.isha;
  }

  tz.TZDateTime _getNextValidScheduleTime(
    tz.TZDateTime originalTime,
    NotificationRepeatInterval interval,
  ) {
    final now = tz.TZDateTime.now(originalTime.location);
    var nextTime = originalTime;
    
    while (nextTime.isBefore(now)) {
      switch (interval) {
        case NotificationRepeatInterval.once:
          // Should not reach here
          return nextTime;
        case NotificationRepeatInterval.daily:
          nextTime = nextTime.add(const Duration(days: 1));
          break;
        case NotificationRepeatInterval.weekly:
          nextTime = nextTime.add(const Duration(days: 7));
          break;
        case NotificationRepeatInterval.monthly:
          nextTime = tz.TZDateTime(
            nextTime.location,
            nextTime.month == 12 ? nextTime.year + 1 : nextTime.year,
            nextTime.month == 12 ? 1 : nextTime.month + 1,
            nextTime.day,
            nextTime.hour,
            nextTime.minute,
            nextTime.second,
          );
          break;
        case NotificationRepeatInterval.yearly:
          nextTime = tz.TZDateTime(
            nextTime.location,
            nextTime.year + 1,
            nextTime.month,
            nextTime.day,
            nextTime.hour,
            nextTime.minute,
            nextTime.second,
          );
          break;
        case NotificationRepeatInterval.custom:
          // For custom, just add one day as fallback
          nextTime = nextTime.add(const Duration(days: 1));
          break;
      }
    }
    
    return nextTime;
  }

  @override
  Future<void> cancelNotification(int id) async {
    if (_isDisposed) return;
    
    _logger.debug(message: "Cancelling notification", data: {'id': id});
    await _flutterLocalNotificationsPlugin.cancel(id);
    _analytics.recordEvent('notification_cancelled', {'id': id});
  }

  @override
  Future<void> cancelNotifications(List<int> ids) async {
    if (_isDisposed) return;
    
    _logger.debug(
      message: "Cancelling multiple notifications",
      data: {'ids': ids}
    );
    
    for (final id in ids) {
      await _flutterLocalNotificationsPlugin.cancel(id);
    }
    
    _analytics.recordEvent('notifications_cancelled', {'count': ids.length});
  }

  @override
  Future<void> cancelAllNotifications() async {
    if (_isDisposed) return;
    
    _logger.debug(message: "Cancelling all notifications");
    await _flutterLocalNotificationsPlugin.cancelAll();
    _analytics.recordEvent('all_notifications_cancelled');
  }

  @override
  Future<void> cancelNotificationsByGroup(String groupKey) async {
    if (_isDisposed) return;
    
    _logger.debug(
      message: "Cancelling notifications by group",
      data: {'groupKey': groupKey}
    );
    
    // Android specific - cancel by group
    if (Platform.isAndroid) {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Get active notifications
        final activeNotifications = await androidPlugin.getActiveNotifications();
        
        // Filter by group and cancel
        for (final notification in activeNotifications) {
          if (notification.groupKey == groupKey) {
            await _flutterLocalNotificationsPlugin.cancel(notification.id!);
          }
        }
      }
    } else {
      // For iOS, we need to track groups manually
      _logger.warning(
        message: "Group cancellation not directly supported on this platform"
      );
    }
    
    _analytics.recordEvent('notifications_cancelled_by_group', {'group': groupKey});
  }

  @override
  Future<List<PendingNotification>> getPendingNotifications() async {
    if (_isDisposed) return [];
    
    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      
      return pendingNotifications.map((notification) {
        Map<String, dynamic>? payload;
        if (notification.payload != null) {
          payload = NotificationPayloadHandler.decode(notification.payload!);
        }
        
        return PendingNotification(
          id: notification.id,
          title: notification.title,
          body: notification.body,
          payload: payload,
        );
      }).toList();
    } catch (e) {
      _logger.error(
        message: "Error getting pending notifications",
        error: e,
      );
      return [];
    }
  }

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async {
    if (_isDisposed || !Platform.isAndroid) return [];
    
    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final activeNotifications = await androidPlugin.getActiveNotifications();
        
        return activeNotifications.map((notification) {
          Map<String, dynamic>? payload;
          if (notification.payload != null) {
            payload = NotificationPayloadHandler.decode(notification.payload!);
          }
          
          return ActiveNotification(
            id: notification.id!,
            channelId: notification.channelId,
            title: notification.title,
            body: notification.body,
            payload: payload,
          );
        }).toList();
      }
    } catch (e) {
      _logger.error(
        message: "Error getting active notifications",
        error: e,
      );
    }
    
    return [];
  }

  @override
  Future<void> updateBadgeCount(int count) async {
    if (_isDisposed || !Platform.isIOS) return;
    
    try {
      // iOS specific badge update
      _logger.debug(
        message: "Updating badge count",
        data: {'count': count}
      );
      // Implementation depends on additional iOS setup
    } catch (e) {
      _logger.error(
        message: "Error updating badge count",
        error: e,
      );
    }
  }

  @override
  Future<void> clearBadge() async {
    await updateBadgeCount(0);
  }

  @override
  void setNotificationTapHandler(Function(NotificationResponse) handler) {
    _onNotificationTapped = handler;
  }

  @override
  void setNotificationActionHandler(Function(NotificationResponse) handler) {
    _onNotificationAction = handler;
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    
    _logger.debug(message: "Disposing NotificationServiceImpl");
    _isDisposed = true;
    _isInitialized = false;
    _onNotificationTapped = null;
    _onNotificationAction = null;
    _registeredChannels.clear();
    
    // Cleanup resources
    await _retryManager.dispose();
    _analytics.dispose();
  }

  // Helper methods

  AndroidScheduleMode _getAndroidScheduleMode(NotificationData notification) {
    if (notification.priority == NotificationPriority.critical ||
        !notification.respectBatteryOptimizations) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    return AndroidScheduleMode.exact;
  }

  DateTimeComponents? _mapRepeatIntervalToDateTimeComponents(
    NotificationRepeatInterval interval,
  ) {
    switch (interval) {
      case NotificationRepeatInterval.once:
        return null;
      case NotificationRepeatInterval.daily:
        return DateTimeComponents.time;
      case NotificationRepeatInterval.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case NotificationRepeatInterval.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case NotificationRepeatInterval.yearly:
      case NotificationRepeatInterval.custom:
        return null; // Not directly supported
    }
  }

  Importance _mapPriorityToImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.min:
        return Importance.min;
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.max:
      case NotificationPriority.critical:
        return Importance.max;
    }
  }

  Priority _mapPriorityToAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.min:
        return Priority.min;
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.max:
      case NotificationPriority.critical:
        return Priority.max;
    }
  }

  NotificationVisibility? _mapVisibility(NotificationVisibility visibility) {
    switch (visibility) {
      case NotificationVisibility.public:
        return NotificationVisibility.public;
      case NotificationVisibility.private:
        return NotificationVisibility.private;
      case NotificationVisibility.secret:
        return NotificationVisibility.secret;
    }
  }

  InterruptionLevel _mapPriorityToInterruptionLevel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.min:
      case NotificationPriority.low:
        return InterruptionLevel.passive;
      case NotificationPriority.normal:
        return InterruptionLevel.active;
      case NotificationPriority.high:
        return InterruptionLevel.timeSensitive;
      case NotificationPriority.max:
      case NotificationPriority.critical:
        return InterruptionLevel.critical;
    }
  }
}