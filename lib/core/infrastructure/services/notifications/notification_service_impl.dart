
// lib/core/infrastructure/services/notifications/notification_service_impl.dart

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:athkar_app/core/infrastructure/services/device/do_not_disturb/do_not_disturb_service.dart' as dnd;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'models/notification_data.dart' as models;
import '../device/battery/battery_service.dart';
import '../timezone/timezone_service.dart';
import '../logging/logger_service.dart';
import '../storage/storage_service.dart';
import 'utils/notification_payload_handler.dart';
import 'utils/notification_analytics.dart';
import 'utils/notification_retry_manager.dart';
import '../../../../app/di/service_locator.dart';
import 'notification_service.dart';

/// Callback for background notifications
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  if (kDebugMode) {
    print('[NotificationService] Background tap: ${notificationResponse.id}');
  }
}

/// Implementation of notification service
class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final BatteryService _batteryService;
  final dnd.DoNotDisturbService _doNotDisturbService;
  final TimezoneService _timezoneService;
  final StorageService _storageService;
  final LoggerService _logger;
  final NotificationAnalytics _analytics;
  final NotificationRetryManager _retryManager;

  // Service state
  models.NotificationConfig _config = models.NotificationConfig();
  bool _isInitialized = false;
  bool _isDisposed = false;

  // Callbacks
  Function(models.NotificationResponse)? _onNotificationTapped;
  Function(models.NotificationResponse)? _onNotificationAction;
  Function(models.NotificationData)? _onNotificationReceived;
  
  // Registered channels
  final Map<String, models.NotificationChannel> _registeredChannels = {};
  
  // Progress notifications tracking
  final Map<int, Timer> _progressTimers = {};

  NotificationServiceImpl(
    this._flutterLocalNotificationsPlugin,
    this._batteryService,
    this._doNotDisturbService,
    this._timezoneService, {
    StorageService? storageService,
    LoggerService? logger,
    NotificationAnalytics? analytics,
    NotificationRetryManager? retryManager,
  })  : _storageService = storageService ?? getIt<StorageService>(),
        _logger = logger ?? getIt<LoggerService>(),
        _analytics = analytics ?? NotificationAnalytics(logger: logger ?? getIt<LoggerService>()),
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
    models.NotificationChannel? defaultChannel,
    List<models.NotificationChannel>? channels,
    models.NotificationConfig? config,
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
      // Set configuration
      if (config != null) {
        _config = config;
      }

      // Initialize timezones
      await _timezoneService.initializeTimeZones();
      _logger.debug(message: "Timezones initialized for notifications");

      // Android settings
      final AndroidInitializationSettings androidInitSettings =
          AndroidInitializationSettings(defaultIcon ?? '@mipmap/ic_launcher');

      // iOS/macOS settings with all permissions disabled initially
      const DarwinInitializationSettings darwinInitSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        requestCriticalPermission: false,
        requestProvisionalPermission: false,
        notificationCategories: [],
      );

      // Linux settings
      final LinuxInitializationSettings linuxInitSettings =
          LinuxInitializationSettings(
        defaultActionName: 'Open notification',
        defaultIcon: AssetsLinuxIcon(defaultIcon ?? 'icons/app_icon.png'),
      );

      final InitializationSettings initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: darwinInitSettings,
        macOS: darwinInitSettings,
        linux: linuxInitSettings,
      );

      // Initialize plugin
      final bool? initialized = await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      if (initialized != true) {
        throw Exception('Failed to initialize notifications plugin');
      }

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

      // Load saved notification preferences
      await _loadNotificationPreferences();

      _isInitialized = true;
      _logger.info(message: "NotificationService initialized successfully");
      
      _analytics.recordEvent('notification_service_initialized', {
        'channels_count': _registeredChannels.length,
        'has_custom_config': config != null,
      });
      
      _logger.logEvent('notification_service_ready', parameters: {
        'channels': _registeredChannels.length,
      });
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

    // Default channel
    final defaultChannel = models.NotificationChannel(
      id: 'default_channel',
      name: 'Default Notifications',
      description: 'Default notification channel for general notifications',
      importance: models.NotificationPriority.normal,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // High priority channel
    final highPriorityChannel = models.NotificationChannel(
      id: 'high_priority_channel',
      name: 'Important Notifications',
      description: 'High priority notifications that require immediate attention',
      importance: models.NotificationPriority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    // Reminder channel
    final reminderChannel = models.NotificationChannel(
      id: 'reminder_channel',
      name: 'Reminders',
      description: 'Scheduled reminders and alerts',
      importance: models.NotificationPriority.normal,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Service channel (for ongoing notifications)
    final serviceChannel = models.NotificationChannel(
      id: 'service_channel',
      name: 'Service Notifications',
      description: 'Ongoing service notifications',
      importance: models.NotificationPriority.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    await createNotificationChannel(defaultChannel);
    await createNotificationChannel(highPriorityChannel);
    await createNotificationChannel(reminderChannel);
    await createNotificationChannel(serviceChannel);
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final prefs = _storageService.getMap('notification_preferences');
      if (prefs != null) {
        _logger.debug(
          message: 'Notification preferences loaded',
          data: prefs,
        );
      }
    } catch (e) {
      _logger.warning(
        message: 'Failed to load notification preferences',
        data: {'error': e.toString()},
      );
    }
  }

  @override
  Future<void> createNotificationChannel(models.NotificationChannel channel) async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return;

    try {
      final androidChannel = AndroidNotificationChannel(
        channel.id,
        channel.name,
        description: channel.description,
        importance: _mapPriorityToImportance(channel.importance),
        playSound: channel.playSound,
        enableVibration: channel.enableVibration,
        enableLights: channel.enableLights,
        showBadge: channel.showBadge,
        sound: channel.soundName != null
            ? RawResourceAndroidNotificationSound(channel.soundName!)
            : null,
        vibrationPattern: channel.vibrationPattern != null
            ? Int64List.fromList(channel.vibrationPattern!)
            : null,
        ledColor: channel.lightColor != null ? Color(channel.lightColor!) : null,
      );

      await androidPlugin.createNotificationChannel(androidChannel);
      _registeredChannels[channel.id] = channel;
      
      _logger.debug(
        message: "Notification channel created",
        data: {'channelId': channel.id, 'name': channel.name}
      );
      
      _analytics.recordEvent('channel_created', {
        'channel_id': channel.id,
        'importance': channel.importance.toString(),
      });
    } catch (e) {
      _logger.error(
        message: 'Failed to create notification channel',
        error: e,
      );
    }
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
  
  @override
  Future<List<models.NotificationChannel>> getNotificationChannels() async {
    return _registeredChannels.values.toList();
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
    final notificationResponse = models.NotificationResponse(
      id: response.id,
      actionId: response.actionId,
      input: response.input,
      payload: response.payload != null 
          ? NotificationPayloadHandler.decode(response.payload!)
          : null,
      type: response.actionId != null 
          ? models.NotificationResponseType.selectedNotificationAction
          : models.NotificationResponseType.selectedNotification,
    );

    // Call appropriate handler
    if (response.actionId != null && _onNotificationAction != null) {
      _onNotificationAction!(notificationResponse);
    } else if (_onNotificationTapped != null) {
      _onNotificationTapped!(notificationResponse);
    }
    
    _logger.logEvent('notification_interacted', parameters: {
      'id': response.id,
      'action': response.actionId ?? 'tap',
      'has_payload': response.payload != null,
    });
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
          provisional: false,
          critical: false,
        );
      } else if (Platform.isAndroid) {
        final androidImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
          // Android 13+ requires explicit permission
          granted = await androidImplementation.requestNotificationsPermission();
        } else {
          granted = true; // Pre-Android 13
        }
      } else {
        // Other platforms
        granted = true;
      }
      
      final isGranted = granted ?? false;
      _logger.info(message: "Notification permission granted: $isGranted");
      _analytics.recordEvent('permission_requested', {'granted': isGranted});
      
      if (isGranted) {
        _logger.logEvent('notification_permission_granted');
      } else {
        _logger.logEvent('notification_permission_denied');
      }
      
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
      } else if (Platform.isIOS || Platform.isMacOS) {
        // For iOS/macOS, we need to check permission status
        final iosPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        
        // Request status without prompting
        final settings = await iosPlugin?.checkPermissions();
        return settings?.isEnabled ?? false;
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
  Future<void> showNotification(models.NotificationData notification) async {
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
        data: {'id': notification.id, 'title': notification.title}
      );
      return;
    }

    try {
      final notificationDetails = await _buildNotificationDetails(notification);
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
      
      _analytics.recordNotificationScheduled(
        notification.id,
        notification.category.toString(),
      );
      
      // Call received handler if in foreground
      _onNotificationReceived?.call(notification);
      
      _logger.logEvent('notification_shown', parameters: {
        'id': notification.id,
        'category': notification.category.toString(),
        'priority': notification.priority.toString(),
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
  Future<void> showProgressNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    int maxProgress = 100,
    bool indeterminate = false,
    String? channelId,
  }) async {
    if (!_isInitialized || _isDisposed) return;
    
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId ?? 'progress_channel',
        'Progress Notifications',
        channelDescription: 'Notifications showing progress',
        importance: Importance.low,
        priority: Priority.low,
        onlyAlertOnce: true,
        showProgress: true,
        progress: progress,
        maxProgress: maxProgress,
        indeterminate: indeterminate,
      );
      
      final details = NotificationDetails(android: androidDetails);
      
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        details,
      );
      
      _logger.debug(
        message: 'Progress notification shown',
        data: {
          'id': id,
          'progress': '$progress/$maxProgress',
          'indeterminate': indeterminate,
        },
      );
    } catch (e) {
      _logger.error(
        message: 'Error showing progress notification',
        error: e,
      );
    }
  }
  
  @override
  Future<void> showGroupedNotification({
    required String groupKey,
    required List<models.NotificationData> notifications,
    required models.NotificationData summary,
  }) async {
    if (!_isInitialized || _isDisposed) return;
    
    try {
      // Show individual notifications
      for (final notification in notifications) {
        await showNotification(
          notification.copyWith(groupKey: groupKey),
        );
      }
      
      // Show summary notification
      await showNotification(
        summary.copyWith(
          groupKey: groupKey,
          additionalData: {
            'is_group_summary': true,
            'notifications_count': notifications.length,
          },
        ),
      );
      
      _logger.info(
        message: 'Grouped notifications shown',
        data: {
          'group': groupKey,
          'count': notifications.length,
        },
      );
    } catch (e) {
      _logger.error(
        message: 'Error showing grouped notifications',
        error: e,
      );
    }
  }

  @override
  Future<bool> scheduleNotification(models.NotificationData notification) async {
    return _scheduleNotificationInternal(notification, null);
  }

  @override
  Future<bool> scheduleNotificationInTimeZone(
    models.NotificationData notification,
    String timeZoneId,
  ) async {
    return _scheduleNotificationInternal(notification, timeZoneId);
  }
  
  @override
  Future<bool> scheduleRepeatingNotification(
    models.NotificationData notification,
    Duration interval,
  ) async {
    if (!_isInitialized || _isDisposed) return false;
    
    try {
      // Calculate repeat interval type
      models.NotificationRepeatInterval repeatInterval;
      if (interval.inHours == 1) {
        repeatInterval = models.NotificationRepeatInterval.hourly;
      } else if (interval.inDays == 1) {
        repeatInterval = models.NotificationRepeatInterval.daily;
      } else if (interval.inDays == 7) {
        repeatInterval = models.NotificationRepeatInterval.weekly;
      } else {
        // For custom intervals, we'll use periodic scheduling
        repeatInterval = models.NotificationRepeatInterval.custom;
      }
      
      final repeatingNotification = notification.copyWith(
        repeatInterval: repeatInterval,
        customSchedulingData: {
          'interval_seconds': interval.inSeconds,
        },
      );
      
      return await scheduleNotification(repeatingNotification);
    } catch (e) {
      _logger.error(
        message: 'Error scheduling repeating notification',
        error: e,
      );
      return false;
    }
  }

  Future<bool> _scheduleNotificationInternal(
    models.NotificationData notification,
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
        _analytics.recordNotificationSuppressed('system_conditions');
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
        'repeat': notification.repeatInterval.toString(),
      }
    );

    try {
      final notificationDetails = await _buildNotificationDetails(notification);
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
        if (notification.repeatInterval != models.NotificationRepeatInterval.once) {
          scheduledTZDateTime = _getNextValidScheduleTime(
            scheduledTZDateTime,
            notification.repeatInterval,
            notification.customSchedulingData,
          );
          _logger.info(
            message: "Adjusted schedule time to future",
            data: {'new_time': scheduledTZDateTime.toIso8601String()}
          );
        } else {
          // Show immediately if in the past and not repeating
          await showNotification(notification);
          return true;
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
        matchDateTimeComponents: notification.repeatInterval != models.NotificationRepeatInterval.once
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
      
      _logger.logEvent('notification_scheduled', parameters: {
        'id': notification.id,
        'category': notification.category.toString(),
        'repeat': notification.repeatInterval.toString(),
        'timezone': timeZoneId ?? 'local',
      });
      
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

  Future<NotificationDetails> _buildNotificationDetails(models.NotificationData notification) async {
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
                icon: action.icon != null 
                    ? DrawableResourceAndroidBitmap(action.icon!)
                    : null,
              ))
          .toList();

      // Handle large icon if provided
      AndroidBitmap<Object>? largeIcon;
      if (notification.additionalData?['large_icon'] != null) {
        largeIcon = await _processLargeIcon(
          notification.additionalData!['large_icon'],
        );
      }

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
        styleInformation: _getStyleInformation(notification),
        groupKey: notification.groupKey,
        setAsGroupSummary: notification.additionalData?['is_group_summary'] == true,
        ongoing: notification.ongoing,
        autoCancel: notification.autoCancel,
        showWhen: notification.showWhen,
        when: notification.showWhen ? notification.scheduledDate.millisecondsSinceEpoch : null,
        enableVibration: notification.enableVibration,
        vibrationPattern: notification.vibrationPattern != null 
            ? Int64List.fromList(notification.vibrationPattern!)
            : null,
        enableLights: notification.enableLights,
        color: notification.color != null ? Color(notification.color!) : null,
        ledColor: notification.color != null ? Color(notification.color!) : null,
        ledOnMs: 1000,
        ledOffMs: 500,
        icon: notification.iconName,
        largeIcon: largeIcon,
        tag: notification.additionalData?['tag'] as String?,
        usesChronometer: notification.additionalData?['uses_chronometer'] as bool? ?? false,
        showProgress: false,
        category: _mapCategoryToAndroid(notification.category),
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
        categoryIdentifier: _mapCategoryToiOS(notification.category),
        interruptionLevel: _mapPriorityToInterruptionLevel(notification.priority),
        attachments: await _processiOSAttachments(notification),
      );
    }

    // Linux details
    LinuxNotificationDetails? linuxDetails;
    if (Platform.isLinux) {
      linuxDetails = LinuxNotificationDetails(
        urgency: _mapPriorityToLinuxUrgency(notification.priority),
        category: _mapCategoryToLinux(notification.category),
        sound: notification.playSound 
            ? ThemeLinuxSound('message-new-instant')
            : null,
      );
    }

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
    );
  }

  StyleInformation? _getStyleInformation(models.NotificationData notification) {
    // Big text style for long content
    if (notification.body.length > 40) {
      return BigTextStyleInformation(
        notification.body,
        contentTitle: notification.title,
        summaryText: notification.additionalData?['summary'] as String?,
      );
    }
    
    // Inbox style for multiple lines
    final lines = notification.additionalData?['lines'] as List<String>?;
    if (lines != null && lines.isNotEmpty) {
      return InboxStyleInformation(
        lines,
        contentTitle: notification.title,
        summaryText: '${lines.length} items',
      );
    }
    
    // Default style
    return null;
  }

  Future<AndroidBitmap<Object>?> _processLargeIcon(dynamic iconData) async {
    try {
      if (iconData is String) {
        // Asset path
        if (iconData.startsWith('assets/')) {
          return DrawableResourceAndroidBitmap(iconData);
        }
        // File path
        return FilePathAndroidBitmap(iconData);
      }
      return null;
    } catch (e) {
      _logger.warning(
        message: 'Failed to process large icon',
        data: {'error': e.toString()},
      );
      return null;
    }
  }

  Future<List<DarwinNotificationAttachment>> _processiOSAttachments(
    models.NotificationData notification,
  ) async {
    final attachments = <DarwinNotificationAttachment>[];
    
    try {
      final attachmentPaths = notification.additionalData?['attachments'] as List<String>?;
      if (attachmentPaths != null) {
        for (final path in attachmentPaths) {
          attachments.add(DarwinNotificationAttachment(path));
        }
      }
    } catch (e) {
      _logger.warning(
        message: 'Failed to process iOS attachments',
        data: {'error': e.toString()},
      );
    }
    
    return attachments;
  }

  Future<bool> _shouldSendNotification(models.NotificationData notification) async {
    if (_isDisposed) return false;

    // Check battery optimization
    if (_config.respectSystemSettings && notification.respectSystemSettings) {
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

    // Check Do Not Disturb with custom handler
    if (_config.respectSystemSettings && notification.respectSystemSettings) {
      try {
        final dndEnabled = await _doNotDisturbService.isDoNotDisturbEnabled();
        if (dndEnabled) {
          // Use custom handler if provided
          if (_config.systemConstraintHandler != null) {
            final shouldOverride = await _config.systemConstraintHandler!
                .shouldSendNotification(notification);
            
            if (!shouldOverride) {
              _logger.info(
                message: "Notification suppressed by DND",
                data: {'id': notification.id}
              );
              _analytics.recordNotificationSuppressed('dnd');
              return false;
            }
          } else {
            // Default behavior - check priority
            final shouldOverride = await _doNotDisturbService
                .shouldOverrideDoNotDisturb(_mapToSystemOverridePriority(notification.priority));
            
            if (!shouldOverride) {
              _logger.info(
                message: "Notification suppressed by DND",
                data: {'id': notification.id}
              );
              _analytics.recordNotificationSuppressed('dnd');
              return false;
            }
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

  dnd.SystemOverridePriority _mapToSystemOverridePriority(models.NotificationPriority priority) {
    switch (priority) {
      case models.NotificationPriority.min:
      case models.NotificationPriority.low:
        return dnd.SystemOverridePriority.low;
      case models.NotificationPriority.normal:
        return dnd.SystemOverridePriority.medium;
      case models.NotificationPriority.high:
        return dnd.SystemOverridePriority.high;
      case models.NotificationPriority.max:
      case models.NotificationPriority.critical:
        return dnd.SystemOverridePriority.critical;
    }
  }

  tz.TZDateTime _getNextValidScheduleTime(
    tz.TZDateTime originalTime,
    models.NotificationRepeatInterval interval,
    Map<String, dynamic>? customData,
  ) {
    final now = tz.TZDateTime.now(originalTime.location);
    var nextTime = originalTime;
    
    while (nextTime.isBefore(now)) {
      switch (interval) {
        case models.NotificationRepeatInterval.once:
          // Should not reach here
          return nextTime;
        case models.NotificationRepeatInterval.hourly:
          nextTime = nextTime.add(const Duration(hours: 1));
          break;
        case models.NotificationRepeatInterval.daily:
          nextTime = nextTime.add(const Duration(days: 1));
          break;
        case models.NotificationRepeatInterval.weekly:
          nextTime = nextTime.add(const Duration(days: 7));
          break;
        case models.NotificationRepeatInterval.monthly:
          // Add one month properly
          if (nextTime.month == 12) {
            nextTime = tz.TZDateTime(
              nextTime.location,
              nextTime.year + 1,
              1,
              nextTime.day,
              nextTime.hour,
              nextTime.minute,
              nextTime.second,
            );
          } else {
            nextTime = tz.TZDateTime(
              nextTime.location,
              nextTime.year,
              nextTime.month + 1,
              math.min(nextTime.day, _daysInMonth(nextTime.year, nextTime.month + 1)),
              nextTime.hour,
              nextTime.minute,
              nextTime.second,
            );
          }
          break;
        case models.NotificationRepeatInterval.yearly:
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
        case models.NotificationRepeatInterval.custom:
          // Use custom interval if provided
          final intervalSeconds = customData?['interval_seconds'] as int?;
          if (intervalSeconds != null) {
            nextTime = nextTime.add(Duration(seconds: intervalSeconds));
          } else {
            // Default to daily
            nextTime = nextTime.add(const Duration(days: 1));
          }
          break;
      }
    }
    
    return nextTime;
  }

  int _daysInMonth(int year, int month) {
    if (month == 2) {
      // February - check for leap year
      return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
    } else if ([4, 6, 9, 11].contains(month)) {
      return 30;
    } else {
      return 31;
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    if (_isDisposed) return;
    
    _logger.debug(message: "Cancelling notification", data: {'id': id});
    
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      
      // Cancel any progress timer
      _progressTimers[id]?.cancel();
      _progressTimers.remove(id);
      
      _analytics.recordEvent('notification_cancelled', {'id': id});
    } catch (e) {
      _logger.error(
        message: 'Error cancelling notification',
        error: e,
      );
    }
  }

  @override
  Future<void> cancelNotifications(List<int> ids) async {
    if (_isDisposed) return;
    
    _logger.debug(
      message: "Cancelling multiple notifications",
      data: {'ids': ids}
    );
    
    for (final id in ids) {
      await cancelNotification(id);
    }
    
    _analytics.recordEvent('notifications_cancelled', {'count': ids.length});
  }

  @override
  Future<void> cancelAllNotifications() async {
    if (_isDisposed) return;
    
    _logger.debug(message: "Cancelling all notifications");
    
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      
      // Cancel all progress timers
      for (final timer in _progressTimers.values) {
        timer.cancel();
      }
      _progressTimers.clear();
      
      _analytics.recordEvent('all_notifications_cancelled');
      _logger.logEvent('all_notifications_cancelled');
    } catch (e) {
      _logger.error(
        message: 'Error cancelling all notifications',
        error: e,
      );
    }
  }

  @override
  Future<void> cancelNotificationsByGroup(String groupKey) async {
    if (_isDisposed) return;
    
    _logger.debug(
      message: "Cancelling notifications by group",
      data: {'groupKey': groupKey}
    );
    
    try {
      // Android specific - cancel by group
      if (Platform.isAndroid) {
        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          // Get active notifications
          final activeNotifications = await androidPlugin.getActiveNotifications();
          
          // Filter by group and cancel
          for (final notification in activeNotifications) {
            if (notification.groupKey == groupKey && notification.id != null) {
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
    } catch (e) {
      _logger.error(
        message: 'Error cancelling notifications by group',
        error: e,
      );
    }
  }
  
  @override
  Future<void> cancelNotificationsByTag(String tag) async {
    if (_isDisposed || !Platform.isAndroid) return;
    
    _logger.debug(
      message: "Cancelling notifications by tag",
      data: {'tag': tag}
    );
    
    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Get active notifications
        final activeNotifications = await androidPlugin.getActiveNotifications();
        
        // Filter by tag and cancel
        for (final notification in activeNotifications) {
          if (notification.tag == tag && notification.id != null) {
            await _flutterLocalNotificationsPlugin.cancel(notification.id!);
          }
        }
      }
      
      _analytics.recordEvent('notifications_cancelled_by_tag', {'tag': tag});
    } catch (e) {
      _logger.error(
        message: 'Error cancelling notifications by tag',
        error: e,
      );
    }
  }

  @override
  Future<List<models.PendingNotification>> getPendingNotifications() async {
    if (_isDisposed) return [];
    
    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      
      return pendingNotifications.map((notification) {
        Map<String, dynamic>? payload;
        if (notification.payload != null) {
          payload = NotificationPayloadHandler.decode(notification.payload!);
        }
        
        return models.PendingNotification(
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
  Future<List<models.ActiveNotification>> getActiveNotifications() async {
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
          
          return models.ActiveNotification(
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
      
      // This requires additional native implementation
      // You might need to use a package like flutter_app_badger
      
      _logger.logEvent('badge_updated', parameters: {'count': count});
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
  void setNotificationTapHandler(Function(models.NotificationResponse) handler) {
    _onNotificationTapped = handler;
    _logger.debug(message: 'Notification tap handler set');
  }

  @override
  void setNotificationActionHandler(Function(models.NotificationResponse) handler) {
    _onNotificationAction = handler;
    _logger.debug(message: 'Notification action handler set');
  }
  
  @override
  void setNotificationReceivedHandler(Function(models.NotificationData) handler) {
    _onNotificationReceived = handler;
    _logger.debug(message: 'Notification received handler set');
  }
  
  @override
  Map<String, dynamic> getAnalytics() {
    return _analytics.getStats();
  }

  @override
  void setConfiguration(models.NotificationConfig config) {
    _config = config;
    _logger.debug(message: "Notification configuration updated");
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    
    _logger.debug(message: "Disposing NotificationServiceImpl");
    _isDisposed = true;
    _isInitialized = false;
    _onNotificationTapped = null;
    _onNotificationAction = null;
    _onNotificationReceived = null;
    _registeredChannels.clear();
    
    // Cancel all progress timers
    for (final timer in _progressTimers.values) {
      timer.cancel();
    }
    _progressTimers.clear();
    
    // Cleanup resources
    await _retryManager.dispose();
    _analytics.dispose();
    
    _logger.info(message: 'NotificationService disposed');
  }

  // Helper methods

  AndroidScheduleMode _getAndroidScheduleMode(models.NotificationData notification) {
    if (notification.priority == models.NotificationPriority.critical ||
        !notification.respectSystemSettings) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    } else if (notification.priority == models.NotificationPriority.high) {
      return AndroidScheduleMode.exact;
    }
    return AndroidScheduleMode.inexact;
  }

  DateTimeComponents? _mapRepeatIntervalToDateTimeComponents(
    models.NotificationRepeatInterval interval,
  ) {
    switch (interval) {
      case models.NotificationRepeatInterval.once:
        return null;
      case models.NotificationRepeatInterval.hourly:
        return DateTimeComponents.time;
      case models.NotificationRepeatInterval.daily:
        return DateTimeComponents.time;
      case models.NotificationRepeatInterval.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case models.NotificationRepeatInterval.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case models.NotificationRepeatInterval.yearly:
      case models.NotificationRepeatInterval.custom:
        return null; // Not directly supported
    }
  }

  Importance _mapPriorityToImportance(models.NotificationPriority priority) {
    switch (priority) {
      case models.NotificationPriority.min:
        return Importance.min;
      case models.NotificationPriority.low:
        return Importance.low;
      case models.NotificationPriority.normal:
        return Importance.defaultImportance;
      case models.NotificationPriority.high:
        return Importance.high;
      case models.NotificationPriority.max:
      case models.NotificationPriority.critical:
        return Importance.max;
    }
  }

  Priority _mapPriorityToAndroidPriority(models.NotificationPriority priority) {
    switch (priority) {
      case models.NotificationPriority.min:
        return Priority.min;
      case models.NotificationPriority.low:
        return Priority.low;
      case models.NotificationPriority.normal:
        return Priority.defaultPriority;
      case models.NotificationPriority.high:
        return Priority.high;
      case models.NotificationPriority.max:
      case models.NotificationPriority.critical:
        return Priority.max;
    }
  }

  NotificationVisibility? _mapVisibility(models.NotificationVisibility visibility) {
    switch (visibility) {
      case models.NotificationVisibility.public:
        return NotificationVisibility.public;
      case models.NotificationVisibility.private:
        return NotificationVisibility.private;
      case models.NotificationVisibility.secret:
        return NotificationVisibility.secret;
    }
  }

  InterruptionLevel _mapPriorityToInterruptionLevel(models.NotificationPriority priority) {
    switch (priority) {
      case models.NotificationPriority.min:
      case models.NotificationPriority.low:
        return InterruptionLevel.passive;
      case models.NotificationPriority.normal:
        return InterruptionLevel.active;
      case models.NotificationPriority.high:
        return InterruptionLevel.timeSensitive;
      case models.NotificationPriority.max:
      case models.NotificationPriority.critical:
        return InterruptionLevel.critical;
    }
  }
  
  LinuxNotificationUrgency _mapPriorityToLinuxUrgency(models.NotificationPriority priority) {
    switch (priority) {
      case models.NotificationPriority.min:
      case models.NotificationPriority.low:
        return LinuxNotificationUrgency.low;
      case models.NotificationPriority.normal:
        return LinuxNotificationUrgency.normal;
      case models.NotificationPriority.high:
      case models.NotificationPriority.max:
      case models.NotificationPriority.critical:
        return LinuxNotificationUrgency.critical;
    }
  }
  
  AndroidNotificationCategory? _mapCategoryToAndroid(models.NotificationCategory category) {
    switch (category) {
      case models.NotificationCategory.alarm:
        return AndroidNotificationCategory.alarm;
      case models.NotificationCategory.call:
        return AndroidNotificationCategory.call;
      case models.NotificationCategory.email:
        return AndroidNotificationCategory.email;
      case models.NotificationCategory.error:
        return AndroidNotificationCategory.error;
      case models.NotificationCategory.event:
        return AndroidNotificationCategory.event;
      case models.NotificationCategory.message:
        return AndroidNotificationCategory.message;
      case models.NotificationCategory.progress:
        return AndroidNotificationCategory.progress;
      case models.NotificationCategory.promo:
        return AndroidNotificationCategory.promo;
      case models.NotificationCategory.recommendation:
        return AndroidNotificationCategory.recommendation;
      case models.NotificationCategory.reminder:
        return AndroidNotificationCategory.reminder;
      case models.NotificationCategory.service:
        return AndroidNotificationCategory.service;
      case models.NotificationCategory.social:
        return AndroidNotificationCategory.social;
      case models.NotificationCategory.status:
        return AndroidNotificationCategory.status;
      case models.NotificationCategory.system:
        return AndroidNotificationCategory.system;
      case models.NotificationCategory.transport:
        return AndroidNotificationCategory.transport;
      default:
        return null;
    }
  }
  
  String? _mapCategoryToiOS(models.NotificationCategory category) {
    // iOS uses string identifiers for categories
    return category.toString().split('.').last;
  }
  
  LinuxNotificationCategory? _mapCategoryToLinux(models.NotificationCategory category) {
    switch (category) {
      case models.NotificationCategory.email:
        return LinuxNotificationCategory.email;
      case models.NotificationCategory.message:
        return LinuxNotificationCategory.im;
      case models.NotificationCategory.system:
        return LinuxNotificationCategory.device;
      default:
        return null;
    }
  }
}