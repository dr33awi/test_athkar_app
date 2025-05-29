// lib/core/services/implementations/battery_service_impl.dart
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import '../interfaces/battery_service.dart' as app_battery;
import '../interfaces/logger_service.dart'; // <--- إضافة: استيراد LoggerService
// افترض أن لديك طريقة للحصول على LoggerService، مثلاً عبر get_it
import '../../../app/di/service_locator.dart'; // <--- إضافة: افترض وجود Service Locator

class BatteryServiceImpl implements app_battery.BatteryService {
  final Battery _battery = Battery();
  final LoggerService _logger; // <--- إضافة: حقل لـ LoggerService
  final StreamController<app_battery.BatteryState> _batteryStateController =
      StreamController<app_battery.BatteryState>.broadcast();

  int _minimumBatteryLevel = 15;
  StreamSubscription<BatteryState>? _batterySubscription;

  // <--- تعديل: تحديث المُنشئ لاستقبال LoggerService
  BatteryServiceImpl({LoggerService? logger})
      : _logger = logger ?? getIt<LoggerService>() { // استخدام getIt كـ fallback أو طريقة أساسية
    _initBatteryStateListener();
  }

  void _initBatteryStateListener() {
    if (_batterySubscription != null) return;

    _batterySubscription =
        _battery.onBatteryStateChanged.listen((BatteryState state) async {
      final int level = await getBatteryLevel();
      final bool charging = await isCharging();
      final bool powerSaveMode = await isPowerSaveMode();

      _batteryStateController.add(
        app_battery.BatteryState(
          level: level,
          isCharging: charging,
          isPowerSaveMode: powerSaveMode,
        ),
      );
    }, onError: (error, stackTrace) { // <--- إضافة: معالجة الأخطاء في الـ Stream
      _logger.error(
          message: 'Error in battery state changed listener',
          error: error,
          stackTrace: stackTrace);
    });
  }

  @override
  Future<int> getBatteryLevel() async {
    try {
      final int level = await _battery.batteryLevel;
      return level;
    } catch (e, s) { // <--- تعديل: استخدام LoggerService
      _logger.error(
          message: 'Error getting battery level', error: e, stackTrace: s);
      return 100; // نفترض أن مستوى البطارية مرتفع لتجنب تعطيل الإشعارات
    }
  }

  @override
  Future<bool> isCharging() async {
    try {
      final BatteryState batteryStatus = await _battery.batteryState;
      return batteryStatus == BatteryState.charging ||
             batteryStatus == BatteryState.full;
    } catch (e, s) { // <--- تعديل: استخدام LoggerService
      _logger.error(
          message: 'Error getting charging status', error: e, stackTrace: s);
      return true; // نفترض أن الجهاز قيد الشحن لتجنب تعطيل الإشعارات
    }
  }

  @override
  Future<bool> isPowerSaveMode() async {
    try {
      final bool isInPowerSaveMode = await _battery.isInBatterySaveMode;
      return isInPowerSaveMode;
    } catch (e, s) { // <--- تعديل: استخدام LoggerService
      _logger.error(
          message: 'Error getting power save mode', error: e, stackTrace: s);
      return false; // نفترض أن وضع توفير الطاقة غير مفعل
    }
  }

  @override
  Future<bool> canSendNotification() async {
    final bool charging = await isCharging();
    if (charging) {
      return true;
    }

    final int level = await getBatteryLevel();
    final bool powerSaveModeActive = await isPowerSaveMode();

    if (level <= _minimumBatteryLevel && powerSaveModeActive) {
      _logger.info(
          message:
              'Notification sending deferred: Low battery ($level%) and power save mode active.');
      return false;
    }

    return true;
  }

  @override
  Future<void> setMinimumBatteryLevel(int level) async {
    if (level >= 0 && level <= 100) {
      _minimumBatteryLevel = level;
      _logger.info(message: 'Minimum battery level set to: $level%');
    } else {
      _logger.warning(
          message:
              'Attempted to set invalid minimum battery level: $level%. Level remains $_minimumBatteryLevel%');
    }
  }

  @override
  Stream<app_battery.BatteryState> getBatteryStateStream() {
    return _batteryStateController.stream;
  }

  @override
  Future<void> dispose() async {
    await _batterySubscription?.cancel();
    _batterySubscription = null;
    if (!_batteryStateController.isClosed) {
      await _batteryStateController.close();
    }
    _logger.debug(message: 'BatteryServiceImpl disposed');
  }
}