// lib/core/services/utils/notification_payload_handler.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// معالج مركزي لـ payload الإشعارات
/// يوفر تحويل آمن بين Map و String
class NotificationPayloadHandler {
  /// تحويل Map إلى JSON String
  static String encode(Map<String, dynamic> data) {
    try {
      return jsonEncode(data);
    } catch (e) {
      if (kDebugMode) {
        print('Error encoding notification payload: $e');
      }
      // في حالة الفشل، إرجاع JSON فارغ
      return '{}';
    }
  }

  /// تحويل JSON String إلى Map
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
        print('Error decoding notification payload: $e');
      }
      // في حالة الفشل، إرجاع Map يحتوي على القيمة الأصلية
      return {'raw_payload': payload};
    }
  }

  /// التحقق من صحة payload وتحويله إلى String
  static String? validateAndEncode(String? payload) {
    if (payload == null || payload.isEmpty) return null;

    try {
      // محاولة فك التشفير للتأكد من صحة JSON
      jsonDecode(payload);
      return payload;
    } catch (e) {
      // إذا لم يكن JSON صالح، تحويله إلى JSON
      return encode({'value': payload});
    }
  }

  /// استخراج قيمة محددة من payload
  static T? extractValue<T>(String? payload, String key, {T? defaultValue}) {
    final Map<String, dynamic> data = decode(payload);
    
    if (data.containsKey(key)) {
      final value = data[key];
      if (value is T) {
        return value;
      }
    }
    
    return defaultValue;
  }

  /// استخراج معلومات التوجيه من payload
  static NotificationRoute? extractRoute(String? payload) {
    final data = decode(payload);
    
    if (data.containsKey('route')) {
      return NotificationRoute(
        path: data['route'] as String,
        arguments: data['arguments'] as Map<String, dynamic>?,
      );
    }
    
    return null;
  }

  /// بناء payload لإشعار الأذكار
  static String buildAthkarPayload({
    required String categoryId,
    required String categoryName,
    Map<String, dynamic>? additionalData,
  }) {
    return encode({
      'type': 'athkar',
      'category': categoryId,
      'route': '/athkar-details',
      'arguments': {
        'categoryId': categoryId,
        'categoryName': categoryName,
      },
      if (additionalData != null) ...additionalData,
    });
  }

  /// بناء payload لإشعار الصلاة
  static String buildPrayerPayload({
    required String prayerName,
    required DateTime prayerTime,
    bool isReminder = false,
    Map<String, dynamic>? additionalData,
  }) {
    return encode({
      'type': 'prayer',
      'prayer_name': prayerName,
      'prayer_time': prayerTime.toIso8601String(),
      'is_reminder': isReminder,
      'route': '/prayer-times',
      if (additionalData != null) ...additionalData,
    });
  }

  /// بناء payload عام
  static String buildCustomPayload({
    required String type,
    String? route,
    Map<String, dynamic>? arguments,
    Map<String, dynamic>? data,
  }) {
    return encode({
      'type': type,
      if (route != null) 'route': route,
      if (arguments != null) 'arguments': arguments,
      if (data != null) ...data,
    });
  }
}

/// معلومات التوجيه المستخرجة من payload
class NotificationRoute {
  final String path;
  final Map<String, dynamic>? arguments;

  NotificationRoute({
    required this.path,
    this.arguments,
  });

  @override
  String toString() => 'NotificationRoute(path: $path, arguments: $arguments)';
}