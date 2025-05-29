// lib/core/infrastructure/services/permissions/permission_service_impl.dart
import 'dart:async';
import 'dart:io';
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart' as app_settings;
import '../logging/logger_service.dart';
import '../../../../app/di/service_locator.dart';

/// Implementation of permission service with comprehensive permission handling
class PermissionServiceImpl implements PermissionService {
  final LoggerService _logger;
  final Map<AppPermissionType, int> _permissionAttempts = {};
  final Map<AppPermissionType, DateTime> _lastRequestTime = {};
  final Map<AppPermissionType, AppPermissionStatus> _cachedStatuses = {};
  
  // Cooldown duration between permission requests
  static const int _requestCooldownSeconds = 30;
  
  PermissionServiceImpl({LoggerService? logger})
      : _logger = logger ?? getIt<LoggerService>() {
    _logger.debug(message: 'PermissionServiceImpl initialized');
  }

  @override
  Future<AppPermissionStatus> requestPermission(AppPermissionType permission) async {
    _logger.info(message: 'Requesting permission: ${permission.toString()}');
    
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
        _logger.info(message: 'Permission already granted: $permission');
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
      
      // Handle permanently denied
      if (appStatus == AppPermissionStatus.permanentlyDenied) {
        _logger.warning(message: 'Permission permanently denied: $permission');
      }
      
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
  Future<AppPermissionStatus> checkPermissionStatus(AppPermissionType permission) async {
    _logger.debug(
      message: 'Checking permission status',
      data: {'permission': permission.toString()}
    );
    
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
    
    // Check all permissions in parallel
    final futures = AppPermissionType.values.map((type) async {
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
  Future<void> openAppSettings([AppSettingsType? settingsPage]) async {
    _logger.info(
      message: 'Opening app settings',
      data: {'page': settingsPage?.toString() ?? 'default'}
    );
    
    try {
      switch (settingsPage) {
        case AppSettingsType.location:
          await app_settings.AppSettings.openAppSettings(
            type: app_settings.AppSettingsType.location
          );
          break;
        case AppSettingsType.notification:
          await app_settings.AppSettings.openAppSettings(
            type: app_settings.AppSettingsType.notification
          );
          break;
        case AppSettingsType.battery:
          await app_settings.AppSettings.openAppSettings(
            type: app_settings.AppSettingsType.batteryOptimization
          );
          break;
        case AppSettingsType.app:
        case null:
          await app_settings.AppSettings.openAppSettings();
          break;
      }
      
      // Schedule a recheck after user might return
      Timer(const Duration(seconds: 3), () async {
        await checkAllPermissions();
      });
    } catch (e, s) {
      _logger.error(
        message: 'Error opening app settings',
        error: e,
        stackTrace: s,
      );
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
      
      _logger.debug(
        message: 'Permission rationale check',
        data: {
          'permission': permission.toString(),
          'status': status.toString(),
          'shouldShowRationale': shouldShowRationale,
        }
      );
      
      return shouldShowRationale;
    } catch (e) {
      _logger.warning(
        message: 'Error checking permission rationale',
        data: {'permission': permission.toString(), 'error': e.toString()}
      );
      return false;
    }
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
        await app_settings.AppSettings.openAppSettings(
          type: app_settings.AppSettingsType.notification
        );
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
        await app_settings.AppSettings.openAppSettings(
          type: app_settings.AppSettingsType.batteryOptimization
        );
        
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