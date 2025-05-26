// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart'; // أضفت هذا الاستيراد لتهيئة بيانات اللغة

import 'app/app.dart';
import 'app/di/service_locator.dart';
import 'app/routes/app_router.dart';
import 'app/themes/app_theme.dart';
import 'core/services/interfaces/notification_service.dart';
import 'core/services/interfaces/timezone_service.dart';
import 'core/services/interfaces/storage_service.dart';
import 'features/settings/domain/usecases/get_settings.dart';
import 'features/settings/domain/usecases/update_settings.dart';
import 'core/services/utils/notification_scheduler.dart';
import 'core/constants/app_constants.dart';
import 'features/onboarding/presentation/screens/permissions_onboarding_screen.dart';
import 'features/athkar/presentation/providers/athkar_provider.dart';
import 'features/prayers/presentation/providers/prayer_times_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/athkar/domain/usecases/get_athkar_by_category.dart';
import 'features/athkar/domain/usecases/get_athkar_categories.dart';
import 'features/athkar/domain/usecases/get_athkar_by_id.dart';
import 'features/athkar/domain/usecases/save_athkar_favorite.dart';
import 'features/athkar/domain/usecases/get_favorite_athkar.dart';
import 'features/athkar/domain/usecases/search_athkar.dart';
import 'features/prayers/domain/usecases/get_prayer_times.dart';
import 'features/prayers/domain/usecases/get_qibla_direction.dart';
import 'app/themes/app_theme.dart';

Future<void> main() async {
  // تهيئة ربط Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة بيانات اللغة المحلية للتواريخ (أضفت هذا السطر لحل المشكلة)
  await initializeDateFormatting('ar', null);
  
  // تعيين اتجاه التطبيق
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  try {
    // إعداد NavigationService
    _setupNavigationService();
    
    // تسجيل Observer لمراقبة دورة حياة التطبيق
    WidgetsBinding.instance.addObserver(AppLifecycleObserver());
    
    // تهيئة جميع الخدمات قبل إنشاء providers
    await _initAllServices();
    
    // التحقق من أول تشغيل للتطبيق
    final storageService = getIt<StorageService>();
    final isFirstRun = storageService.getBool('isFirstRun') ?? true;
    
    // إنشاء جميع providers على مستوى جذر التطبيق
    final providers = MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            getSettings: getIt<GetSettings>(),
            updateSettings: getIt<UpdateSettings>(),
          )..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => AthkarProvider(
            getAthkarCategories: getIt<GetAthkarCategories>(),
            getAthkarByCategory: getIt<GetAthkarByCategory>(),
            getAthkarById: getIt<GetAthkarById>(),
            saveFavorite: getIt<SaveAthkarFavorite>(),
            getFavorites: getIt<GetFavoriteAthkar>(),
            searchAthkar: getIt<SearchAthkar>(),
          )..loadCategories(),
        ),
        ChangeNotifierProvider(
          create: (_) => PrayerTimesProvider(
            getPrayerTimes: getIt<GetPrayerTimes>(),
            getQiblaDirection: getIt<GetQiblaDirection>(),
          ),
        ),
      ],
      child: isFirstRun ? OnboardingApp() : const AthkarApp(),
    );
    
    runApp(providers);
    
    // حفظ حالة أول تشغيل
    if (isFirstRun) {
      await storageService.setBool('isFirstRun', false);
    }
    
    // طلب أذونات الإشعارات عند بدء التطبيق
    await _requestNotificationPermissions();
    
    // جدولة الإشعارات بناءً على الإعدادات المحفوظة
    await _scheduleNotifications();
    
  } catch (e) {
    debugPrint('Error al iniciar la aplicación: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('حدث خطأ أثناء تهيئة التطبيق: $e'),
          ),
        ),
      ),
    );
  }
}

/// تهيئة جميع الخدمات (الأساسية وغير الأساسية) في مرة واحدة
Future<void> _initAllServices() async {
  // تهيئة كل الخدمات في مرة واحدة (لحل مشكلة الاعتمادات)
  await ServiceLocator().init();
  
  // التأكد من تهيئة التوقيت
  final timezoneService = getIt<TimezoneService>();
  await timezoneService.initializeTimeZones();
  
  debugPrint('Todos los servicios inicializados correctamente');
}

