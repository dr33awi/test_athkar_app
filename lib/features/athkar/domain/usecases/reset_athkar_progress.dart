// lib/features/athkar/domain/usecases/reset_athkar_progress.dart
import '../repositories/athkar_repository.dart';

class ResetAthkarProgress {
  final AthkarRepository _repository;
  const ResetAthkarProgress(this._repository);

  Future<void> call(String athkarId) async {
    await _repository.resetAthkarProgress(athkarId);
  }
}