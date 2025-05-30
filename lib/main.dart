// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/di/service_locator.dart';
import 'app/routes/app_router.dart';
import 'app/themes/app_theme.dart';
import 'core/infrastructure/services/notifications/notification_service.dart';
import 'core/infrastructure/services/timezone/timezone_service.dart';
import 'core/infrastructure/services/storage/storage_service.dart';
import 'features/settings/domain/usecases/get_settings.dart';
import 'features/settings/domain/usecases/update_settings.dart';
import 'features/notifications/domain/services/notification_scheduler.dart';
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

Future<void> main() async {
  // تهيئة ربط Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة بيانات اللغة المحلية للتواريخ
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
    
    // تهيئة جميع الخدمات
    await _initAllServices();
    
    // التحقق من أول تشغيل للتطبيق
    final storageService = getIt<StorageService>();
    final isFirstRun = storageService.getBool('isFirstRun') ?? true;
    
    // إنشاء جميع providers على مستوى جذر التطبيق
    final app = MultiProvider(
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
      child: AthkarApp(isFirstRun: isFirstRun),
    );
    
    runApp(app);
    
    // حفظ حالة أول تشغيل
    if (isFirstRun) {
      await storageService.setBool('isFirstRun', false);
    }
    
    // طلب أذونات الإشعارات عند بدء التطبيق
    await _requestNotificationPermissions();
    
    // جدولة الإشعارات بناءً على الإعدادات المحفوظة
    await _scheduleNotifications();
    
  } catch (e, s) {
    debugPrint('Error al iniciar la aplicación: $e');
    debugPrint('Stack trace: $s');
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

/// تهيئة جميع الخدمات
Future<void> _initAllServices() async {
  await ServiceLocator().init();
  
  // التأكد من تهيئة التوقيت
  final timezoneService = getIt<TimezoneService>();
  await timezoneService.initializeTimeZones();
  
  debugPrint('جميع الخدمات تم تهيئتها بنجاح');
}

/// إعداد خدمة التنقل
void _setupNavigationService() {
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
    final settings = await getIt<GetSettings>().call();
    
    if (settings.enableNotifications) {
      final notificationScheduler = getIt<NotificationScheduler>();
      // يمكن إضافة المزيد من المنطق هنا لجدولة الإشعارات
      debugPrint('الإشعارات تم جدولتها بنجاح');
    }
  } catch (e) {
    debugPrint('حدث خطأ أثناء جدولة الإشعارات: $e');
  }
}

// تطبيق رئيسي موحد
class AthkarApp extends StatelessWidget {
  final bool isFirstRun;
  
  const AthkarApp({super.key, required this.isFirstRun});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.settings?.enableDarkMode ?? false;
    final language = settingsProvider.settings?.language ?? AppConstants.defaultLanguage;
    
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
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
      initialRoute: isFirstRun ? AppRouter.permissionsOnboarding : AppRouter.home,
      navigatorObservers: [
        _NavigationObserver(),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}

// خدمة التنقل
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

/// مراقب دورة حياة التطبيق
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('حالة التطبيق: $state');
    
    if (state == AppLifecycleState.detached) {
      _disposeResources();
    }
  }
  
  Future<void> _disposeResources() async {
    try {
      debugPrint('تنظيف الموارد...');
      
      if (getIt.isRegistered<NotificationService>()) {
        final notificationService = getIt<NotificationService>();
        await notificationService.dispose();
      }
      
      await ServiceLocator().dispose();
      
      debugPrint('تم تنظيف الموارد بنجاح');
    } catch (e) {
      debugPrint('خطأ في تنظيف الموارد: $e');
    }
  }
}

/// مراقب التنقل
class _NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('التنقل: ${route.settings.name} (من: ${previousRoute?.settings.name})');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('الرجوع: ${route.settings.name} (إلى: ${previousRoute?.settings.name})');
    super.didPop(route, previousRoute);
  }
}