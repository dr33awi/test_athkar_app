// lib/features/prayers/domain/entities/prayer_calculation_params.dart

class PrayerCalculationParams {
  final String calculationMethod;
  final String madhab;
  final Map<String, int> adjustments;
  final bool highLatitudeRule;
  
  const PrayerCalculationParams({
    required this.calculationMethod,
    required this.madhab,
    this.adjustments = const {},
    this.highLatitudeRule = true,
  });
  
  factory PrayerCalculationParams.fromStorage(Map<String, dynamic> json) {
    return PrayerCalculationParams(
      calculationMethod: json['calculationMethod'] ?? 'muslim_world_league',
      madhab: json['madhab'] ?? 'shafi',
      adjustments: Map<String, int>.from(json['adjustments'] ?? {}),
      highLatitudeRule: json['highLatitudeRule'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'calculationMethod': calculationMethod,
    'madhab': madhab,
    'adjustments': adjustments,
    'highLatitudeRule': highLatitudeRule,
  };
}