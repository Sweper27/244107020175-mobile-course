import '../../../../core/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for logging out the current user and invalidating tokens.
class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<({bool success, Failure? failure})> call() {
    return _repository.logout();
  }
}
