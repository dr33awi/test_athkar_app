// lib/core/infrastructure/services/permissions/permission_service_impl.dart

import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart' as app_settings;
import '../logging/logger_service.dart';
import '../../../../app/di/service_locator.dart';
import 'permission_service.dart';

/// Implementation of permission service
class PermissionServiceImpl implements PermissionService {
  final LoggerService _logger;
  final Map<AppPermissionType, int> _permissionAttempts = {};
  final Map<AppPermissionType, DateTime> _lastRequestTime = {};
  final Map<AppPermissionType, AppPermissionStatus> _cachedStatuses = {};
  
  // Configuration
  static const int _requestCooldownSeconds = 30;
  static const int _maxAttemptsBeforePermanent = 3;
  
  PermissionServiceImpl({LoggerService? logger})
      : _logger = logger ?? getIt<LoggerService>() {
    _logger.debug(message: 'PermissionServiceImpl initialized');
  }

  @override
  Future<AppPermissionStatus> requestPermission(AppPermissionType permission) async {
    _logger.info(message: 'Requesting permission', data: {'type': permission.toString()});
    
    // Check if available on platform
    if (!isPermissionAvailable(permission)) {
      _logger.info(message: 'Permission not available on platform', data: {'type': permission.toString()});
      return AppPermissionStatus.granted;
    }
    
    // Check cooldown period
    if (!_canRequestPermission(permission)) {
      _logger.warning(
        message: 'Permission request blocked by cooldown',
        data: {
          'permission': permission.toString(),
          'cooldown_seconds': _requestCooldownSeconds,
        }
      );
      return await checkPermissionStatus(permission);
    }
    
    _recordPermissionAttempt(permission);
    
    try {
      // Get platform permission
      final platformPermission = _getPlatformPermission(permission);
      if (platformPermission == null) {
        _logger.error(
          message: 'Platform permission mapping not found',
          error: 'Unknown permission type: $permission',
        );
        return AppPermissionStatus.unknown;
      }
      
      // Check current status
      final currentStatus = await platformPermission.status;
      if (currentStatus.isGranted) {
        _logger.info(message: 'Permission already granted', data: {'type': permission.toString()});
        return _updateCachedStatus(permission, AppPermissionStatus.granted);
      }
      
      // Special handling for certain permissions
      if (permission == AppPermissionType.doNotDisturb && Platform.isAndroid) {
        return await _requestDoNotDisturbPermission();
      } else if (permission == AppPermissionType.batteryOptimization) {
        return await _requestBatteryOptimizationPermission();
      }
      
      // Request permission
      final status = await platformPermission.request();
      final appStatus = _mapToPermissionStatus(status);
      
      _logger.info(
        message: 'Permission request result',
        data: {
          'permission': permission.toString(),
          'status': appStatus.toString(),
        }
      );
      
      // Log analytics event
_logger.logEvent('permission_requested', parameters: {
  'type': permission.toString(),
  'result': appStatus.toString(),
  'attempt': _permissionAttempts[permission] ?? 1,
});
      
      return _updateCachedStatus(permission, appStatus);
    } catch (e, s) {
      _logger.error(
        message: 'Error requesting permission',
        error: e,
        stackTrace: s,
      );
      return AppPermissionStatus.unknown;
    }
  }
  
  @override
  Future<Map<AppPermissionType, AppPermissionStatus>> requestPermissions(
    List<AppPermissionType> permissions,
  ) async {
    _logger.info(
      message: 'Requesting multiple permissions',
      data: {'count': permissions.length},
    );
    
    final results = <AppPermissionType, AppPermissionStatus>{};
    
    for (final permission in permissions) {
      results[permission] = await requestPermission(permission);
    }
    
    return results;
  }

  @override
  Future<AppPermissionStatus> checkPermissionStatus(AppPermissionType permission) async {
    _logger.debug(
      message: 'Checking permission status',
      data: {'permission': permission.toString()}
    );
    
    // Check if available on platform
    if (!isPermissionAvailable(permission)) {
      return AppPermissionStatus.granted;
    }
    
    try {
      // Special handling for battery optimization
      if (permission == AppPermissionType.batteryOptimization) {
        final isGranted = await _checkBatteryOptimizationStatus();
        return _updateCachedStatus(
          permission,
          isGranted ? AppPermissionStatus.granted : AppPermissionStatus.denied
        );
      }
      
      // Get platform permission
      final platformPermission = _getPlatformPermission(permission);
      if (platformPermission == null) {
        _logger.error(
          message: 'Platform permission mapping not found',
          error: 'Unknown permission type: $permission',
        );
        return AppPermissionStatus.unknown;
      }
      
      final status = await platformPermission.status;
      final appStatus = _mapToPermissionStatus(status);
      return _updateCachedStatus(permission, appStatus);
    } catch (e, s) {
      _logger.error(
        message: 'Error checking permission status',
        error: e,
        stackTrace: s
      );
      return AppPermissionStatus.unknown;
    }
  }

