// lib/core/infrastructure/services/timezone/timezone_service.dart

import 'package:timezone/timezone.dart' as tz;

/// Service for handling timezone operations
abstract class TimezoneService {
  /// Initialize timezone database
  Future<void> initializeTimeZones();
  
  /// Get current timezone location
  tz.Location getCurrentLocation();
  
  /// Get timezone location by ID
  tz.Location? getLocation(String timeZoneId);
  
  /// Convert DateTime to TZDateTime in specific timezone
  tz.TZDateTime getDateTimeInTimeZone(DateTime dateTime, String timeZoneId);
  
  /// Convert DateTime to local TZDateTime
  tz.TZDateTime getLocalTZDateTime(DateTime dateTime);
  
  /// Get list of available timezone IDs
  List<String> getAvailableTimeZoneIds();
  
  /// Get current timezone ID
  String getCurrentTimeZoneId();
  
  /// Set default timezone
  void setDefaultTimeZone(String timeZoneId);
  
  /// Convert TZDateTime between timezones
  tz.TZDateTime convertBetweenTimeZones(
    tz.TZDateTime dateTime,
    String fromTimeZoneId,
    String toTimeZoneId,
  );
  
  /// Get timezone offset for a specific timezone
  Duration getTimeZoneOffset(String timeZoneId);
  
  /// Check if timezone exists
  bool timeZoneExists(String timeZoneId);
  
  /// Get user-friendly timezone name
  String getTimeZoneDisplayName(String timeZoneId);
  
  /// Get timezone abbreviation (e.g., EST, PST)
  String getTimeZoneAbbreviation(String timeZoneId);
  
  /// Get timezones by offset
  List<String> getTimeZonesByOffset(Duration offset);
  
  /// Search timezones by name
  List<String> searchTimeZones(String query);
}