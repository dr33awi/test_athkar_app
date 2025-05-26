// lib/features/athkar/domain/usecases/get_all_thikr_counts.dart
import '../repositories/athkar_repository.dart';

class GetAllThikrCounts {
  final AthkarRepository _repository;
  const GetAllThikrCounts(this._repository);

  Future<Map<String, int>> call() async {
    return await _repository.getAllThikrCounts();
  }
}