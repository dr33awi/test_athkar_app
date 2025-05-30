// lib/core/infrastructure/services/storage/storage_service_impl.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../logging/logger_service.dart';
import 'storage_service.dart';

/// Implementation of StorageService using SharedPreferences
class StorageServiceImpl implements StorageService {
  final SharedPreferences _prefs;
  final LoggerService? _logger;
  
  // Prefix for all keys to avoid conflicts
  static const String _keyPrefix = 'athkar_';

  StorageServiceImpl(this._prefs, {LoggerService? logger}) : _logger = logger;

  @override
  Future<bool> setString(String key, String value) async {
    try {
      final prefixedKey = _getPrefixedKey(key);
      final result = await _prefs.setString(prefixedKey, value);
      _logger?.debug(
        message: 'String saved',
        data: {'key': key, 'length': value.length},
      );
      return result;
    } catch (e) {
      _logger?.error(
        message: 'Failed to save string',
        error: e,
      );
      return false;
    }
  }

  @override
  String? getString(String key) {
    try {
      final prefixedKey = _getPrefixedKey(key);
      return _prefs.getString(prefixedKey);
    } catch (e) {
      _logger?.error(
        message: 'Failed to get string',
        error: e,
      );
      return null;
    }
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    try {
      final prefixedKey = _getPrefixedKey(key);
      final result = await _prefs.setBool(prefixedKey, value);
      _logger?.debug(
        message: 'Bool saved',
        data: {'key': key, 'value': value},
      );
      return result;
    } catch (e) {
      _logger?.error(
        message: 'Failed to save bool',
        error: e,
      );
      return false;
    }
  }

  @override
  bool? getBool(String key) {
    try {
      final prefixedKey = _getPrefixedKey(key);
      return _prefs.getBool(prefixedKey);
    } catch (e) {
      _logger?.error(
        message: 'Failed to get bool',
        error: e,
      );
      return null;
    }
  }

  @override
  Future<bool> setInt(String key, int value) async {
    try {
      final prefixedKey = _getPrefixedKey(key);
      final result = await _prefs.setInt(prefixedKey, value);
      _logger?.debug(
        message: 'Int saved',
        data: {'key': key, 'value': value},
      );
      return result;
    } catch (e) {
      _logger?.error(
        message: 'Failed to save int',
        error: e,
      );
      return false;
    }
  }

  @override
  int? getInt(String key) {
    try {
      final prefixedKey = _getPrefixedKey(key);
      return _prefs.getInt(prefixedKey);
    } catch (e) {
      _logger?.error(
        message: 'Failed to get int',
        error: e,
      );
      return null;
    }
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    try {
      final prefixedKey = _getPrefixedKey(key);
      final result = await _prefs.setDouble(prefixedKey, value);
      _logger?.debug(
        message: 'Double saved',
        data: {'key': key, 'value': value},
      );
      return result;
    } catch (e) {
      _logger?.error(
        message: 'Failed to save double',
        error: e,
      );
      return false;
    }
  }

