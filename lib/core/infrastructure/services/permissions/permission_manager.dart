// lib/core/infrastructure/services/permissions/permission_manager.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as handler;
import 'permission_service.dart';

/// مدير الأذونات - التنفيذ الفعلي
class PermissionManager implements PermissionService {
  static const Map<AppPermissionType, String> _permissionDescriptions = {
    AppPermissionType.location: 'موقعك لحساب أوقات الصلاة بدقة',
    AppPermissionType.notification: 'الإشعارات لتذكيرك بالأذكار',
    AppPermissionType.doNotDisturb: 'عدم الإزعاج لتخصيص أوقات التذكير',
    AppPermissionType.batteryOptimization: 'تحسين البطارية لضمان عمل التطبيق',
    AppPermissionType.unknown: 'إذن غير معروف',
  };

  @override
  Future<AppPermissionStatus> requestPermission(AppPermissionType permission) async {
    final nativePermission = _mapToNativePermission(permission);
    if (nativePermission == null) {
      return AppPermissionStatus.unknown;
    }

    // معالجة خاصة لأذونات الموقع
    if (permission == AppPermissionType.location) {
      // التحقق من خدمات الموقع
      final serviceStatus = await handler.Permission.locationWhenInUse.serviceStatus;
      if (!serviceStatus.isEnabled) {
        return AppPermissionStatus.denied;
      }
    }

    final status = await nativePermission.request();
    return _mapFromNativeStatus(status);
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
    final nativePermission = _mapToNativePermission(permission);
    if (nativePermission == null) {
      return AppPermissionStatus.unknown;
    }

    final status = await nativePermission.status;
    return _mapFromNativeStatus(status);
  }

  @override
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions() async {
    final permissions = AppPermissionType.values
        .where((p) => p != AppPermissionType.unknown)
        .toList();
    
    final results = <AppPermissionType, AppPermissionStatus>{};
    for (final permission in permissions) {
      results[permission] = await checkPermissionStatus(permission);
    }
    
    return results;
  }

  @override
  Future<bool> openAppSettings([AppSettingsType? settingsPage]) async {
    if (settingsPage == null) {
      return await handler.openAppSettings();
    }

    // معالجة خاصة لصفحات الإعدادات المحددة
    switch (settingsPage) {
      case AppSettingsType.location:
        if (Platform.isIOS) {
          return await handler.openAppSettings();
        }
        return await handler.openAppSettings();
      
      case AppSettingsType.notification:
        if (Platform.isAndroid) {
          return await handler.openAppSettings();
        }
        return await handler.openAppSettings();
      
      case AppSettingsType.battery:
        if (Platform.isAndroid) {
          return await handler.openAppSettings();
        }
        return false;
      
      default:
        return await handler.openAppSettings();
    }
  }

  @override
  Future<bool> shouldShowPermissionRationale(AppPermissionType permission) async {
    if (!Platform.isAndroid) return false;
    
    final nativePermission = _mapToNativePermission(permission);
    if (nativePermission == null) return false;
    
    final status = await nativePermission.status;
    return status.isDenied && !status.isPermanentlyDenied;
  }

  @override
  Future<bool> isPermissionPermanentlyDenied(AppPermissionType permission) async {
    final nativePermission = _mapToNativePermission(permission);
    if (nativePermission == null) return false;
    
    final status = await nativePermission.status;
    return status.isPermanentlyDenied;
  }

  @override
  String getPermissionDescription(AppPermissionType permission) {
    return _permissionDescriptions[permission] ?? _permissionDescriptions[AppPermissionType.unknown]!;
  }

  @override
  bool isPermissionAvailable(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.location:
        return true;
      
      case AppPermissionType.notification:
        return true;
      
      case AppPermissionType.doNotDisturb:
        return Platform.isAndroid;
      
      case AppPermissionType.batteryOptimization:
        return Platform.isAndroid;
      
      case AppPermissionType.unknown:
        return false;
    }
  }

  // تحويل من أنواع الأذونات الخاصة بنا إلى أذونات المكتبة
  handler.Permission? _mapToNativePermission(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.location:
        return handler.Permission.locationWhenInUse;
      
      case AppPermissionType.notification:
        return handler.Permission.notification;
      
      case AppPermissionType.doNotDisturb:
        return Platform.isAndroid ? handler.Permission.accessNotificationPolicy : null;
      
      case AppPermissionType.batteryOptimization:
        return Platform.isAndroid ? handler.Permission.ignoreBatteryOptimizations : null;
      
      case AppPermissionType.unknown:
        return null;
    }
  }

  // تحويل من حالات المكتبة إلى حالاتنا
  AppPermissionStatus _mapFromNativeStatus(handler.PermissionStatus status) {
    if (status.isGranted) {
      return AppPermissionStatus.granted;
    } else if (status.isDenied) {
      return AppPermissionStatus.denied;
    } else if (status.isPermanentlyDenied) {
      return AppPermissionStatus.permanentlyDenied;
    } else if (status.isRestricted) {
      return AppPermissionStatus.restricted;
    } else if (status.isLimited) {
      return AppPermissionStatus.limited;
    } else if (status.isProvisional) {
      return AppPermissionStatus.provisional;
    } else {
      return AppPermissionStatus.unknown;
    }
  }

  // دالة مساعدة للحصول على الأيقونة المناسبة للإذن
  String getPermissionIcon(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.location:
        return '📍';
      case AppPermissionType.notification:
        return '🔔';
      case AppPermissionType.doNotDisturb:
        return '🔕';
      case AppPermissionType.batteryOptimization:
        return '🔋';
      case AppPermissionType.unknown:
        return '❓';
    }
  }

  // دالة مساعدة للحصول على اسم الإذن
  String getPermissionName(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.location:
        return 'الموقع';
      case AppPermissionType.notification:
        return 'الإشعارات';
      case AppPermissionType.doNotDisturb:
        return 'عدم الإزعاج';
      case AppPermissionType.batteryOptimization:
        return 'تحسين البطارية';
      case AppPermissionType.unknown:
        return 'غير معروف';
    }
  }
}