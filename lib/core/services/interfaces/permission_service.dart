// lib/core/services/interfaces/permission_service.dart
// import 'package:permission_handler/permission_handler.dart'; // <--- تم الحذف

enum AppPermissionType {
  location,
  notification,
  doNotDisturb,
  batteryOptimization,
}

enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  unknown, // إضافة حالة غير معروفة
}

enum AppSettingsType {
  app,
  location,
  notification,
  battery,
  // doNotDisturb, // قد لا تكون هناك صفحة إعدادات مباشرة
}

abstract class PermissionService {
  Future<AppPermissionStatus> requestLocationPermission();
  Future<AppPermissionStatus> requestNotificationPermission();
  Future<AppPermissionStatus> requestDoNotDisturbPermission();
  Future<AppPermissionStatus> requestBatteryOptimizationPermission();
  Future<AppPermissionStatus> checkPermissionStatus(AppPermissionType permission);
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions();
  Future<void> openAppSettings([AppSettingsType? settingsPage]);
}