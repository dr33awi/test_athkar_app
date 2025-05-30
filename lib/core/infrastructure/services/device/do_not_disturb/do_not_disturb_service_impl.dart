// lib/core/infrastructure/services/device/do_not_disturb/do_not_disturb_service_impl.dart

import 'dart:async';
import 'dart:io';
import 'package:athkar_app/core/infrastructure/services/device/do_not_disturb/do_not_disturb_service.dart';
import 'package:flutter/services.dart';
import '../../logging/logger_service.dart';
import '../../permissions/permission_service.dart';
import '../../../../../app/di/service_locator.dart';

/// Implementation of Do Not Disturb service
class DoNotDisturbServiceImpl implements DoNotDisturbService {
  final LoggerService _logger;
  final PermissionService _permissionService;
  
  static const String _channelName = 'com.athkar.app/dnd';
  static const MethodChannel _channel = MethodChannel(_channelName);
  
  DoNotDisturbOverrideHandler? _overrideHandler;
  Function(bool)? _dndChangeListener;
  Timer? _dndPollingTimer;
  bool? _lastKnownDndState;
  
  DoNotDisturbServiceImpl({
    LoggerService? logger,
    PermissionService? permissionService,
  })  : _logger = logger ?? getIt<LoggerService>(),
        _permissionService = permissionService ?? getIt<PermissionService>() {
    _initialize();
  }
  
  void _initialize() {
    _logger.debug(message: 'DoNotDisturbServiceImpl initialized');
    
    // Set up method channel for platform-specific implementation
    _setupMethodChannel();
  }
  
