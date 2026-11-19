import '../../../../core/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for verifying whether user has an active session.
class CheckAuthStatusUseCase {
  const CheckAuthStatusUseCase(this._repository);

  final AuthRepository _repository;

  Future<({bool isLoggedIn, Failure? failure})> call() {
    return _repository.isLoggedIn();
  }
}
