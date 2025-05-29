// lib/core/infrastructure/services/device/battery/battery_service_impl.dart
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'battery_service.dart' as app_battery;
import '../../logging/logger_service.dart';

class BatteryServiceImpl implements app_battery.BatteryService {
  final Battery _battery;
  final LoggerService _logger;
  final StreamController<app_battery.BatteryState> _batteryStateController =
      StreamController<app_battery.BatteryState>.broadcast();

  int _minimumBatteryLevel = 15;
  StreamSubscription<BatteryState>? _batterySubscription;
  Timer? _pollTimer;
  
  // Cache for battery state
  app_battery.BatteryState? _lastKnownState;
  DateTime? _lastUpdateTime;
  static const Duration _cacheValidity = Duration(seconds: 30);

  BatteryServiceImpl({
    required LoggerService logger,
    Battery? battery,
  })  : _logger = logger,
        _battery = battery ?? Battery() {
    _initBatteryStateListener();
    _startPolling();
  }

  void _initBatteryStateListener() {
    if (_batterySubscription != null) return;

    _batterySubscription = _battery.onBatteryStateChanged.listen(
      (BatteryState state) async {
        await _updateBatteryState();
      },
      onError: (error, stackTrace) {
        _logger.error(
          message: 'Error in battery state changed listener',
          error: error,
          stackTrace: stackTrace,
        );
      },
      cancelOnError: false,
    );
  }

  void _startPolling() {
    // Poll battery state every 5 minutes as backup
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _updateBatteryState();
    });
  }

  Future<void> _updateBatteryState() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final isInSaveMode = await _battery.isInBatterySaveMode;

      final charging = state == BatteryState.charging || state == BatteryState.full;

      final newState = app_battery.BatteryState(
        level: level,
        isCharging: charging,
        isPowerSaveMode: isInSaveMode,
      );

      _lastKnownState = newState;
      _lastUpdateTime = DateTime.now();

      if (!_batteryStateController.isClosed) {
        _batteryStateController.add(newState);
      }

      _logger.debug(
        message: 'Battery state updated',
        data: {
          'level': level,
          'charging': charging,
          'powerSaveMode': isInSaveMode,
        },
      );
    } catch (e, s) {
      _logger.error(
        message: 'Error updating battery state',
        error: e,
        stackTrace: s,
      );
    }
  }

  app_battery.BatteryState? _getCachedState() {
    if (_lastKnownState == null || _lastUpdateTime == null) return null;

    final age = DateTime.now().difference(_lastUpdateTime!);
    if (age > _cacheValidity) return null;

    return _lastKnownState;
  }

  @override
  Future<int> getBatteryLevel() async {
    // Try cached value first
    final cached = _getCachedState();
    if (cached != null) return cached.level;

    try {
      final level = await _battery.batteryLevel;
      _logger.debug(message: 'Battery level: $level%');
      return level;
    } catch (e, s) {
      _logger.error(
        message: 'Error getting battery level',
        error: e,
        stackTrace: s,
      );
      return 100; // Assume full battery on error
    }
  }

  @override
  Future<bool> isCharging() async {
    // Try cached value first
    final cached = _getCachedState();
    if (cached != null) return cached.isCharging;

    try {
      final state = await _battery.batteryState;
      final charging = state == BatteryState.charging || state == BatteryState.full;
      _logger.debug(message: 'Charging status: $charging');
      return charging;
    } catch (e, s) {
      _logger.error(
        message: 'Error getting charging status',
        error: e,
        stackTrace: s,
      );
      return true; // Assume charging on error
    }
  }

  @override
  Future<bool> isPowerSaveMode() async {
    // Try cached value first
    final cached = _getCachedState();
    if (cached != null) return cached.isPowerSaveMode;

    try {
      final isInPowerSaveMode = await _battery.isInBatterySaveMode;
      _logger.debug(message: 'Power save mode: $isInPowerSaveMode');
      return isInPowerSaveMode;
    } catch (e, s) {
      _logger.error(
        message: 'Error getting power save mode',
        error: e,
        stackTrace: s,
      );
      return false; // Assume not in power save mode on error
    }
  }

  @override
  Future<bool> canSendNotification() async {
    try {
      final charging = await isCharging();
      if (charging) {
        _logger.debug(message: 'Can send notification: Device is charging');
        return true;
      }

      final level = await getBatteryLevel();
      final powerSaveModeActive = await isPowerSaveMode();

      if (level <= _minimumBatteryLevel && powerSaveModeActive) {
        _logger.info(
          message: 'Notification deferred due to battery constraints',
          data: {
            'batteryLevel': level,
            'minimumLevel': _minimumBatteryLevel,
            'powerSaveMode': powerSaveModeActive,
          },
        );
        return false;
      }

      return true;
    } catch (e, s) {
      _logger.error(
        message: 'Error checking notification permission based on battery',
        error: e,
        stackTrace: s,
      );
      return true; // Allow notifications on error
    }
  }

  @override
  Future<void> setMinimumBatteryLevel(int level) async {
    if (level < 0 || level > 100) {
      _logger.warning(
        message: 'Invalid minimum battery level',
        data: {'requestedLevel': level, 'currentLevel': _minimumBatteryLevel},
      );
      return;
    }

    _minimumBatteryLevel = level;
    _logger.info(
      message: 'Minimum battery level updated',
      data: {'newLevel': level},
    );
  }

  @override
  Stream<app_battery.BatteryState> getBatteryStateStream() {
    return _batteryStateController.stream;
  }

  @override
  Future<void> dispose() async {
    _logger.debug(message: 'Disposing BatteryServiceImpl');
    
    await _batterySubscription?.cancel();
    _batterySubscription = null;
    
    _pollTimer?.cancel();
    _pollTimer = null;
    
    if (!_batteryStateController.isClosed) {
      await _batteryStateController.close();
    }
    
    _lastKnownState = null;
    _lastUpdateTime = null;
  }
}