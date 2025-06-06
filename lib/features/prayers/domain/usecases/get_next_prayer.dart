// lib/features/prayers/domain/usecases/get_next_prayer.dart

import '../entities/prayer_time.dart';
import '../entities/prayer_times.dart';
import '../repositories/prayer_times_repository.dart';

class GetNextPrayer {
  final PrayerTimesRepository _repository;
  
  GetNextPrayer(this._repository);
  
  Future<PrayerTime?> call({
    required double latitude,
    required double longitude,
  }) async {
    final todayPrayers = await _repository.getTodayPrayerTimes(
      latitude: latitude,
      longitude: longitude,
    );
    
    final now = DateTime.now();
    
    // Find next prayer
    for (final prayer in todayPrayers.prayers) {
      if (prayer.time.isAfter(now) && prayer.id != 'sunrise') {
        return prayer;
      }
    }
    
    // If no prayer left today, get tomorrow's Fajr
    final tomorrowPrayers = await _repository.getPrayerTimes(
      date: DateTime.now().add(const Duration(days: 1)),
      latitude: latitude,
      longitude: longitude,
    );
    
    return tomorrowPrayers.prayers.firstWhere((p) => p.id == 'fajr');
  }
}