// lib/core/infrastructure/services/configuration/configuration_service_impl.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../storage/storage_service.dart';
import '../logging/logger_service.dart';
import 'configuration_service.dart';

/// Implementation of configuration service
class ConfigurationServiceImpl implements ConfigurationService {
  final StorageService _storage;
  final LoggerService _logger;
  
  Environment _environment = Environment.development;
  final Map<String, dynamic> _config = {};
  final Map<String, List<Function(dynamic)>> _changeListeners = {};
  
  static const String _configKey = 'app_configuration';
  static const String _envKey = 'app_environment';
  
  // Default configuration file paths
  static const String _defaultConfigPath = 'assets/config/default.json';
  static const String _devConfigPath = 'assets/config/development.json';
  static const String _stagingConfigPath = 'assets/config/staging.json';
  static const String _prodConfigPath = 'assets/config/production.json';
  
  ConfigurationServiceImpl({
    required StorageService storage,
    required LoggerService logger,
  }) : _storage = storage,
       _logger = logger {
    _determineEnvironment();
  }
  
  void _determineEnvironment() {
    // Determine environment based on various factors
    if (kReleaseMode) {
      _environment = Environment.production;
    } else if (kProfileMode) {
      _environment = Environment.staging;
    } else {
      _environment = Environment.development;
    }
    
    // Check if environment is overridden in storage
    final savedEnv = _storage.getString(_envKey);
    if (savedEnv != null) {
      try {
        _environment = Environment.values.firstWhere(
          (e) => e.toString() == savedEnv,
        );
      } catch (e) {
        _logger.warning(
          message: 'Invalid saved environment',
          data: {'saved': savedEnv},
        );
      }
    }
    
    _logger.info(
      message: 'Environment determined',
      data: {'environment': _environment.toString()},
    );
  }
  
  @override
  Environment get environment => _environment;
  
  @override
  T? getValue<T>(String key, {T? defaultValue}) {
    try {
      final value = _getNestedValue(key);
      if (value == null) return defaultValue;
      
      if (value is T) return value;
      
      // Type conversion
      if (T == String) {
        return value.toString() as T;
      } else if (T == int) {
        if (value is num) return value.toInt() as T;
        if (value is String) return int.tryParse(value) as T?;
      } else if (T == double) {
        if (value is num) return value.toDouble() as T;
        if (value is String) return double.tryParse(value) as T?;
      } else if (T == bool) {
        if (value is bool) return value as T;
        if (value is String) return (value.toLowerCase() == 'true') as T;
        if (value is num) return (value != 0) as T;
      }
      
      _logger.warning(
        message: 'Type conversion failed',
        data: {
          'key': key,
          'expected_type': T.toString(),
          'actual_type': value.runtimeType.toString(),
        },
      );
      
      return defaultValue;
    } catch (e) {
      _logger.error(
        message: 'Error getting config value',
        error: e,
      );
      return defaultValue;
    }
  }
  
  @override
  String? getString(String key, {String? defaultValue}) {
    return getValue<String>(key, defaultValue: defaultValue);
  }
  
  @override
  int? getInt(String key, {int? defaultValue}) {
    return getValue<int>(key, defaultValue: defaultValue);
  }
  
  @override
  double? getDouble(String key, {double? defaultValue}) {
    return getValue<double>(key, defaultValue: defaultValue);
  }
  
  @override
  bool getBool(String key, {bool defaultValue = false}) {
    return getValue<bool>(key, defaultValue: defaultValue) ?? defaultValue;
  }
  
  @override
  List<T>? getList<T>(String key, {List<T>? defaultValue}) {
    final value = _getNestedValue(key);
    if (value == null) return defaultValue;
    
    if (value is List) {
      try {
        return value.cast<T>();
      } catch (e) {
        _logger.warning(
          message: 'Error casting list',
          data: {'key': key, 'error': e.toString()},
        );
        return defaultValue;
      }
    }
    
    return defaultValue;
  }
  
  @override
  Map<String, dynamic>? getMap(String key, {Map<String, dynamic>? defaultValue}) {
    final value = _getNestedValue(key);
    if (value == null) return defaultValue;
    
    if (value is Map<String, dynamic>) {
      return value;
    }
    
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (e) {
        _logger.warning(
          message: 'Error converting map',
          data: {'key': key, 'error': e.toString()},
        );
      }
    }
    
