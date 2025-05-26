// lib/features/athkar/data/datasources/local/user_athkar_data_local_data_source_impl.dart
import 'dart:convert'; // لاستخدامه مع Map<String, int>
import 'package:athkar_app/core/services/interfaces/storage_service.dart';
import 'package:athkar_app/features/athkar/domain/repositories/user_athkar_data_local_data_source.dart';
import '../../../../../app/di/service_locator.dart' as di; // للوصول إلى StorageService

class UserAthkarDataLocalDataSourceImpl implements UserAthkarDataLocalDataSource {
  final StorageService _storageService;

  // تعريف ثوابت للمفاتيح المستخدمة في SharedPreferences
  static const String _favPrefix = 'athkar_fav_';
  static const String _countPrefix = 'athkar_count_';
  // مفاتيح اختيارية لتخزين كل المعرفات/العدادات مرة واحدة (يمكن تحسينها لاحقًا)
  static const String _allFavIdsKey = 'athkar_all_fav_ids';
  static const String _allCountsMapKey = 'athkar_all_counts_map';


  UserAthkarDataLocalDataSourceImpl({StorageService? storageService}) 
      : _storageService = storageService ?? di.getIt<StorageService>();

  String _generateFavoriteKey(String athkarId) => '$_favPrefix$athkarId';
  String _generateCountKey(String athkarId) => '$_countPrefix$athkarId';

  @override
  Future<bool> isFavorite(String athkarId) async {
    return _storageService.getBool(_generateFavoriteKey(athkarId)) ?? false;
  }

  @override
  Future<void> saveFavorite(String athkarId, bool isFavorite) async {
    await _storageService.setBool(_generateFavoriteKey(athkarId), isFavorite);
    
    // تحديث قائمة المعرفات المفضلة المجمعة
    List<String> allFavIds = await getAllFavoriteAthkarIds();
    if (isFavorite) {
      if (!allFavIds.contains(athkarId)) {
        allFavIds.add(athkarId);
      }
    } else {
      allFavIds.remove(athkarId);
    }
    await _storageService.setStringList(_allFavIdsKey, allFavIds);
  }

  @override
  Future<List<String>> getAllFavoriteAthkarIds() async {
    return _storageService.getStringList(_allFavIdsKey) ?? [];
  }

  @override
  Future<Map<String, bool>> getAllFavoriteStatuses() async {
    final List<String> favoriteIds = await getAllFavoriteAthkarIds();
    final Map<String, bool> statuses = {};
    // للحصول على كل المفاتيح ثم فلترتها (أكثر كفاءة إذا كانت المفضلة قليلة)
    // أو المرور على قائمة الأذكار المعروفة والتحقق من كل واحد (أكثر كفاءة إذا كانت المفضلة كثيرة جدًا)
    // هنا، سنعتمد على قائمة المعرفات المفضلة.
    final allKeys = _storageService.getKeys();
    for (String key in allKeys) {
        if (key.startsWith(_favPrefix)) {
            final athkarId = key.substring(_favPrefix.length);
            statuses[athkarId] = _storageService.getBool(key) ?? false;
        }
    }
    // التأكد من أن جميع العناصر في favoriteIds لها قيمة true
    for (String id in favoriteIds) {
        statuses[id] = true;
    }
    return statuses;
  }

  @override
  Future<int> getThikrCount(String athkarId) async {
    return _storageService.getInt(_generateCountKey(athkarId)) ?? 0;
  }

  @override
  Future<void> updateThikrCount(String athkarId, int count) async {
    await _storageService.setInt(_generateCountKey(athkarId), count);
    
    // تحديث خريطة العدادات المجمعة
    Map<String, int> allCounts = await getAllThikrCounts();
    if (count == 0) { // إذا أصبح العداد صفرًا، يمكن إزالته من الخريطة المجمعة
        allCounts.remove(athkarId);
    } else {
        allCounts[athkarId] = count;
    }
    await _storageService.setString(_allCountsMapKey, jsonEncode(allCounts));
  }

  @override
  Future<Map<String, int>> getAllThikrCounts() async {
    final String? countsJson = _storageService.getString(_allCountsMapKey);
    if (countsJson != null && countsJson.isNotEmpty) {
      try {
        final decodedMap = jsonDecode(countsJson) as Map<String, dynamic>;
        return decodedMap.map((key, value) => MapEntry(key, value as int));
      } catch (e) {
        // في حالة الخطأ في التحليل، أرجع خريطة فارغة أو سجل الخطأ
        return {};
      }
    }
    return {}; // إذا لم يكن هناك بيانات مخزنة، أرجع خريطة فارغة
  }

  @override
  Future<void> resetAthkarProgress(String athkarId) async {
    await updateThikrCount(athkarId, 0); // إعادة العداد إلى صفر
  }

  @override
  Future<void> resetAllUserAthkarData() async {
    final keys = _storageService.getKeys();
    List<Future<bool>> futures = [];
    for (String key in keys) {
      if (key.startsWith(_favPrefix) || key.startsWith(_countPrefix) || key == _allFavIdsKey || key == _allCountsMapKey) {
        futures.add(_storageService.remove(key));
      }
    }
    await Future.wait(futures);
    // مسح القوائم المجمعة أيضًا
    await _storageService.remove(_allFavIdsKey);
    await _storageService.remove(_allCountsMapKey);
  }
}