  @override
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions() async {
    _logger.info(message: 'Checking all permissions');
    
    final Map<AppPermissionType, AppPermissionStatus> results = {};
    
    // Check all available permissions
    final availablePermissions = AppPermissionType.values
        .where((type) => type != AppPermissionType.unknown && isPermissionAvailable(type))
        .toList();
    
    // Check permissions in parallel
    final futures = availablePermissions.map((type) async {
      final status = await checkPermissionStatus(type);
      return MapEntry(type, status);
    });
    
    final entries = await Future.wait(futures);
    results.addEntries(entries);
    
    _logger.info(
      message: 'All permissions checked',
      data: {
        'results': results.map((k, v) => MapEntry(k.toString(), v.toString()))
      }
    );
    
    return results;
  }

  @override
  Future<bool> openAppSettings([AppSettingsType? settingsPage]) async {
    _logger.info(
      message: 'Opening app settings',
      data: {'page': settingsPage?.toString() ?? 'default'}
    );
    
    try {
      bool opened = false;
      
switch (settingsPage) {
  case AppSettingsType.location:
    await app_settings.AppSettings.openAppSettings(type: app_settings.AppSettingsType.location);
    opened = true;
    break;
  case AppSettingsType.notification:
    await app_settings.AppSettings.openAppSettings(type: app_settings.AppSettingsType.notification);
    opened = true;
    break;
  case AppSettingsType.battery:
    await app_settings.AppSettings.openAppSettings(type: app_settings.AppSettingsType.batteryOptimization);
    opened = true;
    break;
  case AppSettingsType.storage:
    await app_settings.AppSettings.openAppSettings(type: app_settings.AppSettingsType.internalStorage);
    opened = true;
    break;
  case AppSettingsType.privacy:
    await app_settings.AppSettings.openAppSettings(type: app_settings.AppSettingsType.security);
    opened = true;
    break;
  case AppSettingsType.accessibility:
    await app_settings.AppSettings.openAppSettings(type: app_settings.AppSettingsType.accessibility);
    opened = true;
    break;
  case AppSettingsType.app:
  case null:
    await app_settings.AppSettings.openAppSettings();
    opened = true;
    break;
}
      
      // Schedule a recheck after user might return
      if (opened) {
        Timer(const Duration(seconds: 3), () async {
          await checkAllPermissions();
        });
      }
      
_logger.logEvent('settings_opened', parameters: {'page': settingsPage?.toString() ?? 'app'});
      
      return opened;
    } catch (e, s) {
      _logger.error(
        message: 'Error opening app settings',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  @override
  Future<bool> shouldShowPermissionRationale(AppPermissionType permission) async {
    try {
      final platformPermission = _getPlatformPermission(permission);
      if (platformPermission == null) {
        return false;
      }
      
      // Check if we should show rationale
      final status = await platformPermission.status;
      final shouldShowRationale = await platformPermission.shouldShowRequestRationale;
      
      // Also check attempt count
      final attempts = _permissionAttempts[permission] ?? 0;
      final shouldShowBasedOnAttempts = attempts > 0 && attempts < _maxAttemptsBeforePermanent;
      
      _logger.debug(
        message: 'Permission rationale check',
        data: {
          'permission': permission.toString(),
          'status': status.toString(),
          'shouldShowRationale': shouldShowRationale,
          'attempts': attempts,
          'shouldShowBasedOnAttempts': shouldShowBasedOnAttempts,
        }
      );
      
      return shouldShowRationale || shouldShowBasedOnAttempts;
    } catch (e) {
      _logger.warning(
        message: 'Error checking permission rationale',
        data: {'permission': permission.toString(), 'error': e.toString()}
      );
      return false;
    }
  }
  
  @override
  Future<bool> isPermissionPermanentlyDenied(AppPermissionType permission) async {
    final status = await checkPermissionStatus(permission);
    return status == AppPermissionStatus.permanentlyDenied;
  }
  
  @override
  String getPermissionDescription(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.location:
        return 'Access to your location helps us provide prayer times and Qibla direction for your area.';
      case AppPermissionType.notification:
        return 'Notifications allow us to remind you of prayer times and daily Athkar.';
      case AppPermissionType.doNotDisturb:
        return 'Do Not Disturb access ensures important reminders can reach you when needed.';
      case AppPermissionType.batteryOptimization:
        return 'Battery optimization exemption ensures timely notifications even in power-saving mode.';
      case AppPermissionType.camera:
        return 'Camera access is needed to scan QR codes or take photos.';
      case AppPermissionType.microphone:
        return 'Microphone access is needed for audio recording features.';
      case AppPermissionType.storage:
        return 'Storage access allows saving and accessing your data locally.';
      case AppPermissionType.contacts:
        return 'Contacts access helps you share content with your contacts.';
      case AppPermissionType.calendar:
        return 'Calendar access allows adding prayer times and events to your calendar.';
      case AppPermissionType.reminders:
        return 'Reminders access helps create system reminders for prayers and Athkar.';
      case AppPermissionType.photos:
        return 'Photos access allows selecting and saving images.';
      case AppPermissionType.mediaLibrary:
        return 'Media library access is needed to save and access media files.';
      case AppPermissionType.sensors:
        return 'Sensor access helps determine device orientation for features like Qibla.';
      case AppPermissionType.bluetooth:
        return 'Bluetooth access allows connecting to nearby devices.';
      case AppPermissionType.appTrackingTransparency:
        return 'This helps us improve the app experience while respecting your privacy.';
      case AppPermissionType.criticalAlerts:
        return 'Critical alerts ensure you receive important notifications even in Do Not Disturb mode.';
      case AppPermissionType.accessMediaLocation:
        return 'Media location access helps organize photos by location.';
      case AppPermissionType.activityRecognition:
        return 'Activity recognition helps provide context-aware reminders.';
      case AppPermissionType.unknown:
        return 'This permission helps improve your app experience.';
    }
  }
  
  @override
  bool isPermissionAvailable(AppPermissionType permission) {
    // Platform-specific availability
    if (Platform.isIOS) {
      switch (permission) {
        case AppPermissionType.doNotDisturb:
        case AppPermissionType.batteryOptimization:
        case AppPermissionType.accessMediaLocation:
        case AppPermissionType.activityRecognition:
          return false;
        default:
          return true;
      }
    } else if (Platform.isAndroid) {
      switch (permission) {
        case AppPermissionType.appTrackingTransparency:
        case AppPermissionType.criticalAlerts:
        case AppPermissionType.reminders:
        case AppPermissionType.mediaLibrary:
          return false;
        default:
          return true;
      }
    }
    
    return false;
  }

  // Private helper methods

  /// Get platform permission for app permission type
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
      case AppPermissionType.camera:
        return Permission.camera;
      case AppPermissionType.microphone:
        return Permission.microphone;
      case AppPermissionType.storage:
        return Permission.storage;
      case AppPermissionType.contacts:
        return Permission.contacts;
      case AppPermissionType.calendar:
        return Permission.calendarFullAccess;
      case AppPermissionType.reminders:
        return Platform.isIOS ? Permission.reminders : null;
      case AppPermissionType.photos:
        return Permission.photos;
      case AppPermissionType.mediaLibrary:
        return Platform.isIOS ? Permission.mediaLibrary : null;
      case AppPermissionType.sensors:
        return Permission.sensors;
      case AppPermissionType.bluetooth:
        return Permission.bluetooth;
      case AppPermissionType.appTrackingTransparency:
        return Platform.isIOS ? Permission.appTrackingTransparency : null;
      case AppPermissionType.criticalAlerts:
        return Platform.isIOS ? Permission.criticalAlerts : null;
      case AppPermissionType.accessMediaLocation:
        return Platform.isAndroid ? Permission.accessMediaLocation : null;
      case AppPermissionType.activityRecognition:
        return Platform.isAndroid ? Permission.activityRecognition : null;
      case AppPermissionType.unknown:
        return null;
    }
  }

