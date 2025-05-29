// lib/core/services/implementations/timezone_service_impl.dart
// import 'package:flutter/foundation.dart'; // <--- تم الحذف: استيراد غير مستخدم
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';
import 'timezone_service.dart';
import '../logging/logger_service.dart';
import '../../../../app/di/service_locator.dart';

class TimezoneServiceImpl implements TimezoneService {
  final LoggerService _logger;
  bool _isInitialized = false;

  TimezoneServiceImpl({LoggerService? logger})
      : _logger = logger ?? getIt<LoggerService>() {
    _logger.debug(message: 'TimezoneServiceImpl initialized');
  }

  @override
  Future<void> initializeTimeZones() async {
    if (_isInitialized) {
      _logger.debug(message: 'Timezones already initialized.');
      return;
    }

    _logger.debug(message: 'Initializing timezones data...');
    tz_data.initializeTimeZones();

    try {
      final String timeZoneName = await FlutterNativeTimezoneLatest.getLocalTimezone();
      _logger.info(message: 'Native timezone detected: $timeZoneName');
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e, s) {
      // <--- تم التعديل: تصحيح استدعاء logger.warning
      _logger.warning(
          message: 'Error setting local timezone via native library: ${e.toString()}. Falling back to offset detection.',
          data: {'error': e, 'stackTrace': s.toString()});
      try {
        final String timeZoneFromOffset = await _detectTimeZoneFromOffset();
        _logger.info(message: 'Timezone detected from offset: $timeZoneFromOffset');
        tz.setLocalLocation(tz.getLocation(timeZoneFromOffset));
      } catch (e2, s2) {
        // <--- تم التعديل: التأكد من صحة استدعاء logger.error
        _logger.error(
            message: 'Error detecting timezone from offset. Falling back to UTC.',
            error: e2, // هذا صحيح حسب الواجهة
            stackTrace: s2); // هذا صحيح حسب الواجهة
        tz.setLocalLocation(tz.getLocation('Etc/UTC'));
      }
    }

    _isInitialized = true;
    _logger.info(message: 'TimezoneService initialization complete. Local timezone set to: ${tz.local.name}');
  }

  @override
  Future<String> getLocalTimezone() async {
    if (!_isInitialized) {
      _logger.warning(message: "getLocalTimezone called before initializeTimeZones. Initializing now.");
      await initializeTimeZones();
    }
    try {
      return await FlutterNativeTimezoneLatest.getLocalTimezone();
    } catch (e, s) {
      _logger.warning(
          message: 'Error getting native timezone: ${e.toString()}. Falling back to offset detection.',
          data: {'error': e, 'stackTrace': s.toString()});
      return await _detectTimeZoneFromOffset();
    }
  }

  Future<String> _detectTimeZoneFromOffset() async {
    final DateTime now = DateTime.now();
    final Duration offset = now.timeZoneOffset;
    _logger.debug(message: "Attempting to detect timezone from offset: $offset");

    // الخريطة هنا هي تبسيط وقد لا تكون دقيقة تمامًا لجميع الحالات (مثل التوقيت الصيفي).
    // يفضل الاعتماد على flutter_native_timezone_latest قدر الإمكان.
    final Map<Duration, String> commonTimeZones = {
      const Duration(hours: 0): 'Etc/UTC',
      const Duration(hours: 1): 'Europe/Paris',
      const Duration(hours: 2): 'Africa/Cairo', // أو Europe/Helsinki, Europe/Bucharest الخ
      const Duration(hours: 3): 'Asia/Riyadh', // أو Europe/Moscow
      const Duration(hours: 4): 'Asia/Dubai',
      const Duration(hours: 5): 'Asia/Karachi',
      const Duration(hours: 5, minutes: 30): 'Asia/Kolkata',
      // يمكن إضافة المزيد من المناطق الشائعة هنا
    };

    if (commonTimeZones.containsKey(offset)) {
      final matchedZone = commonTimeZones[offset]!;
      _logger.info(message: "Found exact offset match: $matchedZone for offset $offset");
      return matchedZone;
    }
    _logger.warning(message: "No exact offset match found for $offset. Returning UTC as fallback.");
    return 'Etc/UTC';
  }

  @override
  tz.TZDateTime getLocalTZDateTime(DateTime dateTime) {
    if (!_isInitialized) {
      _logger.warning(message: "getLocalTZDateTime called before timezones initialized. TZDateTime might use default/uninitialized tz.local.");
      // Consider throwing an exception or awaiting initializeTimeZones() if critical.
    }
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  @override
  tz.TZDateTime nowLocal() {
    if (!_isInitialized) {
      _logger.warning(message: "nowLocal called before timezones initialized. TZDateTime might use default/uninitialized tz.local.");
    }
    return tz.TZDateTime.now(tz.local);
  }

  @override
  tz.TZDateTime fromDateTime(DateTime dateTime) {
     if (!_isInitialized) {
       _logger.warning(message: "fromDateTime called before timezones initialized. TZDateTime might use default/uninitialized tz.local.");
    }
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  @override
  tz.TZDateTime getNextDateTimeInstance(DateTime dateTime) {
    if (!_isInitialized) {
       _logger.warning(message: "getNextDateTimeInstance called before timezones initialized. Scheduling might use incorrect local zone.");
    }
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      _logger.debug(message: "Original scheduled date ($dateTime) was in the past. Moved to next day: $scheduledDate");
    }
    return scheduledDate;
  }

  @override
  tz.TZDateTime getDateTimeInTimeZone(DateTime dateTime, String timeZoneId) {
    if (!_isInitialized) {
       _logger.warning(message: "getDateTimeInTimeZone called before timezones initialized.");
    }
    try {
      final location = tz.getLocation(timeZoneId);
      return tz.TZDateTime.from(dateTime, location);
    } catch (e, s) {
      _logger.error(
          message: 'Error converting DateTime to timezone $timeZoneId. Falling back to local TZDateTime.',
          error: e,
          stackTrace: s);
      return getLocalTZDateTime(dateTime);
    }
  }
}