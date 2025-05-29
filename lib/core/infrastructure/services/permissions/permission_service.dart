// lib/core/services/permissions/permission_service.dart

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
  unknown,
}

enum AppSettingsType {
  app,
  location,
  notification,
  battery,
}

abstract class PermissionService {
  /// Request a specific permission
  Future<AppPermissionStatus> requestPermission(AppPermissionType permission);
  
  /// Check status of a specific permission
  Future<AppPermissionStatus> checkPermissionStatus(AppPermissionType permission);
  
  /// Check status of all permissions
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions();
  
  /// Open app settings
  Future<void> openAppSettings([AppSettingsType? settingsPage]);
  
  /// Check if should show permission rationale
  Future<bool> shouldShowPermissionRationale(AppPermissionType permission);
}