  /// Request Do Not Disturb permission (Android specific)
  Future<AppPermissionStatus> _requestDoNotDisturbPermission() async {
    if (!Platform.isAndroid) {
      _logger.info(message: 'DND permission not applicable on this platform');
      return AppPermissionStatus.granted;
    }
    
    try {
      // Check current status
      final currentStatus = await Permission.accessNotificationPolicy.status;
      if (currentStatus.isGranted) {
        _logger.info(message: 'DND permission already granted');
        return _updateCachedStatus(AppPermissionType.doNotDisturb, AppPermissionStatus.granted);
      }
      
      // Request permission
      final status = await Permission.accessNotificationPolicy.request();
      final appStatus = _mapToPermissionStatus(status);
      
      _logger.info(
        message: 'DND permission request result',
        data: {'status': appStatus.toString()}
      );
      
      // If denied, might need to open settings manually
      if (appStatus == AppPermissionStatus.denied || 
          appStatus == AppPermissionStatus.permanentlyDenied) {
        _logger.info(message: 'Opening DND settings for manual permission grant');
        await openAppSettings(AppSettingsType.notification);
      }
      
      return _updateCachedStatus(AppPermissionType.doNotDisturb, appStatus);
    } catch (e, s) {
      _logger.error(
        message: 'Error requesting DND permission',
        error: e,
        stackTrace: s,
      );
      return AppPermissionStatus.unknown;
    }
  }

