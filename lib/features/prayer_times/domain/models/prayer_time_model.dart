// lib/features/prayer_times/domain/models/prayer_time_model.dart
import 'package:flutter/material.dart';

/// نموذج وقت الصلاة
class PrayerTimeModel {
  final String id;
  final String name;
  final String arabicName;
  final String time;
  final DateTime dateTime;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isNotificationEnabled;
  final int notificationMinutesBefore;

  PrayerTimeModel({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.time,
    required this.dateTime,
    required this.icon,
    required this.gradientColors,
    this.isNotificationEnabled = true,
    this.notificationMinutesBefore = 0,
  });

  /// التحقق من مرور وقت الصلاة
  bool get isPassed => DateTime.now().isAfter(dateTime);

  /// التحقق من أن هذه الصلاة هي القادمة
  bool get isNext => !isPassed;

  /// الحصول على الوقت المتبقي
  Duration get timeRemaining {
    if (isPassed) return Duration.zero;
    return dateTime.difference(DateTime.now());
  }

  /// نسخ مع تعديل
  PrayerTimeModel copyWith({
    String? id,
    String? name,
    String? arabicName,
    String? time,
    DateTime? dateTime,
    IconData? icon,
    List<Color>? gradientColors,
    bool? isNotificationEnabled,
    int? notificationMinutesBefore,
  }) {
    return PrayerTimeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      arabicName: arabicName ?? this.arabicName,
      time: time ?? this.time,
      dateTime: dateTime ?? this.dateTime,
      icon: icon ?? this.icon,
      gradientColors: gradientColors ?? this.gradientColors,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      notificationMinutesBefore: notificationMinutesBefore ?? this.notificationMinutesBefore,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'arabicName': arabicName,
    'time': time,
    'dateTime': dateTime.toIso8601String(),
    'isNotificationEnabled': isNotificationEnabled,
    'notificationMinutesBefore': notificationMinutesBefore,
  };

  /// إنشاء من JSON
  factory PrayerTimeModel.fromJson(Map<String, dynamic> json) {
    return PrayerTimeModel(
      id: json['id'],
      name: json['name'],
      arabicName: json['arabicName'],
      time: json['time'],
      dateTime: DateTime.parse(json['dateTime']),
      icon: _getIconForPrayer(json['name']),
      gradientColors: _getGradientForPrayer(json['name']),
      isNotificationEnabled: json['isNotificationEnabled'] ?? true,
      notificationMinutesBefore: json['notificationMinutesBefore'] ?? 0,
    );
  }

  /// الحصول على الأيقونة حسب الصلاة
  static IconData _getIconForPrayer(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return Icons.dark_mode;
      case 'sunrise':
        return Icons.wb_sunny_outlined;
      case 'dhuhr':
        return Icons.light_mode;
      case 'asr':
        return Icons.wb_cloudy;
      case 'maghrib':
        return Icons.wb_twilight;
      case 'isha':
        return Icons.bedtime;
      default:
        return Icons.access_time;
    }
  }

  /// الحصول على التدرج اللوني حسب الصلاة
  static List<Color> _getGradientForPrayer(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return [const Color(0xFF1A237E), const Color(0xFF3949AB)];
      case 'sunrise':
        return [const Color(0xFFFF6F00), const Color(0xFFFFB300)];
      case 'dhuhr':
        return [const Color(0xFFFF6F00), const Color(0xFFFFCA28)];
      case 'asr':
        return [const Color(0xFF00897B), const Color(0xFF4DB6AC)];
      case 'maghrib':
        return [const Color(0xFFE65100), const Color(0xFFFF6E40)];
      case 'isha':
        return [const Color(0xFF4A148C), const Color(0xFF7B1FA2)];
      default:
        return [const Color(0xFF0B8457), const Color(0xFF1FA06D)];
    }
  }
}