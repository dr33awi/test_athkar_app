// lib/features/prayer_times/infrastructure/services/prayer_times_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../../core/infrastructure/services/logging/logger_service.dart';
import '../../../../core/infrastructure/services/notifications/notification_manager.dart';
import '../../../../core/infrastructure/services/permissions/permission_service.dart';
import '../../domain/models/prayer_time_model.dart';
import '../../domain/models/prayer_times_settings.dart';

/// خدمة أوقات الصلاة
class PrayerTimesService {
  final StorageService _storage;
  final LoggerService _logger;
  final PermissionService _permissions;
  
  static const String _settingsKey = 'prayer_times_settings';
  static const String _cachedTimesKey = 'cached_prayer_times';
  static const String _lastUpdateKey = 'prayer_times_last_update';
  
  PrayerTimesSettings _currentSettings = const PrayerTimesSettings();
  final StreamController<List<PrayerTimeModel>> _prayerTimesController = 
      StreamController<List<PrayerTimeModel>>.broadcast();
  
  Timer? _updateTimer;
  Timer? _notificationCheckTimer;

  PrayerTimesService({
    required StorageService storage,
    required LoggerService logger,
    required PermissionService permissions,
  }) : _storage = storage,
       _logger = logger,
       _permissions = permissions {
    _initialize();
  }

  /// تهيئة الخدمة
  Future<void> _initialize() async {
    _logger.info(message: '[PrayerTimesService] تهيئة خدمة أوقات الصلاة');
    
    // تحميل الإعدادات
    await _loadSettings();
    
    // تحميل الأوقات المحفوظة
    await _loadCachedTimes();
    
    // بدء المؤقتات
    _startTimers();
    
    // تحديث الأوقات
    await updatePrayerTimes();
  }

  /// تحميل الإعدادات
  Future<void> _loadSettings() async {
    try {
      final data = _storage.getMap(_settingsKey);
      if (data != null) {
        _currentSettings = PrayerTimesSettings.fromJson(data);
        _logger.debug(message: '[PrayerTimesService] تم تحميل الإعدادات');
      }
    } catch (e) {
      _logger.error(message: '[PrayerTimesService] خطأ في تحميل الإعدادات', error: e);
    }
  }

  /// حفظ الإعدادات
  Future<void> _saveSettings() async {
    try {
      await _storage.setMap(_settingsKey, _currentSettings.toJson());
      _logger.debug(message: '[PrayerTimesService] تم حفظ الإعدادات');
    } catch (e) {
      _logger.error(message: '[PrayerTimesService] خطأ في حفظ الإعدادات', error: e);
    }
  }

  /// الحصول على أوقات الصلاة لليوم
  Future<List<PrayerTimeModel>> getTodayPrayerTimes() async {
    final today = DateTime.now();
    
    // محاكاة الحصول على الأوقات من API أو حسابها محلياً
    // في التطبيق الحقيقي، استخدم مكتبة مثل adhan_dart
    final prayers = [
      PrayerTimeModel(
        id: 'fajr_${today.toIso8601String()}',
        name: 'Fajr',
        arabicName: 'الفجر',
        time: '04:35',
        dateTime: DateTime(today.year, today.month, today.day, 4, 35),
        icon: Icons.dark_mode,
        gradientColors: [const Color(0xFF1A237E), const Color(0xFF3949AB)],
        isNotificationEnabled: _currentSettings.notificationSettings['fajr'] ?? true,
        notificationMinutesBefore: _currentSettings.notificationMinutesBefore['fajr'] ?? 0,
      ),
      PrayerTimeModel(
        id: 'sunrise_${today.toIso8601String()}',
        name: 'Sunrise',
        arabicName: 'الشروق',
        time: '05:55',
        dateTime: DateTime(today.year, today.month, today.day, 5, 55),
        icon: Icons.wb_sunny_outlined,
        gradientColors: [const Color(0xFFFF6F00), const Color(0xFFFFB300)],
        isNotificationEnabled: false,
      ),
      PrayerTimeModel(
        id: 'dhuhr_${today.toIso8601String()}',
        name: 'Dhuhr',
        arabicName: 'الظهر',
        time: '12:15',
        dateTime: DateTime(today.year, today.month, today.day, 12, 15),
        icon: Icons.light_mode,
        gradientColors: [const Color(0xFFFF6F00), const Color(0xFFFFCA28)],
        isNotificationEnabled: _currentSettings.notificationSettings['dhuhr'] ?? true,
        notificationMinutesBefore: _currentSettings.notificationMinutesBefore['dhuhr'] ?? 0,
      ),
      PrayerTimeModel(
        id: 'asr_${today.toIso8601String()}',
        name: 'Asr',
        arabicName: 'العصر',
        time: '15:45',
        dateTime: DateTime(today.year, today.month, today.day, 15, 45),
        icon: Icons.wb_cloudy,
        gradientColors: [const Color(0xFF00897B), const Color(0xFF4DB6AC)],
        isNotificationEnabled: _currentSettings.notificationSettings['asr'] ?? true,
        notificationMinutesBefore: _currentSettings.notificationMinutesBefore['asr'] ?? 0,
      ),
      PrayerTimeModel(
        id: 'maghrib_${today.toIso8601String()}',
        name: 'Maghrib',
        arabicName: 'المغرب',
        time: '18:30',
        dateTime: DateTime(today.year, today.month, today.day, 18, 30),
        icon: Icons.wb_twilight,
        gradientColors: [const Color(0xFFE65100), const Color(0xFFFF6E40)],
        isNotificationEnabled: _currentSettings.notificationSettings['maghrib'] ?? true,
        notificationMinutesBefore: _currentSettings.notificationMinutesBefore['maghrib'] ?? 0,
      ),
      PrayerTimeModel(
        id: 'isha_${today.toIso8601String()}',
        name: 'Isha',
        arabicName: 'العشاء',
        time: '20:00',
        dateTime: DateTime(today.year, today.month, today.day, 20, 0),
        icon: Icons.bedtime,
        gradientColors: [const Color(0xFF4A148C), const Color(0xFF7B1FA2)],
        isNotificationEnabled: _currentSettings.notificationSettings['isha'] ?? true,
        notificationMinutesBefore: _currentSettings.notificationMinutesBefore['isha'] ?? 0,
      ),
    ];
    
    // تطبيق التعديلات اليدوية
    for (final prayer in prayers) {
      final adjustment = _currentSettings.manualAdjustments[prayer.name.toLowerCase()] ?? 0;
      if (adjustment != 0) {
        final adjustedTime = prayer.dateTime.add(Duration(minutes: adjustment));
        prayers[prayers.indexOf(prayer)] = prayer.copyWith(
          dateTime: adjustedTime,
          time: '${adjustedTime.hour.toString().padLeft(2, '0')}:${adjustedTime.minute.toString().padLeft(2, '0')}',
        );
      }
    }
    
    return prayers;
  }

