// lib/core/services/implementations/permission_service_impl.dart
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart' as app_settings;
import '../interfaces/permission_service.dart';
import '../interfaces/logger_service.dart';
import '../../../app/di/service_locator.dart';

/// تنفيذ خدمة إدارة الأذونات مع تحسينات شاملة
class PermissionServiceImpl implements PermissionService {
  final LoggerService _logger;
  final Map<AppPermissionType, int> _permissionAttempts = {};
  final Map<AppPermissionType, DateTime> _lastRequestTime = {};
  final Map<AppPermissionType, AppPermissionStatus> _cachedStatuses = {};
  
  // مدة الانتظار بين محاولات طلب الإذن (بالثواني)
  static const int _requestCooldownSeconds = 30;
  
  PermissionServiceImpl({LoggerService? logger})
      : _logger = logger ?? getIt<LoggerService>() {
    _logger.debug(message: 'PermissionServiceImpl initialized');
  }

  @override
  Future<AppPermissionStatus> requestLocationPermission() async {
    _logger.info(message: 'Requesting location permission');
    
    // التحقق من cooldown period
    if (!_canRequestPermission(AppPermissionType.location)) {
      _logger.warning(
        message: 'Location permission request blocked by cooldown',
        data: {'cooldown_seconds': _requestCooldownSeconds}
      );
      return await checkPermissionStatus(AppPermissionType.location);
    }
    
    _recordPermissionAttempt(AppPermissionType.location);
    
    try {
      // التحقق من الحالة الحالية أولاً
      final currentStatus = await Permission.location.status;
      if (currentStatus.isGranted) {
        _logger.info(message: 'Location permission already granted');
        return _updateCachedStatus(AppPermissionType.location, AppPermissionStatus.granted);
      }
      
      // طلب الإذن
      final status = await Permission.location.request();
      final appStatus = _mapToPermissionStatus(status);
      
      _logger.info(
        message: 'Location permission request result',
        data: {'status': appStatus.toString()}
      );
      
      // إذا تم الرفض بشكل دائم، اقترح فتح الإعدادات
      if (appStatus == AppPermissionStatus.permanentlyDenied) {
        _logger.warning(message: 'Location permission permanently denied');
        // يمكن إضافة callback هنا لإشعار UI
      }
      
      return _updateCachedStatus(AppPermissionType.location, appStatus);
    } catch (e, s) {
      _logger.error(
        message: 'Error requesting location permission',
        error: e,
        stackTrace: s
      );
      return AppPermissionStatus.unknown;
    }
  }

  @override
  Future<AppPermissionStatus> requestNotificationPermission() async {
    _logger.info(message: 'Requesting notification permission');
    
    if (!_canRequestPermission(AppPermissionType.notification)) {
      _logger.warning(
        message: 'Notification permission request blocked by cooldown',
        data: {'cooldown_seconds': _requestCooldownSeconds}
      );
      return await checkPermissionStatus(AppPermissionType.notification);
    }
    
    _recordPermissionAttempt(AppPermissionType.notification);
    
    try {
      final currentStatus = await Permission.notification.status;
      if (currentStatus.isGranted) {
        _logger.info(message: 'Notification permission already granted');
        return _updateCachedStatus(AppPermissionType.notification, AppPermissionStatus.granted);
      }
      
      final status = await Permission.notification.request();
      final appStatus = _mapToPermissionStatus(status);
      
      _logger.info(
        message: 'Notification permission request result',
        data: {'status': appStatus.toString()}
      );
      
      return _updateCachedStatus(AppPermissionType.notification, appStatus);
    } catch (e, s) {
      _logger.error(
        message: 'Error requesting notification permission',
        error: e,
        stackTrace: s
      );
      return AppPermissionStatus.unknown;
    }
  }

