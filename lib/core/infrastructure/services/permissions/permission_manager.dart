// lib/core/infrastructure/services/permissions/permission_manager.dart

import 'package:flutter/material.dart';
import '../logging/logger_service.dart';
import 'permission_service.dart';

/// Permission manager for handling app permissions with UI helpers
class PermissionManager {
  final PermissionService _permissionService;
  final LoggerService? _logger;
  
  // Permission request tracking
  final Map<AppPermissionType, DateTime> _lastRequestTime = {};
  final Map<AppPermissionType, int> _denialCount = {};
  
  // Constants
  static const Duration _requestCooldown = Duration(hours: 24);
  static const int _maxDenials = 3;

  PermissionManager(
    this._permissionService, {
    LoggerService? logger,
  }) : _logger = logger;

  /// Check status of all permissions
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions() async {
    _logger?.debug(message: '[PermissionManager] Checking all permissions');
    return await _permissionService.checkAllPermissions();
  }

  /// Request essential permissions (notification and location)
  Future<Map<AppPermissionType, AppPermissionStatus>> requestEssentialPermissions({
    BuildContext? context,
    bool showRationale = true,
  }) async {
    _logger?.info(message: '[PermissionManager] Requesting essential permissions');
    
    final Map<AppPermissionType, AppPermissionStatus> results = {};
    
    // Request notification permission
    if (context != null && showRationale) {
      final shouldProceed = await _showPermissionRationale(
        context,
        AppPermissionType.notification,
        title: 'Notification Permission',
        message: _permissionService.getPermissionDescription(AppPermissionType.notification),
      );
      
      if (!shouldProceed) {
        results[AppPermissionType.notification] = AppPermissionStatus.denied;
      } else {
        results[AppPermissionType.notification] = await _requestPermissionWithTracking(
          AppPermissionType.notification,
        );
      }
    } else {
      results[AppPermissionType.notification] = await _requestPermissionWithTracking(
        AppPermissionType.notification,
      );
    }
    
    // Request location permission
    if (context != null && context.mounted && showRationale) {
      final shouldProceed = await _showPermissionRationale(
        context,
        AppPermissionType.location,
        title: 'Location Permission',
        message: _permissionService.getPermissionDescription(AppPermissionType.location),
      );
      
      if (!shouldProceed) {
        results[AppPermissionType.location] = AppPermissionStatus.denied;
      } else {
        results[AppPermissionType.location] = await _requestPermissionWithTracking(
          AppPermissionType.location,
        );
      }
    } else {
      results[AppPermissionType.location] = await _requestPermissionWithTracking(
        AppPermissionType.location,
      );
    }
    
    _logger?.info(
      message: '[PermissionManager] Essential permissions requested',
      data: results.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
    
    return results;
  }

  /// Request optional permissions (battery optimization and DND)
  Future<Map<AppPermissionType, AppPermissionStatus>> requestOptionalPermissions({
    BuildContext? context,
    bool showRationale = true,
  }) async {
    _logger?.info(message: '[PermissionManager] Requesting optional permissions');
    
    final Map<AppPermissionType, AppPermissionStatus> results = {};
    
    // Request battery optimization permission
    if (_permissionService.isPermissionAvailable(AppPermissionType.batteryOptimization)) {
      if (context != null && showRationale) {
        final shouldProceed = await _showPermissionRationale(
          context,
          AppPermissionType.batteryOptimization,
          title: 'Battery Optimization',
          message: _permissionService.getPermissionDescription(AppPermissionType.batteryOptimization),
        );
        
        if (!shouldProceed) {
          results[AppPermissionType.batteryOptimization] = AppPermissionStatus.denied;
        } else {
          results[AppPermissionType.batteryOptimization] = await _requestPermissionWithTracking(
            AppPermissionType.batteryOptimization,
          );
        }
      } else {
        results[AppPermissionType.batteryOptimization] = await _requestPermissionWithTracking(
          AppPermissionType.batteryOptimization,
        );
      }
    }
    
    // Request DND permission
    if (_permissionService.isPermissionAvailable(AppPermissionType.doNotDisturb)) {
      if (context != null && context.mounted && showRationale) {
        final shouldProceed = await _showPermissionRationale(
          context,
          AppPermissionType.doNotDisturb,
          title: 'Do Not Disturb Access',
          message: _permissionService.getPermissionDescription(AppPermissionType.doNotDisturb),
        );
        
        if (!shouldProceed) {
          results[AppPermissionType.doNotDisturb] = AppPermissionStatus.denied;
        } else {
          results[AppPermissionType.doNotDisturb] = await _requestPermissionWithTracking(
            AppPermissionType.doNotDisturb,
          );
        }
      } else {
        results[AppPermissionType.doNotDisturb] = await _requestPermissionWithTracking(
          AppPermissionType.doNotDisturb,
        );
      }
    }
    
    _logger?.info(
      message: '[PermissionManager] Optional permissions requested',
      data: results.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
    
    return results;
  }

  /// Request single permission
  Future<AppPermissionStatus> requestPermission(
    AppPermissionType type, {
    BuildContext? context,
    bool showRationale = true,
  }) async {
    // Check if permission is available on platform
    if (!_permissionService.isPermissionAvailable(type)) {
      _logger?.info(
        message: '[PermissionManager] Permission not available on platform',
        data: {'type': type.toString()},
      );
      return AppPermissionStatus.granted;
    }
    
    // Check if should show rationale
    if (context != null && showRationale) {
      final shouldShowRationale = await _shouldShowRationale(type);
      
      if (shouldShowRationale) {
        final proceed = await _showPermissionRationale(
          context,
          type,
          title: _getPermissionTitle(type),
          message: _permissionService.getPermissionDescription(type),
        );
        
        if (!proceed) {
          return AppPermissionStatus.denied;
        }
      }
    }
    
    return await _requestPermissionWithTracking(type);
  }
  
  /// Request permission with rationale dialog
  Future<AppPermissionStatus> requestPermissionWithRationale(
    BuildContext context,
    AppPermissionType type, {
    required String rationaleTitle,
    required String rationaleMessage,
    String? positiveButtonText,
    String? negativeButtonText,
    VoidCallback? onDenied,
  }) async {
    // Check if we should show rationale
    final shouldShowRationale = await _permissionService.shouldShowPermissionRationale(type);
    
    if (shouldShowRationale || _shouldForceRationale(type)) {
      // Show rationale dialog
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(rationaleTitle),
          content: Text(rationaleMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                onDenied?.call();
              },
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
        _trackDenial(type);
        return AppPermissionStatus.denied;
      }
    }
    
    return await _requestPermissionWithTracking(type);
  }
  
  /// Check permission with automatic settings redirect
  Future<AppPermissionStatus> checkPermissionWithSettingsRedirect(
    BuildContext context,
    AppPermissionType type, {
    String? deniedMessage,
    String? permanentlyDeniedMessage,
  }) async {
    final status = await _permissionService.checkPermissionStatus(type);
    
    if (status == AppPermissionStatus.denied && context.mounted) {
      // Show denied dialog
      final shouldOpenSettings = await showPermissionDeniedDialog(
        context,
        title: 'Permission Denied',
        message: deniedMessage ?? 
            'This permission is required for the app to function properly. Please grant it in settings.',
        onOpenSettings: () => openPermissionSettings(type),
      );
      
      if (shouldOpenSettings) {
        await openPermissionSettings(type);
        // Recheck after returning from settings
        return await _permissionService.checkPermissionStatus(type);
      }
    } else if (status == AppPermissionStatus.permanentlyDenied && context.mounted) {
      // Show permanently denied dialog
      await showPermissionDeniedDialog(
        context,
        title: 'Permission Required',
        message: permanentlyDeniedMessage ?? 
            'This permission has been permanently denied. Please enable it in your device settings to continue.',
        onOpenSettings: () => openPermissionSettings(type),
        settingsButtonText: 'Open Settings',
      );
    }
    
    return status;
  }
  
  /// Open app settings for a specific permission type
  Future<void> openPermissionSettings(AppPermissionType type) async {
    _logger?.info(
      message: '[PermissionManager] Opening permission settings',
      data: {'type': type.toString()},
    );
    
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
      case AppPermissionType.storage:
      case AppPermissionType.photos:
      case AppPermissionType.mediaLibrary:
      case AppPermissionType.accessMediaLocation:
        settingsType = AppSettingsType.storage;
        break;
      case AppPermissionType.camera:
      case AppPermissionType.microphone:
      case AppPermissionType.contacts:
      case AppPermissionType.calendar:
      case AppPermissionType.reminders:
      case AppPermissionType.sensors:
      case AppPermissionType.bluetooth:
      case AppPermissionType.appTrackingTransparency:
      case AppPermissionType.criticalAlerts:
      case AppPermissionType.activityRecognition:
        settingsType = AppSettingsType.privacy;
        break;
      case AppPermissionType.unknown:
        settingsType = AppSettingsType.app;
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
  
  /// Check multiple permissions at once
  Future<bool> arePermissionsGranted(List<AppPermissionType> permissions) async {
    for (final permission in permissions) {
      final isGranted = await isPermissionGranted(permission);
      if (!isGranted) return false;
    }
    return true;
  }
  
  /// Get missing permissions from a list
  Future<List<AppPermissionType>> getMissingPermissions(
    List<AppPermissionType> requiredPermissions,
  ) async {
    final missing = <AppPermissionType>[];
    
    for (final permission in requiredPermissions) {
      final isGranted = await isPermissionGranted(permission);
      if (!isGranted) {
        missing.add(permission);
      }
    }
    
    return missing;
  }
  
  /// Show permission status widget
  static Widget buildPermissionStatus(
    AppPermissionType type,
    AppPermissionStatus status, {
    VoidCallback? onTap,
  }) {
    IconData icon;
    Color color;
    String statusText;
    
    switch (status) {
      case AppPermissionStatus.granted:
        icon = Icons.check_circle;
        color = Colors.green;
        statusText = 'Granted';
        break;
      case AppPermissionStatus.denied:
        icon = Icons.cancel;
        color = Colors.orange;
        statusText = 'Denied';
        break;
      case AppPermissionStatus.permanentlyDenied:
        icon = Icons.block;
        color = Colors.red;
        statusText = 'Permanently Denied';
        break;
      case AppPermissionStatus.restricted:
        icon = Icons.lock;
        color = Colors.grey;
        statusText = 'Restricted';
        break;
      case AppPermissionStatus.limited:
        icon = Icons.warning;
        color = Colors.amber;
        statusText = 'Limited';
        break;
      case AppPermissionStatus.provisional:
        icon = Icons.access_time;
        color = Colors.blue;
        statusText = 'Provisional';
        break;
      case AppPermissionStatus.unknown:
        icon = Icons.help;
        color = Colors.grey;
        statusText = 'Unknown';
        break;
    }
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(_getPermissionTitle(type)),
      subtitle: Text(statusText),
      trailing: status != AppPermissionStatus.granted && onTap != null
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
      onTap: onTap,
    );
  }
  
  /// Show permission denied dialog
  static Future<bool> showPermissionDeniedDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onOpenSettings,
    String? settingsButtonText,
    String? cancelButtonText,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelButtonText ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
              onOpenSettings();
            },
            child: Text(settingsButtonText ?? 'Open Settings'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  // Private helper methods
  
  Future<AppPermissionStatus> _requestPermissionWithTracking(
    AppPermissionType type,
  ) async {
    _lastRequestTime[type] = DateTime.now();
    final status = await _permissionService.requestPermission(type);
    
    if (status == AppPermissionStatus.denied || 
        status == AppPermissionStatus.permanentlyDenied) {
      _trackDenial(type);
    }
    
    return status;
  }
  
  void _trackDenial(AppPermissionType type) {
    _denialCount[type] = (_denialCount[type] ?? 0) + 1;
    _logger?.debug(
      message: '[PermissionManager] Permission denial tracked',
      data: {
        'type': type.toString(),
        'denial_count': _denialCount[type],
      },
    );
  }
  
  Future<bool> _shouldShowRationale(AppPermissionType type) async {
    // Check if should show based on denial count
    final denials = _denialCount[type] ?? 0;
    if (denials >= _maxDenials) {
      return false; // Don't show rationale after max denials
    }
    
    // Check if enough time has passed since last request
    final lastRequest = _lastRequestTime[type];
    if (lastRequest != null) {
      final timeSinceLastRequest = DateTime.now().difference(lastRequest);
      if (timeSinceLastRequest < _requestCooldown) {
        return false; // Don't show rationale too frequently
      }
    }
    
    return await _permissionService.shouldShowPermissionRationale(type);
  }
  
  bool _shouldForceRationale(AppPermissionType type) {
    // Force rationale for critical permissions on first request
    final criticalPermissions = [
      AppPermissionType.notification,
      AppPermissionType.location,
    ];
    
    return criticalPermissions.contains(type) && 
           (_denialCount[type] ?? 0) == 0;
  }
  
  Future<bool> _showPermissionRationale(
    BuildContext context,
    AppPermissionType type, {
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getPermissionIcon(type), size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(26), // Use withAlpha instead of withOpacity
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can change this later in settings',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  static String _getPermissionTitle(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.location:
        return 'Location';
      case AppPermissionType.notification:
        return 'Notifications';
      case AppPermissionType.doNotDisturb:
        return 'Do Not Disturb';
      case AppPermissionType.batteryOptimization:
        return 'Battery Optimization';
      case AppPermissionType.camera:
        return 'Camera';
      case AppPermissionType.microphone:
        return 'Microphone';
      case AppPermissionType.storage:
        return 'Storage';
      case AppPermissionType.contacts:
        return 'Contacts';
      case AppPermissionType.calendar:
        return 'Calendar';
      case AppPermissionType.reminders:
        return 'Reminders';
      case AppPermissionType.photos:
        return 'Photos';
      case AppPermissionType.mediaLibrary:
        return 'Media Library';
      case AppPermissionType.sensors:
        return 'Sensors';
      case AppPermissionType.bluetooth:
        return 'Bluetooth';
      case AppPermissionType.appTrackingTransparency:
        return 'App Tracking';
      case AppPermissionType.criticalAlerts:
        return 'Critical Alerts';
      case AppPermissionType.accessMediaLocation:
        return 'Media Location';
      case AppPermissionType.activityRecognition:
        return 'Activity Recognition';
      case AppPermissionType.unknown:
        return 'Permission';
    }
  }
  
  static IconData _getPermissionIcon(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.location:
        return Icons.location_on;
      case AppPermissionType.notification:
        return Icons.notifications;
      case AppPermissionType.doNotDisturb:
        return Icons.do_not_disturb;
      case AppPermissionType.batteryOptimization:
        return Icons.battery_charging_full;
      case AppPermissionType.camera:
        return Icons.camera_alt;
      case AppPermissionType.microphone:
        return Icons.mic;
      case AppPermissionType.storage:
        return Icons.storage;
      case AppPermissionType.contacts:
        return Icons.contacts;
      case AppPermissionType.calendar:
        return Icons.calendar_today;
      case AppPermissionType.reminders:
        return Icons.alarm;
      case AppPermissionType.photos:
        return Icons.photo_library;
      case AppPermissionType.mediaLibrary:
        return Icons.perm_media;
      case AppPermissionType.sensors:
        return Icons.sensors;
      case AppPermissionType.bluetooth:
        return Icons.bluetooth;
      case AppPermissionType.appTrackingTransparency:
        return Icons.track_changes;
      case AppPermissionType.criticalAlerts:
        return Icons.notification_important;
      case AppPermissionType.accessMediaLocation:
        return Icons.location_searching;
      case AppPermissionType.activityRecognition:
        return Icons.directions_walk;
      case AppPermissionType.unknown:
        return Icons.help_outline;
    }
  }
}