  void _setupMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDndStateChanged':
          final isEnabled = call.arguments as bool;
          _handleDndStateChange(isEnabled);
          break;
        default:
          _logger.warning(
            message: 'Unknown method call',
            data: {'method': call.method},
          );
      }
    });
  }
  
  void _handleDndStateChange(bool isEnabled) {
    _logger.debug(
      message: 'DND state changed',
      data: {'enabled': isEnabled},
    );
    
    _lastKnownDndState = isEnabled;
    _dndChangeListener?.call(isEnabled);
    
_logger.logEvent('dnd_state_changed', parameters: {'enabled': isEnabled});
  }
  
  @override
  Future<bool> isDoNotDisturbEnabled() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }
    
    try {
      // Try platform-specific check first
      if (Platform.isAndroid) {
        final hasPermission = await _permissionService.checkPermissionStatus(
          AppPermissionType.doNotDisturb
        ) == AppPermissionStatus.granted;
        
        if (hasPermission) {
          final isEnabled = await _channel.invokeMethod<bool>('isDndEnabled') ?? false;
          _lastKnownDndState = isEnabled;
          
          _logger.debug(
            message: 'DND status checked',
            data: {'enabled': isEnabled},
          );
          
          return isEnabled;
        }
      } else if (Platform.isIOS) {
        // iOS doesn't provide direct DND access
        // We can only check if critical alerts are allowed
        return false;
      }
      
      return false;
    } catch (e) {
      _logger.error(
        message: 'Error checking DND status',
        error: e,
      );
      return _lastKnownDndState ?? false;
    }
  }
  
  @override
  Future<bool> requestDoNotDisturbPermission() async {
    _logger.info(message: 'Requesting DND permission');
    
    if (!Platform.isAndroid) {
      _logger.info(message: 'DND permission only available on Android');
      return false;
    }
    
    try {
      final status = await _permissionService.requestPermission(
        AppPermissionType.doNotDisturb
      );
      
      final isGranted = status == AppPermissionStatus.granted;
      
      _logger.info(
        message: 'DND permission request result',
        data: {'granted': isGranted},
      );
      
_logger.logEvent('dnd_permission_requested', parameters: {'granted': isGranted});
      
      return isGranted;
    } catch (e) {
      _logger.error(
        message: 'Error requesting DND permission',
        error: e,
      );
      return false;
    }
  }
  
  @override
  Future<void> openDoNotDisturbSettings() async {
    _logger.info(message: 'Opening DND settings');
    
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('openDndSettings');
      } else {
        // Open general notification settings for iOS
        await _permissionService.openAppSettings(AppSettingsType.notification);
      }
      
      _logger.logEvent('dnd_settings_opened');
    } catch (e) {
      _logger.error(
        message: 'Error opening DND settings',
        error: e,
      );
      
      // Fallback to general settings
      await _permissionService.openAppSettings(AppSettingsType.notification);
    }
  }
  
  @override
  Future<void> registerDoNotDisturbListener(Function(bool) onDoNotDisturbChange) async {
    _logger.debug(message: 'Registering DND listener');
    
    _dndChangeListener = onDoNotDisturbChange;
    
    // Start polling for DND state changes (every 30 seconds)
    _dndPollingTimer?.cancel();
    _dndPollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final currentState = await isDoNotDisturbEnabled();
      if (currentState != _lastKnownDndState) {
        _handleDndStateChange(currentState);
      }
    });
    
    // Get initial state
    final initialState = await isDoNotDisturbEnabled();
    _handleDndStateChange(initialState);
  }
  
  @override
  Future<void> unregisterDoNotDisturbListener() async {
    _logger.debug(message: 'Unregistering DND listener');
    
    _dndChangeListener = null;
    _dndPollingTimer?.cancel();
    _dndPollingTimer = null;
  }
  
  @override
  Future<bool> shouldOverrideDoNotDisturb(SystemOverridePriority priority) async {
    // Check custom handler first
    if (_overrideHandler != null) {
      return await _overrideHandler!.shouldOverride({
        'priority': priority.toString(),
      });
    }
    
    // Default behavior based on priority
    switch (priority) {
      case SystemOverridePriority.critical:
        return true; // Always override for critical
      case SystemOverridePriority.high:
        return true; // Override for high priority
      case SystemOverridePriority.medium:
        // Check if user has allowed medium priority overrides
        return await _checkMediumPriorityOverride();
      case SystemOverridePriority.low:
      case SystemOverridePriority.none:
        return false; // Don't override for low/none
    }
  }
  
  Future<bool> _checkMediumPriorityOverride() async {
    // This could be a user preference
    // For now, default to not overriding
    return false;
  }
  
  @override
  Future<Map<String, dynamic>> getDoNotDisturbPolicy() async {
    try {
      if (Platform.isAndroid) {
        final policy = await _channel.invokeMethod<Map>('getDndPolicy');
        return Map<String, dynamic>.from(policy ?? {});
      }
      
      return {
        'available': false,
        'platform': Platform.operatingSystem,
      };
    } catch (e) {
      _logger.error(
        message: 'Error getting DND policy',
        error: e,
      );
      return {};
    }
  }
  
  @override
  void setOverrideHandler(DoNotDisturbOverrideHandler? handler) {
    _logger.debug(
      message: 'Setting DND override handler',
      data: {'hasHandler': handler != null},
    );
    _overrideHandler = handler;
  }
  
  @override
  Future<bool> canShowCriticalAlerts() async {
    if (Platform.isIOS) {
      // Check if critical alerts permission is granted
      final status = await _permissionService.checkPermissionStatus(
        AppPermissionType.criticalAlerts
      );
      return status == AppPermissionStatus.granted;
    } else if (Platform.isAndroid) {
      // Android always allows critical notifications with proper channel
      return true;
    }
    
    return false;
  }
  
  @override
  Future<DoNotDisturbSchedule?> getDoNotDisturbSchedule() async {
    try {
      if (!Platform.isAndroid) {
        return null;
      }
      
      final scheduleData = await _channel.invokeMethod<Map>('getDndSchedule');
      if (scheduleData == null) {
        return null;
      }
      
      return DoNotDisturbSchedule(
        isEnabled: scheduleData['enabled'] as bool? ?? false,
        startTime: _parseTimeOfDay(scheduleData['startTime']),
        endTime: _parseTimeOfDay(scheduleData['endTime']),
        activeDays: (scheduleData['activeDays'] as List?)?.cast<int>(),
      );
    } catch (e) {
      _logger.error(
        message: 'Error getting DND schedule',
        error: e,
      );
      return null;
    }
  }
  
  TimeOfDay? _parseTimeOfDay(dynamic data) {
    if (data == null) return null;
    
    if (data is Map) {
      return TimeOfDay(
        hour: data['hour'] as int? ?? 0,
        minute: data['minute'] as int? ?? 0,
      );
    }
    
    return null;
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    _logger.debug(message: 'Disposing DoNotDisturbServiceImpl');
    
    await unregisterDoNotDisturbListener();
    _overrideHandler = null;
    _lastKnownDndState = null;
  }
}
