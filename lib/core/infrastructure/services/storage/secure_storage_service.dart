// lib/core/infrastructure/services/storage/secure_storage_service.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../logging/logger_service.dart';
import 'storage_service.dart';

/// Secure storage service for sensitive data
/// Uses platform-specific secure storage mechanisms
abstract class SecureStorageService {
  /// Save secure string value
  Future<bool> setSecureString(String key, String value);
  
  /// Get secure string value
  Future<String?> getSecureString(String key);
  
  /// Save secure map data
  Future<bool> setSecureMap(String key, Map<String, dynamic> value);
  
  /// Get secure map data
  Future<Map<String, dynamic>?> getSecureMap(String key);
  
  /// Save secure credentials
  Future<bool> setCredentials({
    required String username,
    required String password,
    String? domain,
  });
  
  /// Get secure credentials
  Future<Map<String, String>?> getCredentials();
  
  /// Save secure token
  Future<bool> setToken(String token, {String? refreshToken});
  
  /// Get secure token
  Future<Map<String, String>?> getToken();
  
  /// Remove specific secure key
  Future<bool> removeSecure(String key);
  
  /// Clear all secure storage
  Future<bool> clearSecure();
  
  /// Check if secure key exists
  Future<bool> containsSecureKey(String key);
  
  /// Get all secure keys
  Future<Set<String>> getSecureKeys();
  
  /// Check if secure storage is available
  Future<bool> isSecureStorageAvailable();
  
  /// Migrate data from regular to secure storage
  Future<bool> migrateToSecure(String key);
  
  /// Encrypt and store data
  Future<bool> encryptAndStore(String key, String data);
  
  /// Retrieve and decrypt data
  Future<String?> retrieveAndDecrypt(String key);
}

/// Implementation of secure storage service
class SecureStorageServiceImpl implements SecureStorageService {
  final FlutterSecureStorage _secureStorage;
  final StorageService _regularStorage;
  final LoggerService? _logger;
  
  static const String _keyPrefix = 'secure_';
  static const String _credentialsKey = '${_keyPrefix}credentials';
  static const String _tokenKey = '${_keyPrefix}token';
  
