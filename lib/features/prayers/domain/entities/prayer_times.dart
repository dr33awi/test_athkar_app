// lib/features/prayers/domain/entities/prayer_time.dart

/// Prayer time entity
class PrayerTime {
  final String id;
  final String name;
  final String englishName;
  final DateTime time;
  final bool isNotificationEnabled;
  final int? notificationOffset; // Minutes before/after prayer time
  
  PrayerTime({
    required this.id,
    required this.name,
    required this.englishName,
    required this.time,
    required this.isNotificationEnabled,
    this.notificationOffset,
  });
  
  /// Check if prayer time has passed
  bool get hasPassed => DateTime.now().isAfter(time);
  
  /// Get time remaining until prayer
  Duration get timeRemaining => time.difference(DateTime.now());
  
  /// Format time as string (HH:mm)
  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  /// Copy with modifications
  PrayerTime copyWith({
    String? id,
    String? name,
    String? englishName,
    DateTime? time,
    bool? isNotificationEnabled,
    int? notificationOffset,
  }) {
    return PrayerTime(
      id: id ?? this.id,
      name: name ?? this.name,
      englishName: englishName ?? this.englishName,
      time: time ?? this.time,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      notificationOffset: notificationOffset ?? this.notificationOffset,
    );
  }
}

/// Calculation method for prayer times
class CalculationMethod {
  final String id;
  final String name;
  final String englishName;
  final String? description;
  
  CalculationMethod({
    required this.id,
    required this.name,
    required this.englishName,
    this.description,
  });
}