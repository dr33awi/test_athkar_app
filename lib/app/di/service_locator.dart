// lib/app/di/service_locator.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_plus/battery_plus.dart';

// Core Services
import '../../core/infrastructure/services/logging/logger_service.dart';
import '../../core/infrastructure/services/logging/logger_service_impl.dart';
import '../../core/infrastructure/services/storage/storage_service.dart';
import '../../core/infrastructure/services/storage/storage_service_impl.dart';
import '../../core/infrastructure/services/timezone/timezone_service.dart';
import '../../core/infrastructure/services/timezone/timezone_service_impl.dart';
import '../../core/infrastructure/services/configuration/configuration_service.dart';
import '../../core/infrastructure/services/configuration/configuration_service_impl.dart';
import '../../core/infrastructure/services/permissions/permission_service.dart';
import '../../core/infrastructure/services/permissions/permission_service_impl.dart';
import '../../core/infrastructure/services/permissions/permission_manager.dart';
import '../../core/infrastructure/services/device/battery/battery_service.dart';
import '../../core/infrastructure/services/device/battery/battery_service_impl.dart';
import '../../core/infrastructure/services/device/do_not_disturb/do_not_disturb_service.dart';
import '../../core/infrastructure/services/device/do_not_disturb/do_not_disturb_service_impl.dart';
import '../../core/infrastructure/services/notifications/notification_service.dart';
import '../../core/infrastructure/services/notifications/notification_service_impl.dart';
import '../../core/infrastructure/services/notifications/utils/notification_analytics.dart';
import '../../core/infrastructure/services/notifications/utils/notification_retry_manager.dart';
import '../../core/error/error_handler.dart';

final getIt = GetIt.instance;

