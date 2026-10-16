import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notification/core/failures.dart';
import 'package:campus_notification/features/auth/domain/entities/auth_user.dart';
import 'package:campus_notification/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notification/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:campus_notification/features/auth/domain/usecases/login_usecase.dart';
import 'package:campus_notification/features/auth/domain/usecases/logout_usecase.dart';

/// Fake repository implementing AuthRepository interface for pure unit testing.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.shouldFail = false,
    this.failure = const AuthFailure('Email atau password salah'),
    bool initialLoggedIn = false,
  }) : _isLoggedIn = initialLoggedIn;

  final bool shouldFail;
  final Failure failure;
  bool _isLoggedIn;

  @override
  Future<({AuthUser? user, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      return (user: null, failure: failure);
    }

    if (email == 'mahasiswa@kampus.ac.id' && password == '123456') {
      _isLoggedIn = true;
      return (
        user: AuthUser(email: email, accessToken: 'fake_access_token'),
        failure: null,
      );
    }

    return (user: null, failure: const AuthFailure('Kredensial tidak valid'));
  }

  @override
  Future<({bool success, Failure? failure})> logout() async {
    if (shouldFail) {
      return (success: false, failure: failure);
    }
    _isLoggedIn = false;
    return (success: true, failure: null);
  }

  @override
  Future<({bool isLoggedIn, Failure? failure})> isLoggedIn() async {
    if (shouldFail) {
      return (isLoggedIn: false, failure: failure);
    }
    return (isLoggedIn: _isLoggedIn, failure: null);
  }

  @override
  Future<({bool refreshed, Failure? failure})> refreshToken() async {
    if (shouldFail) {
      return (refreshed: false, failure: failure);
    }
    return (refreshed: true, failure: null);
  }
}

void main() {
  group('LoginUseCase Tests', () {
    test(
      '1. Skenario Sukses: Mengembalikan AuthUser saat kredensial valid',
      () async {
        final fakeRepo = FakeAuthRepository();
        final useCase = LoginUseCase(fakeRepo);

        final result = await useCase(
          email: 'mahasiswa@kampus.ac.id',
          password: '123456',
        );

        expect(result.failure, isNull);
        expect(result.user, isNotNull);
        expect(result.user!.email, 'mahasiswa@kampus.ac.id');
        expect(result.user!.accessToken, isNotNull);
      },
    );

    test('2. Skenario Gagal: Mengembalikan AuthFailure saat kredensial salah tanpa throw exception', () async {
      final fakeRepo = FakeAuthRepository(
        shouldFail: true,
        failure: const AuthFailure('Email atau password salah'),
      );
      final useCase = LoginUseCase(fakeRepo);

      final result = await useCase(
        email: 'wrong@kampus.ac.id',
        password: 'wrong',
      );

      expect(result.user, isNull);
      expect(result.failure, isA<AuthFailure>());
      expect(result.failure!.message, 'Email atau password salah');
    });

    test(
      '3. Skenario Gagal: Validasi input kosong ditolak langsung oleh usecase',
      () async {
        final fakeRepo = FakeAuthRepository();
        final useCase = LoginUseCase(fakeRepo);

        final result = await useCase(email: '', password: '   ');

        expect(result.user, isNull);
        expect(result.failure, isA<AuthFailure>());
        expect(
          result.failure!.message,
          'Email dan password tidak boleh kosong',
        );
      },
    );
  });

  group('LogoutUseCase & CheckAuthStatusUseCase Tests', () {
    test(
      '4. Skenario Sukses: LogoutUseCase mengembalikan success=true',
      () async {
        final fakeRepo = FakeAuthRepository(initialLoggedIn: true);
        final logoutUseCase = LogoutUseCase(fakeRepo);

        final result = await logoutUseCase();

        expect(result.failure, isNull);
        expect(result.success, isTrue);
      },
    );

    test(
      '5. Skenario Sukses: CheckAuthStatusUseCase memeriksa status aktif',
      () async {
        final fakeRepo = FakeAuthRepository(initialLoggedIn: true);
        final checkAuth = CheckAuthStatusUseCase(fakeRepo);

        final result = await checkAuth();

        expect(result.failure, isNull);
        expect(result.isLoggedIn, isTrue);
      },
    );
  });
}
