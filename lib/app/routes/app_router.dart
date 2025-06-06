// lib/app/routes/app_router.dart
import 'package:athkar_app/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import '../../app/themes/app_theme.dart';

class AppRouter {
  // Main Routes
  static const String initialRoute = '/';
  static const String home = '/';
  static const String prayerTimes = '/prayer-times';
  static const String athkar = '/athkar';
  static const String quran = '/quran';
  static const String qibla = '/qibla';
  static const String tasbih = '/tasbih';
  static const String dua = '/dua';
  
  // Feature Routes
  static const String favorites = '/favorites';
  static const String settings = '/settings';
  static const String progress = '/progress';
  static const String achievements = '/achievements';
  static const String reminderSettings = '/reminder-settings';
  static const String notificationSettings = '/notification-settings';
  
  // Detail Routes
  static const String athkarDetails = '/athkar-details';
  static const String quranReader = '/quran-reader';
  static const String duaDetails = '/dua-details';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    debugPrint('AppRouter: Generating route for ${settings.name}');
    
    switch (settings.name) {
      // Main Screen
      case home:
        return _fadeRoute(const HomeScreen(), settings);
      
      // Main Features
      case prayerTimes:
        return _slideRoute(_buildComingSoonScreen('مواقيت الصلاة'), settings);
        
      case athkar:
        return _slideRoute(_buildComingSoonScreen('الأذكار'), settings);
        
      case quran:
        return _slideRoute(_buildComingSoonScreen('القرآن الكريم'), settings);
        
      case qibla:
        return _slideRoute(_buildComingSoonScreen('اتجاه القبلة'), settings);
        
      case tasbih:
        return _slideRoute(_buildComingSoonScreen('التسبيح'), settings);
        
      case dua:
        return _slideRoute(_buildComingSoonScreen('الأدعية'), settings);
        
      // Feature Routes
      case favorites:
        return _slideRoute(_buildComingSoonScreen('المفضلة'), settings);
        

        
      case progress:
        return _slideRoute(_buildComingSoonScreen('التقدم اليومي'), settings);
        
      case achievements:
        return _slideRoute(_buildComingSoonScreen('الإنجازات'), settings);
        
      case reminderSettings:
        return _slideRoute(_buildComingSoonScreen('إعدادات التذكيرات'), settings);
        
      case notificationSettings:
        return _slideRoute(_buildComingSoonScreen('إعدادات الإشعارات'), settings);
        
      // Default
      default:
        return _fadeRoute(_buildNotFoundScreen(settings.name), settings);
    }
  }

  // Route Builders
  static Route<T> _fadeRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: ThemeConstants.durationNormal,
      reverseTransitionDuration: ThemeConstants.durationFast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  static Route<T> _slideRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: ThemeConstants.durationNormal,
      reverseTransitionDuration: ThemeConstants.durationFast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  // Screen Builders
  static Widget _buildComingSoonScreen(String title) {
    return Scaffold(
      appBar: CustomAppBar.simple(title: title),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: ThemeConstants.lightTextHint,
            ),
            ThemeConstants.space4.h,
            Text(
              'قريباً',
              style: AppTextStyles.h3.copyWith(
                color: ThemeConstants.lightTextSecondary,
              ),
            ),
            ThemeConstants.space2.h,
            Text(
              'هذه الميزة قيد التطوير',
              style: AppTextStyles.body1.copyWith(
                color: ThemeConstants.lightTextHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildNotFoundScreen(String? routeName) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: ThemeConstants.error,
            ),
            ThemeConstants.space4.h,
            Text(
              'الصفحة غير موجودة',
              style: AppTextStyles.h3,
            ),
            ThemeConstants.space2.h,
            Text(
              'لم نتمكن من العثور على الصفحة المطلوبة',
              style: AppTextStyles.body1.copyWith(
                color: ThemeConstants.lightTextSecondary,
              ),
            ),
            if (routeName != null) ...[
              ThemeConstants.space2.h,
              Text(
                routeName,
                style: AppTextStyles.caption.copyWith(
                  color: ThemeConstants.lightTextHint,
                ),
              ),
            ],
            ThemeConstants.space6.h,
            AppButton.primary(
              text: 'العودة للرئيسية',
              onPressed: () => Navigator.of(_navigatorKey.currentContext!)
                  .pushNamedAndRemoveUntil(home, (route) => false),
              icon: Icons.home,
            ),
          ],
        ),
      ),
    );
  }

  // Navigator key for global navigation
  static final GlobalKey<NavigatorState> _navigatorKey = 
      GlobalKey<NavigatorState>();
  
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
}