  /// تحديث أوقات الصلاة
  Future<void> updatePrayerTimes() async {
    try {
      _logger.info(message: '[PrayerTimesService] تحديث أوقات الصلاة');
      
      final times = await getTodayPrayerTimes();
      
      // حفظ في الكاش
      await _cachePrayerTimes(times);
      
      // إرسال للمستمعين
      _prayerTimesController.add(times);
      
      // جدولة الإشعارات
      await _scheduleNotifications(times);
      
      _logger.info(message: '[PrayerTimesService] تم تحديث أوقات الصلاة بنجاح');
    } catch (e) {
      _logger.error(message: '[PrayerTimesService] خطأ في تحديث أوقات الصلاة', error: e);
    }
  }

  /// جدولة إشعارات الصلاة
  Future<void> _scheduleNotifications(List<PrayerTimeModel> prayers) async {
    // التحقق من إذن الإشعارات
    final hasPermission = await _permissions.checkPermissionStatus(
      AppPermissionType.notification,
    );
    
    if (hasPermission != AppPermissionStatus.granted) {
      _logger.warning(message: '[PrayerTimesService] لا يوجد إذن للإشعارات');
      return;
    }
    
    // إلغاء الإشعارات السابقة
    await NotificationManager.instance.cancelAllPrayerNotifications();
    
    // جدولة إشعارات جديدة
    for (final prayer in prayers) {
      if (!prayer.isNotificationEnabled || prayer.name.toLowerCase() == 'sunrise') {
        continue;
      }
      
      await NotificationManager.instance.schedulePrayerNotification(
        prayerName: prayer.name,
        arabicName: prayer.arabicName,
        time: prayer.dateTime,
        minutesBefore: prayer.notificationMinutesBefore,
      );
    }
    
    _logger.info(message: '[PrayerTimesService] تم جدولة إشعارات الصلاة');
  }

  /// الحصول على الصلاة القادمة
  PrayerTimeModel? getNextPrayer(List<PrayerTimeModel> prayers) {
    final now = DateTime.now();
    
    // استبعاد الشروق
    final prayersWithoutSunrise = prayers
        .where((p) => p.name.toLowerCase() != 'sunrise')
        .toList();
    
    for (final prayer in prayersWithoutSunrise) {
      if (prayer.dateTime.isAfter(now)) {
        return prayer;
      }
    }
    
    // إذا مرت جميع الصلوات، أرجع الفجر
    return prayersWithoutSunrise.firstWhere(
      (p) => p.name.toLowerCase() == 'fajr',
      orElse: () => prayersWithoutSunrise.first,
    );
  }

  /// الحصول على الصلاة الحالية
  PrayerTimeModel? getCurrentPrayer(List<PrayerTimeModel> prayers) {
    final now = DateTime.now();
    
    PrayerTimeModel? current;
    for (int i = 0; i < prayers.length; i++) {
      if (i == prayers.length - 1) {
        // آخر صلاة (العشاء)
        if (now.isAfter(prayers[i].dateTime)) {
          current = prayers[i];
        }
      } else {
        // باقي الصلوات
        if (now.isAfter(prayers[i].dateTime) && now.isBefore(prayers[i + 1].dateTime)) {
          current = prayers[i];
        }
      }
    }
    
    return current;
  }

