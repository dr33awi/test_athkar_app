// lib/core/infrastructure/services/timezone/timezone_service_impl.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';
import '../logging/logger_service.dart';
import 'timezone_service.dart';

/// Implementation of timezone service
class TimezoneServiceImpl implements TimezoneService {
  final LoggerService _logger;
  
  bool _isInitialized = false;
  String _currentTimeZoneId = 'UTC';
  tz.Location _currentLocation = tz.UTC;
  
  TimezoneServiceImpl({required LoggerService logger}) : _logger = logger;
  
  @override
  Future<void> initializeTimeZones() async {
    if (_isInitialized) {
      _logger.debug(message: 'Timezones already initialized');
      return;
    }
    
    try {
      // Initialize timezone database
      tz.initializeTimeZones();
      
      // Get device timezone
      String timeZoneName;
      try {
        timeZoneName = await FlutterTimezone.getLocalTimezone();
      } catch (e) {
        _logger.warning(
          message: 'Failed to get local timezone, using UTC',
          data: {'error': e.toString()}
        );
        timeZoneName = 'UTC';
      }
      
      // Set local timezone
      _currentTimeZoneId = timeZoneName;
      _currentLocation = tz.getLocation(timeZoneName);
      tz.setLocalLocation(_currentLocation);
      
      _isInitialized = true;
      
      _logger.info(
        message: 'Timezones initialized',
        data: {'local_timezone': timeZoneName}
      );
    } catch (e, s) {
      _logger.error(
        message: 'Error initializing timezones',
        error: e,
        stackTrace: s
      );
      
      // Fallback to UTC
      _currentTimeZoneId = 'UTC';
      _currentLocation = tz.UTC;
      tz.setLocalLocation(tz.UTC);
      _isInitialized = true;
    }
  }
  
  @override
  tz.Location? getLocation(String timeZoneId) {
    _ensureInitialized();
    
    try {
      return tz.getLocation(timeZoneId);
    } catch (e) {
      _logger.warning(
        message: 'Timezone not found',
        data: {'timezone_id': timeZoneId, 'error': e.toString()}
      );
      return null;
    }
  }
  
  @override
  tz.TZDateTime getDateTimeInTimeZone(DateTime dateTime, String timeZoneId) {
    _ensureInitialized();
    
    final location = getLocation(timeZoneId);
    if (location == null) {
      _logger.warning(
        message: 'Invalid timezone, using current location',
        data: {'timezone_id': timeZoneId}
      );
      return tz.TZDateTime.from(dateTime, _currentLocation);
    }
    
    return tz.TZDateTime.from(dateTime, location);
  }
  
  @override
  tz.TZDateTime getLocalTZDateTime(DateTime dateTime) {
    _ensureInitialized();
    return tz.TZDateTime.from(dateTime, _currentLocation);
  }
  
  @override
  List<String> getAvailableTimeZoneIds() {
    _ensureInitialized();
    return tz.timeZoneDatabase.locations.keys.toList()..sort();
  }
  
  @override
  String getCurrentTimeZoneId() {
    _ensureInitialized();
    return _currentTimeZoneId;
  }
  
  @override
  void setDefaultTimeZone(String timeZoneId) {
    _ensureInitialized();
    
    final location = getLocation(timeZoneId);
    if (location == null) {
      _logger.error(
        message: 'Cannot set invalid timezone',
        error: 'Timezone not found: $timeZoneId'
      );
      return;
    }
    
    _currentTimeZoneId = timeZoneId;
    _currentLocation = location;
    tz.setLocalLocation(location);
    
    _logger.info(
      message: 'Default timezone updated',
      data: {'timezone_id': timeZoneId}
    );
  }
  
  @override
  tz.TZDateTime convertBetweenTimeZones(
    tz.TZDateTime dateTime,
    String fromTimeZoneId,
    String toTimeZoneId,
  ) {
    _ensureInitialized();
    
    final toLocation = getLocation(toTimeZoneId);
    if (toLocation == null) {
      _logger.warning(
        message: 'Invalid target timezone',
        data: {'timezone_id': toTimeZoneId}
      );
      return dateTime;
    }
    
    // Convert to UTC first, then to target timezone
    final utcTime = dateTime.toUtc();
    return tz.TZDateTime.from(utcTime, toLocation);
  }
  
  @override
  Duration getTimeZoneOffset(String timeZoneId) {
    _ensureInitialized();
    
    final location = getLocation(timeZoneId);
    if (location == null) {
      return Duration.zero;
    }
    
    final now = tz.TZDateTime.now(location);
    return now.timeZoneOffset;
  }
  
  @override
  bool timeZoneExists(String timeZoneId) {
    _ensureInitialized();
    return tz.timeZoneDatabase.locations.containsKey(timeZoneId);
  }
  
  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('TimezoneService not initialized. Call initializeTimeZones() first.');
    }
  }
  
  /// Get user-friendly timezone name
  String getTimeZoneDisplayName(String timeZoneId) {
    // Convert timezone ID to display name
    // e.g., "America/New_York" -> "New York"
    return timeZoneId.split('/').last.replaceAll('_', ' ');
  }
  
  /// Get timezone abbreviation (e.g., EST, PST)
  String getTimeZoneAbbreviation(String timeZoneId) {
    final location = getLocation(timeZoneId);
    if (location == null) return '';
    
    final now = tz.TZDateTime.now(location);
    return now.timeZoneName;
  }
} getCurrentLocation() {
    _ensureInitialized();
    return _currentLocation;
  }
  
  @override
  tz.Location