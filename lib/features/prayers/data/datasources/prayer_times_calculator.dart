import 'package:adhan/adhan.dart';
import 'package:athkar_app/core/infrastructure/services/logging/logger_service.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';


class PrayerTimesCalculator {
  final LoggerService _logger;
  final StorageService _storage;
  
  static const String _methodKey = 'prayer_calculation_method';
  static const String _madhhabKey = 'prayer_madhab';
  
  PrayerTimesCalculator({
    required LoggerService logger,
    required StorageService storage,
  }) : _logger = logger,
       _storage = storage;
  
  Future<PrayerTimes> calculate({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) async {
    try {
      _logger.debug(
        message: 'Calculating prayer times',
        data: {
          'lat': latitude,
          'lng': longitude,
          'date': date.toIso8601String(),
        },
      );
      
      final method = _getCalculationMethod();
      final madhab = _getMadhab();
      
      final params = method.getParameters();
      params.madhab = madhab;
      
      final coordinates = Coordinates(latitude, longitude);
      final prayerTimes = PrayerTimes.today(coordinates, params);
      
      _logger.info(message: 'Prayer times calculated successfully');
      
      return _mapToDomainEntity(prayerTimes, date);
    } catch (e, s) {
      _logger.error(
        message: 'Failed to calculate prayer times',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
  
  CalculationMethod _getCalculationMethod() {
    final savedMethod = _storage.getString(_methodKey) ?? 'muslim_world_league';
    
    switch (savedMethod) {
      case 'egyptian':
        return CalculationMethod.egyptian;
      case 'karachi':
        return CalculationMethod.karachi;
      case 'umm_al_qura':
        return CalculationMethod.umm_al_qura;
      default:
        return CalculationMethod.muslim_world_league;
    }
  }
  
  Madhab _getMadhab() {
    final savedMadhab = _storage.getString(_madhhabKey) ?? 'shafi';
    return savedMadhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
  }
}