  /// تحديث إعدادات الموقع
  Future<void> updateLocation(double latitude, double longitude) async {
    _currentSettings = _currentSettings.copyWith(
      latitude: latitude,
      longitude: longitude,
    );
    
    await _saveSettings();
    await updatePrayerTimes();
    
    _logger.info(message: '[PrayerTimesService] تم تحديث الموقع', data: {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// تحديث طريقة الحساب
  Future<void> updateCalculationMethod(String method) async {
    _currentSettings = _currentSettings.copyWith(
      calculationMethod: method,
    );
    
    await _saveSettings();
    await updatePrayerTimes();
    
    _logger.info(message: '[PrayerTimesService] تم تحديث طريقة الحساب', data: {
      'method': method,
    });
  }

  /// تحديث المذهب
  Future<void> updateMadhab(String madhab) async {
    _currentSettings = _currentSettings.copyWith(
      madhab: madhab,
    );
    
    await _saveSettings();
    await updatePrayerTimes();
    
    _logger.info(message: '[PrayerTimesService] تم تحديث المذهب', data: {
      'madhab': madhab,
    });
  }

  /// تحديث التعديل اليدوي لوقت صلاة
  Future<void> updateManualAdjustment(String prayerName, int minutes) async {
    final adjustments = Map<String, int>.from(_currentSettings.manualAdjustments);
    adjustments[prayerName.toLowerCase()] = minutes;
    
    _currentSettings = _currentSettings.copyWith(
      manualAdjustments: adjustments,
    );
    
    await _saveSettings();
    await updatePrayerTimes();
    
    _logger.info(message: '[PrayerTimesService] تم تحديث التعديل اليدوي', data: {
      'prayer': prayerName,
      'minutes': minutes,
    });
  }

  /// تحديث إعدادات الإشعارات
  Future<void> updateNotificationSettings(String prayerName, bool enabled, int minutesBefore) async {
    final notificationSettings = Map<String, bool>.from(_currentSettings.notificationSettings);
    final notificationMinutes = Map<String, int>.from(_currentSettings.notificationMinutesBefore);
    
    notificationSettings[prayerName.toLowerCase()] = enabled;
    notificationMinutes[prayerName.toLowerCase()] = minutesBefore;
    
    _currentSettings = _currentSettings.copyWith(
      notificationSettings: notificationSettings,
      notificationMinutesBefore: notificationMinutes,
    );
    
    await _saveSettings();
    await updatePrayerTimes();
    
    _logger.info(message: '[PrayerTimesService] تم تحديث إعدادات الإشعارات', data: {
      'prayer': prayerName,
      'enabled': enabled,
      'minutesBefore': minutesBefore,
    });
  }

  /// بدء المؤقتات
  void _startTimers() {
    // مؤقت تحديث الأوقات (كل يوم عند منتصف الليل)
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = midnight.difference(now);
    
    Future.delayed(durationUntilMidnight, () {
      updatePrayerTimes();
      
      // بدء مؤقت يومي
      _updateTimer = Timer.periodic(const Duration(days: 1), (_) {
        updatePrayerTimes();
      });
    });
    
    // مؤقت فحص الإشعارات (كل دقيقة)
    _notificationCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkUpcomingPrayers();
    });
  }

  /// فحص الصلوات القادمة
  Future<void> _checkUpcomingPrayers() async {
    // يمكن إضافة منطق إضافي هنا إذا لزم الأمر
  }

  /// حفظ الأوقات في الكاش
  Future<void> _cachePrayerTimes(List<PrayerTimeModel> times) async {
    try {
      final data = times.map((t) => t.toJson()).toList();
      await _storage.setStringList(
        _cachedTimesKey,
        data.map((d) => d.toString()).toList(),
      );
      await _storage.setString(
        _lastUpdateKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      _logger.error(message: '[PrayerTimesService] خطأ في حفظ الكاش', error: e);
    }
  }

  /// تحميل الأوقات من الكاش
  Future<void> _loadCachedTimes() async {
    try {
      final lastUpdate = _storage.getString(_lastUpdateKey);
      if (lastUpdate != null) {
        final updateDate = DateTime.parse(lastUpdate);
        if (updateDate.day == DateTime.now().day) {
          // نفس اليوم، استخدم الكاش
          final cached = _storage.getStringList(_cachedTimesKey);
          if (cached != null) {
            // تحويل البيانات المحفوظة
            _logger.debug(message: '[PrayerTimesService] تم تحميل الأوقات من الكاش');
          }
        }
      }
    } catch (e) {
      _logger.error(message: '[PrayerTimesService] خطأ في تحميل الكاش', error: e);
    }
  }

  /// الحصول على stream أوقات الصلاة
  Stream<List<PrayerTimeModel>> get prayerTimesStream => _prayerTimesController.stream;

  /// الحصول على الإعدادات الحالية
  PrayerTimesSettings get currentSettings => _currentSettings;

  /// التنظيف
  void dispose() {
    _updateTimer?.cancel();
    _notificationCheckTimer?.cancel();
    _prayerTimesController.close();
    _logger.info(message: '[PrayerTimesService] تم إيقاف خدمة أوقات الصلاة');
  }
}