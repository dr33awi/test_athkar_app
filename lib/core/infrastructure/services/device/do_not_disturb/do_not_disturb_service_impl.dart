// lib/core/infrastructure/services/device/do_not_disturb/do_not_disturb_service_impl.dart
import 'dart:async';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/services.dart';
import 'do_not_disturb_service.dart';
import '../../logging/logger_service.dart';

class DoNotDisturbServiceImpl implements DoNotDisturbService {
  static const MethodChannel _channel = MethodChannel('com.athkar.app/do_not_disturb');
  
  final LoggerService _logger;
  StreamSubscription<dynamic>? _subscription;
  Function(bool)? _onDoNotDisturbChangeCallback;
  
  // State tracking
  bool _currentDoNotDisturbState = false;
  DateTime? _lastCheckTime;
  static const Duration _cacheValidity = Duration(seconds: 30);
  
  // Platform availability cache
  static bool? _platformSupported;

  DoNotDisturbServiceImpl({
    required LoggerService logger,
  }) : _logger = logger {
    _checkPlatformSupport();
  }

  Future<void> _checkPlatformSupport() async {
    if (_platformSupported != null) return;
    
    try {
      if (Platform.isAndroid) {
        // Check Android API level
        final Map<String, dynamic>? deviceInfo = await _channel.invokeMethod('getDeviceInfo');
        final int sdkInt = deviceInfo?['sdkInt'] ?? 0;
        _platformSupported = sdkInt >= 23; // Android M+
      } else if (Platform.isIOS) {
        _platformSupported = true; // iOS always supported, but with limitations
      } else {
        _platformSupported = false;
      }
      
      _logger.info(
        message: 'DND platform support checked',
        data: {'supported': _platformSupported, 'platform': Platform.operatingSystem},
      );
    } catch (e) {
      _logger.warning(
        message: 'Could not determine DND platform support',
        data: {'error': e.toString()},
      );
      _platformSupported = false;
    }
  }

  bool _shouldUseCache() {
    if (_lastCheckTime == null) return false;
    return DateTime.now().difference(_lastCheckTime!) < _cacheValidity;
  }

