// lib/core/infrastructure/services/permissions/permission_service.dart

/// أنواع الأذونات المطلوبة لتطبيق الأذكار
enum AppPermissionType {
  location,
  notification,
  doNotDisturb,
  batteryOptimization,
  unknown,
}

/// حالة الإذن
enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  provisional,
  unknown,
}

/// أنواع صفحات الإعدادات
enum AppSettingsType {
  app,
  location,
  notification,
  battery,
  accessibility,
}

/// واجهة خدمة الأذونات
abstract class PermissionService {
  Future<AppPermissionStatus> requestPermission(AppPermissionType permission);
  Future<Map<AppPermissionType, AppPermissionStatus>> requestPermissions(
    List<AppPermissionType> permissions,
  );
  Future<AppPermissionStatus> checkPermissionStatus(AppPermissionType permission);
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions();
  Future<bool> openAppSettings([AppSettingsType? settingsPage]);
  Future<bool> shouldShowPermissionRationale(AppPermissionType permission);
  Future<bool> isPermissionPermanentlyDenied(AppPermissionType permission);
  String getPermissionDescription(AppPermissionType permission);
  bool isPermissionAvailable(AppPermissionType permission);
}