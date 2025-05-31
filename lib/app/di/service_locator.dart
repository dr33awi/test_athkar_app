// lib/app/di/service_locator.dart
import 'package:athkar_app/features/notifications/domain/services/notification_scheduler_impl.dart';
import 'package:athkar_app/features/prayers/domain/services/prayer_times_service_impl.dart';
import 'package:athkar_app/features/prayers/qibla_service_impl.dart';
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

// Feature Services
import '../../features/prayers/domain/services/prayer_times_service.dart';
import '../../features/prayers/domain/services/qibla_service.dart';
import '../../features/notifications/domain/services/notification_scheduler.dart';

// Data Sources
import '../../features/athkar/data/datasources/athkar_local_data_source.dart';
import '../../features/settings/data/datasources/settings_local_data_source.dart';

// Repositories
import '../../features/athkar/data/repositories/athkar_repository_impl.dart';
import '../../features/prayers/data/repositories/prayer_times_repository_impl.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/athkar/domain/repositories/athkar_repository.dart';
import '../../features/prayers/domain/repositories/prayer_times_repository.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';

// Use Cases
import '../../features/athkar/domain/usecases/get_athkar_by_category.dart';
import '../../features/athkar/domain/usecases/get_athkar_categories.dart';
import '../../features/athkar/domain/usecases/get_athkar_by_id.dart';
import '../../features/athkar/domain/usecases/save_athkar_favorite.dart';
import '../../features/athkar/domain/usecases/get_favorite_athkar.dart';
import '../../features/athkar/domain/usecases/search_athkar.dart';
import '../../features/prayers/domain/usecases/get_prayer_times.dart';
import '../../features/prayers/domain/usecases/get_qibla_direction.dart';
import '../../features/settings/domain/usecases/get_settings.dart';
import '../../features/settings/domain/usecases/update_settings.dart';

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
      
      // Data Sources
      getIt.registerLazySingleton<SettingsLocalDataSource>(
        () => SettingsLocalDataSourceImpl(getIt<StorageService>()),
      );

      // Repositories
      getIt.registerLazySingleton<SettingsRepository>(
        () => SettingsRepositoryImpl(getIt<SettingsLocalDataSource>()),
      );

      // Use Cases
      getIt.registerLazySingleton(() => GetSettings(getIt<SettingsRepository>()));
      getIt.registerLazySingleton(() => UpdateSettings(getIt<SettingsRepository>()));

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
      
      // Feature Services
      getIt.registerLazySingleton<PrayerTimesService>(
        () => PrayerTimesServiceImpl(
          logger: _logger,
          storageService: getIt<StorageService>(),
        ),
      );
      
      getIt.registerLazySingleton<QiblaService>(
        () => QiblaServiceImpl(
          logger: _logger,
          permissionService: getIt<PermissionService>(),
        ),
      );
      
      getIt.registerLazySingleton<NotificationScheduler>(
        () => NotificationSchedulerImpl(
          notificationService: getIt<NotificationService>(),
          prayerTimesService: getIt<PrayerTimesService>(),
          logger: _logger,
        ),
      );
      
      // Error Handler
      getIt.registerLazySingleton<AppErrorHandler>(
        () => AppErrorHandler(_logger!),
      );

      // Data Sources
      getIt.registerLazySingleton<AthkarLocalDataSource>(
        () => AthkarLocalDataSourceImpl(
          storageService: getIt<StorageService>(),
          logger: _logger,
        ),
      );

      // Repositories
      getIt.registerLazySingleton<AthkarRepository>(
        () => AthkarRepositoryImpl(
          localDataSource: getIt<AthkarLocalDataSource>(),
          errorHandler: getIt<AppErrorHandler>(),
        ),
      );
      
      getIt.registerLazySingleton<PrayerTimesRepository>(
        () => PrayerTimesRepositoryImpl(
          prayerTimesService: getIt<PrayerTimesService>(),
          qiblaService: getIt<QiblaService>(),
          errorHandler: getIt<AppErrorHandler>(),
        ),
      );

      // Use Cases
      getIt.registerLazySingleton(() => GetAthkarByCategory(getIt<AthkarRepository>()));
      getIt.registerLazySingleton(() => GetAthkarCategories(getIt<AthkarRepository>()));
      getIt.registerLazySingleton(() => GetAthkarById(getIt<AthkarRepository>()));
      getIt.registerLazySingleton(() => SaveAthkarFavorite(getIt<AthkarRepository>()));
      getIt.registerLazySingleton(() => GetFavoriteAthkar(getIt<AthkarRepository>()));
      getIt.registerLazySingleton(() => SearchAthkar(getIt<AthkarRepository>()));
      getIt.registerLazySingleton(() => GetPrayerTimes(getIt<PrayerTimesRepository>()));
      getIt.registerLazySingleton(() => GetQiblaDirection(getIt<PrayerTimesRepository>()));

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
      if (getIt.isRegistered<NotificationScheduler>()) {
        await (getIt<NotificationScheduler>() as NotificationSchedulerImpl).dispose();
      }
      
      if (getIt.isRegistered<NotificationService>()) {
        await getIt<NotificationService>().dispose();
      }
      
      if (getIt.isRegistered<QiblaService>()) {
        getIt<QiblaService>().dispose();
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