  @override
  Future<bool> isDoNotDisturbEnabled() async {
    if (_shouldUseCache()) {
      return _currentDoNotDisturbState;
    }

    if (_platformSupported == false) {
      _logger.debug(message: 'DND check skipped - platform not supported');
      return false;
    }

    try {
      if (Platform.isAndroid) {
        final bool? isDndEnabled = await _channel.invokeMethod<bool>('isDoNotDisturbEnabled');
        _currentDoNotDisturbState = isDndEnabled ?? false;
        _lastCheckTime = DateTime.now();
        
        _logger.debug(
          message: 'Android DND status checked',
          data: {'enabled': _currentDoNotDisturbState},
        );
        
        return _currentDoNotDisturbState;
      } else if (Platform.isIOS) {
        // iOS: Check notification permissions as proxy
        final bool? canSendNotifications = await _channel.invokeMethod<bool>('canSendNotifications');
        _currentDoNotDisturbState = !(canSendNotifications ?? true);
        _lastCheckTime = DateTime.now();
        
        _logger.debug(
          message: 'iOS notification status checked (DND proxy)',
          data: {'canSend': canSendNotifications, 'dndEstimate': _currentDoNotDisturbState},
        );
        
        return _currentDoNotDisturbState;
      }
      
      return false;
    } on PlatformException catch (e) {
      _logger.error(
        message: 'Platform error checking DND status',
        error: e,
      );
      return false;
    } catch (e, s) {
      _logger.error(
        message: 'Unexpected error checking DND status',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  @override
  Future<bool> requestDoNotDisturbPermission() async {
    if (_platformSupported == false) {
      _logger.info(message: 'DND permission request skipped - platform not supported');
      return false;
    }

    try {
      if (Platform.isAndroid) {
        final bool? granted = await _channel.invokeMethod<bool>('requestDoNotDisturbPermission');
        
        _logger.info(
          message: 'DND permission request result',
          data: {'granted': granted},
        );
        
        return granted ?? false;
      } else {
        // iOS: No direct DND permission
        _logger.info(message: 'iOS has no direct DND permission API');
        return true;
      }
    } on PlatformException catch (e) {
      _logger.error(
        message: 'Platform error requesting DND permission',
        error: e,
      );
      return false;
    } catch (e, s) {
      _logger.error(
        message: 'Unexpected error requesting DND permission',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  @override
  Future<void> openDoNotDisturbSettings() async {
    try {
      bool openedSuccessfully = false;
      
      if (Platform.isAndroid) {
        // Try platform-specific method first
        try {
          final bool? opened = await _channel.invokeMethod<bool>('openDoNotDisturbSettings');
          openedSuccessfully = opened ?? false;
        } catch (e) {
          _logger.debug(
            message: 'Platform channel failed to open DND settings',
            data: {'error': e.toString()},
          );
        }
        
        // Fallback to app_settings
        if (!openedSuccessfully) {
          await AppSettings.openAppSettings(type: AppSettingsType.notification);
          openedSuccessfully = true;
        }
      } else if (Platform.isIOS) {
        // iOS: Open general settings
        await AppSettings.openAppSettings();
        openedSuccessfully = true;
      }
      
      if (openedSuccessfully) {
        _logger.info(message: 'DND settings opened successfully');
        
        // Schedule a recheck after user might return
        Timer(const Duration(seconds: 3), () async {
          final newState = await isDoNotDisturbEnabled();
          if (newState != _currentDoNotDisturbState) {
            _currentDoNotDisturbState = newState;
            _onDoNotDisturbChangeCallback?.call(newState);
          }
        });
      }
    } catch (e, s) {
      _logger.error(
        message: 'Error opening DND settings',
        error: e,
        stackTrace: s,
      );
      
      // Last resort fallback
      try {
        await AppSettings.openAppSettings();
      } catch (e2) {
        _logger.error(
          message: 'Failed to open any settings',
          error: e2,
        );
      }
    }
  }

  @override
  Future<void> registerDoNotDisturbListener(Function(bool) onDoNotDisturbChange) async {
    _onDoNotDisturbChangeCallback = onDoNotDisturbChange;

    // Cancel existing subscription
    await _subscription?.cancel();
    _subscription = null;

    if (_platformSupported == false) {
      _logger.info(message: 'DND listener registration skipped - platform not supported');
      return;
    }

    try {
      if (Platform.isAndroid) {
        _subscription = const EventChannel('com.athkar.app/do_not_disturb_events')
            .receiveBroadcastStream()
            .listen(
              (dynamic event) {
                if (event is bool) {
                  _handleDoNotDisturbChange(event);
                }
              },
              onError: (Object error) {
                _logger.error(
                  message: 'Error in Android DND listener',
                  error: error,
                );
              },
              cancelOnError: false,
            );
      } else if (Platform.isIOS) {
        _subscription = const EventChannel('com.athkar.app/notification_settings_events')
            .receiveBroadcastStream()
            .listen(
              (dynamic event) {
                if (event is bool) {
                  _handleDoNotDisturbChange(event);
                }
              },
              onError: (Object error) {
                _logger.error(
                  message: 'Error in iOS notification settings listener',
                  error: error,
                );
              },
              cancelOnError: false,
            );
      }

      // Report initial state
      final initialStatus = await isDoNotDisturbEnabled();
      if (_currentDoNotDisturbState != initialStatus) {
        _handleDoNotDisturbChange(initialStatus);
      }
      
      _logger.info(message: 'DND listener registered successfully');
    } catch (e, s) {
      _logger.error(
        message: 'Error registering DND listener',
        error: e,
        stackTrace: s,
      );
    }
  }

  void _handleDoNotDisturbChange(bool newState) {
    if (_currentDoNotDisturbState != newState) {
      _currentDoNotDisturbState = newState;
      _lastCheckTime = DateTime.now();
      _onDoNotDisturbChangeCallback?.call(newState);
      
      _logger.info(
        message: 'DND state changed',
        data: {'newState': newState},
      );
    }
  }

  @override
  Future<void> unregisterDoNotDisturbListener() async {
    await _subscription?.cancel();
    _subscription = null;
    _onDoNotDisturbChangeCallback = null;
    _logger.debug(message: 'DND listener unregistered');
  }

  @override
  Future<bool> shouldOverrideDoNotDisturb(DoNotDisturbOverrideType type) async {
    if (!_currentDoNotDisturbState) {
      return true; // DND is off, no need to override
    }

    final shouldOverride = type != DoNotDisturbOverrideType.none;
    
    _logger.debug(
      message: 'DND override check',
      data: {
        'dndEnabled': _currentDoNotDisturbState,
        'overrideType': type.toString(),
        'shouldOverride': shouldOverride,
      },
    );

    return shouldOverride;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await unregisterDoNotDisturbListener();
    _lastCheckTime = null;
    _logger.debug(message: 'DoNotDisturbServiceImpl disposed');
  }
}