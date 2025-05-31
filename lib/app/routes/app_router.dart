// lib/app/routes/app_router.dart
import 'package:flutter/material.dart';

class AppRouter {
  // Route الرئيسي فقط
  static const String initialRoute = '/';
  static const String home = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    
    debugPrint('توليد مسار لـ: $routeName');
    
    switch (routeName) {
      case home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('الصفحة الرئيسية'),
            ),
          ),
        );
        
      default:
        debugPrint('مسار غير موجود! ${settings.name}');
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('لا يوجد طريق للمسار ${settings.name}'),
            ),
          ),
        );
    }
  }
}