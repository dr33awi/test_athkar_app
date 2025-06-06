// lib/features/prayers/data/datasources/prayer_times_local_datasource.dart

import 'package:adhan/adhan.dart';

import '../../../../core/infrastructure/services/storage/storage_service.dart';
import '../../domain/entities/prayer_times.dart';

abstract class PrayerTimesLocalDataSource {
  Future<PrayerTimes?> getCachedPrayerTimes(DateTime date);
  Future<void> cachePrayerTimes(PrayerTimes prayerTimes);
  Future<void> clearCache();
}

class PrayerTimesLocalDataSourceImpl implements PrayerTimesLocalDataSource {
  final StorageService _storage;
  
  static const String _cacheKeyPrefix = 'prayer_times_';
  static const Duration _cacheValidity = Duration(days: 1);
  
  PrayerTimesLocalDataSourceImpl({
    required StorageService storage,
  }) : _storage = storage;
  
  @override
  Future<PrayerTimes?> getCachedPrayerTimes(DateTime date) async {
    final key = _getCacheKey(date);
    final cached = _storage.getMap(key);
    
    if (cached == null) return null;
    
    final cacheTime = DateTime.parse(cached['cacheTime']);
    if (DateTime.now().difference(cacheTime) > _cacheValidity) {
      await _storage.remove(key);
      return null;
    }
    
    return PrayerTimes.fromJson(cached['data']);
  }
  
  @override
  Future<void> cachePrayerTimes(PrayerTimes prayerTimes) async {
    final key = _getCacheKey(prayerTimes.date);
    await _storage.setMap(key, {
      'data': prayerTimes.toJson(),
      'cacheTime': DateTime.now().toIso8601String(),
    });
  }
  
  @override
  Future<void> clearCache() async {
    final keys = _storage.getKeys()
        .where((key) => key.startsWith(_cacheKeyPrefix))
        .toList();
    
    for (final key in keys) {
      await _storage.remove(key);
    }
  }
  
  String _getCacheKey(DateTime date) {
    return '$_cacheKeyPrefix${date.year}_${date.month}_${date.day}';
  }
}