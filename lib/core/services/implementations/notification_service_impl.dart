// lib/core/services/implementations/notification_service_impl.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../interfaces/notification_service.dart' as app_notification;
import '../interfaces/battery_service.dart';
import '../interfaces/do_not_disturb_service.dart';
import '../interfaces/timezone_service.dart';
import '../interfaces/logger_service.dart';
import '../utils/notification_payload_handler.dart';
import '../utils/notification_analytics.dart';
import '../utils/notification_retry_manager.dart';
import '../../../app/di/service_locator.dart';

/// Callback للإشعارات في الخلفية
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // معالجة الضغط على الإشعار في الخلفية
  if (kDebugMode) {
    print('Notification tapped in background: ${notificationResponse.id}');
  }
}

/// تنفيذ محسّن لخدمة الإشعارات
class NotificationServiceImpl implements app_notification.NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final BatteryService _batteryService;
  final DoNotDisturbService _doNotDisturbService;
  final TimezoneService _timezoneService;
  final LoggerService _logger;
  final NotificationAnalytics _analytics;
  final NotificationRetryManager _retryManager;

  // إعدادات الخدمة
  bool _respectBatteryOptimizations = true;
  bool _respectDoNotDisturb = true;
  bool _isInitialized = false;
  bool _isDisposed = false;

  // تخزين callbacks
  Function(NotificationResponse)? _onNotificationTapped;
  
  // قنوات الإشعارات المُسجلة
  final Map<String, AndroidNotificationChannel> _registeredChannels = {};

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
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) {
      _logger.debug(
        message: "NotificationService initialize skipped",
        data: {'initialized': _isInitialized, 'disposed': _isDisposed}
      );
      return;
    }

    _logger.info(message: "Initializing NotificationService...");

    try {
      // تهيئة المناطق الزمنية
      await _timezoneService.initializeTimeZones();
      _logger.debug(message: "Timezones initialized for notifications");

      // إعدادات Android
      const AndroidInitializationSettings androidInitSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // إعدادات iOS/macOS
      const DarwinInitializationSettings darwinInitSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        // onDidReceiveLocalNotification تم إزالته في الإصدارات الحديثة
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: darwinInitSettings,
        macOS: darwinInitSettings,
      );

      // تهيئة المكون الإضافي
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // إنشاء قنوات الإشعارات الافتراضية (Android)
      await _createDefaultNotificationChannels();

      _isInitialized = true;
      _logger.info(message: "NotificationService initialized successfully");
      
      // تسجيل نجاح التهيئة
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

  /// إنشاء قنوات الإشعارات الافتراضية لنظام Android
  Future<void> _createDefaultNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return;

    // قناة الأذكار
    const athkarChannel = AndroidNotificationChannel(
      'athkar_channel',
      'إشعارات الأذكار',
      description: 'إشعارات تذكير بالأذكار اليومية',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // قناة مواقيت الصلاة
    const prayerChannel = AndroidNotificationChannel(
      'prayer_channel',
      'إشعارات مواقيت الصلاة',
      description: 'إشعارات بأوقات الصلاة',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await androidPlugin.createNotificationChannel(athkarChannel);
    await androidPlugin.createNotificationChannel(prayerChannel);
    
    _registeredChannels['athkar_channel'] = athkarChannel;
    _registeredChannels['prayer_channel'] = prayerChannel;
    
    _logger.info(message: "Default notification channels created");
  }

  /// معالجة الإشعارات المحلية على iOS القديم
  // تم إزالة هذه الدالة لأنها لم تعد مدعومة في الإصدارات الحديثة

  /// معالجة الضغط على الإشعار
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

    // تسجيل التفاعل
    _analytics.recordNotificationInteraction(
      response.id ?? 0,
      response.actionId ?? 'tap',
    );

    // استدعاء callback المخصص إن وجد
    _onNotificationTapped?.call(response);
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
          // criticalAlert يتطلب إذن خاص من Apple
        );
      } else if (Platform.isAndroid) {
        final androidImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
          // Android 13+ يتطلب إذن صريح
          granted = await androidImplementation.requestNotificationsPermission();
        } else {
          // Android أقدم من 13 - الإذن ممنوح افتراضياً
          granted = true;
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
  Future<bool> scheduleNotification(
    app_notification.NotificationData notification,
  ) async {
    return _scheduleNotificationInternal(notification, null);
  }

  @override
  Future<bool> scheduleNotificationWithActions(
    app_notification.NotificationData notification,
    List<app_notification.NotificationAction> actions,
  ) async {
    return _scheduleNotificationInternal(notification, actions);
  }

  @override
  Future<bool> scheduleNotificationInTimeZone(
    app_notification.NotificationData notification,
    String timeZoneId,
  ) async {
    return _scheduleNotificationInternal(notification, null, timeZoneId: timeZoneId);
  }

  /// الدالة الداخلية الموحدة لجدولة الإشعارات
  Future<bool> _scheduleNotificationInternal(
    app_notification.NotificationData notification,
    List<app_notification.NotificationAction>? actions, {
    String? timeZoneId,
  }) async {
    if (!_isInitialized || _isDisposed) {
      _logger.warning(
        message: "Cannot schedule notification - service not ready",
        data: {'id': notification.id, 'initialized': _isInitialized}
      );
      return false;
    }

    // التحقق من إمكانية إرسال الإشعار
    if (!await _shouldSendNotification(notification)) {
      _logger.info(
        message: "Notification suppressed by system conditions",
        data: {'id': notification.id}
      );
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
      // إعداد تفاصيل الإشعار
      final notificationDetails = _buildNotificationDetails(notification, actions);
      
      // تحويل payload إلى JSON string
      final payloadString = notification.payload != null 
          ? NotificationPayloadHandler.validateAndEncode(notification.payload!)
          : null;

      // حساب الوقت في المنطقة الزمنية المطلوبة
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

      // التحقق من أن الوقت في المستقبل
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
        
        // محاولة تعديل الوقت للمستقبل
        if (notification.repeatInterval != null) {
          scheduledTZDateTime = _getNextValidScheduleTime(
            scheduledTZDateTime,
            notification.repeatInterval!,
          );
          _logger.info(
            message: "Adjusted schedule time to future",
            data: {'new_time': scheduledTZDateTime.toIso8601String()}
          );
        } else {
          return false;
        }
      }

      // جدولة الإشعار
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notification.id,
        notification.title,
        notification.body,
        scheduledTZDateTime,
        notificationDetails,
        androidScheduleMode: _getAndroidScheduleMode(notification),
        payload: payloadString,
        matchDateTimeComponents: notification.repeatInterval != null
            ? _mapRepeatIntervalToDateTimeComponents(notification.repeatInterval!)
            : null,
      );

      _logger.info(
        message: "Notification scheduled successfully",
        data: {'id': notification.id}
      );
      
      // تسجيل النجاح
      _analytics.recordNotificationScheduled(
        notification.id,
        notification.notificationTime.toString(),
      );
      
      return true;
    } catch (e, s) {
      _logger.error(
        message: "Error scheduling notification",
        error: e,
        stackTrace: s
      );
      
      _analytics.recordError('scheduling_failed', e.toString());
      
      // محاولة إعادة الجدولة
      if (await _retryManager.shouldRetry(notification.id)) {
        _logger.info(message: "Queuing notification for retry");
        await _retryManager.queueForRetry(notification);
      }
      
      return false;
    }
  }

  /// بناء تفاصيل الإشعار للمنصات المختلفة
  NotificationDetails _buildNotificationDetails(
    app_notification.NotificationData notification,
    List<app_notification.NotificationAction>? actions,
  ) {
    final androidDetails = _getAndroidNotificationDetails(notification, actions);
    final darwinDetails = _getDarwinNotificationDetails(notification);

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  /// إعداد تفاصيل الإشعار لنظام Android
  AndroidNotificationDetails _getAndroidNotificationDetails(
    app_notification.NotificationData notification,
    List<app_notification.NotificationAction>? actions,
  ) {
    // تحويل الإجراءات
    final androidActions = actions
        ?.map((action) => AndroidNotificationAction(
              action.id,
              action.title,
              showsUserInterface: action.showsUserInterface ?? false,
              cancelNotification: action.cancelNotification ?? false,
            ))
        .toList();

    return AndroidNotificationDetails(
      notification.channelId,
      _registeredChannels[notification.channelId]?.name ?? notification.channelId,
      channelDescription: _registeredChannels[notification.channelId]?.description,
      importance: _mapPriorityToImportance(notification.priority),
      priority: _mapPriorityToAndroidPriority(notification.priority),
      playSound: notification.soundName != null,
      sound: notification.soundName != null
          ? RawResourceAndroidNotificationSound(
              notification.soundName!.replaceAll(RegExp(r'\.(mp3|wav)$'), ''),
            )
          : null,
      visibility: _mapVisibility(notification.visibility),
      actions: androidActions,
      styleInformation: const BigTextStyleInformation(''),
      groupKey: notification.channelId,
      setAsGroupSummary: false,
      ongoing: false,
      autoCancel: true,
      color: const Color(0xFF2196F3), // لون أزرق للإشعارات
    );
  }

  /// إعداد تفاصيل الإشعار لنظام iOS/macOS
  DarwinNotificationDetails _getDarwinNotificationDetails(
    app_notification.NotificationData notification,
  ) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: notification.soundName != null,
      sound: notification.soundName,
      badgeNumber: null,
      threadIdentifier: notification.channelId,
      interruptionLevel: _mapPriorityToInterruptionLevel(notification.priority),
    );
  }

  /// التحقق من إمكانية إرسال الإشعار
  Future<bool> _shouldSendNotification(
    app_notification.NotificationData notification,
  ) async {
    if (_isDisposed) return false;

    // التحقق من البطارية
    if (_respectBatteryOptimizations) {
      try {
        final canSend = await _batteryService.canSendNotification();
        if (!canSend) {
          _logger.info(
            message: "Notification suppressed by battery optimization",
            data: {'id': notification.id}
          );
          _analytics.recordEvent('notification_suppressed', {'reason': 'battery'});
          return false;
        }
      } catch (e) {
        _logger.warning(
          message: "Error checking battery status",
          data: {'error': e.toString()}
        );
      }
    }

    // التحقق من وضع عدم الإزعاج
    if (_respectDoNotDisturb && notification.respectDoNotDisturb) {
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
            _analytics.recordEvent('notification_suppressed', {'reason': 'dnd'});
            return false;
          } else {
            _logger.info(
              message: "Notification overriding DND",
              data: {'id': notification.id, 'override_type': overrideType.toString()}
            );
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

  /// تحديد نوع تجاوز وضع عدم الإزعاج
  DoNotDisturbOverrideType _getDoNotDisturbOverrideType(
    app_notification.NotificationData notification,
  ) {
    // إشعارات الصلاة
    if (_isPrayerNotification(notification.notificationTime)) {
      return DoNotDisturbOverrideType.prayer;
    }
    
    // إشعارات حرجة
    if (notification.priority == app_notification.NotificationPriority.critical) {
      return DoNotDisturbOverrideType.critical;
    }
    
    // أذكار مهمة (الصباح والمساء)
    if (notification.notificationTime == app_notification.NotificationTime.morning ||
        notification.notificationTime == app_notification.NotificationTime.evening) {
      return DoNotDisturbOverrideType.importantAthkar;
    }
    
    return DoNotDisturbOverrideType.none;
  }

  /// التحقق من كون الإشعار للصلاة
  bool _isPrayerNotification(app_notification.NotificationTime time) {
    return time == app_notification.NotificationTime.fajr ||
           time == app_notification.NotificationTime.dhuhr ||
           time == app_notification.NotificationTime.asr ||
           time == app_notification.NotificationTime.maghrib ||
           time == app_notification.NotificationTime.isha;
  }

  /// الحصول على الوقت الصالح التالي للجدولة
  tz.TZDateTime _getNextValidScheduleTime(
    tz.TZDateTime originalTime,
    app_notification.NotificationRepeatInterval interval,
  ) {
    final now = tz.TZDateTime.now(originalTime.location);
    var nextTime = originalTime;
    
    while (nextTime.isBefore(now)) {
      switch (interval) {
        case app_notification.NotificationRepeatInterval.daily:
          nextTime = nextTime.add(const Duration(days: 1));
          break;
        case app_notification.NotificationRepeatInterval.weekly:
          nextTime = nextTime.add(const Duration(days: 7));
          break;
        case app_notification.NotificationRepeatInterval.monthly:
          // تقريبي - 30 يوم
          nextTime = nextTime.add(const Duration(days: 30));
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
  Future<void> cancelNotificationsByIds(List<int> ids) async {
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
  Future<void> cancelNotificationsByTag(String tag) async {
    if (_isDisposed) return;
    
    _logger.debug(message: "Cancelling notifications by tag", data: {'tag': tag});
    
    // flutter_local_notifications لا يدعم الإلغاء بالـ tag مباشرة
    // كحل بديل، يمكن تتبع الإشعارات حسب الـ tag وإلغاؤها
    _logger.warning(
      message: "Direct tag-based cancellation not supported. Consider tracking IDs by tag."
    );
    
    // مؤقتاً - إلغاء جميع الإشعارات
    await _flutterLocalNotificationsPlugin.cancelAll();
    _analytics.recordEvent('notifications_cancelled_by_tag', {'tag': tag});
  }

  @override
  Future<void> cancelAllNotifications() async {
    if (_isDisposed) return;
    
    _logger.debug(message: "Cancelling all notifications");
    await _flutterLocalNotificationsPlugin.cancelAll();
    _analytics.recordEvent('all_notifications_cancelled');
  }

  @override
  Future<void> setRespectBatteryOptimizations(bool enabled) async {
    _respectBatteryOptimizations = enabled;
    _logger.info(
      message: "Battery optimization respect setting updated",
      data: {'enabled': enabled}
    );
    _analytics.recordEvent('battery_optimization_setting', {'enabled': enabled});
  }

  @override
  Future<void> setRespectDoNotDisturb(bool enabled) async {
    _respectDoNotDisturb = enabled;
    _logger.info(
      message: "Do Not Disturb respect setting updated", 
      data: {'enabled': enabled}
    );
    _analytics.recordEvent('dnd_setting', {'enabled': enabled});
  }

  @override
  Future<bool> canSendNotificationsNow() async {
    if (_isDisposed) return false;
    
    _logger.debug(message: "Checking if notifications can be sent now");
    
    // التحقق من الإذن
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      _logger.info(message: "Cannot send notifications: Permission denied");
      return false;
    }
    
    // إنشاء إشعار وهمي للتحقق
    final dummyNotification = app_notification.NotificationData(
      id: 0,
      title: '',
      body: '',
      scheduledDate: DateTime.now(),
      respectDoNotDisturb: _respectDoNotDisturb,
      priority: app_notification.NotificationPriority.normal,
    );
    
    return await _shouldSendNotification(dummyNotification);
  }

  /// تعيين callback للضغط على الإشعار
  void setNotificationTapCallback(Function(NotificationResponse) callback) {
    _onNotificationTapped = callback;
  }

  /// الحصول على إحصائيات الإشعارات
  Map<String, dynamic> getNotificationStats() {
    return _analytics.getStats();
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    
    _logger.debug(message: "Disposing NotificationServiceImpl");
    _isDisposed = true;
    _isInitialized = false;
    _onNotificationTapped = null;
    
    // تنظيف الموارد
    await _retryManager.dispose();
    _analytics.dispose();
  }

  // دوال تحويل خاصة

  AndroidScheduleMode _getAndroidScheduleMode(
    app_notification.NotificationData notification,
  ) {
    if (notification.priority == app_notification.NotificationPriority.critical ||
        !notification.respectBatteryOptimizations) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    return AndroidScheduleMode.exact;
  }

  DateTimeComponents? _mapRepeatIntervalToDateTimeComponents(
    app_notification.NotificationRepeatInterval interval,
  ) {
    switch (interval) {
      case app_notification.NotificationRepeatInterval.daily:
        return DateTimeComponents.time;
      case app_notification.NotificationRepeatInterval.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case app_notification.NotificationRepeatInterval.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
    }
  }

  Importance _mapPriorityToImportance(
    app_notification.NotificationPriority priority,
  ) {
    switch (priority) {
      case app_notification.NotificationPriority.low:
        return Importance.low;
      case app_notification.NotificationPriority.normal:
        return Importance.defaultImportance;
      case app_notification.NotificationPriority.high:
        return Importance.high;
      case app_notification.NotificationPriority.critical:
        return Importance.max;
    }
  }

  Priority _mapPriorityToAndroidPriority(
    app_notification.NotificationPriority priority,
  ) {
    switch (priority) {
      case app_notification.NotificationPriority.low:
        return Priority.low;
      case app_notification.NotificationPriority.normal:
        return Priority.defaultPriority;
      case app_notification.NotificationPriority.high:
        return Priority.high;
      case app_notification.NotificationPriority.critical:
        return Priority.max;
    }
  }

  NotificationVisibility? _mapVisibility(
    app_notification.NotificationVisibility visibility,
  ) {
    switch (visibility) {
      case app_notification.NotificationVisibility.public:
        return NotificationVisibility.public;
      case app_notification.NotificationVisibility.private:
        return NotificationVisibility.private;
      case app_notification.NotificationVisibility.secret:
        return NotificationVisibility.secret;
    }
  }

  InterruptionLevel _mapPriorityToInterruptionLevel(
    app_notification.NotificationPriority priority,
  ) {
    switch (priority) {
      case app_notification.NotificationPriority.low:
        return InterruptionLevel.passive;
      case app_notification.NotificationPriority.normal:
        return InterruptionLevel.active;
      case app_notification.NotificationPriority.high:
        return InterruptionLevel.timeSensitive;
      case app_notification.NotificationPriority.critical:
        return InterruptionLevel.critical;
    }
  }
}