import 'package:flutter/material.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/infrastructure/services/logging/logger_service.dart';
import '../../../core/infrastructure/services/notifications/notification_manager.dart';

class PrayerTimesProvider extends ChangeNotifier {
  final GetPrayerTimes _getPrayerTimes;
  final GetNextPrayer _getNextPrayer;
  final SchedulePrayerNotifications _scheduleNotifications;
  final AppErrorHandler _errorHandler;
  final LoggerService _logger;
  
  PrayerTimes? _todayPrayerTimes;
  PrayerTime? _nextPrayer;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  PrayerTimes? get todayPrayerTimes => _todayPrayerTimes;
  PrayerTime? get nextPrayer => _nextPrayer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  
  PrayerTimesProvider({
    required GetPrayerTimes getPrayerTimes,
    required GetNextPrayer getNextPrayer,
    required SchedulePrayerNotifications scheduleNotifications,
    required AppErrorHandler errorHandler,
    required LoggerService logger,
  }) : _getPrayerTimes = getPrayerTimes,
       _getNextPrayer = getNextPrayer,
       _scheduleNotifications = scheduleNotifications,
       _errorHandler = errorHandler,
       _logger = logger;
  
  Future<void> loadTodayPrayerTimes({
    required double latitude,
    required double longitude,
  }) async {
    _setLoading(true);
    
    final result = await _errorHandler.executeOperation(
      () => _getPrayerTimes(
        date: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
      ),
      operationName: 'loadTodayPrayerTimes',
    );
    
    result.fold(
      (failure) {
        _error = _errorHandler.getUserFriendlyMessage(failure);
        _logger.error(
          message: 'Failed to load prayer times',
          error: failure,
        );
      },
      (prayerTimes) {
        _todayPrayerTimes = prayerTimes;
        _error = null;
        _loadNextPrayer();
        _scheduleNotifications(prayerTimes);
      },
    );
    
    _setLoading(false);
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}