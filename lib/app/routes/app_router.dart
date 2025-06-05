// lib/app/routes/app_router.dart
import 'package:flutter/material.dart';
import '../../features/home/screens/home_screen.dart';

class AppRouter {
  // Routes
  static const String initialRoute = '/';
  static const String home = '/';
  static const String prayerTimes = '/prayer-times';
  static const String athkar = '/athkar';
  static const String favorites = '/favorites';
  static const String settingsRoute = '/settings';
  static const String quoteDetails = '/quote-details';



  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    
    debugPrint('توليد مسار لـ: $routeName');
    
    switch (routeName) {
      case home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );
      
      case prayerTimes:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('صفحة مواقيت الصلاة'),
            ),
          ),
        );
        
      case athkar:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('صفحة الأذكار'),
            ),
          ),
        );
        
      case favorites:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('صفحة المفضلة'),
            ),
          ),
        );
        
      case settingsRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('صفحة الإعدادات'),
            ),
          ),
        );
        
      case quoteDetails:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('تفاصيل الاقتباس'),
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