/// Service Locator for dependency injection
/// Manages all service registrations and lifecycle
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  bool _basicServicesInitialized = false;
  bool _fullInitialized = false;
  
  LoggerService? _logger;

  /// Initialize basic services required for app startup
  Future<void> initBasicServices() async {
    if (_basicServicesInitialized) return;

    try {
      // Logger - First to initialize
      getIt.registerLazySingleton<LoggerService>(
        () => LoggerServiceImpl(),
      );
      _logger = getIt<LoggerService>();
      _logger!.info(message: 'Initializing basic services...');

      // External dependencies
      final sharedPreferences = await SharedPreferences.getInstance();
      getIt.registerSingleton<SharedPreferences>(sharedPreferences);
      
      // Core Services
      getIt.registerLazySingleton<StorageService>(
        () => StorageServiceImpl(
          sharedPreferences,
          logger: _logger,
        ),
      );
      
      getIt.registerLazySingleton<ConfigurationService>(
        () => ConfigurationServiceImpl(
          storage: getIt<StorageService>(),
          logger: _logger!,
        ),
      );
      
      // Load configuration
      await getIt<ConfigurationService>().loadConfiguration();

      _basicServicesInitialized = true;
      _logger!.info(message: 'Basic services initialized successfully');
      
    } catch (e, s) {
      debugPrint('Error initializing basic services: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// Initialize remaining services in background
  Future<void> initRemainingServices() async {
    if (_fullInitialized) return;
    if (!_basicServicesInitialized) await initBasicServices();

    try {
      _logger?.info(message: 'Initializing remaining services...');

      // Timezone Service
      getIt.registerLazySingleton<TimezoneService>(
        () => TimezoneServiceImpl(logger: _logger!),
      );
      await getIt<TimezoneService>().initializeTimeZones();
      
      // Permission Services
      getIt.registerLazySingleton<PermissionService>(
        () => PermissionServiceImpl(logger: _logger),
      );
      
      getIt.registerLazySingleton<PermissionManager>(
        () => PermissionManager(
          getIt<PermissionService>(),
          logger: _logger,
        ),
      );
      
      // Device Services
      getIt.registerLazySingleton<Battery>(
        () => Battery(),
      );
      
      getIt.registerLazySingleton<BatteryService>(
        () => BatteryServiceImpl(
          battery: getIt<Battery>(),
          logger: _logger,
          storage: getIt<StorageService>(),
        ),
      );
      
      getIt.registerLazySingleton<DoNotDisturbService>(
        () => DoNotDisturbServiceImpl(
          logger: _logger,
          permissionService: getIt<PermissionService>(),
        ),
      );
      
      // Notification Services
      getIt.registerLazySingleton<FlutterLocalNotificationsPlugin>(
        () => FlutterLocalNotificationsPlugin(),
      );
      
      getIt.registerLazySingleton<NotificationAnalytics>(
        () => NotificationAnalytics(logger: _logger),
      );
      
      getIt.registerLazySingleton<NotificationRetryManager>(
        () => NotificationRetryManager(
          storage: getIt<StorageService>(),
          logger: _logger,
        ),
      );
      
      getIt.registerLazySingleton<NotificationService>(
        () => NotificationServiceImpl(
          getIt<FlutterLocalNotificationsPlugin>(),
          getIt<BatteryService>(),
          getIt<DoNotDisturbService>(),
          getIt<TimezoneService>(),
          storageService: getIt<StorageService>(),
          logger: _logger,
          analytics: getIt<NotificationAnalytics>(),
          retryManager: getIt<NotificationRetryManager>(),
        ),
      );
      
      // Initialize notification service
      final config = getIt<ConfigurationService>();
      await getIt<NotificationService>().initialize(
        defaultIcon: config.getString('notification.default_icon'),
      );
      
      // Error Handler
      getIt.registerLazySingleton<AppErrorHandler>(
        () => AppErrorHandler(_logger!),
      );

      _fullInitialized = true;
      _logger?.info(message: 'All services initialized successfully');
      
      _logger?.logEvent('app_services_initialized', parameters: {
        'services_count': getIt.registrations.length,
      });
      
    } catch (e, s) {
      _logger?.error(
        message: 'Error initializing remaining services',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
  
  /// Initialize all services (for backward compatibility)
  Future<void> init() async {
    if (_fullInitialized) return;
    
    await initBasicServices();
    await initRemainingServices();
  }
  
  /// Cleanup resources when app closes
  Future<void> dispose() async {
    if (!_basicServicesInitialized) return;
    
    try {
      _logger?.info(message: 'Disposing services...');
      
      // Dispose services that need cleanup
      if (getIt.isRegistered<NotificationService>()) {
        await getIt<NotificationService>().dispose();
      }
      
      if (getIt.isRegistered<DoNotDisturbService>()) {
        final dndService = getIt<DoNotDisturbService>() as DoNotDisturbServiceImpl;
        await dndService.dispose();
      }
      
      if (getIt.isRegistered<BatteryService>()) {
        await getIt<BatteryService>().dispose();
      }
      
      if (getIt.isRegistered<NotificationRetryManager>()) {
        await getIt<NotificationRetryManager>().dispose();
      }
      
      if (getIt.isRegistered<NotificationAnalytics>()) {
        getIt<NotificationAnalytics>().dispose();
      }
      
      if (getIt.isRegistered<PermissionService>()) {
        (getIt<PermissionService>() as PermissionServiceImpl).dispose();
      }
      
      // Reset GetIt
      await getIt.reset();
      _basicServicesInitialized = false;
      _fullInitialized = false;
      _logger = null;
      
      debugPrint('All services disposed successfully');
    } catch (e) {
      debugPrint('Error disposing services: $e');
    }
  }
  
  /// Reset for testing
  Future<void> reset() async {
    await dispose();
  }
  
  /// Check if service is registered
  bool isRegistered<T extends Object>() {
    return getIt.isRegistered<T>();
  }
  
  /// Get service instance
  T get<T extends Object>() {
    return getIt<T>();
  }
}

extension on GetIt {
  get registrations => null;
}