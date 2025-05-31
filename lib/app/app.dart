// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// استيراد الثيمات
import 'themes/app_theme.dart';
import '../core/constants/app_constants.dart';

class AthkarApp extends StatelessWidget {
  final bool isDarkMode;
  final String language;
  
  const AthkarApp({
    super.key,
    this.isDarkMode = false,
    this.language = 'ar',
  });

  @override
  Widget build(BuildContext context) {
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
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Athkar App'),
        ),
        body: const Center(
          child: Text(
            'مرحبا بك في تطبيق الأذكار',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}