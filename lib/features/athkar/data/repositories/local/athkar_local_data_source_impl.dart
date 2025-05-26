// lib/features/athkar/data/datasources/local/athkar_local_data_source_impl.dart
import 'dart:convert';
import 'package:athkar_app/features/athkar/data/datasources/athkar_local_data_source.dart';
import 'package:athkar_app/features/athkar/data/models/athkar_model.dart';
import 'package:athkar_app/features/athkar/domain/entities/athkar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../../../core/error/exceptions.dart';


class AthkarLocalDataSourceImpl implements AthkarLocalDataSource {
  final String _athkarAssetPath = 'assets/data/athkar.json';

  Future<Map<String, dynamic>> _loadAthkarData() async {
    try {
      final String jsonString = await rootBundle.loadString(_athkarAssetPath);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      return data;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('خطأ فادح أثناء تحميل أو تفسير ملف الأذكار "$_athkarAssetPath": $e');
        debugPrint('StackTrace: $s');
      }
      throw DataLoadException('فشل تحميل بيانات الأذكار من الملف المحلي: ${e.toString()}');
    }
  }

  CustomTime? _parseCustomTime(dynamic jsonTime) {
    if (jsonTime == null) return null;
    if (jsonTime is Map) {
      final hour = jsonTime['hour'] as int?;
      final minute = jsonTime['minute'] as int?;
      if (hour != null && minute != null) {
        try {
          return CustomTime(hour: hour, minute: minute);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('خطأ أثناء تفسير CustomTime من الخريطة ($jsonTime): $e');
          }
          return null;
        }
      }
    } else if (jsonTime is String && jsonTime.contains(':')) {
      try {
        final parts = jsonTime.split(':');
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return CustomTime(hour: hour, minute: minute);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('خطأ أثناء تفسير CustomTime من السلسلة النصية ($jsonTime): $e');
        }
        return null;
      }
    }
    if (kDebugMode) {
      debugPrint('تنسيق CustomTime غير مدعوم: $jsonTime');
    }
    return null;
  }

  @override
  Future<List<AthkarCategory>> getAthkarCategories() async {
    final data = await _loadAthkarData();
    final List<dynamic> categoriesJson = data['categories'] as List<dynamic>? ?? [];
    return categoriesJson.map((jsonCategory) {
      final categoryMap = jsonCategory as Map<String, dynamic>;
      return AthkarCategory(
        id: categoryMap['id'] as String,
        name: categoryMap['name'] as String,
        description: categoryMap['description'] as String? ?? '',
        icon: categoryMap['icon'] as String,
        notificationsEnabled: categoryMap['notificationsEnabled'] as bool? ?? false,
        customNotificationTime: _parseCustomTime(categoryMap['customNotificationTime']),
      );
    }).toList();
  }

  @override
  Future<List<Athkar>> getAthkarByCategory(String categoryId) async {
    final data = await _loadAthkarData();
    final List<dynamic> allAthkarJson = data['athkar'] as List<dynamic>? ?? [];
    return allAthkarJson
        .where((jsonAthkar) {
          final athkarMap = jsonAthkar as Map<String, dynamic>;
          return athkarMap['categoryId'] == categoryId;
        })
        .map((jsonAthkar) => AthkarModel.fromJson(jsonAthkar as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<Athkar?> getAthkarById(String id) async {
    final data = await _loadAthkarData();
    final List<dynamic> allAthkarJson = data['athkar'] as List<dynamic>? ?? [];
    try {
      final athkarJson = allAthkarJson.cast<Map<String, dynamic>>()
          .firstWhere((json) => json['id'] == id);
      return AthkarModel.fromJson(athkarJson).toEntity();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('لم يتم العثور على ذكر بالمعرف "$id": $e');
      }
      return null;
    }
  }

  Future<void> resetData() async {}
  // تم إزالة getFavoriteAthkar و saveAthkarFavorite من هذا التنفيذ
}