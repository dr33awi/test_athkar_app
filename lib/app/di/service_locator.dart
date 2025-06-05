// lib/app/di/service_locator.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:battery_plus/battery_plus.dart';

// خدمات التخزين
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service_impl.dart';

// خدمات السجلات
import 'package:athkar_app/core/infrastructure/services/logging/logger_service.dart';
import 'package:athkar_app/core/infrastructure/services/logging/logger_service_impl.dart';

// خدمات الإشعارات
import 'package:athkar_app/core/infrastructure/services/notifications/notification_manager.dart';
import 'package:athkar_app/core/infrastructure/services/notifications/notification_service.dart';
import 'package:athkar_app/core/infrastructure/services/notifications/notification_service_impl.dart';

// خدمات الأذونات
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service.dart';
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service_impl.dart';



// معالج الأخطاء
import '../../core/error/error_handler.dart';

final getIt = GetIt.instance;

/// Service Locator لإدارة جميع الخدمات في التطبيق
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  bool _isInitialized = false;

  /// تهيئة جميع الخدمات
  static Future<void> init() async {
    final instance = ServiceLocator();
    await instance._initializeServices();
  }

  /// التحقق من تهيئة الخدمات
  static bool get isInitialized => _instance._isInitialized;

  /// تهيئة الخدمات الداخلية
  Future<void> _initializeServices() async {
    if (_isInitialized) {
      debugPrint('ServiceLocator: الخدمات مهيأة مسبقاً');
      return;
    }

    try {
      debugPrint('ServiceLocator: بدء تهيئة الخدمات...');

      // 1. الخدمات الأساسية
      await _registerCoreServices();

      // 2. خدمات التخزين
      await _registerStorageServices();

      // 3. خدمات السجلات
      _registerLoggingServices();

      // 4. خدمات الأذونات
      _registerPermissionServices();

      // 6. خدمات الإشعارات
      await _registerNotificationServices();

      // 7. معالج الأخطاء
      _registerErrorHandler();

      _isInitialized = true;
      debugPrint('ServiceLocator: تم تهيئة جميع الخدمات بنجاح ✓');
      
    } catch (e, stackTrace) {
      debugPrint('ServiceLocator: خطأ في تهيئة الخدمات: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// تسجيل الخدمات الأساسية
  Future<void> _registerCoreServices() async {
    debugPrint('ServiceLocator: تسجيل الخدمات الأساسية...');

    // SharedPreferences
    if (!getIt.isRegistered<SharedPreferences>()) {
      final sharedPreferences = await SharedPreferences.getInstance();
      getIt.registerSingleton<SharedPreferences>(sharedPreferences);
    }

    // Battery
    if (!getIt.isRegistered<Battery>()) {
      getIt.registerLazySingleton<Battery>(() => Battery());
    }

    // Flutter Local Notifications Plugin
    if (!getIt.isRegistered<FlutterLocalNotificationsPlugin>()) {
      getIt.registerLazySingleton<FlutterLocalNotificationsPlugin>(
        () => FlutterLocalNotificationsPlugin(),
      );
    }
  }

  /// تسجيل خدمات التخزين
  Future<void> _registerStorageServices() async {
    debugPrint('ServiceLocator: تسجيل خدمات التخزين...');

    if (!getIt.isRegistered<StorageService>()) {
      getIt.registerLazySingleton<StorageService>(
        () => StorageServiceImpl(
          getIt<SharedPreferences>(),
          logger: getIt.isRegistered<LoggerService>() ? getIt<LoggerService>() : null,
        ),
      );
    }
  }

  /// تسجيل خدمات السجلات
  void _registerLoggingServices() {
    debugPrint('ServiceLocator: تسجيل خدمات السجلات...');

    if (!getIt.isRegistered<LoggerService>()) {
      getIt.registerLazySingleton<LoggerService>(
        () => LoggerServiceImpl(),
      );
    }
  }

  /// تسجيل خدمات الأذونات
  void _registerPermissionServices() {
    debugPrint('ServiceLocator: تسجيل خدمات الأذونات...');

    if (!getIt.isRegistered<PermissionService>()) {
      getIt.registerLazySingleton<PermissionService>(
        () => PermissionServiceImpl(
          logger: getIt<LoggerService>(),
          storage: getIt<StorageService>(),
        ),
      );
    }
  }

  /// تسجيل خدمات الإشعارات
  Future<void> _registerNotificationServices() async {
    debugPrint('ServiceLocator: تسجيل خدمات الإشعارات...');

    // خدمة الإشعارات الأساسية
    if (!getIt.isRegistered<NotificationService>()) {
      getIt.registerLazySingleton<NotificationService>(
        () => NotificationServiceImpl(
          prefs: getIt<SharedPreferences>(),
          plugin: getIt<FlutterLocalNotificationsPlugin>(),
          battery: getIt<Battery>(),
        ),
      );
    }

    // تهيئة مدير الإشعارات
    try {
      await NotificationManager.initialize(getIt<NotificationService>());
      debugPrint('ServiceLocator: تم تهيئة مدير الإشعارات');
    } catch (e) {
      debugPrint('ServiceLocator: خطأ في تهيئة مدير الإشعارات: $e');
      // يمكن المتابعة حتى لو فشلت الإشعارات
    }
  }

  /// تسجيل معالج الأخطاء
  void _registerErrorHandler() {
    debugPrint('ServiceLocator: تسجيل معالج الأخطاء...');

    if (!getIt.isRegistered<AppErrorHandler>()) {
      getIt.registerLazySingleton<AppErrorHandler>(
        () => AppErrorHandler(getIt<LoggerService>()),
      );
    }
  }

  /// إعادة تعيين خدمة محددة
  static Future<void> resetService<T extends Object>() async {
    if (getIt.isRegistered<T>()) {
      await getIt.unregister<T>();
      debugPrint('ServiceLocator: تم إلغاء تسجيل ${T.toString()}');
    }
  }

  /// إعادة تعيين جميع الخدمات
  static Future<void> reset() async {
    debugPrint('ServiceLocator: إعادة تعيين جميع الخدمات...');
    
    try {
      // التنظيف قبل إعادة التعيين
      await _instance._cleanup();
      
      // إعادة تعيين GetIt
      await getIt.reset();
      
      _instance._isInitialized = false;
      debugPrint('ServiceLocator: تم إعادة تعيين جميع الخدمات');
    } catch (e) {
      debugPrint('ServiceLocator: خطأ في إعادة التعيين: $e');
    }
  }

  /// تنظيف الموارد
  Future<void> _cleanup() async {
    debugPrint('ServiceLocator: تنظيف الموارد...');

    try {
      // تنظيف الإشعارات
      if (getIt.isRegistered<NotificationService>()) {
        await getIt<NotificationService>().dispose();
      }

      // تنظيف الأذونات
      if (getIt.isRegistered<PermissionService>()) {
        await getIt<PermissionService>().dispose();
      }

      debugPrint('ServiceLocator: تم تنظيف الموارد');
    } catch (e) {
      debugPrint('ServiceLocator: خطأ في تنظيف الموارد: $e');
    }
  }

  /// التنظيف عند إغلاق التطبيق
  static Future<void> dispose() async {
    if (!_instance._isInitialized) return;

    debugPrint('ServiceLocator: بدء التنظيف النهائي...');
    
    try {
      await _instance._cleanup();
      await reset();
      debugPrint('ServiceLocator: تم التنظيف النهائي بنجاح');
    } catch (e) {
      debugPrint('ServiceLocator: خطأ في التنظيف النهائي: $e');
    }
  }
}

/// Extension methods لسهولة الوصول للخدمات
extension ServiceLocatorExtensions on BuildContext {
  /// الحصول على خدمة بسهولة
  T getService<T extends Object>() => getIt<T>();
  
  /// التحقق من وجود خدمة
  bool hasService<T extends Object>() => getIt.isRegistered<T>();
  
  /// الحصول على خدمة التخزين
  StorageService get storageService => getIt<StorageService>();
  
  /// الحصول على خدمة الإشعارات
  NotificationService get notificationService => getIt<NotificationService>();
  
  /// الحصول على خدمة الأذونات
  PermissionService get permissionService => getIt<PermissionService>();
  
  /// الحصول على خدمة السجلات
  LoggerService get loggerService => getIt<LoggerService>();
  
  /// الحصول على معالج الأخطاء
  AppErrorHandler get errorHandler => getIt<AppErrorHandler>();
}