  /// Request battery optimization permission
  Future<AppPermissionStatus> _requestBatteryOptimizationPermission() async {
    try {
      // Check current status
      final isGranted = await _checkBatteryOptimizationStatus();
      if (isGranted) {
        _logger.info(message: 'Battery optimization already disabled (permission granted)');
        return _updateCachedStatus(
          AppPermissionType.batteryOptimization, 
          AppPermissionStatus.granted
        );
      }
      
      // Request permission
      final status = await Permission.ignoreBatteryOptimizations.request();
      
      if (!status.isGranted) {
        _logger.info(message: 'Opening battery optimization settings');
        await openAppSettings(AppSettingsType.battery);
        
        // Wait and recheck
        await Future.delayed(const Duration(seconds: 3));
        final recheckStatus = await _checkBatteryOptimizationStatus();
        
        return _updateCachedStatus(
          AppPermissionType.batteryOptimization,
          recheckStatus ? AppPermissionStatus.granted : AppPermissionStatus.denied
        );
      }
      
      final appStatus = _mapToPermissionStatus(status);
      _logger.info(
        message: 'Battery optimization permission request result',
        data: {'status': appStatus.toString()}
      );
      
      return _updateCachedStatus(AppPermissionType.batteryOptimization, appStatus);
    } catch (e, s) {
      _logger.error(
        message: 'Error requesting battery optimization permission',
        error: e,
        stackTrace: s,
      );
      return AppPermissionStatus.unknown;
    }
  }

  /// Check battery optimization status reliably
  Future<bool> _checkBatteryOptimizationStatus() async {
    try {
      // Try multiple methods to check status
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isGranted) return true;
      
      // Some devices might return different values
      final isRestricted = await Permission.ignoreBatteryOptimizations.isRestricted;
      final isDenied = await Permission.ignoreBatteryOptimizations.isDenied;
      
      // If not restricted or denied, might be granted
      return !isRestricted && !isDenied;
    } catch (e) {
      _logger.warning(
        message: 'Error checking battery optimization status',
        data: {'error': e.toString()}
      );
      return false;
    }
  }

  /// Convert PermissionStatus to AppPermissionStatus
  AppPermissionStatus _mapToPermissionStatus(PermissionStatus status) {
    if (status.isGranted) return AppPermissionStatus.granted;
    if (status.isPermanentlyDenied) return AppPermissionStatus.permanentlyDenied;
    if (status.isRestricted) return AppPermissionStatus.restricted;
    if (status.isLimited) return AppPermissionStatus.limited;
    if (status.isProvisional) return AppPermissionStatus.provisional;
    if (status.isDenied) return AppPermissionStatus.denied;
    return AppPermissionStatus.unknown;
  }

  /// Record permission request attempt
  void _recordPermissionAttempt(AppPermissionType type) {
    _permissionAttempts[type] = (_permissionAttempts[type] ?? 0) + 1;
    _lastRequestTime[type] = DateTime.now();
    
    _logger.debug(
      message: 'Permission attempt recorded',
      data: {
        'type': type.toString(),
        'attempts': _permissionAttempts[type],
      }
    );
  }

  /// Check if can request permission (cooldown period)
  bool _canRequestPermission(AppPermissionType type) {
    final lastRequest = _lastRequestTime[type];
    if (lastRequest == null) return true;
    
    final timeSinceLastRequest = DateTime.now().difference(lastRequest);
    return timeSinceLastRequest.inSeconds >= _requestCooldownSeconds;
  }

  /// Update cached status
  AppPermissionStatus _updateCachedStatus(
    AppPermissionType type, 
    AppPermissionStatus status
  ) {
    _cachedStatuses[type] = status;
    return status;
  }

  /// Get analytics data for permissions
  Map<String, dynamic> getPermissionAnalytics() {
    return {
      'attempts': _permissionAttempts.map((k, v) => MapEntry(k.toString(), v)),
      'cached_statuses': _cachedStatuses.map((k, v) => MapEntry(k.toString(), v.toString())),
      'last_requests': _lastRequestTime.map((k, v) => MapEntry(k.toString(), v.toIso8601String())),
    };
  }

  /// Clear cache
  void clearCache() {
    _cachedStatuses.clear();
    _logger.debug(message: 'Permission status cache cleared');
  }

  /// Dispose resources
  void dispose() {
    clearCache();
    _permissionAttempts.clear();
    _lastRequestTime.clear();
    _logger.debug(message: 'PermissionServiceImpl disposed');
  }
}