// lib/core/infrastructure/services/di/core_module.dart

import 'package:athkar_app/core/infrastructure/services/device/do_not_disturb/do_not_disturb_service.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../../error/error_handler.dart';
import '../device/battery/battery_service.dart';
import '../device/battery/battery_service_impl.dart';
import '../device/do_not_disturb/do_not_disturb_service_impl.dart';
import '../logging/logger_service.dart';
import '../logging/logger_service_impl.dart';
import '../notifications/utils/notification_analytics.dart';
import '../notifications/utils/notification_retry_manager.dart';
import '../notifications/notification_service.dart';
import '../notifications/notification_service_impl.dart';
import '../permissions/permission_manager.dart';
import '../permissions/permission_service.dart';
import '../permissions/permission_service_impl.dart';
import '../storage/storage_service.dart';
import '../storage/storage_service_impl.dart';
import '../timezone/timezone_service.dart';
import '../timezone/timezone_service_impl.dart';
import '../configuration/configuration_service.dart';
import '../configuration/configuration_service_impl.dart';

/// Core module for dependency injection
/// Registers all core services and their implementations
class CoreModule {
  static final GetIt _getIt = GetIt.instance;

  /// Initialize core services
  static Future<void> init() async {
    // Logger - First to initialize as other services depend on it
    _getIt.registerLazySingleton<LoggerService>(
      () => LoggerServiceImpl(),
    );
    
    final logger = _getIt<LoggerService>();
    logger.info(message: 'Initializing Core Module...');

    // Storage - Second priority as many services use it
    final sharedPreferences = await SharedPreferences.getInstance();
    _getIt.registerLazySingleton<StorageService>(
      () => StorageServiceImpl(
        sharedPreferences,
        logger: logger,
      ),
    );
    
    logger.debug(message: 'Storage service registered');

    // Configuration
    _getIt.registerLazySingleton<ConfigurationService>(
      () => ConfigurationServiceImpl(
        storage: _getIt<StorageService>(),
        logger: logger,
      ),
    );
    
    // Load configuration
    await _getIt<ConfigurationService>().loadConfiguration();
    logger.debug(message: 'Configuration service registered and loaded');

    // Timezone
    _getIt.registerLazySingleton<TimezoneService>(
      () => TimezoneServiceImpl(logger: logger),
    );
    
    logger.debug(message: 'Timezone service registered');

    // Permissions
    _getIt.registerLazySingleton<PermissionService>(
      () => PermissionServiceImpl(logger: logger),
    );

    _getIt.registerLazySingleton<PermissionManager>(
      () => PermissionManager(
        _getIt<PermissionService>(),
        logger: logger,
      ),
    );
    
    logger.debug(message: 'Permission services registered');

    // Device services
    _getIt.registerLazySingleton<Battery>(
      () => Battery(),
    );
    
    _getIt.registerLazySingleton<BatteryService>(
      () => BatteryServiceImpl(
        battery: _getIt<Battery>(),
        logger: logger,
        storage: _getIt<StorageService>(),
      ),
    );

    _getIt.registerLazySingleton<DoNotDisturbService>(
      () => DoNotDisturbServiceImpl(
        logger: logger,
        permissionService: _getIt<PermissionService>(),
      ),
    );
    
    logger.debug(message: 'Device services registered');

    // Notification services
    _getIt.registerLazySingleton<NotificationAnalytics>(
      () => NotificationAnalytics(logger: logger),
    );

    _getIt.registerLazySingleton<NotificationRetryManager>(
      () => NotificationRetryManager(
        storage: _getIt<StorageService>(),
        logger: logger,
      ),
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
        storageService: _getIt<StorageService>(),
        logger: logger,
        analytics: _getIt<NotificationAnalytics>(),
        retryManager: _getIt<NotificationRetryManager>(),
      ),
    );
    
    logger.debug(message: 'Notification services registered');

    // Error handler
    _getIt.registerLazySingleton<AppErrorHandler>(
      () => AppErrorHandler(logger),
    );
    
    logger.debug(message: 'Error handler registered');

    // Initialize services that need it
    try {
      // Initialize timezone service
      await _getIt<TimezoneService>().initializeTimeZones();
      logger.info(message: 'Timezone service initialized');
      
      // Initialize notification service
      final config = _getIt<ConfigurationService>();
      await _getIt<NotificationService>().initialize(
        defaultIcon: config.getString('notification.default_icon'),
      );
      logger.info(message: 'Notification service initialized');
      
    } catch (e, s) {
      logger.error(
        message: 'Error initializing services',
        error: e,
        stackTrace: s,
      );
      // Don't rethrow - allow app to continue with degraded functionality
    }
    
    logger.info(message: 'Core Module initialized successfully');
logger.logEvent('core_module_initialized', parameters: {
  'services_count': _getIt.registrations.length,
    });
  }

  /// Dispose all services
  static Future<void> dispose() async {
    final logger = _getIt<LoggerService>();
    logger.info(message: 'Disposing Core Module...');
    
    try {
      // Dispose services that need cleanup
      if (_getIt.isRegistered<NotificationService>()) {
        await _getIt<NotificationService>().dispose();
        logger.debug(message: 'NotificationService disposed');
      }
      
      if (_getIt.isRegistered<BatteryService>()) {
        await _getIt<BatteryService>().dispose();
        logger.debug(message: 'BatteryService disposed');
      }
      
      if (_getIt.isRegistered<DoNotDisturbService>()) {
        final dndService = _getIt<DoNotDisturbService>() as DoNotDisturbServiceImpl;
        await dndService.dispose();
        logger.debug(message: 'DoNotDisturbService disposed');
      }
      
      if (_getIt.isRegistered<NotificationAnalytics>()) {
        _getIt<NotificationAnalytics>().dispose();
        logger.debug(message: 'NotificationAnalytics disposed');
      }
      
      if (_getIt.isRegistered<NotificationRetryManager>()) {
        await _getIt<NotificationRetryManager>().dispose();
        logger.debug(message: 'NotificationRetryManager disposed');
      }
      
      if (_getIt.isRegistered<PermissionService>()) {
        final permissionService = _getIt<PermissionService>() as PermissionServiceImpl;
        permissionService.dispose();
        logger.debug(message: 'PermissionService disposed');
      }
      
      logger.info(message: 'Core Module disposed successfully');
      
    } catch (e, s) {
      logger.error(
        message: 'Error disposing Core Module',
        error: e,
        stackTrace: s,
      );
    }
  }
  
  /// Reset all services (useful for testing)
  static Future<void> reset() async {
    await dispose();
    _getIt.reset();
    await init();
  }
  
  /// Check if a service is registered
  static bool isRegistered<T extends Object>() {
    return _getIt.isRegistered<T>();
  }
  
  /// Get service instance
  static T get<T extends Object>() {
    return _getIt<T>();
  }
  
  /// Get service instance if registered
  static T? getIfRegistered<T extends Object>() {
    return _getIt.isRegistered<T>() ? _getIt<T>() : null;
  }
  
  /// Register factory (for testing purposes)
  static void registerFactory<T extends Object>(
    T Function() factory,
  ) {
    if (_getIt.isRegistered<T>()) {
      _getIt.unregister<T>();
    }
    _getIt.registerFactory<T>(factory);
  }
  
  /// Register singleton (for testing purposes)
  static void registerSingleton<T extends Object>(T instance) {
    if (_getIt.isRegistered<T>()) {
      _getIt.unregister<T>();
    }
    _getIt.registerSingleton<T>(instance);
  }
  
  /// Get all registered types
  static List<Type> getRegisteredTypes() {
    return _getIt.getRegisteredTypes();
  }
}