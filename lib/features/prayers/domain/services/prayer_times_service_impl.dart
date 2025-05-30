// lib/features/prayers/infrastructure/services/prayer_times_service_impl.dart

import 'package:adhan/adhan.dart' as adhan;
import 'package:athkar_app/features/prayers/domain/entities/prayer_times.dart';
import '../../../../core/infrastructure/services/logging/logger_service.dart';
import '../../../../core/infrastructure/services/storage/storage_service.dart';
import '../../domain/services/prayer_times_service.dart';

/// Implementation of prayer times service using Adhan library
class PrayerTimesServiceImpl implements PrayerTimesService {
  final LoggerService? _logger;
  final StorageService _storageService;
  
  static const String _calculationMethodKey = 'prayer_calculation_method';
  static const String _adjustmentsKey = 'prayer_time_adjustments';
  
  PrayerTimesServiceImpl({
    LoggerService? logger,
    required StorageService storageService,
  })  : _logger = logger,
        _storageService = storageService;
  
  @override
  Future<List<PrayerTime>> getPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    String? calculationMethod,
    String? timezone,
  }) async {
    try {
      _logger?.debug(
        message: 'Getting prayer times',
        data: {
          'date': date.toIso8601String(),
          'latitude': latitude,
          'longitude': longitude,
          'method': calculationMethod,
        },
      );
      
      // Create coordinates
      final coordinates = adhan.Coordinates(latitude, longitude);
      
      // Get calculation parameters
      final params = _getCalculationParameters(calculationMethod);
      
      // Apply saved adjustments
      final adjustments = _getSavedAdjustments();
      params.adjustments.fajr = adjustments['fajr'] ?? 0;
      params.adjustments.sunrise = adjustments['sunrise'] ?? 0;
      params.adjustments.dhuhr = adjustments['dhuhr'] ?? 0;
      params.adjustments.asr = adjustments['asr'] ?? 0;
      params.adjustments.maghrib = adjustments['maghrib'] ?? 0;
      params.adjustments.isha = adjustments['isha'] ?? 0;
      
      // Calculate prayer times
      final prayerTimes = adhan.PrayerTimes.today(coordinates, params);
      
      // Convert to our domain entities
      final prayers = [
        PrayerTime(
          id: 'fajr',
          name: 'الفجر',
          englishName: 'Fajr',
          time: prayerTimes.fajr!,
          isNotificationEnabled: true,
        ),
        PrayerTime(
          id: 'sunrise',
          name: 'الشروق',
          englishName: 'Sunrise',
          time: prayerTimes.sunrise!,
          isNotificationEnabled: false,
        ),
        PrayerTime(
          id: 'dhuhr',
          name: 'الظهر',
          englishName: 'Dhuhr',
          time: prayerTimes.dhuhr!,
          isNotificationEnabled: true,
        ),
        PrayerTime(
          id: 'asr',
          name: 'العصر',
          englishName: 'Asr',
          time: prayerTimes.asr!,
          isNotificationEnabled: true,
        ),
        PrayerTime(
          id: 'maghrib',
          name: 'المغرب',
          englishName: 'Maghrib',
          time: prayerTimes.maghrib!,
          isNotificationEnabled: true,
        ),
        PrayerTime(
          id: 'isha',
          name: 'العشاء',
          englishName: 'Isha',
          time: prayerTimes.isha!,
          isNotificationEnabled: true,
        ),
      ];
      
      _logger?.info(
        message: 'Prayer times calculated successfully',
        data: {'count': prayers.length},
      );
      
      return prayers;
    } catch (e, s) {
      _logger?.error(
        message: 'Error calculating prayer times',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
  
  @override
  Future<PrayerTime?> getNextPrayer({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final now = DateTime.now();
      final todayPrayers = await getTodayPrayerTimes(
        latitude: latitude,
        longitude: longitude,
      );
      
      // Find next prayer
      for (final prayer in todayPrayers) {
        if (prayer.time.isAfter(now) && prayer.id != 'sunrise') {
          return prayer;
        }
      }
      
      // If no prayer left today, get tomorrow's Fajr
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowPrayers = await getPrayerTimes(
        date: tomorrow,
        latitude: latitude,
        longitude: longitude,
      );
      
      return tomorrowPrayers.firstWhere((p) => p.id == 'fajr');
    } catch (e) {
      _logger?.error(
        message: 'Error getting next prayer',
        error: e,
      );
      return null;
    }
  }
  
  @override
  Future<List<PrayerTime>> getTodayPrayerTimes({
    required double latitude,
    required double longitude,
  }) async {
    return getPrayerTimes(
      date: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
    );
  }
  
  @override
  Future<Map<DateTime, List<PrayerTime>>> getWeeklyPrayerTimes({
    required double latitude,
    required double longitude,
  }) async {
    final weeklyTimes = <DateTime, List<PrayerTime>>{};
    final startDate = DateTime.now();
    
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final prayers = await getPrayerTimes(
        date: date,
        latitude: latitude,
        longitude: longitude,
      );
      weeklyTimes[date] = prayers;
    }
    
    return weeklyTimes;
  }
  
  @override
  Future<Map<DateTime, List<PrayerTime>>> getMonthlyPrayerTimes({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
  }) async {
    final monthlyTimes = <DateTime, List<PrayerTime>>{};
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final prayers = await getPrayerTimes(
        date: date,
        latitude: latitude,
        longitude: longitude,
      );
      monthlyTimes[date] = prayers;
    }
    
    return monthlyTimes;
  }
  
  @override
  Map<String, int> calculateAdjustments({
    int? fajrOffset,
    int? dhuhrOffset,
    int? asrOffset,
    int? maghribOffset,
    int? ishaOffset,
  }) {
    final adjustments = <String, int>{
      'fajr': fajrOffset ?? 0,
      'dhuhr': dhuhrOffset ?? 0,
      'asr': asrOffset ?? 0,
      'maghrib': maghribOffset ?? 0,
      'isha': ishaOffset ?? 0,
    };
    
    // Save adjustments
    _storageService.setMap(_adjustmentsKey, adjustments);
    
    return adjustments;
  }
  
  @override
  List<CalculationMethod> getAvailableCalculationMethods() {
    return [
      CalculationMethod(
        id: 'muslim_world_league',
        name: 'رابطة العالم الإسلامي',
        englishName: 'Muslim World League',
      ),
      CalculationMethod(
        id: 'egyptian',
        name: 'الهيئة المصرية العامة للمساحة',
        englishName: 'Egyptian General Authority of Survey',
      ),
      CalculationMethod(
        id: 'karachi',
        name: 'جامعة العلوم الإسلامية، كراتشي',
        englishName: 'University of Islamic Sciences, Karachi',
      ),
      CalculationMethod(
        id: 'umm_al_qura',
        name: 'جامعة أم القرى، مكة',
        englishName: 'Umm Al-Qura University, Makkah',
      ),
      CalculationMethod(
        id: 'dubai',
        name: 'دائرة الشؤون الإسلامية والعمل الخيري بدبي',
        englishName: 'Dubai',
      ),
      CalculationMethod(
        id: 'qatar',
        name: 'قطر',
        englishName: 'Qatar',
      ),
      CalculationMethod(
        id: 'kuwait',
        name: 'الكويت',
        englishName: 'Kuwait',
      ),
      CalculationMethod(
        id: 'singapore',
        name: 'سنغافورة',
        englishName: 'Singapore',
      ),
      CalculationMethod(
        id: 'north_america',
        name: 'أمريكا الشمالية',
        englishName: 'Islamic Society of North America',
      ),
    ];
  }
  
  @override
  bool isValidLocation(double latitude, double longitude) {
    return latitude >= -90 && 
           latitude <= 90 && 
           longitude >= -180 && 
           longitude <= 180;
  }
  
  // Private helper methods
  
  adhan.CalculationParameters _getCalculationParameters(String? method) {
    final savedMethod = method ?? _storageService.getString(_calculationMethodKey);
    
    switch (savedMethod) {
      case 'egyptian':
        return adhan.CalculationMethod.egyptian.getParameters();
      case 'karachi':
        return adhan.CalculationMethod.karachi.getParameters();
      case 'umm_al_qura':
        return adhan.CalculationMethod.umm_al_qura.getParameters();
      case 'dubai':
        return adhan.CalculationMethod.dubai.getParameters();
      case 'qatar':
        return adhan.CalculationMethod.qatar.getParameters();
      case 'kuwait':
        return adhan.CalculationMethod.kuwait.getParameters();
      case 'singapore':
        return adhan.CalculationMethod.singapore.getParameters();
      case 'north_america':
        return adhan.CalculationMethod.north_america.getParameters();
      case 'muslim_world_league':
      default:
        return adhan.CalculationMethod.muslim_world_league.getParameters();
    }
  }
  
  Map<String, int> _getSavedAdjustments() {
    final saved = _storageService.getMap(_adjustmentsKey);
    if (saved == null) return {};
    
    return saved.map((key, value) => MapEntry(key, value as int));
  }
}