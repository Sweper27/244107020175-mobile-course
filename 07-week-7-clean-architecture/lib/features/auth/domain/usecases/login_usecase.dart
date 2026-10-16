import '../../../../core/failures.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Use case for authenticating user credentials.
/// Handles business logic & validation before querying repository.
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<({AuthUser? user, Failure? failure})> call({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      return (
        user: null,
        failure: const AuthFailure('Email dan password tidak boleh kosong'),
      );
    }

    return _repository.login(email: trimmedEmail, password: trimmedPassword);
  }
}
