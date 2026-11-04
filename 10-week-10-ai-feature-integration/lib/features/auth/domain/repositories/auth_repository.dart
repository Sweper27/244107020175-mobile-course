import '../../../../core/failures.dart';
import '../entities/auth_user.dart';

/// Repository contract for Authentication.
/// Pure Dart interface defined in Domain layer.
abstract class AuthRepository {
  Future<({AuthUser? user, Failure? failure})> login({
    required String email,
    required String password,
  });

  Future<({bool success, Failure? failure})> logout();

  Future<({bool isLoggedIn, Failure? failure})> isLoggedIn();

  Future<({bool refreshed, Failure? failure})> refreshToken();
}
