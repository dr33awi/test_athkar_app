// lib/core/infrastructure/services/permissions/permission_service.dart

/// Application permission types
enum AppPermissionType {
  location,
  notification,
  doNotDisturb,
  batteryOptimization,
  camera,
  microphone,
  storage,
  contacts,
  calendar,
  reminders,
  photos,
  mediaLibrary,
  sensors,
  bluetooth,
  appTrackingTransparency,
  criticalAlerts,
  accessMediaLocation,
  activityRecognition,
  unknown,
}

/// Permission status
enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  provisional,
  unknown,
}

/// Settings page types
enum AppSettingsType {
  app,
  location,
  notification,
  battery,
  storage,
  privacy,
  accessibility,
}

/// Permission service interface
abstract class PermissionService {
  /// Request a specific permission
  Future<AppPermissionStatus> requestPermission(AppPermissionType permission);
  
  /// Request multiple permissions
  Future<Map<AppPermissionType, AppPermissionStatus>> requestPermissions(
    List<AppPermissionType> permissions,
  );
  
  /// Check status of a specific permission
  Future<AppPermissionStatus> checkPermissionStatus(AppPermissionType permission);
  
  /// Check status of all permissions
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions();
  
  /// Open app settings
  Future<bool> openAppSettings([AppSettingsType? settingsPage]);
  
  /// Check if should show permission rationale
  Future<bool> shouldShowPermissionRationale(AppPermissionType permission);
  
  /// Check if permission is permanently denied
  Future<bool> isPermissionPermanentlyDenied(AppPermissionType permission);
  
  /// Get permission description
  String getPermissionDescription(AppPermissionType permission);
  
  /// Check if permission is available on current platform
  bool isPermissionAvailable(AppPermissionType permission);
}