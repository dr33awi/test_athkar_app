// lib/core/infrastructure/services/device/battery/battery_service_impl.dart

import 'dart:async';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart' as battery_plus;
import '../../logging/logger_service.dart';
import '../../storage/storage_service.dart';
import 'battery_service.dart';

/// Implementation of battery service
class BatteryServiceImpl implements BatteryService {
  final battery_plus.Battery _battery;
  final LoggerService? _logger;
  final StorageService _storage;
  
  static const String _minBatteryLevelKey = 'min_battery_level';
  static const int _defaultMinBatteryLevel = 15;
  
  StreamController<BatteryState>? _batteryStateController;
  StreamSubscription<battery_plus.BatteryState>? _batteryStateSubscription;
  Timer? _pollingTimer;
  int _minimumBatteryLevel = _defaultMinBatteryLevel;
  BatteryState? _lastKnownState;
  
  BatteryServiceImpl({
    battery_plus.Battery? battery,
    LoggerService? logger,
    required StorageService storage,
  })  : _battery = battery ?? battery_plus.Battery(),
        _logger = logger,
        _storage = storage {
    _initialize();
  }
  
  void _initialize() {
    _logger?.debug(message: '[BatteryService] Initializing...');
    
    // Load saved minimum battery level
    _minimumBatteryLevel = _storage.getInt(_minBatteryLevelKey) ?? _defaultMinBatteryLevel;
    
    // Initialize battery state monitoring
    _initializeBatteryMonitoring();
  }
  
  void _initializeBatteryMonitoring() {
    _batteryStateController = StreamController<BatteryState>.broadcast(
      onListen: _startMonitoring,
      onCancel: _stopMonitoring,
    );
  }
  
