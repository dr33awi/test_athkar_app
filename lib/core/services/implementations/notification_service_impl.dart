// lib/core/services/implementations/notification_service_impl.dart
import 'dart:convert';
import 'dart:io'; // Platform is used
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/material.dart'; // Likely unused if Logger is implemented
import 'package:timezone/timezone.dart' as tz;
import '../interfaces/notification_service.dart' as app_notification;
import '../interfaces/battery_service.dart';
import '../interfaces/do_not_disturb_service.dart';
import '../interfaces/timezone_service.dart';
import '../interfaces/logger_service.dart';
import '../../../app/di/service_locator.dart'; // Assuming for DI
// import '../../../main.dart'; // This import seems problematic, onSelectNotification is static

// Callback for when a notification is tapped (foreground)
@pragma('vm:entry-point') // Required for background isolate
void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) {
  final LoggerService logger = getIt<LoggerService>(); // Get logger instance
  logger.info(message: 'Notification response received (foreground/background tap)', data: {
    'id': notificationResponse.id,
    'actionId': notificationResponse.actionId,
    'payload': notificationResponse.payload,
    'input': notificationResponse.input,
  });
  // Here, you would typically navigate to a specific screen or handle the action
  // Example: MyApp.navigatorKey.currentState?.pushNamed('/details', arguments: notificationResponse.payload);
  // As MyApp.navigatorKey is not directly accessible here in a static/top-level function,
  // consider using a stream/event bus, or a more robust navigation handling mechanism for notifications.
}

// Callback for when a notification is tapped (background - older versions, less common now)
// onDidReceiveBackgroundNotificationResponse is preferred for background actions.
// For simplicity and modern approach, focusing on onDidReceiveNotificationResponse
// and background message handlers for FCM/other push services.

