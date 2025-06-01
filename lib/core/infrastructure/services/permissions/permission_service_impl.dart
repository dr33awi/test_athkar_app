// lib/core/infrastructure/services/permissions/permission_service_impl.dart

import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart' as app_settings;
import '../logging/logger_service.dart';
import 'permission_service.dart';

/// تنفيذ خدمة الأذونات المبسطة لتطبيق الأذكار
class PermissionServiceImpl implements PermissionService {
  final LoggerService _logger;
  
  PermissionServiceImpl({required LoggerService logger}) : _logger = logger;

  @override
  Future<AppPermissionStatus> requestPermission(AppPermissionType permission) async {
    _logger.info(message: 'طلب إذن', data: {'type': permission.toString()});
    
    if (!isPermissionAvailable(permission)) {
      _logger.info(message: 'الإذن غير متوفر على هذه المنصة');
      return AppPermissionStatus.granted;
    }
    
    try {
      final platformPermission = _getPlatformPermission(permission);
      if (platformPermission == null) {
        return AppPermissionStatus.unknown;
      }
      
      final status = await platformPermission.request();
      return _mapToPermissionStatus(status);
    } catch (e) {
      _logger.error(message: 'خطأ في طلب الإذن', error: e);
      return AppPermissionStatus.unknown;
    }
  }
  
  @override
  Future<Map<AppPermissionType, AppPermissionStatus>> requestPermissions(
    List<AppPermissionType> permissions,
  ) async {
    final results = <AppPermissionType, AppPermissionStatus>{};
    
    for (final permission in permissions) {
      results[permission] = await requestPermission(permission);
    }
    
    return results;
  }

  @override
  Future<AppPermissionStatus> checkPermissionStatus(AppPermissionType permission) async {
    if (!isPermissionAvailable(permission)) {
      return AppPermissionStatus.granted;
    }
    
    try {
      final platformPermission = _getPlatformPermission(permission);
      if (platformPermission == null) {
        return AppPermissionStatus.unknown;
      }
      
      final status = await platformPermission.status;
      return _mapToPermissionStatus(status);
    } catch (e) {
      _logger.error(message: 'خطأ في فحص حالة الإذن', error: e);
      return AppPermissionStatus.unknown;
    }
  }

  @override
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions() async {
    final Map<AppPermissionType, AppPermissionStatus> results = {};
    
    for (final type in AppPermissionType.values) {
      if (isPermissionAvailable(type)) {
        results[type] = await checkPermissionStatus(type);
      }
    }
    
    return results;
  }

  @override
  Future<bool> openAppSettings([AppSettingsType? settingsPage]) async {
    try {
      switch (settingsPage) {
        case AppSettingsType.location:
          await app_settings.AppSettings.openAppSettings(
            type: app_settings.AppSettingsType.location
          );
          return true;
        case AppSettingsType.notification:
          await app_settings.AppSettings.openAppSettings(
            type: app_settings.AppSettingsType.notification
          );
          return true;
        case AppSettingsType.battery:
          await app_settings.AppSettings.openAppSettings(
            type: app_settings.AppSettingsType.batteryOptimization
          );
          return true;
        case AppSettingsType.app:
        case null:
          await app_settings.AppSettings.openAppSettings();
          return true;
      }
    } catch (e) {
      _logger.error(message: 'خطأ في فتح الإعدادات', error: e);
      return false;
    }
  }
  
  @override
  String getPermissionDescription(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.location:
        return 'نحتاج إلى موقعك لعرض مواقيت الصلاة واتجاه القبلة بدقة.';
      case AppPermissionType.notification:
        return 'نحتاج إلى إذن الإشعارات لتذكيرك بالأذكار ومواقيت الصلاة.';
      case AppPermissionType.doNotDisturb:
        return 'نحتاج هذا الإذن لضمان وصول التذكيرات المهمة حتى في وضع عدم الإزعاج.';
      case AppPermissionType.batteryOptimization:
        return 'نحتاج إلى تعطيل تحسين البطارية لضمان عمل التذكيرات في الوقت المحدد.';
    }
  }
  
  @override
  bool isPermissionAvailable(AppPermissionType permission) {
    if (Platform.isIOS) {
      switch (permission) {
        case AppPermissionType.doNotDisturb:
        case AppPermissionType.batteryOptimization:
          return false;
        default:
          return true;
      }
    } else if (Platform.isAndroid) {
      return true;
    }
    return false;
  }

  Permission? _getPlatformPermission(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.location:
        return Permission.location;
      case AppPermissionType.notification:
        return Permission.notification;
      case AppPermissionType.doNotDisturb:
        return Platform.isAndroid ? Permission.accessNotificationPolicy : null;
      case AppPermissionType.batteryOptimization:
        return Platform.isAndroid ? Permission.ignoreBatteryOptimizations : null;
    }
  }

  AppPermissionStatus _mapToPermissionStatus(PermissionStatus status) {
    if (status.isGranted) return AppPermissionStatus.granted;
    if (status.isPermanentlyDenied) return AppPermissionStatus.permanentlyDenied;
    if (status.isRestricted) return AppPermissionStatus.restricted;
    if (status.isDenied) return AppPermissionStatus.denied;
    return AppPermissionStatus.unknown;
  }
}