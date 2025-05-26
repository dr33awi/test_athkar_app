// lib/features/athkar/domain/usecases/update_thikr_count.dart
import '../repositories/athkar_repository.dart';

class UpdateThikrCount {
  final AthkarRepository _repository;
  const UpdateThikrCount(this._repository);

  Future<void> call({required String athkarId, required int count}) async {
    await _repository.updateThikrCount(athkarId, count);
  }
}