class NotificationServiceImpl implements app_notification.NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final BatteryService _batteryService;
  final DoNotDisturbService _doNotDisturbService;
  final TimezoneService _timezoneService;
  final LoggerService _logger;

  bool _respectBatteryOptimizations = true;
  bool _respectDoNotDisturb = true;
  bool _isInitialized = false;
  bool _isDisposed = false;

  NotificationServiceImpl(
    this._flutterLocalNotificationsPlugin,
    this._batteryService,
    this._doNotDisturbService,
    this._timezoneService, {
    LoggerService? logger, // Allow logger injection
  }) : _logger = logger ?? getIt<LoggerService>() {
    _logger.debug(message: "NotificationServiceImpl constructor called.");
  }


  @override
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) {
      _logger.debug(
          message:
              "NotificationService initialize skipped: already initialized or disposed.");
      return;
    }
    _logger.info(message: "Initializing NotificationService...");

    try {
      await _timezoneService.initializeTimeZones();
      _logger.debug(message: "Timezones initialized for notifications.");

      const AndroidInitializationSettings androidInitSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings darwinInitSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false, // Permissions will be requested separately
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );

      final InitializationSettings initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: darwinInitSettings,
        macOS: darwinInitSettings, // Assuming same settings for macOS
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: onDidReceiveNotificationResponse, // Using the same for background tap
      );

      _isInitialized = true;
      _logger.info(message: "NotificationService initialized successfully.");
    } catch (e, s) {
      _logger.error(
          message: "Error initializing NotificationService",
          error: e,
          stackTrace: s);
      _isInitialized = false; // Ensure it's marked as not initialized on error
    }
  }

  void _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // Handle legacy iOS notifications received while app is in foreground
    _logger.info(
        message: "Legacy iOS onDidReceiveLocalNotification",
        data: {'id': id, 'title': title, 'body': body, 'payload': payload});
    // Display a dialog or other UI for foreground iOS notifications if needed
  }


  @override
  Future<bool> requestPermission() async {
    if (_isDisposed) {
      _logger.warning(message: "requestPermission called after dispose.");
      return false;
    }
    _logger.debug(message: "Requesting notification permissions...");
    bool? granted = false;
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        granted = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        granted ??= await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      } else if (Platform.isAndroid) {
        // For Android 13+, POST_NOTIFICATIONS permission is needed.
        // flutter_local_notifications handles this internally when scheduling if targetSDK is 33+
        // but explicit request is good practice.
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        granted = await androidImplementation?.requestNotificationsPermission(); // For API 33+
        granted ??= true; // Assume granted for older Android versions where this is not needed.
      } else {
        _logger.warning(message: "Requesting permissions for unsupported platform.");
        granted = true; // Or false, depending on desired default behavior
      }
      _logger.info(message: "Notification permission granted: ${granted ?? false}");
      return granted ?? false;
    } catch (e, s) {
      _logger.error(
          message: "Error requesting notification permission",
          error: e,
          stackTrace: s);
      return false;
    }
  }

  AndroidNotificationDetails _getAndroidNotificationDetails(
    app_notification.NotificationData notification,
    List<app_notification.NotificationAction>? actions,
  ) {
    final List<AndroidNotificationAction> androidActions = (actions ?? [])
        .map((action) => AndroidNotificationAction(
              action.id,
              action.title,
              // showsUserInterface: action.showsUserInterface, // This needs to be handled in onDidReceiveNotificationResponse
              // cancelNotification: action.cancelNotification, // This needs to be handled in onDidReceiveNotificationResponse
            ))
        .toList();

    return AndroidNotificationDetails(
      notification.channelId, // channelId
      notification.channelId, // channelName (can be more descriptive)
      channelDescription: 'Channel for ${notification.channelId}', // channelDescription
      importance: _mapPriorityToImportance(notification.priority),
      priority: _mapPriorityToAndroidPriority(notification.priority),
      playSound: notification.soundName != null,
      sound: notification.soundName != null
          ? RawResourceAndroidNotificationSound(
              notification.soundName!.replaceAll('.mp3', '').replaceAll('.wav', ''))
          : null,
      visibility: _mapVisibility(notification.visibility),
      actions: androidActions.isNotEmpty ? androidActions : null,
      // ongoing: if it's a critical, non-dismissable notification for example
      // styleInformation: for big text, inbox style etc.
    );
  }

  DarwinNotificationDetails _getDarwinNotificationDetails(
      app_notification.NotificationData notification) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: notification.soundName != null,
      sound: notification.soundName, // For iOS, use the sound file name with extension
      // attachments: for images/videos
      // categoryIdentifier: for custom actions defined natively
    );
  }

  // @override // <--- تم الحذف: هذا الخطأ في التحليل يشير إلى أن هذه الدالة ليست تجاوزًا لواجهة
  Future<bool> _shouldSendNotification(
      app_notification.NotificationData notification) async {
    if (_isDisposed) return false;

    if (_respectBatteryOptimizations) {
      try {
        final bool canSend = await _batteryService.canSendNotification();
        if (!canSend) {
          _logger.info(message: "Notification (${notification.id}) suppressed due to battery optimizations.");
          return false;
        }
      } catch (e,s) {
        _logger.warning(message: "Error checking battery status for notification", error: e, stackTrace: s);
        // Decide if to proceed or not on error, current logic proceeds
      }
    }

    if (_respectDoNotDisturb && notification.respectDoNotDisturb) {
      try {
        final bool dndEnabled = await _doNotDisturbService.isDoNotDisturbEnabled();
        if (dndEnabled) {
          // Check if this specific notification type should override DND
          final bool shouldOverride = await _doNotDisturbService
              .shouldOverrideDoNotDisturb(notification.notificationTime == app_notification.NotificationTime.fajr || notification.notificationTime == app_notification.NotificationTime.dhuhr || notification.notificationTime == app_notification.NotificationTime.asr || notification.notificationTime == app_notification.NotificationTime.maghrib || notification.notificationTime == app_notification.NotificationTime.isha
                  ? app_notification.DoNotDisturbOverrideType.prayer // A bit simplistic mapping
                  : app_notification.DoNotDisturbOverrideType.none); // Default to no override
          
          if (!shouldOverride) {
            _logger.info(message: "Notification (${notification.id}) suppressed due to DND mode.");
            return false;
          }
           _logger.info(message: "Notification (${notification.id}) overriding DND mode.");
        }
      } catch (e,s) {
        _logger.warning(message: "Error checking DND status for notification", error: e, stackTrace: s);
        // Decide if to proceed or not on error
      }
    }
    return true;
  }


  @override
  Future<bool> scheduleNotification(app_notification.NotificationData notification) async {
    return _scheduleActualNotification(notification, null);
  }

  @override
  Future<bool> scheduleNotificationWithActions(
    app_notification.NotificationData notification,
    List<app_notification.NotificationAction> actions,
  ) async {
    return _scheduleActualNotification(notification, actions);
  }


  Future<bool> _scheduleActualNotification(
    app_notification.NotificationData notification,
    List<app_notification.NotificationAction>? actions,
  ) async {
    if (!_isInitialized || _isDisposed) {
      _logger.warning(message: "Attempted to schedule notification (${notification.id}) when service not initialized or disposed.");
      return false;
    }
    if (!await _shouldSendNotification(notification)) return false;

    _logger.info(message: "Scheduling notification: ${notification.id} - ${notification.title}");

    final AndroidNotificationDetails androidDetails = _getAndroidNotificationDetails(notification, actions);
    final DarwinNotificationDetails darwinDetails = _getDarwinNotificationDetails(notification);

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    // Convert payload Map to JSON String if it's not already a string
    String? finalPayload;
    if (notification.payload is String) {
        finalPayload = notification.payload as String?;
    } else if (notification.payload is Map) {
        try {
            finalPayload = jsonEncode(notification.payload);
        } catch (e, s) {
            _logger.error(message: "Error encoding payload for notification ${notification.id}", error: e, stackTrace: s);
            finalPayload = null; // or some default error string
        }
    }


    try {
      tz.TZDateTime scheduledTZDateTime = _timezoneService.getLocalTZDateTime(notification.scheduledDate);
      // Ensure the scheduled time is in the future
      if (scheduledTZDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
          // If it's a repeating notification, the library might handle adjustment for next occurrence
          // For non-repeating, if it's in the past, it might not show or show immediately.
          // Let's adjust to be at least a few seconds in the future if it's past.
          // However, NotificationScheduler should ideally provide future dates.
          _logger.warning(message: "Scheduled time for notification ${notification.id} is in the past ($scheduledTZDateTime). It might not be shown as expected.");
          // Optionally, adjust it: scheduledTZDateTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
      }


      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notification.id,
        notification.title,
        notification.body,
        scheduledTZDateTime,
        platformChannelSpecifics,
        androidScheduleMode: _getAndroidScheduleMode(notification),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: finalPayload, // Ensure payload is a String
        matchDateTimeComponents: notification.repeatInterval == null
            ? null // No repeat
            : _mapRepeatIntervalToDateTimeComponents(notification.repeatInterval!),
      );
      _logger.info(message: "Notification ${notification.id} scheduled successfully for $scheduledTZDateTime.");
      return true;
    } catch (e, s) {
      _logger.error(
          message: "Error scheduling notification ${notification.id}",
          error: e,
          stackTrace: s);
      return false;
    }
  }


  AndroidScheduleMode? _getAndroidScheduleMode(app_notification.NotificationData notification) {
    if (notification.priority == app_notification.NotificationPriority.critical || 
        !notification.respectBatteryOptimizations) { // Assuming critical or non-respecting battery opt means it needs to be exact
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    return AndroidScheduleMode.alarmClock; // Default to alarmClock for better reliability with doze
  }


  DateTimeComponents? _mapRepeatIntervalToDateTimeComponents(
      app_notification.NotificationRepeatInterval interval) {
    switch (interval) {
      case app_notification.NotificationRepeatInterval.daily:
        return DateTimeComponents.time; // Repeats daily at the same time
      case app_notification.NotificationRepeatInterval.weekly:
        return DateTimeComponents.dayOfWeekAndTime; // Repeats weekly on the same day of week and time
      case app_notification.NotificationRepeatInterval.monthly:
         _logger.warning(message: "Monthly repeat interval is not directly supported by DateTimeComponents for flutter_local_notifications. Scheduling as daily.");
        return DateTimeComponents.time; // Fallback or needs custom handling for true monthly
      default:
        return null;
    }
  }

  Importance _mapPriorityToImportance(app_notification.NotificationPriority priority) {
    switch (priority) {
      case app_notification.NotificationPriority.low:
        return Importance.low;
      case app_notification.NotificationPriority.normal:
        return Importance.defaultImportance;
      case app_notification.NotificationPriority.high:
        return Importance.high;
      case app_notification.NotificationPriority.critical:
        return Importance.max;
      default:
        return Importance.defaultImportance;
    }
  }

  Priority _mapPriorityToAndroidPriority(app_notification.NotificationPriority priority) {
    switch (priority) {
      case app_notification.NotificationPriority.low:
        return Priority.low;
      case app_notification.NotificationPriority.normal:
        return Priority.defaultPriority;
      case app_notification.NotificationPriority.high:
        return Priority.high;
      case app_notification.NotificationPriority.critical:
        return Priority.max;
      default:
        return Priority.defaultPriority;
    }
  }

  NotificationVisibility? _mapVisibility(app_notification.NotificationVisibility visibility) {
    switch (visibility) {
      case app_notification.NotificationVisibility.public:
        return NotificationVisibility.public;
      case app_notification.NotificationVisibility.private:
        return NotificationVisibility.private;
      case app_notification.NotificationVisibility.secret:
        return NotificationVisibility.secret;
      default:
        return NotificationVisibility.public;
    }
  }


  // This method is not part of the interface defined in notification_service.dart
  // If it's intended to be, it should be added there.
  // The lint `override_on_non_overriding_member` was for this.
  // Future<bool> scheduleRepeatingNotification(app_notification.NotificationData notification) async {
  //   // flutter_local_notifications handles repeat via matchDateTimeComponents in zonedSchedule
  //   return scheduleNotification(notification);
  // }

  // This method seems to be a duplicate or alternative way of scheduling,
  // If `scheduleNotification` can handle timezones via TZDateTime, this might be redundant
  // or needs clearer distinction from `scheduleNotification`.
  // The interface already has scheduleNotificationInTimeZone.
  // @override
  // Future<bool> scheduleNotificationInTimeZone(
  //   app_notification.NotificationData notification,
  //   String timeZoneId, // The TZDateTime creation should use this
  // ) async {
  //   if (!_isInitialized || _isDisposed) return false;
  //   if (!await _shouldSendNotification(notification)) return false;

  //   // This method needs to correctly use timeZoneId to create TZDateTime
  //   // The current implementation in _scheduleActualNotification uses _timezoneService.getLocalTZDateTime
  //   // It should be:
  //   // tz.TZDateTime scheduledTZDateTime = _timezoneService.getDateTimeInTimeZone(notification.scheduledDate, timeZoneId);

  //   // For now, let's assume _scheduleActualNotification will be adapted or this method will be fully implemented.
  //   // The provided code was calling _scheduleActualNotification which uses local TZ.
  //   // This is a conceptual fix:
  //   _logger.info(message: "Scheduling notification ${notification.id} in timezone $timeZoneId");
  //   try {
  //      final tz.Location location = tz.getLocation(timeZoneId);
  //      tz.TZDateTime scheduledTZDateTime = tz.TZDateTime.from(notification.scheduledDate, location);

  //      // Rest of the logic from _scheduleActualNotification, but using this specific scheduledTZDateTime
  //      // ... (omitted for brevity, similar to _scheduleActualNotification but with the correct TZDateTime)
  //     _logger.warning(message: "scheduleNotificationInTimeZone needs full implementation using the provided timeZoneId for TZDateTime.");

  //     // Temporary: Call the main scheduling logic, but this won't respect the timeZoneId correctly
  //     // without modification to how TZDateTime is created in _scheduleActualNotification or here.
  //     return _scheduleActualNotification(notification, null); // This is not ideal.

  //   } catch (e,s) {
  //     _logger.error(message: "Error scheduling notification in timezone $timeZoneId", error:e, stackTrace:s);
  //     return false;
  //   }
  // }


  @override
  Future<void> cancelNotification(int id) async {
    if (_isDisposed) return;
    _logger.debug(message: "Cancelling notification: $id");
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  @override
  Future<void> cancelNotificationsByIds(List<int> ids) async {
    if (_isDisposed) return;
    _logger.debug(message: "Cancelling multiple notifications by IDs: $ids");
    for (int id in ids) {
      await _flutterLocalNotificationsPlugin.cancel(id);
    }
  }

  @override
  Future<void> cancelNotificationsByTag(String tag) async {
    if (_isDisposed) return;
     _logger.debug(message: "Cancelling notifications by tag: $tag (Android only)");
    // Tag cancellation is Android-specific for grouping.
    // flutter_local_notifications uses ID for cancellation primarily.
    // If using tags, it's typically done when showing the notification.
    // This might require iterating through pending notifications if not directly supported.
    // For now, this method might not do much if tags aren't used when showing.
    await _flutterLocalNotificationsPlugin.cancelAll(); // Or more specific logic if tags are managed
  }


  @override
  Future<void> cancelAllNotifications() async {
    if (_isDisposed) return;
    _logger.debug(message: "Cancelling all notifications");
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  @override
  Future<void> setRespectBatteryOptimizations(bool enabled) async {
    _respectBatteryOptimizations = enabled;
    _logger.info(message: "Respect battery optimizations set to: $enabled");
  }

  @override
  Future<void> setRespectDoNotDisturb(bool enabled) async {
    _respectDoNotDisturb = enabled;
    _logger.info(message: "Respect Do Not Disturb set to: $enabled");

  }

  @override
  Future<bool> canSendNotificationsNow() async {
    if (_isDisposed) return false;
    _logger.debug(message: "Checking if notifications can be sent now...");

    final bool hasPermission = await requestPermission();
    if (!hasPermission) {
       _logger.info(message: "Cannot send notifications now: Permission denied.");
      return false;
    }

    // Use the internal _shouldSendNotification logic with a dummy/generic notification data
    // to check battery and DND rules based on current service settings.
    // This is a simplified check.
    final dummyNotification = app_notification.NotificationData(
      id: 0, title: '', body: '', scheduledDate: DateTime.now(),
      respectDoNotDisturb: _respectDoNotDisturb // Use the current service setting
    );
    return await _shouldSendNotification(dummyNotification);
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _logger.debug(message: "Disposing NotificationServiceImpl...");
    _isDisposed = true;
    _isInitialized = false;
    // No specific resources from flutter_local_notifications plugin itself to dispose here,
    // but good practice for services.
  }
}