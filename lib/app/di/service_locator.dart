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
import '../../core/infrastructure/services/device/battery/battery_service.dart'; // No alias needed
import '../../core/infrastructure/services/device/battery/battery_service_impl.dart';
import '../../core/infrastructure/services/device/do_not_disturb/do_not_disturb_service.dart';
import '../../core/infrastructure/services/device/do_not_disturb/do_not_disturb_service_impl.dart';
import '../../core/infrastructure/services/notifications/notification_service.dart';
import '../../core/infrastructure/services/notifications/notification_service_impl.dart';
import '../../core/infrastructure/services/notifications/utils/notification_analytics.dart';
import '../../core/infrastructure/services/notifications/utils/notification_retry_manager.dart';
import '../../core/error/error_handler.dart';
import '../../core/infrastructure/services/storage/secure_storage_service.dart';
import '../../core/infrastructure/services/notifications/notification_scheduler.dart';

final getIt = GetIt.instance;

/// Service Locator for dependency injection
/// Manages all service registrations and lifecycle
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  bool _isInitialized = false;
  LoggerService? _logger;

  /// Initialize only essential services
  Future<void> initEssentialServices() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing essential services...');
      
      // Logger - First to initialize
      if (!getIt.isRegistered<LoggerService>()) {
        getIt.registerLazySingleton<LoggerService>(
          () => LoggerServiceImpl(),
        );
      }
      _logger = getIt<LoggerService>();
      _logger!.info(message: 'Initializing essential services...');

      // External dependencies
      final sharedPreferences = await SharedPreferences.getInstance();
      if (!getIt.isRegistered<SharedPreferences>()) {
        getIt.registerSingleton<SharedPreferences>(sharedPreferences);
      }
      
      // Core Services
      if (!getIt.isRegistered<StorageService>()) {
        getIt.registerLazySingleton<StorageService>(
          () => StorageServiceImpl(
            sharedPreferences,
            logger: _logger,
          ),
        );
      }
      
      _logger?.info(message: 'Essential services initialized');
      _isInitialized = true;
      
    } catch (e, s) {
      debugPrint('Error initializing essential services: $e');
      debugPrint('Stack trace: $s');
      // Don't rethrow - allow app to continue
    }
  }

  /// Initialize remaining services
  Future<void> initRemainingServices() async {
    if (!_isInitialized) {
      await initEssentialServices();
    }

    try {
      _logger?.info(message: 'Initializing remaining services...');
      
      // Configuration Service
      if (!getIt.isRegistered<ConfigurationService>()) {
        getIt.registerLazySingleton<ConfigurationService>(
          () => ConfigurationServiceImpl(
            storage: getIt<StorageService>(),
            logger: _logger!,
          ),
        );
        
        try {
          await getIt<ConfigurationService>().loadConfiguration();
        } catch (e) {
          _logger?.warning(message: 'Failed to load configuration', data: {'error': e.toString()});
        }
      }
      
      // Timezone Service
      if (!getIt.isRegistered<TimezoneService>()) {
        getIt.registerLazySingleton<TimezoneService>(
          () => TimezoneServiceImpl(logger: _logger!),
        );
        
        try {
          await getIt<TimezoneService>().initializeTimeZones();
        } catch (e) {
          _logger?.warning(message: 'Failed to initialize timezones', data: {'error': e.toString()});
        }
      }
      
      // Permission Services
      if (!getIt.isRegistered<PermissionService>()) {
        getIt.registerLazySingleton<PermissionService>(
          () => PermissionServiceImpl(logger: _logger),
        );
      }
      
      if (!getIt.isRegistered<PermissionManager>()) {
        getIt.registerLazySingleton<PermissionManager>(
          () => PermissionManager(
            getIt<PermissionService>(),
            logger: _logger,
          ),
        );
      }
      
      // Device Services
      if (!getIt.isRegistered<Battery>()) {
        getIt.registerLazySingleton<Battery>(
          () => Battery(),
        );
      }
      
      if (!getIt.isRegistered<BatteryService>()) { 
        getIt.registerLazySingleton<BatteryService>( 
          () => BatteryServiceImpl(
            battery: getIt<Battery>(),
            logger: _logger,
            storage: getIt<StorageService>(),
          ),
        );
      }
      
      if (!getIt.isRegistered<DoNotDisturbService>()) {
        getIt.registerLazySingleton<DoNotDisturbService>(
          () => DoNotDisturbServiceImpl(
            logger: _logger,
            permissionService: getIt<PermissionService>(),
          ),
        );
      }
      
      // Notification Services - with careful error handling
      try {
        if (!getIt.isRegistered<FlutterLocalNotificationsPlugin>()) {
          getIt.registerLazySingleton<FlutterLocalNotificationsPlugin>(
            () => FlutterLocalNotificationsPlugin(),
          );
        }
        
        if (!getIt.isRegistered<NotificationAnalytics>()) {
          getIt.registerLazySingleton<NotificationAnalytics>(
            () => NotificationAnalytics(logger: _logger),
          );
        }
        
        if (!getIt.isRegistered<NotificationRetryManager>()) {
          getIt.registerLazySingleton<NotificationRetryManager>(
            () => NotificationRetryManager(
              storage: getIt<StorageService>(),
              logger: _logger,
            ),
          );
        }
        
        if (!getIt.isRegistered<NotificationService>()) {
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
          
          // Initialize notification service with error handling
          try {
            // final config = getIt<ConfigurationService>(); // Not needed for this test line
            // String? defaultIcon = config.getString('notification.default_icon'); // Original line

            // **** START MODIFICATION FOR TEST ****
            String? defaultIcon = null; // Temporarily force to null for testing
            _logger?.info(message: "TEMPORARY TEST: defaultIcon in NotificationService.initialize() is forced to null.");
            // **** END MODIFICATION FOR TEST ****
                        
            await getIt<NotificationService>().initialize(
              defaultIcon: defaultIcon,
            );
          } catch (e) {
            _logger?.warning(message: 'Failed to initialize notification service', data: {'error': e.toString()});
          }
        }
      } catch (e) {
        _logger?.error(
          message: 'Error initializing notification services dependencies',
          error: e.toString(),
        );
      }
      
      // Error Handler
      if (!getIt.isRegistered<AppErrorHandler>()) {
        getIt.registerLazySingleton<AppErrorHandler>(
          () => AppErrorHandler(_logger!),
        );
      }

      // Secure Storage Service
      if (!getIt.isRegistered<SecureStorageService>()) {
        getIt.registerLazySingleton<SecureStorageService>(
          () => SecureStorageServiceImpl(
            regularStorage: getIt<StorageService>(),
            logger: _logger,
          ),
        );
      }

      // Notification Scheduler
      if (!getIt.isRegistered<NotificationScheduler>()) {
        if (getIt.isRegistered<NotificationService>()) {
            getIt.registerLazySingleton<NotificationScheduler>(
            () => NotificationScheduler(
                notificationService: getIt<NotificationService>(),
                logger: _logger,
                storage: getIt<StorageService>(),
            ),
            );
        } else {
            _logger?.warning(message: "NotificationService not available, NotificationScheduler cannot be registered.");
        }
      }
      
      _logger?.info(message: 'All remaining services initialized');
      _logger?.logEvent('app_services_initialized');
      
    } catch (e, s) {
      _logger?.error(
        message: 'Error initializing remaining services',
        error: e.toString(), 
        stackTrace: s,
      );
    }
  }

  /// Initialize all services
  Future<void> init() async {
    await initEssentialServices();
    await initRemainingServices();
  }
  
  /// Cleanup resources when app closes
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    try {
      _logger?.info(message: 'Disposing services...');
      
      if (getIt.isRegistered<NotificationService>()) {
        try {
          await getIt<NotificationService>().dispose();
        } catch (e) {
          debugPrint('Error disposing NotificationService: $e');
        }
      }
      
      if (getIt.isRegistered<DoNotDisturbService>()) {
        try {
           dynamic dndService = getIt<DoNotDisturbService>();
           if (dndService is DoNotDisturbServiceImpl) {
             await dndService.dispose();
           }
        } catch (e) {
          debugPrint('Error disposing DoNotDisturbService: $e');
        }
      }
      
      if (getIt.isRegistered<BatteryService>()) { 
        try {
          await getIt<BatteryService>().dispose(); 
        } catch (e) {
          debugPrint('Error disposing BatteryService: $e');
        }
      }
      
      if (getIt.isRegistered<NotificationRetryManager>()) {
        try {
          await getIt<NotificationRetryManager>().dispose();
        } catch (e) {
          debugPrint('Error disposing NotificationRetryManager: $e');
        }
      }
      
      if (getIt.isRegistered<NotificationAnalytics>()) {
        try {
          getIt<NotificationAnalytics>().dispose();
        } catch (e) {
          debugPrint('Error disposing NotificationAnalytics: $e');
        }
      }
      
      if (getIt.isRegistered<PermissionService>()) {
        try {
          dynamic permService = getIt<PermissionService>();
          if (permService is PermissionServiceImpl) {
             permService.dispose();
          }
        } catch (e) {
          debugPrint('Error disposing PermissionService: $e');
        }
      }
       if (getIt.isRegistered<NotificationScheduler>()) {
        try {
            // Assuming NotificationScheduler might have a dispose method.
            // No explicit interface contract for dispose here.
        } catch (e) {
          debugPrint('Error (potentially) disposing NotificationScheduler: $e');
        }
      }
      
      await getIt.reset();
      _isInitialized = false;
      _logger = null;
      
      debugPrint('All services disposed successfully');
    } catch (e) {
      debugPrint('Error disposing services: $e');
    }
  }
  
  Future<void> reset() async {
    await dispose();
  }
  
  bool isRegistered<T extends Object>() {
    return getIt.isRegistered<T>();
  }
  
  T get<T extends Object>() {
    return getIt<T>();
  }
  
  T? tryGet<T extends Object>() {
    try {
      if (getIt.isRegistered<T>()) {
        return getIt<T>();
      }
    } catch (e) {
      _logger?.debug(message: 'Service $T not registered or error during retrieval.', data: {'error': e.toString()});
    }
    return null;
  }
}