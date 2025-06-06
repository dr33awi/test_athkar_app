// lib/features/prayers/prayer_constants.dart

import 'package:flutter/material.dart';

class PrayerConstants {
  PrayerConstants._();
  
  // ألوان الصلوات
  static const Map<String, Color> prayerColors = {
    'fajr': Color(0xFF5C6BC0),
    'sunrise': Color(0xFFFFB74D), 
    'dhuhr': Color(0xFFFFD54F),
    'asr': Color(0xFF66BB6A),
    'maghrib': Color(0xFFAB47BC),
    'isha': Color(0xFF4DB6AC),
  };
  
  // أيقونات الصلوات
  static const Map<String, IconData> prayerIcons = {
    'fajr': Icons.wb_twilight,
    'sunrise': Icons.wb_sunny_outlined,
    'dhuhr': Icons.wb_sunny,
    'asr': Icons.wb_cloudy,
    'maghrib': Icons.nights_stay,
    'isha': Icons.nightlight_round,
  };
  
  // طرق الحساب
  static const Map<String, String> calculationMethods = {
    'muslim_world_league': 'رابطة العالم الإسلامي',
    'egyptian': 'الهيئة المصرية العامة للمساحة',
    'karachi': 'جامعة العلوم الإسلامية - كراتشي',
    'umm_al_qura': 'أم القرى - مكة المكرمة',
    'dubai': 'هيئة الشؤون الإسلامية - دبي',
    'qatar': 'قطر',
    'kuwait': 'الكويت',
    'singapore': 'سنغافورة',
    'turkey': 'تركيا',
    'tehran': 'طهران',
    'north_america': 'أمريكا الشمالية (ISNA)',
  };
  
  // المذاهب
  static const Map<String, String> madhabs = {
    'shafi': 'الشافعي',
    'hanafi': 'الحنفي',
  };
}