// lib/core/di/core_module.dart
import 'package:athkar_app/core/error/error_handler.dart';
import 'package:athkar_app/core/infrastructure/services/device/battery/battery_service.dart';
import 'package:athkar_app/core/infrastructure/services/device/battery/battery_service_impl.dart';
import 'package:athkar_app/core/infrastructure/services/device/do_not_disturb/do_not_disturb_service.dart';
import 'package:athkar_app/core/infrastructure/services/device/do_not_disturb/do_not_disturb_service_impl.dart';
import 'package:athkar_app/core/infrastructure/services/logging/logger_service.dart';
import 'package:athkar_app/core/infrastructure/services/logging/logger_service_impl.dart';
import 'package:athkar_app/core/infrastructure/services/notifications/notification_analytics.dart';
import 'package:athkar_app/core/infrastructure/services/notifications/notification_retry_manager.dart';
import 'package:athkar_app/core/infrastructure/services/notifications/notification_service.dart';
import 'package:athkar_app/core/infrastructure/services/notifications/notification_service_impl.dart';
import 'package:athkar_app/core/infrastructure/services/permissions/permission_manager.dart';
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service.dart';
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service_impl.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service_impl.dart';
import 'package:athkar_app/core/infrastructure/services/timezone/timezone_service.dart';
import 'package:athkar_app/core/infrastructure/services/timezone/timezone_service_impl.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Core module for dependency injection
class CoreModule {
  static final GetIt _getIt = GetIt.instance;

  /// Initialize core services
  static Future<void> init() async {
    // Logger - First to initialize
    _getIt.registerLazySingleton<LoggerService>(
      () => LoggerServiceImpl(),
    );

    // Storage
    final sharedPreferences = await SharedPreferences.getInstance();
    _getIt.registerLazySingleton<StorageService>(
      () => StorageServiceImpl(sharedPreferences),
    );

    // Timezone
    _getIt.registerLazySingleton<TimezoneService>(
      () => TimezoneServiceImpl(logger: _getIt<LoggerService>()),
    );

    // Permissions
    _getIt.registerLazySingleton<PermissionService>(
      () => PermissionServiceImpl(logger: _getIt<LoggerService>()),
    );

    _getIt.registerLazySingleton<PermissionManager>(
      () => PermissionManager(_getIt<PermissionService>()),
    );

    // Device services
    _getIt.registerLazySingleton<BatteryService>(
      () => BatteryServiceImpl(logger: _getIt<LoggerService>()),
    );

    _getIt.registerLazySingleton<DoNotDisturbService>(
      () => DoNotDisturbServiceImpl(logger: _getIt<LoggerService>()),
    );

    // Notification services
    _getIt.registerLazySingleton<NotificationAnalytics>(
      () => NotificationAnalytics(),
    );

    _getIt.registerLazySingleton<NotificationRetryManager>(
      () => NotificationRetryManager(storage: _getIt<StorageService>()),
    );

    _getIt.registerLazySingleton<FlutterLocalNotificationsPlugin>(
      () => FlutterLocalNotificationsPlugin(),
    );

    _getIt.registerLazySingleton<NotificationService>(
      () => NotificationServiceImpl(
        _getIt<FlutterLocalNotificationsPlugin>(),
        _getIt<BatteryService>(),
        _getIt<DoNotDisturbService>(),
        _getIt<TimezoneService>(),
        logger: _getIt<LoggerService>(),
        analytics: _getIt<NotificationAnalytics>(),
        retryManager: _getIt<NotificationRetryManager>(),
      ),
    );

    // Error handler
    _getIt.registerLazySingleton<AppErrorHandler>(
      () => AppErrorHandler(_getIt<LoggerService>()),
    );

    // Initialize timezone service
    await _getIt<TimezoneService>().initializeTimeZones();
    
    // Initialize notification service
    await _getIt<NotificationService>().initialize();
  }

  /// Dispose all services
  static Future<void> dispose() async {
    // Dispose services that need cleanup
    if (_getIt.isRegistered<NotificationService>()) {
      await _getIt<NotificationService>().dispose();
    }
    
    if (_getIt.isRegistered<BatteryService>()) {
      await _getIt<BatteryService>().dispose();
    }
    
    if (_getIt.isRegistered<DoNotDisturbService>()) {
      final dndService = _getIt<DoNotDisturbService>() as DoNotDisturbServiceImpl;
      await dndService.dispose();
    }
    
    if (_getIt.isRegistered<NotificationAnalytics>()) {
      _getIt<NotificationAnalytics>().dispose();
    }
    
    if (_getIt.isRegistered<NotificationRetryManager>()) {
      await _getIt<NotificationRetryManager>().dispose();
    }
  }
}