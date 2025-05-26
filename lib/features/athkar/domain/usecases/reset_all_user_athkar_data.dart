// lib/features/athkar/domain/usecases/reset_all_user_athkar_data.dart
import '../repositories/athkar_repository.dart';

class ResetAllUserAthkarData {
  final AthkarRepository _repository;
  const ResetAllUserAthkarData(this._repository);

  Future<void> call() async {
    await _repository.resetAllUserAthkarData();
  }
}