  SecureStorageServiceImpl({
    FlutterSecureStorage? secureStorage,
    required StorageService regularStorage,
    LoggerService? logger,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _regularStorage = regularStorage,
        _logger = logger;
  
  @override
  Future<bool> setSecureString(String key, String value) async {
    try {
      final prefixedKey = _getPrefixedKey(key);
      await _secureStorage.write(
        key: prefixedKey,
        value: value,
      );
      
      _logger?.debug(
        message: 'Secure string saved',
        data: {'key': key, 'length': value.length},
      );
      
      return true;
    } catch (e) {
      _logger?.error(
        message: 'Failed to save secure string',
        error: e,
      );
      return false;
    }
  }
  
  @override
  Future<String?> getSecureString(String key) async {
    try {
      final prefixedKey = _getPrefixedKey(key);
      return await _secureStorage.read(
        key: prefixedKey,
      );
    } catch (e) {
      _logger?.error(
        message: 'Failed to get secure string',
        error: e,
      );
      return null;
    }
  }
  
  @override
  Future<bool> setSecureMap(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await setSecureString(key, jsonString);
    } catch (e) {
      _logger?.error(
        message: 'Failed to save secure map',
        error: e,
      );
      return false;
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getSecureMap(String key) async {
    try {
      final jsonString = await getSecureString(key);
      if (jsonString == null) return null;
      
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      
      _logger?.warning(
        message: 'Invalid secure map format',
        data: {'key': key, 'type': decoded.runtimeType},
      );
      return null;
    } catch (e) {
      _logger?.error(
        message: 'Failed to get secure map',
        error: e,
      );
      return null;
    }
  }
  
  @override
  Future<bool> setCredentials({
    required String username,
    required String password,
    String? domain,
  }) async {
    try {
      final credentials = {
        'username': username,
        'password': password,
        if (domain != null) 'domain': domain,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final success = await setSecureMap(_credentialsKey, credentials);
      
      if (success) {
        _logger?.info(
          message: 'Credentials saved securely',
          data: {'username': username, 'has_domain': domain != null},
        );
      }
      
      return success;
    } catch (e) {
      _logger?.error(
        message: 'Failed to save credentials',
        error: e,
      );
      return false;
    }
  }
  
  @override
  Future<Map<String, String>?> getCredentials() async {
    try {
      final data = await getSecureMap(_credentialsKey);
      if (data == null) return null;
      
      return data.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      _logger?.error(
        message: 'Failed to get credentials',
        error: e,
      );
      return null;
    }
  }
  
  @override
  Future<bool> setToken(String token, {String? refreshToken}) async {
    try {
      final tokenData = {
        'access_token': token,
        if (refreshToken != null) 'refresh_token': refreshToken,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final success = await setSecureMap(_tokenKey, tokenData);
      
      if (success) {
        _logger?.info(
          message: 'Token saved securely',
          data: {'has_refresh': refreshToken != null},
        );
      }
      
      return success;
    } catch (e) {
      _logger?.error(
        message: 'Failed to save token',
        error: e,
      );
      return false;
    }
  }
  
  @override
  Future<Map<String, String>?> getToken() async {
    try {
      final data = await getSecureMap(_tokenKey);
      if (data == null) return null;
      
      return data.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      _logger?.error(
        message: 'Failed to get token',
        error: e,
      );
      return null;
    }
  }
  
  @override
  Future<bool> removeSecure(String key) async {
    try {
      final prefixedKey = _getPrefixedKey(key);
      await _secureStorage.delete(
        key: prefixedKey,
      );
      
      _logger?.debug(
        message: 'Secure key removed',
        data: {'key': key},
      );
      
      return true;
    } catch (e) {
      _logger?.error(
        message: 'Failed to remove secure key',
        error: e,
      );
      return false;
    }
  }
  
  @override
  Future<bool> clearSecure() async {
    try {
      await _secureStorage.deleteAll();
      
      _logger?.info(message: 'Secure storage cleared');
      return true;
    } catch (e) {
      _logger?.error(
        message: 'Failed to clear secure storage',
        error: e,
      );
      return false;
    }
  }
  
  @override
  Future<bool> containsSecureKey(String key) async {
    try {
      final prefixedKey = _getPrefixedKey(key);
      return await _secureStorage.containsKey(
        key: prefixedKey,
      );
    } catch (e) {
      _logger?.error(
        message: 'Failed to check secure key existence',
        error: e,
      );
      return false;
    }
  }
  
  @override
  Future<Set<String>> getSecureKeys() async {
    try {
      final allKeys = await _secureStorage.readAll();
      
      return allKeys.keys
          .where((key) => key.startsWith(_keyPrefix))
          .map((key) => key.substring(_keyPrefix.length))
          .toSet();
    } catch (e) {
      _logger?.error(
        message: 'Failed to get secure keys',
        error: e,
      );
      return {};
    }
  }
  
  @override
  Future<bool> isSecureStorageAvailable() async {
    try {
      // Try to write and read a test value
      const testKey = '${_keyPrefix}test';
      const testValue = 'test';
      
      await _secureStorage.write(
        key: testKey,
        value: testValue,
      );
      
      final readValue = await _secureStorage.read(
        key: testKey,
      );
      
      await _secureStorage.delete(
        key: testKey,
      );
      
      return readValue == testValue;
    } catch (e) {
      _logger?.warning(
        message: 'Secure storage not available',
        data: {'error': e.toString()},
      );
      return false;
    }
  }
  
  @override
  Future<bool> migrateToSecure(String key) async {
    try {
      // Get value from regular storage
      final value = _regularStorage.getString(key);
      if (value == null) {
        _logger?.warning(
          message: 'Key not found in regular storage',
          data: {'key': key},
        );
        return false;
      }
      
      // Save to secure storage
      final success = await setSecureString(key, value);
      
      if (success) {
        // Remove from regular storage
        await _regularStorage.remove(key);
        
        _logger?.info(
          message: 'Data migrated to secure storage',
          data: {'key': key},
        );
      }
      
      return success;
    } catch (e) {
      _logger?.error(
        message: 'Failed to migrate to secure storage',
        error: e,
      );
      return false;
    }
  }
  
  @override
  Future<bool> encryptAndStore(String key, String data) async {
    // For now, secure storage handles encryption internally
    // You can add custom encryption here if needed
    return await setSecureString(key, data);
  }
  
  @override
  Future<String?> retrieveAndDecrypt(String key) async {
    // For now, secure storage handles decryption internally
    // You can add custom decryption here if needed
    return await getSecureString(key);
  }
  
  /// Get prefixed key to avoid conflicts
  String _getPrefixedKey(String key) {
    if (key.startsWith(_keyPrefix)) {
      return key;
    }
    return '$_keyPrefix$key';
  }
}