  void _startMonitoring() {
    _logger?.debug(message: '[BatteryService] Starting battery monitoring');
    
    // Start with immediate update
    _updateBatteryState();
    
    // Set up periodic polling (every 60 seconds)
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _updateBatteryState();
    });
    
    // Also listen to battery state changes if available
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((state) {
      _logger?.debug(
        message: '[BatteryService] Battery state changed',
        data: {'state': state.toString()},
      );
      _updateBatteryState();
    });
  }
  
  void _stopMonitoring() {
    _logger?.debug(message: '[BatteryService] Stopping battery monitoring');
    _pollingTimer?.cancel();
    _batteryStateSubscription?.cancel();
  }
  
  Future<void> _updateBatteryState() async {
    try {
      final state = await getCurrentBatteryState();
      _lastKnownState = state;
      _batteryStateController?.add(state);
      
      _logger?.debug(
        message: '[BatteryService] Battery state updated',
        data: state.toJson(),
      );
      
      // Log analytics event for critical battery levels
      if (state.level <= 5 && !state.isCharging) {
        _logger?.logEvent('critical_battery_level', parameters: {
          'level': state.level,
          'is_charging': state.isCharging,
        });
      }
    } catch (e) {
      _logger?.error(
        message: '[BatteryService] Error updating battery state',
        error: e,
      );
    }
  }
  
  @override
  Future<int> getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      _logger?.debug(
        message: '[BatteryService] Battery level retrieved',
        data: {'level': level},
      );
      return level;
    } catch (e) {
      _logger?.error(
        message: '[BatteryService] Error getting battery level',
        error: e,
      );
      return 100; // Assume full battery on error
    }
  }
  
  @override
  Future<bool> isCharging() async {
    try {
      final state = await _battery.batteryState;
      final isCharging = state == battery_plus.BatteryState.charging || 
                        state == battery_plus.BatteryState.full;
      
      _logger?.debug(
        message: '[BatteryService] Charging status retrieved',
        data: {'isCharging': isCharging, 'state': state.toString()},
      );
      
      return isCharging;
    } catch (e) {
      _logger?.error(
        message: '[BatteryService] Error checking charging status',
        error: e,
      );
      return false;
    }
  }
  
  @override
  Future<bool> isPowerSaveMode() async {
    try {
      final isInSaveMode = await _battery.isInBatterySaveMode;
      _logger?.debug(
        message: '[BatteryService] Power save mode status retrieved',
        data: {'isPowerSaveMode': isInSaveMode},
      );
      return isInSaveMode;
    } catch (e) {
      _logger?.error(
        message: '[BatteryService] Error checking power save mode',
        error: e,
      );
      return false;
    }
  }
  
  @override
  Future<bool> canSendNotification() async {
    try {
      final batteryLevel = await getBatteryLevel();
      final charging = await isCharging();
      final powerSaveMode = await isPowerSaveMode();
      
      // Can send if:
      // 1. Charging, or
      // 2. Battery level is above minimum and not in power save mode, or
      // 3. Battery level is above critical level (5%)
      final canSend = charging || 
                     (batteryLevel >= _minimumBatteryLevel && !powerSaveMode) ||
                     batteryLevel >= 5;
      
      _logger?.debug(
        message: '[BatteryService] Notification permission check',
        data: {
          'canSend': canSend,
          'batteryLevel': batteryLevel,
          'minimumLevel': _minimumBatteryLevel,
          'isCharging': charging,
          'isPowerSaveMode': powerSaveMode,
        },
      );
      
      if (!canSend) {
        _logger?.logEvent('notification_blocked_battery', parameters: {
          'battery_level': batteryLevel,
          'minimum_level': _minimumBatteryLevel,
          'power_save_mode': powerSaveMode,
        });
      }
      
      return canSend;
    } catch (e) {
      _logger?.error(
        message: '[BatteryService] Error checking notification permission',
        error: e,
      );
      return true; // Allow notifications on error
    }
  }
  
  @override
  Future<void> setMinimumBatteryLevel(int level) async {
    if (level < 0 || level > 100) {
      _logger?.warning(
        message: '[BatteryService] Invalid battery level',
        data: {'level': level},
      );
      return;
    }
    
    _minimumBatteryLevel = level;
    await _storage.setInt(_minBatteryLevelKey, level);
    
    _logger?.info(
      message: '[BatteryService] Minimum battery level updated',
      data: {'level': level},
    );
    
    _logger?.logEvent('battery_threshold_changed', parameters: {'new_level': level});
  }
  
  @override
  int getMinimumBatteryLevel() {
    return _minimumBatteryLevel;
  }
  
  @override
  Stream<BatteryState> getBatteryStateStream() {
    _batteryStateController ??= StreamController<BatteryState>.broadcast(
      onListen: _startMonitoring,
      onCancel: _stopMonitoring,
    );
    
    return _batteryStateController!.stream;
  }
  
  @override
  Future<BatteryState> getCurrentBatteryState() async {
    final level = await getBatteryLevel();
    final charging = await isCharging();
    final powerSaveMode = await isPowerSaveMode();
    
    return BatteryState(
      level: level,
      isCharging: charging,
      isPowerSaveMode: powerSaveMode,
    );
  }
  
  @override
  Future<bool> isBatteryOptimizationEnabled() async {
    if (!Platform.isAndroid) return false;
    
    try {
      // This would require platform-specific implementation
      // For now, we assume it's related to power save mode
      return await isPowerSaveMode();
    } catch (e) {
      _logger?.error(
        message: '[BatteryService] Error checking battery optimization',
        error: e,
      );
      return false;
    }
  }
  
  @override
  Future<void> dispose() async {
    _logger?.debug(message: '[BatteryService] Disposing...');
    
    await _batteryStateSubscription?.cancel();
    _pollingTimer?.cancel();
    await _batteryStateController?.close();
    
    _batteryStateController = null;
    _batteryStateSubscription = null;
    _pollingTimer = null;
    _lastKnownState = null;
    
    _logger?.info(message: '[BatteryService] Disposed');
  }
}