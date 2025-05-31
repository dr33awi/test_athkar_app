// lib/app/routes/app_router.dart
import 'package:flutter/material.dart';

class AppRouter {
  // Basic Routes
  static const String initialRoute = '/';
  static const String home = '/';
  static const String permissionsOnboarding = '/permissions-onboarding';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    
    debugPrint('Generating route for: $routeName');
    
    switch (routeName) {
      case home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Welcome to App'),
            ),
          ),
        );
      
      case permissionsOnboarding:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Permissions Setup'),
            ),
          ),
        );
      
      default:
        debugPrint('Route not found! ${settings.name}');
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
}