  @override
  Future<AppPermissionStatus> requestDoNotDisturbPermission() async {
    _logger.info(message: 'Requesting Do Not Disturb permission');
    
    if (!_canRequestPermission(AppPermissionType.doNotDisturb)) {
      _logger.warning(
        message: 'DND permission request blocked by cooldown',
        data: {'cooldown_seconds': _requestCooldownSeconds}
      );
      return await checkPermissionStatus(AppPermissionType.doNotDisturb);
    }
    
    _recordPermissionAttempt(AppPermissionType.doNotDisturb);
    
    try {
      // التحقق من حالة الإذن الحالية
      final currentStatus = await Permission.accessNotificationPolicy.status;
      if (currentStatus.isGranted) {
        _logger.info(message: 'DND permission already granted');
        return _updateCachedStatus(AppPermissionType.doNotDisturb, AppPermissionStatus.granted);
      }
      
      // طلب الإذن
      final status = await Permission.accessNotificationPolicy.request();
      final appStatus = _mapToPermissionStatus(status);
      
      _logger.info(
        message: 'DND permission request result',
        data: {'status': appStatus.toString()}
      );
      
      // على Android، قد نحتاج لفتح الإعدادات يدوياً
      if (appStatus == AppPermissionStatus.denied || 
          appStatus == AppPermissionStatus.permanentlyDenied) {
        _logger.info(message: 'Opening DND settings for manual permission grant');
        await app_settings.AppSettings.openAppSettings(
          type: app_settings.AppSettingsType.notification
        );
      }
      
      return _updateCachedStatus(AppPermissionType.doNotDisturb, appStatus);
    } catch (e, s) {
      _logger.error(
        message: 'Error requesting DND permission',
        error: e,
        stackTrace: s
      );
      // بعض الأجهزة لا تدعم هذا الإذن
      return AppPermissionStatus.unknown;
    }
  }

  @override
  Future<AppPermissionStatus> requestBatteryOptimizationPermission() async {
    _logger.info(message: 'Requesting battery optimization permission');
    
    if (!_canRequestPermission(AppPermissionType.batteryOptimization)) {
      _logger.warning(
        message: 'Battery optimization permission request blocked by cooldown',
        data: {'cooldown_seconds': _requestCooldownSeconds}
      );
      return await checkPermissionStatus(AppPermissionType.batteryOptimization);
    }
    
    _recordPermissionAttempt(AppPermissionType.batteryOptimization);
    
    try {
      // التحقق من الحالة الحالية
      final isGranted = await _checkBatteryOptimizationStatus();
      if (isGranted) {
        _logger.info(message: 'Battery optimization already disabled (permission granted)');
        return _updateCachedStatus(
          AppPermissionType.batteryOptimization, 
          AppPermissionStatus.granted
        );
      }
      
      // طلب الإذن
      final status = await Permission.ignoreBatteryOptimizations.request();
      
      if (!status.isGranted) {
        _logger.info(message: 'Opening battery optimization settings');
        await app_settings.AppSettings.openAppSettings(
          type: app_settings.AppSettingsType.batteryOptimization
        );
        
        // انتظار قليل ثم إعادة التحقق
        await Future.delayed(const Duration(seconds: 3));
        final recheckStatus = await _checkBatteryOptimizationStatus();
        
        return _updateCachedStatus(
          AppPermissionType.batteryOptimization,
          recheckStatus ? AppPermissionStatus.granted : AppPermissionStatus.denied
        );
      }
      
      final appStatus = _mapToPermissionStatus(status);
      _logger.info(
        message: 'Battery optimization permission request result',
        data: {'status': appStatus.toString()}
      );
      
      return _updateCachedStatus(AppPermissionType.batteryOptimization, appStatus);
    } catch (e, s) {
      _logger.error(
        message: 'Error requesting battery optimization permission',
        error: e,
        stackTrace: s
      );
      return AppPermissionStatus.unknown;
    }
  }

  @override
  Future<AppPermissionStatus> checkPermissionStatus(AppPermissionType permission) async {
    _logger.debug(
      message: 'Checking permission status',
      data: {'permission': permission.toString()}
    );
    
    try {
      PermissionStatus status;
      
      switch (permission) {
        case AppPermissionType.location:
          status = await Permission.location.status;
          break;
        case AppPermissionType.notification:
          status = await Permission.notification.status;
          break;
        case AppPermissionType.doNotDisturb:
          status = await Permission.accessNotificationPolicy.status;
          break;
        case AppPermissionType.batteryOptimization:
          // معالجة خاصة لإذن البطارية
          final isGranted = await _checkBatteryOptimizationStatus();
          return _updateCachedStatus(
            permission,
            isGranted ? AppPermissionStatus.granted : AppPermissionStatus.denied
          );
      }
      
      final appStatus = _mapToPermissionStatus(status);
      return _updateCachedStatus(permission, appStatus);
    } catch (e, s) {
      _logger.error(
        message: 'Error checking permission status',
        error: e,
        stackTrace: s
      );
      return AppPermissionStatus.unknown;
    }
  }

