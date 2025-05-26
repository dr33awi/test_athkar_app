// lib/features/athkar/domain/usecases/get_thikr_count.dart
import '../repositories/athkar_repository.dart';

class GetThikrCount {
  final AthkarRepository _repository;
  const GetThikrCount(this._repository);

  Future<int> call(String athkarId) async {
    return await _repository.getThikrCount(athkarId);
  }
}