// lib/features/athkar/data/datasources/user_athkar_data_local_data_source.dart
abstract class UserAthkarDataLocalDataSource {
  Future<bool> isFavorite(String athkarId);
  Future<void> saveFavorite(String athkarId, bool isFavorite); // تم تغيير الاسم من toggleFavorite
  Future<List<String>> getAllFavoriteAthkarIds();

  Future<int> getThikrCount(String athkarId);
  Future<void> updateThikrCount(String athkarId, int count);
  Future<Map<String, int>> getAllThikrCounts();
  Future<Map<String, bool>> getAllFavoriteStatuses(); // تم تغيير الاسم ليتوافق مع الريبو

  Future<void> resetAthkarProgress(String athkarId);
  Future<void> resetAllUserAthkarData();
}