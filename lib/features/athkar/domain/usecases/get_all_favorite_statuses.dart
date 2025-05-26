// lib/features/athkar/domain/usecases/get_all_favorite_statuses.dart
import '../repositories/athkar_repository.dart';

class GetAllFavoriteStatuses {
  final AthkarRepository _repository;
  const GetAllFavoriteStatuses(this._repository);

  Future<Map<String, bool>> call() async {
    return await _repository.getAllFavoriteStatuses();
  }
}