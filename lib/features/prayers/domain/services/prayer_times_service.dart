// lib/features/prayers/domain/services/prayer_times_service.dart

import 'package:athkar_app/features/prayers/domain/entities/prayer_times.dart';


/// Prayer times service interface
abstract class PrayerTimesService {
  /// Get prayer times for a specific date and location
  Future<List<PrayerTime>> getPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    String? calculationMethod,
    String? timezone,
  });
  
  /// Get next prayer time
  Future<PrayerTime?> getNextPrayer({
    required double latitude,
    required double longitude,
  });
  
  /// Get prayer times for today
  Future<List<PrayerTime>> getTodayPrayerTimes({
    required double latitude,
    required double longitude,
  });
  
  /// Get prayer times for the week
  Future<Map<DateTime, List<PrayerTime>>> getWeeklyPrayerTimes({
    required double latitude,
    required double longitude,
  });
  
  /// Get prayer times for the month
  Future<Map<DateTime, List<PrayerTime>>> getMonthlyPrayerTimes({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
  });
  
  /// Calculate prayer time adjustments
  Map<String, int> calculateAdjustments({
    int? fajrOffset,
    int? dhuhrOffset,
    int? asrOffset,
    int? maghribOffset,
    int? ishaOffset,
  });
  
  /// Get available calculation methods
  List<CalculationMethod> getAvailableCalculationMethods();
  
  /// Validate location coordinates
  bool isValidLocation(double latitude, double longitude);
}