/// إعداد خدمة التنقل
void _setupNavigationService() {
  // إعداد NavigationKey للوصول إلى السياق
  NavigationService.navigatorKey = GlobalKey<NavigatorState>();
}

/// طلب أذونات الإشعارات
Future<void> _requestNotificationPermissions() async {
  try {
    final notificationService = getIt<NotificationService>();
    final hasPermission = await notificationService.requestPermission();
    debugPrint('Permiso de notificaciones: $hasPermission');
  } catch (e) {
    debugPrint('Error requesting notification permissions: $e');
  }
}

/// جدولة الإشعارات عند بدء التطبيق
Future<void> _scheduleNotifications() async {
  try {
    // الحصول على الإعدادات المحفوظة
    final settings = await getIt<GetSettings>().call();
    
    // جدولة الإشعارات
    if (settings.enableNotifications) {
      final notificationScheduler = getIt<NotificationScheduler>();
      await notificationScheduler.scheduleAllNotifications(settings);
      debugPrint('Notificaciones programadas correctamente');
    }
  } catch (e) {
    debugPrint('حدث خطأ أثناء جدولة الإشعارات: $e');
  }
}

// تطبيق شاشة الأذونات والترحيب
class OnboardingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.permissionsOnboarding,
      navigatorObservers: [
        _NavigationObserver(), 
      ],
    );
  }
}

// تنفيذ محدث لـ AthkarApp
class AthkarApp extends StatelessWidget {
  const AthkarApp({super.key});

  @override
  Widget build(BuildContext context) {
    // الوصول إلى SettingsProvider المتاح عالميًا
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.settings?.enableDarkMode ?? false;
    final language = settingsProvider.settings?.language ?? AppConstants.defaultLanguage;
    
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(language),
      supportedLocales: const [
        Locale('ar'), // العربية
        Locale('en'), // الإنجليزية
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorKey: NavigationService.navigatorKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.home,
      navigatorObservers: [
        _NavigationObserver(),
      ],
    );
  }
}

// خدمة التنقل للوصول إلى السياق العام للتطبيق
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

/// مراقب دورة حياة التطبيق لتنظيف الموارد عند إغلاق التطبيق
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('Estado de ciclo de vida cambiado a: $state');
    
    if (state == AppLifecycleState.detached) {
      // عندما يتم إغلاق التطبيق نهائيًا
      _disposeResources();
    }
  }
  
  /// تنظيف الموارد عند إغلاق التطبيق
  Future<void> _disposeResources() async {
    try {
      debugPrint('Disposing resources...');
      
      // تنظيف موارد خدمة الإشعارات
      if (getIt.isRegistered<NotificationService>()) {
        final notificationService = getIt<NotificationService>();
        await notificationService.dispose();
      }
      
      // تنظيف موارد جميع الخدمات
      await ServiceLocator().dispose();
      
      debugPrint('Resources disposed successfully');
    } catch (e) {
      debugPrint('Error disposing resources: $e');
    }
  }
}

/// تسجيل الخروج من التطبيق
class AppShutdownManager {
  static Future<bool> shutdownApp() async {
    try {
      // تنظيف الموارد
      await ServiceLocator().dispose();
      return true;
    } catch (e) {
      debugPrint('Error during app shutdown: $e');
      return false;
    }
  }
}

/// مراقب التنقل للتصحيح
class _NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Navegación: Ruta empujada - ${route.settings.name} (previa: ${previousRoute?.settings.name})');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Navegación: Ruta retirada - ${route.settings.name} (volviendo a: ${previousRoute?.settings.name})');
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint('Navegación: Ruta reemplazada - Nueva: ${newRoute?.settings.name}, Vieja: ${oldRoute?.settings.name}');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Navegación: Ruta eliminada - ${route.settings.name}');
    super.didRemove(route, previousRoute);
  }
}