// lib/core/services/implementations/do_not_disturb_service_impl.dart
import 'dart:async';
import 'dart:io'; // Platform is used from dart:io
import 'package:app_settings/app_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'; // For debugPrint, consider a dedicated logger service
import 'do_not_disturb_service.dart';

class DoNotDisturbServiceImpl implements DoNotDisturbService {
  static const MethodChannel _channel = MethodChannel('com.athkar.app/do_not_disturb');
  StreamSubscription<dynamic>? _subscription;
  Function(bool)? _onDoNotDisturbChangeCallback; // Renamed for clarity
  bool _currentDoNotDisturbState = false; // Renamed for clarity

  @override
  Future<bool> isDoNotDisturbEnabled() async {
    try {
      if (Platform.isAndroid) {
        final bool? isDndEnabled = await _channel.invokeMethod<bool>('isDoNotDisturbEnabled');
        _currentDoNotDisturbState = isDndEnabled ?? false;
        return _currentDoNotDisturbState;
      } else if (Platform.isIOS) {
        // On iOS, direct DND access is not possible.
        // Alternative: check if notifications are generally permitted.
        // This is an approximation and might not reflect the actual DND/Focus mode.
        final bool? canSendNotifications = await _channel.invokeMethod<bool>('canSendNotifications');
        _currentDoNotDisturbState = !(canSendNotifications ?? true); // If can't send, assume DND-like mode
        return _currentDoNotDisturbState;
      }
      return false; // Default for unsupported platforms
    } on PlatformException catch (e) {
      debugPrint('Error checking DND status: ${e.message}');
      return false; // Return a consistent value on error
    }
  }

  @override
  Future<bool> requestDoNotDisturbPermission() async {
    try {
      if (Platform.isAndroid) {
        // Android requires specific permission to read DND state.
        final bool? granted = await _channel.invokeMethod<bool>('requestDoNotDisturbPermission');
        return granted ?? false;
      } else {
        // iOS does not have a direct DND permission concept for apps to request this way.
        // Focus modes are managed by the user.
        return true; // Assume "granted" as no specific permission is needed or can be requested.
      }
    } on PlatformException catch (e) {
      debugPrint('Error requesting DND permission: ${e.message}');
      return false;
    }
  }

  @override
  Future<void> openDoNotDisturbSettings() async {
    try {
      bool openedSuccessfully = false;
      if (Platform.isAndroid) {
        // Try to open specific DND settings via method channel first
        final bool? openedViaChannel = await _channel.invokeMethod<bool>('openDoNotDisturbSettings');
        openedSuccessfully = openedViaChannel ?? false;
        
        if (!openedSuccessfully) {
          // Fallback to general notification settings if specific DND settings failed
          await AppSettings.openAppSettings(type: AppSettingsType.notification);
          openedSuccessfully = true; // Assume AppSettings call works or has its own error handling
        }
      } else if (Platform.isIOS) {
        // On iOS, open general app settings, user navigates to Focus/Notifications
        await AppSettings.openAppSettings();
        openedSuccessfully = true;
      }
      
      // After attempting to open settings, re-check the DND state after a short delay
      // to allow the user to make changes and return to the app.
      if (openedSuccessfully) {
        await Future.delayed(const Duration(seconds: 2)); // Increased delay
        final bool newDndState = await isDoNotDisturbEnabled();
        if (_onDoNotDisturbChangeCallback != null && newDndState != _currentDoNotDisturbState) {
           _currentDoNotDisturbState = newDndState;
          _onDoNotDisturbChangeCallback!(_currentDoNotDisturbState);
        }
      }
    } catch (e) {
      debugPrint('Error opening DND settings: $e');
      // As a final fallback, attempt to open general app settings
      await AppSettings.openAppSettings();
    }
  }

  @override
  Future<void> registerDoNotDisturbListener(Function(bool p1) onDoNotDisturbChange) async {
    _onDoNotDisturbChangeCallback = onDoNotDisturbChange;

    // Cancel any existing subscription
    await _subscription?.cancel();
    _subscription = null;

    if (Platform.isAndroid) {
      _subscription = const EventChannel('com.athkar.app/do_not_disturb_events')
          .receiveBroadcastStream()
          .listen((dynamic event) {
        if (event is bool) {
          _currentDoNotDisturbState = event;
          _onDoNotDisturbChangeCallback?.call(event);
        }
      }, onError: (Object error) {
        debugPrint('Error in Android DND listener: $error');
      });
    } else if (Platform.isIOS) {
      // iOS DND listening is more complex.
      // An EventChannel 'com.athkar.app/notification_settings_events' is mentioned.
      // This likely observes UIApplication.willEnterForegroundNotification or similar
      // and re-checks notification permissions as a proxy for DND/Focus changes.
      _subscription = const EventChannel('com.athkar.app/notification_settings_events')
          .receiveBroadcastStream()
          .listen((dynamic event) {
        // Assuming the event directly provides the approximated DND state for iOS
        if (event is bool) {
          _currentDoNotDisturbState = event;
         _onDoNotDisturbChangeCallback?.call(event);
        }
      }, onError: (Object error) {
        debugPrint('Error in iOS DND (Notification Settings) listener: $error');
      });
    }

    // Fetch and report initial state
    final initialStatus = await isDoNotDisturbEnabled();
    if (_currentDoNotDisturbState != initialStatus) {
      _currentDoNotDisturbState = initialStatus;
       _onDoNotDisturbChangeCallback?.call(_currentDoNotDisturbState);
    }
  }
  
  @override
  Future<void> unregisterDoNotDisturbListener() async {
    await _subscription?.cancel();
    _subscription = null;
    _onDoNotDisturbChangeCallback = null; // Clear the callback
  }

  @override
  Future<bool> shouldOverrideDoNotDisturb(DoNotDisturbOverrideType type) async {
    if (!_currentDoNotDisturbState) {
      return true; // DND is off, no need to override
    }

    // DND is on, check override rules
    switch (type) {
      case DoNotDisturbOverrideType.none:
        return false;
      case DoNotDisturbOverrideType.prayer:
      case DoNotDisturbOverrideType.importantAthkar:
      case DoNotDisturbOverrideType.critical:
        return true; // These types should override DND
      // No default needed if all enum values are covered
      // The lint 'unreachable_switch_default' implies all are covered.
    }
    // If the enum could have more values in the future and no 'default' is present,
    // this would be a compile error (exhaustive switch).
    // If the linter was correct, this point should not be reached for defined enum values.
    // However, to be absolutely safe if the enum definition changes without updating the switch:
    // return false; // Or throw an exception for unhandled override type.
  }
}