    return defaultValue;
  }
  
  @override
  Future<void> setValue(String key, dynamic value) async {
    final oldValue = _getNestedValue(key);
    _setNestedValue(key, value);
    
    // Notify listeners
    _notifyListeners(key, value, oldValue);
    
    // Save configuration
    await _saveConfiguration();
    
    _logger.debug(
      message: 'Configuration value set',
      data: {'key': key, 'value': value},
    );
  }
  
  @override
  Future<void> setValues(Map<String, dynamic> values) async {
    final oldValues = <String, dynamic>{};
    
    for (final entry in values.entries) {
      oldValues[entry.key] = _getNestedValue(entry.key);
      _setNestedValue(entry.key, entry.value);
    }
    
    // Notify listeners for each changed value
    for (final entry in values.entries) {
      _notifyListeners(entry.key, entry.value, oldValues[entry.key]);
    }
    
    // Save configuration
    await _saveConfiguration();
    
    _logger.debug(
      message: 'Multiple configuration values set',
      data: {'count': values.length},
    );
  }
  
  @override
  Future<void> loadConfiguration() async {
    try {
      _logger.info(message: 'Loading configuration...');
      
      // Load from storage first
      final saved = _storage.getMap(_configKey);
      if (saved != null) {
        _config.clear();
        _config.addAll(saved);
        _logger.debug(
          message: 'Configuration loaded from storage',
          data: {'keys': saved.length},
        );
      }
      
      // Load default configuration
      await _loadConfigFile(_defaultConfigPath);
      
      // Load environment-specific configuration
      switch (_environment) {
        case Environment.development:
          await _loadConfigFile(_devConfigPath);
          break;
        case Environment.staging:
          await _loadConfigFile(_stagingConfigPath);
          break;
        case Environment.production:
          await _loadConfigFile(_prodConfigPath);
          break;
      }
      
      // Re-apply saved configuration (to preserve user settings)
      if (saved != null) {
        _mergeConfiguration(saved);
      }
      
      _logger.info(
        message: 'Configuration loaded successfully',
        data: {
          'environment': _environment.toString(),
          'total_keys': _config.length,
        },
      );
      
      _logger.logEvent('configuration_loaded', parameters: {
        'environment': _environment.toString(),
        'keys_count': _config.length,
        });
        
    } catch (e, s) {
      _logger.error(
        message: 'Error loading configuration',
        error: e,
        stackTrace: s,
      );
      
      // Load minimal default configuration
      _loadDefaultConfiguration();
    }
  }
  
  Future<void> _loadConfigFile(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final config = jsonDecode(jsonString) as Map<String, dynamic>;
      _mergeConfiguration(config);
      
      _logger.debug(
        message: 'Configuration file loaded',
        data: {'path': path, 'keys': config.length},
      );
    } catch (e) {
      _logger.debug(
        message: 'Configuration file not found or invalid',
        data: {'path': path},
      );
    }
  }
  
  void _mergeConfiguration(Map<String, dynamic> newConfig) {
    newConfig.forEach((key, value) {
      if (value is Map && _config[key] is Map) {
        // Recursively merge maps
        _config[key] = _deepMerge(_config[key] as Map, value as Map);
      } else {
        _config[key] = value;
      }
    });
  }
  
  Map<String, dynamic> _deepMerge(Map<String, dynamic> target, Map<String, dynamic> source) {
    final result = Map<String, dynamic>.from(target);
    
    source.forEach((key, value) {
      if (value is Map && result[key] is Map) {
        result[key] = _deepMerge(result[key] as Map<String, dynamic>, value as Map<String, dynamic>);
      } else {
        result[key] = value;
      }
    });
    
    return result;
  }
  
  void _loadDefaultConfiguration() {
    _config.clear();
    _config.addAll({
      'app': {
        'name': 'Athkar App',
        'version': '1.0.0',
        'environment': _environment.toString(),
      },
      'api': {
        'timeout': 30,
        'retry_count': 3,
      },
      'feature': {
        'analytics': true,
        'crashlytics': true,
        'offline_mode': true,
      },
    });
  }
  
  @override
  Future<void> loadFromJson(String jsonString) async {
    try {
      final config = jsonDecode(jsonString) as Map<String, dynamic>;
      _config.clear();
      _config.addAll(config);
      await _saveConfiguration();
      
      _logger.info(
        message: 'Configuration loaded from JSON',
        data: {'keys': config.length},
      );
    } catch (e) {
      _logger.error(
        message: 'Error loading configuration from JSON',
        error: e,
      );
      throw FormatException('Invalid JSON configuration: $e');
    }
  }
  
  @override
  Future<void> reloadConfiguration() async {
    _logger.info(message: 'Reloading configuration...');
    _config.clear();
    _changeListeners.clear();
    await loadConfiguration();
  }
  
  @override
  Future<void> clearConfiguration() async {
    _config.clear();
    await _storage.remove(_configKey);
    _logger.info(message: 'Configuration cleared');
    
    // Notify all listeners
    _changeListeners.forEach((key, listeners) {
      for (final listener in listeners) {
        listener(null);
      }
    });
  }
  
  @override
  Future<void> clearSection(String section) async {
    _config.remove(section);
    await _saveConfiguration();
    
    _logger.info(
      message: 'Configuration section cleared',
      data: {'section': section},
    );
    
    // Notify listeners for keys in this section
    _changeListeners.forEach((key, listeners) {
      if (key.startsWith('$section.')) {
        for (final listener in listeners) {
          listener(null);
        }
      }
    });
  }
  
  @override
  bool hasKey(String key) {
    return _getNestedValue(key) != null;
  }
  
  @override
  Set<String> getAllKeys() {
    final keys = <String>{};
    _collectKeys(_config, '', keys);
    return keys;
  }
  
  @override
  Set<String> getSectionKeys(String section) {
    final keys = <String>{};
    final sectionData = _config[section];
    
    if (sectionData is Map<String, dynamic>) {
      _collectKeys(sectionData, section, keys);
    }
    
    return keys;
  }
  
  @override
  Map<String, dynamic> exportConfiguration() {
    return Map<String, dynamic>.from(_config);
  }
  
  @override
  Map<String, dynamic> exportSection(String section) {
    final sectionData = _config[section];
    if (sectionData is Map<String, dynamic>) {
      return Map<String, dynamic>.from(sectionData);
    }
    return {};
  }
  
  @override
  Future<void> importConfiguration(Map<String, dynamic> config) async {
    _config.clear();
    _config.addAll(config);
    await _saveConfiguration();
    
    _logger.info(
      message: 'Configuration imported',
      data: {'keys': config.length},
    );
    
    // Notify all listeners
    _notifyAllListeners();
  }
  
  @override
  void addChangeListener(String key, Function(dynamic) listener) {
    _changeListeners.putIfAbsent(key, () => []).add(listener);
    
    _logger.debug(
      message: 'Change listener added',
      data: {'key': key},
    );
  }
  
  @override
  void removeChangeListener(String key, Function(dynamic) listener) {
    _changeListeners[key]?.remove(listener);
    
    if (_changeListeners[key]?.isEmpty ?? false) {
      _changeListeners.remove(key);
    }
    
    _logger.debug(
      message: 'Change listener removed',
      data: {'key': key},
    );
  }
  
  @override
  Future<bool> validateConfiguration() async {
    try {
      // Basic validation rules
      final errors = <String>[];
      
      // Check required keys
      final requiredKeys = [
        ConfigKeys.appName,
        ConfigKeys.appVersion,
        ConfigKeys.appEnvironment,
      ];
      
      for (final key in requiredKeys) {
        if (!hasKey(key)) {
          errors.add('Missing required key: $key');
        }
      }
      
      // Validate types
      if (hasKey(ConfigKeys.apiTimeout)) {
        final timeout = getInt(ConfigKeys.apiTimeout);
        if (timeout == null || timeout <= 0) {
          errors.add('Invalid API timeout value');
        }
      }
      
      if (errors.isNotEmpty) {
        _logger.warning(
          message: 'Configuration validation failed',
          data: {'errors': errors},
        );
        return false;
      }
      
      _logger.info(message: 'Configuration validation passed');
      return true;
    } catch (e) {
      _logger.error(
        message: 'Error validating configuration',
        error: e,
      );
      return false;
    }
  }
  
  // Helper methods
  
  dynamic _getNestedValue(String key) {
    final parts = key.split('.');
    dynamic current = _config;
    
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    
    return current;
  }
  
  void _setNestedValue(String key, dynamic value) {
    final parts = key.split('.');
    Map<String, dynamic> current = _config;
    
    for (int i = 0; i < parts.length - 1; i++) {
      if (!current.containsKey(parts[i]) || current[parts[i]] is! Map) {
        current[parts[i]] = <String, dynamic>{};
      }
      current = current[parts[i]] as Map<String, dynamic>;
    }
    
    current[parts.last] = value;
  }
  
  void _collectKeys(Map<String, dynamic> map, String prefix, Set<String> keys) {
    map.forEach((key, value) {
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';
      keys.add(fullKey);
      
      if (value is Map<String, dynamic>) {
        _collectKeys(value, fullKey, keys);
      }
    });
  }
  
  Future<void> _saveConfiguration() async {
    try {
      await _storage.setMap(_configKey, _config);
      await _storage.setString(_envKey, _environment.toString());
    } catch (e) {
      _logger.error(
        message: 'Error saving configuration',
        error: e,
      );
    }
  }
  
  void _notifyListeners(String key, dynamic newValue, dynamic oldValue) {
    if (newValue == oldValue) return;
    
    // Notify exact key listeners
    final listeners = _changeListeners[key];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(newValue);
        } catch (e) {
          _logger.error(
            message: 'Error in change listener',
            error: e,
          );
        }
      }
    }
    
    // Notify parent key listeners (for nested values)
    final parts = key.split('.');
    for (int i = parts.length - 1; i > 0; i--) {
      final parentKey = parts.sublist(0, i).join('.');
      final parentListeners = _changeListeners[parentKey];
      
      if (parentListeners != null) {
        final parentValue = _getNestedValue(parentKey);
        for (final listener in parentListeners) {
          try {
            listener(parentValue);
          } catch (e) {
            _logger.error(
              message: 'Error in parent change listener',
              error: e,
            );
          }
        }
      }
    }
  }
  
  void _notifyAllListeners() {
    _changeListeners.forEach((key, listeners) {
      final value = _getNestedValue(key);
      for (final listener in listeners) {
        try {
          listener(value);
        } catch (e) {
          _logger.error(
            message: 'Error in change listener during notify all',
            error: e,
          );
        }
      }
    });
  }
}