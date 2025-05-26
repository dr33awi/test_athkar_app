// lib/features/athkar/domain/usecases/is_athkar_favorite.dart
import '../repositories/athkar_repository.dart';

class IsAthkarFavorite {
  final AthkarRepository _repository;
  const IsAthkarFavorite(this._repository);

  Future<bool> call(String athkarId) async {
    return await _repository.isAthkarFavorite(athkarId);
  }
}