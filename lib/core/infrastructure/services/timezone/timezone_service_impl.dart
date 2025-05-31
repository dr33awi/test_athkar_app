// lib/core/infrastructure/services/timezone/timezone_service_impl.dart
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../logging/logger_service.dart';
import 'timezone_service.dart';

/// Implementation of timezone service
class TimezoneServiceImpl implements TimezoneService {
  final LoggerService _logger;
  
  bool _isInitialized = false;
  String _currentTimeZoneId = 'UTC';
  tz.Location _currentLocation = tz.UTC;
  
  // Cache for performance
  final Map<String, tz.Location> _locationCache = {};
  final Map<String, String> _displayNameCache = {};
  
  TimezoneServiceImpl({required LoggerService logger}) : _logger = logger;
  

  @override
  Future<void> initializeTimeZones() async {
    if (_isInitialized) {
      _logger.debug(message: 'Timezones already initialized');
      return;
    }
    
    try {
      _logger.info(message: 'Initializing timezone database...');
      
      // Initialize timezone database FIRST
      tz.initializeTimeZones();
      
      // Mark as initialized immediately after tz initialization
      _isInitialized = true;
      
      // Get device timezone
      String timeZoneName;
      try {
        timeZoneName = await FlutterTimezone.getLocalTimezone();
        _logger.debug(
          message: 'Device timezone detected',
          data: {'timezone': timeZoneName},
        );
      } catch (e) {
        _logger.warning(
          message: 'Failed to get local timezone, using UTC',
          data: {'error': e.toString()}
        );
        timeZoneName = 'UTC';
      }
      
      // Validate and set timezone (now we can use timeZoneExists)
      if (!timeZoneExists(timeZoneName)) {
        _logger.warning(
          message: 'Invalid timezone detected, using UTC',
          data: {'detected': timeZoneName},
        );
        timeZoneName = 'UTC';
      }
      
      // Set local timezone
      _currentTimeZoneId = timeZoneName;
      _currentLocation = tz.getLocation(timeZoneName);
      tz.setLocalLocation(_currentLocation);
      
      _isInitialized = true;
      
      _logger.info(
        message: 'Timezones initialized successfully',
        data: {
          'local_timezone': timeZoneName,
          'total_timezones': tz.timeZoneDatabase.locations.length,
        }
      );
      
      _logger.logEvent('timezone_initialized', parameters: {
        'timezone': timeZoneName,
        'device_locale': WidgetsBinding.instance.platformDispatcher.locale.toString(),
      });
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
      
      throw Exception('Failed to initialize timezones: $e');
    }
  }
  
  @override
  tz.Location getCurrentLocation() {
    _ensureInitialized();
    return _currentLocation;
  }
  
  @override
  tz.Location? getLocation(String timeZoneId) {
    _ensureInitialized();
    
    // Check cache first
    if (_locationCache.containsKey(timeZoneId)) {
      return _locationCache[timeZoneId];
    }
    
    try {
      final location = tz.getLocation(timeZoneId);
      _locationCache[timeZoneId] = location;
      return location;
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
      throw ArgumentError('Invalid timezone: $timeZoneId');
    }
    
    _currentTimeZoneId = timeZoneId;
    _currentLocation = location;
    tz.setLocalLocation(location);
    
    _logger.info(
      message: 'Default timezone updated',
      data: {'timezone_id': timeZoneId}
    );
    
    _logger.logEvent('timezone_changed', parameters: {
      'new_timezone': timeZoneId,
      'offset_hours': location.currentTimeZone.offset ~/ 3600000,
    });
  }
  
