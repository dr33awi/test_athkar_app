// lib/core/services/permission_manager.dart
import 'package:flutter/material.dart';
import './interfaces/permission_service.dart';

class PermissionManager {
  final PermissionService _permissionService;

  PermissionManager(this._permissionService);

  // Check status of all permissions
  Future<Map<AppPermissionType, AppPermissionStatus>> checkPermissions() async {
    return await _permissionService.checkAllPermissions();
  }

  // Request essential permissions (notification and location)
  Future<Map<AppPermissionType, AppPermissionStatus>> requestEssentialPermissions(BuildContext context) async {
    Map<AppPermissionType, AppPermissionStatus> results = {};
    
    // Request notification permission
    final notificationStatus = await _permissionService.requestNotificationPermission();
    results[AppPermissionType.notification] = notificationStatus;
    
    // Request location permission
    final locationStatus = await _permissionService.requestLocationPermission();
    results[AppPermissionType.location] = locationStatus;
    
    return results;
  }

  // Request optional permissions (battery optimization and DND)
  Future<Map<AppPermissionType, AppPermissionStatus>> requestOptionalPermissions(BuildContext context) async {
    Map<AppPermissionType, AppPermissionStatus> results = {};
    
    // Request battery optimization permission
    final batteryOptStatus = await _permissionService.requestBatteryOptimizationPermission();
    results[AppPermissionType.batteryOptimization] = batteryOptStatus;
    
    // Request DND permission
    final dndStatus = await _permissionService.requestDoNotDisturbPermission();
    results[AppPermissionType.doNotDisturb] = dndStatus;
    
    return results;
  }

  // Request location permission specifically
  Future<AppPermissionStatus> requestLocationPermission(BuildContext context) async {
    return await _permissionService.requestLocationPermission();
  }
  
  // Open app settings for a specific permission type
  Future<void> openPermissionSettings(AppPermissionType type) async {
    AppSettingsType? settingsType;
    
    switch (type) {
      case AppPermissionType.location:
        settingsType = AppSettingsType.location;
        break;
      case AppPermissionType.notification:
        settingsType = AppSettingsType.notification;
        break;
      case AppPermissionType.batteryOptimization:
        settingsType = AppSettingsType.battery;
        break;
      case AppPermissionType.doNotDisturb:
        settingsType = AppSettingsType.app;
        break;
    }
    
    await _permissionService.openAppSettings(settingsType);
  }
  
  // Helper methods for checking specific permissions
  Future<bool> hasLocationPermission() async {
    final status = await _permissionService.checkPermissionStatus(AppPermissionType.location);
    return status == AppPermissionStatus.granted;
  }
  
  Future<bool> hasNotificationPermission() async {
    final status = await _permissionService.checkPermissionStatus(AppPermissionType.notification);
    return status == AppPermissionStatus.granted;
  }
  
  Future<bool> hasBatteryOptimizationPermission() async {
    final status = await _permissionService.checkPermissionStatus(AppPermissionType.batteryOptimization);
    return status == AppPermissionStatus.granted;
  }
  
  Future<bool> hasDoNotDisturbPermission() async {
    final status = await _permissionService.checkPermissionStatus(AppPermissionType.doNotDisturb);
    return status == AppPermissionStatus.granted;
  }
}