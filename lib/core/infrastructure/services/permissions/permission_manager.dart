// lib/core/services/permissions/permission_manager.dart

import 'package:flutter/material.dart';
import 'permission_service.dart';

/// Permission manager for handling app permissions
class PermissionManager {
  final PermissionService _permissionService;

  PermissionManager(this._permissionService);

  /// Check status of all permissions
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions() async {
    return await _permissionService.checkAllPermissions();
  }

  /// Request essential permissions (notification and location)
  Future<Map<AppPermissionType, AppPermissionStatus>> requestEssentialPermissions() async {
    final Map<AppPermissionType, AppPermissionStatus> results = {};
    
    // Request notification permission
    results[AppPermissionType.notification] = await _permissionService.requestPermission(
      AppPermissionType.notification,
    );
    
    // Request location permission
    results[AppPermissionType.location] = await _permissionService.requestPermission(
      AppPermissionType.location,
    );
    
    return results;
  }

  /// Request optional permissions (battery optimization and DND)
  Future<Map<AppPermissionType, AppPermissionStatus>> requestOptionalPermissions() async {
    final Map<AppPermissionType, AppPermissionStatus> results = {};
    
    // Request battery optimization permission
    results[AppPermissionType.batteryOptimization] = await _permissionService.requestPermission(
      AppPermissionType.batteryOptimization,
    );
    
    // Request DND permission
    results[AppPermissionType.doNotDisturb] = await _permissionService.requestPermission(
      AppPermissionType.doNotDisturb,
    );
    
    return results;
  }

  /// Request single permission
  Future<AppPermissionStatus> requestPermission(AppPermissionType type) async {
    return await _permissionService.requestPermission(type);
  }
  
  /// Request permission with rationale
  Future<AppPermissionStatus> requestPermissionWithRationale(
    BuildContext context,
    AppPermissionType type, {
    required String rationaleTitle,
    required String rationaleMessage,
    String? positiveButtonText,
    String? negativeButtonText,
  }) async {
    // Check if we should show rationale
    final shouldShowRationale = await _permissionService.shouldShowPermissionRationale(type);
    
    if (shouldShowRationale) {
      // Show rationale dialog
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(rationaleTitle),
          content: Text(rationaleMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(negativeButtonText ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(positiveButtonText ?? 'Continue'),
            ),
          ],
        ),
      );
      
      if (proceed != true) {
        return AppPermissionStatus.denied;
      }
    }
    
    return await _permissionService.requestPermission(type);
  }
  
  /// Open app settings for a specific permission type
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
        settingsType = AppSettingsType.notification;
        break;
    }
    
    await _permissionService.openAppSettings(settingsType);
  }
  
  /// Check if permission is granted
  Future<bool> isPermissionGranted(AppPermissionType type) async {
    final status = await _permissionService.checkPermissionStatus(type);
    return status == AppPermissionStatus.granted;
  }
  
  /// Check if permission is permanently denied
  Future<bool> isPermissionPermanentlyDenied(AppPermissionType type) async {
    final status = await _permissionService.checkPermissionStatus(type);
    return status == AppPermissionStatus.permanentlyDenied;
  }
  
  /// Get permission status
  Future<AppPermissionStatus> getPermissionStatus(AppPermissionType type) async {
    return await _permissionService.checkPermissionStatus(type);
  }
  
  /// Show permission denied dialog
  static Future<void> showPermissionDeniedDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onOpenSettings,
    String? settingsButtonText,
    String? cancelButtonText,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelButtonText ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onOpenSettings();
            },
            child: Text(settingsButtonText ?? 'Open Settings'),
          ),
        ],
      ),
    );
  }
}