  @override
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions() async {
    _logger.info(message: 'Checking all permissions');
    
    final Map<AppPermissionType, AppPermissionStatus> results = {};
    
    // التحقق من جميع الأذونات بشكل متوازي
    final futures = AppPermissionType.values.map((type) async {
      final status = await checkPermissionStatus(type);
      return MapEntry(type, status);
    });
    
    final entries = await Future.wait(futures);
    results.addEntries(entries);
    
    _logger.info(
      message: 'All permissions checked',
      data: {
        'results': results.map((k, v) => MapEntry(k.toString(), v.toString()))
      }
    );
    
    return results;
  }

  @override
  Future<void> openAppSettings([AppSettingsType? settingsPage]) async {
    _logger.info(
      message: 'Opening app settings',
      data: {'page': settingsPage?.toString() ?? 'default'}
    );
    
    try {
      switch (settingsPage) {
        case AppSettingsType.location:
          await app_settings.AppSettings.openAppSettings(
            type: app_settings.AppSettingsType.location
          );
          break;
        case AppSettingsType.notification:
          await app_settings.AppSettings.openAppSettings(
            type: app_settings.AppSettingsType.notification
          );
          break;
        case AppSettingsType.battery:
          await app_settings.AppSettings.openAppSettings(
            type: app_settings.AppSettingsType.batteryOptimization
          );
          break;
        case AppSettingsType.app:
        case null:
          await app_settings.AppSettings.openAppSettings();
          break;
      }
    } catch (e, s) {
      _logger.error(
        message: 'Error opening app settings',
        error: e,
        stackTrace: s
      );
    }
  }

  // دوال مساعدة خاصة

  /// التحقق من حالة استثناء البطارية بشكل موثوق
  Future<bool> _checkBatteryOptimizationStatus() async {
    try {
      // محاولة التحقق بطرق متعددة
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isGranted) return true;
      
      // بعض الأجهزة قد ترجع قيم مختلفة
      final isRestricted = await Permission.ignoreBatteryOptimizations.isRestricted;
      final isDenied = await Permission.ignoreBatteryOptimizations.isDenied;
      
      // إذا لم يكن مقيداً أو مرفوضاً، فقد يكون ممنوحاً
      return !isRestricted && !isDenied;
    } catch (e) {
      _logger.warning(
        message: 'Error checking battery optimization status',
        data: {'error': e.toString()}
      );
      return false;
    }
  }

  /// تحويل PermissionStatus إلى AppPermissionStatus
  AppPermissionStatus _mapToPermissionStatus(PermissionStatus status) {
    if (status.isGranted) return AppPermissionStatus.granted;
    if (status.isPermanentlyDenied) return AppPermissionStatus.permanentlyDenied;
    if (status.isRestricted) return AppPermissionStatus.restricted;
    if (status.isLimited) return AppPermissionStatus.limited;
    if (status.isDenied) return AppPermissionStatus.denied;
    return AppPermissionStatus.unknown;
  }

  /// تسجيل محاولة طلب إذن
  void _recordPermissionAttempt(AppPermissionType type) {
    _permissionAttempts[type] = (_permissionAttempts[type] ?? 0) + 1;
    _lastRequestTime[type] = DateTime.now();
    
    _logger.debug(
      message: 'Permission attempt recorded',
      data: {
        'type': type.toString(),
        'attempts': _permissionAttempts[type],
      }
    );
  }

  /// التحقق من إمكانية طلب الإذن (cooldown period)
  bool _canRequestPermission(AppPermissionType type) {
    final lastRequest = _lastRequestTime[type];
    if (lastRequest == null) return true;
    
    final timeSinceLastRequest = DateTime.now().difference(lastRequest);
    return timeSinceLastRequest.inSeconds >= _requestCooldownSeconds;
  }

  /// تحديث الحالة المخزنة مؤقتاً
  AppPermissionStatus _updateCachedStatus(
    AppPermissionType type, 
    AppPermissionStatus status
  ) {
    _cachedStatuses[type] = status;
    return status;
  }

  /// الحصول على معلومات تحليلية عن الأذونات
  Map<String, dynamic> getPermissionAnalytics() {
    return {
      'attempts': _permissionAttempts.map((k, v) => MapEntry(k.toString(), v)),
      'cached_statuses': _cachedStatuses.map((k, v) => MapEntry(k.toString(), v.toString())),
      'last_requests': _lastRequestTime.map((k, v) => MapEntry(k.toString(), v.toIso8601String())),
    };
  }
}