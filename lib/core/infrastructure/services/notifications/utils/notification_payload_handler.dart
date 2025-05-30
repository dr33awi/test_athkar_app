// lib/core/infrastructure/services/notifications/utils/notification_payload_handler.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Generic notification payload handler
class NotificationPayloadHandler {
  /// Convert Map to JSON String
  static String encode(Map<String, dynamic> data) {
    try {
      return jsonEncode(data);
    } catch (e) {
      if (kDebugMode) {
        print('[PayloadHandler] Error encoding payload: $e');
      }
      return '{}';
    }
  }

  /// Convert JSON String to Map
  static Map<String, dynamic> decode(String? payload) {
    if (payload == null || payload.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'raw': decoded};
    } catch (e) {
      if (kDebugMode) {
        print('[PayloadHandler] Error decoding payload: $e');
      }
      return {'raw_payload': payload};
    }
  }

  /// Validate and encode payload
  static String? validateAndEncode(dynamic payload) {
    if (payload == null) return null;
    
    if (payload is String) {
      if (payload.isEmpty) return null;
      
      try {
        // Try to decode to validate JSON
        jsonDecode(payload);
        return payload;
      } catch (e) {
        // If not valid JSON, wrap it
        return encode({'value': payload});
      }
    } else if (payload is Map<String, dynamic>) {
      return encode(payload);
    } else {
      return encode({'value': payload.toString()});
    }
  }

  /// Extract a specific value from payload
  static T? extractValue<T>(String? payload, String key, {T? defaultValue}) {
    final Map<String, dynamic> data = decode(payload);
    
    if (data.containsKey(key)) {
      final value = data[key];
      if (value is T) {
        return value;
      }
      
      // Try type conversion for common cases
      if (T == int && value is String) {
        return int.tryParse(value) as T?;
      } else if (T == double && value is String) {
        return double.tryParse(value) as T?;
      } else if (T == bool && value is String) {
        return (value.toLowerCase() == 'true') as T?;
      } else if (T == DateTime && value is String) {
        return DateTime.tryParse(value) as T?;
      }
    }
    
    return defaultValue;
  }

  /// Extract multiple values
  static Map<String, dynamic> extractValues(
    String? payload,
    List<String> keys,
  ) {
    final Map<String, dynamic> data = decode(payload);
    final Map<String, dynamic> result = {};
    
    for (final key in keys) {
      if (data.containsKey(key)) {
        result[key] = data[key];
      }
    }
    
    return result;
  }

  /// Merge payloads
  static String mergePayloads(String? basePayload, Map<String, dynamic> additionalData) {
    final Map<String, dynamic> base = decode(basePayload);
    base.addAll(additionalData);
    return encode(base);
  }

  /// Extract navigation route information
  static NavigationRoute? extractRoute(String? payload) {
    final data = decode(payload);
    
    if (data.containsKey('route') || data.containsKey('path')) {
      return NavigationRoute(
        path: data['route'] ?? data['path'] ?? '/',
        arguments: data['arguments'] as Map<String, dynamic>?,
        parameters: data['parameters'] as Map<String, String>?,
      );
    }
    
    return null;
  }

  /// Build navigation payload
  static String buildNavigationPayload({
    required String route,
    Map<String, dynamic>? arguments,
    Map<String, String>? parameters,
    Map<String, dynamic>? additionalData,
  }) {
    return encode({
      'route': route,
      if (arguments != null) 'arguments': arguments,
      if (parameters != null) 'parameters': parameters,
      if (additionalData != null) ...additionalData,
    });
  }

  /// Build generic payload with type
  static String buildTypedPayload({
    required String type,
    required String id,
    String? title,
    String? route,
    Map<String, dynamic>? data,
  }) {
    return encode({
      'type': type,
      'id': id,
      if (title != null) 'title': title,
      if (route != null) 'route': route,
      if (data != null) 'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Check if payload contains a specific type
  static bool hasType(String? payload, String type) {
    final data = decode(payload);
    return data['type'] == type;
  }

  /// Get payload type
  static String? getType(String? payload) {
    return extractValue<String>(payload, 'type');
  }

  /// Validate payload structure
  static bool isValidPayload(String? payload, List<String> requiredKeys) {
    if (payload == null || payload.isEmpty) return false;
    
    try {
      final data = decode(payload);
      return requiredKeys.every((key) => data.containsKey(key));
    } catch (e) {
      return false;
    }
  }
  
  /// Build action payload
  static String buildActionPayload({
    required String action,
    Map<String, dynamic>? data,
  }) {
    return encode({
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      if (data != null) ...data,
    });
  }
  
  /// Extract action from payload
  static String? extractAction(String? payload) {
    return extractValue<String>(payload, 'action');
  }
  
  /// Build notification metadata payload
  static String buildMetadataPayload({
    required String notificationId,
    required String category,
    String? groupKey,
    Map<String, dynamic>? customData,
  }) {
    return encode({
      'notification_id': notificationId,
      'category': category,
      if (groupKey != null) 'group_key': groupKey,
      if (customData != null) 'custom_data': customData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  /// Sanitize payload (remove sensitive data)
  static String sanitizePayload(String? payload, List<String> sensitiveKeys) {
    if (payload == null || payload.isEmpty) return '{}';
    
    final data = decode(payload);
    final sanitized = Map<String, dynamic>.from(data);
    
    // Remove sensitive keys
    for (final key in sensitiveKeys) {
      sanitized.remove(key);
    }
    
    // Recursively sanitize nested maps
    sanitized.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeMap(value, sensitiveKeys);
      }
    });
    
    return encode(sanitized);
  }
  
  static Map<String, dynamic> _sanitizeMap(
    Map<String, dynamic> map,
    List<String> sensitiveKeys,
  ) {
    final sanitized = Map<String, dynamic>.from(map);
    
    for (final key in sensitiveKeys) {
      sanitized.remove(key);
    }
    
    sanitized.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeMap(value, sensitiveKeys);
      }
    });
    
    return sanitized;
  }
}

/// Navigation route information
class NavigationRoute {
  final String path;
  final Map<String, dynamic>? arguments;
  final Map<String, String>? parameters;

  NavigationRoute({
    required this.path,
    this.arguments,
    this.parameters,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'path': path,
      if (arguments != null) 'arguments': arguments,
      if (parameters != null) 'parameters': parameters,
    };
  }

  @override
  String toString() => 'NavigationRoute(path: $path, arguments: $arguments, parameters: $parameters)';
}