  @override
  double? getDouble(String key) {
    try {
      final prefixedKey = _getPrefixedKey(key);
      return _prefs.getDouble(prefixedKey);
    } catch (e) {
      _logger?.error(
        message: 'Failed to get double',
        error: e,
      );
      return null;
    }
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      final prefixedKey = _getPrefixedKey(key);
      final result = await _prefs.setStringList(prefixedKey, value);
      _logger?.debug(
        message: 'String list saved',
        data: {'key': key, 'count': value.length},
      );
      return result;
    } catch (e) {
      _logger?.error(
        message: 'Failed to save string list',
        error: e,
      );
      return false;
    }
  }

  @override
  List<String>? getStringList(String key) {
    try {
      final prefixedKey = _getPrefixedKey(key);
      return _prefs.getStringList(prefixedKey);
    } catch (e) {
      _logger?.error(
        message: 'Failed to get string list',
        error: e,
      );
      return null;
    }
  }

  @override
  Future<bool> setMap(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await setString(key, jsonString);
    } catch (e) {
      _logger?.error(
        message: 'Failed to save map',
        error: e,
      );
      return false;
    }
  }

  @override
  Map<String, dynamic>? getMap(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      
      _logger?.warning(
        message: 'Invalid map format',
        data: {'key': key, 'type': decoded.runtimeType},
      );
      return null;
    } catch (e) {
      _logger?.error(
        message: 'Failed to get map',
        error: e,
      );
      return null;
    }
  }
  
  @override
  Future<bool> setObject<T>(String key, T object, Map<String, dynamic> Function(T) toJson) async {
    try {
      final map = toJson(object);
      return await setMap(key, map);
    } catch (e) {
      _logger?.error(
        message: 'Failed to save object',
        error: e,
      );
      return false;
    }
  }
  
  @override
  T? getObject<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      final map = getMap(key);
      if (map == null) return null;
      
      return fromJson(map);
    } catch (e) {
      _logger?.error(
        message: 'Failed to get object',
        error: e,
      );
      return null;
    }
  }

  @override
  Future<bool> remove(String key) async {
    try {
      final prefixedKey = _getPrefixedKey(key);
      final result = await _prefs.remove(prefixedKey);
      _logger?.debug(
        message: 'Key removed',
        data: {'key': key},
      );
      return result;
    } catch (e) {
      _logger?.error(
        message: 'Failed to remove key',
        error: e,
      );
      return false;
    }
  }

  @override
  Future<bool> clear() async {
    try {
      // Only clear our prefixed keys
      final keysToRemove = getKeys();
      for (final key in keysToRemove) {
        await remove(key);
      }
      
      _logger?.info(
        message: 'Storage cleared',
        data: {'removed_keys': keysToRemove.length},
      );
      return true;
    } catch (e) {
      _logger?.error(
        message: 'Failed to clear storage',
        error: e,
      );
      return false;
    }
  }

  @override
  bool containsKey(String key) {
    try {
      final prefixedKey = _getPrefixedKey(key);
      return _prefs.containsKey(prefixedKey);
    } catch (e) {
      _logger?.error(
        message: 'Failed to check key existence',
        error: e,
      );
      return false;
    }
  }

  @override
  Set<String> getKeys() {
    try {
      return _prefs
          .getKeys()
          .where((key) => key.startsWith(_keyPrefix))
          .map((key) => key.substring(_keyPrefix.length))
          .toSet();
    } catch (e) {
      _logger?.error(
        message: 'Failed to get keys',
        error: e,
      );
      return {};
    }
  }
  
  @override
  Future<int> getStorageSize() async {
    try {
      int totalSize = 0;
      
      for (final key in _prefs.getKeys()) {
        final value = _prefs.get(key);
        if (value != null) {
          totalSize += _estimateSize(value);
        }
      }
      
      _logger?.debug(
        message: 'Storage size calculated',
        data: {'bytes': totalSize, 'kb': (totalSize / 1024).toStringAsFixed(2)},
      );
      
      return totalSize;
    } catch (e) {
      _logger?.error(
        message: 'Failed to calculate storage size',
        error: e,
      );
      return 0;
    }
  }
  
  @override
  Future<void> reload() async {
    try {
      await _prefs.reload();
      _logger?.debug(message: 'Storage reloaded');
    } catch (e) {
      _logger?.error(
        message: 'Failed to reload storage',
        error: e,
      );
    }
  }
  
  /// Get prefixed key to avoid conflicts
  String _getPrefixedKey(String key) {
    return '$_keyPrefix$key';
  }
  
  /// Estimate size of a value in bytes
  int _estimateSize(dynamic value) {
    if (value is String) {
      return value.length * 2; // Approximate UTF-16 encoding
    } else if (value is int || value is double || value is bool) {
      return 8; // Approximate size
    } else if (value is List<String>) {
      return value.fold<int>(0, (sum, str) => sum + str.length * 2);
    }
    return 0;
  }
}