// lib/app/di/service_locator.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_plus/battery_plus.dart';

// الخدمات الأساسية فقط
import '../../core/infrastructure/services/logging/logger_service.dart';
import '../../core/infrastructure/services/logging/logger_service_impl.dart';
import '../../core/infrastructure/services/storage/storage_service.dart';
import '../../core/infrastructure/services/storage/storage_service_impl.dart';
import '../../core/infrastructure/services/timezone/timezone_service.dart';
import '../../core/infrastructure/services/timezone/timezone_service_impl.dart';
import '../../core/infrastructure/services/permissions/permission_service.dart';
import '../../core/infrastructure/services/permissions/permission_service_impl.dart';
import '../../core/infrastructure/services/device/battery/battery_service.dart';
import '../../core/infrastructure/services/device/battery/battery_service_impl.dart';
import '../../core/infrastructure/services/device/do_not_disturb/do_not_disturb_service.dart';
import '../../core/infrastructure/services/device/do_not_disturb/do_not_disturb_service_impl.dart';
import '../../core/infrastructure/services/notifications/notification_service.dart';
import '../../core/infrastructure/services/notifications/notification_service_impl.dart';
import '../../core/error/error_handler.dart';

final getIt = GetIt.instance;

/// Service Locator المبسط لتطبيق الأذكار
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  bool _isInitialized = false;
  LoggerService? _logger;

  /// تهيئة جميع الخدمات
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      debugPrint('تهيئة الخدمات...');
      
      // Logger
      getIt.registerLazySingleton<LoggerService>(
        () => LoggerServiceImpl(),
      );
      _logger = getIt<LoggerService>();
      
      // SharedPreferences
      final sharedPreferences = await SharedPreferences.getInstance();
      getIt.registerSingleton<SharedPreferences>(sharedPreferences);
      
      // Storage Service
      getIt.registerLazySingleton<StorageService>(
        () => StorageServiceImpl(
          sharedPreferences,
          logger: _logger,
        ),
      );
      
      // Timezone Service
      getIt.registerLazySingleton<TimezoneService>(
        () => TimezoneServiceImpl(logger: _logger!),
      );
      await getIt<TimezoneService>().initializeTimeZones();
      
      // Permission Service
      getIt.registerLazySingleton<PermissionService>(
        () => PermissionServiceImpl(logger: _logger!),
      );
      
      // Battery Service (اختياري)
      getIt.registerLazySingleton<Battery>(() => Battery());
      getIt.registerLazySingleton<BatteryService>(
        () => BatteryServiceImpl(
          battery: getIt<Battery>(),
          logger: _logger,
          storage: getIt<StorageService>(),
        ),
      );
      
      // Do Not Disturb Service (اختياري)
      getIt.registerLazySingleton<DoNotDisturbService>(
        () => DoNotDisturbServiceImpl(
          logger: _logger,
          permissionService: getIt<PermissionService>(),
        ),
      );
      
      // Notification Service
      getIt.registerLazySingleton<FlutterLocalNotificationsPlugin>(
        () => FlutterLocalNotificationsPlugin(),
      );
      
      getIt.registerLazySingleton<NotificationService>(
        () => NotificationServiceImpl(
          getIt<FlutterLocalNotificationsPlugin>(),
          getIt<BatteryService>(),
          getIt<DoNotDisturbService>(),
          getIt<TimezoneService>(),
          storageService: getIt<StorageService>(),
          logger: _logger,
        ),
      );
      
      // تهيئة خدمة الإشعارات
      await getIt<NotificationService>().initialize();
      
      // Error Handler
      getIt.registerLazySingleton<AppErrorHandler>(
        () => AppErrorHandler(_logger!),
      );
      
      _isInitialized = true;
      _logger?.info(message: 'تم تهيئة جميع الخدمات بنجاح');
      
    } catch (e, s) {
      debugPrint('خطأ في تهيئة الخدمات: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }
  
  /// تنظيف الموارد عند إغلاق التطبيق
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    try {
      _logger?.info(message: 'تنظيف الخدمات...');
      
      if (getIt.isRegistered<NotificationService>()) {
        await getIt<NotificationService>().dispose();
      }
      
      if (getIt.isRegistered<BatteryService>()) {
        await getIt<BatteryService>().dispose();
      }
      
      await getIt.reset();
      _isInitialized = false;
      _logger = null;
      
      debugPrint('تم تنظيف جميع الخدمات بنجاح');
    } catch (e) {
      debugPrint('خطأ في تنظيف الخدمات: $e');
    }
  }
}