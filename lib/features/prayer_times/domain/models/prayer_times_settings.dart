// lib/features/prayer_times/domain/models/prayer_times_settings.dart

/// إعدادات أوقات الصلاة
class PrayerTimesSettings {
  final String calculationMethod;
  final String madhab;
  final double latitude;
  final double longitude;
  final String timezone;
  final bool adjustForHighLatitude;
  final Map<String, int> manualAdjustments;
  final Map<String, bool> notificationSettings;
  final Map<String, int> notificationMinutesBefore;

  const PrayerTimesSettings({
    this.calculationMethod = 'MuslimWorldLeague',
    this.madhab = 'Shafi',
    this.latitude = 24.7136,
    this.longitude = 46.6753,
    this.timezone = 'Asia/Riyadh',
    this.adjustForHighLatitude = false,
    this.manualAdjustments = const {},
    this.notificationSettings = const {},
    this.notificationMinutesBefore = const {},
  });

  Map<String, dynamic> toJson() => {
    'calculationMethod': calculationMethod,
    'madhab': madhab,
    'latitude': latitude,
    'longitude': longitude,
    'timezone': timezone,
    'adjustForHighLatitude': adjustForHighLatitude,
    'manualAdjustments': manualAdjustments,
    'notificationSettings': notificationSettings,
    'notificationMinutesBefore': notificationMinutesBefore,
  };

  factory PrayerTimesSettings.fromJson(Map<String, dynamic> json) {
    return PrayerTimesSettings(
      calculationMethod: json['calculationMethod'] ?? 'MuslimWorldLeague',
      madhab: json['madhab'] ?? 'Shafi',
      latitude: json['latitude'] ?? 24.7136,
      longitude: json['longitude'] ?? 46.6753,
      timezone: json['timezone'] ?? 'Asia/Riyadh',
      adjustForHighLatitude: json['adjustForHighLatitude'] ?? false,
      manualAdjustments: Map<String, int>.from(json['manualAdjustments'] ?? {}),
      notificationSettings: Map<String, bool>.from(json['notificationSettings'] ?? {}),
      notificationMinutesBefore: Map<String, int>.from(json['notificationMinutesBefore'] ?? {}),
    );
  }

  PrayerTimesSettings copyWith({
    String? calculationMethod,
    String? madhab,
    double? latitude,
    double? longitude,
    String? timezone,
    bool? adjustForHighLatitude,
    Map<String, int>? manualAdjustments,
    Map<String, bool>? notificationSettings,
    Map<String, int>? notificationMinutesBefore,
  }) {
    return PrayerTimesSettings(
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      adjustForHighLatitude: adjustForHighLatitude ?? this.adjustForHighLatitude,
      manualAdjustments: manualAdjustments ?? this.manualAdjustments,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      notificationMinutesBefore: notificationMinutesBefore ?? this.notificationMinutesBefore,
    );
  }
}