  @override
  tz.TZDateTime convertBetweenTimeZones(
    tz.TZDateTime dateTime,
    String fromTimeZoneId,
    String toTimeZoneId,
  ) {
    _ensureInitialized();
    
    if (fromTimeZoneId == toTimeZoneId) {
      return dateTime;
    }
    
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
  
  @override
  String getTimeZoneDisplayName(String timeZoneId) {
    // Check cache
    if (_displayNameCache.containsKey(timeZoneId)) {
      return _displayNameCache[timeZoneId]!;
    }
    
    // Generate display name
    String displayName;
    
    if (timeZoneId == 'UTC') {
      displayName = 'Coordinated Universal Time (UTC)';
    } else {
      // Convert timezone ID to display name
      // e.g., "America/New_York" -> "New York"
      // e.g., "Asia/Dubai" -> "Dubai"
      final parts = timeZoneId.split('/');
      final city = parts.last.replaceAll('_', ' ');
      
      // Add region if it provides context
      if (parts.length > 1 && !city.contains(parts[0])) {
        final region = _formatRegion(parts[0]);
        displayName = '$city ($region)';
      } else {
        displayName = city;
      }
    }
    
    _displayNameCache[timeZoneId] = displayName;
    return displayName;
  }
  
  String _formatRegion(String region) {
    switch (region) {
      case 'America':
        return 'Americas';
      case 'Asia':
        return 'Asia';
      case 'Africa':
        return 'Africa';
      case 'Europe':
        return 'Europe';
      case 'Australia':
        return 'Australia';
      case 'Pacific':
        return 'Pacific';
      case 'Indian':
        return 'Indian Ocean';
      case 'Atlantic':
        return 'Atlantic';
      case 'Arctic':
        return 'Arctic';
      case 'Antarctica':
        return 'Antarctica';
      default:
        return region;
    }
  }
  
  @override
  String getTimeZoneAbbreviation(String timeZoneId) {
    final location = getLocation(timeZoneId);
    if (location == null) return '';
    
    final now = tz.TZDateTime.now(location);
    return now.timeZoneName;
  }
  
  @override
  List<String> getTimeZonesByOffset(Duration offset) {
    _ensureInitialized();
    
    final offsetMillis = offset.inMilliseconds;
    final results = <String>[];
    
    for (final entry in tz.timeZoneDatabase.locations.entries) {
      final location = entry.value;
      final now = tz.TZDateTime.now(location);
      
      if (now.timeZoneOffset.inMilliseconds == offsetMillis) {
        results.add(entry.key);
      }
    }
    
    results.sort();
    return results;
  }
  
  @override
  List<String> searchTimeZones(String query) {
    _ensureInitialized();
    
    if (query.isEmpty) return [];
    
    final normalizedQuery = query.toLowerCase();
    final results = <String>[];
    
    for (final timeZoneId in tz.timeZoneDatabase.locations.keys) {
      // Search in timezone ID
      if (timeZoneId.toLowerCase().contains(normalizedQuery)) {
        results.add(timeZoneId);
        continue;
      }
      
      // Search in display name
      final displayName = getTimeZoneDisplayName(timeZoneId).toLowerCase();
      if (displayName.contains(normalizedQuery)) {
        results.add(timeZoneId);
        continue;
      }
      
      // Search in abbreviation
      final abbreviation = getTimeZoneAbbreviation(timeZoneId).toLowerCase();
      if (abbreviation.contains(normalizedQuery)) {
        results.add(timeZoneId);
      }
    }
    
    // Sort by relevance (exact matches first)
    results.sort((a, b) {
      final aExact = a.toLowerCase() == normalizedQuery;
      final bExact = b.toLowerCase() == normalizedQuery;
      
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      
      return a.compareTo(b);
    });
    
    return results;
  }
  
  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('TimezoneService not initialized. Call initializeTimeZones() first.');
    }
  }
  
  /// Get analytics data
  Map<String, dynamic> getAnalytics() {
    return {
      'current_timezone': _currentTimeZoneId,
      'offset_hours': _currentLocation.currentTimeZone.offset ~/ 3600000,
      'abbreviation': getTimeZoneAbbreviation(_currentTimeZoneId),
      'cache_size': _locationCache.length,
    };
  }
}