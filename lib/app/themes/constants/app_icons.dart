// lib/app/themes/constants/app_icons.dart

import 'package:flutter/material.dart';

/// أيقونات تطبيق الأذكار
class AppIcons {
  AppIcons._();

  // أيقونات الصلاة
  static const IconData prayer = Icons.mosque;
  static const IconData prayerTime = Icons.access_time;
  static const IconData qibla = Icons.explore;
  static const IconData adhan = Icons.volume_up;

  // أيقونات الأذكار
  static const IconData athkar = Icons.menu_book;
  static const IconData morningAthkar = Icons.wb_sunny;
  static const IconData eveningAthkar = Icons.nights_stay;
  static const IconData sleepAthkar = Icons.bedtime;
  static const IconData prayerAthkar = Icons.auto_awesome;
  static const IconData dailyAthkar = Icons.today;

  // أيقونات التسبيح
  static const IconData tasbih = Icons.radio_button_checked;
  static const IconData counter = Icons.add_circle_outline;
  static const IconData reset = Icons.refresh;
  static const IconData vibration = Icons.vibration;

  // أيقونات القرآن
  static const IconData quran = Icons.book;
  static const IconData bookmark = Icons.bookmark;
  static const IconData lastRead = Icons.history;

  // أيقونات الإعدادات
  static const IconData settings = Icons.settings;
  static const IconData language = Icons.language;
  static const IconData theme = Icons.palette;
  static const IconData notifications = Icons.notifications;
  static const IconData location = Icons.location_on;
  static const IconData about = Icons.info;

  // أيقونات الحالة
  static const IconData favorite = Icons.favorite;
  static const IconData favoriteOutline = Icons.favorite_border;
  static const IconData complete = Icons.check_circle;
  static const IconData incomplete = Icons.radio_button_unchecked;
  static const IconData achievement = Icons.emoji_events;

  // أيقونات الإجراءات
  static const IconData share = Icons.share;
  static const IconData copy = Icons.content_copy;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete;
  static const IconData add = Icons.add;
  static const IconData remove = Icons.remove;
  static const IconData close = Icons.close;
  static const IconData back = Icons.arrow_back_ios;
  static const IconData menu = Icons.menu;

  // أيقونات التنقل
  static const IconData home = Icons.home;
  static const IconData search = Icons.search;
  static const IconData more = Icons.more_horiz;

  // أيقونات خاصة
  static const IconData dua = Icons.pan_tool;
  static const IconData calendar = Icons.calendar_today;
  static const IconData reminder = Icons.alarm;
  static const IconData statistics = Icons.bar_chart;

  // دوال مساعدة
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'morning':
      case 'صباح':
        return morningAthkar;
      case 'evening':
      case 'مساء':
        return eveningAthkar;
      case 'sleep':
      case 'نوم':
        return sleepAthkar;
      case 'prayer':
      case 'صلاة':
        return prayerAthkar;
      case 'daily':
      case 'يومي':
        return dailyAthkar;
      case 'quran':
      case 'قرآن':
        return quran;
      case 'dua':
      case 'دعاء':
        return dua;
      default:
        return athkar;
    }
  }

  static IconData getPrayerIcon(String prayer) {
    switch (prayer.toLowerCase()) {
      case 'fajr':
      case 'الفجر':
        return Icons.brightness_5;
      case 'dhuhr':
      case 'الظهر':
        return Icons.wb_sunny;
      case 'asr':
      case 'العصر':
        return Icons.wb_twighlight;
      case 'maghrib':
      case 'المغرب':
        return Icons.wb_twilight;
      case 'isha':
      case 'العشاء':
        return Icons.nightlight_round;
      default:
        return prayerTime;
    }
  }
}