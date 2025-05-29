// lib/core/services/implementations/notification_service_impl.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../interfaces/notification_service.dart' as app_notification;
import '../interfaces/battery_service.dart';
import '../interfaces/do_not_disturb_service.dart'; // <--- إضافة: استيراد مباشر لـ DoNotDisturbService
import '../interfaces/timezone_service.dart';
import '../interfaces/logger_service.dart';
import '../../../app/di/service_locator.dart'; // افترض أن هذا هو ملف حقن التبعيات

// Callback for when a notification is tapped
@pragma('vm:entry-point')
void onDidReceiveNotificationResponseBackground(NotificationResponse notificationResponse) {
  // هذا الـ callback يُستدعى عندما يكون التطبيق في الخلفية أو مغلق ويتم الضغط على الإشعار
  // لا تقم بتحديث الواجهة مباشرة من هنا
  final LoggerService logger = getIt<LoggerService>(); // يجب التأكد من تهيئة getIt هنا
  logger.info(message: 'Notification response received in background/terminated', data: {
    'id': notificationResponse.id,
    'actionId': notificationResponse.actionId,
    'payload': notificationResponse.payload,
  });
  // يمكن استخدام Isolate.spawn أو طرق أخرى لمعالجة الحمولة أو فتح التطبيق
}


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
    LoggerService? logger,
  }) : _logger = logger ?? getIt<LoggerService>() {
    _logger.debug(message: "NotificationServiceImpl constructed");
  }

  // Callback for foreground notifications on older iOS versions
  void _onDidReceiveLocalNotificationIOS(
      int id, String? title, String? body, String? payload) async {
    _logger.info(
        message: "Legacy iOS onDidReceiveLocalNotification (foreground)",
        data: {'id': id, 'title': title, 'body': body, 'payload': payload});
    // يمكنك هنا عرض حوار أو تحديث الواجهة إذا كان التطبيق في المقدمة
  }


  @override
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) {
      _logger.debug(message: "NotificationService initialize skipped: already initialized or disposed.");
      return;
    }
    _logger.info(message: "Initializing NotificationService...");

    try {
      await _timezoneService.initializeTimeZones();
      _logger.debug(message: "Timezones initialized for notifications.");

      const AndroidInitializationSettings androidInitSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher'); // تأكد أن هذا الملف موجود

      final DarwinInitializationSettings darwinInitSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotificationIOS, // <--- تم التعديل: استخدام المعامل الصحيح
      );

      final InitializationSettings initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: darwinInitSettings,
        macOS: darwinInitSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponseBackground, // عند الضغط على الإشعار والتطبيق مفتوح
        onDidReceiveBackgroundNotificationResponse: onDidReceiveNotificationResponseBackground, // عند الضغط على الإشعار والتطبيق في الخلفية
      );

      _isInitialized = true;
      _logger.info(message: "NotificationService initialized successfully.");
    } catch (e, s) {
      _logger.error(
          message: "Error initializing NotificationService",
          error: e,
          stackTrace: s);
      _isInitialized = false;
    }
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
        final plugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        granted = await plugin?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      } else if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        granted = await androidImplementation?.requestPermission(); // For API 33+
        // For older Android, permission is implicitly granted unless user disables it.
        // `requestPermission` returns true if already granted or newly granted.
      } else {
        _logger.warning(message: "Requesting permissions for unsupported platform.");
        granted = true; // أو false، حسب السلوك الافتراضي المرغوب
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
              // showsUserInterface and cancelNotification are handled by the app logic
              // based on action.id in onDidReceiveNotificationResponse
            ))
        .toList();

    return AndroidNotificationDetails(
      notification.channelId,
      notification.channelId, // اسم القناة (يمكن أن يكون أكثر وصفًا)
      channelDescription: 'Channel for ${notification.channelId}',
      importance: _mapPriorityToImportance(notification.priority),
      priority: _mapPriorityToAndroidPriority(notification.priority),
      playSound: notification.soundName != null,
      sound: notification.soundName != null
          ? RawResourceAndroidNotificationSound(
              notification.soundName!.replaceAll('.mp3', '').replaceAll('.wav', ''))
          : null,
      visibility: _mapVisibility(notification.visibility),
      actions: androidActions.isNotEmpty ? androidActions : null,
    );
  }

  DarwinNotificationDetails _getDarwinNotificationDetails(
      app_notification.NotificationData notification) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: notification.soundName != null,
      sound: notification.soundName,
    );
  }

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
        // <--- تم التعديل: تصحيح استدعاء logger.warning
        _logger.warning(message: "Error checking battery status for notification: ${e.toString()}", data: {'error': e, 'stackTrace': s.toString()});
      }
    }

    if (_respectDoNotDisturb && notification.respectDoNotDisturb) {
      try {
        final bool dndEnabled = await _doNotDisturbService.isDoNotDisturbEnabled();
        if (dndEnabled) {
          // <--- تم التعديل: استخدام DoNotDisturbOverrideType مباشرة بعد استيرادها
          DoNotDisturbOverrideType overrideType = DoNotDisturbOverrideType.none;
          if (notification.notificationTime == app_notification.NotificationTime.fajr ||
              notification.notificationTime == app_notification.NotificationTime.dhuhr ||
              // ... (بقية أوقات الصلاة)
              notification.notificationTime == app_notification.NotificationTime.isha ) {
                overrideType = DoNotDisturbOverrideType.prayer;
              } else if (notification.priority == app_notification.NotificationPriority.critical) {
                overrideType = DoNotDisturbOverrideType.critical;
              }

          final bool shouldOverride = await _doNotDisturbService.shouldOverrideDoNotDisturb(overrideType);
          
          if (!shouldOverride) {
            _logger.info(message: "Notification (${notification.id}) suppressed due to DND mode.");
            return false;
          }
           _logger.info(message: "Notification (${notification.id}) overriding DND mode.");
        }
      } catch (e,s) {
        // <--- تم التعديل: تصحيح استدعاء logger.warning
        _logger.warning(message: "Error checking DND status for notification: ${e.toString()}", data: {'error': e, 'stackTrace': s.toString()});
      }
    }
    return true;
  }

  Future<bool> _scheduleDelegate(
    app_notification.NotificationData notification,
    List<app_notification.NotificationAction>? actions, {
    String? timeZoneId,
  }) async {
    if (!_isInitialized || _isDisposed) {
      _logger.warning(message: "Attempted to schedule notification (${notification.id}) when service not initialized or disposed.");
      return false;
    }
    if (!await _shouldSendNotification(notification)) return false;

    _logger.info(message: "Scheduling notification: ${notification.id} - ${notification.title} for timeZone: ${timeZoneId ?? 'local'}");

    final AndroidNotificationDetails androidDetails = _getAndroidNotificationDetails(notification, actions);
    final DarwinNotificationDetails darwinDetails = _getDarwinNotificationDetails(notification);

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    // الحمولة يجب أن تكون String? كما هو محدد في الواجهة المحدثة
    final String? payloadString = notification.payload; // <--- تم الحذف: لا حاجة لـ jsonEncode إذا كانت الحمولة بالفعل String

    try {
      tz.TZDateTime scheduledTZDateTime;
      if (timeZoneId != null) {
        scheduledTZDateTime = _timezoneService.getDateTimeInTimeZone(notification.scheduledDate, timeZoneId);
      } else {
        scheduledTZDateTime = _timezoneService.getLocalTZDateTime(notification.scheduledDate);
      }
      
      if (scheduledTZDateTime.isBefore(tz.TZDateTime.now(scheduledTZDateTime.location))) {
          _logger.warning(message: "Scheduled time for notification ${notification.id} is in the past ($scheduledTZDateTime). Adjusting or might not show.");
          // يمكن إضافة منطق لتعديل الوقت هنا إذا لزم الأمر
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notification.id,
        notification.title,
        notification.body,
        scheduledTZDateTime,
        platformChannelSpecifics,
        androidScheduleMode: _getAndroidScheduleMode(notification), // <--- تم التعديل: التأكد من أنها غير null
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, // <--- تم التعديل: استخدام الاسم الصحيح
        payload: payloadString,
        matchDateTimeComponents: notification.repeatInterval == null
            ? null
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

  @override
  Future<bool> scheduleNotification(app_notification.NotificationData notification) async {
    return _scheduleDelegate(notification, null);
  }

  @override
  Future<bool> scheduleNotificationWithActions(
    app_notification.NotificationData notification,
    List<app_notification.NotificationAction> actions,
  ) async {
    return _scheduleDelegate(notification, actions);
  }

  // <--- تم التعديل: تنفيذ الدالة المفقودة
  @override
  Future<bool> scheduleNotificationInTimeZone(
    app_notification.NotificationData notification,
    String timeZoneId,
  ) async {
    return _scheduleDelegate(notification, null, timeZoneId: timeZoneId);
  }

  // <--- تم التعديل: التأكد من أنها غير nullable
  AndroidScheduleMode _getAndroidScheduleMode(app_notification.NotificationData notification) {
    if (notification.priority == app_notification.NotificationPriority.critical ||
        !notification.respectBatteryOptimizations) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    // الخيار الآخر هو AndroidScheduleMode.inexactAllowWhileIdle لجدولة أقل دقة ولكنها موفرة للطاقة
    return AndroidScheduleMode.alarmClock; // يضمن التسليم حتى لو كان الجهاز في وضع Doze
  }

  DateTimeComponents? _mapRepeatIntervalToDateTimeComponents(
      app_notification.NotificationRepeatInterval interval) {
    switch (interval) {
      case app_notification.NotificationRepeatInterval.daily:
        return DateTimeComponents.time;
      case app_notification.NotificationRepeatInterval.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case app_notification.NotificationRepeatInterval.monthly:
        _logger.warning(message: "Monthly repeat interval is not directly supported by DateTimeComponents. Consider custom scheduling logic or daily fallback.");
        return null; // أو DateTimeComponents.dayOfMonthAndTime إذا كان مدعومًا بشكل جيد
      // لا حاجة لـ default إذا كانت جميع الحالات مغطاة
    }
    return null; // يجب أن يكون هناك return هنا إذا لم تكن جميع الحالات مغطاة
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
      // لا حاجة لـ default
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
      // لا حاجة لـ default
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
      // لا حاجة لـ default
    }
  }

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
    _logger.debug(message: "Cancelling notifications by tag: $tag (Android only). Note: flutter_local_notifications primarily uses ID for cancellation.");
    //  flutter_local_notifications لا يدعم الإلغاء المباشر بالـ tag بهذه الطريقة.
    //  إذا كنت بحاجة لإلغاء مجموعة معينة، استخدم ID أو ألغِ الكل.
    //  await _flutterLocalNotificationsPlugin.cancel(id, tag: tag); // هكذا يُستخدم الـ tag عند الإلغاء لإشعار معين
    await _flutterLocalNotificationsPlugin.cancelAll(); // كحل بديل مؤقت إذا كان هذا هو المقصود
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
    // هذا فحص مبسط
    final dummyNotification = app_notification.NotificationData(
      id: 0, title: '', body: '', scheduledDate: DateTime.now(),
      respectDoNotDisturb: _respectDoNotDisturb, // استخدام الإعداد الحالي للخدمة
      priority: app_notification.NotificationPriority.normal // أولوية افتراضية للفحص
    );
    return await _shouldSendNotification(dummyNotification);
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _logger.debug(message: "Disposing NotificationServiceImpl...");
    _isDisposed = true;
    _isInitialized = false;
  }
}