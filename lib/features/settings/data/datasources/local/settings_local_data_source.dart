//lib/settings/data/datasources/local/settings_local_data_source.dart// أو lib/features/settings/data/datasources/settings_local_data_source.dart
import 'package:athkar_app/features/settings/data/models/settings_model.dart';

import '../../../../../core/infrastructure/services/storage/storage_service.dart';


abstract class SettingsLocalDataSource {
  Future<Map<String, dynamic>> getSettings();
  Future<bool> updateSettings(Map<String, dynamic> settings);
  Future<bool> updateSetting({required String key, required dynamic value});
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final StorageService _storageService;
  static const String _settingsKey = 'app_settings_v2'; // 🔴 تم تغيير المفتاح لتجنب التعارض مع البيانات القديمة المحتملة

  SettingsLocalDataSourceImpl(this._storageService);

  @override
  Future<Map<String, dynamic>> getSettings() async {
    final settingsMap = _storageService.getMap(_settingsKey);
    if (settingsMap == null) {
      final defaultSettingsMap = SettingsModel.defaultSettings().toJson();
      await _storageService.setMap(_settingsKey, defaultSettingsMap);
      return defaultSettingsMap;
    }
    // دمج الإعدادات المحفوظة مع الافتراضية لضمان وجود جميع الحقول
    final defaultSettingsMap = SettingsModel.defaultSettings().toJson();
    final mergedSettingsMap = {...defaultSettingsMap, ...settingsMap};
    return mergedSettingsMap;
  }

  @override
  Future<bool> updateSettings(Map<String, dynamic> settings) async {
    return await _storageService.setMap(_settingsKey, settings);
  }

  @override
  Future<bool> updateSetting({required String key, required dynamic value}) async {
    final currentSettings = await getSettings();
    currentSettings[key] = value;
    return await updateSettings(currentSettings);
  }
}