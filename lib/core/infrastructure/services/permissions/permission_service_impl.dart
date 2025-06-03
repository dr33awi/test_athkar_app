// lib/core/infrastructure/services/permissions/permission_service_impl.dart

import 'dart:io';
import 'package:permission_handler/permission_handler.dart' as handler;
import '../logging/logger_service.dart';
import 'permission_service.dart';

/// تنفيذ خدمة الأذونات المحسنة لتطبيق الأذكار
class PermissionServiceImpl implements PermissionService {
  final LoggerService _logger;
  
  static const Map<AppPermissionType, String> _permissionDescriptions = {
    AppPermissionType.location: 'موقعك لحساب أوقات الصلاة بدقة',
    AppPermissionType.notification: 'الإشعارات لتذكيرك بالأذكار',
    AppPermissionType.doNotDisturb: 'عدم الإزعاج لتخصيص أوقات التذكير',
    AppPermissionType.batteryOptimization: 'تحسين البطارية لضمان عمل التطبيق',
    AppPermissionType.unknown: 'إذن غير معروف',
  };
  
  PermissionServiceImpl({required LoggerService logger}) : _logger = logger;

  @override
  Future<AppPermissionStatus> requestPermission(AppPermissionType permission) async {
    _logger.info(message: 'طلب إذن', data: {'type': permission.toString()});
    
    final nativePermission = _mapToNativePermission(permission);
    if (nativePermission == null) {
      _logger.warning(message: 'نوع الإذن غير مدعوم', data: {'type': permission.toString()});
      return AppPermissionStatus.unknown;
    }

    try {
      // معالجة خاصة لأذونات الموقع
      if (permission == AppPermissionType.location) {
        // التحقق من خدمات الموقع
        final serviceStatus = await handler.Permission.locationWhenInUse.serviceStatus;
        if (!serviceStatus.isEnabled) {
          _logger.warning(message: 'خدمات الموقع غير مفعلة');
          return AppPermissionStatus.denied;
        }
      }

      final status = await nativePermission.request();
      final appStatus = _mapFromNativeStatus(status);
      
      _logger.info(
        message: 'نتيجة طلب الإذن', 
        data: {
          'type': permission.toString(),
          'status': appStatus.toString()
        }
      );
      
      return appStatus;
    } catch (e) {
      _logger.error(message: 'خطأ في طلب الإذن', error: e);
      return AppPermissionStatus.unknown;
    }
  }

  @override
  Future<Map<AppPermissionType, AppPermissionStatus>> requestPermissions(
    List<AppPermissionType> permissions,
  ) async {
    _logger.info(
      message: 'طلب أذونات متعددة', 
      data: {'permissions': permissions.map((p) => p.toString()).toList()}
    );
    
    final results = <AppPermissionType, AppPermissionStatus>{};
    
    for (final permission in permissions) {
      results[permission] = await requestPermission(permission);
    }
    
    _logger.info(
      message: 'نتائج طلب الأذونات', 
      data: results.map((k, v) => MapEntry(k.toString(), v.toString()))
    );
    
    return results;
  }

  @override
  Future<AppPermissionStatus> checkPermissionStatus(AppPermissionType permission) async {
    final nativePermission = _mapToNativePermission(permission);
    if (nativePermission == null) {
      _logger.warning(message: 'نوع الإذن غير مدعوم للفحص', data: {'type': permission.toString()});
      return AppPermissionStatus.unknown;
    }

    try {
      final status = await nativePermission.status;
      final appStatus = _mapFromNativeStatus(status);
      
      _logger.debug(
        message: 'حالة الإذن', 
        data: {
          'type': permission.toString(),
          'status': appStatus.toString()
        }
      );
      
      return appStatus;
    } catch (e) {
      _logger.error(message: 'خطأ في فحص حالة الإذن', error: e);
      return AppPermissionStatus.unknown;
    }
  }

  @override
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions() async {
    final permissions = AppPermissionType.values
        .where((p) => p != AppPermissionType.unknown)
        .toList();
    
    _logger.info(message: 'فحص جميع الأذونات');
    
    final results = <AppPermissionType, AppPermissionStatus>{};
    for (final permission in permissions) {
      results[permission] = await checkPermissionStatus(permission);
    }
    
    _logger.info(
      message: 'نتائج فحص جميع الأذونات', 
      data: results.map((k, v) => MapEntry(k.toString(), v.toString()))
    );
    
    return results;
  }

  @override
  Future<bool> openAppSettings([AppSettingsType? settingsPage]) async {
    _logger.info(
      message: 'فتح الإعدادات', 
      data: {'settingsPage': settingsPage?.toString() ?? 'app'}
    );
    
    try {
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
          _logger.warning(message: 'إعدادات البطارية غير متوفرة على iOS');
          return false;
        
        default:
          return await handler.openAppSettings();
      }
    } catch (e) {
      _logger.error(message: 'خطأ في فتح الإعدادات', error: e);
      return false;
    }
  }

  @override
  Future<bool> shouldShowPermissionRationale(AppPermissionType permission) async {
    if (!Platform.isAndroid) {
      _logger.debug(message: 'shouldShowPermissionRationale متوفر فقط على Android');
      return false;
    }
    
    final nativePermission = _mapToNativePermission(permission);
    if (nativePermission == null) return false;
    
    try {
      final status = await nativePermission.status;
      final shouldShow = status.isDenied && !status.isPermanentlyDenied;
      
      _logger.debug(
        message: 'shouldShowPermissionRationale', 
        data: {
          'type': permission.toString(),
          'shouldShow': shouldShow
        }
      );
      
      return shouldShow;
    } catch (e) {
      _logger.error(message: 'خطأ في فحص shouldShowPermissionRationale', error: e);
      return false;
    }
  }

  @override
  Future<bool> isPermissionPermanentlyDenied(AppPermissionType permission) async {
    final nativePermission = _mapToNativePermission(permission);
    if (nativePermission == null) return false;
    
    try {
      final status = await nativePermission.status;
      final isPermanentlyDenied = status.isPermanentlyDenied;
      
      _logger.debug(
        message: 'فحص الرفض الدائم', 
        data: {
          'type': permission.toString(),
          'isPermanentlyDenied': isPermanentlyDenied
        }
      );
      
      return isPermanentlyDenied;
    } catch (e) {
      _logger.error(message: 'خطأ في فحص الرفض الدائم', error: e);
      return false;
    }
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